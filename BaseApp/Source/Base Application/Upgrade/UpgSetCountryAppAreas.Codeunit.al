codeunit 104010 "Upg Set Country App Areas"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
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

        IF ApplicationAreaSetup.GET AND ApplicationAreaSetup.Basic THEN BEGIN
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
        IF BankAccountPostingGroup.FINDSET(TRUE) THEN BEGIN
            REPEAT
                BankAccountPostingGroup."G/L Account No." := BankAccountPostingGroup."G/L Bank Account No.";
                BankAccountPostingGroup.Modify();
            UNTIL BankAccountPostingGroup.NEXT = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetGLBankAccountNoTag());
    end;
}

