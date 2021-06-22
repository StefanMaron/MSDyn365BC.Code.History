codeunit 483 "Change Global Dimensions"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Sales Shipment Header" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Sales Invoice Header" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Sales Cr.Memo Line" = rm,
                  TableData "Purch. Rcpt. Header" = rm,
                  TableData "Purch. Rcpt. Line" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Inv. Line" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Purch. Cr. Memo Line" = rm,
                  TableData "Job Ledger Entry" = rm,
                  TableData "Res. Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Phys. Inventory Ledger Entry" = rm,
                  TableData "Issued Reminder Header" = rm,
                  TableData "Issued Reminder Line" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Issued Fin. Charge Memo Line" = rm,
                  TableData "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Detailed Vendor Ledg. Entry" = rm,
                  TableData "Posted Assembly Header" = rm,
                  TableData "Posted Assembly Line" = rm,
                  TableData "Job WIP G/L Entry" = rm,
                  TableData "Employee Ledger Entry" = rm,
                  TableData "Detailed Employee Ledger Entry" = rm,
                  TableData "Production Order" = rm,
                  TableData "Prod. Order Line" = rm,
                  TableData "Prod. Order Component" = rm,
                  TableData "Prod. Order Routing Line" = rm,
                  TableData "Prod. Order Capacity Need" = rm,
                  TableData "Prod. Order Routing Tool" = rm,
                  TableData "Prod. Order Routing Personnel" = rm,
                  TableData "Prod. Order Rtng Qlty Meas." = rm,
                  TableData "Prod. Order Comment Line" = rm,
                  TableData "Prod. Order Rtng Comment Line" = rm,
                  TableData "Prod. Order Comp. Cmt Line" = rm,
                  TableData "FA Ledger Entry" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm,
                  TableData "Value Entry" = rm,
                  TableData "Capacity Ledger Entry" = rm,
                  TableData "Service Header" = rm,
                  TableData "Service Item Line" = rm,
                  TableData "Service Line" = rm,
                  TableData "Service Ledger Entry" = rm,
                  TableData "Service Contract Header" = rm,
                  TableData "Service Contract Line" = rm,
                  TableData "Service Invoice Line" = rm,
                  TableData "Warehouse Entry" = rm,
                  TableData "Filed Service Contract Header" = rm,
                  TableData "Return Shipment Header" = rm,
                  TableData "Return Shipment Line" = rm,
                  TableData "Return Receipt Header" = rm,
                  TableData "Return Receipt Line" = rm;
    TableNo = "Change Global Dim. Log Entry";

    trigger OnRun()
    begin
        if ChangeGlobalDimLogMgt.IsBufferClear then
            ChangeGlobalDimLogMgt.FillBuffer;
        BindSubscription(ChangeGlobalDimLogMgt);
        if RunTask(Rec) then begin
            DeleteEntry(Rec);
            if ChangeGlobalDimLogMgt.IsBufferClear then
                ResetState;
        end;
    end;

    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
        Window: Dialog;
        CloseActiveSessionsMsg: Label 'Close all other active sessions.';
        CloseSessionNotificationTok: Label 'A2C57B69-B056-4B3B-8D0F-C0D997145EE7', Locked = true;
        CurrRecord: Integer;
        NoOfRecords: Integer;
        ProgressMsg: Label 'Updating #1#####\@2@@@@@@@@@@', Comment = '#1-Table Id and Name;#2 - progress bar.';
        IsWindowOpen: Boolean;
        TagCategoryTxt: Label 'Change Global Dimensions', Locked = true;
        StartTraceTagMsg: Label 'Change Global Dimensions is started, parallel processing is on.';
        SequentialStartTraceTagMsg: Label 'Change Global Dimensions is started, parallel processing is off.';
        FinishTraceTagMsg: Label 'Change Global Dimensions is finished.';
        SessionListActionTxt: Label 'Session List';
        SessionUpdateRequiredMsg: Label 'All records were successfully updated. To apply the updates, close the General Ledger Setup page.';

    procedure ResetIfAllCompleted()
    begin
        ChangeGlobalDimLogMgt.FillBuffer;
        if ChangeGlobalDimLogMgt.AreAllCompleted then
            ResetState;
    end;

    local procedure GetDelayInScheduling(): Integer
    begin
        // duration in milliseconds between scheduled jobs
        exit(100);
    end;

    procedure Prepare()
    begin
        ChangeGlobalDimHeader.Get();
        if IsPrepareEnabled(ChangeGlobalDimHeader) and ChangeGlobalDimHeader."Parallel Processing" then
            if IsCurrentSessionActiveOnly then
                PrepareTableList
            else
                SendCloseSessionsNotification
    end;

    local procedure PrepareTableList() IsListFilled: Boolean
    begin
        IsListFilled := InitTableList;
        if not IsListFilled then begin
            UpdateGLSetup;
            RefreshHeader;
        end;
    end;

    local procedure ProcessTableList()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        with ChangeGlobalDimLogEntry do begin
            Reset;
            SetFilter("Table ID", '>0');
            SetRange("Parent Table ID", 0);
            if IsWindowOpen then begin
                CurrRecord := 0;
                CalcSums("Total Records");
                NoOfRecords := "Total Records";
            end;
            if FindSet(true) then
                repeat
                    if IsWindowOpen then
                        Window.Update(1, StrSubstNo('%1 %2', "Table ID", "Table Name"));
                    if RunTask(ChangeGlobalDimLogEntry) then
                        DeleteEntry(ChangeGlobalDimLogEntry);
                until Next = 0;
            ResetIfAllCompleted;
        end;
    end;

    procedure RemoveHeader()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        if ChangeGlobalDimLogEntry.IsEmpty then
            ChangeGlobalDimHeader.DeleteAll();
    end;

    procedure ResetState()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry.DeleteAll(true);
        ClearAll;
        ChangeGlobalDimLogMgt.ClearBuffer;
        RefreshHeader;
    end;

    procedure Rerun(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        ChangeGlobalDimLogEntry.LockTable();
        ChangeGlobalDimLogEntry.UpdateStatus;
        if ChangeGlobalDimLogMgt.FillBuffer then
            RerunEntry(ChangeGlobalDimLogEntry);
    end;

    local procedure RunTask(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry") Completed: Boolean
    begin
        ChangeGlobalDimLogEntry.SetSessionInProgress;
        if ChangeGlobalDimHeader."Parallel Processing" then
            Commit();
        Completed := ChangeDimsOnTable(ChangeGlobalDimLogEntry);
    end;

    procedure Start()
    begin
        ChangeGlobalDimHeader.Get();
        if IsStartEnabled then begin
            SendTraceTagOn(StartTraceTagMsg);
            CompleteEmptyTables;
            UpdateGLSetup;
            ScheduleJobs(GetDelayInScheduling);
            RefreshHeader;
        end;
    end;

    procedure StartSequential()
    begin
        ChangeGlobalDimHeader.Get();
        if IsPrepareEnabled(ChangeGlobalDimHeader) and not ChangeGlobalDimHeader."Parallel Processing" then begin
            WindowOpen;
            if PrepareTableList then begin
                SendTraceTagOn(SequentialStartTraceTagMsg);
                CompleteEmptyTables;
                UpdateGLSetup;
                ProcessTableList;
                RefreshHeader;
                SendTraceTagOn(FinishTraceTagMsg);
            end;
            WindowClose;
        end;
    end;

    local procedure CompleteEmptyTables()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        RecRef: RecordRef;
    begin
        ChangeGlobalDimLogEntry.SetFilter("Table ID", '>0');
        ChangeGlobalDimLogEntry.SetRange("Total Records", 0);
        if ChangeGlobalDimLogEntry.FindSet(true) then
            repeat
                RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
                RecRef.LockTable(true);
                ChangeGlobalDimLogEntry."Total Records" := RecRef.Count();
                if ChangeGlobalDimLogEntry."Total Records" = 0 then
                    DeleteEntry(ChangeGlobalDimLogEntry)
                else
                    ChangeGlobalDimLogEntry.Modify();
                RecRef.Close;
            until ChangeGlobalDimLogEntry.Next = 0;
    end;

    procedure FillBuffer()
    begin
        ChangeGlobalDimLogMgt.FillBuffer;
    end;

    local procedure FindChildTableNo(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"): Integer
    begin
        if ChangeGlobalDimLogEntry."Is Parent Table" then
            exit(ChangeGlobalDimLogMgt.FindChildTable(ChangeGlobalDimLogEntry."Table ID"));
        exit(0);
    end;

    local procedure FindDependentTableNo(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var DependentRecRef: RecordRef): Boolean
    var
        ChildTableNo: Integer;
    begin
        with ChangeGlobalDimLogEntry do begin
            ChildTableNo := FindChildTableNo(ParentChangeGlobalDimLogEntry);
            if ChildTableNo > 0 then
                if Get(ChildTableNo) then begin
                    DependentRecRef.Open("Table ID");
                    DependentRecRef.LockTable(true);
                    "Total Records" := DependentRecRef.Count();
                    "Session ID" := SessionId;
                    "Server Instance ID" := ServiceInstanceId;
                    exit("Total Records" > 0);
                end;
        end;
    end;

    procedure FindTablesForScheduling(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"): Boolean
    begin
        with ChangeGlobalDimLogEntry do begin
            SetRange("Parent Table ID", 0);
            SetFilter("Total Records", '>0');
            exit(FindSet(true))
        end;
    end;

    local procedure GetMinCommitSize(): Integer
    begin
        // number of records that should be modified between COMMIT calls
        exit(10);
    end;

    local procedure CalcRecordsWithinCommit(TotalRecords: Integer) RecordsWithinCommit: Integer
    begin
        RecordsWithinCommit := Round(TotalRecords / 100, 1, '>');
        if RecordsWithinCommit < GetMinCommitSize then
            RecordsWithinCommit := GetMinCommitSize;
    end;

    local procedure ChangeDimsOnTable(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry") Completed: Boolean
    var
        DependentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        RecRef: RecordRef;
        DependentRecRef: RecordRef;
        CurrentRecNo: Integer;
        DependentRecNo: Integer;
        RecordsWithinCommit: Integer;
        StartedFromRecord: Integer;
        StartedFromDependentRecord: Integer;
        DependentEntryCompleted: Boolean;
    begin
        RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
        RecRef.LockTable(true);
        if not RecRef.IsEmpty then begin
            CurrentRecNo := ChangeGlobalDimLogEntry."Completed Records";
            StartedFromRecord := CurrentRecNo;
            ChangeGlobalDimLogEntry."Total Records" := RecRef.Count();
            RecordsWithinCommit := CalcRecordsWithinCommit(ChangeGlobalDimLogEntry."Total Records");
            if RecRef.FindSet(true) then begin
                if FindDependentTableNo(DependentChangeGlobalDimLogEntry, ChangeGlobalDimLogEntry, DependentRecRef) then begin
                    DependentChangeGlobalDimLogEntry.SetSessionInProgress;
                    DependentRecNo := DependentChangeGlobalDimLogEntry."Completed Records";
                    StartedFromDependentRecord := DependentRecNo;
                    DependentChangeGlobalDimLogEntry."Earliest Start Date/Time" := CurrentDateTime;
                end;
                if ChangeGlobalDimLogEntry."Completed Records" > 0 then
                    RecRef.Next(ChangeGlobalDimLogEntry."Completed Records");
                ChangeGlobalDimLogEntry."Earliest Start Date/Time" := CurrentDateTime;
                repeat
                    ChangeDimsOnRecord(ChangeGlobalDimLogEntry, RecRef);
                    CurrentRecNo += 1;
                    if DependentChangeGlobalDimLogEntry."Total Records" > 0 then
                        ChangeDependentRecords(ChangeGlobalDimLogEntry, DependentChangeGlobalDimLogEntry, RecRef, DependentRecRef, DependentRecNo);

                    if CurrentRecNo >= (ChangeGlobalDimLogEntry."Completed Records" + RecordsWithinCommit) then begin
                        DependentChangeGlobalDimLogEntry.Update(DependentRecNo, StartedFromDependentRecord);
                        Completed := UpdateWithCommit(ChangeGlobalDimLogEntry, CurrentRecNo, StartedFromRecord);
                        if DependentRecNo > 0 then
                            DependentRecRef.LockTable();
                        RecRef.LockTable();
                    end;
                    if IsWindowOpen then begin
                        CurrRecord += 1;
                        if CurrRecord mod Round(NoOfRecords / 100, 1, '>') = 1 then
                            Window.Update(2, Round(CurrRecord / NoOfRecords * 10000, 1));
                    end;
                until RecRef.Next = 0;
            end;
            if DependentRecNo > 0 then begin
                DependentRecRef.Close;
                DependentChangeGlobalDimLogEntry.Update(DependentRecNo, StartedFromDependentRecord);
                if DependentChangeGlobalDimLogEntry.Status = DependentChangeGlobalDimLogEntry.Status::Completed then
                    DependentEntryCompleted := DeleteEntry(DependentChangeGlobalDimLogEntry);
                if not DependentEntryCompleted then begin
                    DependentChangeGlobalDimLogEntry.Update(0, 0);
                    CurrentRecNo := 0; // set the parent to Incomplete
                end;
            end;
            Completed := UpdateWithCommit(ChangeGlobalDimLogEntry, CurrentRecNo, StartedFromRecord);
        end;
        RecRef.Close;
    end;

    local procedure ChangeDimsOnRecord(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef): Boolean
    var
        GlobalDimFieldRef: array[2] of FieldRef;
        OldDimValueCode: array[2] of Code[20];
        IsHandled: Boolean;
    begin
        with ChangeGlobalDimLogEntry do begin
            if ("Change Type 1" = "Change Type 1"::None) and ("Change Type 2" = "Change Type 2"::None) then
                exit(false);

            OnChangeDimsOnRecord(ChangeGlobalDimLogEntry, RecRef, IsHandled);
            if IsHandled then
                exit;

            GetFieldRefValues(RecRef, GlobalDimFieldRef, OldDimValueCode);
            ChangeDimOnRecord(RecRef, 1, GlobalDimFieldRef[1], OldDimValueCode[2]);
            ChangeDimOnRecord(RecRef, 2, GlobalDimFieldRef[2], OldDimValueCode[1]);
            exit(RecRef.Modify);
        end;
    end;

    local procedure ChangeDependentRecords(ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ParentRecRef: RecordRef; var RecRef: RecordRef; var CurrentRecNo: Integer)
    var
        ParentKeyValue: Variant;
        GlobalDimFieldRef: array[2] of FieldRef;
        ParentKeyFieldRef: FieldRef;
        ParentDimValueCode: array[2] of Code[20];
        DimValueCode: array[2] of Code[20];
        IsHandled: Boolean;
    begin
        ParentChangeGlobalDimLogEntry.GetFieldRefValues(ParentRecRef, GlobalDimFieldRef, ParentDimValueCode);
        ChangeGlobalDimLogEntry.GetPrimaryKeyFieldRef(ParentRecRef, ParentKeyFieldRef);
        ParentKeyValue := ParentKeyFieldRef.Value;

        ParentKeyFieldRef := RecRef.Field(2);
        ParentKeyFieldRef.SetRange(ParentKeyValue);
        if RecRef.FindSet(true) then begin
            repeat
                OnChangeDependentRecords(ChangeGlobalDimLogEntry, RecRef, IsHandled);
                if not IsHandled then begin
                    ChangeGlobalDimLogEntry.GetFieldRefValues(RecRef, GlobalDimFieldRef, DimValueCode);
                    GlobalDimFieldRef[1].Value(ParentDimValueCode[1]);
                    GlobalDimFieldRef[2].Value(ParentDimValueCode[2]);
                    RecRef.Modify();
                    CurrentRecNo += 1;
                end;
            until RecRef.Next = 0;
        end;
    end;

    local procedure RerunEntry(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        with ChangeGlobalDimLogEntry do
            if Status in [Status::" ", Status::Incomplete, Status::Scheduled] then begin
                SendTraceTagOnRerun;
                if "Parent Table ID" <> 0 then
                    RescheduleParentTable("Parent Table ID")
                else
                    ScheduleJobForTable(ChangeGlobalDimLogEntry, CurrentDateTime + 2000);
            end;
    end;

    local procedure RescheduleParentTable(ParentTableID: Integer)
    var
        ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ParentChangeGlobalDimLogEntry.Get(ParentTableID);
        ParentChangeGlobalDimLogEntry.Validate("Completed Records", 0);
        ScheduleJobForTable(ParentChangeGlobalDimLogEntry, CurrentDateTime + 100);
    end;

    local procedure ScheduleJobs(DeltaMsec: Integer)
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        StartTime: DateTime;
    begin
        if FindTablesForScheduling(ChangeGlobalDimLogEntry) then begin
            StartTime := CurrentDateTime + 1000;
            repeat
                StartTime += DeltaMsec;
                ScheduleJobForTable(ChangeGlobalDimLogEntry, StartTime);
            until ChangeGlobalDimLogEntry.Next = 0;
        end;
    end;

    local procedure ScheduleJobForTable(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; StartNotBefore: DateTime)
    var
        DoNotScheduleTask: Boolean;
        TaskID: Guid;
    begin
        with ChangeGlobalDimLogEntry do begin
            OnBeforeScheduleTask("Table ID", DoNotScheduleTask, TaskID);
            if DoNotScheduleTask then
                "Task ID" := TaskID
            else begin
                CancelTask;
                "Task ID" :=
                  TASKSCHEDULER.CreateTask(
                    CODEUNIT::"Change Global Dimensions", CODEUNIT::"Change Global Dim Err. Handler",
                    true, CompanyName, StartNotBefore, RecordId);
            end;
            if IsNullGuid("Task ID") then
                Status := Status::" "
            else
                Status := Status::Scheduled;
            "Earliest Start Date/Time" := StartNotBefore;
            Modify;
            SendTraceTagOnScheduling;
        end;
        if ChangeGlobalDimLogEntry."Is Parent Table" then
            ScheduleDependentTables(ChangeGlobalDimLogEntry);
    end;

    local procedure ScheduleDependentTables(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        DependentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        with DependentChangeGlobalDimLogEntry do begin
            SetRange("Parent Table ID", ChangeGlobalDimLogEntry."Table ID");
            if FindSet then
                repeat
                    "Task ID" := ChangeGlobalDimLogEntry."Task ID";
                    Validate("Completed Records", 0);
                    Status := ChangeGlobalDimLogEntry.Status;
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure IsCurrentSessionActiveOnly() Result: Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        OnCountingActiveSessions(Result);
        if Result then
            exit(true);
        // Ignore session types: Web Service,Client Service,NAS,Management Client
        ActiveSession.SetFilter(
          "Client Type", '<>%1&<>%2&<>%3&<>%4',
          ActiveSession."Client Type"::"Web Service", ActiveSession."Client Type"::"Client Service",
          ActiveSession."Client Type"::NAS, ActiveSession."Client Type"::"Management Client");
        ActiveSession.SetFilter("Session ID", '<>%1', SessionId);
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId);
        exit(ActiveSession.IsEmpty);
    end;

    procedure IsDimCodeEnabled(): Boolean
    begin
        exit(ChangeGlobalDimLogMgt.IsBufferClear);
    end;

    procedure IsPrepareEnabled(var ChangeGlobalDimHeader: Record "Change Global Dim. Header"): Boolean
    begin
        with ChangeGlobalDimHeader do
            exit(
              (("Change Type 1" <> "Change Type 1"::None) or ("Change Type 2" <> "Change Type 2"::None)) and
              ChangeGlobalDimLogMgt.IsBufferClear);
    end;

    procedure IsStartEnabled(): Boolean
    begin
        if ChangeGlobalDimLogMgt.IsBufferClear then
            exit(false);
        exit(not ChangeGlobalDimLogMgt.IsStarted);
    end;

    procedure RefreshHeader()
    begin
        if ChangeGlobalDimHeader.Get then begin
            ChangeGlobalDimHeader.Refresh;
            ChangeGlobalDimHeader.Modify();
        end else begin
            ChangeGlobalDimHeader.Refresh;
            ChangeGlobalDimHeader.Insert();
        end
    end;

    procedure SetParallelProcessing(NewParallelProcessing: Boolean)
    begin
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader."Parallel Processing" := NewParallelProcessing;
        ChangeGlobalDimHeader.Modify();
    end;

    procedure InitTableList(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TempAllObjWithCaption: Record AllObjWithCaption temporary;
        TempParentTableInteger: Record "Integer" temporary;
        TotalRecords: Integer;
    begin
        TotalRecords := 0;
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimLogEntry.LockTable();
        ChangeGlobalDimLogEntry.DeleteAll(true);
        if FindTablesWithDims(TempAllObjWithCaption) then begin
            repeat
                ChangeGlobalDimLogEntry.Init();
                ChangeGlobalDimLogEntry."Table ID" := TempAllObjWithCaption."Object ID";
                ChangeGlobalDimLogEntry."Table Name" := TempAllObjWithCaption."Object Name";
                ChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimHeader."Change Type 1";
                ChangeGlobalDimLogEntry."Change Type 2" := ChangeGlobalDimHeader."Change Type 2";
                FillTableData(ChangeGlobalDimLogEntry);
                TotalRecords += ChangeGlobalDimLogEntry."Total Records";
                TempParentTableInteger.Number := ChangeGlobalDimLogEntry."Parent Table ID";
                if TempParentTableInteger.Number <> 0 then
                    TempParentTableInteger.Insert();
                ChangeGlobalDimLogEntry.Insert();
            until TempAllObjWithCaption.Next = 0;

            if TempParentTableInteger.FindSet then
                repeat
                    if ChangeGlobalDimLogEntry.Get(TempParentTableInteger.Number) then begin
                        ChangeGlobalDimLogEntry."Is Parent Table" := true;
                        ChangeGlobalDimLogEntry.Modify();
                    end;
                until TempParentTableInteger.Next = 0;
        end;
        if TotalRecords = 0 then
            ChangeGlobalDimLogEntry.DeleteAll(true);
        ChangeGlobalDimLogMgt.FillBuffer;
        exit(TotalRecords <> 0);
    end;

    local procedure TestDirectModifyPermission(var RecRef: RecordRef)
    var
        IsHandled: Boolean;
    begin
        OnBeforeTestDirectModifyPermission(RecRef, IsHandled);
        if IsHandled then
            exit;

        if RecRef.FindFirst then
            RecRef.Modify();
    end;

    local procedure DeleteEntry(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"): Boolean
    begin
        if ChangeGlobalDimLogEntry.Delete then begin
            ChangeGlobalDimLogMgt.ExcludeTable(ChangeGlobalDimLogEntry."Table ID");
            exit(true);
        end
    end;

    local procedure FillTableData(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
        TestDirectModifyPermission(RecRef);
        ChangeGlobalDimLogEntry.FillData(RecRef);
        RecRef.Close;
    end;

    local procedure FindTablesWithDims(var TempAllObjWithCaption: Record AllObjWithCaption temporary): Boolean
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.DefaultDimObjectNoWithGlobalDimsList(TempAllObjWithCaption);
        DimensionManagement.GlobalDimObjectNoList(TempAllObjWithCaption);
        DimensionManagement.JobTaskDimObjectNoList(TempAllObjWithCaption);
        OnAfterGetObjectNoList(TempAllObjWithCaption);
        exit(TempAllObjWithCaption.FindSet);
    end;

    local procedure UpdateGLSetup()
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", ChangeGlobalDimHeader."Global Dimension 1 Code");
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
        GeneralLedgerSetup.Modify(true);

        UpdateDimValues;
        if ChangeGlobalDimHeader."Parallel Processing" then
            Commit();
    end;

    local procedure UpdateDimValues()
    var
        DimensionValue: Record "Dimension Value";
    begin
        with DimensionValue do begin
            SetCurrentKey(Code, "Global Dimension No.");
            SetRange("Global Dimension No.", 1, 2);
            ModifyAll("Global Dimension No.", 0);
            Reset;
            if ChangeGlobalDimHeader."Global Dimension 1 Code" <> '' then begin
                SetRange("Dimension Code", ChangeGlobalDimHeader."Global Dimension 1 Code");
                ModifyAll("Global Dimension No.", 1);
            end;
            if ChangeGlobalDimHeader."Global Dimension 2 Code" <> '' then begin
                SetRange("Dimension Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
                ModifyAll("Global Dimension No.", 2);
            end;
        end;
    end;

    procedure GetCloseSessionsNotificationID() Id: Guid
    begin
        Evaluate(Id, CloseSessionNotificationTok);
    end;

    local procedure PrepareNotification(var Notification: Notification; ID: Guid; Msg: Text)
    begin
        Notification.Id(ID);
        Notification.Recall;
        Notification.Message(Msg);
        Notification.Scope(NOTIFICATIONSCOPE::LocalScope);
    end;

    local procedure SendCloseSessionsNotification()
    var
        Notification: Notification;
    begin
        PrepareNotification(Notification, GetCloseSessionsNotificationID, CloseActiveSessionsMsg);
        Notification.AddAction(SessionListActionTxt, CODEUNIT::"Change Global Dimensions", 'ShowActiveSessions');
        Notification.Send;
    end;

    local procedure SendTraceTagOn(TraceTagMessage: Text)
    begin
        Session.LogMessage('00001ZE', TraceTagMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TagCategoryTxt);
    end;

    procedure ShowActiveSessions(BlockNotification: Notification)
    begin
        PAGE.Run(PAGE::"Concurrent Session List");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCountingActiveSessions(var IsCurrSessionActiveOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleTask(TableNo: Integer; var DoNotScheduleTask: Boolean; var TaskID: Guid)
    begin
    end;

    local procedure UpdateWithCommit(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; CurrentRecNo: Integer; StartedFromRecord: Integer): Boolean
    begin
        if ChangeGlobalDimHeader."Parallel Processing" then
            exit(ChangeGlobalDimLogEntry.UpdateWithCommit(CurrentRecNo, StartedFromRecord));
        exit(ChangeGlobalDimLogEntry.UpdateWithoutCommit(CurrentRecNo, StartedFromRecord));
    end;

    local procedure WindowOpen()
    begin
        if GuiAllowed then begin
            Window.Open(ProgressMsg);
            IsWindowOpen := true;
        end;
    end;

    local procedure WindowClose()
    begin
        if IsWindowOpen then begin
            Window.Close;
            IsWindowOpen := false;

            Message(SessionUpdateRequiredMsg);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDirectModifyPermission(var RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeDependentRecords(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeDimsOnRecord(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

}

