table 31104 "VAT Ctrl.Rep. - VAT Entry Link"
{
    Caption = 'VAT Ctrl.Rep. - VAT Entry Link';
#if CLEAN17
    ObsoleteState = Removed;
#else
    Permissions = TableData "VAT Ctrl.Rep. - VAT Entry Link" = rimd;
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Control Report No."; Code[20])
        {
            Caption = 'VAT Control Report No.';
#if not CLEAN17
            TableRelation = "VAT Control Report Header";
#endif
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
#if not CLEAN17
            TableRelation = "VAT Control Report Line"."Line No." WHERE("Control Report No." = FIELD("Control Report No."));
#endif
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

