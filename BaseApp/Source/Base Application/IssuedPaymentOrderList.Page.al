page 11724 "Issued Payment Order List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Issued Payment Orders';
    CardPageID = "Issued Payment Order";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Issued Payment Order Header";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the payment order.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for payment order lines. The program calculates this amount from the sum of line amount fields on payment order lines.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the line consists of. The amount is in the local currency.';
                }
                field("No. of Lines"; "No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in the payment order.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies internally field.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Payment Order")
            {
                Caption = '&Payment Order';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Issued Payment Order Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected payment order.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Payment Order Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order Export';
                    Ellipsis = true;
                    Image = ExportToBank;
                    ToolTip = 'Open the report for expor payment order to the bank.';

                    trigger OnAction()
                    begin
                        ExportPmtOrd;
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("Payment Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order';
                    Ellipsis = true;
                    Image = BankAccountStatement;
                    ToolTip = 'Open the report for payment order.';

                    trigger OnAction()
                    begin
                        PrintPaymentOrder;
                    end;
                }
                action("Payment Order Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order Domestic';
                    Ellipsis = true;
                    Image = PurchaseTaxStatement;
                    ToolTip = 'Open the report for domestic payment order.';

                    trigger OnAction()
                    begin
                        PrintDomesticPaymentOrder;
                    end;
                }
                action("Payment Order International")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Order International';
                    Ellipsis = true;
                    Image = SalesTaxStatement;
                    ToolTip = 'Open the report for foreign payment order.';

                    trigger OnAction()
                    begin
                        PrintForeignPaymentOrder;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PaymentOrderMgt: Codeunit "Payment Order Management";
        StatSelected: Boolean;
    begin
        PaymentOrderMgt.IssuedPaymentOrderSelection(Rec, StatSelected);
        if not StatSelected then
            Error('');
    end;

    local procedure PrintPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter;
        IssuedPmtOrdHdr.PrintRecords(true);
    end;

    local procedure PrintDomesticPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter;
        IssuedPmtOrdHdr.PrintDomesticPmtOrd(true);
    end;

    local procedure PrintForeignPaymentOrder()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr := Rec;
        IssuedPmtOrdHdr.SetRecFilter;
        IssuedPmtOrdHdr.PrintForeignPmtOrd(true);
    end;
}

