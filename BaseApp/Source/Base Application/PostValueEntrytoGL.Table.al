table 5811 "Post Value Entry to G/L"
{
    Caption = 'Post Value Entry to G/L';

    fields
    {
        field(1; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
    }

    keys
    {
        key(Key1; "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Posting Date")
        {
        }
        key(Key3; "Item No.")
        {
        }
    }

    fieldgroups
    {
    }
}

