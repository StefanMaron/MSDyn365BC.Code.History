table 1543 "Flow Service Configuration"
{
    Caption = 'Flow Service Configuration';
    DataPerCompany = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Flow Service"; Option)
        {
            Caption = 'Flow Service';
            OptionCaption = 'Production Service,Testing Service (TIP 1),Testing Service (TIP 2)';
            OptionMembers = "Production Service","Testing Service (TIP 1)","Testing Service (TIP 2)";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

