report 18543 "Create Tax Accounting Period"
{
    Caption = 'Create Tax Accounting Period';
    ProcessingOnly = true;
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
                    field("Tax Type"; TaxType)
                    {
                        ApplicationArea = Basic, Suite;
                        TableRelation = "Tax Acc. Period Setup";
                        Caption = 'Tax Type';
                        ToolTip = 'Specifies the tax type for the accounting period';
                    }
                    field(StartingDate; FiscalYearStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field("No. Of Periods"; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies how many accounting periods to include.';
                    }
                    field("Period Length"; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            if NoOfPeriods = 0 then begin
                NoOfPeriods := 12;
                Evaluate(PeriodLength, '<1M>');
            end;
            if AccountingPeriod.Find('+') then
                FiscalYearStartDate := AccountingPeriod."Starting Date";
        end;
    }
    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        EndDate: Date;
        FinancialYear: Integer;
        FirstPeriodLocked: Boolean;
        Year: Integer;
        FiscalYearStartDate2: Date;
        FirstPeriodStartDate: Date;
        i: Integer;
        CreateAndCloseQst: Label 'The new fiscal year begins before an existing fiscal year, so the new year will be closed automatically.\\Do you want to create and close the fiscal year?';
        CreateQst: Label 'After you create the new fiscal year, you cannot change its starting date.\\Do you want to create the fiscal year?';
    begin
        AccountingPeriod."Tax Type Code" := TaxType;
        AccountingPeriod."Starting Date" := FiscalYearStartDate;
        AccountingPeriod.TestField("Starting Date");

        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("Tax Type Code", TaxType);
        if AccountingPeriod.Find('-') then begin
            FirstPeriodStartDate := AccountingPeriod."Starting Date";
            FirstPeriodLocked := AccountingPeriod."Date Locked";
            if (not HideDialog) and (FiscalYearStartDate < FirstPeriodStartDate) and FirstPeriodLocked then
                if not ConfirmManagement.GetResponseOrDefault(CreateAndCloseQst, false) then
                    exit;
        end else
            if not HideDialog then
                if not ConfirmManagement.GetResponseOrDefault(CreateQst, false) then
                    exit;

        AccountingPeriod.SetRange(Closed);
        FiscalYearStartDate2 := FiscalYearStartDate;

        EndDate := CalcDate('<1Y>', FiscalYearStartDate2);
        Year := Date2DMY(FiscalYearStartDate2, 3);
        for i := 1 to NoOfPeriods + 1 do begin
            if (FiscalYearStartDate <= FirstPeriodStartDate) and (i = NoOfPeriods + 1) then
                exit;

            AccountingPeriod.Init();
            AccountingPeriod."Tax Type Code" := TaxType;
            AccountingPeriod."Starting Date" := FiscalYearStartDate;
            AccountingPeriod.Validate("Starting Date");
            AccountingPeriod."Ending Date" := CalcDate('<CM>', FiscalYearStartDate);
            FinancialYear := Date2DMY(EndDate, 3);
            if i = NoOfPeriods + 1 then begin
                FinancialYear := FinancialYear + 1;
                Year := Year + 1;
            end;
            AccountingPeriod."Financial Year" := Format(Year) + '-' + Format(FinancialYear);

            IF (i = 1) OR (i = NoOfPeriods + 1) then
                AccountingPeriod."New Fiscal Year" := true;

            AccountingPeriod.Quarter := GetQuarters(i);
            if (FirstPeriodStartDate = 0D) and (i = 1) then
                AccountingPeriod."Date Locked" := true;
            if (AccountingPeriod."Starting Date" < FirstPeriodStartDate) and FirstPeriodLocked then begin
                AccountingPeriod.Closed := true;
                AccountingPeriod."Date Locked" := true;
            end;
            if not AccountingPeriod.Find('=') then
                AccountingPeriod.Insert();
            FiscalYearStartDate := CalcDate(PeriodLength, FiscalYearStartDate);
        end;
        AccountingPeriod.Get(TaxType, FiscalYearStartDate2);
    end;

    procedure InitializeRequest(NewNoOfPeriods: Integer; NewPeriodLength: DateFormula; StartingDate: Date; NewTaxType: Code[20])
    begin
        NoOfPeriods := NewNoOfPeriods;
        PeriodLength := NewPeriodLength;
        AccountingPeriod.SetRange("Tax Type Code", NewTaxType);
        if AccountingPeriod.FindLast() then
            FiscalYearStartDate := AccountingPeriod."Starting Date"
        else
            FiscalYearStartDate := StartingDate;
        TaxType := NewTaxType;
    end;

    procedure HideConfirmationDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure GetQuarters(i: Integer): Code[10]
    var
        Quarter: Code[10];
    begin
        CASE i OF
            1 .. 3, 13:
                Quarter := 'Q1';
            4 .. 6:
                Quarter := 'Q2';
            7 .. 9:
                Quarter := 'Q3';
            ELSE
                Quarter := 'Q4';
        END;
        exit(Quarter);
    end;

    var
        AccountingPeriod: Record "Tax Accounting Period";
        PeriodLength: DateFormula;
        FiscalYearStartDate: Date;
        NoOfPeriods: Integer;
        TaxType: Code[10];
        HideDialog: Boolean;
}
