page 11708 "Bank Statement Lines"
{
    Caption = 'Bank Statement Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Bank Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1220016)
            {
                ShowCaption = false;
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the bank statement line.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of partner (customer, vendor, bank account).';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the bank statement line contains.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the local currency for payment.';
                }
                field("Amount (Bank Stat. Currency)"; "Amount (Bank Stat. Currency)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in bank statement currencythat the bank statement line contains.';
                }
                field("Bank Statement Currency Code"; "Bank Statement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank statement currency code which is setup in the bank card.';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of advance letter line relations';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank statement.';
                    Visible = false;
                }
                field("Cust./Vendor Bank Account Code"; "Cust./Vendor Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code of the customer or vendor.';
                    Visible = false;
                }
                field("Bank Statement No."; "Bank Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of bank statement.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

