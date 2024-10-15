page 10027 "Sales Order Shipment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Line";
    SourceTableView = WHERE("Document Type" = FILTER(Order),
                            "Outstanding Quantity" = FILTER(<> 0));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    Editable = false;
                    ToolTip = 'Specifies the type of the record on the document line. ';
                }
                field("No."; "No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate;
                    end;
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the cross-reference number of the item specified on the line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        // Item Cross Ref - start
                        if Type = Type::Item then begin
                            SalesHeader.Get("Document Type", "Document No.");
                            ItemCrossReference.Reset();
                            ItemCrossReference.SetCurrentKey("Cross-Reference Type", "Cross-Reference Type No.");
                            ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Customer);
                            ItemCrossReference.SetRange("Cross-Reference Type No.", SalesHeader."Sell-to Customer No.");
                            if PAGE.RunModal(PAGE::"Cross Reference List", ItemCrossReference) = ACTION::LookupOK then begin
                                Validate("Cross-Reference No.", ItemCrossReference."Cross-Reference No.");
                                InsertExtendedText(false);
                            end;
                        end;
                        // Item Cross Ref - end
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    Editable = "Variant CodeEditable";
                    ToolTip = 'Specifies the variant number of the items sold.';
                    Visible = false;
                }
                field("Substitution Available"; "Substitution Available")
                {
                    Editable = false;
                    ToolTip = 'Specifies that a substitute is available for the item on the sales line.';
                    Visible = false;
                }
                field("Purchasing Code"; "Purchasing Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies a purchasing code that indicates actions that need to be taken to purchase this item. ';
                    Visible = false;
                }
                field(Nonstock; Nonstock)
                {
                    Editable = false;
                    ToolTip = 'Specifies that the item on the sales line is a catalog item (an item not normally kept in inventory).';
                    Visible = false;
                }
                field(Description; Description)
                {
                    Editable = false;
                    ToolTip = 'Specifies a description of the shipment line.';
                }
                field(Control26; "Drop Shipment")
                {
                    Editable = false;
                    ToolTip = 'Specifies whether to ship the items on the line directly to your customer.';
                    Visible = false;
                }
                field(Control106; "Special Order")
                {
                    Editable = false;
                    ToolTip = 'Specifies that the item on the sales line is a special-order item.';
                    Visible = false;
                }
                field("Package Tracking No."; "Package Tracking No.")
                {
                    Editable = "Package Tracking No.Editable";
                    ToolTip = 'Specifies the shipping agent''s package number.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the location from where inventory items are to be shipped by default, to the customer on the sales document.';
                }
                field("Bin Code"; "Bin Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the bin from where items on the sales order line are taken from when they are shipped.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items on document line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate;
                    end;
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many of the units in the Quantity field are reserved.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the item''s unit of measure. ';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValida;
                    end;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    Editable = false;
                    ToolTip = 'Specifies the item''s unit of measure. ';
                    Visible = false;
                }
                field("Qty. to Ship"; "Qty. to Ship")
                {
                    BlankZero = true;
                    Editable = "Qty. to ShipEditable";
                    ToolTip = 'Specifies how many of the units in the Quantity field to post as shipped. ';
                }
                field("Quantity Shipped"; "Quantity Shipped")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies how many of the units in the Quantity field have been posted as shipped.';
                }
                field("Allow Item Charge Assignment"; "Allow Item Charge Assignment")
                {
                    Editable = AllowItemChargeAssignmentEdita;
                    ToolTip = 'Specifies that you can assign item charges to this line.';
                    Visible = false;
                }
                field("Qty. to Assign"; "Qty. to Assign")
                {
                    ToolTip = 'Specifies how many of the units in the Quantity field to assign.';
                    Visible = false;
                }
                field("Qty. Assigned"; "Qty. Assigned")
                {
                    ToolTip = 'Specifies how many of the units in the Quantity field have been assigned.';
                    Visible = false;
                }
                field("Requested Delivery Date"; "Requested Delivery Date")
                {
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date for the sales order shipment.';
                    Visible = false;
                }
                field("Promised Delivery Date"; "Promised Delivery Date")
                {
                    Editable = "Promised Delivery DateEditable";
                    ToolTip = 'Specifies the promised delivery date for the sales order shipment.';
                    Visible = false;
                }
                field("Planned Delivery Date"; "Planned Delivery Date")
                {
                    Editable = "Planned Delivery DateEditable";
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address.';
                }
                field("Planned Shipment Date"; "Planned Shipment Date")
                {
                    Editable = "Planned Shipment DateEditable";
                    ToolTip = 'Specifies the date that the shipment should ship from the warehouse.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    Editable = "Shipment DateEditable";
                    ToolTip = 'Specifies the date that the items on the line are in inventory and available to be picked. The shipment date is the date you expect to ship the items on the line.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    Editable = "Shipping Agent CodeEditable";
                    ToolTip = 'Specifies which shipping company will be used when you ship items to the customer.';
                    Visible = false;
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    Editable = ShippingAgentServiceCodeEditab;
                    ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                    Visible = false;
                }
                field("Shipping Time"; "Shipping Time")
                {
                    Editable = "Shipping TimeEditable";
                    ToolTip = 'Specifies the shipping time for the order. This is the time it takes from when the order is shipped from the warehouse, to when the order is delivered to the customer''s address.';
                    Visible = false;
                }
                field("Whse. Outstanding Qty. (Base)"; "Whse. Outstanding Qty. (Base)")
                {
                    ToolTip = 'Specifies the variant number of the items sold.';
                    Visible = false;
                }
                field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                {
                    ToolTip = 'Specifies the outbound warehouse handling time, which is used to calculate the planned shipment date.';
                    Visible = false;
                }
                field("FA Posting Date"; "FA Posting Date")
                {
                    Editable = "FA Posting DateEditable";
                    ToolTip = 'Specifies the posting date for the fixed asset.';
                    Visible = false;
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    Editable = "Appl.-from Item EntryEditable";
                    ToolTip = 'Specifies the number of the item ledger entry that the sales credit memo line is applied from. This means that the inventory increase from this sales credit memo line is linked to the inventory decrease in the item ledger entry that you indicate in this field.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    Editable = "Appl.-to Item EntryEditable";
                    ToolTip = 'Specifies the number of a particular item ledger entry that the line should be applied to. This means that the inventory decrease from this sales line will be taken from the inventory increase in the item ledger entry that you select in this field. This creates a link so that the cost of the applied-to item ledger entry is carried over to this line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Purchase &Order")
                    {
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'Purchase goods or services from a vendor.';

                        trigger OnAction()
                        begin
                            OpenPurchOrderForm;
                        end;
                    }
                }
                group("Special Order")
                {
                    Caption = 'Special Order';
                    Image = SpecialOrder;
                    action(Action1902080804)
                    {
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'Purchase goods or services from a vendor.';

                        trigger OnAction()
                        begin
                            OpenPurchOrderForm;
                        end;
                    }
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Item Charge &Assignment")
                {
                    Caption = 'Item Charge &Assignment';
					Enabled = Type = Type::"Charge (Item)";
                    ToolTip = 'Record additional direct costs, for example for freight. This action is available only for Charge (Item) line types.';

                    trigger OnAction()
                    begin
                        ItemChargeAssgnt;
                    end;
                }
                action("Item &Tracking Lines")
                {
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
					Enabled = Type = Type::Item;
                    ToolTip = 'View or edit serial and lot numbers for the selected item. This action is available only for lines that contain an item.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        "Appl.-to Item EntryEditable" := true;
        "Appl.-from Item EntryEditable" := true;
        "FA Posting DateEditable" := true;
        "Shipping TimeEditable" := true;
        ShippingAgentServiceCodeEditab := true;
        "Shipping Agent CodeEditable" := true;
        "Shipment DateEditable" := true;
        "Planned Shipment DateEditable" := true;
        "Planned Delivery DateEditable" := true;
        "Promised Delivery DateEditable" := true;
        AllowItemChargeAssignmentEdita := true;
        "Qty. to ShipEditable" := true;
        "Package Tracking No.Editable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Type := xRec.Type;
        Clear(ShortcutDimCode);
    end;

    var
        SalesHeader: Record "Sales Header";
        ItemCrossReference: Record "Item Cross Reference";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ShortcutDimCode: array[8] of Code[20];
        [InDataSet]
        "Variant CodeEditable": Boolean;
        [InDataSet]
        "Package Tracking No.Editable": Boolean;
        [InDataSet]
        "Qty. to ShipEditable": Boolean;
        [InDataSet]
        AllowItemChargeAssignmentEdita: Boolean;
        [InDataSet]
        "Promised Delivery DateEditable": Boolean;
        [InDataSet]
        "Planned Delivery DateEditable": Boolean;
        [InDataSet]
        "Planned Shipment DateEditable": Boolean;
        [InDataSet]
        "Shipment DateEditable": Boolean;
        [InDataSet]
        "Shipping Agent CodeEditable": Boolean;
        [InDataSet]
        ShippingAgentServiceCodeEditab: Boolean;
        [InDataSet]
        "Shipping TimeEditable": Boolean;
        [InDataSet]
        "FA Posting DateEditable": Boolean;
        [InDataSet]
        "Appl.-from Item EntryEditable": Boolean;
        [InDataSet]
        "Appl.-to Item EntryEditable": Boolean;

    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
    end;

    procedure CalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", Rec);
    end;

    procedure ExplodeBOM()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", Rec);
    end;

    procedure OpenPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchOrder: Page "Purchase Order";
    begin
        PurchHeader.SetRange("No.", "Purchase Order No.");
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := false;
        PurchOrder.Run;
    end;

    procedure OpenSpecialPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchOrder: Page "Purchase Order";
    begin
        PurchHeader.SetRange("No.", "Special Order Purchase No.");
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := false;
        PurchOrder.Run;
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord;
            TransferExtendedText.InsertSalesExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate then
            UpdateForm(true);
    end;

    procedure ShowLineReservation()
    begin
        Find;
        ShowReservation;
    end;

    procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin)
    begin
        ItemAvailability(AvailabilityType);
    end;

    procedure ShowReservationEntries()
    begin
        ShowReservationEntries(true);
    end;

    procedure ShowNonstockItems()
    begin
        ShowNonstock;
    end;

    procedure ShowTracking()
    var
        TrackingForm: Page "Order Tracking";
    begin
        TrackingForm.SetSalesLine(Rec);
        TrackingForm.RunModal;
    end;

    procedure ItemChargeAssgnt()
    begin
        ShowItemChargeAssgnt;
    end;

    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    procedure OrderOnHold(OnHold: Boolean)
    begin
        "Variant CodeEditable" := not OnHold;
        "Package Tracking No.Editable" := not OnHold;
        "Qty. to ShipEditable" := not OnHold;
        AllowItemChargeAssignmentEdita := not OnHold;
        "Promised Delivery DateEditable" := not OnHold;
        "Planned Delivery DateEditable" := not OnHold;
        "Planned Shipment DateEditable" := not OnHold;
        "Shipment DateEditable" := not OnHold;
        "Shipping Agent CodeEditable" := not OnHold;
        ShippingAgentServiceCodeEditab := not OnHold;
        "Shipping TimeEditable" := not OnHold;
        "FA Posting DateEditable" := not OnHold;
        "Appl.-from Item EntryEditable" := not OnHold;
        "Appl.-to Item EntryEditable" := not OnHold;
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
        if (Type = Type::"Charge (Item)") and ("No." <> xRec."No.") and
           (xRec."No." <> '')
        then
            CurrPage.SaveRecord;
    end;

    local procedure QuantityOnAfterValidate()
    begin
        if Reserve = Reserve::Always then begin
            CurrPage.SaveRecord;
            AutoReserve;
            CurrPage.Update(false);
        end;
    end;

    local procedure UnitofMeasureCodeOnAfterValida()
    begin
        if Reserve = Reserve::Always then begin
            CurrPage.SaveRecord;
            AutoReserve;
            CurrPage.Update(false);
        end;
    end;
}

