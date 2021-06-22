page 167 "Item Ledger Entries Preview"
{
    Caption = 'Item Ledger Entries Preview';
    DataCaptionFields = "Item No.";
    Editable = false;
    PageType = List;
    SourceTable = "Item Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction the entry is created from.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Document Line No."; "Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line on the posted document that corresponds to the item ledger entry.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item in the entry.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the last date that the item on the line can be used.';
                    Visible = false;
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field("Invoiced Quantity"; "Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been invoiced.';
                    Visible = true;
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                    Visible = true;
                }
                field("Shipped Qty. Not Returned"; "Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this item ledger entry that was shipped and has not yet been returned.';
                    Visible = false;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity per item unit of measure.';
                    Visible = false;
                }
                field(SalesAmountExpected; SalesAmountExpected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Amount (Expected)';
                    ToolTip = 'Specifies the expected sales amount in LCY. Choose the field to see the value entries that make up this amount.';
                    Visible = false;
                }
                field(SalesAmountActual; SalesAmountActual)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Amount (Actual)';
                    ToolTip = 'Specifies the sum of the actual sales amounts if you post.';
                }
                field(CostAmountExpected; CostAmountExpected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Amount (Expected)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field(CostAmountActual; CostAmountActual)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Amount (Actual)';
                    ToolTip = 'Specifies the sum of the actual cost amounts if you post.';
                }
                field(CostAmountNonInvtbl; CostAmountNonInvtbl)
                {
                    ApplicationArea = ItemCharges;
                    Caption = 'Cost Amount (Non-Invtbl.)';
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts if you post. Typical non-inventoriable costs come from item charges.';
                }
                field(CostAmountExpectedACY; CostAmountExpectedACY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Amount (Expected) (ACY)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field(CostAmountActualACY; CostAmountActualACY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Amount (Actual) (ACY)';
                    ToolTip = 'Specifies the actual cost amount of the item.';
                    Visible = false;
                }
                field(CostAmountNonInvtblACY; CostAmountNonInvtblACY)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cost Amount (Non-Invtbl.) (ACY)';
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts if you post. Typical non-inventoriable costs come from item charges.';
                    Visible = false;
                }
                field("Completely Invoiced"; "Completely Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully invoiced or if more posted invoices are expected. Only completely invoiced entries can be revalued.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully applied to.';
                }
                field("Drop Shipment"; "Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
                    Visible = false;
                }
                field("Assemble to Order"; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the posting represents an assemble-to-order sale.';
                    Visible = false;
                }
                field("Applied Entry to Adjust"; "Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether there is one or more applied entries, which need to be adjusted.';
                    Visible = false;
                }
                field("Order Type"; "Order Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction the entry is created from.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                    Visible = false;
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number of the order that created the entry.';
                    Visible = false;
                }
                field("Prod. Order Comp. Line No."; "Prod. Order Comp. Line No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the line number of the production order component.';
                    Visible = false;
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
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
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Show Applied Entries", Rec);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        ShowReservationEntries(true);
                    end;
                }
                action("Application Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Application Worksheet';
                    Image = ApplicationWorksheet;
                    ToolTip = 'View item applications that are automatically created between item ledger entries during item transactions.';

                    trigger OnAction()
                    var
                        ApplicationWorksheet: Page "Application Worksheet";
                    begin
                        Clear(ApplicationWorksheet);
                        ApplicationWorksheet.SetRecordToShow(Rec);
                        ApplicationWorksheet.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Order &Tracking")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        OrderTrackingForm: Page "Order Tracking";
                    begin
                        OrderTrackingForm.SetItemLedgEntry(Rec);
                        OrderTrackingForm.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcAmounts;
    end;

    var
        TempValueEntry: Record "Value Entry" temporary;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        SalesAmountExpected: Decimal;
        SalesAmountActual: Decimal;
        CostAmountExpected: Decimal;
        CostAmountActual: Decimal;
        CostAmountNonInvtbl: Decimal;
        CostAmountExpectedACY: Decimal;
        CostAmountActualACY: Decimal;
        CostAmountNonInvtblACY: Decimal;

    procedure Set(var TempItemLedgerEntry2: Record "Item Ledger Entry" temporary; var TempValueEntry2: Record "Value Entry" temporary)
    begin
        if TempItemLedgerEntry2.FindSet then
            repeat
                Rec := TempItemLedgerEntry2;
                Insert;
            until TempItemLedgerEntry2.Next = 0;

        if TempValueEntry2.FindSet then
            repeat
                TempValueEntry := TempValueEntry2;
                TempValueEntry.Insert();
            until TempValueEntry2.Next = 0;
    end;

    local procedure CalcAmounts()
    begin
        SalesAmountExpected := 0;
        SalesAmountActual := 0;
        CostAmountExpected := 0;
        CostAmountActual := 0;
        CostAmountNonInvtbl := 0;
        CostAmountExpectedACY := 0;
        CostAmountActualACY := 0;
        CostAmountNonInvtblACY := 0;

        TempValueEntry.SetFilter("Item Ledger Entry No.", '%1', "Entry No.");
        if TempValueEntry.FindSet then
            repeat
                SalesAmountExpected += TempValueEntry."Sales Amount (Expected)";
                SalesAmountActual += TempValueEntry."Sales Amount (Actual)";
                CostAmountExpected += TempValueEntry."Cost Amount (Expected)";
                CostAmountActual += TempValueEntry."Cost Amount (Actual)";
                CostAmountNonInvtbl += TempValueEntry."Cost Amount (Non-Invtbl.)";
                CostAmountExpectedACY += TempValueEntry."Cost Amount (Expected) (ACY)";
                CostAmountActualACY += TempValueEntry."Cost Amount (Actual) (ACY)";
                CostAmountNonInvtblACY += TempValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
            until TempValueEntry.Next = 0;
    end;
}

