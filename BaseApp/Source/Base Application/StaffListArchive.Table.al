table 17375 "Staff List Archive"
{
    Caption = 'Staff List Archive';
    LookupPageID = "Staff List Archives";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(3; "Staff Positions"; Decimal)
        {
            CalcFormula = Sum ("Staff List Line Archive"."Staff Positions" WHERE("Document No." = FIELD("Document No.")));
            Caption = 'Staff Positions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "HR Manager No."; Code[20])
        {
            Caption = 'HR Manager No.';
            TableRelation = Employee;
        }
        field(5; "Chief Accountant No."; Code[20])
        {
            Caption = 'Chief Accountant No.';
            TableRelation = Employee;
        }
        field(6; "Staff List Date"; Date)
        {
            Caption = 'Staff List Date';
            Editable = false;
        }
        field(7; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(8; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(9; "Out-of-Staff Positions"; Decimal)
        {
            CalcFormula = Sum ("Staff List Line Archive"."Out-of-Staff Positions" WHERE("Document No." = FIELD("Document No.")));
            Caption = 'Out-of-Staff Positions';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StaffListLineArchive: Record "Staff List Line Archive";
    begin
        StaffListLineArchive.Reset();
        StaffListLineArchive.SetRange("Document No.", "Document No.");
        StaffListLineArchive.DeleteAll();
    end;
}

