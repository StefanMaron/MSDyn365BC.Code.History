namespace System.IO;

table 8401 "Record Set Tree"
{
    Caption = 'Record Set Tree';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Node ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Node ID';
        }
        field(10; Value; RecordID)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
        }
        field(11; "Parent Node ID"; Integer)
        {
            Caption = 'Parent Node ID';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Node ID")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Parent Node ID", Value)
        {
        }
    }

    fieldgroups
    {
    }
}

