table 5205 "Employee Relative"
{
    Caption = 'Employee Relative';
    DataCaptionFields = "Person No.";
    DrillDownPageID = "Employee Relatives";
    LookupPageID = "Employee Relatives";

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            NotBlank = true;
            TableRelation = Person;
            //This property is currently not supported
            //TestTableRelation = false;
        }
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
        field(9; "Relative Person No."; Code[20])
        {
            Caption = 'Relative Person No.';
            TableRelation = Person;

            trigger OnValidate()
            begin
                if Person.Get("Relative Person No.") then begin
                    "First Name" := Person."First Name";
                    "Middle Name" := Person."Middle Name";
                    "Last Name" := Person."Last Name";
                    "Birth Date" := Person."Birth Date";
                    "Phone No." := Person."Phone No.";
                end;
            end;
        }
        field(10; Comment; Boolean)
        {
            CalcFormula = Exist ("Human Resource Comment Line" WHERE("Table Name" = CONST("Employee Relative"),
                                                                     "No." = FIELD("Person No."),
                                                                     "Table Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17400; "Relation Start Date"; Date)
        {
            Caption = 'Relation Start Date';
        }
        field(17401; "Relation End Date"; Date)
        {
            Caption = 'Relation End Date';
        }
    }

    keys
    {
        key(Key1; "Person No.", "Line No.")
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
        Relative: Record Relative;
        Employee: Record Employee;
    begin
        HRCommentLine.SetRange("Table Name", HRCommentLine."Table Name"::"Employee Relative");
        HRCommentLine.SetRange("No.", "Person No.");
        HRCommentLine.DeleteAll();
    end;

    var
        Person: Record Person;

    [Scope('OnPrem')]
    procedure GetType(): Integer
    var
        Relative: Record Relative;
    begin
        TestField("Relative Code");
        if Relative.Get("Relative Code") then
            exit(Relative."Relative Type")
        else
            exit(0);
    end;
}

