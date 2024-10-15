table 7000024 Suffix
{
    Caption = 'Suffix';
    DrillDownPageID = Suffixes;
    LookupPageID = Suffixes;

    fields
    {
        field(1; "Bank Acc. Code"; Code[20])
        {
            Caption = 'Bank Acc. Code';
            NotBlank = true;
            TableRelation = "Bank Account"."No.";
        }
        field(2; Suffix; Code[3])
        {
            Caption = 'Suffix';
        }
        field(3; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Bank Acc. Code", Suffix)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

