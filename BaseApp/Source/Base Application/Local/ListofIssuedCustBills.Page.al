page 12182 "List of Issued Cust. Bills"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Issued Customer Bill Card';
    CardPageID = "Issued Customer Bill Card";
    Editable = false;
    PageType = List;
    SourceTable = "Issued Customer Bill Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the issued bill number.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the customer bills.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the customer bills that is entered in the Customer Card.';
                }
                field("List Date"; Rec."List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the issued customer bill list is created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the bill header was issued.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the bank receipt that is applied to the customer bill.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code from the transaction entry.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount due of the issued customer bills that have been sent to the bank.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Closing Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Closing Bank Receipts';
                Image = "Report";
                RunObject = Report "Closing Bank Receipts";
                ToolTip = 'View the related closing bank receipts.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Closing Bank Receipts_Promoted"; "Closing Bank Receipts")
                {
                }
            }
        }
    }
}

