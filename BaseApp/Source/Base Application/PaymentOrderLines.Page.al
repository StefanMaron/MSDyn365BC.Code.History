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
                field("Account No."; "Account No.")
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
                field("Amount to Pay"; "Amount to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount.';
                }
                field("Amount (LCY) to Pay"; "Amount (LCY) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount in local currency.';
                }
                field("Amount(Pay.Order Curr.) to Pay"; "Amount(Pay.Order Curr.) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment order amount in payment order currency.';
                }
                field("Payment Order Currency Code"; "Payment Order Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order currency code.';
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
                    ToolTip = 'Specifies the type of partner (customer, vendor, bank account, employee).';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of partner (customer, vendor, bank account, employee).';
                    Visible = false;
                }
                field("Cust./Vendor Bank Account Code"; "Cust./Vendor Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code of the customer or vendor.';
                    Visible = false;
#if not CLEAN17

                    trigger OnValidate()
                    begin
                        CalcFields("Third Party Bank Account");
                        if Type <> Type::Vendor then
                            Clear("Third Party Bank Account");
                    end;
#endif
                }
                field("Payment Order No."; "Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Payment Order.';
                }
#if not CLEAN17
                field("VAT Uncertainty Payer"; "VAT Uncertainty Payer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor is uncertainty payer.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.5';
                    Visible = false;
                }
                field("Public Bank Account"; "Public Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the bank account is public.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.5';
                    Visible = false;
                }
                field("Third Party Bank Account"; "Third Party Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the account is third party bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.5';
                    Visible = false;
                }
#endif
            }
        }
    }

    actions
    {
    }
#if not CLEAN17

    trigger OnAfterGetRecord()
    begin
        if Type <> Type::Vendor then
            Clear("Third Party Bank Account");
    end;
#endif
}
#endif
