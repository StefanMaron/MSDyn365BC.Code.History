table 17430 "Payroll Calendar Line"
{
    Caption = 'Payroll Calendar Line';

    fields
    {
        field(1; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Payroll Calendar";
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;

            trigger OnValidate()
            var
                ShiftDayNo: Integer;
            begin
                GetCalendar;
                if PayrollCalendar."Shift Start Date" <> 0D then begin
                    // Shift calendar
                    PayrollCalendar.TestField("Shift Days");
                    if Date >= PayrollCalendar."Shift Start Date" then
                        ShiftDayNo := (Date - PayrollCalendar."Shift Start Date") mod PayrollCalendar."Shift Days" + 1
                    else
                        ShiftDayNo := -1;

                    PayrollCalendarSetup.Reset();
                    PayrollCalendarSetup.SetRange("Calendar Code", "Calendar Code");
                    PayrollCalendarSetup.SetRange("Period Type", PayrollCalendarSetup."Period Type"::Shift);
                    PayrollCalendarSetup.SetRange("Day No.", ShiftDayNo);
                    PayrollCalendarSetup.SetRange(Year, Date2DMY(Date, 3));
                    if PayrollCalendarSetup.FindFirst then
                        InitLine(PayrollCalendarSetup)
                    else begin
                        PayrollCalendarSetup.SetRange(Year);
                        if PayrollCalendarSetup.FindFirst then
                            InitLine(PayrollCalendarSetup);
                    end;
                end else begin
                    // Regular calendar
                    PayrollCalendarSetup.Reset();
                    PayrollCalendarSetup.SetRange("Calendar Code", "Calendar Code");
                    PayrollCalendarSetup.SetRange(Year, 0); // No year defined
                    if PayrollCalendarSetup.FindFirst then begin
                        GetDayWeek;
                        GetDayMonth;
                    end;
                    PayrollCalendarSetup.SetRange(Year, Date2DMY(Date, 3));
                    if PayrollCalendarSetup.FindFirst then begin // if Year defined
                        GetDayWeek;
                        GetDayMonth;
                    end;
                end;

                "Week Day" := Date2DWY(Date, 1) - 1;
            end;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; Nonworking; Boolean)
        {
            Caption = 'Nonworking';

            trigger OnValidate()
            begin
                if Nonworking then begin
                    "Starting Time" := 0T;
                    "Work Hours" := 0;
                end;
            end;
        }
        field(5; "Starting Time"; Time)
        {
            BlankNumbers = BlankZero;
            Caption = 'Starting Time';
        }
        field(6; "Work Hours"; Decimal)
        {
            BlankZero = true;
            Caption = 'Work Hours';
            MaxValue = 24;
            MinValue = 0;
        }
        field(7; "Week Day"; Option)
        {
            Caption = 'Week Day';
            Editable = false;
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
        }
        field(8; "Night Hours"; Decimal)
        {
            Caption = 'Night Hours';

            trigger OnValidate()
            begin
                GetCalendar;
                if PayrollCalendar."Shift Days" = 0 then
                    Error(Text001, FieldCaption("Night Hours"));
            end;
        }
        field(10; "Day Status"; Option)
        {
            Caption = 'Day Status';
            OptionCaption = ' ,Weekend,Holiday';
            OptionMembers = " ",Weekend,Holiday;
        }
        field(11; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(12; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "Calendar Code", Date)
        {
            Clustered = true;
        }
        key(Key2; "Calendar Code", Nonworking, "Day Status", Date)
        {
            SumIndexFields = "Work Hours", "Night Hours";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        TimesheetLine.Reset();
        TimesheetLine.SetCurrentKey("Calendar Code", Date);
        TimesheetLine.SetRange("Calendar Code", "Calendar Code");
        TimesheetLine.SetRange(Date, Date);
        if not TimesheetLine.IsEmpty then
            Error('');
    end;

    trigger OnModify()
    begin
        TestField(Status, Status::Open);
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        PayrollCalendar: Record "Payroll Calendar";
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
        PayrollCalendarSetup2: Record "Payroll Calendar Setup";
        PayrollCalendarLine: Record "Payroll Calendar Line";
        TimesheetLine: Record "Timesheet Line";
        TimesheetStatus: Record "Timesheet Status";
        Text001: Label 'You can enter %1 in shift calendar only.';
        TimesheetMgt: Codeunit "Timesheet Management RU";

    [Scope('OnPrem')]
    procedure GetCalendar()
    begin
        TestField("Calendar Code");
        if "Calendar Code" <> PayrollCalendar.Code then
            PayrollCalendar.Get("Calendar Code");
    end;

    [Scope('OnPrem')]
    procedure SetNewLine(xPayrollCalendarLine: Record "Payroll Calendar Line")
    begin
        PayrollCalendarLine.SetRange("Calendar Code", "Calendar Code");
        if PayrollCalendarLine.FindFirst then
            Validate(Date, xPayrollCalendarLine.Date + 1);
    end;

    [Scope('OnPrem')]
    procedure InitLine(PayrollCalendarSetup: Record "Payroll Calendar Setup")
    begin
        Description := PayrollCalendarSetup.Description;
        Nonworking := PayrollCalendarSetup.Nonworking;
        "Starting Time" := PayrollCalendarSetup."Starting Time";
        "Work Hours" := PayrollCalendarSetup."Work Hours";
        "Night Hours" := PayrollCalendarSetup."Night Hours";
        "Day Status" := PayrollCalendarSetup."Day Status";
        PayrollCalendarSetup.TestField("Time Activity Code");
        "Time Activity Code" := PayrollCalendarSetup."Time Activity Code";
    end;

    [Scope('OnPrem')]
    procedure GetDayMonth()
    begin
        PayrollCalendarSetup2.CopyFilters(PayrollCalendarSetup);
        PayrollCalendarSetup2.SetRange("Period Type", PayrollCalendarSetup2."Period Type"::Month);
        if PayrollCalendarSetup2.FindFirst then begin
            PayrollCalendarSetup2.SetFilter("Period No.", '%1|%2', 0, Date2DMY(Date, 2));
            if PayrollCalendarSetup2.FindFirst then begin
                PayrollCalendarSetup2.SetRange("Period No.", Date2DMY(Date, 2));
                if not PayrollCalendarSetup2.FindFirst then
                    PayrollCalendarSetup2.SetRange("Period No.", 0);
                PayrollCalendarSetup2.SetFilter("Day No.", '%1|%2', 0, Date2DMY(Date, 1));
                if PayrollCalendarSetup2.FindFirst then begin
                    PayrollCalendarSetup2.SetRange("Day No.", Date2DMY(Date, 1));
                    if not PayrollCalendarSetup2.FindFirst then
                        PayrollCalendarSetup2.SetRange("Day No.", 0);
                    if PayrollCalendarSetup2.FindLast then
                        InitLine(PayrollCalendarSetup2);
                end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDayWeek()
    begin
        PayrollCalendarSetup2.CopyFilters(PayrollCalendarSetup);
        PayrollCalendarSetup2.SetRange("Period Type", PayrollCalendarSetup2."Period Type"::Week);
        if PayrollCalendarSetup2.FindFirst then begin
            PayrollCalendarSetup2.SetFilter("Period No.", '%1|%2', 0, Date2DWY(Date, 2));
            if PayrollCalendarSetup2.FindFirst then begin
                PayrollCalendarSetup2.SetRange("Period No.", Date2DWY(Date, 2));
                if not PayrollCalendarSetup2.FindFirst then
                    PayrollCalendarSetup2.SetRange("Period No.", 0);
                PayrollCalendarSetup2.SetFilter("Day No.", '%1|%2', 0, Date2DWY(Date, 1));
                if PayrollCalendarSetup2.FindFirst then begin
                    PayrollCalendarSetup2.SetRange("Day No.", Date2DWY(Date, 1));
                    if not PayrollCalendarSetup2.FindFirst then
                        PayrollCalendarSetup2.SetRange("Day No.", 0);
                    if PayrollCalendarSetup2.FindFirst then
                        InitLine(PayrollCalendarSetup2);
                end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure Release()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        EmployeeJobEntry: Record "Employee Job Entry";
    begin
        Validate(Status, Status::Open);
        TestField("Time Activity Code");

        GetCalendar;
        if (PayrollCalendar."Shift Days" = 0) and (not Nonworking) then
            TestField("Work Hours");

        Employee.Reset();
        if Employee.FindSet then
            repeat
                if Employee.GetJobEntry(Employee."No.", Date, EmployeeJobEntry) then
                    if (EmployeeJobEntry."Calendar Code" = "Calendar Code") and
                       TimesheetStatus.Get(PayrollPeriod.PeriodByDate(Date), Employee."No.")
                    then begin
                        TimesheetStatus.TestField(Status, TimesheetStatus.Status::Open);
                        TimesheetMgt.UpdateTimesheet(Employee, Date, Date, "Calendar Code", false);
                    end;
            until Employee.Next = 0;

        Status := Status::Released;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        EmployeeJobEntry: Record "Employee Job Entry";
    begin
        Validate(Status, Status::Released);

        Employee.Reset();
        if Employee.FindSet then
            repeat
                if Employee.GetJobEntry(Employee."No.", Date, EmployeeJobEntry) then
                    if (EmployeeJobEntry."Calendar Code" = "Calendar Code") and
                       TimesheetStatus.Get(PayrollPeriod.PeriodByDate(Date), Employee."No.")
                    then
                        TimesheetStatus.TestField(Status, TimesheetStatus.Status::Open);
            until Employee.Next = 0;

        Status := Status::Open;
        Modify;
    end;
}

