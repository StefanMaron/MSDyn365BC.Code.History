table 5203 "Employee Qualification"
{
    Caption = 'Employee Qualification';
    DataCaptionFields = "Person No.";
    DrillDownPageID = "Qualified Employees";
    LookupPageID = "Employee Qualifications";

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
        field(3; "Qualification Code"; Code[10])
        {
            Caption = 'Qualification Code';
            TableRelation = Qualification;

            trigger OnValidate()
            begin
                Qualification.Get("Qualification Code");
                Description := Qualification.Description;
            end;
        }
        field(4; "From Date"; Date)
        {
            Caption = 'From Date';
        }
        field(5; "To Date"; Date)
        {
            Caption = 'To Date';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Internal,External,Previous Position';
            OptionMembers = " ",Internal,External,"Previous Position";
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Institution/Company"; Text[100])
        {
            Caption = 'Institution/Company';
        }
        field(9; Cost; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost';
        }
        field(10; "Course Grade"; Text[50])
        {
            Caption = 'Course Grade';
        }
        field(11; "Employee Status"; Enum "Employee Status")
        {
            Caption = 'Employee Status';
            Editable = false;
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist("Human Resource Comment Line" WHERE("Table Name" = CONST("Employee Qualification"),
                                                                     "No." = FIELD("Person No."),
                                                                     "Table Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(17400; "Qualification Type"; Option)
        {
            Caption = 'Qualification Type';
            OptionCaption = 'Education,Attestation,Language';
            OptionMembers = Education,Attestation,Language;
        }
        field(17401; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Diploma,Certificate,Other';
            OptionMembers = " ",Diploma,Certificate,Other;
        }
        field(17402; "Document No."; Text[20])
        {
            Caption = 'Document No.';
        }
        field(17403; "Document Series"; Text[10])
        {
            Caption = 'Document Series';
        }
        field(17404; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(17407; "Kind of Education"; Code[10])
        {
            Caption = 'Kind of Education';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('34'));
        }
        field(17409; "Form of Education"; Code[10])
        {
            Caption = 'Form of Education';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('33'));
        }
        field(17410; "Type of Education"; Code[10])
        {
            Caption = 'Type of Education';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('30'));
        }
        field(17411; "Organization Address"; Text[50])
        {
            Caption = 'Organization Address';
        }
        field(17412; "Faculty Name"; Text[30])
        {
            Caption = 'Faculty';
        }
        field(17413; Speciality; Text[50])
        {
            Caption = 'Speciality';
        }
        field(17414; "Science Degree"; Text[30])
        {
            Caption = 'Science Degree';
        }
        field(17420; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            var
                Language: Codeunit Language;
            begin
                Description := Language.GetWindowsLanguageName("Language Code");
            end;
        }
        field(17421; "Language Proficiency"; Code[10])
        {
            Caption = 'Language Proficiency';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('05'));
        }
        field(17422; "Speciality Code"; Code[10])
        {
            Caption = 'Speciality Code';
        }
    }

    keys
    {
        key(Key1; "Person No.", "Qualification Type", "From Date", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Qualification Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Comment then
            Error(Text000);
    end;

    trigger OnInsert()
    begin
        Person.Get("Person No.");
        "Employee Status" := Person.Status;
    end;

    var
        Text000: Label 'You cannot delete employee qualification information if there are comments associated with it.';
        Qualification: Record Qualification;
        Person: Record Employee;
        GenDict: Record "General Directory";
        EmployeeQualification: Record "Employee Qualification";
}

