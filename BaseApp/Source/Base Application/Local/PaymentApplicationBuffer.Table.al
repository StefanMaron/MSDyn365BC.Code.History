table 10562 "Payment Application Buffer"
{
    Caption = 'Payment Application Buffer';

    fields
    {
        field(1; "Invoice Entry No."; Integer)
        {
            Caption = 'Invoice Entry No.';
        }
        field(2; "Pmt. Entry No."; Integer)
        {
            Caption = 'Pmt. Entry No.';
        }
        field(3; "Invoice Posting Date"; Date)
        {
            Caption = 'Invoice Posting Date';
        }
        field(4; "Invoice Receipt Date"; Date)
        {
            Caption = 'Invoice Receipt Date';
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(6; "Pmt. Posting Date"; Date)
        {
            Caption = 'Pmt. Posting Date';
        }
        field(7; "Invoice Is Open"; Boolean)
        {
            Caption = 'Invoice Is Open';
        }
        field(10; "Invoice Doc. No."; Code[20])
        {
            Caption = 'Invoice Doc. No.';
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
        }
        field(12; "Inv. External Document No."; Code[35])
        {
            Caption = 'Inv. External Document No.';
        }
    }

    keys
    {
        key(Key1; "Invoice Entry No.", "Pmt. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CopyFromInvoiceVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Invoice Entry No." := VendorLedgerEntry."Entry No.";
        "Vendor No." := VendorLedgerEntry."Vendor No.";
        "Inv. External Document No." := VendorLedgerEntry."External Document No.";
        "Invoice Doc. No." := VendorLedgerEntry."Document No.";
        "Invoice Posting Date" := VendorLedgerEntry."Posting Date";
        if VendorLedgerEntry."Invoice Receipt Date" = 0D then
            "Invoice Receipt Date" := VendorLedgerEntry."Document Date"
        else
            "Invoice Receipt Date" := VendorLedgerEntry."Invoice Receipt Date";
        "Due Date" := VendorLedgerEntry."Due Date";
        "Invoice Is Open" := VendorLedgerEntry.Open;
    end;
}

