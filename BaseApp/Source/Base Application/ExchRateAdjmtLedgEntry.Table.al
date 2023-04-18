table 186 "Exch. Rate Adjmt. Ledg. Entry"
{
    Caption = 'Exch. Rate Adjmt. Ledger Entry';
    DrillDownPageID = "Exch.Rate Adjmt. Ledg.Entries";
    LookupPageID = "Exch.Rate Adjmt. Ledg.Entries";

    fields
    {
        field(1; "Register No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'No.';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(9; "Account Type"; Enum "Exch. Rate Adjmt. Account Type")
        {
            Caption = 'Account Type';
        }
        field(10; "Account Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(12; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            Editable = false;
        }
        field(15; "Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Base Amount';
            Editable = false;
        }
        field(16; "Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base Amount (LCY)';
            Editable = false;
        }
        field(17; "Adjustment Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Adjustment Amount';
            Editable = false;
        }
        field(19; "Detailed Ledger Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(20; "Detailed Ledger Entry No."; Decimal)
        {
            Caption = 'Detailed Ledger Entry No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Register No.", "Entry No.")
        {
            Clustered = true;
        }
    }
}
