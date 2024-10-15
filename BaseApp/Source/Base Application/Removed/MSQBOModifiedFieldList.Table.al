table 7823 "MS-QBO Modified Field List"
{
    Caption = 'MS-QBO Modified Field List';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record Id"; RecordID)
        {
            Caption = 'Record Id';
            DataClassification = CustomerContent;
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

