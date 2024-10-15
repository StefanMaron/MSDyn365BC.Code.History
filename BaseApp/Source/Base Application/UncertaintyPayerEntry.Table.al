table 11760 "Uncertainty Payer Entry"
{
    Caption = 'Uncertainty Payer Entry';
    DrillDownPageID = "Uncertainty Payer Entries";
    LookupPageID = "Uncertainty Payer Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(8; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(20; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        field(21; "Public Date"; Date)
        {
            Caption = 'Public Date';
        }
        field(22; "End Public Date"; Date)
        {
            Caption = 'End Public Date';
        }
        field(25; "Uncertainty Payer"; Option)
        {
            Caption = 'Uncertainty Payer';
            OptionCaption = ' ,NO,YES,NOTFOUND';
            OptionMembers = " ",NO,YES,NOTFOUND;
        }
        field(30; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Payer,Bank Account';
            OptionMembers = Payer,"Bank Account";
        }
        field(40; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(50; "Tax Office Number"; Code[10])
        {
            Caption = 'Tax Office Number';
        }
        field(60; "Full Bank Account No."; Code[50])
        {
            Caption = 'Full Bank Account No.';
        }
        field(61; "Bank Account No. Type"; Option)
        {
            Caption = 'Bank Account No. Type';
            OptionCaption = 'Standard,No standard';
            OptionMembers = Standard,"No standard";
        }
        field(70; "Vendor Name"; Text[100])
        {
            CalcFormula = Lookup (Vendor.Name WHERE("No." = FIELD("Vendor No.")));
            Caption = 'Vendor Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.", "Check Date")
        {
        }
        key(Key3; "VAT Registration No.", "Vendor No.", "Check Date")
        {
        }
        key(Key4; "Vendor No.", "Entry Type", "Full Bank Account No.", "End Public Date")
        {
        }
    }

    fieldgroups
    {
    }
}

