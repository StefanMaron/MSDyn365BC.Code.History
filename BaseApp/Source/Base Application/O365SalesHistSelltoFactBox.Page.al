page 2193 "O365 Sales Hist.Sell-toFactBox"
{
    Caption = 'Customer Sales History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(Control23)
            {
                ShowCaption = false;
                Visible = RegularFastTabVisible;
                field("No. of Invoices"; "No. of Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Draft Invoices';
                    ToolTip = 'Specifies the number of draft invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    begin
                        DrillDownInvoices(false);
                    end;
                }
                field("No. of Pstd. Invoices"; "No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
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
                Visible = CuesVisible;
                field(NoofInvoicesTile; "No. of Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
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
                    ApplicationArea = Basic, Suite, Invoicing;
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

    trigger OnOpenPage()
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        RegularFastTabVisible := ClientTypeMgt.GetCurrentClientType = CLIENTTYPE::Windows;
        CuesVisible := (not RegularFastTabVisible) or OfficeManagement.IsAvailable;
    end;

    var
        ClientTypeMgt: Codeunit "Client Type Management";
        RegularFastTabVisible: Boolean;
        CuesVisible: Boolean;

    local procedure DrillDownInvoices(Posted: Boolean)
    var
        O365SalesDocument: Record "O365 Sales Document";
        O365CustomerSalesDocuments: Page "O365 Customer Sales Documents";
    begin
        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
        O365SalesDocument.SetRange(Posted, Posted);

        Clear(O365CustomerSalesDocuments);
        O365CustomerSalesDocuments.SetTableView(O365SalesDocument);
        O365CustomerSalesDocuments.RunModal;
    end;
}

