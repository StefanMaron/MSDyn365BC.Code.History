codeunit 17375 "Vacation Days Calculation"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure CalcVacationForClosedPeriods(EmployeeNo: Code[20]; ToDate: Date; TimeActivityCodeFilter: Code[250]; EntryType: Integer) VacationDays: Decimal
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
    begin
        with EmployeeAbsenceEntry do begin
            SetCurrentKey("Employee No.", "Time Activity Code", "Entry Type", "Start Date");
            SetRange("Accrual Entry No.", 0);
            SetRange("Employee No.", EmployeeNo);
            SetRange("Entry Type", EntryType);
            SetFilter("Time Activity Code", TimeActivityCodeFilter);
            SetFilter("Start Date", '<=%1', ToDate);

            if Find('+') then
                while Next(-1) <> 0 do // period is closed if another period exists after current period
                    if "Start Date" < ToDate then // not including periods after Report To Date
                        VacationDays += "Calendar Days"; // for closed periods only
        end
    end;

    [Scope('OnPrem')]
    procedure CalcVacationForLastPeriod(EmployeeNo: Code[20]; ToDate: Date; TimeActivityCodeFilter: Code[250]; EntryType: Integer; SpecialTerminationReason: Boolean) VacationDays: Decimal
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        Months: Integer;
        LastDate: Date;
    begin
        with EmployeeAbsenceEntry do begin
            SetCurrentKey("Employee No.", "Time Activity Code", "Entry Type", "Start Date");
            SetRange("Accrual Entry No.", 0);
            SetRange("Employee No.", EmployeeNo);
            SetRange("Entry Type", EntryType);
            SetFilter("Time Activity Code", TimeActivityCodeFilter);
            // No filter for EndDate because ToDate may point to additional entries.
            SetFilter("Start Date", '<=%1', ToDate);

            if FindLast then begin
                LastDate := GetAdditionalEntriesLastDate("Entry No.", EntryType);
                if LastDate = 0D then
                    LastDate := "End Date";

                if ToDate <= LastDate then begin
                    Months := (Date2DMY(ToDate, 3) - Date2DMY("Start Date", 3)) * 12 + (Date2DMY(ToDate, 2) - Date2DMY("Start Date", 2)) -
                      ((Date2DMY(LastDate, 3) - Date2DMY("End Date", 3)) * 12 + Date2DMY(LastDate, 2) - Date2DMY("End Date", 2));

                    if (Date2DMY(ToDate, 1) - Date2DMY("Start Date", 1) - (Date2DMY(LastDate, 1) - Date2DMY("End Date", 1))) > 15 then
                        Months += 1;

                    if (Date2DMY(ToDate, 1) - Date2DMY("Start Date", 1) - (Date2DMY(LastDate, 1) - Date2DMY("End Date", 1))) <= -15 then
                        Months -= 1;

                    if (SpecialTerminationReason and (Months > 6)) or (Months >= 11) then
                        VacationDays := "Calendar Days"
                    else
                        VacationDays := ("Calendar Days" / 12) * Months;
                end else
                    VacationDays := "Calendar Days";
            end;
        end;
        exit(VacationDays);
    end;

    [Scope('OnPrem')]
    procedure GetAdditionalEntriesLastDate(AccrualEntryNo: Integer; EntryType: Integer): Date
    var
        AdditionalAbsenceEntry: Record "Employee Absence Entry";
        MaxDate: Date;
    begin
        with AdditionalAbsenceEntry do begin
            SetCurrentKey("Accrual Entry No.", "Entry Type");
            SetRange("Accrual Entry No.", AccrualEntryNo);
            SetRange("Entry Type", EntryType);

            MaxDate := 0D;

            if FindSet then
                repeat
                    if "End Date" > MaxDate then
                        MaxDate := "End Date";
                until Next() = 0;

            exit(MaxDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalculateVacationDays(EmployeeNo: Code[20]; ToDate: Date; TimeActivityCodeFilter: Code[250]): Decimal
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
    begin
        exit(CalcVacationForClosedPeriods(EmployeeNo, ToDate, TimeActivityCodeFilter, EmployeeAbsenceEntry."Entry Type"::Accrual) +
          CalcVacationForLastPeriod(EmployeeNo, ToDate, TimeActivityCodeFilter, EmployeeAbsenceEntry."Entry Type"::Accrual, false));
    end;

    [Scope('OnPrem')]
    procedure CalculateUsedVacationDays(EmployeeNo: Code[20]; ToDate: Date; TimeActivityCodeFilter: Code[250]): Decimal
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
    begin
        with EmployeeAbsenceEntry do begin
            SetCurrentKey("Employee No.", "Time Activity Code", "Entry Type", "Start Date");
            SetRange("Employee No.", EmployeeNo);
            SetRange("Entry Type", "Entry Type"::Usage);
            SetFilter("Time Activity Code", TimeActivityCodeFilter);
            SetFilter("Start Date", '<=%1', ToDate);

            CalcSums("Calendar Days");
            exit("Calendar Days");
        end
    end;

    [Scope('OnPrem')]
    procedure CalculateUnusedVacationDays(EmployeeNo: Code[20]; ToDate: Date; TimeActivityCodeFilter: Code[250]): Decimal
    begin
        exit(CalculateVacationDays(EmployeeNo, ToDate, TimeActivityCodeFilter) -
          CalculateUsedVacationDays(EmployeeNo, ToDate, TimeActivityCodeFilter));
    end;

    [Scope('OnPrem')]
    procedure CalculateAllUnusedVacationDays(EmployeeNo: Code[20]; ToDate: Date): Decimal
    var
        PayrollPeriodClose: Codeunit "Payroll Period-Close";
    begin
        exit(CalculateUnusedVacationDays(EmployeeNo, ToDate,
            PayrollPeriodClose.GetAnnualVacTimeActFilter(ToDate)));
    end;
}

