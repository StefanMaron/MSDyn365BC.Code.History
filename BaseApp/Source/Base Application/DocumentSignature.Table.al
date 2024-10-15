table 12420 "Document Signature"
{
    Caption = 'Document Signature';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Employee Type"; Option)
        {
            Caption = 'Employee Type';
            OptionCaption = 'Director,Accountant,Cashier,Responsible,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Member1,Member2,Member3,StoredBy';
            OptionMembers = Director,Accountant,Cashier,Responsible,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Member1,Member2,Member3,StoredBy;
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                "Employee Name" := CopyStr(Employee.GetFullName, 1, MaxStrLen("Employee Name"));
                if (Employee."Short Name" <> '') and
                   ("Employee Name" <> Employee."Short Name")
                then
                    "Employee Name" := Employee."Short Name";
                if OrganizationalUnit.Get(Employee."Org. Unit Code") then
                    "Employee Org. Unit" := OrganizationalUnit.Name;
                if Employee."Job Title" <> '' then
                    "Employee Job Title" := Employee."Job Title"
                else
                    if JobTitle.Get(Employee."Job Title Code") then
                        "Employee Job Title" := JobTitle.Name;
            end;
        }
        field(6; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
        }
        field(7; "Employee Job Title"; Text[50])
        {
            Caption = 'Employee Job Title';
        }
        field(8; "Employee Org. Unit"; Text[50])
        {
            Caption = 'Employee Org. Unit';
        }
        field(9; "Warrant Description"; Text[30])
        {
            Caption = 'Warrant Description';
        }
        field(10; "Warrant No."; Text[20])
        {
            Caption = 'Warrant No.';
        }
        field(11; "Warrant Date"; Date)
        {
            Caption = 'Warrant Date';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Document Type", "Document No.", "Employee Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You can not rename a %1.';
        Employee: Record Employee;
        OrganizationalUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
}

