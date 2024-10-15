codeunit 104150 "UPG GB"
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

        UpgradeIntrastatSetup();
#if not CLEAN23
        UpgradePaymentPractices();
#endif
    end;

    local procedure UpgradeIntrastatSetup()
    var
        IntrastatSetup: Record "Intrastat Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateIntrastatSetupTag()) then
            exit;

        if not IntrastatSetup.Get() then
            exit;

        IntrastatSetup."Company VAT No. on File" := IntrastatSetup."Company VAT No. on File"::"VAT Reg. No. Without EU Country Code";
        IntrastatSetup.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateIntrastatSetupTag());
    end;

#if not CLEAN23
    local procedure UpgradePaymentPractices()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag()) then
            exit;

        UpgradePaymentPractices_GJL();

        UpgradePaymentPractices_PGJL();

        UpgradePaymentPractices_VLE();

        UpgradePaymentPractices_PH();

        UpgradePaymentPractices_Vendor();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag());
    end;

    local procedure UpgradePaymentPractices_GJL()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::"Gen. Journal Line", Database::"Gen. Journal Line");
        DataTransfer.AddFieldValue(GenJournalLine.FieldNo("Invoice Receipt Date"), GenJournalLine.FieldNo("Invoice Received Date"));
        DataTransfer.CopyFields();
    end;

    local procedure UpgradePaymentPractices_PGJL()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::"Posted Gen. Journal Line", Database::"Posted Gen. Journal Line");
        DataTransfer.AddFieldValue(PostedGenJournalLine.FieldNo("Invoice Receipt Date"), PostedGenJournalLine.FieldNo("Invoice Received Date"));
        DataTransfer.CopyFields();
    end;

    local procedure UpgradePaymentPractices_VLE()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::"Vendor Ledger Entry", Database::"Vendor Ledger Entry");
        DataTransfer.AddFieldValue(VendorLedgerEntry.FieldNo("Invoice Receipt Date"), VendorLedgerEntry.FieldNo("Invoice Received Date"));
        DataTransfer.CopyFields();
    end;

    local procedure UpgradePaymentPractices_PH()
    var
        PurchaseHeader: Record "Purchase Header";
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::"Purchase Header", Database::"Purchase Header");
        DataTransfer.AddFieldValue(PurchaseHeader.FieldNo("Invoice Receipt Date"), PurchaseHeader.FieldNo("Invoice Received Date"));
        DataTransfer.CopyFields();
    end;

    local procedure UpgradePaymentPractices_Vendor()
    var
        Vendor: Record Vendor;
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::Vendor, Database::Vendor);
        DataTransfer.AddFieldValue(Vendor.FieldNo("Exclude from Pmt. Pract. Rep."), Vendor.FieldNo("Exclude from Pmt. Practices"));
        DataTransfer.CopyFields();
    end;
#endif
}

