page 15000002 "Remittance Payment Order"
{
    Caption = 'Remittance Payment Order';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Remittance Payment Order";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ID; ID)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the internal ID of the payment order.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the payment order.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the payment order was submitted.';
                }
                field(Time; Time)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the time when the payment order was submitted.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies comments for the payment order.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a checkmark if the payment order has been canceled.';
                }
                field("Number Sent"; "Number Sent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Payment Order ID - Sent field, if the payment order has been submitted.';
                }
                field("Number Approved"; "Number Approved")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Payment Order ID - Approved field, if the payment order has been approved.';
                }
                field("Number Settled"; "Number Settled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Payment Order ID - Settled field, if the payment has been settled.';
                }
                field("Number Rejected"; "Number Rejected")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Payment Order ID - Rejected field, if the payment order has been rejected.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Payment order")
            {
                Caption = '&Payment order';
                action("Print status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print status';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'View the printing status.';

                    trigger OnAction()
                    begin
                        RemPaymOrder.SetRange(ID, ID);
                        RemPaymOrderStatus.SetTableView(RemPaymOrder);
                        RemPaymOrderStatus.Run();
                    end;
                }
                group(Export)
                {
                    Caption = 'Export';
                    Image = Export;
                    action("Waiting journal - sent")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Waiting journal - sent';
                        RunObject = Page "Waiting Journal";
                        RunPageLink = "Payment Order ID - Sent" = FIELD(ID);
                        RunPageView = SORTING("Payment Order ID - Sent");
                        ToolTip = 'View the electronic payment orders that have been submitted but not yet settled by the bank.';
                    }
                    action("Print payment overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print payment overview';
                        Ellipsis = true;
                        ToolTip = 'View or print the overview of payments.';

                        trigger OnAction()
                        begin
                            RemTools.PrintPaymentOverview(ID);
                        end;
                    }
                    separator(Action35)
                    {
                    }
                    action("Cancel payment order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cancel payment order';
                        Ellipsis = true;
                        ToolTip = 'Cancel the payment order. A payment order can be canceled if the payments are not received by the bank and a new remittance must be made. You can also cancel a payment order if you do not want to transfer the payments to the bank, for example if the payments are incorrect. Only open payment orders can be canceled.';

                        trigger OnAction()
                        begin
                            ResetRemPaymOrder.SetPaymOrder(Rec);
                            ResetRemPaymOrder.Run();
                            Clear(ResetRemPaymOrder);
                        end;
                    }
                    action(ExportPaymentFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export payment file';
                        Ellipsis = true;
                        ToolTip = 'Export the payment to a file for upload to the bank.';

                        trigger OnAction()
                        var
                            ExportManual: Report "Rem. paym. order - man. export";
                        begin
                            ExportManual.SetPaymOrder(Rec);
                            ExportManual.Run();
                        end;
                    }
                    action(Data)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data';
                        RunObject = Page "Payment Order Data";
                        RunPageLink = "Payment Order No." = FIELD(ID);
                        ShortCutKey = 'Ctrl+F12';
                        ToolTip = 'View the data that is submitted from the electronic payment order.';
                    }
                }
                group(Return)
                {
                    Caption = 'Return';
                    Image = Import;
                    action("Waiting journal approved")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Waiting journal approved';
                        RunObject = Page "Waiting Journal";
                        RunPageLink = "Payment Order ID - Approved" = FIELD(ID);
                        RunPageView = SORTING("Payment Order ID - Approved");
                        ToolTip = 'View submitted payment orders that have been approved.';
                    }
                    action("Waiting journal settled")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Waiting journal settled';
                        RunObject = Page "Waiting Journal";
                        RunPageLink = "Payment Order ID - Settled" = FIELD(ID);
                        RunPageView = SORTING("Payment Order ID - Settled");
                        ToolTip = 'View submitted payment orders that have been settled.';
                    }
                    action("Waiting journal - rejected")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Waiting journal - rejected';
                        RunObject = Page "Waiting Journal";
                        RunPageLink = "Payment Order ID - Rejected" = FIELD(ID);
                        RunPageView = SORTING("Payment Order ID - Rejected");
                        ToolTip = 'View submitted payment orders that have been rejected.';
                    }
                    action("Settlement status")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement status';
                        ToolTip = 'View when the payment order has been or will be settled.';

                        trigger OnAction()
                        begin
                            PaymentOrderSettlStatus.SetPaymOrder(Rec);
                            PaymentOrderSettlStatus.Run();
                        end;
                    }
                }
            }
        }
    }

    var
        RemPaymOrder: Record "Remittance Payment Order";
        RemPaymOrderStatus: Report "Rem. payment order status";
        ResetRemPaymOrder: Codeunit "Reset Remittance Payment Order";
        RemTools: Codeunit "Remittance Tools";
        PaymentOrderSettlStatus: Page "Payment Order - Settl. Status";
}

