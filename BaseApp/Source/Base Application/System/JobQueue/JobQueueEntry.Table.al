﻿namespace System.Threading;

using Microsoft.Foundation.Reporting;
using System.DateTime;
using System.Telemetry;
using System.Device;
using System.Environment;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 472 "Job Queue Entry"
{
    Caption = 'Job Queue Entry';
    DataCaptionFields = "Object Type to Run", "Object ID to Run", "Object Caption to Run";
    DrillDownPageID = "Job Queue Entries";
    LookupPageID = "Job Queue Entries";
    Permissions = TableData "Job Queue Entry" = rimd,
                  TableData "Job Queue Log Entry" = rimd;
    ReplicateData = false;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "User ID"; Text[65])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(3; XML; BLOB)
        {
            Caption = 'XML';
        }
        field(4; "Last Ready State"; DateTime)
        {
            Caption = 'Last Ready State';
            Editable = false;
        }
        field(5; "Expiration Date/Time"; DateTime)
        {
            Caption = 'Expiration Date/Time';

            trigger OnLookup()
            begin
                Validate("Expiration Date/Time", LookupDateTime("Expiration Date/Time", "Earliest Start Date/Time", 0DT));
            end;

            trigger OnValidate()
            begin
                CheckStartAndExpirationDateTime();
            end;
        }
        field(6; "Earliest Start Date/Time"; DateTime)
        {
            Caption = 'Earliest Start Date/Time';

            trigger OnLookup()
            begin
                Validate("Earliest Start Date/Time", LookupDateTime("Earliest Start Date/Time", 0DT, "Expiration Date/Time"));
            end;

            trigger OnValidate()
            begin
                CheckStartAndExpirationDateTime();
                if "Earliest Start Date/Time" <> xRec."Earliest Start Date/Time" then
                    Reschedule();
            end;
        }
        field(7; "Object Type to Run"; Option)
        {
            Caption = 'Object Type to Run';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit';
            OptionMembers = ,,,"Report",,"Codeunit";

            trigger OnValidate()
            begin
                if "Object Type to Run" <> xRec."Object Type to Run" then
                    Validate("Object ID to Run", 0);
            end;
        }
        field(8; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("Object Type to Run"));

            trigger OnLookup()
            var
                NewObjectID: Integer;
            begin
                if LookupObjectID(NewObjectID) then
                    Validate("Object ID to Run", NewObjectID);
            end;

            trigger OnValidate()
            var
                AllObj: Record AllObj;
            begin
                if "Object ID to Run" <> xRec."Object ID to Run" then begin
                    Clear(XML);
                    Clear(Description);
                    Clear("Parameter String");
                    Clear("Report Request Page Options");
                end;
                if "Object ID to Run" = 0 then
                    exit;
                if not AllObj.Get("Object Type to Run", "Object ID to Run") then
                    Error(ObjNotFoundErr, "Object ID to Run");

                CalcFields("Object Caption to Run");
                if Description = '' then
                    Description := GetDefaultDescription();

                if "Object Type to Run" <> "Object Type to Run"::Report then
                    exit;
                if REPORT.DefaultLayout("Object ID to Run") = DEFAULTLAYOUT::None then // Processing-only
                    "Report Output Type" := "Report Output Type"::"None (Processing only)"
                else begin
                    "Report Output Type" := "Report Output Type"::PDF;
                    if REPORT.DefaultLayout("Object ID to Run") = DEFAULTLAYOUT::Word then
                        "Report Output Type" := "Report Output Type"::Word;
                end;
            end;
        }
        field(9; "Object Caption to Run"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type to Run"),
                                                                           "Object ID" = field("Object ID to Run")));
            Caption = 'Object Caption to Run';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Report Output Type"; Enum "Job Queue Report Output Type")
        {
            Caption = 'Report Output Type';

            trigger OnValidate()
            var
                ReportLayoutSelection: Record "Report Layout Selection";
                InitServerPrinterTable: Codeunit "Init. Server Printer Table";
                EnvironmentInfo: Codeunit "Environment Information";
            begin
                TestField("Object Type to Run", "Object Type to Run"::Report);

                if REPORT.DefaultLayout("Object ID to Run") = DEFAULTLAYOUT::None then // Processing-only
                    TestField("Report Output Type", "Report Output Type"::"None (Processing only)")
                else begin
                    if "Report Output Type" = "Report Output Type"::"None (Processing only)" then
                        Error(ReportOutputTypeCannotBeNoneErr);
                    if ReportLayoutSelection.HasCustomLayout("Object ID to Run") = 2 then // Word layout
                        if not ("Report Output Type" in ["Report Output Type"::Print, "Report Output Type"::Word, "Report Output Type"::PDF]) then
                            Error(CustomLayoutReportCanHaveLimitedOutputTypeErr);
                end;
                if "Report Output Type" = "Report Output Type"::Print then begin
                    if EnvironmentInfo.IsSaaS() then begin
                        "Report Output Type" := "Report Output Type"::PDF;
                        Message(NoPrintOnSaaSMsg);
                    end else
                        "Printer Name" := InitServerPrinterTable.FindClosestMatchToClientDefaultPrinter("Object ID to Run");
                end else
                    "Printer Name" := '';
            end;
        }
        field(11; "Maximum No. of Attempts to Run"; Integer)
        {
            Caption = 'Maximum No. of Attempts to Run';
        }
        field(12; "No. of Attempts to Run"; Integer)
        {
            Caption = 'No. of Attempts to Run';
            Editable = false;
        }
        field(13; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Ready,In Process,Error,On Hold,Finished,On Hold with Inactivity Timeout';
            OptionMembers = Ready,"In Process",Error,"On Hold",Finished,"On Hold with Inactivity Timeout";
        }
        field(14; Priority; Integer)
        {
            Caption = 'Priority';
            InitValue = 1000;
            ObsoleteState = Removed;
            ObsoleteReason = 'No longer supported.';
            ObsoleteTag = '15.0';
        }
        field(15; "Record ID to Process"; RecordID)
        {
            Caption = 'Record ID to Process';
            DataClassification = CustomerContent;
        }
        field(16; "Parameter String"; Text[250])
        {
            Caption = 'Parameter String';
        }
        field(17; "Recurring Job"; Boolean)
        {
            Caption = 'Recurring Job';
        }
        field(18; "No. of Minutes between Runs"; Integer)
        {
            Caption = 'No. of Minutes between Runs';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
                SetMinimumNumberOfMinutesBetweenRuns();
            end;
        }
        field(19; "Run on Mondays"; Boolean)
        {
            Caption = 'Run on Mondays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(20; "Run on Tuesdays"; Boolean)
        {
            Caption = 'Run on Tuesdays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(21; "Run on Wednesdays"; Boolean)
        {
            Caption = 'Run on Wednesdays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(22; "Run on Thursdays"; Boolean)
        {
            Caption = 'Run on Thursdays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(23; "Run on Fridays"; Boolean)
        {
            Caption = 'Run on Fridays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(24; "Run on Saturdays"; Boolean)
        {
            Caption = 'Run on Saturdays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(25; "Run on Sundays"; Boolean)
        {
            Caption = 'Run on Sundays';

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetRecurringField();
            end;
        }
        field(26; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                TestField("Recurring Job");
                if "Starting Time" = 0T then
                    "Reference Starting Time" := 0DT
                else
                    "Reference Starting Time" := CreateDateTime(DMY2Date(1, 1, 2000), "Starting Time");
            end;
        }
        field(27; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                TestField("Recurring Job");
            end;
        }
        field(28; "Reference Starting Time"; DateTime)
        {
            Caption = 'Reference Starting Time';
            Editable = false;

            trigger OnValidate()
            begin
                "Starting Time" := DT2Time("Reference Starting Time");
            end;
        }
        field(29; "Next Run Date Formula"; DateFormula)
        {
            Caption = 'Next Run Date Formula';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
            begin
                Clear("No. of Minutes between Runs");
                ClearRunOnWeekdays();
                SetRecurringField();
                if IsNextRunDateFormulaSet() and ("Earliest Start Date/Time" = 0DT) then
                    "Earliest Start Date/Time" := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(Rec, CurrentDateTime);
            end;
        }
        field(30; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(31; "Run in User Session"; Boolean)
        {
            Caption = 'Run in User Session';
            Editable = false;
        }
        field(32; "User Session ID"; Integer)
        {
            Caption = 'User Session ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(33; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            TableRelation = "Job Queue Category";
        }
        field(34; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
        field(35; "Error Message 2"; Text[250])
        {
            Caption = 'Error Message 2';
            ObsoleteReason = 'Error Message field size has been increased.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(36; "Error Message 3"; Text[250])
        {
            Caption = 'Error Message 3';
            ObsoleteReason = 'Error Message field size has been increased.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(37; "Error Message 4"; Text[250])
        {
            Caption = 'Error Message 4';
            ObsoleteReason = 'Error Message field size has been increased.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(40; "User Service Instance ID"; Integer)
        {
            Caption = 'User Service Instance ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(41; "User Session Started"; DateTime)
        {
            Caption = 'User Session Started';
            Editable = false;
        }
        field(42; "Timeout (sec.)"; Integer)
        {
            Caption = 'Timeout (sec.)';
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'No longer supported.';
            ObsoleteTag = '15.0';
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
        }
        field(44; "User Language ID"; Integer)
        {
            Caption = 'User Language ID';
        }
        field(45; "Printer Name"; Text[250])
        {
            Caption = 'Printer Name';

            trigger OnLookup()
            var
                Printer: Record Printer;
                ServerPrinters: Page "Server Printers";
            begin
                ServerPrinters.SetSelectedPrinterName("Printer Name");
                if ServerPrinters.RunModal() = ACTION::OK then begin
                    ServerPrinters.GetRecord(Printer);
                    "Printer Name" := Printer.ID;
                end;
            end;

            trigger OnValidate()
            var
                InitServerPrinterTable: Codeunit "Init. Server Printer Table";
            begin
                TestField("Report Output Type", "Report Output Type"::Print);
                if "Printer Name" = '' then
                    exit;
                InitServerPrinterTable.ValidatePrinterName("Printer Name");
            end;
        }
        field(46; "Report Request Page Options"; Boolean)
        {
            Caption = 'Report Request Page Options';

            trigger OnValidate()
            begin
                if "Report Request Page Options" then
                    RunReportRequestPage()
                else begin
                    Clear(XML);
                    Message(RequestPagesOptionsDeletedMsg);
                    "User ID" := UserId();
                end;
            end;
        }
        field(47; "Rerun Delay (sec.)"; Integer)
        {
            Caption = 'Rerun Delay (sec.)';
            MaxValue = 3600;
            MinValue = 0;
        }
        field(48; "System Task ID"; Guid)
        {
            Caption = 'System Task ID';
        }
        field(49; Scheduled; Boolean)
        {
            CalcFormula = exist("Scheduled Task" where(ID = field("System Task ID")));
            Caption = 'Scheduled';
            FieldClass = FlowField;
        }
        field(50; "Manual Recurrence"; Boolean)
        {
            Caption = 'Manual Recurrence';
        }
        field(51; "On Hold Due to Inactivity"; Boolean)
        {
            Caption = 'On Hold Due to Inactivity';
            ObsoleteReason = 'Functionality moved into new job queue status';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(52; "Inactivity Timeout Period"; Integer)
        {
            Caption = 'Inactivity Timeout Period';
            MinValue = 5;
            InitValue = 5;
        }
        field(53; "Error Message Register Id"; Guid)
        {
            Caption = 'Error Message Register Id';
            DataClassification = SystemMetadata;
            TableRelation = "Error Message Register".ID;
        }
        field(54; "Job Timeout"; Duration)
        {
            Caption = 'Job Timeout';
            DataClassification = SystemMetadata;
        }
        field(55; "Recovery Task Id"; Guid)
        {
            Caption = 'Recovery Task Id';
            Editable = false;
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
            ObsoleteReason = 'The recovery job is no longer needed.';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Job Queue Category Code")
        {
            IncludedFields = Status, "User ID", "System Task ID", "Object Type to Run", "Object ID to Run", "Earliest Start Date/Time";
        }
        key(Key3; "Last Ready State")
        {
        }
        key(Key4; "Recurring Job")
        {
        }
        key(Key5; "System Task ID")
        {
        }
        key(Key6; "User ID", Status, "Recurring Job")
        {
        }
        key(Key7; "Object ID to Run", "Object Type to Run")
        {
            IncludedFields = Status, "User ID", "System Task ID", "Job Queue Category Code", "Earliest Start Date/Time";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Status = Status::"In Process" then
            Error(CannotDeleteEntryErr, Status);
        CancelTask();
    end;

    trigger OnInsert()
    var
        SetupUserId: Boolean;
    begin
        if IsNullGuid(ID) then
            ID := CreateGuid();
        SetupUserId := true;
        OnInsertOnBeforeSetDefaultValues(Rec, SetupUserId);

        SetDefaultValues(SetupUserId);
        SetMinimumNumberOfMinutesBetweenRuns();
    end;

    trigger OnModify()
    var
        RunParametersChanged: Boolean;
    begin
        RunParametersChanged := AreRunParametersChanged();
        OnModifyOnAfterRunParametersChangedCalculated(Rec, xRec, RunParametersChanged);
        if RunParametersChanged then
            Reschedule();
        SetDefaultValues(RunParametersChanged);
        SetMinimumNumberOfMinutesBetweenRuns();
    end;

    var
        NoErrMsg: Label 'There is no error message.';
        CannotDeleteEntryErr: Label 'You cannot delete an entry that has status %1.', Comment = '%1 is a status value, such as Success or Error.';
        DeletedEntryErr: Label 'The job queue entry has been deleted.';
        ScheduledForPostingMsg: Label 'Scheduled for posting on %1 by %2.', Comment = '%1=a date, %2 = a user.';
        NoRecordErr: Label 'No record is associated with the job queue entry.';
        RequestPagesOptionsDeletedMsg: Label 'You have cleared the report parameters. Select the check box in the field to show the report request page again.';
        ExpiresBeforeStartErr: Label '%1 must be later than %2.', Comment = '%1 = Expiration Date, %2=Start date';
        UserSessionJobsCannotBeRecurringErr: Label 'You cannot set up recurring user session job queue entries.';
        NoPrintOnSaaSMsg: Label 'You cannot select a printer from this online product. Instead, save as PDF, or another format, which you can print later.\\The output type has been set to PDF.';
        LastJobQueueLogEntryNo: Integer;
        ObjNotFoundErr: Label 'There is no Object with ID %1.', Comment = '%1=Object Id.';
        NoPermissionsErr: Label 'You are not allowed to schedule background tasks. Ask your system administrator to give you permission to do so. Specifically, you need Insert, Modify and Delete Permissions for the %1 table.', Comment = '%1 Table Name';
        ReportOutputTypeCannotBeNoneErr: Label 'You cannot set the report output to None because users can view the report. Use the None option when the report does something in the background. For example, when it is part of a batch job.';
        CustomLayoutReportCanHaveLimitedOutputTypeErr: Label 'This report uses a custom layout. To view the report you can open it in Word, print it, or save it as PDF.';

    procedure DoesExistLocked(): Boolean
    begin
        LockTable();
        exit(Get(ID));
    end;

    procedure RefreshLocked()
    begin
        SetLoadFields();
        LockTable();
        Get(ID);
    end;

    procedure IsExpired(AtDateTime: DateTime): Boolean
    begin
        exit((AtDateTime <> 0DT) and ("Expiration Date/Time" <> 0DT) and ("Expiration Date/Time" < AtDateTime));
    end;

    procedure IsReadyToStart() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsReadyToStart(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(Status in [Status::Ready, Status::"In Process", Status::"On Hold with Inactivity Timeout"]);
    end;

    procedure ShowErrorMessage()
    var
        ErrorMessage: Record "Error Message";
        ErrorMessages: Page "Error Messages";
    begin
        ErrorMessage.SetRange("Register ID", "Error Message Register Id");
        if not IsNullGuid("Error Message Register Id") and ErrorMessage.FindSet() then begin
            ErrorMessages.SetRecords(ErrorMessage);
            ErrorMessages.Run();
        end else
            if "Error Message" = '' then
                Message(NoErrMsg)
            else
                Message("Error Message");
    end;

    procedure SetError(ErrorText: Text)
    begin
        RefreshLocked();
        "Error Message" := CopyStr(ErrorText, 1, 2048);
        ClearServiceValues();
        SetStatusValue(Status::Error);
    end;

    internal procedure SetResult(PrevStatus: Option)
    begin
        if (Rec.Status = Status::"On Hold") or Rec."Manual Recurrence" then
            exit;

        if "Recurring Job" and (PrevStatus in [Status::"On Hold", Status::"On Hold with Inactivity Timeout"]) then
            Status := PrevStatus
        else
            Status := Status::Finished;
        Rec.Modify();
    end;

    procedure SetResult(IsSuccess: Boolean; PrevStatus: Option; ErrorMessageRegisterId: Guid)
    var
        ErrorMessage: Record "Error Message";
    begin
        if (Status = Status::"On Hold") or "Manual Recurrence" then
            exit;
        if IsSuccess then
            if "Recurring Job" and (PrevStatus in [Status::"On Hold", Status::"On Hold with Inactivity Timeout"]) then
                Status := PrevStatus
            else
                Status := Status::Finished
        else begin
            Status := Status::Error;
            if not IsNullGuid(ErrorMessageRegisterId) then begin
                "Error Message Register Id" := ErrorMessageRegisterId;
                ErrorMessage.SetRange("Register ID", ErrorMessageRegisterId);
                if ErrorMessage.FindFirst() then
                    "Error Message" := ErrorMessage."Message"
                else
                    "Error Message" := GetLastErrorText();
            end else
                "Error Message" := GetLastErrorText();
        end;
        Modify();
    end;

    procedure SetResultDeletedEntry()
    begin
        Status := Status::Error;
        "Error Message" := DeletedEntryErr;
        Modify();
    end;

    procedure FinalizeRun()
    begin
        case Status of
            Status::Finished, Status::"On Hold with Inactivity Timeout":
                CleanupAfterExecution();
            Status::Error:
                HandleExecutionError();
        end;

        OnAfterFinalizeRun(Rec);
    end;

    procedure GetLastLogEntryNo(): Integer
    begin
        exit(LastJobQueueLogEntryNo);
    end;

    procedure InsertLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := Rec.ID;
        JobQueueLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueLogEntry."User ID"));
        JobQueueLogEntry."Parameter String" := Rec."Parameter String";
        JobQueueLogEntry."Start Date/Time" := Rec."User Session Started";
        JobQueueLogEntry."Object Type to Run" := Rec."Object Type to Run";
        JobQueueLogEntry."Object ID to Run" := Rec."Object ID to Run";
        JobQueueLogEntry.Description := Rec.Description;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry."Job Queue Category Code" := Rec."Job Queue Category Code";
        JobQueueLogEntry."System Task Id" := Rec."System Task ID";
        JobQueueLogEntry."User Session ID" := Rec."User Session ID";
        JobQueueLogEntry."User Service Instance ID" := Rec."User Service Instance ID";
        Rec.CalcFields(XML);
        JobQueueLogEntry.XML := Rec.XML;
        OnBeforeInsertLogEntry(JobQueueLogEntry, Rec);
        JobQueueLogEntry.Insert(true);
        LastJobQueueLogEntryNo := JobQueueLogEntry."Entry No.";
    end;

    procedure FinalizeLogEntry(JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
        FinalizeLogEntry(JobQueueLogEntry, '');
    end;

    procedure FinalizeLogEntry(JobQueueLogEntry: Record "Job Queue Log Entry"; LastErrorCallStack: Text)
    begin
        if Rec.Status = Status::Error then begin
            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
            JobQueueLogEntry."Error Message" := Rec."Error Message";
            if LastErrorCallStack <> '' then
                JobQueueLogEntry.SetErrorCallStack(LastErrorCallstack)
            else
                JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallstack());
            JobQueueLogEntry."Error Message Register Id" := Rec."Error Message Register Id";
        end else
            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Success;
        JobQueueLogEntry."End Date/Time" := CurrentDateTime();
        OnBeforeModifyLogEntry(JobQueueLogEntry, Rec);
        JobQueueLogEntry.Modify(true);
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        if NewStatus = Status then
            exit;
        RefreshLocked();
        ClearServiceValues();
        SetStatusValue(NewStatus);
    end;

    procedure Cancel()
    begin
        if DoesExistLocked() then
            DeleteTask();
    end;

    procedure DeleteTask()
    begin
        Status := Status::Finished;
        Delete(true);
    end;

    procedure DeleteTasks()
    begin
        if FindSet() then
            repeat
                DeleteTask();
            until Next() = 0;
    end;

    procedure Restart()
    begin
        OnBeforeRestart(Rec);
        RefreshLocked();
        ClearServiceValues();
        if (Status = Status::"On Hold with Inactivity Timeout") and ("Inactivity Timeout Period" > 0) then
            "Earliest Start Date/Time" := CurrentDateTime();
        Status := Status::"On Hold";
        SetStatusValue(Status::Ready);
    end;

    local procedure EnqueueTask()
    begin
        CheckRequiredPermissions();
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", Rec);
    end;

    procedure CheckRequiredPermissions()
    var
        DummyJobQueueLogEntry: Record "Job Queue Log Entry";
        DummyErrorMessageRegister: Record "Error Message Register";
        DummyErrorMessage: Record "Error Message";
    begin
        if not DummyJobQueueLogEntry.WritePermission() then
            Error(NoPermissionsErr, DummyJobQueueLogEntry.TableName());

        if not DummyErrorMessageRegister.WritePermission() then
            Error(NoPermissionsErr, DummyErrorMessageRegister.TableName());

        if not DummyErrorMessage.WritePermission() then
            Error(NoPermissionsErr, DummyErrorMessage.TableName());
    end;

    procedure HasRequiredPermissions(): Boolean
    var
        DummyJobQueueLogEntry: Record "Job Queue Log Entry";
        DummyErrorMessageRegister: Record "Error Message Register";
        DummyErrorMessage: Record "Error Message";
    begin
        if not DummyJobQueueLogEntry.WritePermission() then
            exit(false);

        if not DummyErrorMessageRegister.WritePermission() then
            exit(false);

        if not DummyErrorMessage.WritePermission() then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    internal procedure TryCheckRequiredPermissions()
    begin
        CheckRequiredPermissions();
    end;

    procedure CancelTask()
    var
        ScheduledTask: Record "Scheduled Task";
        TelemetrySubscribers: Codeunit "Telemetry Subscribers";
    begin
        if not IsNullGuid("System Task ID") then begin
            if ScheduledTask.Get("System Task ID") then begin
                TASKSCHEDULER.CancelTask("System Task ID");
                TelemetrySubscribers.SendTraceOnJobQueueEntryScheduledTaskCancelled(Rec);
            end;
            Clear("System Task ID");
        end;
    end;

    procedure ScheduleTask(): Guid
    var
        TaskGUID: Guid;
        IsHandled: Boolean;
        JobTimeout: Duration;
        ShouldChangeUserID: Boolean;
    begin
        CheckRequiredPermissions();
        ShouldChangeUserID := "User ID" <> UserId();
        OnScheduleTaskOnAfterCalcShouldChangeUserID(Rec, ShouldChangeUserID);
        if ShouldChangeUserID then begin
            "User ID" := UserId();
            Modify(true);
        end;
        IsHandled := false;
        OnBeforeScheduleTask(Rec, TaskGUID, IsHandled);
        if IsHandled then
            exit(TaskGUID);

        if not IsNullGuid(TaskGUID) then
            exit(TaskGUID);

        if Rec."Job Timeout" <> 0 then
            JobTimeout := Rec."Job Timeout"
        else
            JobTimeout := DefaultJobTimeout();

        exit(
          TASKSCHEDULER.CreateTask(
            CODEUNIT::"Job Queue Dispatcher",
            CODEUNIT::"Job Queue Error Handler",
            true, CurrentCompany(), "Earliest Start Date/Time", RecordId(), JobTimeout));
    end;

    procedure DefaultJobTimeout(): Duration
    begin
        exit(12 * 60 * 60 * 1000); // 12 hours
    end;

    local procedure Reschedule()
    begin
        CancelTask();
        if Status in [Status::Ready, Status::"On Hold with Inactivity Timeout"] then begin
            SetDefaultValues(false);
            EnqueueTask();
        end;

        OnAfterReschedule(Rec);
    end;

    procedure ReuseExistingJobFromID(JobID: Guid; ExecutionDateTime: DateTime): Boolean
    begin
        if Get(JobID) then begin
            if not (Status in [Status::Ready, Status::"In Process"]) then begin
                "Earliest Start Date/Time" := ExecutionDateTime;
                SetStatus(Status::Ready);
            end;

            OnReuseExisingJobFromId(Rec);

            exit(true);
        end;

        exit(false);
    end;

    procedure ReuseExistingJobFromCategory(JobQueueCategoryCode: Code[10]; ExecutionDateTime: DateTime): Boolean
    begin
        SetRange("Job Queue Category Code", JobQueueCategoryCode);
        if FindFirst() then
            exit(ReuseExistingJobFromID(ID, ExecutionDateTime));

        exit(false);
    end;

    procedure ReuseExistingJobFromCategoryAndUser(JobQueueCategoryCode: Code[10]; UserId: Text; ExecutionDateTime: DateTime): Boolean
    begin
        Rec.SetRange("Job Queue Category Code", JobQueueCategoryCode);
        Rec.SetRange("User ID", CopyStr(UserId, 1, MaxStrLen(Rec."User ID")));
        if Rec.FindFirst() then
            exit(ReuseExistingJobFromID(Rec.ID, ExecutionDateTime));

        exit(false);
    end;

    internal procedure ReuseExistingJobFromCategoryAndParamString(JobQueueCategoryCode: Code[10]; ParamString: Text[250]; ExecutionDateTime: DateTime): Boolean
    begin
        Rec.SetRange("Job Queue Category Code", JobQueueCategoryCode);
        Rec.SetRange("Parameter String", ParamString);
        if Rec.FindFirst() then
            exit(ReuseExistingJobFromID(Rec.ID, ExecutionDateTime));

        exit(false);
    end;

    internal procedure ReuseExistingJobFromUserCategoryAndParamString(UserId: Text; JobQueueCategoryCode: Code[10]; ParamString: Text[250]; ExecutionDateTime: DateTime): Boolean
    begin
        Rec.SetRange("User ID", CopyStr(UserId, 1, MaxStrLen(Rec."User ID")));
        Rec.SetRange("Job Queue Category Code", JobQueueCategoryCode);
        Rec.SetRange("Parameter String", ParamString);
        if Rec.FindFirst() then
            exit(ReuseExistingJobFromID(Rec.ID, ExecutionDateTime));

        exit(false);
    end;

    local procedure AreRunParametersChanged(): Boolean
    begin
        exit(
          ("User ID" = '') or
          ("Object Type to Run" <> xRec."Object Type to Run") or
          ("Object ID to Run" <> xRec."Object ID to Run") or
          ("Parameter String" <> xRec."Parameter String"));
    end;

    local procedure SetDefaultValues(SetupUserId: Boolean)
    var
        Language: Codeunit Language;
    begin
        "Last Ready State" := CurrentDateTime();
        "User Language ID" := Language.GetLanguageIdOrDefault(Language.GetUserLanguageCode());
        if SetupUserId then
            "User ID" := UserId();
        "No. of Attempts to Run" := 0;
        if "Job Timeout" = 0 then
            "Job Timeout" := DefaultJobTimeout();

        OnAfterSetDefaultValues(Rec);
    end;

    local procedure ClearServiceValues()
    begin
        OnBeforeClearServiceValues(Rec);

        "User Session Started" := 0DT;
        "User Service Instance ID" := 0;
        "User Session ID" := 0;
        "No. of Attempts to Run" := 0;
    end;

    procedure CleanupAfterExecution()
    var
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCleanupAfterExecution(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Recurring Job" then begin
            ClearServiceValues();
            if Status = Status::"On Hold with Inactivity Timeout" then
                "Earliest Start Date/Time" := JobQueueDispatcher.CalcNextRunTimeHoldDuetoInactivityJob(Rec, CurrentDateTime)
            else
                "Earliest Start Date/Time" := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(Rec, CurrentDateTime);
            EnqueueTask();
        end else
            Rec.Delete();

        OnAfterCleanupAfterExecution(Rec);
    end;

    local procedure HandleExecutionError()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        TelemetrySubscribers: Codeunit "Telemetry Subscribers";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleExecutionError(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Maximum No. of Attempts to Run" > Rec."No. of Attempts to Run" then begin
            Rec."No. of Attempts to Run" += 1;
            Rec."Earliest Start Date/Time" := CurrentDateTime + 1000 * Rec."Rerun Delay (sec.)";
            EnqueueTask();
        end else begin
            SetStatusValue(Rec.Status::Error);
            Commit();
            TryRunJobQueueSendNotification();

            JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallStack());
            TelemetrySubscribers.SendTraceOnJobQueueEntryFinalRunErrored(JobQueueLogEntry, Rec);
        end;
    end;

    local procedure TryRunJobQueueSendNotification()
    var
        IsHandled: Boolean;
        SessionId: Integer;
    begin
        IsHandled := false;
        OnBeforeTryRunJobQueueSendNotification(Rec, IsHandled);
        if IsHandled then
            exit;

        if Session.StartSession(SessionId, Codeunit::"Job Queue - Send Notification", CurrentCompany(), Rec) then;
    end;

    local procedure ClearRunOnWeekdays()
    begin
        "Run on Fridays" := false;
        "Run on Mondays" := false;
        "Run on Saturdays" := false;
        "Run on Sundays" := false;
        "Run on Thursdays" := false;
        "Run on Tuesdays" := false;
        "Run on Wednesdays" := false;
    end;

    [Scope('OnPrem')]
    procedure IsNextRunDateFormulaSet(): Boolean
    begin
        exit(Format("Next Run Date Formula") <> '');
    end;

    local procedure SetRecurringField()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetRecurringField(Rec, IsHandled);
        if IsHandled then
            exit;

        "Recurring Job" :=
          "Run on Mondays" or "Run on Tuesdays" or "Run on Wednesdays" or "Run on Thursdays" or
          "Run on Fridays" or "Run on Saturdays" or "Run on Sundays" or (Format("Next Run Date Formula") <> '');

        if "Recurring Job" and "Run in User Session" then
            Error(UserSessionJobsCannotBeRecurringErr);

        SetMinimumNumberOfMinutesBetweenRuns();
    end;

    local procedure SetMinimumNumberOfMinutesBetweenRuns()
    begin
        if Rec."Recurring Job" and not IsNextRunDateFormulaSet() and (Rec."No. of Minutes between Runs" = 0) then
            Rec."No. of Minutes between Runs" := 1440; // Default to one day
    end;

    local procedure SetStatusValue(NewStatus: Option)
    var
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetStatusValue(Rec, xRec, NewStatus, IsHandled);
        if IsHandled then
            exit;

        if NewStatus = Status then
            exit;
        case NewStatus of
            Status::Ready:
                begin
                    SetDefaultValues(false);
                    "Earliest Start Date/Time" := JobQueueDispatcher.CalcInitialRunTime(Rec, CurrentDateTime);
                    EnqueueTask();
                end;
            Status::"On Hold":
                CancelTask();
            Status::"On Hold with Inactivity Timeout":
                if "Inactivity Timeout Period" > 0 then begin
                    SetDefaultValues(false);
                    "Earliest Start Date/Time" := JobQueueDispatcher.CalcNextRunTimeHoldDuetoInactivityJob(Rec, CurrentDateTime);
                    EnqueueTask();
                end;
        end;
        Status := NewStatus;
        Modify();
    end;

    procedure ShowStatusMsg(JQID: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(JQID) then
            case JobQueueEntry.Status of
                JobQueueEntry.Status::Error:
                    Message(JobQueueEntry."Error Message");
                JobQueueEntry.Status::"In Process":
                    Message(Format(JobQueueEntry.Status::"In Process"));
                else
                    Message(ScheduledForPostingMsg, JobQueueEntry."User Session Started", JobQueueEntry."User ID");
            end;
    end;

    procedure LookupRecordToProcess()
    var
        RecRef: RecordRef;
        RecVariant: Variant;
    begin
        if IsNullGuid(ID) then
            exit;
        if Format("Record ID to Process") = '' then
            Error(NoRecordErr);
        RecRef.Get("Record ID to Process");
        RecRef.SetRecFilter();
        RecVariant := RecRef;
        PAGE.Run(0, RecVariant);
    end;

    procedure LookupObjectID(var NewObjectID: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        if AllObjWithCaption.Get("Object Type to Run", "Object ID to Run") then;
        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", "Object Type to Run");
        AllObjWithCaption.FilterGroup(0);
        Objects.SetRecord(AllObjWithCaption);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = ACTION::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            NewObjectID := AllObjWithCaption."Object ID";
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupDateTime(InitDateTime: DateTime; EarliestDateTime: DateTime; LatestDateTime: DateTime): DateTime
    var
        DateTimeDialog: Page "Date-Time Dialog";
        NewDateTime: DateTime;
    begin
        NewDateTime := InitDateTime;
        if InitDateTime < EarliestDateTime then
            InitDateTime := EarliestDateTime;
        if (LatestDateTime <> 0DT) and (InitDateTime > LatestDateTime) then
            InitDateTime := LatestDateTime;

        DateTimeDialog.SetDateTime(RoundDateTime(InitDateTime, 1000));

        if DateTimeDialog.RunModal() = ACTION::OK then
            NewDateTime := DateTimeDialog.GetDateTime();
        exit(NewDateTime);
    end;

    local procedure CheckStartAndExpirationDateTime()
    begin
        if IsExpired("Earliest Start Date/Time") then
            Error(ExpiresBeforeStartErr, FieldCaption("Expiration Date/Time"), FieldCaption("Earliest Start Date/Time"));
    end;

    procedure GetXmlContent() Params: Text
    var
        InStr: InStream;
    begin
        CalcFields(XML);
        if XML.HasValue() then begin
            XML.CreateInStream(InStr, TEXTENCODING::UTF8);
            InStr.Read(Params);
        end;

        OnAfterGetXmlContent(Rec, Params);
    end;

    procedure SetXmlContent(Params: Text)
    var
        OutStr: OutStream;
    begin
        Clear(XML);
        if Params <> '' then begin
            XML.CreateOutStream(OutStr, TEXTENCODING::UTF8);
            OutStr.Write(Params);
        end;

        OnSetXmlContentOnBeforeModify(Rec, Params);
        Modify();
    end;

    procedure GetReportParameters(): Text
    begin
        TestField("Object Type to Run", "Object Type to Run"::Report);
        TestField("Object ID to Run");

        exit(GetXmlContent());
    end;

    procedure SetReportParameters(Params: Text)
    begin
        TestField("Object Type to Run", "Object Type to Run"::Report);
        TestField("Object ID to Run");

        "Report Request Page Options" := Params <> '';

        SetXmlContent(Params);
        OnAfterSetReportParameters(Rec);
    end;

    [Scope('OnPrem')]
    procedure RunReportRequestPage()
    var
        Params: Text;
        OldParams: Text;
    begin
        if "Object Type to Run" <> "Object Type to Run"::Report then
            exit;
        if "Object ID to Run" = 0 then
            exit;

        OnRunReportRequestPageBeforeGetReportParameters(Rec);
        OldParams := GetReportParameters();
        Params := REPORT.RunRequestPage("Object ID to Run", OldParams);

        if (Params <> '') and (Params <> OldParams) then begin
            "User ID" := UserId();
            SetReportParameters(Params);
        end;

        OnAfterRunReportRequestPage(Rec, Params);
    end;

    procedure ScheduleJobQueueEntry(CodeunitID: Integer; RecordIDToProcess: RecordID)
    begin
        ScheduleJobQueueEntryWithParameters(CodeunitID, RecordIDToProcess, '');
    end;

    procedure ScheduleJobQueueEntryWithParameters(CodeunitID: Integer; RecordIDToProcess: RecordID; JobParameter: Text[250])
    begin
        Init();
        "Earliest Start Date/Time" := CreateDateTime(Today, Time);
        "Object Type to Run" := "Object Type to Run"::Codeunit;
        "Object ID to Run" := CodeunitID;
        "Record ID to Process" := RecordIDToProcess;
        "Run in User Session" := false;
        "Parameter String" := JobParameter;
        EnqueueTask();
    end;

    procedure ScheduleJobQueueEntryForLater(CodeunitID: Integer; StartDateTime: DateTime; JobQueueCategoryCode: Code[10]; JobParameter: Text)
    begin
        Init();
        "Earliest Start Date/Time" := StartDateTime;
        "Object Type to Run" := "Object Type to Run"::Codeunit;
        "Object ID to Run" := CodeunitID;
        "Run in User Session" := false;
        "Job Queue Category Code" := JobQueueCategoryCode;
        "Maximum No. of Attempts to Run" := 3;
        "Rerun Delay (sec.)" := 60;
        "Parameter String" := CopyStr(JobParameter, 1, MaxStrLen("Parameter String"));
        EnqueueTask();
    end;

    procedure GetStartingDateTime(Date: DateTime): DateTime
    begin
        if "Reference Starting Time" = 0DT then
            Validate("Starting Time");
        exit(CreateDateTime(DT2Date(Date), DT2Time("Reference Starting Time")));
    end;

    procedure GetEndingDateTime(Date: DateTime): DateTime
    begin
        if "Reference Starting Time" = 0DT then
            Validate("Starting Time");
        if "Ending Time" = 0T then
            exit(CreateDateTime(DT2Date(Date), 0T));
        if "Starting Time" = 0T then
            exit(CreateDateTime(DT2Date(Date), "Ending Time"));
        if "Starting Time" < "Ending Time" then
            exit(CreateDateTime(DT2Date(Date), "Ending Time"));
        exit(CreateDateTime(DT2Date(Date) + 1, "Ending Time"));
    end;

    procedure ScheduleRecurrentJobQueueEntry(ObjType: Option; ObjID: Integer; RecId: RecordID)
    begin
        Reset();
        SetRange("Object Type to Run", ObjType);
        SetRange("Object ID to Run", ObjID);
        if Format(RecId) <> '' then
            SetFilter("Record ID to Process", Format(RecId));
        LockTable();

        if not FindFirst() then begin
            InitRecurringJob(5);
            "Object Type to Run" := ObjType;
            "Object ID to Run" := ObjID;
            "Record ID to Process" := RecId;
            "Starting Time" := 080000T;
            "Maximum No. of Attempts to Run" := 3;
            EnqueueTask();
        end;
    end;

    procedure ScheduleRecurrentJobQueueEntryWithFrequency(ObjType: Option; ObjID: Integer; RecId: RecordID; NoofMinutesbetweenRuns: Integer)
    begin
        ScheduleRecurrentJobQueueEntryWithFrequency(ObjType, ObjID, RecID, NoofMinutesbetweenRuns, 3, 0, 080000T);
    end;

    procedure ScheduleRecurrentJobQueueEntryWithFrequency(ObjType: Option; ObjID: Integer; RecId: RecordID; NoofMinutesbetweenRuns: Integer; StartTime: Time)
    begin
        ScheduleRecurrentJobQueueEntryWithFrequency(ObjType, ObjID, RecID, NoofMinutesbetweenRuns, 3, 0, StartTime);
    end;

    internal procedure ScheduleRecurrentJobQueueEntryWithFrequency(ObjType: Option; ObjID: Integer; RecId: RecordID; NoofMinutesbetweenRuns: Integer; MaxAttemptsToRun: Integer; RerunDelay: Integer; StartingTime: Time)
    begin
        Reset();
        if NoofMinutesbetweenRuns = 0 then begin
            ScheduleRecurrentJobQueueEntry(ObjType, ObjID, RecId);
            exit;
        end;
        SetRange("Object Type to Run", ObjType);
        SetRange("Object ID to Run", ObjID);
        if Format(RecId) <> '' then
            SetFilter("Record ID to Process", Format(RecId));
        LockTable();

        if not FindFirst() then begin
            InitRecurringJob(NoofMinutesbetweenRuns);
            "Object Type to Run" := ObjType;
            "Object ID to Run" := ObjID;
            "Record ID to Process" := RecId;
            "Starting Time" := StartingTime;
            "Maximum No. of Attempts to Run" := MaxAttemptsToRun;
            "Rerun Delay (sec.)" := RerunDelay;
            OnScheduleRecurrentJobQueueEntryOnBeforeEnqueueTask(Rec);
            EnqueueTask();
        end;
    end;

    procedure ScheduleRecurrentJobQueueEntryWithRunDateFormula(ObjType: Option; ObjID: Integer; RecId: RecordID; JobQueueCategoryCode: Code[10]; MaxAttemptsToRun: Integer; NextRunDateFormula: DateFormula; StartingTime: Time)
    begin
        ScheduleRecurrentJobQueueEntryWithRunDateFormula(ObjType, ObjID, RecId, JobQueueCategoryCode, MaxAttemptsToRun, NextRunDateFormula, StartingTime, DefaultJobTimeout());
    end;

    internal procedure ScheduleRecurrentJobQueueEntryWithRunDateFormula(ObjType: Option; ObjID: Integer; RecId: RecordID; JobQueueCategoryCode: Code[10]; MaxAttemptsToRun: Integer; NextRunDateFormula: DateFormula; StartingTime: Time; JobTimeout: Duration)
    begin
        Reset();
        if format(NextRunDateFormula) = '<0D>' then
            Evaluate(NextRunDateFormula, '<1D>');

        SetRange("Object Type to Run", ObjType);
        SetRange("Object ID to Run", ObjID);
        if Format(RecId) <> '' then
            SetFilter("Record ID to Process", Format(RecId));
        LockTable();

        if not FindFirst() then begin
            InitRecurringJob(0);
            "Object Type to Run" := ObjType;
            "Object ID to Run" := ObjID;
            "Record ID to Process" := RecId;
            "Job Queue Category Code" := JobQueueCategoryCode;
            "Starting Time" := StartingTime;
            "Next Run Date Formula" := NextRunDateFormula;
            "Earliest Start Date/Time" := CreateDateTime(CalcDate("Next Run Date Formula", Today), "Starting Time");
            "Maximum No. of Attempts to Run" := MaxAttemptsToRun;
            "Job Timeout" := JobTimeout;
            EnqueueTask();
        end;
    end;

    procedure InitRecurringJob(NoofMinutesbetweenRuns: Integer)
    begin
        Init();
        Clear(ID); // "Job Queue - Enqueue" is to define new ID
        "Recurring Job" := true;
        "Run on Mondays" := true;
        "Run on Tuesdays" := true;
        "Run on Wednesdays" := true;
        "Run on Thursdays" := true;
        "Run on Fridays" := true;
        "Run on Saturdays" := true;
        "Run on Sundays" := true;
        "No. of Minutes between Runs" := NoofMinutesbetweenRuns;
        "Earliest Start Date/Time" := CurrentDateTime();
    end;

    procedure FindJobQueueEntry(ObjType: Option; ObjID: Integer): Boolean
    begin
        Reset();
        SetRange("Object Type to Run", ObjType);
        SetRange("Object ID to Run", ObjID);
        exit(FindFirst());
    end;

    procedure GetDefaultDescription(): Text[250]
    var
        DefaultDescription: Text[250];
    begin
        CalcFields("Object Caption to Run");
        DefaultDescription := CopyStr("Object Caption to Run", 1, MaxStrLen(DefaultDescription));
        exit(DefaultDescription);
    end;

    procedure IsToReportInbox(): Boolean
    begin
        exit(
          ("Object Type to Run" = "Object Type to Run"::Report) and
          ("Report Output Type" in ["Report Output Type"::PDF, "Report Output Type"::Word,
                                    "Report Output Type"::Excel]));
    end;

    procedure FilterInactiveOnHoldEntries()
    begin
        Reset();
        SetRange(Status, Status::"On Hold with Inactivity Timeout");
    end;

    procedure DoesJobNeedToBeRun() Result: Boolean
    begin
        OnFindingIfJobNeedsToBeRun(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReschedule(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanupAfterExecution(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetXmlContent(var JobQueueEntry: Record "Job Queue Entry"; var Params: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunReportRequestPage(JobQueueEntry: Record "Job Queue Entry"; var Params: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultValues(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearServiceValues(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeRun(JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRecurringField(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetStatusValue(var JobQueueEntry: Record "Job Queue Entry"; var xJobQueueEntry: Record "Job Queue Entry"; var NewStatus: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryRunJobQueueSendNotification(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeSetDefaultValues(var JobQueueEntry: Record "Job Queue Entry"; var SetupUserId: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnReuseExisingJobFromId(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportRequestPageBeforeGetReportParameters(JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScheduleTaskOnAfterCalcShouldChangeUserID(var JobQueueEntry: Record "Job Queue Entry"; var ShouldChangeUserID: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetXmlContentOnBeforeModify(var JobQueueEntry: Record "Job Queue Entry"; var Params: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanupAfterExecution(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestart(JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReportParameters(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScheduleRecurrentJobQueueEntryOnBeforeEnqueueTask(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnAfterRunParametersChangedCalculated(var JobQueueEntry: Record "Job Queue Entry"; var xJobQueueEntry: Record "Job Queue Entry"; var RunParametersChanged: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleExecutionError(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsReadyToStart(var JobQueueEntry: Record "Job Queue Entry"; var ReadyToStart: Boolean; var IsHandled: Boolean)
    begin
    end;
}

