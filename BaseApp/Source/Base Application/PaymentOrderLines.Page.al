#if not CLEAN19
page 11718 "Payment Order Lines"
{
    Caption = 'Payment Order Lines (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Payment Order Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220019)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment order line.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of partner (customer, vendor, bank account).';
                    Visible = false;
                }
                field("Amount to Pay"; Rec."Amount to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount.';
                }
                field("Amount (LCY) to Pay"; Rec."Amount (LCY) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount in local currency.';
                }
                field("Amount(Pay.Order Curr.) to Pay"; Rec."Amount(Pay.Order Curr.) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount in payment order currency.';
                }
                field("Payment Order Currency Code"; Rec."Payment Order Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order currency code.';
                }
                field("Variable Symbol"; Rec."Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                }
                field("Constant Symbol"; Rec."Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Specific Symbol"; Rec."Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Transit No."; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of partner (customer, vendor, bank account, employee).';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of partner (customer, vendor, bank account, employee).';
                    Visible = false;
                }
                field("Cust./Vendor Bank Account Code"; Rec."Cust./Vendor Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code of the customer or vendor.';
                    Visible = false;
                }
                field("Payment Order No."; Rec."Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Payment Order.';
                }
            }
        }
    }

    actions
    {
    }
}
#endif