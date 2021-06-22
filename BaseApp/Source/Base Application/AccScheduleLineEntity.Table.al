table 5503 "Acc. Schedule Line Entity"
{
    Caption = 'Acc. Schedule Line Entity';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Net Change"; Decimal)
        {
            Caption = 'Net Change';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
        }
        field(6; "Line Type"; Text[30])
        {
            Caption = 'Line Type';
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

