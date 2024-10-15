page 10838 "Shipments bound by Invoice"
{
    Caption = 'Shipments bound by Invoice';
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
                field("Shipment No."; "Shipment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipment number bounded to the invoice.';
                }
                field("Qty. to Ship"; "Qty. to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of shipped items that have been invoiced.';
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
            action("&Shipment")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Shipment';
                Image = Shipment;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Posted Sales Shipment";
                RunPageLink = "No." = FIELD("Shipment No.");
                ToolTip = 'View details about the posted shipment related to the selected invoice.';
            }
        }
    }
}

