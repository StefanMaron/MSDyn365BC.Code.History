table 31017 "Advance Link"
{
    Caption = 'Advance Link';
#if not CLEAN19
    DrillDownPageID = "Links to Advance Letter";
    LookupPageID = "Links to Advance Letter";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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
            TableRelation = IF (Type = CONST(Sale)) "Cust. Ledger Entry"
            ELSE
            IF (Type = CONST(Purchase)) "Vendor Ledger Entry";
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(9; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
            TableRelation = IF ("Entry Type" = CONST("Link To Letter")) "Sales Invoice Header"."No.";
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
#if not CLEAN19

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
#endif
}

