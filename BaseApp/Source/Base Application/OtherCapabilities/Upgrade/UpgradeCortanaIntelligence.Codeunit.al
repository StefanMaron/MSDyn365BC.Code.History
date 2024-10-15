// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.CashFlow.Setup;
using System.AI;
using System.Environment;
using System.Upgrade;

codeunit 104045 "Upgrade Cortana Intelligence"
{
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

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

        if CortanaIntelligenceUsage.Get() then begin
            if not AzureAIUsage.Get() then begin
                AzureAIUsage.Init();

                AzureAIUsage.Service := CortanaIntelligenceUsage.Service;
                AzureAIUsage."Total Resource Usage" := CortanaIntelligenceUsage."Total Resource Usage";
                AzureAIUsage."Original Resource Limit" := CortanaIntelligenceUsage."Original Resource Limit";
                AzureAIUsage."Limit Period" := CortanaIntelligenceUsage."Limit Period";
                AzureAIUsage."Last DateTime Updated" := CortanaIntelligenceUsage."Last DateTime Updated";

                AzureAIUsage.Insert();
            end;

            CortanaIntelligenceUsage.DeleteAll();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCortanaIntelligenceUsageUpgradeTag());
    end;
}