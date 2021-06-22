#pragma warning disable AA0235
codeunit 3999 "Reten. Pol. Install - BaseApp"
#pragma warning restore AA0235
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "Retention Period" = ri, tabledata "Retention Policy Setup" = ri;

    var
        OneMonthTok: Label 'One Month', MaxLength = 20;

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
        if UpgradeTag.HasUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag()) then
            exit;

        AddChangeLogEntryToAllowedTables();
        // if you add a new table here, also update codeunit 3995 "Base Application Logs Delete"
        RetenPolAllowedTables.AddAllowedTable(Database::"Job Queue Log Entry", JobQueueLogEntry.FieldNo("End Date/Time"));
        RetenPolAllowedTables.AddAllowedTable(Database::"Workflow Step Instance Archive");
        RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job", IntegrationSyncJob.FieldNo("Finish Date/Time"));
        RetenPolAllowedTables.AddAllowedTable(Database::"Integration Synch. Job Errors", IntegrationSynchJobErrors.FieldNo("Date/Time"));
        RetenPolAllowedTables.AddAllowedTable(Database::"Report Inbox");

        CreateRetentionPolicySetup(Database::"Integration Synch. Job", CreateOneMonthRetentionPeriod());
        CreateRetentionPolicySetup(Database::"Integration Synch. Job Errors", CreateOneMonthRetentionPeriod());

        UpgradeTag.SetUpgradeTag(GetRetenPolBaseAppTablesUpgradeTag());
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetRetenPolBaseAppTablesUpgradeTag());
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