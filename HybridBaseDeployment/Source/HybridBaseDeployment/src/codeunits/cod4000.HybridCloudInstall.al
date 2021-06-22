codeunit 4000 "Hybrid Cloud Install"
{
    Subtype = Install;

    var
        DataSyncWizardPageNameTxt: Label 'Set up Cloud Migration';

    trigger OnInstallAppPerCompany();
    var
        HybridCueSetupManagement: Codeunit "Hybrid Cue Setup Management";
    begin
        HybridCueSetupManagement.InsertDataForReplicationSuccessRateCue();
        UpdateHybridReplicationSummaryRecords();
    end;

    // This upgrade logic is to address moving the value of the "Replication Type" field
    // into the "Trigger Type" field, which is more accurate to what the values represented.
    procedure UpdateHybridReplicationSummaryRecords()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        HybridReplicationSummary.SetRange("Trigger Type", HybridReplicationSummary."Trigger Type"::Unknown);
        if HybridReplicationSummary.FindSet(true) then
            repeat
                HybridReplicationSummary."Trigger Type" := HybridReplicationSummary."Replication Type" + 1;
                HybridReplicationSummary."ReplicationType" := HybridReplicationSummary.ReplicationType::Normal;
                HybridReplicationSummary.Modify();
            until HybridReplicationSummary.Next() = 0;
    end;

    procedure AddIntelligentCloudToAssistedSetup(IsIntelligentCloudSetup: Boolean);
    var
        assistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        assistedSetup.Add(Info.Id(), PAGE::"Hybrid Cloud Setup Wizard", DataSyncWizardPageNameTxt, AssistedSetupGroup::GettingStarted);
        if IsIntelligentCloudSetup then
            assistedSetup.Complete(Info.Id(), PAGE::"Hybrid Cloud Setup Wizard");
    end;

    // This upgrade logic is to address the rebranding of "Intelligent Cloud" to "Cloud Migration"
    procedure UpdateHybridReplicationAssistedSetupRecord()
    var
        assistedSetup: Codeunit "Assisted Setup";
        emptyGuid: Guid;
        completed: Boolean;
    begin
        completed := assistedSetup.IsComplete(EmptyGuid, PAGE::"Hybrid Cloud Setup Wizard");
        AddIntelligentCloudToAssistedSetup(completed);
    end;
}