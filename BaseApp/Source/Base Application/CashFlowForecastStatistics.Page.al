page 868 "Cash Flow Forecast Statistics"
{
    Caption = 'Cash Flow Forecast Statistics';
    Editable = false;
    PageType = Card;
    SourceTable = "Cash Flow Forecast";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LiquidFunds; Amounts[CFForecastEntry."Source Type"::"Liquid Funds"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Liquid Funds';
                    ToolTip = 'Specifies amounts related to liquid funds.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Liquid Funds");
                    end;
                }
                field(Receivables; Amounts[CFForecastEntry."Source Type"::Receivables])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies amounts related to receivables.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::Receivables);
                    end;
                }
                field(SalesOrders; Amounts[CFForecastEntry."Source Type"::"Sales Order"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    ToolTip = 'Specifies amounts related to sales orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Sales Order");
                    end;
                }
                field(ServiceOrders; Amounts[CFForecastEntry."Source Type"::"Service Orders"])
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    ToolTip = 'Specifies amounts related to service orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Service Orders");
                    end;
                }
                field(SalesofFixedAssets; Amounts[CFForecastEntry."Source Type"::"Fixed Assets Disposal"])
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Disposal';
                    ToolTip = 'Specifies amounts related to fixed assets disposal.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Fixed Assets Disposal");
                    end;
                }
                field(ManualRevenues; Amounts[CFForecastEntry."Source Type"::"Cash Flow Manual Revenue"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Revenues';
                    ToolTip = 'Specifies amounts related to cash flow manual revenues.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Cash Flow Manual Revenue");
                    end;
                }
                field(Payables; Amounts[CFForecastEntry."Source Type"::Payables])
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
                field(PurchaseOrders; Amounts[CFForecastEntry."Source Type"::"Purchase Order"])
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    ToolTip = 'Specifies amounts related to purchase orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Purchase Order");
                    end;
                }
                field(BudgetedFixedAssets; Amounts[CFForecastEntry."Source Type"::"Fixed Assets Budget"])
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Budget';
                    ToolTip = 'Specifies amounts related to fixed asset budgets.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Fixed Assets Budget");
                    end;
                }
                field(ManualExpenses; Amounts[CFForecastEntry."Source Type"::"Cash Flow Manual Expense"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Expenses';
                    ToolTip = 'Specifies amounts related to cash flow manual expenses.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Cash Flow Manual Expense");
                    end;
                }
                field(GLBudgets; Amounts[CFForecastEntry."Source Type"::"G/L Budget"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Budgets';
                    ToolTip = 'Specifies amounts related to general ledger budgets.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"G/L Budget");
                    end;
                }
                field(SalesAdvances; Amounts[CFForecastEntry."Source Type"::"Sales Advance Letters"])
                {
                    Caption = 'Sales Advances';
                    ToolTip = 'Specifies an amount of sales advances';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Sales Advance Letters"); // NAVCZ
                    end;
                }
                field(PurchaseAdvances; Amounts[CFForecastEntry."Source Type"::"Purchase Advance Letters"])
                {
                    Caption = 'Purchase Advances';
                    ToolTip = 'Specifies an amount of purchase advances';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Purchase Advance Letters"); // NAVCZ
                    end;
                }
                field(Job; Amounts[CFForecastEntry."Source Type"::Job])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job';
                    ToolTip = 'Specifies amounts related to jobs.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::Job);
                    end;
                }
                field(Tax; Amounts[CFForecastEntry."Source Type"::Tax])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax';
                    ToolTip = 'Specifies amounts related to taxes.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::Tax);
                    end;
                }
                field(Total; SumTotal)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text1000, Format("Manual Payments To")));
                    Caption = 'Total';
                    ToolTip = 'Specifies total amounts.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource(0);
                    end;
                }
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

        CalculateAllAmounts(0D, 0D, Amounts, SumTotal);
    end;

    var
        Text1000: Label 'Liquid Funds at %1';
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        SumTotal: Decimal;
        CurrentDate: Date;
        Amounts: array[15] of Decimal;
}

