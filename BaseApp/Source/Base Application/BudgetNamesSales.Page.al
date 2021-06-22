page 9374 "Budget Names Sales"
{
    ApplicationArea = SalesBudget;
    Caption = 'Sales Budgets';
    PageType = List;
    SourceTable = "Item Budget Name";
    SourceTableView = WHERE("Analysis Area" = CONST(Sales));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies the name of the item budget.';
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies a description of the item budget.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Budget Dimension 1 Code"; "Budget Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a dimension code for Item Budget Dimension 1.';
                }
                field("Budget Dimension 2 Code"; "Budget Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a dimension code for Item Budget Dimension 2.';
                }
                field("Budget Dimension 3 Code"; "Budget Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a dimension code for Item Budget Dimension 3.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditBudget)
            {
                ApplicationArea = SalesBudget;
                Caption = 'Edit Budget';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Specify budgets that you can create in the general ledger application area. If you need several different budgets, you can create several budget names.';

                trigger OnAction()
                var
                    SalesBudgetOverview: Page "Sales Budget Overview";
                begin
                    SalesBudgetOverview.SetNewBudgetName(Name);
                    SalesBudgetOverview.Run;
                end;
            }
        }
    }
}

