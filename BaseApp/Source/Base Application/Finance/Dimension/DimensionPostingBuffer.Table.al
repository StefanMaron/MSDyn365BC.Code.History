namespace Microsoft.Finance.Dimension;

table 385 "Dimension Posting Buffer"
{
    Caption = 'Dimension Posting Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Set Entry";
        }
        field(2; "Group ID"; Text[250])
        {
            Caption = 'Group ID';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Dimension Set ID", "Group ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

