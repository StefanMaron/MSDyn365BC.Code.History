#pragma warning disable AA0235
codeunit 3999 "Reten. Pol. Install - BaseApp"
#pragma warning restore AA0235
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "Retention Period" = ri, tabledata "Retention Policy Setup" = ri;

    var
        OneMonthTok: Label 'One Month', MaxLength = 20;
        OneWeekTok: Label 'One Week', MaxLength = 20;

    trigger OnInstallAppPerCompany()
    var
    begin
        AddAllowedTables();
    end;

    procedure AddAllowedTables()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        IntegrationSyncJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // if you add a new table here, also update codeunit 3995 "Base Application Logs Delete"
        if not UpgradeTag.HasUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag()) then begin
            AddChangeLogEntryToAllowedTables();
            RetenPolAllowedTables.AddAllowedTable(Database::"Job Queue Log Entry", JobQueueLogEntry.FieldNo("End Date/Time"));
            RetenPolAllowedTables.AddAllowedTable(Database::"Workflow Step Instance Archive");
            RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job", IntegrationSyncJob.FieldNo("Finish Date/Time"));
            RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job Errors", IntegrationSynchJobErrors.FieldNo("Date/Time"));
            RetenPolAllowedTables.AddAllowedTable(Database::"Report Inbox");
            CreateRetentionPolicySetup(Database::"Integration Synch. Job", CreateOneMonthRetentionPeriod());
            CreateRetentionPolicySetup(Database::"Integration Synch. Job Errors", CreateOneMonthRetentionPeriod());
            UpgradeTag.SetUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag()) then begin
            AddDocumentArchiveTablesToAllowedTables();
            UpgradeTag.SetUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetRetenPolDataverseEntityChangeUpgradeTag()) then begin
            AddDataverseEntityChange();
            UpgradeTag.SetUpgradeTag(GetRetenPolDataverseEntityChangeUpgradeTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetRetenPolActivityLogUpgradeTag()) then begin
            RetenPolAllowedTables.AddAllowedTable(Database::"Activity Log");
            UpgradeTag.SetUpgradeTag(GetRetenPolActivityLogUpgradeTag());
        end;
    end;

    local procedure AddChangeLogEntryToAllowedTables()
    var
        ChangeLogEntry: Record "Change Log Entry";
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        RetentionPeriod: Enum "Retention Period Enum";
        TableFilters: JsonArray;
    begin
        ChangeLogEntry.SetRange(Protected, true);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeLogEntry."Field Log Entry Feature"::All);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"28 Days", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        RetenPolAllowedTables.AddAllowedTable(Database::"Change Log Entry", ChangeLogEntry.FieldNo(SystemCreatedAt), TableFilters);

        if RetentionPolicySetup.Get(Database::"Change Log Entry") then
            exit;

        RetentionPolicySetup.Validate("Table Id", Database::"Change Log Entry");
        RetentionPolicySetup.Insert(true);
    end;

    local procedure AddDocumentArchiveTablesToAllowedTables()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        RetentionPeriod: Enum "Retention Period Enum";
        RetenPolFiltering: Enum "Reten. Pol. Filtering";
        RetenPolDeleting: Enum "Reten. Pol. Deleting";
        TableFilters: JsonArray;
    begin
        SalesHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        SalesHeaderArchive.Reset();
        SalesHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Sales Header Archive", SalesHeaderArchive.FieldNo("Last Archived Date"), 0, RetenPolFiltering::"Document Archive Filtering", RetenPolDeleting::Default, TableFilters);

        Clear(TableFilters);
        PurchaseHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(PurchaseHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        PurchaseHeaderArchive.Reset();
        PurchaseHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, RetentionPeriod::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Purchase Header Archive", PurchaseHeaderArchive.FieldNo("Last Archived Date"), 0, RetenPolFiltering::"Document Archive Filtering", RetenPolDeleting::Default, TableFilters);
    end;

    local procedure AddDataverseEntityChange()
    var
        DataverseEntityChange: Record "Dataverse Entity Change";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Dataverse Entity Change", DataverseEntityChange.FieldNo(SystemCreatedAt));
        CreateRetentionPolicySetup(Database::"Dataverse Entity Change", CreateOneWeekRetentionPeriod());
        EnableRetentionPolicySetup(Database::"Dataverse Entity Change");
    end;

    local procedure CreateOneMonthRetentionPeriod(): Code[20]
    var
        RetentionPeriod: Record "Retention Period";
    begin
        if RetentionPeriod.Get(OneMonthTok) then
            exit(RetentionPeriod.Code);

        RetentionPeriod.SetRange("Retention Period", RetentionPeriod."Retention Period"::"1 Month");
        if RetentionPeriod.FindFirst() then
            exit(RetentionPeriod.Code);

        RetentionPeriod.Code := CopyStr(UpperCase(OneMonthTok), 1, MaxStrLen(RetentionPeriod.Code));
        RetentionPeriod.Description := OneMonthTok;
        RetentionPeriod.Validate("Retention Period", RetentionPeriod."Retention Period"::"1 Month");
        RetentionPeriod.Insert(true);
        exit(RetentionPeriod.Code);
    end;

    local procedure CreateOneWeekRetentionPeriod(): Code[20]
    var
        RetentionPeriod: Record "Retention Period";
    begin
        if RetentionPeriod.Get(OneWeekTok) then
            exit(RetentionPeriod.Code);

        RetentionPeriod.SetRange("Retention Period", RetentionPeriod."Retention Period"::"1 Week");
        if RetentionPeriod.FindFirst() then
            exit(RetentionPeriod.Code);

        RetentionPeriod.Code := CopyStr(UpperCase(OneWeekTok), 1, MaxStrLen(RetentionPeriod.Code));
        RetentionPeriod.Description := OneWeekTok;
        RetentionPeriod.Validate("Retention Period", RetentionPeriod."Retention Period"::"1 Week");
        RetentionPeriod.Insert(true);
        exit(RetentionPeriod.Code);
    end;

    local procedure CreateRetentionPolicySetup(TableId: Integer; RetentionPeriodCode: Code[20])
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(TableId) then
            exit;
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate(Enabled, false);
        RetentionPolicySetup.Insert(true);
    end;

    local procedure EnableRetentionPolicySetup(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TaskScheduler.CanCreateTask() then
            exit;

        if not (JobQueueEntry.ReadPermission() and JobQueueEntry.WritePermission()) then
            exit;

        if not JobQueueEntry.TryCheckRequiredPermissions() then
            exit;

        if not RetentionPolicySetup.Get(TableId) then
            exit;

        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Modify(true);
    end;

    local procedure GetRetenPolBaseAppTablesUpgradeTag(): Code[250]
    begin
        exit('MS-334067-RetenPolBaseAppTables-20200801');
    end;

    local procedure GetRetenPolDocArchivesTablesUpgradeTag(): Code[250]
    begin
        exit('MS-378964-RetenPolDocArchives-20210423');
    end;

    local procedure GetRetenPolDataverseEntityChangeUpgradeTag(): Code[250]
    begin
        exit('MS-434662-RetenPolDataverseEntityChange-20220428');
    end;

    local procedure GetRetenPolActivityLogUpgradeTag(): Code[250]
    begin
        exit('MS-436257-RetenPolActivityLog-20220526');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeOnRun', '', false, false)]
    local procedure AddAllowedTablesOnBeforeCompanyInit()
    var
        SystemInitialization: Codeunit "System Initialization";
    begin
        if SystemInitialization.IsInProgress() then
            AddAllowedTables();
    end;
}