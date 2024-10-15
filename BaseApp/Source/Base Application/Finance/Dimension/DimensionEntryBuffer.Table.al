namespace Microsoft.Finance.Dimension;

table 373 "Dimension Entry Buffer"
{
    Caption = 'Dimension Entry Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}

