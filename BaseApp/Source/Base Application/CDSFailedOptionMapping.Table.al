table 5358 "CDS Failed Option Mapping"
{
    Caption = 'CDS Failed Option Mapping';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "CRM Integration Record Id"; Guid)
        {
            Caption = 'CRM Integration Record Id';
            DataClassification = SystemMetadata;
            TableRelation = "CRM Integration Record".SystemId;
        }
        field(2; "Record Id"; Guid)
        {
            Caption = 'Record Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "CRM Integration Record Id", "Record Id", "Field No.")
        {
            Clustered = true;
        }
    }
}