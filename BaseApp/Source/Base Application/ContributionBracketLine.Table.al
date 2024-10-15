table 12109 "Contribution Bracket Line"
{
    Caption = 'Contribution Bracket Line';
    DrillDownPageID = "Contribution Bracket Lines";
    LookupPageID = "Contribution Bracket Lines";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Contribution Bracket".Code;
        }
        field(2; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(3; "Taxable Base %"; Decimal)
        {
            Caption = 'Taxable Base %';
            DecimalPlaces = 0 : 2;
        }
        field(4; "Contribution Type"; Option)
        {
            Caption = 'Contribution Type';
            OptionCaption = 'INPS,INAIL';
            OptionMembers = INPS,INAIL;
        }
    }

    keys
    {
        key(Key1; "Code", Amount, "Contribution Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

