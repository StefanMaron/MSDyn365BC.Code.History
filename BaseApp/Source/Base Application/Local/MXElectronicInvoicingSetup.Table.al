table 10004 "MX Electronic Invoicing Setup"
{
    Caption = 'MX Electronic Invoicing Setup';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Download XML with Requests"; Boolean)
        {
            Caption = 'Download XML with Requests';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

