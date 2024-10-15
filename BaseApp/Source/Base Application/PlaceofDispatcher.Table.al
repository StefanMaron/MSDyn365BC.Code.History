table 11000 "Place of Dispatcher"
{
    Caption = 'Place of Dispatcher';
    LookupPageID = "Place of Dispatchers";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Text; Text[80])
        {
            Caption = 'Text';
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
        fieldgroup(DropDown; "Code", Text)
        {
        }
    }
}

