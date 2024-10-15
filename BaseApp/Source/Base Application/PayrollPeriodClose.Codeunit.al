codeunit 17410 "Payroll Period-Close"
{
    Permissions = TableData "Employee Absence Entry" = rim;
    TableNo = "Payroll Period";

    trigger OnRun()
    begin
        if Closed then
            exit;

        PayrollStatus.SetRange("Period Code", Code);
        PayrollStatus.SetFilter("Payroll Status", '<%1', PayrollStatus."Payroll Status"::Posted);
        if PayrollStatus.FindSet then
            repeat
                PayrollStatus.FieldError("Payroll Status");
            until PayrollStatus.Next = 0;

        if not HideDialog then
            if not
               Confirm(
                 Text001 +
                 Text002, false,
                 "Starting Date", "Ending Date")
            then
                exit;

        UpdateEmployeeAbsenceEntries("Starting Date", "Ending Date");

        Closed := true;
        Modify(true);
    end;

    var
        Text001: Label 'This function closes the payroll period from %1 to %2. ';
        Text002: Label 'Do you want to close the payroll period?';
        HRSetup: Record "Human Resources Setup";
        PayrollStatus: Record "Payroll Status";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        HideDialog: Boolean;

    [Scope('OnPrem')]
    procedure Reopen(var PayrollPeriod: Record "Payroll Period")
    begin
        with PayrollPeriod do begin
            if not Closed then
                exit;

            Closed := false;
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateEmployeeAbsenceEntries(StartDate: Date; EndDate: Date)
    var
        Employee: Record Employee;
        EmplAbsenceEntry: Record "Employee Absence Entry";
        LinkedEmplAbsenceEntry: Record "Employee Absence Entry";
        NewEmplAbsenceEntry: Record "Employee Absence Entry";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        NewStartDate: Date;
        NewEndDate: Date;
        AbsenceDays: Integer;
        NextEntryNo: Integer;
    begin
        HRSetup.Get();
        HRSetup.TestField("Annual Vacation Group Code");
        HRSetup.TestField("Change Vacation Accr. Periodic");

        if EmplAbsenceEntry.IsEmpty() then
            exit;
        NextEntryNo := EmplAbsenceEntry.GetLastEntryNo() + 1;

        if Employee.FindSet then
            repeat
                AbsenceDays :=
                  TimesheetMgt.GetTimesheetInfo(
                    Employee."No.",
                    HRSetup."Change Vacation Accr. Periodic",
                    StartDate,
                    EndDate,
                    4);
                if AbsenceDays > 0 then begin
                    EmplAbsenceEntry.SetRange("Employee No.", Employee."No.");
                    EmplAbsenceEntry.SetRange("Accrual Entry No.", 0);
                    EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Accrual);
                    EmplAbsenceEntry.SetFilter("End Date", '>%1', StartDate);
                    EmplAbsenceEntry.SetFilter("Start Date", '<%1', EndDate);
                    EmplAbsenceEntry.SetFilter("Time Activity Code", GetAnnualVacTimeActFilter(EndDate));
                    if EmplAbsenceEntry.FindLast then begin
                        NewEmplAbsenceEntry.Init();
                        NewEmplAbsenceEntry.TransferFields(EmplAbsenceEntry);
                        NewEmplAbsenceEntry."Entry No." := NextEntryNo;
                        NewEmplAbsenceEntry."Start Date" := EmplAbsenceEntry."End Date" + 1;
                        NewEmplAbsenceEntry."End Date" := NewEmplAbsenceEntry."Start Date" + AbsenceDays;
                        NewEmplAbsenceEntry."Accrual Entry No." := EmplAbsenceEntry."Entry No.";
                        NewEmplAbsenceEntry."Calendar Days" := 0;
                        NewEmplAbsenceEntry."Working Days" := 0;
                        NewEmplAbsenceEntry.Description := HRSetup.FieldCaption("Change Vacation Accr. Periodic") +
                          ' ' + Format(EndDate, 0, '<Month Text> <Year4>');
                        NewEmplAbsenceEntry.Insert();
                        NextEntryNo := NextEntryNo + 1;
                    end;
                end;

                EmplAbsenceEntry.Reset();
                EmplAbsenceEntry.SetRange("Employee No.", Employee."No.");
                EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Accrual);
                EmplAbsenceEntry.SetRange("End Date", StartDate, EndDate);
                EmplAbsenceEntry.SetRange("Accrual Entry No.", 0);
                EmplAbsenceEntry.SetFilter("Time Activity Code", GetAnnualVacTimeActFilter(EndDate));
                if EmplAbsenceEntry.FindSet then
                    repeat
                        LinkedEmplAbsenceEntry.SetRange("Accrual Entry No.", EmplAbsenceEntry."Entry No.");
                        LinkedEmplAbsenceEntry.SetRange("Entry Type", LinkedEmplAbsenceEntry."Entry Type"::Accrual);
                        if LinkedEmplAbsenceEntry.FindLast then
                            NewStartDate := LinkedEmplAbsenceEntry."End Date" + 1
                        else
                            NewStartDate := EmplAbsenceEntry."End Date" + 1;
                        NewEndDate := CalcDate('<1Y-1D>', NewStartDate);

                        if not AccrualEntryExists(Employee."No.", NewStartDate, NewEndDate) then begin
                            NewEmplAbsenceEntry.Init();
                            NewEmplAbsenceEntry.TransferFields(EmplAbsenceEntry);
                            NewEmplAbsenceEntry."Entry No." := NextEntryNo;
                            NewEmplAbsenceEntry."Start Date" := NewStartDate;
                            NewEmplAbsenceEntry."End Date" := NewEndDate;
                            NewEmplAbsenceEntry."Accrual Entry No." := EmplAbsenceEntry."Entry No.";
                            NewEmplAbsenceEntry."Calendar Days" := EmplAbsenceEntry."Calendar Days";
                            NewEmplAbsenceEntry."Working Days" := 0;
                            NewEmplAbsenceEntry.Insert();
                            NextEntryNo := NextEntryNo + 1;
                        end;
                    until EmplAbsenceEntry.Next = 0;
            until Employee.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetAnnualVacTimeActFilter(StartDate: Date): Code[250]
    var
        TimeActivityFilter: Record "Time Activity Filter";
    begin
        HRSetup.Get();
        TimesheetMgt.GetTimeGroupFilter(HRSetup."Annual Vacation Group Code", StartDate, TimeActivityFilter);
        exit(TimeActivityFilter."Activity Code Filter");
    end;

    [Scope('OnPrem')]
    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [Scope('OnPrem')]
    procedure AccrualEntryExists(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Boolean
    var
        EmplAbsenceEntry: Record "Employee Absence Entry";
    begin
        with EmplAbsenceEntry do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Entry Type", "Entry Type"::Accrual);
            SetRange("Start Date", StartDate);
            SetRange("End Date", EndDate);
            exit(not IsEmpty);
        end;
    end;
}

