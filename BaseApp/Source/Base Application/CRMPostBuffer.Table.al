table 5387 "CRM Post Buffer"
{
    Caption = 'CRM Post Buffer';

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; RecId; RecordID)
        {
            Caption = 'RecId';
            DataClassification = SystemMetadata;
        }
        field(4; ChangeType; Option)
        {
            Caption = 'ChangeType';
            DataClassification = SystemMetadata;
            OptionCaption = ',SalesDocReleased,SalesShptHeaderCreated,SalesInvHeaderCreated';
            OptionMembers = ,SalesDocReleased,SalesShptHeaderCreated,SalesInvHeaderCreated;
        }
        field(5; ChangeDateTime; DateTime)
        {
            Caption = 'ChangeDateTime';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

