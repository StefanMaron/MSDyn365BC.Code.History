table 7828 "MS-QBO Sync Buffer"
{
    Caption = 'MS-QBO Sync Buffer';
    ObsoleteReason = 'replacing burntIn Extension tables with V2 Extension';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Record Id"; RecordID)
        {
            Caption = 'Record Id';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Record Id")
        {
        }
    }

    fieldgroups
    {
    }
}

