#if not CLEAN20
page 10146 "Deposit List"
{
    Caption = 'Deposit List';
    Editable = false;
    PageType = List;
    SourceTable = "Deposit Header";
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            repeater(Control1020001)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the deposit.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the deposit.';
                }
                field("Total Deposit Amount"; "Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the deposit.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(Deposit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deposit';
                Image = Document;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page Deposit;
                ToolTip = 'Create a new deposit. ';
            }
        }
        area(reporting)
        {
            action("Deposit Test Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deposit Test Report';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Deposit Test Report";
                ToolTip = 'Verify the result of posting the deposit before you run the Deposit report.';
            }
        }
    }
}

#endif