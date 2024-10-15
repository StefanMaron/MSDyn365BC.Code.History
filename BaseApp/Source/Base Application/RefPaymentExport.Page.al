page 32000004 "Ref. Payment - Export"
{
    Caption = 'Ref. Payment - Export';
    DataCaptionFields = "Due Date";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Ref. Payment - Exported";
    SourceTableView = SORTING("Payment Date")
                      ORDER(Ascending);

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
                    ToolTip = 'Specifies the number of the reference payment.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a vendor number for the reference payment.';
                }
#if not CLEAN20
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the reference payment.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use "Description 2" instead';
                    ObsoleteTag = '20.0';
                }
#endif
                field(Description2; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the reference payment.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the purchase invoice.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment will be debited from the bank account.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the reference payment.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payable amount.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a currency code for the reference payment.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an applied-to identification code for the reference payment.';
                }
                field("Transfer Time"; "Transfer Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a transfer time if you have selected the Transferred field.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, in local currency, for the reference payment.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an external document number for the reference payment.';
                }
                field("Message Type"; "Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a message type.';
                }
                field("Invoice Message"; "Invoice Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an invoice message for the reference payment.';
                }
                field(Transferred; Transferred)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the reference payment is transferred.';
                }
                field("Transfer Date"; "Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a transfer date if you have selected the Transferred field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
    }

    var
        Navigate: Page Navigate;
}

