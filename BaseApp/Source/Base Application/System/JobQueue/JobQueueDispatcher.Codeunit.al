namespace System.Threading;

using System.IO;

codeunit 448 "Job Queue Dispatcher"
{
    Permissions = TableData "Job Queue Entry" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Skip: Boolean;
    begin
        OnBeforeRun(Rec, Skip);
        if Skip then
            exit;

        Rec.ReadIsolation(IsolationLevel::UpdLock);
        Rec.Get(Rec.ID);
        if not Rec.IsReadyToStart() then
            exit;

        if Rec.IsExpired(CurrentDateTime) then
            Rec.DeleteTask()
        else
            if not IsWithinStartEndTime(Rec) then
                Reschedule(Rec)
            else
                if WaitForOthersWithSameCategory(Rec) then 
                    RescheduleAsWaiting(Rec)
                else begin
                    HandleRequest(Rec);
                    if Rec."Job Queue Category Code" <> '' then begin
                        Commit();
                        Rec.ActivateNextJobInCategory();
                    end;
                end;
        Commit();
        CleanupCurrentUsersJobsWithSameCategory(Rec);
    end;

    var
        TestMode: Boolean;
        JobQueueEntryFailedtoGetBeforeFinalizingTxt: Label 'Failed to get Job Queue Entry before finalizing record.', Locked = true;
        JobQueueEntryFailedtoGetBeforeUpdatingStatusTxt: Label 'Failed to get Job Queue Entry before updating status.', Locked = true;
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;

    local procedure HandleRequest(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        PrevStatus: Option;
        JobQueueStartTime: DateTime;
        JobQueueExecutionTimeInMs: Integer;
    begin
        OnBeforeHandleRequest(JobQueueEntry);

        // Always update the JQE because if the session dies and the task is rerun, it should have the latest information
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry."User Session Started" := CurrentDateTime();
        JobQueueEntry."User Session ID" := SessionId();
        JobQueueEntry."User Service Instance ID" := ServiceInstanceId();
        JobQueueEntry.Modify();

        JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
        // Codeunit.Run is limited during write transactions because one or more tables will be locked.
        // To avoid NavCSideException we have either to add the COMMIT before the call or do not use a returned value.
        Commit();
        OnBeforeExecuteJob(JobQueueEntry);

        JobQueueStartTime := CurrentDateTime();
        Codeunit.Run(Codeunit::"Job Queue Start Codeunit", JobQueueEntry);
        JobQueueExecutionTimeInMs := CurrentDateTime() - JobQueueStartTime;

        OnAfterSuccessExecuteJob(JobQueueEntry);
        PrevStatus := JobQueueEntry.Status;

        // user may have deleted it in the meantime
        if JobQueueEntry.DoesExistLocked() then
            JobQueueEntry.SetResult(PrevStatus)
        else begin
            SendTraceOnFailedtoGetRecordBeforeUpdatingStatus(JobQueueEntry);
            JobQueueEntry.SetResultDeletedEntry();
        end;
        Commit();

        JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);

        if JobQueueEntry.DoesExistLocked() then
            JobQueueEntry.FinalizeRun()
        else
            SendTraceOnFailedToGetRecordBeforeFinalizingRecord(JobQueueEntry);

        OnAfterSuccessHandleRequest(JobQueueEntry, JobQueueExecutionTimeInMs, JobQueueLogEntry."System Task Id");
    end;

    local procedure IsWithinStartEndTime(var CurrJobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        CurrTime: Time;
    begin
        // No start and end time set, always run
        if (CurrJobQueueEntry."Starting Time" = 0T) and (CurrJobQueueEntry."Ending Time" = 0T) then
            exit(true);

        CurrTime := DT2Time(CurrentDateTime);
        // Start and end time set, check if current time is within the range
        if (CurrJobQueueEntry."Starting Time" <> 0T) and (CurrJobQueueEntry."Ending Time" <> 0T) then
            if CurrJobQueueEntry."Starting Time" <> CurrJobQueueEntry."Ending Time" then
                exit((CurrJobQueueEntry."Starting Time" <= CurrTime) and (CurrTime <= CurrJobQueueEntry."Ending Time"));

        // If start and end time are the same, treat it as only starting time is set.
        // Only start time set, check if current time is after start time
        if (CurrJobQueueEntry."Starting Time" <> 0T) then
            exit(CurrJobQueueEntry."Starting Time" <= CurrTime);

        // Only end time set, check if current time is before end time
        if (CurrJobQueueEntry."Ending Time" <> 0T) then
            exit(CurrTime <= CurrJobQueueEntry."Ending Time");
    end;

    procedure WaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWaitForOthersWithSameCategory(CurrJobQueueEntry, JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CurrJobQueueEntry."Job Queue Category Code" = '' then
            exit(false);

        // Use the Job Queue Category as a semaphore so only one checks at the time.
        JobQueueCategory.ReadIsolation(IsolationLevel::UpdLock);
        if not JobQueueCategory.Get(CurrJobQueueEntry."Job Queue Category Code") then
            exit(false);

        JobQueueEntry.SetLoadFields(ID);
        JobQueueEntry.ReadIsolation(JobQueueEntry.ReadIsolation::ReadUnCommitted);
        JobQueueEntry.SetFilter(ID, '<>%1', CurrJobQueueEntry.ID);
        JobQueueEntry.SetRange("Job Queue Category Code", CurrJobQueueEntry."Job Queue Category Code");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange(Scheduled, true);
        JobQueueEntry.SetCurrentKey("Job Queue Category Code", "Priority Within Category", "Entry No.");
        if not JobQueueEntry.IsEmpty() then
            exit(true);

        JobQueueEntry.SetRange(Scheduled, false);
        if TestMode then
            if not JobQueueEntry.IsEmpty() then
                exit(true);
        exit(false);
    end;

    local procedure CleanupCurrentUsersJobsWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCheck: Record "Job Queue Entry";
    begin
        if CurrJobQueueEntry."Job Queue Category Code" = '' then
            exit;
        JobQueueEntry.SetLoadFields(ID);
        JobQueueEntry.ReadIsolation(JobQueueEntry.ReadIsolation::ReadCommitted);
        JobQueueEntry.SetFilter(ID, '<>%1', CurrJobQueueEntry.ID);
        JobQueueEntry.SetRange("Job Queue Category Code", CurrJobQueueEntry."Job Queue Category Code");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange(Scheduled, false);
        JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntryCheck.ReadIsolation(IsolationLevel::UpdLock);
        if JobQueueEntry.FindSet() then
            repeat
                if JobQueueEntryCheck.Get(JobQueueEntry.ID) then
                    if JobQueueEntryCheck.IsExpired(CurrentDateTime) then
                        JobQueueEntryCheck.DeleteTask()
                    else
                        Reschedule(JobQueueEntryCheck);
            until JobQueueEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure MockTaskScheduler()
    begin
        TestMode := true;
    end;

    local procedure Reschedule(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Clear(JobQueueEntry."System Task ID"); // to avoid canceling this task, which has already been executed
        JobQueueEntry."Earliest Start Date/Time" := CalcInitialRunTime(JobQueueEntry, CurrentDateTime());
        OnRescheduleOnBeforeJobQueueEnqueue(JobQueueEntry);
        JobQueueEntry."System Task ID" := TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue Dispatcher", CODEUNIT::"Job Queue Error Handler", true, JobQueueEntry.CurrentCompany(), JobQueueEntry."Earliest Start Date/Time", JobQueueEntry.RecordId());
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
    end;

    local procedure RescheduleAsWaiting(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Commit();
        JobQueueEntry.RefreshLocked();
        Clear(JobQueueEntry."System Task ID"); // to avoid canceling this task, which has already been executed
        OnRescheduleOnBeforeJobQueueEnqueue(JobQueueEntry);
        JobQueueEntry."System Task ID" := TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue Dispatcher", CODEUNIT::"Job Queue Error Handler", false, JobQueueEntry.CurrentCompany(), JobQueueEntry."Earliest Start Date/Time", JobQueueEntry.RecordId());
        JobQueueEntry.Status := JobQueueEntry.Status::Waiting;
        JobQueueEntry.Modify();
    end;

    internal procedure ActivateNextJobInCategory(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntryToActivate: Record "Job Queue Entry";
    begin
        if JobQueueEntry."Job Queue Category Code" = '' then
            exit;
        JobQueueEntryToActivate.SetLoadFields(ID, "Job Queue Category Code", Status, "Entry No.", "Priority Within Category", "System Task ID");
        JobQueueEntryToActivate.ReadIsolation(IsolationLevel::ReadCommitted);
        JobQueueEntryToActivate.SetRange("Job Queue Category Code", JobQueueEntry."Job Queue Category Code");
        JobQueueEntryToActivate.SetRange(Status, JobQueueEntry.Status::Waiting);
        JobQueueEntryToActivate.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntryToActivate.SetCurrentKey("Job Queue Category Code", "Priority Within Category", "Entry No.");
        if JobQueueEntryToActivate.FindFirst() then
            if TaskScheduler.TaskExists(JobQueueEntryToActivate."System Task ID") then begin
                TaskScheduler.SetTaskReady(JobQueueEntryToActivate."System Task ID");
                JobQueueEntryToActivate.Status := JobQueueEntryToActivate.Status::Ready;
                JobQueueEntryToActivate.Modify();
            end;
    end;

    procedure CalcNextRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
        NewRunDate: Date;
        IsHandled: Boolean;
    begin
        if IsNextRecurringRunTimeCalculated(JobQueueEntry, StartingDateTime, NewRunDateTime) then
            exit(NewRunDateTime);

        if JobQueueEntry.IsNextRunDateFormulaSet() then begin
            NewRunDate := CalcDate(JobQueueEntry."Next Run Date Formula", DT2Date(StartingDateTime));
            exit(CreateDateTime(NewRunDate, JobQueueEntry."Starting Time"));
        end;

        if JobQueueEntry."No. of Minutes between Runs" > 0 then
            NewRunDateTime := AddMinutesToDateTime(StartingDateTime, JobQueueEntry."No. of Minutes between Runs")
        else begin
            if JobQueueEntry."Earliest Start Date/Time" <> 0DT then
                StartingDateTime := JobQueueEntry."Earliest Start Date/Time";
            NewRunDateTime := CreateDateTime(DT2Date(StartingDateTime) + 1, 0T);
        end;

        IsHandled := false;
        OnCalcNextRunTimeForRecurringJobOnAfterCalcNewRunDateTime(JobQueueEntry, NewRunDateTime, IsHandled);
        if IsHandled then
            exit(NewRunDateTime);

        exit(CalcRunTimeForRecurringJob(JobQueueEntry, NewRunDateTime));
    end;

    procedure CalcNextRunTimeHoldDuetoInactivityJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
    begin
        NewRunDateTime := AddMinutesToDateTime(StartingDateTime, JobQueueEntry."Inactivity Timeout Period");
        exit(CalcRunTimeForRecurringJob(JobQueueEntry, NewRunDateTime));
    end;

    procedure CalcNextReadyStateMoment(JobQueueEntry: Record "Job Queue Entry"): DateTime
    begin
        exit(AddMinutesToDateTime(JobQueueEntry."Last Ready State", JobQueueEntry."No. of Minutes between Runs"));
    end;

    procedure CalcInitialRunTime(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        EarliestPossibleRunTime: DateTime;
        IsHandled: Boolean;
    begin
        if (JobQueueEntry."Earliest Start Date/Time" <> 0DT) and (JobQueueEntry."Earliest Start Date/Time" > StartingDateTime) then
            EarliestPossibleRunTime := JobQueueEntry."Earliest Start Date/Time"
        else
            EarliestPossibleRunTime := StartingDateTime;

        IsHandled := false;
        OnCalcInitialRunTimeOnAfterCalcEarliestPossibleRunTime(JobQueueEntry, EarliestPossibleRunTime, IsHandled);
        if IsHandled then
            exit(EarliestPossibleRunTime);

        if JobQueueEntry."Recurring Job" and not JobQueueEntry.IsNextRunDateFormulaSet() then
            exit(CalcRunTimeForRecurringJob(JobQueueEntry, EarliestPossibleRunTime));

        exit(EarliestPossibleRunTime);
    end;

    local procedure CalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime) NewRunDateTime: DateTime
    var
        RunOnDate: array[7] of Boolean;
        StartingWeekDay: Integer;
        NoOfExtraDays: Integer;
        NoOfDays: Integer;
        Found: Boolean;
    begin
        JobQueueEntry.TestField("Recurring Job");
        RunOnDate[1] := JobQueueEntry."Run on Mondays";
        RunOnDate[2] := JobQueueEntry."Run on Tuesdays";
        RunOnDate[3] := JobQueueEntry."Run on Wednesdays";
        RunOnDate[4] := JobQueueEntry."Run on Thursdays";
        RunOnDate[5] := JobQueueEntry."Run on Fridays";
        RunOnDate[6] := JobQueueEntry."Run on Saturdays";
        RunOnDate[7] := JobQueueEntry."Run on Sundays";
        OnCalcRunTimeForRecurringJobOnAfterInitDays(JobQueueEntry, StartingDateTime);
        NewRunDateTime := StartingDateTime;
        NoOfDays := 0;
        if (JobQueueEntry."Ending Time" <> 0T) and (NewRunDateTime > JobQueueEntry.GetEndingDateTime(NewRunDateTime)) then begin
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);
            NoOfDays := NoOfDays + 1;
        end;

        StartingWeekDay := Date2DWY(DT2Date(StartingDateTime), 1);
        Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        OnCalcRunTimeForRecurringJob(JobQueueEntry, RunOnDate, Found, StartingWeekDay, NoOfDays);
        NoOfExtraDays := 0;
        while not Found and (NoOfExtraDays < 7) do begin
            NoOfExtraDays := NoOfExtraDays + 1;
            NoOfDays := NoOfDays + 1;
            Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        end;

        if (JobQueueEntry."Starting Time" <> 0T) and (NewRunDateTime < JobQueueEntry.GetStartingDateTime(NewRunDateTime)) then
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);

        if (NoOfDays > 0) and (NewRunDateTime > JobQueueEntry.GetStartingDateTime(NewRunDateTime)) then
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);

        if (JobQueueEntry."Starting Time" = 0T) and (NoOfExtraDays > 0) and (JobQueueEntry."No. of Minutes between Runs" <> 0) then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime), 0T);

        if Found then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime) + NoOfDays, DT2Time(NewRunDateTime));

        OnAfterCalcRunTimeForRecurringJob(JobQueueEntry, Found, StartingDateTime, NewRunDateTime);
    end;

    local procedure IsNextRecurringRunTimeCalculated(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime) IsHandled: Boolean
    begin
        OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime, NewRunDateTime, IsHandled);
    end;

    local procedure SendTraceOnFailedToGetRecordBeforeFinalizingRecord(JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        // Failed to get record but insert all last known information into custom dimensions
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time"));
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));

        Session.LogMessage('0000HAI', JobQueueEntryFailedtoGetBeforeFinalizingTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    local procedure SendTraceOnFailedtoGetRecordBeforeUpdatingStatus(JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        // Failed to get record but insert all last known information into custom dimensions
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time"));
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));

        Session.LogMessage('0000HAK', JobQueueEntryFailedtoGetBeforeUpdatingStatusTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [Scope('OnPrem')]
    procedure AddMinutesToDateTime(SourceDateTime: DateTime; NoOfMinutes: Integer) NewDateTime: DateTime
    var
        MillisecondsToAdd: BigInteger;
    begin
        MillisecondsToAdd := NoOfMinutes;
        MillisecondsToAdd := MillisecondsToAdd * 60000;
        NewDateTime := SourceDateTime + MillisecondsToAdd;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; Found: Boolean; StartingDateTime: DateTime; var NewRunDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuccessHandleRequest(var JobQueueEntry: Record "Job Queue Entry"; JobQueueExecutionTime: Integer; PreviousTaskId: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuccessExecuteJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleRequest(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var Skip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry"; var JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcNextRunTimeForRecurringJobOnAfterCalcNewRunDateTime(var JobQueueEntry: Record "Job Queue Entry"; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInitialRunTimeOnAfterCalcEarliestPossibleRunTime(var JobQueueEntry: Record "Job Queue Entry"; var EarliestPossibleRunTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRescheduleOnBeforeJobQueueEnqueue(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRunTimeForRecurringJobOnAfterInitDays(var JobQueueEntry: Record "Job Queue Entry"; var StartingDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; var RunOnDate: array[7] of Boolean; var Found: Boolean; var StartingWeekDay: Integer; var NoOfDays: Integer)
    begin
    end;
}

