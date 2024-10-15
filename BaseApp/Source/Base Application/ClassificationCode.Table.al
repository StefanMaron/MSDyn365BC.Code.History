table 31040 "Classification Code"
{
    Caption = 'Classification Code';
    LookupPageID = "Classification Codes";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Classification Type"; Option)
        {
            BlankZero = true;
            Caption = 'Classification Type';
            NotBlank = true;
            OptionCaption = ',CZ-CPA,CZ-CC,DNM';
            OptionMembers = ,"CZ-CPA","CZ-CC",DNM;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Classification Type", "Code")
        {
        }
    }

    fieldgroups
    {
    }
}

