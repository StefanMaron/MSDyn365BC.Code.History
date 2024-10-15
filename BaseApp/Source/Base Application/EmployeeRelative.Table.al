table 5205 "Employee Relative"
{
    Caption = 'Employee Relative';
    DataCaptionFields = "Employee No.";
    DrillDownPageID = "Employee Relatives";
    LookupPageID = "Employee Relatives";

    fields
    {
#pragma warning disable AS0005
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
#pragma warning restore AS0005
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Relative Code"; Code[10])
        {
            Caption = 'Relative Code';
            TableRelation = Relative;
        }
        field(4; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(5; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
        }
        field(6; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(7; "Birth Date"; Date)
        {
            Caption = 'Birth Date';
        }
        field(8; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
#pragma warning disable AS0005
        field(9; "Relative's Employee No."; Code[20])
        {
            Caption = 'Relative''s Employee No.';
            TableRelation = Employee;
        }
#pragma warning restore AS0005
        field(10; Comment; Boolean)
        {
            CalcFormula = Exist("Human Resource Comment Line" WHERE("Table Name" = CONST("Employee Relative"),
                                                                     "No." = FIELD("Employee No."),
                                                                     "Table Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        HRCommentLine: Record "Human Resource Comment Line";
    begin
        HRCommentLine.SetRange("Table Name", HRCommentLine."Table Name"::"Employee Relative");
        HRCommentLine.SetRange("No.", "Employee No.");
        HRCommentLine.DeleteAll();
    end;
}

