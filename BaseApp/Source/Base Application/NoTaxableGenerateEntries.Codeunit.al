codeunit 10840 "No Taxable - Generate Entries"
{
    Permissions = TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
        UpdateNoTaxableVATEntries;

        if CheckNoTaxableEntriesExist then
            exit;

        InsertNoTaxableEntryCustomer;
        InsertNoTaxableEntryVendor;
    end;

    var
        NoTaxableMgt: Codeunit "No Taxable Mgt.";

    local procedure CheckNoTaxableEntriesExist(): Boolean
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        exit(not NoTaxableEntry.IsEmpty);
    end;

    local procedure InsertNoTaxableEntryVendor()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with VendorLedgerEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetRange(Reversed, false);
            if FindSet then
                repeat
                    NoTaxableMgt.UpdateNoTaxableEntryFromVendorLedgerEntry(VendorLedgerEntry);
                until Next = 0;
        end;
    end;

    local procedure InsertNoTaxableEntryCustomer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgerEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetRange(Reversed, false);
            if FindSet then
                repeat
                    NoTaxableMgt.UpdateNoTaxableEntryFromCustomerLedgerEntry(CustLedgerEntry);
                until Next = 0;
        end;
    end;

    local procedure UpdateNoTaxableVATEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        VATPostingSetup.SetFilter("No Taxable Type", '>%1', VATPostingSetup."No Taxable Type"::" ");
        if VATPostingSetup.FindSet then
            repeat
                VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                if not VATEntry.IsEmpty then
                    VATEntry.ModifyAll("No Taxable Type", VATPostingSetup."No Taxable Type");
            until VATPostingSetup.Next = 0;
    end;
}

