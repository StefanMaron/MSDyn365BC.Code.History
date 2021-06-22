page 1120 "Cost Type Balance/Budget"
{
    Caption = 'Cost Type Balance/Budget';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(BudgetFilter; BudgetFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Budget Filter';
                    LookupPageID = "Cost Budget Names";
                    TableRelation = "Cost Budget Name".Name;
                    ToolTip = 'Specifies the budget for which you want to view budget amounts.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(CostCenterFilter; CostCenterFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Center Filter';
                    ToolTip = 'Specifies the cost center for which you want to view budget amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                    begin
                        exit(CostCenter.LookupCostCenterFilter(Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(CostObjectFilter; CostObjectFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Object Filter';
                    ToolTip = 'Specifies the cost object for which you want to view budget amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                    begin
                        exit(CostObject.LookupCostObjectFilter(Text));
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if (AmountType = AmountType::"Balance at Date") or (AmountType = AmountType::"Net Change") then
                            FindPeriod('');
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Date Filter';
                    Editable = false;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                }
            }
            repeater(Control12)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field(Number; "No.")
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the cost type.';
                }
                field("Net Change"; "Net Change")
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = CostAccounting;
                    BlankNumbers = BlankNegAndZero;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = CostAccounting;
                    BlankNumbers = BlankNegAndZero;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Budget Amount"; "Budget Amount")
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies either the cost type''s total budget or, if you have specified a filter in the Budget Filter field, a filtered budget. The contents of the field are calculated by using the entries in the Amount field in the Cost Budget Entry table.';

                    trigger OnValidate()
                    begin
                        CalcFormFields;
                    end;
                }
                field(BudgetPct; BudgetPct)
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    Caption = 'Balance/Budget (%)';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the balance as a percentage of the budgeted amount.';
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
        area(navigation)
        {
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Cost Type Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Cost Center Filter" = FIELD("Cost Center Filter"),
                                  "Cost Object Filter" = FIELD("Cost Object Filter"),
                                  "Budget Filter" = FIELD("Budget Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about cost type.';
                }
                action("Cost E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost E&ntries';
                    Image = CostEntries;
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Type No." = FIELD("No."),
                                  "Posting Date" = FIELD("Date Filter");
                    RunPageView = SORTING("Cost Type No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View cost entries, which can come from sources such as automatic transfer of general ledger entries to cost entries, manual posting for pure cost entries, internal charges, and manual allocations, and automatic allocation postings for actual costs.';
                }
            }
        }
        area(processing)
        {
            action(PreviousPeriod)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Next Period';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Budget")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Copy Budget';
                    Ellipsis = true;
                    Image = CopyBudget;
                    RunObject = Report "Copy G/L Budget";
                    ToolTip = 'Create a copy of the current budget.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        CalcFormFields;
        NameIndent := Indentation;
        Emphasize := Type <> Type::"Cost Type";
    end;

    trigger OnOpenPage()
    begin
        BudgetFilter := GetFilter("Budget Filter");
        FindPeriod('');
    end;

    var
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        BudgetPct: Decimal;
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;
        BudgetFilter: Code[10];
        CostCenterFilter: Text[1024];
        CostObjectFilter: Text[1024];
        DateFilter: Text;

    local procedure FindPeriod(SearchText: Code[3])
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then
            if Calendar."Period Start" = Calendar."Period End" then
                SetRange("Date Filter", Calendar."Period Start")
            else
                SetRange("Date Filter", Calendar."Period Start", Calendar."Period End")
        else
            SetRange("Date Filter", 0D, Calendar."Period End");
        DateFilter := GetFilter("Date Filter");
        CurrPage.Update(false);
    end;

    local procedure CalcFormFields()
    begin
        SetFilter("Budget Filter", BudgetFilter);
        SetFilter("Cost Center Filter", CostCenterFilter);
        SetFilter("Cost Object Filter", CostObjectFilter);

        CalcFields("Net Change", "Budget Amount");
        if "Budget Amount" = 0 then
            BudgetPct := 0
        else
            BudgetPct := Round("Net Change" / "Budget Amount" * 100);
    end;
}

