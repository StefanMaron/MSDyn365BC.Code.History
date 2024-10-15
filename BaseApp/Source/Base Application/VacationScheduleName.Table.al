table 17435 "Vacation Schedule Name"
{
    Caption = 'Vacation Schedule Name';
    LookupPageID = "Vacation Schedule Names";

    fields
    {
        field(1; Year; Integer)
        {
            Caption = 'Year';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(5; "Approver No."; Code[20])
        {
            Caption = 'Approver No.';
            TableRelation = Employee;
        }
        field(6; "Approve Date"; Date)
        {
            Caption = 'Approve Date';
        }
        field(7; "Union Document No."; Code[20])
        {
            Caption = 'Union Document No.';
        }
        field(8; "Union Document Date"; Date)
        {
            Caption = 'Union Document Date';
        }
        field(9; "HR Manager No."; Code[20])
        {
            Caption = 'HR Manager No.';
            TableRelation = Employee;
        }
    }

    keys
    {
        key(Key1; Year)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

