table 2152 "O365 Country/Region"
{
    Caption = 'O365 Country/Region';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "VAT Scheme"; Text[30])
        {
            Caption = 'VAT Scheme';
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
        fieldgroup(Brick; "Code", Name, "VAT Scheme")
        {
        }
    }
}

