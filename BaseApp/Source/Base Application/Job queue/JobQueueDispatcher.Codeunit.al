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

        SelectLatestVersion;
        Get(ID);
        if not IsReadyToStart then
            exit;

        if IsExpired(CurrentDateTime) then
            DeleteTask
        else
            if WaitForOthersWithSameCategory(Rec) then
                Reschedule(Rec)
            else
                HandleRequest(Rec);
        Commit();
    end;

    var
        JobQueueContextTxt: Label 'Job Queue', Locked = true;

    local procedure HandleRequest(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        WasSuccess: Boolean;
        PrevStatus: Option;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageRegisterId: Guid;
    begin
        JobQueueEntry.RefreshLocked;
        if not JobQueueEntry.IsReadyToStart then
            exit;

        OnBeforeHandleRequest(JobQueueEntry);

        with JobQueueEntry do begin
            if Status in [Status::Ready, Status::"On Hold with Inactivity Timeout"] then begin
                Status := Status::"In Process";
                "User Session Started" := CurrentDateTime;
                Modify;
            end;
            InsertLogEntry(JobQueueLogEntry);

            // Codeunit.Run is limited during write transactions because one or more tables will be locked.
            // To avoid NavCSideException we have either to add the COMMIT before the call or do not use a returned value.
            Commit();
            OnBeforeExecuteJob(JobQueueEntry);
            ErrorMessageManagement.Activate(ErrorMessageHandler);
            ErrorMessageManagement.PushContext(ErrorContextElement, RecordId, 0, JobQueueContextTxt);
            WasSuccess := CODEUNIT.Run(CODEUNIT::"Job Queue Start Codeunit", JobQueueEntry);
            if not WasSuccess then
                ErrorMessageRegisterId := ErrorMessageHandler.RegisterErrorMessages();
            OnAfterExecuteJob(JobQueueEntry, WasSuccess);
            PrevStatus := Status;

            // user may have deleted it in the meantime
            if DoesExistLocked then
                SetResult(WasSuccess, PrevStatus, ErrorMessageRegisterId)
            else
                SetResultDeletedEntry;
            Commit();
            FinalizeLogEntry(JobQueueLogEntry);

            if DoesExistLocked then
                FinalizeRun;
        end;

        OnAfterHandleRequest(JobQueueEntry, WasSuccess);
    end;

    local procedure WaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        OnBeforeWaitForOthersWithSameCategory(CurrJobQueueEntry, JobQueueEntry);

        if CurrJobQueueEntry."Job Queue Category Code" = '' then
            exit(false);

        // Use the Job Queue Category as a semaphore so only one checks at the time.
        JobQueueCategory.LockTable();
        if not JobQueueCategory.Get(CurrJobQueueEntry."Job Queue Category Code") then
            exit(false);

        with JobQueueEntry do begin
            SetFilter(ID, '<>%1', CurrJobQueueEntry.ID);
            SetRange("Job Queue Category Code", CurrJobQueueEntry."Job Queue Category Code");
            SetRange(Status, Status::"In Process");
            exit(not IsEmpty);
        end;
    end;

    local procedure Reschedule(var JobQueueEntry: Record "Job Queue Entry")
    begin
        with JobQueueEntry do begin
            RefreshLocked;
            Randomize;
            Clear("System Task ID"); // to avoid canceling this task, which has already been executed
            "Earliest Start Date/Time" := CurrentDateTime + 2000 + Random(5000);
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        end;
    end;

    procedure CalcNextRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
        NewRunDate: Date;
    begin
        if IsNextRecurringRunTimeCalculated(JobQueueEntry, StartingDateTime, NewRunDateTime) then
            exit(NewRunDateTime);

        if JobQueueEntry.IsNextRunDateFormulaSet then begin
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
    begin
        if (JobQueueEntry."Earliest Start Date/Time" <> 0DT) and (JobQueueEntry."Earliest Start Date/Time" > StartingDateTime) then
            EarliestPossibleRunTime := JobQueueEntry."Earliest Start Date/Time"
        else
            EarliestPossibleRunTime := StartingDateTime;

        if JobQueueEntry."Recurring Job" and not JobQueueEntry.IsNextRunDateFormulaSet then
            exit(CalcRunTimeForRecurringJob(JobQueueEntry, EarliestPossibleRunTime));

        exit(EarliestPossibleRunTime);
    end;

    local procedure CalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
        RunOnDate: array[7] of Boolean;
        StartingWeekDay: Integer;
        NoOfExtraDays: Integer;
        NoOfDays: Integer;
        Found: Boolean;
    begin
        with JobQueueEntry do begin
            TestField("Recurring Job");
            RunOnDate[1] := "Run on Mondays";
            RunOnDate[2] := "Run on Tuesdays";
            RunOnDate[3] := "Run on Wednesdays";
            RunOnDate[4] := "Run on Thursdays";
            RunOnDate[5] := "Run on Fridays";
            RunOnDate[6] := "Run on Saturdays";
            RunOnDate[7] := "Run on Sundays";

            NewRunDateTime := StartingDateTime;
            NoOfDays := 0;
            if ("Ending Time" <> 0T) and (NewRunDateTime > GetEndingDateTime(NewRunDateTime)) then begin
                NewRunDateTime := GetStartingDateTime(NewRunDateTime);
                NoOfDays := NoOfDays + 1;
            end;

            StartingWeekDay := Date2DWY(DT2Date(StartingDateTime), 1);
            Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
            while not Found and (NoOfExtraDays < 7) do begin
                NoOfExtraDays := NoOfExtraDays + 1;
                NoOfDays := NoOfDays + 1;
                Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
            end;

            if ("Starting Time" <> 0T) and (NewRunDateTime < GetStartingDateTime(NewRunDateTime)) then
                NewRunDateTime := GetStartingDateTime(NewRunDateTime);

            if (NoOfDays > 0) and (NewRunDateTime > GetStartingDateTime(NewRunDateTime)) then
                NewRunDateTime := GetStartingDateTime(NewRunDateTime);

            if ("Starting Time" = 0T) and (NoOfExtraDays > 0) and ("No. of Minutes between Runs" <> 0) then
                NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime), 0T);

            if Found then
                NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime) + NoOfDays, DT2Time(NewRunDateTime));
        end;
        exit(NewRunDateTime);
    end;

    local procedure IsNextRecurringRunTimeCalculated(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime) IsHandled: Boolean
    begin
        OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime, NewRunDateTime, IsHandled);
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
    local procedure OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleRequest(var JobQueueEntry: Record "Job Queue Entry"; WasSuccess: Boolean)
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
    local procedure OnAfterExecuteJob(var JobQueueEntry: Record "Job Queue Entry"; WasSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var Skip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

