codeunit 5515 "Integration Management Setup"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The page will be removed with Integration Management. Refactor to use systemID, systemLastModifiedAt and other system fields.';
    ObsoleteTag = '17.0';
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        UpdateRecords();
    end;

    procedure ScheduleJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
        FindOrCreateJobQueue(JobQueueEntry);
    end;

    procedure InsertIntegrationTables(InsertNotification: Notification)
    var
        IntegrationManagementSetup: Record "Integration Management Setup";
    begin
        InsertIntegrationTables(IntegrationManagementSetup);
        if Guiallowed() then
            Message(SetupCompleteMsg);
    end;

    procedure InsertIntegrationTables(var IntegrationManagementSetup: Record "Integration Management Setup")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        IntegrationManagement: Codeunit "Integration Management";
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableData);
        AllObjWithCaption.FindSet();
        repeat
            if IntegrationManagement.IsIntegrationRecord(AllObjWithCaption."Object ID") then begin
                Clear(IntegrationManagementSetup);
                IntegrationManagementSetup."Table ID" := AllObjWithCaption."Object ID";
                IntegrationManagementSetup."Table Caption" := AllObjWithCaption."Object Caption";
                IntegrationManagementSetup.Enabled := true;
                IntegrationManagementSetup."Batch Size" := GetDefaultBatchSize();
                IntegrationManagementSetup.Insert();
            end;
        until AllObjWithCaption.Next() = 0;
    end;

    procedure GetPopulateIntegrationTablesNotificationId(): Guid
    begin
        exit('ac52c47f-2512-4d54-8f41-5bb48c4c8b50');
    end;

    procedure GetDefaultBatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure UpdateRecords()
    var
        IntegrationManagementSetup: Record "Integration Management Setup";
    begin
        IntegrationManagementSetup.SetRange(Enabled, true);
        IntegrationManagementSetup.SetRange(Completed, false);
        if IntegrationManagementSetup.FindSet(true) then
            repeat
                UpdateRecordsInTable(IntegrationManagementSetup);
                IntegrationManagementSetup.Completed := true;
                IntegrationManagementSetup."Last DateTime Modified" := CurrentDateTime();
                IntegrationManagementSetup.Modify();
                Commit();
            until IntegrationManagementSetup.Next() = 0;
    end;

    local procedure UpdateRecordsInTable(var IntegrationManagementSetup: Record "Integration Management Setup")
    var
        IntegrationManagement: Codeunit "Integration Management";
        IntegrationManagementSetupCodeunit: Codeunit "Integration Management Setup";
        TableRecordRef: RecordRef;
        FilterModifiedFieldRef: FieldRef;
        ModifiedFieldRef: FieldRef;
        LastModifiedDateTime: DateTime;
        IntegrationRecordModifiedDateTime: DateTime;
        RecordsUpdatedCount: Integer;
    begin
        TableRecordRef.Open(IntegrationManagementSetup."Table ID");
        FilterModifiedFieldRef := TableRecordRef.Field(2000000003);
        TableRecordRef.SetView(StrSubstNo(SortTableViewPlaceholderTxt, FilterModifiedFieldRef.Name));
        FilterModifiedFieldRef.SetFilter('>=%1', IntegrationManagementSetup."Last DateTime Modified");
        BindSubscription(IntegrationManagementSetupCodeunit);
        if TableRecordRef.FindSet() then
            repeat
                ModifiedFieldRef := TableRecordRef.Field(2000000003);
                LastModifiedDateTime := ModifiedFieldRef.Value;
                if LastModifiedDateTime = 0DT then
                    IntegrationRecordModifiedDateTime := CurrentDateTime()
                else
                    IntegrationRecordModifiedDateTime := LastModifiedDateTime;

                IntegrationManagement.InsertUpdateIntegrationRecord(TableRecordRef, IntegrationRecordModifiedDateTime);
                RecordsUpdatedCount += 1;
                if RecordsUpdatedCount = IntegrationManagementSetup."Batch Size" then begin
                    IntegrationManagementSetup."Last DateTime Modified" := LastModifiedDateTime;
                    IntegrationManagementSetup.Modify();
                    Commit();
                    RecordsUpdatedCount := 0;
                end;
            until TableRecordRef.Next() = 0;

        UnbindSubscription(IntegrationManagementSetupCodeunit);
    end;

    local procedure FindOrCreateJobQueue(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueExist: Boolean;
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Management Setup");
        JobQueueExist := JobQueueEntry.FindFirst();
        if JobQueueExist then
            if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
                Error(JobQueueIsRunningErr);

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Integration Management Setup";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(JobQueueEntry.Description));
        if not JobQueueExist then
            JobQueueEntry.Insert(true)
        else
            JobQueueEntry.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Management", 'OnGetIntegrationActivated', '', false, false)]
    local procedure OnGetIntegrationActivated(var IsSyncEnabled: Boolean)
    begin
        IsSyncEnabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Management", 'OnGetIntegrationEnabledOnSystem', '', false, false)]
    local procedure OnGetIntegrationEnabledOnSystem(var IsEnabled: Boolean)
    begin
        IsEnabled := true;
    end;

    procedure GetConfigureIntegrationManagementUpdateQst(): Text
    begin
        exit(ConfigureIntegrationManagementUpdateQst);
    end;

    var
        SortTableViewPlaceholderTxt: Label 'SORTING(%1) ORDER(Ascending)', Locked = true;
        JobQueueEntryDescTxt: Label 'Job used to generate integration records and enable Integration Management.';
        JobQueueIsRunningErr: Label 'The job queue entry is already running. Stop the existing job queue entry to schedule a new one.';
        SetupCompleteMsg: Label 'Setup is complete.';
        ConfigureIntegrationManagementUpdateQst: Label 'Integration Management has been enabled. You may have to generate integration records. Would you like to schedule the update job now?';
}