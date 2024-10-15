// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Bank.BankAccount;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 104010 "Upg Set Country App Areas"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        SetCountryAppAreas();
        MoveGLBankAccountNoToGLAccountNo();
    end;

    local procedure SetCountryAppAreas()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag()) THEN
            EXIT;

        IF ApplicationAreaSetup.GET() AND ApplicationAreaSetup.Basic THEN BEGIN
            ApplicationAreaSetup.VAT := TRUE;
            ApplicationAreaSetup."Basic EU" := TRUE;
            ApplicationAreaSetup."Basic NL" := TRUE;
            ApplicationAreaSetup.Modify();
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag());
    end;

    local procedure MoveGLBankAccountNoToGLAccountNo()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetGLBankAccountNoTag()) THEN
            EXIT;

        BankAccountPostingGroup.SETFILTER("G/L Bank Account No.", '<>%1', '');
        if BankAccountPostingGroup.FINDSET(TRUE) then
            repeat
                BankAccountPostingGroup."G/L Account No." := BankAccountPostingGroup."G/L Bank Account No.";
                BankAccountPostingGroup.Modify();
            until BankAccountPostingGroup.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLBankAccountNoTag());
    end;
}

