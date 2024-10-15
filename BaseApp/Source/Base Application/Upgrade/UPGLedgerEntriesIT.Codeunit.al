codeunit 104151 "UPG.IT Detailed Ledger Entries"
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

        UpgradeDetailedVendorLedgerEntries();
        UpgradeDetailedCustomerLedgerEntries();
    end;

    procedure UpgradeDetailedVendorLedgerEntries();
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTags.GetFixRemainingAmountVLEUpgradeTag()) THEN
            exit;

        IF VendorLedgerEntry.FindSet() then
            repeat
                DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                DetailedVendorLedgEntry.ModifyAll("Original Document No.", VendorLedgerEntry."Document No.");
                DetailedVendorLedgEntry.ModifyAll("Original Document Type", VendorLedgerEntry."Document Type");
            until VendorLedgerEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetFixRemainingAmountVLEUpgradeTag());
    end;

    procedure UpgradeDetailedCustomerLedgerEntries();
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTags.GetFixRemainingAmountCLEUpgradeTag()) THEN
            exit;

        IF CustLedgerEntry.FindSet() then
            repeat
                DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                DetailedCustLedgEntry.ModifyAll("Original Document No.", CustLedgerEntry."Document No.");
                DetailedCustLedgEntry.ModifyAll("Original Document Type", CustLedgerEntry."Document Type");
            until CustLedgerEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetFixRemainingAmountCLEUpgradeTag());
    end;
}

