table 5358 "CDS Failed Option Mapping"
{
    Caption = 'CDS Failed Option Mapping';
    DataClassification = SystemMetadata;
    ObsoleteReason = 'Feature OptionMapping will be enabled by default in version 22.0.';
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif

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