table 284 "Area"
{
    Caption = 'Area';
    LookupPageID = Areas;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Text; Text[50])
        {
            Caption = 'Text';
        }
        field(10700; "Post Code Prefix"; Code[20])
        {
            Caption = 'Post Code Prefix';
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