codeunit 18545 "Tax Fiscal Year Close"
{
    TableNo = "Tax Accounting Period";

    trigger OnRun()
    begin
        TaxAccountingPeriod.Copy(Rec);
        Code();
        Rec := TaxAccountingPeriod;
    end;

    local procedure Code()
    var
        TaxAccountingPeriodClosed: Record "Tax Accounting Period";
        TaxAccountingPeriodLocked: Record "Tax Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        CloseTheOldYearErr: Label 'You must create a new fiscal year before you can close the old year.';
        ClosesTheFiscalYearLbl: Label 'This function closes the fiscal year from %1 to %2 for Tax Type Code %3.', Comment = '%1=Fiscal year from., %2=Fiscal year to., %3=Tax Type Code.';
        FiscalYearCannotBeChangedLbl: Label 'Once the fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.\\';
        CloseTheFiscalYearQst: Label 'Do you want to close the fiscal year for Tax Type Code %3?', Comment = '%3 Tax Type Code.';
    begin
        TaxAccountingPeriodClosed.SetRange(Closed, false);
        TaxAccountingPeriodClosed.SetRange("Tax Type Code", TaxAccountingPeriod."Tax Type Code");
        TaxAccountingPeriodClosed.FindFirst();

        FiscalYearStartDate := TaxAccountingPeriodClosed."Starting Date";
        TaxAccountingPeriod := TaxAccountingPeriodClosed;
        TaxAccountingPeriod.TestField("New Fiscal Year", true);

        TaxAccountingPeriodClosed.SetRange("New Fiscal Year", true);
        TaxAccountingPeriodClosed.SetRange("Tax Type Code", TaxAccountingPeriod."Tax Type Code");
        if TaxAccountingPeriodClosed.Find('>') then begin
            FiscalYearEndDate := CalcDate('<-1D>', TaxAccountingPeriodClosed."Starting Date");
            TaxAccountingPeriodLocked := TaxAccountingPeriodClosed;
            TaxAccountingPeriodClosed.SetRange("New Fiscal Year");
            TaxAccountingPeriodClosed.SetRange("Tax Type Code", TaxAccountingPeriod."Tax Type Code");
            TaxAccountingPeriodClosed.Find('<')
        end else
            Error(CloseTheOldYearErr);

        if not
           Confirm(
             ClosesTheFiscalYearLbl +
             FiscalYearCannotBeChangedLbl +
             CloseTheFiscalYearQst, false,
             FiscalYearStartDate, FiscalYearEndDate, TaxAccountingPeriod."Tax Type Code")
        then
            exit;

        TaxAccountingPeriod.Reset();
        TaxAccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, TaxAccountingPeriodClosed."Starting Date");
        TaxAccountingPeriod.SetRange("Tax Type Code", TaxAccountingPeriodClosed."Tax Type Code");
        TaxAccountingPeriod.ModifyAll(Closed, true);

        TaxAccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, TaxAccountingPeriodLocked."Starting Date");
        TaxAccountingPeriod.SetRange("Tax Type Code", TaxAccountingPeriodLocked."Tax Type Code");
        TaxAccountingPeriod.ModifyAll("Date Locked", true);
    end;

    var
        TaxAccountingPeriod: Record "Tax Accounting Period";
}