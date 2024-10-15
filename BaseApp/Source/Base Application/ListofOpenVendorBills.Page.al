page 12194 "List of Open Vendor Bills"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Bill Card';
    CardPageID = "Vendor Bill Card";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Bill Header";
    SourceTableView = WHERE("List Status" = CONST(Open));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
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
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Vendor Bill List No."; "Vendor Bill List No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor bill list identification number.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created .';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date you want the bill header to be posted.';
                }
                field("Beneficiary Value Date"; "Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency exchange factor based on the list date of the bank transfer.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for the vendor bill.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign the bill''s number.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
                }
                field("Bank Expense"; "Bank Expense")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any expenses or fees that are charged by the bank for the bank transfer.';
                }
                field("Report Header"; "Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Vendor Bill List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Bill List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor Bill Report";
                ToolTip = 'View the list of vendor bills.';
            }
        }
    }
}

