page 840 "CF Forecast Statistics FactBox"
{
    Caption = 'Cash Flow Forecast Statistic';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Cash Flow Forecast";

    layout
    {
        area(content)
        {
            field(LiquidFunds; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Liquid Funds"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Liquid Funds';
                ToolTip = 'Specifies amounts related to liquid funds.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Liquid Funds");
                end;
            }
            field(Receivables; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::Receivables))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivables';
                ToolTip = 'Specifies amounts related to receivables.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::Receivables);
                end;
            }
            field(SalesOrders; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Sales Orders"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Orders';
                ToolTip = 'Specifies amounts related to sales orders.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Sales Orders");
                end;
            }
            field(ServiceOrders; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Service Orders"))
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                ToolTip = 'Specifies the amount of the service order to be received and paid out by your business for the cash flow forecast.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Service Orders");
                end;
            }
            field(SaleofFixedAssets; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Fixed Assets Disposal"))
            {
                ApplicationArea = Suite;
                Caption = 'Fixed Assets Disposal';
                ToolTip = 'Specifies amounts related to fixed assets disposal.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Fixed Assets Disposal");
                end;
            }
            field(ManualRevenues; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Revenue"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Manual Revenues';
                ToolTip = 'Specifies amounts related to cash flow manual revenues.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Cash Flow Manual Revenue");
                end;
            }
            field(Payables; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::Payables))
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Payables';
                ToolTip = 'Specifies amounts related to payables.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::Payables);
                end;
            }
            field(PurchaseOrders; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Purchase Orders"))
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Orders';
                ToolTip = 'Specifies the amount of the purchase order to be received and paid out by your business for the cash flow forecast.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Purchase Orders");
                end;
            }
            field(BudgetedFixedAssets; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Fixed Assets Budget"))
            {
                ApplicationArea = Suite;
                Caption = 'Fixed Assets Budget';
                ToolTip = 'Specifies amounts related to fixed asset budgets.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Fixed Assets Budget");
                end;
            }
            field(ManualExpenses; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Expense"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Manual Expenses';
                ToolTip = 'Specifies amounts related to cash flow manual expenses.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"Cash Flow Manual Expense");
                end;
            }
            field(GLBudgets; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::"G/L Budget"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Budgets';
                ToolTip = 'Specifies amounts related to G/L budgets.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::"G/L Budget");
                end;
            }
            field(Jobs; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::Job))
            {
                ApplicationArea = Jobs;
                Caption = 'Jobs';
                ToolTip = 'Specifies amounts related to jobs.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::Job);
                end;
            }
            field(Tax; CalcAmountFromSource(CashFlowForecastEntry."Source Type"::Tax))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tax';
                ToolTip = 'Specifies amounts related to tax.';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource("Source Type Filter"::Tax);
                end;
            }
            field(Total; CalcAmountFromSource(0))
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text1000, Format("Manual Payments To")));
                Caption = 'Total';
                ToolTip = 'Specifies the total value of cash flow forecast amounts';

                trigger OnDrillDown()
                begin
                    DrillDownEntriesFromSource(0);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate then
            CurrentDate := WorkDate;

        SetCashFlowDateFilter(0D, CurrentDate);
    end;

    var
        Text1000: Label 'Liquid Funds at %1';
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CurrentDate: Date;
}

