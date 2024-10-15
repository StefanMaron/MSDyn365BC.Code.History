#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Inventory.Intrastat;
using System.Environment;
using System.Upgrade;

codeunit 104011 "Upg Advanced Checklist Setup"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        BaseDemoDataSetup();
    end;

    local procedure BaseDemoDataSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAdvancedIntrastatBaseDemoDataUpgradeTag()) then
            exit;

        IntraJnlManagement.CreateDefaultAdvancedIntrastatSetup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAdvancedIntrastatBaseDemoDataUpgradeTag());
    end;
}
#endif