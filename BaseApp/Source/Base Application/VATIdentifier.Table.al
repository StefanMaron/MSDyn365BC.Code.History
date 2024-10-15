table 11767 "VAT Identifier"
{
    Caption = 'VAT Identifier';
    ObsoleteState = Removed;
    ObsoleteReason = 'The enhanced functionality of VAT Identifier will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; Description; Text[80])
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

