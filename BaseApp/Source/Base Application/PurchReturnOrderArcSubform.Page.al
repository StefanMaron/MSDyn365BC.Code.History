page 6645 "Purch Return Order Arc Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purchase Line Archive";
    SourceTableView = WHERE("Document Type" = CONST("Return Order"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Nonstock; Nonstock)
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies that this item is a catalog item.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies a description of the purchase return order. ';
                }
                field("Drop Shipment"; "Drop Shipment")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units are being returned.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; "Unit Price (LCY)")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; "Inv. Discount Amount")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;
                }
                field("Qty. to Receive"; "Qty. to Receive")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';
                }
                field("Quantity Received"; "Quantity Received")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as received.';
                }
                field("Qty. to Invoice"; "Qty. to Invoice")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = PurchReturnOrder;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Allow Item Charge Assignment"; "Allow Item Charge Assignment")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies that you can assign item charges to this line.';
                    Visible = false;
                }
                field("Requested Receipt Date"; "Requested Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the requested date of receipt for the purchase return order.';
                    Visible = false;
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                    Visible = false;
                }
                field("Planned Receipt Date"; "Planned Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date when the item is planned to arrive in inventory. Forward calculation: planned receipt date = order date + vendor lead time (per the vendor calendar and rounded to the next working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: planned receipt date = order date + vendor lead time (per the location calendar). Backward calculation: order date = planned receipt date - vendor lead time (per the vendor calendar and rounded to the previous working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: order date = planned receipt date - vendor lead time (per the location calendar).';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date on which the received items were expected.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                    Visible = false;
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Planning Flexibility"; "Planning Flexibility")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies whether the supply represented by this line is considered by the planning system when calculating action messages.';
                    Visible = false;
                }
                field("Prod. Order Line No."; "Prod. Order Line No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order line.';
                    Visible = false;
                }
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = false;
                }
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production operation.';
                    Visible = false;
                }
                field("Work Center No."; "Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center number of the journal line.';
                    Visible = false;
                }
                field(Finished; Finished)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that any related service or operation is finished.';
                    Visible = false;
                }
                field("Inbound Whse. Handling Time"; "Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';
                    Visible = false;
                }
                field("Blanket Order No."; "Blanket Order No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order that the record originates from.';
                    Visible = false;
                }
                field("Blanket Order Line No."; "Blanket Order Line No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
                field("Deferral Code"; "Deferral Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the deferral template that governs how expenses paid with this purchase document are deferred to the different accounting periods when the expenses were incurred.';
                }
                field("Returns Deferral Start Date"; "Returns Deferral Start Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the starting date of the returns deferral period.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        ShowLineComments;
                    end;
                }
                action("Document &Line Tracking")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        ShowDocumentLineTracking;
                    end;
                }
                action(DeferralSchedule)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Deferral Schedule';
                    Image = PaymentPeriod;
                    ToolTip = 'View the deferral schedule that governs how expenses paid with this purchase document were deferred to different accounting periods when the document was posted.';

                    trigger OnAction()
                    begin
                        ShowDeferrals;
                    end;
                }
            }
        }
    }

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTracking: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTracking);
        DocumentLineTracking.SetDoc(9, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.", '', 0);
        DocumentLineTracking.RunModal;
    end;
}

