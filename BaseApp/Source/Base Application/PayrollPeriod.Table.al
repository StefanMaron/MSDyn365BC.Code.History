table 17426 "Payroll Period"
{
    Caption = 'Payroll Period';
    LookupPageID = "Payroll Periods";

    fields
    {
        field(1; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                "Starting Date" := CalcDate('<-CM>', "Ending Date");
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Closed; Boolean)
        {
            Caption = 'Closed';
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(6; "Period Duration"; Option)
        {
            Caption = 'Period Duration';
            OptionCaption = 'Month,Quarter,Year,User-Defined';
            OptionMembers = Month,Quarter,Year,"User-Defined";
        }
        field(7; Employees; Integer)
        {
            CalcFormula = Count ("Timesheet Status" WHERE("Period Code" = FIELD(Code)));
            Caption = 'Employees';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Advance Date"; Date)
        {
            Caption = 'Advance Date';
        }
        field(9; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(10; "New Payroll Year"; Boolean)
        {
            Caption = 'New Payroll Year';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Starting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Closed, false);

        TimesheetStatus.Reset();
        TimesheetStatus.SetRange("Period Code", Code);
        TimesheetStatus.SetRange(Status, TimesheetStatus.Status::Released);
        if not TimesheetStatus.IsEmpty then
            Error(Text004, TableCaption, TimesheetStatus.TableCaption);
        TimesheetStatus.SetRange(Status, TimesheetStatus.Status::Open);
        TimesheetStatus.DeleteAll(true);

        PayrollStatus.Reset();
        PayrollStatus.SetRange("Period Code", Code);
        PayrollStatus.SetFilter("Payroll Status", '<>%1', PayrollStatus."Payroll Status"::" ");
    end;

    trigger OnInsert()
    begin
        TestField("Ending Date");
        TestField("Starting Date");

        Employee.Reset();
        if Employee.FindSet then
            repeat
                TimesheetMgt.CreateTimesheet(Employee, Rec);
            until Employee.Next = 0;
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Employee: Record Employee;
        TimesheetStatus: Record "Timesheet Status";
        PayrollStatus: Record "Payroll Status";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        Text001: Label 'You cannot rename the %1.';
        Text003: Label 'You cannot post before %1 because the %2 is already closed. You must re-open the period first.';
        Text004: Label 'You cannot delete the %1 because there is at least one released %2 in this period.';

    [Scope('OnPrem')]
    procedure ShowError(PostingDate: Date)
    begin
        Error(Text003, CalcDate('<+1D>', PostingDate), TableCaption);
    end;

    [Scope('OnPrem')]
    procedure PeriodByDate(Date: Date): Code[10]
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Reset();
        PayrollPeriod.SetFilter("Ending Date", '%1..', Date);
        if not PayrollPeriod.FindFirst then
            exit('');
        if PayrollPeriod."Starting Date" <= Date then
            exit(PayrollPeriod.Code);

        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetMinDate(PayrollPeriod: Record "Payroll Period"; StartDate: Date): Date
    begin
        if PayrollPeriod."Starting Date" > StartDate then
            exit(PayrollPeriod."Starting Date");

        exit(StartDate);
    end;

    [Scope('OnPrem')]
    procedure GetMaxDate(PayrollPeriod: Record "Payroll Period"; EndDate: Date): Date
    begin
        if (EndDate = 0D) or (PayrollPeriod."Ending Date" < EndDate) then
            exit(PayrollPeriod."Ending Date");

        exit(EndDate);
    end;

    [Scope('OnPrem')]
    procedure CheckPeriodExistence(Date: Date)
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Reset();
        PayrollPeriod.SetFilter("Ending Date", '%1..', Date);
        PayrollPeriod.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure GetPrevPeriod(var PrevPeriodCode: Code[10]): Boolean
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Get(Code);
        if PayrollPeriod.Next(-1) = 0 then
            exit(false);

        PrevPeriodCode := PayrollPeriod.Code;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure PeriodStartDateByPeriodCode(PeriodCode: Code[10]): Date
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        if not PayrollPeriod.Get(PeriodCode) then
            exit(0D);
        exit(PayrollPeriod."Starting Date");
    end;

    [Scope('OnPrem')]
    procedure PeriodEndDateByPeriodCode(PeriodCode: Code[10]): Date
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        if not PayrollPeriod.Get(PeriodCode) then
            exit(0D);
        exit(PayrollPeriod."Ending Date");
    end;
}

