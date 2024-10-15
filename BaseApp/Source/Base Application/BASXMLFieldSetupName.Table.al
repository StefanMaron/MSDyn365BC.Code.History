table 11607 "BAS XML Field Setup Name"
{
    Caption = 'BAS XML Field Setup Name';
    LookupPageID = "BAS XML Field Setup Names";

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description)
        {
        }
    }
}

