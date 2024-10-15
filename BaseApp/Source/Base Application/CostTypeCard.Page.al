page 1101 "Cost Type Card"
{
    Caption = 'Cost Type Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost type.';
                }
                field(Type; Type)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the type of the cost type.';
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
                }
                field("Combine Entries"; "Combine Entries")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the option to allow for general ledger entries to be posted individually or as a combined posting per day or month.';
                }
                field("G/L Account Range"; "G/L Account Range")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a general ledger account range to establish which general ledger account a cost type belongs to.';
                }
                field("Cost Center Code"; "Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; "Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Balance; Balance)
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the balance of the cost type.';
                }
                field("Balance to Allocate"; "Balance to Allocate")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the net amount that can still be allocated. The entry in the Allocated field in the Cost Entry table determines whether a cost entry is a part of this field.';
                }
                field("Cost Classification"; "Cost Classification")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost type by variability.';
                }
                field("Fixed Share"; "Fixed Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an explanation of the Cost Classification field.';
                }
                field("Blank Line"; "Blank Line")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether you want a blank line to appear immediately after this cost center when you print the chart of cost centers. The New Page, Blank Line, and Indentation fields define the layout of the chart of cost centers.';
                }
                field("New Page"; "New Page")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if you want a new page to start immediately after this cost center when you print the chart of cash flow accounts.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field("Modified Date"; "Modified Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies when the cost object was last modified.';
                }
                field("Modified By"; "Modified By")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the user who last modified the cost object.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Modified By");
                    end;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description that applies to the cost type.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control39; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control38; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cost Type")
            {
                Caption = '&Cost Type';
                Image = Costs;
                action("E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Type No." = FIELD("No.");
                    RunPageView = SORTING("Cost Type No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View cost entries related to the cost type.';
                }
                separator(Action4)
                {
                }
                action("&Balance")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Balance';
                    Image = Balance;
                    RunObject = Page "Cost Type Balance";
                    RunPageLink = "No." = FIELD("No."),
                                  "Cost Center Filter" = FIELD("Cost Center Filter"),
                                  "Cost Object Filter" = FIELD("Cost Object Filter");
                    ToolTip = 'View a summary of the balance at date or the net change for different time periods for the cost types that you select. You can select different time intervals and set filters on the cost centers and cost objects that you want to see.';
                }
            }
        }
        area(processing)
        {
            action("Cost Registers")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Registers';
                Image = GLRegisters;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Cost Registers";
                ToolTip = 'View all the transferred, posted, and allocated entries. A register is created every time that an entry is transferred, posted, or allocated.';
            }
            action("G/L Account")
            {
                ApplicationArea = CostAccounting;
                Caption = 'G/L Account';
                Image = JobPrice;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the G/L account for the select cost type.';
            }
        }
        area(reporting)
        {
            action("Cost Acctg. P/L Statement")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Statement";
                ToolTip = 'View the credit and debit balances per cost type, together with the chart of cost types.';
            }
            action("Cost Acctg. P/L Statement per Period")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement per Period';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Stmt. per Period";
                ToolTip = 'View profit and loss for cost types over two periods with the comparison as a percentage.';
            }
            action("Cost Acctg. P/L Statement with Budget")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement with Budget';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Statement/Budget";
                ToolTip = 'View a comparison of the balance to the budget figures and calculates the variance and the percent variance in the current accounting period, the accumulated accounting period, and the fiscal year.';
            }
            action("Cost Acctg. Analysis")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. Analysis';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Analysis";
                ToolTip = 'View balances per cost type with columns for seven fields for cost centers and cost objects. It is used as the cost distribution sheet in Cost accounting. The structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
            }
            action("Account Details")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Account Details';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Cost Types Details";
                ToolTip = 'View cost entries for each cost type. You can review the transactions for each cost type.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetRange("No.");
    end;
}

