codeunit 10862 "Fiscal Year-FiscalClose"
{
    TableNo = "Accounting Period";

    trigger OnRun()
    begin
        AccountingPeriod.Copy(Rec);
        Code();
        Rec := AccountingPeriod;
    end;

    var
        Text001: Label 'You must create a new fiscal year before you can fiscally close the old year.';
        Text002: Label 'This function fiscally closes the fiscal year from %1 to %2. ';
        Text003: Label 'Make sure to make a backup of the database before fiscally closing the fiscal year, because once the fiscal year is fiscally closed it cannot be opened again and no G/L entries can be posted anymore on a fiscally closed fiscal year.\\';
        Text004: Label 'Do you want to fiscally close the fiscal year?';
        Text006: Label 'To fiscally close the fiscal year from %1 to %2, you must first post or delete all unposted general journal lines for this fiscal year.\\%3=''%4'',%5=''%6'',%7=''%8''.';
        Text007: Label 'The Income Statement G/L accounts are not balanced at date %1. Please run the batch job Close Income Statement again before fiscally closing the fiscal year from %2 to %3.';
        AccountingPeriod: Record "Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        Text008: Label 'The fiscal year from %1 to %2 must first be closed before it can be fiscally closed.';
        Text009: Label 'Fiscally Closed';
        Text010: Label 'Fiscally Open';

    local procedure "Code"()
    begin
        with AccountingPeriod do begin
            SetRange("New Fiscal Year", true);
            SetRange("Fiscally Closed", false);
            FindFirst();

            // define FY starting and ending date
            FiscalYearStartDate := "Starting Date";
            if Find('>') then begin
                FiscalYearEndDate := CalcDate('<-1D>', "Starting Date");
                Find('<');
            end else
                Error(Text001);

            // check last period in fiscal year
            SetRange("New Fiscal Year");
            SetRange("Fiscally Closed");
            if Find('<') then
                if not "Fiscally Closed" then begin
                    FiscalYearEndDate := CalcDate('<-1D>', FiscalYearStartDate);
                    SetRange("New Fiscal Year", true);
                    SetRange("Fiscally Closed", true);
                    FindLast();
                    FiscalYearStartDate := "Starting Date"
                end else
                    Find('>');

            if not Closed then
                Error(Text008, FiscalYearStartDate, FiscalYearEndDate);

            CheckGeneralJournal();
            CheckClosingEntries();

            if not
               Confirm(
                 Text002 +
                 Text003 +
                 Text004, false,
                 FiscalYearStartDate, FiscalYearEndDate)
            then
                exit;

            Reset();

            SetRange("Starting Date", FiscalYearStartDate, FiscalYearEndDate);
            SetRange("Fiscally Closed", false);

            ModifyAll("Fiscal Closing Date", Today);
            ModifyAll("Fiscally Closed", true);

            // update allowed posting range
            UpdateGLSetup(FiscalYearEndDate);
            UpdateUserSetup(FiscalYearEndDate);

            Reset();
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckGeneralJournal()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            SetFilter("Posting Date", '%1..%2', FiscalYearStartDate, FiscalYearEndDate);
            if FindFirst() then
                Error(
                  Text006,
                  FiscalYearStartDate, FiscalYearEndDate,
                  FieldCaption("Journal Template Name"), "Journal Template Name",
                  FieldCaption("Journal Batch Name"), "Journal Batch Name",
                  FieldCaption("Line No."), "Line No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckClosingEntries()
    var
        GLAccount: Record "G/L Account";
    begin
        with GLAccount do begin
            SetRange("Date Filter", FiscalYearStartDate, ClosingDate(FiscalYearEndDate));
            SetRange("Income/Balance", "Income/Balance"::"Income Statement");
            if Find('-') then
                repeat
                    CalcFields("Net Change");
                    if "Net Change" <> 0 then
                        Error(Text007,
                          ClosingDate(FiscalYearEndDate),
                          FiscalYearStartDate, FiscalYearEndDate);
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckFiscalYearStatus(PeriodRange: Text[30]): Text[30]
    var
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", PeriodRange);
        Date.FindLast();
        AccountingPeriod.SetFilter("Starting Date", '<=%1', Date."Period Start");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        if AccountingPeriod."Fiscally Closed" then
            exit(Text009);

        exit(Text010);
    end;
}

