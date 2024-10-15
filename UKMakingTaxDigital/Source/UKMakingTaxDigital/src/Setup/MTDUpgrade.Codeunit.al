// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 10540 "MTD Upgrade"
{
    Subtype = Upgrade;

    var
        MTDMgt: Codeunit "MTD Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";

    trigger OnUpgradePerCompany()
    begin
        UpgradeVATReportSetup();
        UpgradeDailyLimit();
    end;

    local procedure UpgradeVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        MTDInstall: Codeunit "MTD Install";
        IsModify: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(MTDMgt.GetVATReportSetupUpgradeTag()) then
            exit;

        with VATReportSetup do
            if Get() then begin
                IsModify := MTDInstall.InitProductionMode(VATReportSetup);
                IsModify := IsModify or MTDInstall.InitPeriodReminderCalculation(VATReportSetup);
                if IsModify then
                    if Modify() then;
            end;

        UpgradeTag.SetUpgradeTag(MTDMgt.GetVATReportSetupUpgradeTag());
    end;

    local procedure UpgradeDailyLimit()
    var
        DummyOAuth20Setup: Record "OAuth 2.0 Setup";
        MTDOAuth20Mgt: Codeunit "MTD OAuth 2.0 Mgt";
    begin
        if UpgradeTag.HasUpgradeTag(MTDMgt.GetDailyLimitUpgradeTag()) then
            exit;

        MTDOAuth20Mgt.InitOAuthSetup(DummyOAuth20Setup, MTDOAuth20Mgt.GetOAuthPRODSetupCode());

        UpgradeTag.SetUpgradeTag(MTDMgt.GetDailyLimitUpgradeTag());
    end;
}
