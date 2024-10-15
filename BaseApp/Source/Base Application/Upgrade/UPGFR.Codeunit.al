codeunit 104101 "UPG.FR"
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

        UpgradeDetailedCVLedgerEntries;
#if not CLEAN23
        UpgradePaymentPractices();
#endif
    end;

    local procedure UpgradeDetailedCVLedgerEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag) THEN
            EXIT;

        CODEUNIT.RUN(CODEUNIT::"Update Dtld. CV Ledger Entries");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag);
    end;

#if not CLEAN23
    local procedure UpgradePaymentPractices()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag()) then
            exit;

        if Customer.FindSet(true) then
            repeat
                Customer."Exclude from Pmt. Practices" := Customer."Exclude from Payment Reporting";
            until Customer.Next() = 0;

        if Vendor.FindSet(true) then
            repeat
                Vendor."Exclude from Pmt. Practices" := Vendor."Exclude from Payment Reporting";
            until Vendor.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag());
    end;
#endif
}

