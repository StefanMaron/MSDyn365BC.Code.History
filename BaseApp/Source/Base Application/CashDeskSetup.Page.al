#if not CLEAN17
page 11746 "Cash Desk Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Desks Setup (Obsolete)';
    CardPageID = "Cash Desk Setup Card";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";
    SourceTableView = WHERE("Account Type" = CONST("Cash Desk"));
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the cash document.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of cash desk.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Cashier No."; "Cashier No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cashier number from employee list.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to block the cash desk by placing a check mark in the check box.';
                }
                field("Cash Document Receipt Nos."; "Cash Document Receipt Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt number series in cash document.';
                }
                field("Cash Document Withdrawal Nos."; "Cash Document Withdrawal Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withdrawal number series in cash document.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name for the cash desk.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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
            group("&Cash Desk")
            {
                Caption = '&Cash Desk';
                action("Cash Desk Users")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Desk Users';
                    Image = Users;
                    RunObject = Page "Cash Desk Users";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    ToolTip = 'Users authorized to issue or post cash documents for defined cash desk.';
                }
                action("Cash Desk Events")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Desk Events';
                    Image = "Event";
                    RunObject = Page "Cash Desk Events Setup";
                    RunPageLink = "Cash Desk No." = FIELD("No.");
                    ToolTip = 'Specifies the cash desk events. Allows to enter new events too.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Responsibility Hand Over")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Responsibility Hand Over';
                    Ellipsis = true;
                    Image = Responsibility;
                    ToolTip = 'Opens the cash desk hand overe page';

                    trigger OnAction()
                    var
                        HandOver: Report "Cash Desk Hand Over";
                    begin
                        HandOver.SetupCashDesk("No.");
                        HandOver.RunModal;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Account Type" := "Account Type"::"Cash Desk";
    end;
}
#endif