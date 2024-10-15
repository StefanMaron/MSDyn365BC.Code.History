table 35600 "My Employee"
{
    Caption = 'My Employee';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
    }

    keys
    {
        key(Key1; "User ID", "Employee No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

