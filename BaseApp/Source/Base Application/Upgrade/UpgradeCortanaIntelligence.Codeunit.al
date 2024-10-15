codeunit 14040 "Upgrade Cortana Intelligence"
{
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";

    trigger OnUpgradePerCompany()
    begin
        UpgradeCashFlowCortanaIntelligenceFields();
        UpgradeCortanaIntelligenceUsageTable();
    end;

    // "Show Cortana Notification" and "Cortana Intelligence Enabled" fields in "Cash Flow" are being 
    // deprecated and replaced by "Show AzureAI Notification" and "Azure AI Enabled", respectively.
    local procedure UpgradeCashFlowCortanaIntelligenceFields()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCashFlowCortanaFieldsUpgradeTag()) then
            exit;

        if not CashFlowSetup.Get() then
            exit;

        CashFlowSetup."Show AzureAI Notification" := CashFlowSetup."Show Cortana Notification";
        CashFlowSetup."Azure AI Enabled" := CashFlowSetup."Cortana Intelligence Enabled";
        
        CashFlowSetup.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCashFlowCortanaFieldsUpgradeTag());
    end;

    // "Cortana Intelligence Usage" table is being deprecated and replaced by "Azure AI Usage".
    local procedure UpgradeCortanaIntelligenceUsageTable()
    var
        CortanaIntelligenceUsage: Record "Cortana Intelligence Usage";
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCortanaIntelligenceUsageUpgradeTag()) then
            exit;

        if not CortanaIntelligenceUsage.Get() then
            exit;

        AzureAIUsage.Init();

        AzureAIUsage.Service := CortanaIntelligenceUsage.Service;
        AzureAIUsage."Total Resource Usage" := CortanaIntelligenceUsage."Total Resource Usage";
        AzureAIUsage."Original Resource Limit" := CortanaIntelligenceUsage."Original Resource Limit";
        AzureAIUsage."Limit Period" := CortanaIntelligenceUsage."Limit Period";
        AzureAIUsage."Last DateTime Updated" := CortanaIntelligenceUsage."Last DateTime Updated";

        AzureAIUsage.Insert();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCortanaIntelligenceUsageUpgradeTag());
    end;
}