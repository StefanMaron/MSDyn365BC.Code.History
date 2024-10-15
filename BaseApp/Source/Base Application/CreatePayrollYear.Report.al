report 17413 "Create Payroll Year"
{
    Caption = 'Create Payroll Year';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PayrollYearStartDate; PayrollYearStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        Editable = false;
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        Editable = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            NoOfPeriods := 12;
            Evaluate(PeriodLength, '<1M>');
            if PayrollPeriod.Find('+') then
                PayrollYearStartDate := PayrollPeriod."Starting Date";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PayrollPeriod."Starting Date" := PayrollYearStartDate;
        PayrollPeriod.TestField("Starting Date");

        if PayrollPeriod.Find('-') then begin
            FirstPeriodStartDate := PayrollPeriod."Starting Date";
            if PayrollYearStartDate < FirstPeriodStartDate then
                if not
                   Confirm(
                     Text000 +
                     Text001)
                then
                    exit;
            if PayrollPeriod.Find('+') then
                LastPeriodStartDate := PayrollPeriod."Starting Date";
        end else
            if not
               Confirm(
                 Text002 +
                 Text003)
            then
                exit;

        FiscalYearStartDate2 := PayrollYearStartDate;

        for i := 1 to NoOfPeriods + 1 do begin
            if (PayrollYearStartDate <= FirstPeriodStartDate) and (i = NoOfPeriods + 1) then
                exit;

            if FirstPeriodStartDate <> 0D then
                if (PayrollYearStartDate >= FirstPeriodStartDate) and (PayrollYearStartDate < LastPeriodStartDate) then
                    Error(Text004);
            PayrollPeriod.Init();
            PayrollPeriod.Code := Format(PayrollYearStartDate, 0, '<Year><Month,2>');
            PayrollPeriod."Starting Date" := PayrollYearStartDate;
            PayrollPeriod."Ending Date" := CalcDate('<CM>', PayrollYearStartDate);
            PayrollPeriod.Name := Format(PayrollYearStartDate, 0, '<Month Text> <Year4>');
            PayrollPeriod.Validate("Starting Date");
            if Date2DMY(PayrollYearStartDate, 2) = 1 then
                PayrollPeriod."New Payroll Year" := true;

            if PayrollPeriod."Starting Date" < FirstPeriodStartDate then
                PayrollPeriod.Closed := true;

            if not PayrollPeriod.Find('=') then
                PayrollPeriod.Insert(true);
            PayrollYearStartDate := CalcDate(PeriodLength, PayrollYearStartDate);
        end;
    end;

    var
        Text000: Label 'The new payroll year begins before an existing payroll year, so the new year will be closed automatically.\\';
        Text001: Label 'Do you want to create and close the payroll year?';
        Text002: Label 'Once you create the new payroll year you cannot change its starting date.\\';
        Text003: Label 'Do you want to create the payroll year?';
        Text004: Label 'It is only possible to create new payroll years before or after the existing ones.';
        PayrollPeriod: Record "Payroll Period";
        NoOfPeriods: Integer;
        PeriodLength: DateFormula;
        PayrollYearStartDate: Date;
        FiscalYearStartDate2: Date;
        FirstPeriodStartDate: Date;
        LastPeriodStartDate: Date;
        i: Integer;
}

