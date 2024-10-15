namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;

table 317 "Payable Vendor Ledger Entry"
{
    Caption = 'Payable Vendor Ledger Entry';

    fields
    {
        field(1; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Vendor Ledg. Entry No."; Integer)
        {
            Caption = 'Vendor Ledg. Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(5; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(6; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(8; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(9; Future; Boolean)
        {
            Caption = 'Future';
        }
        field(32000000; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
        }
    }

    keys
    {
        key(Key1; Priority, "Vendor No.", "Currency Code", Positive, Future, "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

