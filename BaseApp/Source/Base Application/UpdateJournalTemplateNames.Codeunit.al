#if not CLEAN20
codeunit 11390 "Update Journal Template Names"
{
    var
        ConfirmCopyTxt: Label 'This procedure will copy values from local Journal Template Name to new Journal Templ. Name if new field in the record is empty. Do you want to copy them?';

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponse(ConfirmCopyTxt, true) then
            exit;

        UpgradeGenJournalTemplates();
        UpgradeGLEntryJournalTemplateName();
        UpgradeGLRegisterJournalTemplateName();
        UpgradeVATEntryJournalTemplateName();
        UpgradeBankAccLedgerEntryJournalTemplateName();
        UpgradeCustLedgerEntryJournalTemplateName();
        UpgradeEmplLedgerEntryJournalTemplateName();
        UpgradeVendLedgerEntryJournalTemplateName();
        UpgradePurchaseHeaderJournalTemplateName();
        UpgradeSalesHeaderJournalTemplateName();
        UpgradeServiceHeaderJournalTemplateName();
    end;

    local procedure UpgradeGenJournalTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetLoadFields(
            "Allow Posting Date From", "Allow Posting Date To", "Allow Posting From", "Allow Posting To");
        if GenJournalTemplate.FindSet() then
            repeat
                if (GenJournalTemplate."Allow Posting From" <> 0D) or (GenJournalTemplate."Allow Posting To" <> 0D) then begin
                    if GenJournalTemplate."Allow Posting Date From" <> 0D then
                        GenJournalTemplate."Allow Posting Date From" := GenJournalTemplate."Allow Posting From";
                    if GenJournalTemplate."Allow Posting Date To" <> 0D then
                        GenJournalTemplate."Allow Posting Date To" := GenJournalTemplate."Allow Posting To";
                    GenJournalTemplate.Modify();
                end;
            until GenJournalTemplate.Next() = 0;
    end;

    local procedure UpgradeGLEntryJournalTemplateName()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        GLEntry.SetFilter("Journal Template Name", '<>%1', '');
        GLEntry.SetRange("Journal Templ. Name", '');
        if GLEntry.FindSet() then
            repeat
                GLEntry."Journal Templ. Name" := GLEntry."Journal Template Name";
                GLEntry.Modify();
            until GLEntry.Next() = 0;
    end;

    local procedure UpgradeGLRegisterJournalTemplateName()
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        GLRegister.SetFilter("Journal Template Name", '<>%1', '');
        GLRegister.SetRange("Journal Templ. Name", '');
        if GLRegister.FindSet() then
            repeat
                GLRegister."Journal Templ. Name" := GLRegister."Journal Template Name";
                GLRegister.Modify();
            until GLRegister.Next() = 0;
    end;

    local procedure UpgradeVATEntryJournalTemplateName()
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        VATEntry.SetFilter("Journal Template Name", '<>%1', '');
        VATEntry.SetRange("Journal Templ. Name", '');
        if VATEntry.FindSet() then
            repeat
                VATEntry."Journal Templ. Name" := VATEntry."Journal Template Name";
                VATEntry.Modify();
            until VATEntry.Next() = 0;
    end;

    local procedure UpgradeBankAccLedgerEntryJournalTemplateName()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        BankAccountLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        BankAccountLedgerEntry.SetRange("Journal Templ. Name", '');
        if BankAccountLedgerEntry.FindSet() then
            repeat
                BankAccountLedgerEntry."Journal Templ. Name" := BankAccountLedgerEntry."Journal Template Name";
                BankAccountLedgerEntry.Modify();
            until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeCustLedgerEntryJournalTemplateName()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        CustLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        CustLedgerEntry.SetRange("Journal Templ. Name", '');
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry."Journal Templ. Name" := CustLedgerEntry."Journal Template Name";
                CustLedgerEntry.Modify();
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeEmplLedgerEntryJournalTemplateName()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        EmployeeLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        EmployeeLedgerEntry.SetRange("Journal Templ. Name", '');
        if EmployeeLedgerEntry.FindSet() then
            repeat
                EmployeeLedgerEntry."Journal Templ. Name" := EmployeeLedgerEntry."Journal Template Name";
                EmployeeLedgerEntry.Modify();
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeVendLedgerEntryJournalTemplateName()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        VendLedgerEntry.SetFilter("Journal Template Name", '<>%1', '');
        VendLedgerEntry.SetRange("Journal Templ. Name", '');
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry."Journal Templ. Name" := VendLedgerEntry."Journal Template Name";
                VendLedgerEntry.Modify();
            until VendLedgerEntry.Next() = 0;
    end;

    local procedure UpgradeSalesHeaderJournalTemplateName()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        SalesHeader.SetFilter("Journal Template Name", '<>%1', '');
        SalesHeader.SetRange("Journal Templ. Name", '');
        if SalesHeader.FindSet() then
            repeat
                SalesHeader."Journal Templ. Name" := SalesHeader."Journal Template Name";
                SalesHeader.Modify();
            until SalesHeader.Next() = 0;
    end;

    local procedure UpgradeServiceHeaderJournalTemplateName()
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        ServiceHeader.SetFilter("Journal Template Name", '<>%1', '');
        ServiceHeader.SetRange("Journal Templ. Name", '');
        if ServiceHeader.FindSet() then
            repeat
                ServiceHeader."Journal Templ. Name" := ServiceHeader."Journal Template Name";
                ServiceHeader.Modify();
            until ServiceHeader.Next() = 0;
    end;

    local procedure UpgradePurchaseHeaderJournalTemplateName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetLoadFields("Journal Templ. Name", "Journal Template Name");
        PurchaseHeader.SetFilter("Journal Template Name", '<>%1', '');
        PurchaseHeader.SetRange("Journal Templ. Name", '');
        if PurchaseHeader.FindSet() then
            repeat
                PurchaseHeader."Journal Templ. Name" := PurchaseHeader."Journal Template Name";
                PurchaseHeader.Modify();
            until PurchaseHeader.Next() = 0;
    end;
}
#endif