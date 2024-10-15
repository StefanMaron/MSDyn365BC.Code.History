#pragma warning disable AA0235
codeunit 3999 "Reten. Pol. Install - BaseApp"
#pragma warning restore AA0235
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "Retention Period" = ri, tabledata "Retention Policy Setup" = ri;

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
            CreateRetentionPolicySetup(Database::"Integration Synch. Job", FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Month"));
            CreateRetentionPolicySetup(Database::"Integration Synch. Job Errors", FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Month"));
            UpgradeTag.SetUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag()) then begin
            AddDocumentArchiveTablesToAllowedTables();
            UpgradeTag.SetUpgradeTag(GetRetenPolDocArchivesTablesUpgradeTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GetRetenPolProtectedChangeLogUpgradeTag()) then begin
            AddChangeLogEntryToAllowedTables();
            UpgradeTag.SetUpgradeTag(GetRetenPolProtectedChangeLogUpgradeTag());
        end;
    end;

    local procedure AddChangeLogEntryToAllowedTables()
    var
        ChangeLogEntry: Record "Change Log Entry";
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        ChangeLogEntry.SetRange(Protected, true);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"1 Year", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetFilter("Field Log Entry Feature", '%1|%2', ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields", ChangeLogEntry."Field Log Entry Feature"::All);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"28 Days", ChangeLogEntry.FieldNo(SystemCreatedAt), true, true, RecRef);

        ChangeLogEntry.Reset();
        ChangeLogEntry.SetRange(Protected, false);
        RecRef.GetTable(ChangeLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"1 Year", ChangeLogEntry.FieldNo(SystemCreatedAt), true, false, RecRef);

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
        TableFilters: JsonArray;
    begin
        SalesHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        SalesHeaderArchive.Reset();
        SalesHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", SalesHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Sales Header Archive", SalesHeaderArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);

        Clear(TableFilters);
        PurchaseHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(PurchaseHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        PurchaseHeaderArchive.Reset();
        PurchaseHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(SalesHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", PurchaseHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Purchase Header Archive", PurchaseHeaderArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);
    end;

    local procedure FindOrCreateRetentionPeriod(RetentionPeriodEnum: Enum "Retention Period Enum"): Code[20]
    var
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        exit(RetentionPolicySetup.FindOrCreateRetentionPeriod(RetentionPeriodEnum))
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

    local procedure GetRetenPolBaseAppTablesUpgradeTag(): Code[250]
    begin
        exit('MS-334067-RetenPolBaseAppTables-20200801');
    end;

    local procedure GetRetenPolDocArchivesTablesUpgradeTag(): Code[250]
    begin
        exit('MS-378964-RetenPolDocArchives-20210423');
    end;

    local procedure GetRetenPolProtectedChangeLogUpgradeTag(): Code[250]
    begin
        exit('MS-447066-RetenPolProtectedChangeLog-20221003');
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