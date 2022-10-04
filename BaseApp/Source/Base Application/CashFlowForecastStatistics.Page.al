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
                field(LiquidFunds; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Liquid Funds"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Liquid Funds';
                    ToolTip = 'Specifies amounts related to liquid funds.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Liquid Funds");
                    end;
                }
                field(Receivables; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Receivables))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies amounts related to receivables.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::Receivables);
                    end;
                }
                field(SalesOrders; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Sales Orders"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    ToolTip = 'Specifies amounts related to sales orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Sales Orders");
                    end;
                }
                field(ServiceOrders; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Service Orders"))
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    ToolTip = 'Specifies amounts related to service orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Service Orders");
                    end;
                }
                field(SalesofFixedAssets; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Disposal"))
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Disposal';
                    ToolTip = 'Specifies amounts related to fixed assets disposal.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Fixed Assets Disposal");
                    end;
                }
                field(ManualRevenues; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Revenue"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Revenues';
                    ToolTip = 'Specifies amounts related to cash flow manual revenues.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Cash Flow Manual Revenue");
                    end;
                }
                field(Payables; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Payables))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Payables';
                    ToolTip = 'Specifies amounts related to payables.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::Payables);
                    end;
                }
                field(PurchaseOrders; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Purchase Orders"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    ToolTip = 'Specifies amounts related to purchase orders.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Purchase Orders");
                    end;
                }
                field(BudgetedFixedAssets; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Budget"))
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Budget';
                    ToolTip = 'Specifies amounts related to fixed asset budgets.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Fixed Assets Budget");
                    end;
                }
                field(ManualExpenses; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Expense"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Expenses';
                    ToolTip = 'Specifies amounts related to cash flow manual expenses.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"Cash Flow Manual Expense");
                    end;
                }
                field(GLBudgets; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"G/L Budget"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Budgets';
                    ToolTip = 'Specifies amounts related to general ledger budgets.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::"G/L Budget");
                    end;
                }
                field(Job; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Job))
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job';
                    ToolTip = 'Specifies amounts related to jobs.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::Job);
                    end;
                }
                field(Tax; CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Tax))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax';
                    ToolTip = 'Specifies amounts related to taxes.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Source Type Filter"::Tax);
                    end;
                }
                field(Total; CalcSourceTypeAmount("Cash Flow Source Type"::" "))
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text1000, Format("Manual Payments To")));
                    Caption = 'Total';
                    ToolTip = 'Specifies total amounts.';

                    trigger OnDrillDown()
                    begin
                        DrillDownSourceTypeEntries("Cash Flow Source Type"::" ");
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
        if CurrentDate <> WorkDate() then
            CurrentDate := WorkDate();
        if "Manual Payments To" <> 0D then
            CurrentDate := "Manual Payments To";

        SetCashFlowDateFilter(0D, CurrentDate);
    end;

    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CurrentDate: Date;

        Text1000: Label 'Liquid Funds at %1';
}

