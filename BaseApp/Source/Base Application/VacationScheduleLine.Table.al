table 17436 "Vacation Schedule Line"
{
    Caption = 'Vacation Schedule Line';

    fields
    {
        field(1; Year; Integer)
        {
            Caption = 'Year';
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                UpdateEmployee("Start Date");

                if ("Start Date" <> 0D) and ("End Date" <> 0D) then begin
                    VacationScheduleLine.Reset;
                    VacationScheduleLine.SetRange(Year, Year);
                    VacationScheduleLine.SetRange("Employee No.", "Employee No.");
                    VacationScheduleLine.SetFilter("Line No.", '<>%1', "Line No.");
                    if VacationScheduleLine.FindSet then
                        repeat
                            if (("Start Date" <= VacationScheduleLine."Start Date") and
                                ("End Date" >= VacationScheduleLine."Start Date")) or
                               (("Start Date" <= VacationScheduleLine."End Date") and
                                ("End Date" >= VacationScheduleLine."End Date"))
                            then
                                Error(Text001,
                                  VacationScheduleLine."Start Date", VacationScheduleLine."End Date", VacationScheduleLine."Line No.");
                        until VacationScheduleLine.Next = 0;

                    Employee.GetJobEntry("Employee No.", "Start Date", EmployeeJobEntry);
                    "Calendar Days" :=
                      CalendarMgt.GetPeriodInfo(
                        EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 1) -
                      CalendarMgt.GetPeriodInfo(
                        EmployeeJobEntry."Calendar Code", "Start Date", "End Date", 4);
                end;
            end;
        }
        field(3; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                if Date2DMY("Start Date", 3) <> Year then
                    Error(Text000, FieldCaption("Start Date"), Year);

                Validate("Employee No.");
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
            Editable = false;
        }
        field(6; "Actual Start Date"; Date)
        {
            Caption = 'Actual Start Date';
        }
        field(7; "Carry Over Reason"; Text[30])
        {
            Caption = 'Carry Over Reason';
        }
        field(8; "Estimated Start Date"; Date)
        {
            Caption = 'Estimated Start Date';
        }
        field(9; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                Validate("Employee No.");
            end;
        }
        field(10; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                OrganizationalUnit.Get("Org. Unit Code");
                OrganizationalUnit.TestField(Blocked, false);
            end;
        }
        field(11; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
        }
        field(12; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            TableRelation = "Job Title";

            trigger OnValidate()
            begin
                JobTitle.Get("Job Title Code");
                JobTitle.TestField(Blocked, false);
            end;
        }
        field(13; "Job Title Name"; Text[50])
        {
            Caption = 'Job Title Name';
        }
        field(14; "Employee Name"; Text[90])
        {
            Caption = 'Employee Name';
        }
        field(15; Comments; Text[30])
        {
            Caption = 'Comments';
        }
    }

    keys
    {
        key(Key1; Year, "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Year, "Employee No.", "Start Date")
        {
        }
        key(Key3; Year, "Org. Unit Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Employee: Record Employee;
        Text000: Label 'You should select %1 within current year %2.';
        VacationScheduleLine: Record "Vacation Schedule Line";
        Text001: Label 'Current period overlap with period from %1 to %2 in line %3.';
        EmployeeJobEntry: Record "Employee Job Entry";
        OrganizationalUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
        CalendarMgt: Codeunit "Payroll Calendar Management";

    [Scope('OnPrem')]
    procedure UpdateEmployee(Date: Date)
    begin
        if Employee.Get("Employee No.") then begin
            Validate("Org. Unit Code", Employee."Org. Unit Code");
            "Org. Unit Name" := Employee.GetDepartmentName;
            Validate("Job Title Code", Employee."Job Title Code");
            "Job Title Name" := Employee.GetJobTitleName;
            "Employee Name" := CopyStr(Employee.GetFullNameOnDate(Date), 1, MaxStrLen("Employee Name"));
        end;
    end;

    [Scope('OnPrem')]
    procedure SuggestEmployees(Year: Integer)
    var
        VacationScheduleLine2: Record "Vacation Schedule Line";
        StartDate: Date;
        LineNo: Integer;
    begin
        VacationScheduleLine2.Reset;
        VacationScheduleLine2.SetRange(Year, Year);
        if VacationScheduleLine2.FindLast then
            LineNo := VacationScheduleLine2."Line No." + 10000;

        StartDate := DMY2Date(1, 1, Year);
        Employee.Reset;
        if Employee.FindSet then
            repeat
                if Employee.IsEmployed(StartDate) then begin
                    VacationScheduleLine2.Reset;
                    VacationScheduleLine2.SetRange(Year, Year);
                    VacationScheduleLine2.SetRange("Employee No.", Employee."No.");
                    if VacationScheduleLine2.IsEmpty then begin
                        VacationScheduleLine2.Init;
                        VacationScheduleLine2.Validate(Year, Year);
                        VacationScheduleLine2.Validate("Employee No.", Employee."No.");
                        VacationScheduleLine2."Line No." := LineNo;
                        VacationScheduleLine2.Insert;

                        LineNo += 10000;
                    end;
                end;
            until Employee.Next = 0;
    end;
}

