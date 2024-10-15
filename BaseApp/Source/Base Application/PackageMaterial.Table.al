table 31070 "Package Material"
{
    Caption = 'Package Material';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of Packaging Material will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Tax Rate (LCY)"; Decimal)
        {
            Caption = 'Tax Rate (LCY)';
            MinValue = 0;
        }
        field(4; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Exemption %"; Decimal)
        {
            Caption = 'Exemption %';
            MaxValue = 100;
            MinValue = 0;
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

