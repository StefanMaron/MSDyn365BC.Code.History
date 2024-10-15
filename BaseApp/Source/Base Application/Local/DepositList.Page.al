#pragma warning disable AS0074
#if not CLEAN21
page 10146 "Deposit List"
{
    Caption = 'Deposit List';
    Editable = false;
    PageType = List;
    SourceTable = "Deposit Header";
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#pragma warning restore AS0074
    layout
    {
        area(content)
        {
            repeater(Control1020001)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the deposit.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the deposit.';
                }
                field("Total Deposit Amount"; Rec."Total Deposit Amount")
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
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Deposit Test Report";
                ToolTip = 'Verify the result of posting the deposit before you run the Deposit report.';
            }
        }
        area(Promoted)
        {
        }
    }
}

#endif