table 11791 "Industry Code"
{
    Caption = 'Industry Code';
    LookupPageID = "Industry Codes";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Industry Classification will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[60])
        {
            Caption = 'Description';
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

