codeunit 17351 "Average Headcount Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        HRSetup: Record "Human Resources Setup";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        CalendarMgt: Codeunit "Payroll Calendar Management";

    [Scope('OnPrem')]
    procedure CalcAvgCount(EmployeeNo: Code[20]; CurrDate: Date) AvgAmt: Decimal
    var
        EmplJobEntry: Record "Employee Job Entry";
        PayrollPeriod: Record "Payroll Period";
        StartDate: Date;
        EndDate: Date;
        ActualWorkDays: Decimal;
        ActualWorkHours: Decimal;
        StandardCalendarWorkHours: Decimal;
        AdjustedDaysOff: Decimal;
    begin
        HRSetup.Get;
        HRSetup.TestField("Official Calendar Code");
        HRSetup.TestField("Average Headcount Group Code");

        PayrollPeriod.Get(PayrollPeriod.PeriodByDate(CurrDate));
        PayrollPeriod.TestField("Starting Date");
        StartDate := PayrollPeriod."Starting Date";
        EndDate := PayrollPeriod."Ending Date";

        EmplJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmplJobEntry.SetRange("Employee No.", EmployeeNo);
        EmplJobEntry.SetFilter("Starting Date", '<=%1', EndDate);
        EmplJobEntry.SetFilter("Position Rate", '>0');
        if EmplJobEntry.FindSet then
            repeat
                if (EmplJobEntry."Ending Date" = 0D) or
                   (EmplJobEntry."Ending Date" >= StartDate)
                then
                    // full-time employee
                    if not EmplJobEntry."Out-of-Staff" then begin
                        ActualWorkDays :=
                          TimesheetMgt.GetTimesheetInfo(
                            EmployeeNo, HRSetup."Average Headcount Group Code", StartDate, EndDate, 2);
                        AdjustedDaysOff := AdjustDaysOff(EmployeeNo, StartDate, EndDate);
                        ActualWorkDays -= AdjustedDaysOff;
                        AvgAmt += ActualWorkDays / (EndDate - StartDate + 1);
                    end else begin
                        // part-time employee
                        ActualWorkHours :=
                          TimesheetMgt.GetTimesheetInfo(
                            EmployeeNo, HRSetup."Average Headcount Group Code", StartDate, EndDate, 3);
                        StandardCalendarWorkHours :=
                          CalendarMgt.GetPeriodInfo(HRSetup."Official Calendar Code", StartDate, EndDate, 3);
                        if StandardCalendarWorkHours <> 0 then
                            AvgAmt += ActualWorkHours / StandardCalendarWorkHours;
                    end;
            until EmplJobEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure AdjustDaysOff(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date) AdjAmount: Decimal
    var
        TimesheetLine: Record "Timesheet Line";
        TimesheetLineWorking: Record "Timesheet Line";
    begin
        TimesheetLine.SetRange("Calendar Code", HRSetup."Default Calendar Code");
        TimesheetLine.SetRange("Employee No.", EmployeeNo);
        TimesheetLine.SetRange(Date, StartDate, EndDate);
        TimesheetLine.SetRange(Nonworking, true);
        if TimesheetLine.FindSet then
            repeat
                // find previous working day
                TimesheetLineWorking.Copy(TimesheetLine);
                TimesheetLineWorking.SetFilter(Date, '..%1', TimesheetLine.Date);
                TimesheetLineWorking.SetRange(Nonworking, false);
                if TimesheetLineWorking.FindLast then begin
                    // check employees presence at that date
                    if TimesheetMgt.GetTimesheetInfo(
                         EmployeeNo,
                         HRSetup."Average Headcount Group Code",
                         TimesheetLineWorking.Date,
                         TimesheetLineWorking.Date,
                         2) = 0
                    then
                        AdjAmount += 1;
                end;
            until TimesheetLine.Next = 0;
    end;
}

