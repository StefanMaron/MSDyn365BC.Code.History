#if not CLEAN21
codeunit 2100 "O365 Sales Statistics"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        OutsideFYErr: Label 'The date is outside of the current accounting period.';

    procedure GenerateMonthlyOverview(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        O365SalesCue: Record "O365 Sales Cue";
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        AutoFormat: Codeunit "Auto Format";
        Month: Integer;
        TotalMonthsInCurrentFY: Integer;
        AutoFormatType: Enum "Auto Format";
    begin
        GLSetup.Get();
        GetCurrentAccountingPeriod(AccountingPeriod);

        TotalMonthsInCurrentFY := GetNumberOfElapsedMonthsInFYByDate(WorkDate(), AccountingPeriod);

        for Month := 1 to TotalMonthsInCurrentFY do begin
            // Get transactions for the month
            O365SalesCue.SetFilter("CM Date Filter", '%1..%2',
              CalcDate(StrSubstNo('<%1M>', Month - 1), AccountingPeriod."Starting Date"),
              CalcDate(StrSubstNo('<%1M-1D>', Month), AccountingPeriod."Starting Date"));
            O365SalesCue.CalcFields("Invoiced CM");

            // Insert aggregate data
            TempNameValueBuffer.Init();
            TempNameValueBuffer.ID := Month;
            TempNameValueBuffer.Name := Format(CalcDate(StrSubstNo('<%1M>', Month - 1), AccountingPeriod."Starting Date"), 0, '<Month Text>');
            TempNameValueBuffer.Value := GLSetup.GetCurrencySymbol() + ' ' +
              Format(O365SalesCue."Invoiced CM", 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, GLSetup.GetCurrencyCode('')));
            TempNameValueBuffer.Insert();
        end;
    end;

    procedure GenerateWeeklyOverview(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Month: Integer)
    var
        O365SalesCue: Record "O365 Sales Cue";
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        EndDate: Date;
        CurrentMonth: Integer;
        CurrentWeek: Integer;
        MonthOfStartingFY: Integer;
    begin
        GLSetup.Get();
        GetCurrentAccountingPeriod(AccountingPeriod);
        CurrentWeek := 0;

        Evaluate(MonthOfStartingFY, Format(AccountingPeriod."Starting Date", 0, '<Month>'));
        Month := GetNumberOfElapsedMonthsInFY(Month, AccountingPeriod) - 2;

        repeat
            // Ensure the end date is still within the current month
            EndDate := CalcDate(StrSubstNo('<%1M+%2W>', Month, CurrentWeek + 1), CalcDate('<CM>', AccountingPeriod."Starting Date"));
            if EndDate > CalcDate(StrSubstNo('<%1M>', Month + 1), CalcDate('<CM>', AccountingPeriod."Starting Date")) then
                EndDate := CalcDate(StrSubstNo('<%1M>', Month + 1), CalcDate('<CM>', AccountingPeriod."Starting Date"));

            O365SalesCue.SetFilter("CM Date Filter", '%1..%2',
              CalcDate(StrSubstNo('<%1M+%2W+1D>', Month, CurrentWeek), CalcDate('<CM>', AccountingPeriod."Starting Date")),
              EndDate);
            O365SalesCue.CalcFields("Invoiced CM");

            TempNameValueBuffer.Init();
            TempNameValueBuffer.ID := CurrentWeek;
            TempNameValueBuffer.Name :=
              Format(CalcDate(StrSubstNo('<%1M+%2W+1D>', Month, CurrentWeek), CalcDate('<CM>', AccountingPeriod."Starting Date")));
            TempNameValueBuffer.Value := GLSetup.GetCurrencySymbol() + ' ' + Format(O365SalesCue."Invoiced CM");
            TempNameValueBuffer.Insert();

            // Ensure next week is still the same month
            CurrentWeek += 1;
            Evaluate(
              CurrentMonth,
              Format(CalcDate(StrSubstNo('<%1M+%2W+1D>', Month, CurrentWeek), CalcDate('<CM>', AccountingPeriod."Starting Date")), 0, '<Month>'));
            CurrentMonth -= MonthOfStartingFY;
        until CurrentMonth <> Month + 1;
    end;

    [Scope('OnPrem')]
    procedure GenerateChart(Chart: DotNet BusinessChartAddIn; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; XCaption: Text; YCaption: Text)
    var
        TempBusinessChartBuffer: Record "Business Chart Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        Amount: Decimal;
        I: Integer;
    begin
        GLSetup.Get();

        TempBusinessChartBuffer.Initialize();
        TempBusinessChartBuffer.SetXAxis(XCaption, TempBusinessChartBuffer."Data Type"::String);
        TempBusinessChartBuffer.AddDecimalMeasure(YCaption, 1, TempBusinessChartBuffer."Chart Type"::Column);

        TempNameValueBuffer.FindSet();
        for I := 0 to TempNameValueBuffer.Count - 1 do begin
            TempBusinessChartBuffer.AddColumn(TempNameValueBuffer.Name);
            Evaluate(Amount, CopyStr(TempNameValueBuffer.Value, StrLen(GLSetup.GetCurrencySymbol()) + 1));
            TempBusinessChartBuffer.SetValueByIndex(0, I, Amount);
            TempNameValueBuffer.Next();
        end;

        TempBusinessChartBuffer.Update(Chart);
    end;

    procedure GenerateMonthlyCustomers(Month: Integer; var ResultingCustomer: Record Customer): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        GetCurrentAccountingPeriod(AccountingPeriod);

        Month := GetNumberOfElapsedMonthsInFY(Month, AccountingPeriod) - 1;
        SalesInvoiceEntityAggregate.SetFilter(Status, '%1|%2|%3',
          SalesInvoiceEntityAggregate.Status::Open,
          SalesInvoiceEntityAggregate.Status::Paid,
          SalesInvoiceEntityAggregate.Status::"In Review");
        SalesInvoiceEntityAggregate.SetRange(Posted, true);
        SalesInvoiceEntityAggregate.SetRange("Document Date",
          CalcDate(StrSubstNo('<%1M+1D>', Month - 1), CalcDate('<CM>', AccountingPeriod."Starting Date")),
          CalcDate(StrSubstNo('<%1M>', Month), CalcDate('<CM>', AccountingPeriod."Starting Date")));

        exit(GetCustomersFromSalesInvoiceEntityAggregates(SalesInvoiceEntityAggregate, ResultingCustomer));
    end;

    procedure GetCurrentAccountingPeriod(var AccountingPeriod: Record "Accounting Period")
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if IsEmptyAccountingPeriod() then begin
            AccountingPeriod.Reset();
            AccountingPeriodMgt.InitStartYearAccountingPeriod(AccountingPeriod, WorkDate());
            exit;
        end;

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '..%1', WorkDate());

        if not AccountingPeriod.FindLast() then begin
            AccountingPeriod.SetRange("New Fiscal Year");
            if AccountingPeriod.FindFirst() then;
        end;
    end;

    local procedure GetNumberOfElapsedMonthsInFYByDate(Date: Date; AccountingPeriod: Record "Accounting Period"): Integer
    var
        Month: Integer;
    begin
        if AccountingPeriod."Starting Date" = 0D then
            Error(OutsideFYErr);

        if (Date >= CalcDate('<1Y>', AccountingPeriod."Starting Date")) or
           (Date < AccountingPeriod."Starting Date")
        then
            Error(OutsideFYErr);

        Evaluate(Month, Format(Date, 0, '<Month>'));
        exit(GetNumberOfElapsedMonthsInFY(Month, AccountingPeriod));
    end;

    local procedure GetNumberOfElapsedMonthsInFY(Month: Integer; AccountingPeriod: Record "Accounting Period"): Integer
    var
        MonthOfStartingFY: Integer;
        Result: Integer;
    begin
        Result := Month;
        Evaluate(MonthOfStartingFY, Format(AccountingPeriod."Starting Date", 0, '<Month>'));

        // Ensure that the month is after the starting month of the FY
        if Result < MonthOfStartingFY then
            Result += 12;

        // Find the difference
        Result -= MonthOfStartingFY - 1;

        exit(Result);
    end;

    procedure GetCustomersFromSalesInvoiceEntityAggregates(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate"; var ResultingCustomer: Record Customer): Boolean
    begin
        if SalesInvoiceEntityAggregate.IsEmpty() then
            exit(false);

        SalesInvoiceEntityAggregate.SetFilter("Sell-to Customer No.", '<>''''');
        if not SalesInvoiceEntityAggregate.FindSet() then
            exit(false);

        repeat
            if ResultingCustomer.Get(SalesInvoiceEntityAggregate."Sell-to Customer No.") then
                ResultingCustomer.Mark(true);
        until SalesInvoiceEntityAggregate.Next() = 0;

        exit(ResultingCustomer.MarkedOnly(true));
    end;

    procedure GetRelativeMonthToFY(): Integer
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        GetCurrentAccountingPeriod(AccountingPeriod);
        exit(GetNumberOfElapsedMonthsInFYByDate(WorkDate(), AccountingPeriod));
    end;

    local procedure IsEmptyAccountingPeriod(): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        exit(AccountingPeriod.IsEmpty);
    end;
}
#endif

