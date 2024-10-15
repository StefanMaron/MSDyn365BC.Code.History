table 5609 "FA Location"
{
    Caption = 'FA Location';
    LookupPageID = "FA Locations";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(12400; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(12401; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(14920; "OKATO Code"; Code[11])
        {
            Caption = 'OKATO Code';
            TableRelation = OKATO;
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

    [Scope('OnPrem')]
    procedure GetName(LocationCode: Code[10]): Text[50]
    begin
        if Get(LocationCode) then
            exit(Name);
        exit('');
    end;
}

