codeunit 4000 "Hybrid Cloud Install"
{
    Subtype = Install;

    var
        DataSyncWizardPageNameTxt: Label 'Set up Cloud Migration';
        CloudMigrationDescriptionTxt: Label 'Migrate data from your on-premises environment to Business Central.';
        HelpLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2013440', Locked = true;

    trigger OnInstallAppPerCompany();
    var
        HybridCueSetupManagement: Codeunit "Hybrid Cue Setup Management";
    begin
        HybridCueSetupManagement.InsertDataForReplicationSuccessRateCue();
        UpdateHybridReplicationDetailRecords();
    end;

    // This upgrade logic is to address moving the value of the "Replication Type" field
    // into the "Trigger Type" field, which is more accurate to what the values represented.
    [Obsolete('No longer needed.', '16.2')]
    procedure UpdateHybridReplicationSummaryRecords()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        LocalOption: Option Scheduled,Manual;
    begin
        HybridReplicationSummary.SetRange("Trigger Type", HybridReplicationSummary."Trigger Type"::Unknown);
        if HybridReplicationSummary.FindSet(true) then
            repeat
                if HybridReplicationSummary."Replication Type" = LocalOption::Scheduled then
                    HybridReplicationSummary."Trigger Type" := HybridReplicationSummary."Trigger Type"::Scheduled;

                if HybridReplicationSummary."Replication Type" = LocalOption::Manual then
                    HybridReplicationSummary."Trigger Type" := HybridReplicationSummary."Trigger Type"::Manual;

                HybridReplicationSummary."ReplicationType" := HybridReplicationSummary.ReplicationType::Normal;
                HybridReplicationSummary.Modify();
            until HybridReplicationSummary.Next() = 0;
    end;

    procedure UpdateHybridReplicationDetailRecords()
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        ErrorsInStream: InStream;
        ErrorsValue: Text;
    begin
        if HybridReplicationDetail.FindSet(true) then
            repeat
                Clear(ErrorsValue);
                Clear(ErrorsInStream);
                if HybridReplicationDetail.Errors.HasValue() then begin
                    HybridReplicationDetail.CalcFields(Errors);
                    HybridReplicationDetail.Errors.CreateInStream(ErrorsInStream, TextEncoding::UTF8);
                    ErrorsInStream.ReadText(ErrorsValue);
                    HybridReplicationDetail."Error Message" := CopyStr(ErrorsValue, 1, 2048);
                    Clear(HybridReplicationDetail.Errors);
                    HybridReplicationDetail.Modify();
                end;
            until HybridReplicationDetail.Next() = 0;
    end;

    [Obsolete('Assisted Setup is no longer added during Install', '16.0')]
    procedure AddIntelligentCloudToAssistedSetup(IsIntelligentCloudSetup: Boolean);
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        Description: Text[1024];
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Description := CopyStr(CloudMigrationDescriptionTxt, 1, 1024);
        AssistedSetup.Add(Info.Id(), PAGE::"Hybrid Cloud Setup Wizard", DataSyncWizardPageNameTxt, AssistedSetupGroup::ReadyForBusiness, '', "Video Category"::Uncategorized, HelpLinkTxt, Description);
        if IsIntelligentCloudSetup then
            AssistedSetup.Complete(PAGE::"Hybrid Cloud Setup Wizard");
    end;

    // This upgrade logic is to address the rebranding of "Intelligent Cloud" to "Cloud Migration"
    [Obsolete('No longer needed', '16.0')]
    procedure UpdateHybridReplicationAssistedSetupRecord()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Completed: Boolean;
    begin
        Completed := AssistedSetup.IsComplete(Page::"Hybrid Cloud Setup Wizard");
        AddIntelligentCloudToAssistedSetup(Completed);
    end;
}