namespace Microsoft.Foundation.Period;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Inventory.Setup;

page 100 "Accounting Periods"
{
    AdditionalSearchTerms = 'fiscal year,fiscal period';
    ApplicationArea = Basic, Suite;
    Caption = 'Accounting Periods';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Accounting Period";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the accounting period will begin.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the accounting period.';
                }
                field("New Fiscal Year"; Rec."New Fiscal Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to use the accounting period to start a fiscal year.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the accounting period belongs to a closed fiscal year.';
                }
                field("Date Locked"; Rec."Date Locked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you can change the starting date for the accounting period.';
                }
                field("InvtPeriod.IsInvtPeriodClosed(""Starting Date"")"; InvtPeriod.IsInvtPeriodClosed(Rec."Starting Date"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Period Closed';
                    Editable = false;
                    ToolTip = 'Specifies that the inventory period has been closed.';
                }
                field("Average Cost Period"; Rec."Average Cost Period")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period type that was used in the accounting period to calculate the average cost.';
                    Visible = false;
                }
                field("Average Cost Calc. Type"; Rec."Average Cost Calc. Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the average cost for items in the accounting period was calculated.';
                    Visible = false;
                }
                field("Fiscally Closed"; Rec."Fiscally Closed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the accounting period belongs to a fiscally-closed year.';
                }
                field("Fiscal Closing Date"; Rec."Fiscal Closing Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date the accounting period has been fiscally closed.';
                    Visible = false;
                }
                field("Period Reopened Date"; Rec."Period Reopened Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date the accounting period has been reopened.';
                    Visible = false;
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
            group("F&iscal Closing")
            {
                Caption = 'F&iscal Closing';
                Image = Close;
                action("F&iscally Close Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'F&iscally Close Year';
                    Image = Closed;
                    RunObject = Codeunit "Fiscal Year-FiscalClose";
                    ToolTip = 'Close the accounting periods for the fiscal year.';
                }
                separator(Action1120008)
                {
                }
                action(CloseFiscalPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close Fiscal Period';
                    Image = ClosePeriod;
                    ToolTip = 'Close the selected fiscal period. After you close a fiscal period, you cannot post transactions to it.';

                    trigger OnAction()
                    begin
                        Rec.CloseFiscalPeriod();
                    end;
                }
                action(ReopenFiscalPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen Fiscal Period';
                    Image = ReOpen;
                    ToolTip = 'Open the fiscally closed accounting period to post general ledger entries. Requires that the fiscal year is still open.';

                    trigger OnAction()
                    begin
                        Rec.ReopenFiscalPeriod();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Inventory Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Inventory Period';
                Image = ShowInventoryPeriods;
                RunObject = Page "Inventory Periods";
                ToolTip = 'Create an inventory period. An inventory period defines a period of time in which you can post changes to the inventory value.';
            }
            action("&Create Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Create Year';
                Ellipsis = true;
                Image = CreateYear;
                RunObject = Report "Create Fiscal Year";
                ToolTip = 'Open a new fiscal year and define its accounting periods so you can start posting documents.';
            }
            action("C&lose Year")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'C&lose Year';
                Image = CloseYear;
                RunObject = Codeunit "Fiscal Year-Close";
                ToolTip = 'Close the current fiscal year. A confirmation message will display that tells you which year will be closed. You cannot reopen the year after it has been closed.';
            }
        }
        area(reporting)
        {
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'Show the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
            }
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'Show the chart of accounts with balances and net changes. You can use the report at the close of an accounting period or fiscal year.';
            }
            action("Fiscal Year Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Fiscal Year Balance';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Fiscal Year Balance";
                ToolTip = 'View balance sheet movements for a selected period. The report is useful at the close of an accounting period or fiscal year.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Inventory Period_Promoted"; "&Inventory Period")
                {
                }
                actionref("&Create Year_Promoted"; "&Create Year")
                {
                }
                actionref("C&lose Year_Promoted"; "C&lose Year")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Trial Balance by Period_Promoted"; "Trial Balance by Period")
                {
                }
            }
        }
    }

    var
        InvtPeriod: Record "Inventory Period";
}

