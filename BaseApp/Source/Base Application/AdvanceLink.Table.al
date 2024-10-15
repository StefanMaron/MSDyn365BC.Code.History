table 31017 "Advance Link"
{
    Caption = 'Advance Link';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Initial Amount,Link To Letter,Application';
            OptionMembers = "Initial Amount","Link To Letter",Application;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(6; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
        }
        field(7; "CV Ledger Entry No."; Integer)
        {
            Caption = 'CV Ledger Entry No.';
            TableRelation = if (Type = const(Sale)) "Cust. Ledger Entry"
            else
            if (Type = const(Purchase)) "Vendor Ledger Entry";
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(9; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
            TableRelation = if ("Entry Type" = const("Link To Letter")) "Sales Invoice Header"."No.";
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        field(20; "Remaining Amount to Deduct"; Decimal)
        {
            Caption = 'Remaining Amount to Deduct';
        }
        field(21; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sale,Purchase';
            OptionMembers = Sale,Purchase;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "CV Ledger Entry No.", "Entry Type", "Document No.", "Line No.")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Remaining Amount to Deduct";
        }
        key(Key3; "Document No.", "Line No.", "Entry Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key4; "Invoice No.", "Document No.", "Entry Type")
        {
        }
        key(Key5; "Entry Type", "Document No.", "Line No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}

