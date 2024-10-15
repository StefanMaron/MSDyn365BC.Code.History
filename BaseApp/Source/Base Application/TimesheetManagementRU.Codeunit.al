codeunit 17440 "Timesheet Management RU"
{

    trigger OnRun()
    begin
    end;

    var
        TimesheetStatus: Record "Timesheet Status";
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        HRSetup: Record "Human Resources Setup";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        CalendarMgt: Codeunit "Payroll Calendar Management";
        Text001: Label 'Absence order %1 has been already posted at %2 for %3.';
        PostedOrderCancellation: Boolean;

    [Scope('OnPrem')]
    procedure TimesheetSelection(var CurrentPeriodCode: Code[10]) Selected: Boolean
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        Selected := true;
        PayrollPeriod.Reset();
        case PayrollPeriod.Count of
            0:
                Error('');
            1:
                PayrollPeriod.FindFirst;
            else
                Selected := PAGE.RunModal(0, PayrollPeriod) = ACTION::LookupOK;
        end;
        CurrentPeriodCode := PayrollPeriod.Code;
    end;

    [Scope('OnPrem')]
    procedure LookupName(CurrentEmployeeNo: Code[20]; var CurrentPeriodCode: Code[10]; var TimesheetLine: Record "Timesheet Line")
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        Commit();
        PayrollPeriod.Code := CurrentPeriodCode;
        if PAGE.RunModal(0, PayrollPeriod) = ACTION::LookupOK then begin
            CurrentPeriodCode := PayrollPeriod.Code;
            SetName(CurrentEmployeeNo, PayrollPeriod, TimesheetLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentEmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; var TimesheetLine: Record "Timesheet Line")
    begin
        TimesheetLine.FilterGroup := 2;
        TimesheetLine.SetRange("Employee No.", CurrentEmployeeNo);
        TimesheetLine.SetRange(Date, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date");
        TimesheetLine.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure CreateTimesheet(Employee: Record Employee; PayrollPeriod: Record "Payroll Period")
    var
        TimesheetLine: Record "Timesheet Line";
        TimesheetStatus: Record "Timesheet Status";
        PayrollStatus: Record "Payroll Status";
        EmplJobEntry: Record "Employee Job Entry";
        CalendarLine: Record "Payroll Calendar Line";
        Period: Record Date;
        CurrentDate: Date;
        DayStatus: Option " ",Weekend,Holiday;
    begin
        if Employee."Employment Date" <= PayrollPeriod."Ending Date" then begin
            if not TimesheetStatus.Get(PayrollPeriod.Code, Employee."No.") then begin
                TimesheetStatus.Init();
                TimesheetStatus."Period Code" := PayrollPeriod.Code;
                TimesheetStatus."Employee No." := Employee."No.";
                TimesheetStatus.Insert();
            end;
            if not PayrollStatus.Get(PayrollPeriod.Code, Employee."No.") then begin
                PayrollStatus.Init();
                PayrollStatus."Period Code" := PayrollPeriod.Code;
                PayrollStatus."Employee No." := Employee."No.";
                PayrollStatus.Insert();
            end;
        end;

        CurrentDate := PayrollPeriod."Starting Date";
        while CurrentDate <= PayrollPeriod."Ending Date" do begin
            if Employee.GetJobEntry(Employee."No.", CurrentDate, EmplJobEntry) then begin
                TimesheetLine.Init();
                TimesheetLine."Calendar Code" := EmplJobEntry."Calendar Code";
                TimesheetLine.Date := CurrentDate;
                CalendarLine.Get(TimesheetLine."Calendar Code", TimesheetLine.Date);
                CalendarLine.TestField(Status, CalendarLine.Status::Released);
                TimesheetLine."Employee No." := Employee."No.";
                TimesheetLine.Validate(Nonworking,
                  CalendarMgt.CheckDateStatus(
                    TimesheetLine."Calendar Code", CurrentDate, TimesheetLine.Description));
                TimesheetLine.Validate("Planned Hours",
                  CalendarMgt.GetDateInfo(
                    TimesheetLine."Calendar Code", CurrentDate, TimesheetLine."Time Activity Code", DayStatus));
                TimesheetLine.Validate("Planned Night Hours",
                  CalendarMgt.GetNightInfo(
                    TimesheetLine."Calendar Code", CurrentDate));
                Period.Get(Period."Period Type"::Date, CurrentDate);
                TimesheetLine.Day := Period."Period Name";
                if not TimesheetLine.Insert(true) then
                    TimesheetLine.Modify(true);
                InsertTimesheetDetails(
                  Employee."No.", TimesheetLine.Date, TimesheetLine."Time Activity Code",
                  TimesheetLine."Planned Hours", TimesheetLine."Planned Night Hours", '', 0, '', 0D);
            end;
            CurrentDate := CalcDate('<1D>', CurrentDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTimesheet(Employee: Record Employee; StartDate: Date; EndDate: Date; CalendarCode: Code[10]; CheckReleased: Boolean)
    var
        TimesheetLine: Record "Timesheet Line";
        CalendarLine: Record "Payroll Calendar Line";
        Period: Record Date;
        CurrentDate: Date;
        DayStatus: Option " ",Weekend,Holiday;
    begin
        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            TimesheetLine.Get(Employee."No.", CurrentDate);
            TimesheetLine.Validate("Calendar Code", CalendarCode);
            CalendarLine.Get(TimesheetLine."Calendar Code", TimesheetLine.Date);
            if CheckReleased then
                CalendarLine.TestField(Status, CalendarLine.Status::Released);
            TimesheetLine.Validate(Nonworking,
              CalendarMgt.CheckDateStatus(
                TimesheetLine."Calendar Code", CurrentDate, TimesheetLine.Description));
            TimesheetLine.Validate("Planned Hours",
              CalendarMgt.GetDateInfo(
                TimesheetLine."Calendar Code", CurrentDate, TimesheetLine."Time Activity Code", DayStatus));
            Period.Get(Period."Period Type"::Date, CurrentDate);
            TimesheetLine.Day := Period."Period Name";
            TimesheetLine.Modify(true);
            InsertTimesheetDetails(
              Employee."No.", TimesheetLine.Date, TimesheetLine."Time Activity Code",
              TimesheetLine."Planned Hours", TimesheetLine."Planned Night Hours", '', 0, '', 0D);
            CurrentDate := CalcDate('<1D>', CurrentDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckTimesheetStatus(EmployeeNo: Code[20]; CalendarCode: Code[10]; Date: Date)
    var
        CalendarLine: Record "Payroll Calendar Line";
    begin
        TimesheetStatus.Get(
          PayrollPeriod.PeriodByDate(Date), EmployeeNo);
        TimesheetStatus.TestField(Status, TimesheetStatus.Status::Open);
        CalendarLine.Get(CalendarCode, Date);
        CalendarLine.TestField(Status, CalendarLine.Status::Released);
    end;

    [Scope('OnPrem')]
    procedure InsertTimesheetDetails(EmployeeNo: Code[20]; Date: Date; ActivityCode: Code[10]; PlannedHours: Decimal; NightHours: Decimal; Description: Text[50]; DocType: Option; DocNo: Code[20]; DocDate: Date)
    var
        TimesheetDetail: Record "Timesheet Detail";
        EmplJobEntry: Record "Employee Job Entry";
        PreviousTimeActivityCode: Code[10];
    begin
        TimesheetDetail.Reset();
        TimesheetDetail.SetRange("Employee No.", EmployeeNo);
        TimesheetDetail.SetRange(Date, Date);
        if TimesheetDetail.FindSet then
            repeat
                if PostedOrderCancellation then
                    PreviousTimeActivityCode := TimesheetDetail."Previous Time Activity Code"
                else begin
                    PreviousTimeActivityCode := TimesheetDetail."Time Activity Code";
                    if TimesheetDetail."Document No." <> '' then
                        Error(Text001, TimesheetDetail."Document No.", EmployeeNo, Date);
                end;
            until TimesheetDetail.Next() = 0;
        TimesheetDetail.DeleteAll();

        // Insert planned hours
        TimesheetDetail.Init();
        TimesheetDetail.Validate("Employee No.", EmployeeNo);
        TimesheetDetail.Date := Date;
        if PostedOrderCancellation and (PreviousTimeActivityCode <> '') then
            ActivityCode := PreviousTimeActivityCode;
        TimesheetDetail.Validate("Time Activity Code", ActivityCode);
        if Employee.GetJobEntry(EmployeeNo, Date, EmplJobEntry) then begin
            TimesheetDetail."Calendar Code" := EmplJobEntry."Calendar Code";
            TimesheetDetail."Org. Unit Code" := EmplJobEntry."Org. Unit Code";
        end else begin
            TimesheetDetail."Calendar Code" := Employee."Calendar Code";
            TimesheetDetail."Org. Unit Code" := Employee."Org. Unit Code";
        end;
        TimesheetDetail."Actual Hours" := PlannedHours;
        if Description <> '' then
            TimesheetDetail.Description := Description;
        TimesheetDetail."User ID" := UserId;
        if (DocNo <> '') and (DocDate <> 0D) then begin
            TimesheetDetail."Document Type" := DocType;
            TimesheetDetail."Document No." := DocNo;
            TimesheetDetail."Document Date" := DocDate;
        end;
        if not PostedOrderCancellation then
            TimesheetDetail."Previous Time Activity Code" := PreviousTimeActivityCode;
        TimesheetDetail.Insert();

        // insert night hours if any
        if NightHours <> 0 then begin
            HRSetup.Get();
            HRSetup.TestField("Default Night Hours Code");
            TimesheetDetail."Time Activity Code" := HRSetup."Default Night Hours Code";
            TimesheetDetail."Actual Hours" := NightHours;
            TimesheetDetail."Previous Time Activity Code" := '';
            TimesheetDetail.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTimesheetInfo(EmployeeNo: Code[20]; TimeActivityGroupCode: Code[20]; StartDate: Date; EndDate: Date; What: Option "Planned Days","Planned Hours","Actual Calendar Days","Actual Hours","Actual Work Days","Planned Night Hours"): Decimal
    var
        Employee: Record Employee;
        TimeActivityFilter: Record "Time Activity Filter";
        TimesheetDetail: Record "Timesheet Detail";
        TimesheetLine: Record "Timesheet Line";
        CurrDate: Date;
        ActualDays: Decimal;
    begin
        Employee.Get(EmployeeNo);
        case What of
            What::"Planned Days":
                exit(CalendarMgt.GetPeriodInfo(Employee."Calendar Code", StartDate, EndDate, 2));
            What::"Planned Hours":
                exit(CalendarMgt.GetPeriodInfo(Employee."Calendar Code", StartDate, EndDate, 3));
            What::"Actual Calendar Days",
            What::"Actual Work Days":
                begin
                    ActualDays := 0;
                    TimesheetDetail.Reset();
                    TimesheetDetail.SetRange("Employee No.", EmployeeNo);
                    if TimeActivityGroupCode <> '' then begin
                        GetTimeGroupFilter(TimeActivityGroupCode, StartDate, TimeActivityFilter);
                        if (TimeActivityFilter."Activity Code Filter" = '') and
                           (TimeActivityFilter."Timesheet Code Filter" = '')
                        then
                            exit(0);
                        TimesheetDetail.SetFilter("Time Activity Code", TimeActivityFilter."Activity Code Filter");
                        TimesheetDetail.SetFilter("Timesheet Code", TimeActivityFilter."Timesheet Code Filter");
                    end;
                    CurrDate := StartDate;
                    while CurrDate <= EndDate do begin
                        TimesheetDetail.SetRange(Date, CurrDate);
                        if TimesheetDetail.FindFirst then
                            case What of
                                What::"Actual Calendar Days":
                                    ActualDays := ActualDays + 1;
                                What::"Actual Work Days":
                                    begin
                                        TimesheetLine.Get(TimesheetDetail."Employee No.", TimesheetDetail.Date);
                                        if not TimesheetLine.Nonworking then
                                            ActualDays := ActualDays + 1;
                                    end;
                            end;
                        CurrDate := CalcDate('<1D>', CurrDate);
                    end;
                    exit(ActualDays);
                end;
            What::"Actual Hours":
                begin
                    Employee.Reset();
                    Employee.SetRange("Employee No. Filter", EmployeeNo);
                    Employee.SetRange("Date Filter", StartDate, EndDate);
                    if TimeActivityGroupCode <> '' then begin
                        GetTimeGroupFilter(TimeActivityGroupCode, StartDate, TimeActivityFilter);
                        if (TimeActivityFilter."Activity Code Filter" = '') and
                           (TimeActivityFilter."Timesheet Code Filter" = '')
                        then
                            exit(0);
                        Employee.SetFilter("Time Activity Filter", TimeActivityFilter."Activity Code Filter");
                        Employee.SetFilter("Timesheet Code Filter", TimeActivityFilter."Timesheet Code Filter");
                    end;
                    Employee.CalcFields("Actual Hours");
                    exit(Employee."Actual Hours");
                end;
            What::"Planned Night Hours":
                exit(CalendarMgt.GetPeriodInfo(Employee."Calendar Code", StartDate, EndDate, 6));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTimeSheetData(var PayrollDocLine: Record "Payroll Document Line"; UOM: Option Day,Hour; TimeActivityGroup: Code[20]): Decimal
    begin
        PayrollPeriod.Get(PayrollDocLine."Period Code");
        case UOM of
            UOM::Day:
                begin
                    PayrollDocLine."Payment Days" :=
                      TimesheetMgt.GetTimesheetInfo(
                        PayrollDocLine."Employee No.", TimeActivityGroup,
                        PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 2);
                    PayrollDocLine."Payment Hours" := 0;
                    exit(PayrollDocLine."Payment Days");
                end;
            UOM::Hour:
                begin
                    HRSetup.Get();
                    if TimeActivityGroup = HRSetup."Night Work Group Code" then
                        PayrollDocLine."Payment Hours" :=
                          TimesheetMgt.GetTimesheetInfo(
                            PayrollDocLine."Employee No.", TimeActivityGroup,
                            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 6)
                    else
                        PayrollDocLine."Payment Hours" :=
                          TimesheetMgt.GetTimesheetInfo(
                            PayrollDocLine."Employee No.", TimeActivityGroup,
                            PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 3);
                    PayrollDocLine."Payment Days" := 0;
                    exit(PayrollDocLine."Payment Hours");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTimeGroupFilter(GroupCode: Code[20]; StartDate: Date; var TimeActivityFilter: Record "Time Activity Filter")
    begin
        TimeActivityFilter.Reset();
        TimeActivityFilter.SetRange(Code, GroupCode);
        TimeActivityFilter.SetFilter("Starting Date", '..%1', StartDate);
        if not TimeActivityFilter.FindLast then
            Clear(TimeActivityFilter);
    end;

    [Scope('OnPrem')]
    procedure CreateFromLine(EmployeeNo: Code[20]; TimeActivityCode: Code[10]; StartDate: Date; EndDate: Date; DocumentType: Option; DocumentNo: Code[20]; DocumentDate: Date)
    var
        TimesheetLine: Record "Timesheet Line";
        CurrDate: Date;
    begin
        CurrDate := StartDate;
        while CurrDate <= EndDate do begin
            TimesheetLine.Reset();
            TimesheetLine.SetRange("Employee No.", EmployeeNo);
            TimesheetLine.SetRange(Date, CurrDate);
            TimesheetLine.FindFirst;

            InsertTimesheetDetails(
              EmployeeNo, CurrDate,
              TimeActivityCode, TimesheetLine."Planned Hours", TimesheetLine."Planned Night Hours",
              '', DocumentType, DocumentNo, DocumentDate);

            CurrDate := CalcDate('<1D>', CurrDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsPostedOrderCancellation(PostedOrderCancellation2: Boolean)
    begin
        PostedOrderCancellation := PostedOrderCancellation2;
    end;
}

