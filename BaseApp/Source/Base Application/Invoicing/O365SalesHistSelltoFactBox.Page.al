#if not CLEAN21
page 2193 "O365 Sales Hist.Sell-toFactBox"
{
    Caption = 'Customer Sales History';
    PageType = CardPart;
    SourceTable = Customer;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control23)
            {
                ShowCaption = false;
                Visible = false;
                field("No. of Invoices"; Rec."No. of Invoices")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Draft Invoices';
                    ToolTip = 'Specifies the number of draft invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    begin
                        DrillDownInvoices(false);
                    end;
                }
                field("No. of Pstd. Invoices"; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Sent Invoices';
                    ToolTip = 'Specifies the number of sent invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    begin
                        DrillDownInvoices(true);
                    end;
                }
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field(NoofInvoicesTile; "No. of Invoices")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Draft Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies the number of draft invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    begin
                        DrillDownInvoices(false);
                    end;
                }
                field(NoofPstdInvoicesTile; "No. of Pstd. Invoices")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Sent Invoices';
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies the number of sent invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    begin
                        DrillDownInvoices(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    local procedure DrillDownInvoices(Posted: Boolean)
    var
        O365SalesDocument: Record "O365 Sales Document";
        O365CustomerSalesDocuments: Page "O365 Customer Sales Documents";
    begin
        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
        O365SalesDocument.SetRange(Posted, Posted);

        Clear(O365CustomerSalesDocuments);
        O365CustomerSalesDocuments.SetTableView(O365SalesDocument);
        O365CustomerSalesDocuments.RunModal();
    end;
}
#endif
