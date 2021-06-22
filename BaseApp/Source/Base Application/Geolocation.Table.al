table 806 Geolocation
{
    Caption = 'Geolocation';

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; Latitude; Decimal)
        {
            Caption = 'Latitude';
        }
        field(3; Longitude; Decimal)
        {
            Caption = 'Longitude';
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

