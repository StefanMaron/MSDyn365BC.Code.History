codeunit 104152 "UPG.VAT Report IT"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpgradeVATReportHeader();
    end;

    procedure UpgradeVATReportHeader();
    var
        VATReportHeader: Record "VAT Report Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTags.GetVATReportTaxAuthDocNoUpgradeTag()) THEN
            exit;

        IF VATReportHeader.FindSet() then
            repeat
                VATReportHeader."Tax Auth. Document No." := VATReportHeader."Tax Auth. Doc. No.";
                VATReportHeader.Modify();
            until VATReportHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetVATReportTaxAuthDocNoUpgradeTag());
    end;
}

