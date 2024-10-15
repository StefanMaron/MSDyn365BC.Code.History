codeunit 104153 "Copy Inv. No. To Pmt. Ref"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        SetCopyInvNoToPmtRef();
    end;

    local procedure SetCopyInvNoToPmtRef()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCopyInvNoToPmtRefTag()) THEN
            exit;

        IF PurchasesPayablesSetup.Get() THEN BEGIN
            PurchasesPayablesSetup."Copy Inv. No. To Pmt. Ref." := true;
            PurchasesPayablesSetup.Modify();
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCopyInvNoToPmtRefTag());
    end;
}

