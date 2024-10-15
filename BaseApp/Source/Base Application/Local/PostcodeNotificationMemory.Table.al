table 10501 "Postcode Notification Memory"
{
    Caption = 'Postcode Notification Memory';

    fields
    {
        field(1; UserId; Code[50])
        {
            Caption = 'UserId';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; UserId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

