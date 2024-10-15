table 17376 "Staff List Line Archive"
{
    Caption = 'Staff List Line Archive';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Staff List Archive";
        }
        field(2; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            NotBlank = true;
            TableRelation = "Organizational Unit";
        }
        field(3; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            NotBlank = true;
            TableRelation = "Job Title";
        }
        field(4; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
            Editable = false;
        }
        field(5; "Job Title Name"; Text[50])
        {
            Caption = 'Job Title Name';
            Editable = false;
        }
        field(6; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(7; "Parent Code"; Code[10])
        {
            Caption = 'Parent Code';
            TableRelation = "Organizational Unit";
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Unit,Heading,Total';
            OptionMembers = Unit,Heading,Total;
        }
        field(10; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Staff Positions"; Decimal)
        {
            Caption = 'Staff Positions';
            Editable = false;
        }
        field(22; "Out-of-Staff Positions"; Decimal)
        {
            Caption = 'Out-of-Staff Positions';
            Editable = false;
        }
        field(23; "Staff Base Salary"; Decimal)
        {
            Caption = 'Staff Base Salary';
            Editable = false;
        }
        field(24; "Staff Monthly Salary"; Decimal)
        {
            Caption = 'Staff Monthly Salary';
            Editable = false;
        }
        field(25; "Staff Additional Salary"; Decimal)
        {
            Caption = 'Staff Additional Salary';
            Editable = false;
        }
        field(26; "Staff Budgeted Salary"; Decimal)
        {
            Caption = 'Staff Budgeted Salary';
            Editable = false;
        }
        field(29; "Occupied Staff Positions"; Decimal)
        {
            Caption = 'Occupied Staff Positions';
        }
        field(31; "Vacant Staff Positions"; Decimal)
        {
            Caption = 'Vacant Staff Positions';
        }
        field(35; "Out-of-Staff Base Salary"; Decimal)
        {
            Caption = 'Out-of-Staff Base Salary';
            Editable = false;
        }
        field(36; "Out-of-Staff Monthly Salary"; Decimal)
        {
            Caption = 'Out-of-Staff Monthly Salary';
            Editable = false;
        }
        field(37; "Out-of-Staff Additional Salary"; Decimal)
        {
            Caption = 'Out-of-Staff Additional Salary';
            Editable = false;
        }
        field(38; "Out-of-Staff Budgeted Salary"; Decimal)
        {
            Caption = 'Out-of-Staff Budgeted Salary';
            Editable = false;
        }
        field(39; "Occup. Out-of-Staff Positions"; Decimal)
        {
            Caption = 'Occup. Out-of-Staff Positions';
        }
        field(40; "Vacant Out-of-Staff Positions"; Decimal)
        {
            Caption = 'Vacant Out-of-Staff Positions';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Org. Unit Code", "Job Title Code")
        {
            Clustered = true;
            SumIndexFields = "Staff Positions", "Out-of-Staff Positions";
        }
    }

    fieldgroups
    {
    }
}

