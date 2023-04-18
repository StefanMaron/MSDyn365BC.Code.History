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

