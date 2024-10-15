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
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateIntrastatSetupTag()) then
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
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag()) then
            exit;

        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine."Invoice Received Date" := GenJournalLine."Invoice Receipt Date";
            until GenJournalLine.Next() = 0;

        if PostedGenJournalLine.FindSet(true) then
            repeat
                PostedGenJournalLine."Invoice Received Date" := PostedGenJournalLine."Invoice Receipt Date";
            until PostedGenJournalLine.Next() = 0;

        if VendorLedgerEntry.FindSet(true) then
            repeat
                VendorLedgerEntry."Invoice Received Date" := VendorLedgerEntry."Invoice Receipt Date";
            until VendorLedgerEntry.Next() = 0;

        if PurchaseHeader.FindSet(true) then
            repeat
                PurchaseHeader."Invoice Received Date" := PurchaseHeader."Invoice Receipt Date";
            until PurchaseHeader.Next() = 0;

        if Vendor.FindSet(true) then
            repeat
                Vendor."Exclude from Pmt. Practices" := Vendor."Exclude from Pmt. Pract. Rep.";
            until Vendor.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradePaymentPracticesTag());
    end;
#endif
}

