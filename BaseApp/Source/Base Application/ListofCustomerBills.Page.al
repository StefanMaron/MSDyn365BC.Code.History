page 12178 "List of Customer Bills"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Bill Card';
    CardPageID = "Customer Bill Card";
    Editable = false;
    PageType = List;
    SourceTable = "Customer Bill Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the bill header you are setting up.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the bank that is managing the customer bills.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the customer bills that is entered in the Customer Card.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date you want the bill header to be issued.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the bank receipt that is applied to the customer bill.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code from the transaction entry.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("List of Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List of Bank Receipts';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "List of Bank Receipts";
                ToolTip = 'View the related list of bank receipts.';
            }
        }
    }
}

