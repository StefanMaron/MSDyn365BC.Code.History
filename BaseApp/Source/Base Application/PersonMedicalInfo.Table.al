table 17353 "Person Medical Info"
{
    Caption = 'Person Medical Info';

    fields
    {
        field(1; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            NotBlank = true;
            TableRelation = Person;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Insurance,Disability,Privilege';
            OptionMembers = Insurance,Disability,Privilege;
        }
        field(5; "Insurer No."; Code[20])
        {
            Caption = 'Insurer No.';
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(6; "Polyclinic Name"; Text[100])
        {
            Caption = 'Polyclinic Name';
        }
        field(7; Stomatology; Text[100])
        {
            Caption = 'Stomatology';
        }
        field(8; "Antenatal Clinic"; Text[100])
        {
            Caption = 'Antenatal Clinic';
        }
        field(9; "Police No."; Text[30])
        {
            Caption = 'Police No.';
        }
        field(10; "Disability Group"; Option)
        {
            Caption = 'Disability Group';
            OptionCaption = ' ,1,2,3';
            OptionMembers = " ","1","2","3";
        }
        field(11; "TEK Type"; Option)
        {
            Caption = 'TEK Type';
            OptionCaption = ' ,VTE,MCE';
            OptionMembers = " ",VTE,MCE;
        }
        field(12; "TEK Document No."; Code[10])
        {
            Caption = 'TEK No.';
        }
        field(13; "TEK Document Date"; Date)
        {
            Caption = 'TEK Date';
        }
        field(14; "Police Series"; Text[10])
        {
            Caption = 'Police Series';
        }
        field(15; Privilege; Option)
        {
            Caption = 'Privilege';
            OptionCaption = ' ,Pensioner,Afghanistan Veteran,Chernobyl Veteran';
            OptionMembers = " ",Pensioner,"Afghanistan Veteran","Chernobyl Veteran";
        }
        field(16; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee WHERE("Person No." = FIELD("Person No."));
        }
    }

    keys
    {
        key(Key1; "Person No.", Type, "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

