table 31104 "VAT Ctrl.Rep. - VAT Entry Link"
{
    Caption = 'VAT Ctrl.Rep. - VAT Entry Link';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Control Report No."; Code[20])
        {
            Caption = 'VAT Control Report No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "Control Report No.", "Line No.", "VAT Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}
