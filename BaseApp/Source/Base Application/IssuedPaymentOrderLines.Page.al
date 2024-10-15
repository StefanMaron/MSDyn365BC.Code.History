#if not CLEAN19
page 11723 "Issued Payment Order Lines"
{
    Caption = 'Issued Payment Order Lines (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Issued Payment Order Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220018)
            {
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of issued payment order lines';
                    Visible = false;
                }
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
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Amount on Issued Payment Order Line.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the local currency for payment.';
                    Visible = false;
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
                }
                field("Payment Order No."; "Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Issued Payment Order. The field is either filled automatically from a defined number series.';
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action(Cancel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel';
                    ToolTip = 'This function deletes the payment order line.';
                    Image = CancelLine;

                    trigger OnAction()
                    begin
                        LineCancel();
                    end;
                }
                action(ShowDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        IssuedPaymentOrderHeader: Record "Issued Payment Order Header";
                    begin
                        IssuedPaymentOrderHeader."No." := "Payment Order No.";
                        Page.Run(Page::"Issued Payment Order", IssuedPaymentOrderHeader);
                    end;
                }
            }
        }
    }
}
#endif
