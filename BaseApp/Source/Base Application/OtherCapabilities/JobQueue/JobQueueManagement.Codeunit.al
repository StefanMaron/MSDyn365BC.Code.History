codeunit 456 "Job Queue Management"
{
    var
        TelemetrySubscribers: Codeunit "Telemetry Subscribers";
        RunOnceQst: label 'This will create a temporary non-recurrent copy of this job and will run it once in the foreground.\Do you want to continue?';
        ExecuteBeginMsg: label 'Executing job queue entry...';
        ExecuteEndSuccessMsg: label 'Job finished executing.\Status: %1', Comment = '%1 is a status value, e.g. Success';
        ExecuteEndErrorMsg: label 'Job finished executing.\Status: %1\Error: %2', Comment = '%1 is a status value, e.g. Success, %2=Error message';
        JobSomethingWentWrongMsg: Label 'Something went wrong and the job has stopped. Likely causes are system updates or routine maintenance processes. To restart the job, set the status to Ready.';
        JobQueueDelegatedAdminCategoryTxt: Label 'AL JobQueueEntries Delegated Admin', Locked = true;
        JobQueueStatusChangeTxt: Label 'The status for Job Queue Entry: %1 has changed.', Comment = '%1 is the Job Queue Entry Id', Locked = true;
        StaleJobQueueEntryTxt: Label 'Stale Job Queue Entry', Locked = true;
        StaleJobQueueLogEntryTxt: Label 'Stale Job Queue Log Entry', Locked = true;
        RunJobQueueOnceTxt: Label 'Running job queue once.', Locked = true;
        JobQueueWorkflowSetupErr: Label 'The Job Queue approval workflow has not been setup.';
        DelegatedAdminSendingApprovalLbl: Label 'Delegated admin sending approval', Locked = true;

    trigger OnRun()
    begin
    end;

    procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        EarliestStartDateTime: DateTime;
        ReportOutputType: Enum "Job Queue Report Output Type";
        ObjectTypeToRun: Option;
        ObjectIdToRun: Integer;
        NoOfMinutesBetweenRuns: Integer;
        RecurringJob: Boolean;
    begin
        NoOfMinutesBetweenRuns := JobQueueEntry."No. of Minutes between Runs";
        EarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";
        ReportOutputType := JobQueueEntry."Report Output Type";
        ObjectTypeToRun := JobQueueEntry."Object Type to Run";
        ObjectIdToRun := JobQueueEntry."Object ID to Run";

        with JobQueueEntry do begin
            SetRange("Object Type to Run", ObjectTypeToRun);
            SetRange("Object ID to Run", ObjectIdToRun);
            if NoOfMinutesBetweenRuns <> 0 then
                RecurringJob := true
            else
                RecurringJob := false;
            SetRange("Recurring Job", RecurringJob);
            if not IsEmpty() then
                exit;

            Init();
            Validate("Object Type to Run", ObjectTypeToRun);
            Validate("Object ID to Run", ObjectIdToRun);
            "Earliest Start Date/Time" := CurrentDateTime;
            if NoOfMinutesBetweenRuns <> 0 then begin
                Validate("Run on Mondays", true);
                Validate("Run on Tuesdays", true);
                Validate("Run on Wednesdays", true);
                Validate("Run on Thursdays", true);
                Validate("Run on Fridays", true);
                Validate("Run on Saturdays", true);
                Validate("Run on Sundays", true);
                Validate("Recurring Job", RecurringJob);
                "No. of Minutes between Runs" := NoOfMinutesBetweenRuns;
            end;
            "Maximum No. of Attempts to Run" := 3;
            "Notify On Success" := true;
            Status := Status::"On Hold";
            "Earliest Start Date/Time" := EarliestStartDateTime;
            "Report Output Type" := ReportOutputType;
            Insert(true);
        end;
    end;

    procedure DeleteJobQueueEntries(ObjectTypeToDelete: Option; ObjectIdToDelete: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", ObjectTypeToDelete);
            SetRange("Object ID to Run", ObjectIdToDelete);
            if FindSet() then
                repeat
                    if Status = Status::"In Process" then begin
                        // Non-recurring jobs will be auto-deleted after execution has completed.
                        "Recurring Job" := false;
                        Modify();
                    end else
                        Delete();
                until Next() = 0;
        end;
    end;

    procedure StartInactiveJobQueueEntries(ObjectTypeToStart: Option; ObjectIdToStart: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", ObjectTypeToStart);
            SetRange("Object ID to Run", ObjectIdToStart);
            SetRange(Status, Status::"On Hold");
            if FindSet() then
                repeat
                    SetStatus(Status::Ready);
                until Next() = 0;
        end;
    end;

    procedure SetJobQueueEntriesOnHold(ObjectTypeToSetOnHold: Option; ObjectIdToSetOnHold: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", ObjectTypeToSetOnHold);
            SetRange("Object ID to Run", ObjectIdToSetOnHold);
            if FindSet() then
                repeat
                    SetStatus(Status::"On Hold");
                until Next() = 0;
        end;
    end;

    procedure SetRecurringJobsOnHold(CompanyName: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ChangeCompany(CompanyName);
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet(true) then
            repeat
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
                JobQueueEntry.Modify();
            until JobQueueEntry.Next() = 0;
    end;

    procedure SetStatusToOnHoldIfInstanceInactiveFor(PeriodType: Option Day,Week,Month,Quarter,Year; NoOfPeriods: Integer; ObjectTypeToSetOnHold: Option; ObjectIdToSetOnHold: Integer): Boolean
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        PeriodFirstLetter: Text;
        FromDate: Date;
    begin
        PeriodFirstLetter := CopyStr(Format(PeriodType, 0, 0), 1, 1);
        FromDate := CalcDate(StrSubstNo('<-%1%2>', NoOfPeriods, PeriodFirstLetter));

        if not UserLoginTimeTracker.AnyUserLoggedInSinceDate(FromDate) then begin
            SetJobQueueEntriesOnHold(ObjectTypeToSetOnHold, ObjectIdToSetOnHold);
            exit(true);
        end;

        exit(false);
    end;

    procedure RunJobQueueEntryOnce(var SelectedJobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        SuccessDispatcher: Boolean;
        SuccessErrorHandler: Boolean;
        Window: Dialog;
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        if not Confirm(RunOnceQst, false) then
            exit;

        Window.Open(ExecuteBeginMsg);
        SelectedJobQueueEntry.CalcFields(XML);
        JobQueueEntry := SelectedJobQueueEntry;
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."User ID" := copystr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"Ready";
        JobQueueEntry."Job Queue Category Code" := '';
        clear(JobQueueEntry."Expiration Date/Time");
        clear(JobQueueEntry."System Task ID");
        JobQueueEntry.Insert(true);
        Commit();

        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        TelemetrySubscribers.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Session.LogMessage('0000FMG', RunJobQueueOnceTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);
        GlobalLanguage(CurrentLanguage);

        // Run the job queue
        SuccessDispatcher := Codeunit.run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);

        // If JQ fails, run the error handler
        if not SuccessDispatcher then begin
            SuccessErrorHandler := Codeunit.run(Codeunit::"Job Queue Error Handler", JobQueueEntry);

            // If the error handler fails, save the error (Non-AL errors will automatically surface to end-user)
            // If it is unable to save the error (No permission etc), it should also just be surfaced to the end-user.
            if not SuccessErrorHandler then begin
                JobQueueEntry.SetError(GetLastErrorText());
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry, GetLastErrorCallStack());
                Commit();
            end;
        end;

        Window.Close();
        if JobQueueEntry.Find() then
            if JobQueueEntry.Delete() then;
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.id);
        if JobQueueLogEntry.FindFirst() then
            if JobQueueLogEntry.Status = JobQueueLogEntry.Status::Success then
                Message(ExecuteEndSuccessMsg, JobQueueLogEntry.Status)
            else
                Message(ExecuteEndErrorMsg, JobQueueLogEntry.Status, JobQueueLogEntry."Error Message");
    end;

    internal procedure SendForApproval(var JobQueueEntry: Record "Job Queue Entry")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if ApprovalsMgmt.CheckJobQueueEntryApprovalEnabled() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            Commit();
            ApprovalsMgmt.OnSendJobQueueEntryForApproval(JobQueueEntry);
            FeatureTelemetry.LogUsage('0000JQE', JobQueueDelegatedAdminCategoryTxt, DelegatedAdminSendingApprovalLbl);
        end else begin
            FeatureTelemetry.LogError('0000JQD', JobQueueDelegatedAdminCategoryTxt, DelegatedAdminSendingApprovalLbl, JobQueueWorkflowSetupErr);
            Error(JobQueueWorkflowSetupErr);
        end;
    end;

    /// <summary>
    /// To find stale jobs (in process jobs with no scheduled tasks) and set them to error state.
    /// For both JQE and JQLE
    /// </summary>
    internal procedure FindStaleJobsAndSetError()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if JobQueueEntry.WritePermission() then begin
            // Find all in process job queue entries
            JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
            if JobQueueEntry.FindSet() then
                repeat
                    // Check if job is still running or stale
                    // JQE is stale if it has task no longer exists
                    // If stale, set to error
                    if not TaskScheduler.TaskExists(JobQueueEntry."System Task ID") then begin
                        JobQueueEntry.SetError(JobSomethingWentWrongMsg);

                        StaleJobQueueEntryTelemetry(JobQueueEntry);
                    end;
                until JobQueueEntry.Next() = 0;
        end;

        if JobQueueLogEntry.WritePermission() then begin
            // Find all in process job queue log entries
            JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
            if JobQueueLogEntry.FindSet() then
                repeat
                    // Check if job should be processed
                    if ShouldProcessStaleJobQueueLogEntries(JobQueueLogEntry) then
                        // Check if job is still running or stale
                        // JQLE is stale if it has no task or active session
                        // If stale, set to error
                        if not TaskScheduler.TaskExists(JobQueueLogEntry."System Task ID") or
                            HasNoActiveSession(JobQueueLogEntry."User Service Instance ID", JobQueueLogEntry."User Session ID") then begin
                            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
                            JobQueueLogEntry."Error Message" := JobSomethingWentWrongMsg;
                            JobQueueLogEntry.Modify();

                            StaleJobQueueLogEntryTelemetry(JobQueueLogEntry);
                        end;
                until JobQueueLogEntry.Next() = 0;
        end;
    end;

    local procedure HasNoActiveSession(ServerInstanceID: Integer; SessionID: Integer): Boolean
    var
        SessionEvent: Record "Session Event";
    begin
        SessionEvent.SetRange("Server Instance ID", ServerInstanceID);
        SessionEvent.SetRange("Session ID", SessionID);
        SessionEvent.SetRange("Event Type", SessionEvent."Event Type"::Logoff);
        exit(not SessionEvent.IsEmpty());
    end;

    local procedure StaleJobQueueEntryTelemetry(JobQueueEntry: Record "Job Queue Entry")
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        TelemetrySubscribers.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Session.LogMessage('0000FMH', StaleJobQueueEntryTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;

    local procedure StaleJobQueueLogEntryTelemetry(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        TelemetrySubscribers.SetJobQueueTelemetryDimensions(JobQueueLogEntry, Dimensions);

        Session.LogMessage('0000FMI', StaleJobQueueLogEntryTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;

    /// <summary>
    /// Due to certain usages of JQLE, we need to determine if the log entry is from normal usage
    /// Abnormal usages like assisted company setup should be ignored
    /// </summary>
    local procedure ShouldProcessStaleJobQueueLogEntries(JobQueueLogEntry: Record "Job Queue Log Entry") Process: Boolean
    begin
        // Default true, to process stale jobs
        Process := true;

        if JobQueueLogEntry."Object Type to Run" = JobQueueLogEntry."Object Type to Run"::Codeunit then
            case JobQueueLogEntry."Object ID to Run" of
                Codeunit::"Import Config. Package Files":
                    Process := false;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ScheduleReport', '', false, false)]
    local procedure ScheduleReport(ReportId: Integer; RequestPageXml: Text; var Scheduled: Boolean)
    var
        ScheduleAReport: Page "Schedule a Report";
    begin
        Scheduled := ScheduleAReport.ScheduleAReport(ReportId, RequestPageXml);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnStatusChanged(Rec: Record "Job Queue Entry"; xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec.Status = xRec.Status then
            exit;

        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        TelemetrySubscribers.SetJobQueueTelemetryDimensions(Rec, Dimensions);
        Dimensions.Add('JobQueueOldStatus', Format(xRec.Status));

        Session.LogMessage('0000FNM', JobQueueStatusChangeTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;
}

