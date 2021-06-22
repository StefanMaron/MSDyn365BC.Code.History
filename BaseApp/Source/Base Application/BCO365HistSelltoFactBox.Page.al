page 2309 "BC O365 Hist. Sell-to FactBox"
{
    Caption = 'Sell-to Customer Sales History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = false;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field(NoofInvoicesTile; "No. of Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Draft Invoices';
                    ToolTip = 'Specifies the number of unposted sales invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange(Posted, false);
                        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
                        PAGE.Run(PAGE::"BC O365 Invoice List", O365SalesDocument);
                    end;
                }
                field(NoofQuotesTile; "No. of Quotes")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Estimates';
                    ToolTip = 'Specifies the number of sales quotes that have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange(Posted, false);
                        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
                        PAGE.Run(PAGE::"BC O365 Estimate List", O365SalesDocument);
                    end;
                }
                field(NoofPstdInvoicesTile; "No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Sent Invoices';
                    ToolTip = 'Specifies the number of posted sales invoices that have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        O365SalesDocument: Record "O365 Sales Document";
                    begin
                        O365SalesDocument.SetRange(Posted, true);
                        O365SalesDocument.SetRange("Sell-to Customer No.", "No.");
                        PAGE.Run(PAGE::"BC O365 Invoice List", O365SalesDocument);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"BC O365 Sales Customer Card", Rec);
    end;
}

