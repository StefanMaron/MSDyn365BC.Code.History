table 5074 "Delivery Sorter"
{
    Caption = 'Delivery Sorter';

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
        field(3; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';
        }
        field(4; Subject; Text[100])
        {
            Caption = 'Subject';
        }
        field(5; "Send Word Docs. as Attmt."; Boolean)
        {
            Caption = 'Send Word Docs. as Attmt.';
        }
        field(6; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
        }
        field(7; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Word Template Code';
            TableRelation = "Word Template".Code;
        }
        field(18; "Wizard Action"; Enum "Interaction Template Wizard Action")
        {
            DataClassification = SystemMetadata;
            Caption = 'Wizard Action';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Attachment No.", "Correspondence Type", Subject, "Send Word Docs. as Attmt.")
        {
        }
    }

    fieldgroups
    {
    }
}

