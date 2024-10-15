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

        UpgradeDetailedCVLedgerEntries();
#if not CLEAN23
        UpgradePaymentPractices();
#endif
    end;

    local procedure UpgradeDetailedCVLedgerEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag()) THEN
            EXIT;

        CODEUNIT.RUN(CODEUNIT::"Update Dtld. CV Ledger Entries");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag());
    end;

#if not CLEAN23
    local procedure UpgradePaymentPractices()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag()) then
            exit;

        UpgradePaymentPractices_Vendor();
        UpgradePaymentPractices_Customer();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag());
    end;

    local procedure UpgradePaymentPractices_Vendor()
    var
        Vendor: Record Vendor;
        DataTransfer: Datatransfer;
    begin
        DataTransfer.SetTables(Database::Vendor, Database::Vendor);
        DataTransfer.AddFieldValue(Vendor.FieldNo("Exclude from Payment Reporting"), Vendor.FieldNo("Exclude from Pmt. Practices"));
        DataTransfer.CopyFields();
    end;

    local procedure UpgradePaymentPractices_Customer()
    var
        Customer: Record Customer;
        DataTransfer: Datatransfer;
    begin
        DataTransfer.SetTables(Database::Customer, Database::Customer);
        DataTransfer.AddFieldValue(Customer.FieldNo("Exclude from Payment Reporting"), Customer.FieldNo("Exclude from Pmt. Practices"));
        DataTransfer.CopyFields();
    end;

#endif
}

