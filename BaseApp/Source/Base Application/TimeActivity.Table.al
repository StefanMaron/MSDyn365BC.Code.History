table 5206 "Time Activity"
{
    Caption = 'Time Activity';
    DrillDownPageID = "Time Activity Codes";
    LookupPageID = "Time Activity Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Human Resource Unit of Measure";
        }
        field(4; "Total Absence (Base)"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence"."Quantity (Base)" WHERE("Cause of Absence Code" = FIELD(Code),
                                                                          "Employee No." = FIELD("Employee No. Filter"),
                                                                          "From Date" = FIELD("Date Filter")));
            Caption = 'Total Absence (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(6; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(7; "Employee No. Filter"; Code[20])
        {
            Caption = 'Employee No. Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
        }
        field(8; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(17400; "Timesheet Code"; Code[10])
        {
            Caption = 'Timesheet Code';
            TableRelation = "Timesheet Code";
        }
        field(17401; "Time Activity Type"; Option)
        {
            Caption = 'Time Activity Type';
            OptionCaption = 'Presence,Travel,Vacation,Sick Leave,Other';
            OptionMembers = Presence,Travel,Vacation,"Sick Leave",Other;
        }
        field(17402; "Detailed Description"; Text[250])
        {
            Caption = 'Detailed Description';
        }
        field(17403; "Allow Combination"; Boolean)
        {
            Caption = 'Allow Combination';
        }
        field(17404; "Allow Overtime"; Boolean)
        {
            Caption = 'Allow Overtime';
        }
        field(17405; "Paid Activity"; Boolean)
        {
            Caption = 'Paid Activity';
        }
        field(17406; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;

            trigger OnValidate()
            begin
                TestField("Time Activity Type", "Time Activity Type"::Vacation);
            end;
        }
        field(17407; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";

            trigger OnValidate()
            begin
                TestField("Time Activity Type", "Time Activity Type"::"Sick Leave");
            end;
        }
        field(17409; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(17410; "Save Position Rate"; Boolean)
        {
            Caption = 'Save Position Rate';

            trigger OnValidate()
            begin
                if "Time Activity Type" = "Time Activity Type"::Presence then
                    Error(Text000, FieldCaption("Time Activity Type"), "Time Activity Type"::Presence);
            end;
        }
        field(17411; "Use Accruals"; Boolean)
        {
            Caption = 'Use Accruals';
        }
        field(17412; "Min Days Allowed per Year"; Integer)
        {
            Caption = 'Min Days Allowed per Year';
        }
        field(17413; "Allow Override"; Boolean)
        {
            Caption = 'Allow Override';
        }
        field(17414; "PF Reporting Absence Code"; Code[20])
        {
            Caption = 'PF Reporting Absence Code';
            TableRelation = "General Directory".Code WHERE(Type = CONST("Countable Service Addition"));
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Timesheet Code", "Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1 must not be %2.';
}

