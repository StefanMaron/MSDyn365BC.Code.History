page 6624 "Blanket Purch. Order Arch.Sub."
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purchase Line Archive";
    SourceTableView = WHERE("Document Type" = CONST("Blanket Order"));

    layout
    {
        area(content)
        {
            repeater(Control47)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the archived purchase order.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the item on the sales line is a catalog item, which means it is not normally kept in inventory.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Drop Shipment"; "Drop Shipment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center that is associated with the user, company, or vendor.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; "Unit Price (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the price for one unit of the item, in LCY.';
                    Visible = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if invoice discounts can be calculated on the archived order.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; "Inv. Discount Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the invoice discount amount for the line.';
                    Visible = false;
                }
                field("Qty. to Receive"; "Qty. to Receive")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';
                }
                field("Quantity Received"; "Quantity Received")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as received.';
                }
                field("Qty. to Invoice"; "Qty. to Invoice")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Allow Item Charge Assignment"; "Allow Item Charge Assignment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if item charges can be assigned to the archived order.';
                    Visible = false;
                }
                field("Requested Receipt Date"; "Requested Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date that you want the vendor to deliver your order. The field is used to calculate the latest date you can order, as follows: requested receipt date - lead time calculation = order date. If you do not need delivery on a specific date, you can leave the field blank.';
                    Visible = false;
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                    Visible = false;
                }
                field("Planned Receipt Date"; "Planned Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the item is planned to arrive in inventory. Forward calculation: planned receipt date = order date + vendor lead time (per the vendor calendar and rounded to the next working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: planned receipt date = order date + vendor lead time (per the location calendar). Backward calculation: order date = planned receipt date - vendor lead time (per the vendor calendar and rounded to the previous working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: order date = planned receipt date - vendor lead time (per the location calendar).';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Manufacturing;
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
                    ToolTip = 'Specifies the number of a related work center, for example for subcontracted production.';
                    Visible = false;
                }
                field(Finished; Finished)
                {
                    ApplicationArea = Manufacturing;
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the blanket order. ';
                    Visible = false;
                }
                field("Blanket Order Line No."; "Blanket Order Line No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the blanket order line. ';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied -to.';
                    Visible = false;
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
                action("Co&mments")
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
                action(DocumentLineTracking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Document &Line Tracking';
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        ShowDocumentLineTracking;
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
        DocumentLineTracking.SetDoc(3, "Document No.", "Line No.", "Blanket Order No.", "Blanket Order Line No.", '', 0);
        DocumentLineTracking.RunModal;
    end;
}

