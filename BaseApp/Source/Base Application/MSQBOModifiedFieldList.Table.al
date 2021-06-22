table 7823 "MS-QBO Modified Field List"
{
    Caption = 'MS-QBO Modified Field List';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Record Id"; RecordID)
        {
            Caption = 'Record Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Field Id"; Integer)
        {
            Caption = 'Field Id';
        }
        field(3; "Field Value"; BLOB)
        {
            Caption = 'Field Value';
        }
    }

    keys
    {
        key(Key1; "Record Id", "Field Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

