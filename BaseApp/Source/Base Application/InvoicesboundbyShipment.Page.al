page 10837 "Invoices bound by Shipment"
{
    Caption = 'Invoices bound by Shipment';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Shipment Invoiced";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Invoice No."; "Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice number bounded to the shipment.';
                }
                field("Qty. to Invoice"; "Qty. to Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of invoiced items that have been shipped.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Invoice';
                Image = SalesInvoice;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Posted Sales Invoice";
                RunPageLink = "No." = FIELD("Invoice No.");
                ToolTip = 'View a list of invoices for the items that were included in a shipment.';
            }
        }
    }
}

