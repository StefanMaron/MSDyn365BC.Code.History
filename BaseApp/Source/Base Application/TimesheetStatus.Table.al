table 17440 "Timesheet Status"
{
    Caption = 'Timesheet Status';

    fields
    {
        field(1; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(6; "Payroll Status"; Option)
        {
            Caption = 'Payroll Status';
            OptionCaption = ' ,Calculated,Posted,Paid';
            OptionMembers = " ",Calculated,Posted,Paid;
        }
        field(7; "Advance Status"; Option)
        {
            Caption = 'Advance Status';
            OptionCaption = ' ,Calculated,Posted,Paid';
            OptionMembers = " ",Calculated,Posted,Paid;
        }
        field(10; "Planned Work Days"; Decimal)
        {
            Caption = 'Planned Work Days';
        }
        field(11; "Planned Work Hours"; Decimal)
        {
            Caption = 'Planned Work Hours';
        }
        field(12; "Calendar Days"; Decimal)
        {
            Caption = 'Calendar Days';
        }
        field(13; "Actual Work Days"; Decimal)
        {
            Caption = 'Actual Work Days';
        }
        field(14; "Actual Work Hours"; Decimal)
        {
            Caption = 'Actual Work Hours';
        }
        field(15; "Absence Work Days"; Decimal)
        {
            Caption = 'Absence Work Days';
        }
        field(16; "Absence Hours"; Decimal)
        {
            Caption = 'Absence Hours';
        }
        field(17; "Overtime Hours"; Decimal)
        {
            Caption = 'Overtime Hours';
        }
        field(18; "Holiday Work Days"; Decimal)
        {
            Caption = 'Holiday Work Days';
        }
        field(19; "Holiday Work Hours"; Decimal)
        {
            Caption = 'Holiday Work Hours';
        }
        field(20; "Absence Calendar Days"; Decimal)
        {
            Caption = 'Absence Calendar Days';
        }
        field(21; "Actual Calendar Days"; Decimal)
        {
            Caption = 'Actual Calendar Days';
        }
        field(22; "Planned Night Hours"; Decimal)
        {
            Caption = 'Planned Night Hours';
        }
    }

    keys
    {
        key(Key1; "Period Code", "Employee No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        PayrollPeriod.Get("Period Code");

        TimesheetLine.Reset();
        TimesheetLine.SetRange("Employee No.", "Employee No.");
        TimesheetLine.SetRange(Date, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
        TimesheetLine.DeleteAll(true);
    end;

    var
        PayrollPeriod: Record "Payroll Period";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollDoc: Record "Payroll Document";
        Text14800: Label 'You cannot reopen because there are payroll ledger entries for this period.';
        Text14801: Label 'You cannot reopen because there are payroll documents for this period.';
        EmployeeJobEntry: Record "Employee Job Entry";
        TimesheetStatus: Record "Timesheet Status";
        TimesheetLine: Record "Timesheet Line";
        HumanResSetup: Record "Human Resources Setup";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        Text14802: Label 'You should reopen Timesheet for %1 Period Code first.';

    [Scope('OnPrem')]
    procedure Release()
    begin
        if Status = Status::Released then
            exit;

        TimesheetStatus.Reset();
        TimesheetStatus.SetRange("Employee No.", "Employee No.");
        TimesheetStatus.SetFilter("Period Code", '<%1', "Period Code");
        TimesheetStatus.SetRange(Status, TimesheetStatus.Status::Open);
        if TimesheetStatus.FindFirst then
            TimesheetStatus.TestField(Status, TimesheetStatus.Status::Released);

        Calculate;

        Status := Status::Released;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    begin
        if Status = Status::Open then
            exit;

        PayrollLedgEntry.Reset();
        PayrollLedgEntry.SetCurrentKey("Employee No.");
        PayrollLedgEntry.SetRange("Employee No.", "Employee No.");
        PayrollLedgEntry.SetRange("Period Code", "Period Code");
        PayrollLedgEntry.SetRange(Reversed, false);
        if not PayrollLedgEntry.IsEmpty() then
            Error(Text14800);

        PayrollDoc.Reset();
        PayrollDoc.SetCurrentKey("Employee No.");
        PayrollDoc.SetRange("Employee No.", "Employee No.");
        PayrollDoc.SetRange("Period Code", "Period Code");
        if not PayrollDoc.IsEmpty() then
            Error(Text14801);

        TimesheetStatus.Reset();
        TimesheetStatus.SetRange("Employee No.", "Employee No.");
        TimesheetStatus.SetFilter("Period Code", '>%1', "Period Code");
        TimesheetStatus.SetRange(Status, TimesheetStatus.Status::Released);
        if TimesheetStatus.FindLast then
            Error(Text14802, "Period Code");

        Status := Status::Open;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure Calculate()
    var
        StartDate: Date;
        EndDate: Date;
    begin
        PayrollPeriod.Get("Period Code");

        HumanResSetup.Get();
        HumanResSetup.TestField("Work Time Group Code");
        HumanResSetup.TestField("Night Work Group Code");
        HumanResSetup.TestField("Overtime 1.5 Group Code");
        HumanResSetup.TestField("Overtime 2.0 Group Code");
        HumanResSetup.TestField("Weekend Work Group");
        HumanResSetup.TestField("Holiday Work Group");
        HumanResSetup.TestField("Absence Group Code");

        "Planned Work Days" := 0;
        "Planned Work Hours" := 0;
        "Calendar Days" := 0;
        "Actual Work Days" := 0;
        "Actual Work Hours" := 0;
        "Absence Calendar Days" := 0;
        "Absence Work Days" := 0;
        "Absence Hours" := 0;
        "Overtime Hours" := 0;
        "Holiday Work Days" := 0;
        "Holiday Work Hours" := 0;

        EmployeeJobEntry.Reset();
        EmployeeJobEntry.SetCurrentKey("Employee No.");
        EmployeeJobEntry.SetRange("Employee No.", "Employee No.");
        EmployeeJobEntry.SetRange("Position Changed", true);
        EmployeeJobEntry.SetRange("Starting Date", 0D, PayrollPeriod."Ending Date");
        EmployeeJobEntry.SetFilter("Ending Date", '%1|%2..', 0D, PayrollPeriod."Starting Date");
        if EmployeeJobEntry.FindSet then
            repeat
                StartDate := PayrollPeriod.GetMinDate(PayrollPeriod, EmployeeJobEntry."Starting Date");
                EndDate := PayrollPeriod.GetMaxDate(PayrollPeriod, EmployeeJobEntry."Ending Date");
                "Calendar Days" +=
                  CalendarMgt.GetPeriodInfo(
                    EmployeeJobEntry."Calendar Code", StartDate, EndDate, 1);
                "Planned Work Days" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Work Time Group Code", StartDate, EndDate, 0);
                "Planned Work Hours" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Work Time Group Code", StartDate, EndDate, 1);
                "Planned Night Hours" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Work Time Group Code", StartDate, EndDate, 6);
                "Actual Work Days" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Work Time Group Code", StartDate, EndDate, 2);
                "Actual Work Hours" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Work Time Group Code", StartDate, EndDate, 3);
                "Overtime Hours" +=
                  (TimesheetMgt.GetTimesheetInfo(
                     "Employee No.", HumanResSetup."Overtime 1.5 Group Code", StartDate, EndDate, 3) +
                   TimesheetMgt.GetTimesheetInfo(
                     "Employee No.", HumanResSetup."Overtime 2.0 Group Code", StartDate, EndDate, 3));
                "Holiday Work Days" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Holiday Work Group", StartDate, EndDate, 2);
                "Holiday Work Hours" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Holiday Work Group", StartDate, EndDate, 3);
                "Absence Calendar Days" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Absence Group Code", StartDate, EndDate, 2);
                "Actual Calendar Days" :=
                  "Calendar Days" - "Absence Calendar Days";
                "Absence Work Days" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Absence Group Code", StartDate, EndDate, 4);
                "Absence Hours" +=
                  TimesheetMgt.GetTimesheetInfo(
                    "Employee No.", HumanResSetup."Absence Group Code", StartDate, EndDate, 3);
            until EmployeeJobEntry.Next() = 0;
    end;
}

