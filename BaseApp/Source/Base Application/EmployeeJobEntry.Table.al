table 17363 "Employee Job Entry"
{
    Caption = 'Employee Job Entry';
    DrillDownPageID = "Employee Job Entry";

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
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if "Insured Period Starting Date" = 0D then
                    Validate("Insured Period Starting Date", "Starting Date");
            end;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if "Insured Period Ending Date" = 0D then
                    Validate("Insured Period Ending Date", "Ending Date");
            end;
        }
        field(6; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Labor Contract";
        }
        field(7; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(8; "Employer No."; Code[20])
        {
            Caption = 'Employer No.';
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Hire,Transfer,Termination';
            OptionMembers = " ",Hire,Transfer,Termination;
        }
        field(10; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            TableRelation = Position;

            trigger OnValidate()
            begin
                if Position.Get("Position No.") then begin
                    "Org. Unit Code" := Position."Org. Unit Code";
                    "Job Title Code" := Position."Job Title Code";
                    "Category Code" := Position."Category Code";
                    "Calendar Code" := Position."Calendar Code";
                    "Worktime Norm" := Position."Worktime Norm";
                    "Use Trial Period" := Position."Use Trial Period";
                    "Trial Period" := Position."Trial Period Description";
                    "Liability for Breakage" := Position."Liability for Breakage";
                    "Hire Conditions" := Position."Hire Conditions";
                    "Kind of Work" := Position."Kind of Work";
                    "Conditions of Work" := Position."Conditions of Work";
                    "Out-of-Staff" := Position."Out-of-Staff";
                end;
            end;
        }
        field(12; "Position Changed"; Boolean)
        {
            Caption = 'Position Changed';
        }
        field(15; "Supplement No."; Code[10])
        {
            Caption = 'Supplement No.';
        }
        field(20; "Insured Period Starting Date"; Date)
        {
            Caption = 'Insured Period Starting Date';

            trigger OnValidate()
            begin
                if ("Insured Period Starting Date" <> 0D) and ("Insured Period Starting Date" < "Starting Date") then
                    Error(Text14700,
                      FieldCaption("Insured Period Starting Date"),
                      FieldCaption("Starting Date"));
            end;
        }
        field(21; "Insured Period Ending Date"; Date)
        {
            Caption = 'Insured Period Ending Date';

            trigger OnValidate()
            begin
                if ("Insured Period Ending Date" <> 0D) and ("Insured Period Ending Date" > "Ending Date") then
                    Error(Text14701,
                      FieldCaption("Insured Period Ending Date"),
                      FieldCaption("Ending Date"));
            end;
        }
        field(30; "Uninterrupted Service"; Boolean)
        {
            Caption = 'Uninterrupted Service';
        }
        field(31; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(32; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            TableRelation = "Job Title";
        }
        field(33; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(34; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(35; "Speciality Code"; Code[10])
        {
            Caption = 'Speciality Code';
        }
        field(36; "Speciality Name"; Text[50])
        {
            Caption = 'Speciality Name';
        }
        field(40; "Position Rate"; Decimal)
        {
            Caption = 'Position Rate';
        }
        field(43; "Category Code"; Code[10])
        {
            Caption = 'Category Code';
            TableRelation = "Employee Category";
        }
        field(44; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(46; "Worktime Norm"; Code[10])
        {
            Caption = 'Worktime Norm';
            TableRelation = "Worktime Norm";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(47; "Use Trial Period"; Boolean)
        {
            Caption = 'Use Trial Period';
        }
        field(48; "Trial Period"; Text[50])
        {
            Caption = 'Trial Period';
        }
        field(49; "Liability for Breakage"; Option)
        {
            Caption = 'Liability for Breakage';
            OptionCaption = 'None,Team,Personal';
            OptionMembers = "None",Team,Personal;
        }
        field(50; "Hire Conditions"; Code[20])
        {
            Caption = 'Hire Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Hire Condition"));
        }
        field(51; "Kind of Work"; Option)
        {
            Caption = 'Kind of Work';
            OptionCaption = ' ,Permanent,Temporary,Seasonal';
            OptionMembers = " ",Permanent,"Temporary",Seasonal;
        }
        field(52; "Work Mode"; Option)
        {
            Caption = 'Work Mode';
            OptionCaption = 'Primary Job,Internal Co-work,External Co-work';
            OptionMembers = "Primary Job","Internal Co-work","External Co-work";
        }
        field(53; "Conditions of Work"; Option)
        {
            Caption = 'Conditions of Work';
            OptionCaption = ' ,Regular,Heavy,Unhealthy,Very Heavy';
            OptionMembers = " ",Regular,Heavy,Unhealthy,"Very Heavy";
        }
        field(54; "Out-of-Staff"; Boolean)
        {
            Caption = 'Out-of-Staff';
        }
        field(55; "Working Schedule"; Option)
        {
            Caption = 'Working Schedule';
            OptionCaption = ' ,5 Days,160 Hours,Day - Night - 2 Home,One in Three,Hour Tariff,Other';
            OptionMembers = " ","5 Days","160 Hours","Day - Night - 2 Home","One in Three","Hour Tariff",Other;
        }
        field(56; "Territorial Conditions"; Code[20])
        {
            Caption = 'Territorial Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Territor. Condition"));
        }
        field(57; "Special Conditions"; Code[20])
        {
            Caption = 'Special Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Special Work Condition"));
        }
        field(58; "Time Unit of Measure"; Option)
        {
            Caption = 'Time Unit of Measure';
            OptionCaption = 'Day,Hour';
            OptionMembers = Day,Hour;
        }
        field(59; "Record of Service Reason"; Code[20])
        {
            Caption = 'Calc Seniority: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Reason"));
        }
        field(60; "Record of Service Additional"; Code[20])
        {
            Caption = 'Calc Seniority: Addition';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Addition"));
        }
        field(61; "Service Years Reason"; Code[20])
        {
            Caption = 'Long Service: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Long Service Reason"));
        }
        field(62; "Service Years Additional"; Code[20])
        {
            Caption = 'Service Years Additional';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Long Service Addition"));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "Employee No.", "Starting Date", "Ending Date")
        {
            Clustered = true;
        }
        key(Key3; "Position No.", "Starting Date")
        {
            SumIndexFields = "Position Rate";
        }
        key(Key4; "Org. Unit Code", "Job Title Code", "Starting Date")
        {
            SumIndexFields = "Position Rate";
        }
    }

    fieldgroups
    {
    }

    var
        Text14700: Label '%1 should not be earlier than %2.';
        Text14701: Label '%1 should not be later than %2.';
        Position: Record Position;
        EmployeeJobEntry: Record "Employee Job Entry";
        Text14702: Label '%1 is not employed for period from %2 to %3.';

    [Scope('OnPrem')]
    procedure PositionChangeExist(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Boolean
    var
        JobsNo: Integer;
    begin
        EmployeeJobEntry.Reset;
        EmployeeJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmployeeJobEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeJobEntry.SetFilter("Starting Date", '..%1', EndDate);
        EmployeeJobEntry.SetFilter("Ending Date", '%1|%2..', 0D, StartDate);
        JobsNo := EmployeeJobEntry.Count;
        case JobsNo of
            0:
                Error(Text14702, EmployeeNo, StartDate, EndDate);
            1:
                exit(false);
            else
                exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEmployeeNo(PositionNo: Code[20]; CurrDate: Date): Code[20]
    begin
        EmployeeJobEntry.Reset;
        EmployeeJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmployeeJobEntry.SetRange("Position No.", PositionNo);
        EmployeeJobEntry.SetFilter("Starting Date", '..%1', CurrDate);
        EmployeeJobEntry.SetFilter("Ending Date", '%1|%2..', 0D, CurrDate);
        EmployeeJobEntry.SetRange("Position Changed", true);
        if EmployeeJobEntry.FindFirst then
            exit(EmployeeJobEntry."Employee No.");

        exit('');
    end;
}

