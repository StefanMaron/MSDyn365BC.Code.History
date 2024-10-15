table 31018 "Advance Link Buffer"
{
    Caption = 'Advance Link Buffer';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Letter Line';
            OptionMembers = " ",Payment,"Letter Line";
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = if (Type = const("G/L Account")) "G/L Account"."No."
            else
            if (Type = const(Customer)) Customer."No."
            else
            if (Type = const(Vendor)) Vendor."No.";
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Amount To Link"; Decimal)
        {
            Caption = 'Amount To Link';
            DataClassification = SystemMetadata;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Links-To ID"; Code[50])
        {
            Caption = 'Links-To ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; "Linking Entry"; Boolean)
        {
            Caption = 'Linking Entry';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(14; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(15; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(20; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(21; "Link Code"; Code[30])
        {
            Caption = 'Link Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry Type", "Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Links-To ID", "Linking Entry")
        {
            SumIndexFields = "Amount To Link";
        }
        key(Key3; "Link Code", "Linking Entry")
        {
            SumIndexFields = "Amount To Link";
        }
    }

    fieldgroups
    {
    }
}

