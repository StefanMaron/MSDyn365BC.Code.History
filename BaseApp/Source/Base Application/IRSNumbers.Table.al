table 10900 "IRS Numbers"
{
    Caption = 'IRS Numbers';
    LookupPageID = "IRS Number";

    fields
    {
        field(1; "IRS Number"; Code[10])
        {
            Caption = 'IRS Number';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Reverse Prefix"; Boolean)
        {
            Caption = 'Reverse Prefix';
        }
    }

    keys
    {
        key(Key1; "IRS Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "IRS Number", Name)
        {
        }
    }
}

