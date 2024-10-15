codeunit 17430 "Payroll Calendar Management"
{

    trigger OnRun()
    begin
    end;

    var
        PayrollCalendar: Record "Payroll Calendar";
        CalendarLine: Record "Payroll Calendar Line";
        Text003: Label 'Unknown parameter for %1.';
        Text004: Label 'There are missing calendar %1 lines for period from %2 to %3.';

    [Scope('OnPrem')]
    procedure CheckDateStatus(CalendarCode: Code[10]; TargetDate: Date; var Description: Text[50]): Boolean
    begin
        if CalendarLine.Get(CalendarCode, TargetDate) then begin
            Description := CalendarLine.Description;
            exit(CalendarLine.Nonworking);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDateInfo(CalendarCode: Code[10]; TargetDate: Date; var TimeActivityCode: Code[10]; var DayStatus: Option): Decimal
    begin
        if CalendarLine.Get(CalendarCode, TargetDate) then begin
            TimeActivityCode := CalendarLine."Time Activity Code";
            DayStatus := CalendarLine."Day Status";
            exit(CalendarLine."Work Hours");
        end;

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetNightInfo(CalendarCode: Code[10]; TargetDate: Date): Decimal
    begin
        if CalendarLine.Get(CalendarCode, TargetDate) then
            exit(CalendarLine."Night Hours");

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetPeriodInfo(CalendarCode: Code[10]; StartDate: Date; EndDate: Date; What: Integer): Decimal
    begin
        with PayrollCalendar do begin
            Get(CalendarCode);
            SetRange("Date Filter", StartDate, EndDate);
            CalcFields("Working Hours", "Working Days", "Calendar Days", "Weekend Days", Holidays);
            if "Calendar Days" <> (EndDate - StartDate + 1) then
                Error(Text004, CalendarCode, StartDate, EndDate);
            case What of
                1:
                    exit("Calendar Days");
                2:
                    exit("Working Days");
                3:
                    exit("Working Hours");
                4:
                    exit(Holidays);
                5:
                    exit("Weekend Days");
                6:
                    exit("Night Hours");
                else
                    Error(Text003, TableCaption);
            end;
        end;
    end;
}

