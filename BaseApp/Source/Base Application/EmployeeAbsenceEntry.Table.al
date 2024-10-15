table 17389 "Employee Absence Entry"
{
    Caption = 'Employee Absence Entry';
    DrillDownPageID = "Employee Absence Entries";
    LookupPageID = "Employee Absence Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(4; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(5; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Usage,Accrual';
            OptionMembers = Usage,Accrual;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                if "Entry Type" = "Entry Type"::Accrual then begin
                    EmployeeAbsenceEntry.Reset;
                    EmployeeAbsenceEntry.SetCurrentKey("Employee No.");
                    EmployeeAbsenceEntry.SetRange("Employee No.", "Employee No.");
                    EmployeeAbsenceEntry.SetRange("Time Activity Code", "Time Activity Code");
                    EmployeeAbsenceEntry.SetRange("Entry Type", "Entry Type"::Accrual);
                    EmployeeAbsenceEntry.SetRange("Start Date",
                      "Start Date", CalcDate('<1Y-1D>', "Start Date"));
                    if not EmployeeAbsenceEntry.IsEmpty then
                        Error(Text004,
                          "Employee No.", "Time Activity Code",
                          "Start Date", CalcDate('<1Y-1D>', "Start Date"));
                end;
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(8; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
        }
        field(9; "Working Days"; Decimal)
        {
            Caption = 'Working Days';
        }
        field(10; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(11; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
            Editable = false;
        }
        field(12; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
            Editable = false;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Position No."; Code[20])
        {
            Caption = 'Position No.';
        }
        field(15; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(16; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(17; "Accrual Entry No."; Integer)
        {
            Caption = 'Accrual Entry No.';
            TableRelation = "Employee Absence Entry" WHERE("Employee No." = FIELD("Employee No."),
                                                            "Time Activity Code" = FIELD("Time Activity Code"),
                                                            "Entry Type" = CONST(Accrual));
        }
        field(18; "Used Calendar Days"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence Entry"."Calendar Days" WHERE("Accrual Entry No." = FIELD("Entry No."),
                                                                              "Entry Type" = CONST(Usage)));
            Caption = 'Used Calendar Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Used Working Days"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence Entry"."Working Days" WHERE("Accrual Entry No." = FIELD("Entry No."),
                                                                             "Entry Type" = CONST(Usage)));
            Caption = 'Used Working Days';
            FieldClass = FlowField;
        }
        field(20; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;
        }
        field(21; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";
        }
        field(22; "Relative Code"; Code[20])
        {
            Caption = 'Relative Code';
        }
        field(23; "Save Position Rate"; Boolean)
        {
            Caption = 'Save Position Rate';
        }
        field(24; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(25; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Time Activity Code", "Entry Type", "Start Date")
        {
            SumIndexFields = "Calendar Days", "Working Days";
        }
        key(Key3; "Accrual Entry No.", "Entry Type")
        {
            SumIndexFields = "Calendar Days", "Working Days";
        }
        key(Key4; "Document No.", "Document Date")
        {
        }
        key(Key5; "Entry Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Document No.", '');
    end;

    trigger OnInsert()
    begin
        TestField("Entry Type", "Entry Type"::Accrual);

        if "Entry No." = 0 then begin
            EmployeeAbsenceEntry.Reset;
            if EmployeeAbsenceEntry.FindLast then
                "Entry No." := EmployeeAbsenceEntry."Entry No." + 1
            else
                "Entry No." := 1;
        end;
    end;

    trigger OnModify()
    begin
        TestField("Document No.", '');
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        Text004: Label 'Accrual for %1 with %2 for period from %3 to %4 already exist.';
}

