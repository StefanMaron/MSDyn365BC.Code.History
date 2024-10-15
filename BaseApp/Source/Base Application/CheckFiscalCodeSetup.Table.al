table 12123 "Check Fiscal Code Setup"
{
    Caption = 'Check Fiscal Code Setup';

    fields
    {
        field(1; "Key"; Code[10])
        {
            Caption = 'Key';
        }
        field(2; Str1; Code[100])
        {
            Caption = 'Str1';
        }
        field(3; StrD; Code[150])
        {
            Caption = 'StrD';
            Numeric = true;
        }
        field(4; StrP; Code[150])
        {
            Caption = 'StrP';
            Numeric = true;
        }
        field(5; Str2; Code[100])
        {
            Caption = 'Str2';
            Numeric = true;
        }
        field(6; Str3; Code[100])
        {
            Caption = 'Str3';
        }
        field(10; "Initiated Values"; Boolean)
        {
            Caption = 'Initiated Values';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

