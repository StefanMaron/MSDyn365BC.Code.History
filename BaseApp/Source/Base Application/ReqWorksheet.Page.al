page 291 "Req. Worksheet"
{
    AdditionalSearchTerms = 'supply planning,mrp,mps';
    ApplicationArea = Basic, Suite, Planning;
    AutoSplitKey = true;
    Caption = 'Requisition Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Requisition Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Planning;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ReqJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);

                    OnAfterLookupCurrentJnlBatchName(Rec, CurrentJnlBatchName);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                        ShowShortcutDimCode(ShortcutDimCode);
                        if "Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
                    end;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method that will be used for unit cost calculation in the line.';
                }
                field("Action Message"; Rec."Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Accept Action Message"; Rec."Accept Action Message")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if "Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the bin of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                }
                field("Original Quantity"; Rec."Original Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity stated on the production or purchase order, when an action message proposes to change the quantity on an order.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of units of the item or resource specified on the line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Planning;
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the requisition lines.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", WorkDate());
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter());

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                    Visible = false;
                }
                field("Original Due Date"; Rec."Original Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the due date stated on the production or purchase order, when an action message proposes to reschedule an order.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when the related order was created.';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the order address of the related vendor.';
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the customer.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = false;
                }
                field("Requester ID"; Rec."Requester ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who is ordering the items on the line.';
                    Visible = false;
                }
                field(Confirmed; Confirmed)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the items on the line have been approved for purchase.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Ref. Order No."; Rec."Ref. Order No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the relevant production or purchase order.';
                    Visible = false;
                }
                field("Ref. Order Type"; Rec."Ref. Order Type")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the order is a purchase order, a production order, or a transfer order.';
                    Visible = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies which kind of order to use to create replenishment orders and order proposals.';
                }
                field("Supply From"; Rec."Supply From")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ToolTip = 'Specifies a value, according to the selected replenishment system, before a supply order can be created for the line.';
                }
                field("Ref. Line No."; Rec."Ref. Line No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the purchase or production order line.';
                    Visible = false;
                }
                field("Planning Flexibility"; Rec."Planning Flexibility")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the supply represented by this line is considered by the planning system when calculating action messages.';
                    Visible = false;
                }
                field("Blanket Purch. Order Exists"; Rec."Blanket Purch. Order Exists")
                {
                    ApplicationArea = Planning;
                    BlankZero = true;
                    ToolTip = 'Specifies if a blanket purchase order exists for the item on the requisition line.';
                    Visible = false;
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                fixed(Control1901776201)
                {
                    ShowCaption = false;
                    group(Control1902759801)
                    {
                        Caption = 'Description';
                        field(Description2; Description2)
                        {
                            ApplicationArea = Planning;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies an additional part of the worksheet description.';
                        }
                    }
                    group("Buy-from Vendor Name")
                    {
                        Caption = 'Buy-from Vendor Name';
                        field(BuyFromVendorName; BuyFromVendorName)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Buy-from Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the vendor according to the values in the Document No. and Document Type fields.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control1903326807; "Item Replenishment FactBox")
            {
                ApplicationArea = Planning;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Req. Wksh.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the item or resource.';
                }
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByEvent())
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByPeriod())
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByVariant())
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByLocation())
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromReqLine(Rec, ItemAvailFormsMgt.ByBOM())
                        end;
                    }
#if not CLEAN21
                    action(Timeline)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Timeline';
                        Image = Timeline;
                        ToolTip = 'Get a graphical view of an item''s projected inventory based on future supply and demand events, with or without planning suggestions. The result is a graphical representation of the inventory profile.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'TimelineVisualizer control has been deprecated.';
                        ObsoleteTag = '21.0';

                        trigger OnAction()
                        begin
                            ShowTimeline(Rec);
                        end;
                    }
#endif                
                }
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
                        ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines();
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
                action(CalculatePlan)
                {
                    ApplicationArea = Planning;
                    Caption = 'Calculate Plan';
                    Ellipsis = true;
                    Image = CalculatePlan;
                    ToolTip = 'Use a batch job to help you calculate a supply plan for items and stockkeeping units that have the Replenishment System field set to Purchase or Transfer.';

                    trigger OnAction()
                    begin
                        CalculatePlan.SetTemplAndWorksheet("Worksheet Template Name", "Journal Batch Name");
                        OnCalculatePlanOnBeforeCalculatePlanRunModal(CalculatePlan, Rec);
                        CalculatePlan.RunModal();
                        Clear(CalculatePlan);
                    end;
                }
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Get &Sales Orders")
                    {
                        AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
                        ApplicationArea = Planning;
                        Caption = 'Get &Sales Orders';
                        Ellipsis = true;
                        Image = "Order";
                        ToolTip = 'Copy sales lines to the requisition worksheet. You can use the batch job to create requisition worksheet proposal lines from sales lines for drop shipments or special orders.';

                        trigger OnAction()
                        begin
                            GetSalesOrder.SetReqWkshLine(Rec, 0);
                            OnGetSalesOrderActionOnBeforeGetSalesOrderRunModal(GetSalesOrder, Rec);
                            GetSalesOrder.RunModal();
                            Clear(GetSalesOrder);
                        end;
                    }
                    action("Sales &Order")
                    {
                        AccessByPermission = TableData "Sales Shipment Header" = R;
                        ApplicationArea = Planning;
                        Caption = 'Sales &Order';
                        Image = Document;
                        Enabled = "Sales Order No." <> '';
                        ToolTip = 'View the sales order that is the source of the line. This applies only to drop shipments and special orders.';

                        trigger OnAction()
                        begin
                            SalesHeader.SetRange("No.", "Sales Order No.");
                            SalesOrder.SetTableView(SalesHeader);
                            SalesOrder.Editable := false;
                            SalesOrder.Run();
                        end;
                    }
                }
                group("Special Order")
                {
                    Caption = 'Special Order';
                    Image = SpecialOrder;
                    action(Action53)
                    {
                        AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
                        ApplicationArea = Planning;
                        Caption = 'Get &Sales Orders';
                        Ellipsis = true;
                        Image = "Order";
                        ToolTip = 'Copy sales lines to the requisition worksheet. You can use the batch job to create requisition worksheet proposal lines from sales lines for drop shipments or special orders.';

                        trigger OnAction()
                        begin
                            GetSalesOrder.SetReqWkshLine(Rec, 1);
                            OnActionGetSalesOrdersOnBeforeGetSalesOrderRunModal(GetSalesOrder, Rec);
                            GetSalesOrder.RunModal();
                            Clear(GetSalesOrder);
                        end;
                    }
                    action(Action75)
                    {
                        AccessByPermission = TableData "Sales Shipment Header" = R;
                        ApplicationArea = Planning;
                        Caption = 'Sales &Order';
                        Image = Document;
                        Enabled = "Sales Order No." <> '';
                        ToolTip = 'View the sales order that is the source of the line. This applies only to drop shipments and special orders.';

                        trigger OnAction()
                        begin
                            SalesHeader.SetRange("No.", "Sales Order No.");
                            SalesOrder.SetTableView(SalesHeader);
                            SalesOrder.Editable := false;
                            SalesOrder.Run();
                        end;
                    }
                }
                separator(Action81)
                {
                }
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve one or more units of the item on the job planning line, either from inventory or from incoming supply.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        ShowReservation();
                    end;
                }
                action(CarryOutActionMessage)
                {
                    ApplicationArea = Planning;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    begin
                        CarryOutActionMsg();
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            group("Order Tracking")
            {
                Caption = 'Order Tracking';
                Image = OrderTracking;
                action("Order &Tracking")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        TrackingForm: Page "Order Tracking";
                    begin
                        TrackingForm.SetReqLine(Rec);
                        TrackingForm.RunModal();
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Inventory Availability")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory Availability';
                Image = "Report";
                RunObject = Report "Inventory Availability";
                ToolTip = 'View, print, or save a summary of historical inventory transactions with selected items, for example, to decide when to purchase the items. The report specifies quantity on sales order, quantity on purchase order, back orders from vendors, minimum inventory, and whether there are reorders.';
            }
            action(Status)
            {
                ApplicationArea = Planning;
                Caption = 'Status';
                Image = "Report";
                RunObject = Report Status;
                ToolTip = 'View the status of the worksheet.';
            }
            action("Inventory - Availability Plan")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory - Availability Plan';
                Image = ItemAvailability;
                RunObject = Report "Inventory - Availability Plan";
                ToolTip = 'View a list of the quantity of each item in customer, purchase, and transfer orders and the quantity available in inventory. The list is divided into columns that cover six periods with starting and ending dates as well as the periods before and after those periods. The list is useful when you are planning your inventory purchases.';
            }
            action("Inventory Order Details")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory Order Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Inventory Order Details";
                ToolTip = 'View a list of the orders that have not yet been shipped or received and the items in the orders. It shows the order number, customer''s name, shipment date, order quantity, quantity on back order, outstanding quantity and unit price, as well as possible discount percentage and amount. The quantity on back order and outstanding quantity and amount are totaled for each item. The list can be used to find out whether there are currently shipment problems or any can be expected.';
            }
            action("Inventory Purchase Orders")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory Purchase Orders';
                Image = "Report";
                RunObject = Report "Inventory Purchase Orders";
                ToolTip = 'View a list of items on order from vendors. It also shows the expected receipt date and the quantity and amount on back orders. The report can be used, for example, to see when items should be received and whether a reminder of a back order should be issued.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CarryOutActionMessage_Promoted; CarryOutActionMessage)
                {
                }
                actionref(CalculatePlan_Promoted; CalculatePlan)
                {
                }
                actionref(Reserve_Promoted; Reserve)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Drop Shipment', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Get &Sales Orders_Promoted"; "Get &Sales Orders")
                {
                }
                actionref("Sales &Order_Promoted"; "Sales &Order")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Special Order', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Action53_Promoted; Action53)
                {
                }
                actionref(Action75_Promoted; Action75)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Order &Tracking_Promoted"; "Order &Tracking")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
#if not CLEAN21
                actionref(Card_Promoted; Card)
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action is being demoted based on overall low usage.';
                    ObsoleteTag = '21.0';
                }
#endif
            }
            group(Category_Category7)
            {
                Caption = 'Item Availability by', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
#if not CLEAN21
                actionref(Timeline_Promoted; Timeline)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'TimelineVisualizer control has been deprecated.';
                    ObsoleteTag = '21.0';
                }
#endif
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Inventory Availability_Promoted"; "Inventory Availability")
                {
                }
                actionref(Status_Promoted; Status)
                {
                }
                actionref("Inventory - Availability Plan_Promoted"; "Inventory - Availability Plan")
                {
                }
                actionref("Inventory Purchase Orders_Promoted"; "Inventory Purchase Orders")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record "Item";
    begin
        ShowShortcutDimCode(ShortcutDimCode);
        if "Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Type = Type::Item, "No.");
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        "Accept Action Message" := false;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ReqJnlManagement.SetUpNewLine(Rec, xRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        JnlSelected: Boolean;
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        OnBeforeTemplateSelection(Rec, CurrentJnlBatchName);
        ReqJnlManagement.WkshTemplateSelection(
            PAGE::"Req. Worksheet", false, "Req. Worksheet Template Type"::"Req.", Rec, JnlSelected);
        if not JnlSelected then
            Error('');

        OnBeforeOpenReqWorksheet(CurrentJnlBatchName);
        ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        SalesHeader: Record "Sales Header";
        GetSalesOrder: Report "Get Sales Orders";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ChangeExchangeRate: Page "Change Exchange Rate";
        SalesOrder: Page "Sales Order";
        ExtendedPriceEnabled: Boolean;
        VariantCodeMandatory: Boolean;
        OpenedFromBatch: Boolean;

    protected var
        CalculatePlan: Report "Calculate Plan - Req. Wksh.";
        CurrentJnlBatchName: Code[10];
        Description2: Text[100];
        BuyFromVendorName: Text[100];
        ShortcutDimCode: array[8] of Code[20];

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        ReqJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure CarryOutActionMsg()
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutActionMsg(Rec, IsHandled);
        if IsHandled then
            exit;

        CarryOutActionMsgReq.SetReqWkshLine(Rec);
        CarryOutActionMsgReq.RunModal();
        CarryOutActionMsgReq.GetReqWkshLine(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCurrentJnlBatchName(var RequisitionLine: Record "Requisition Line"; var CurrJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenReqWorksheet(var CUrrentJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelection(var RequisitionLine: Record "Requisition Line"; CurrentJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutActionMsg(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePlanOnBeforeCalculatePlanRunModal(var CalculatePlan: Report "Calculate Plan - Req. Wksh."; var RequisitionLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesOrderActionOnBeforeGetSalesOrderRunModal(var GetSalesOrder: Report "Get Sales Orders"; var RequisitionLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnActionGetSalesOrdersOnBeforeGetSalesOrderRunModal(var GetSalesOrder: Report "Get Sales Orders"; var RequisitionLine: Record "Requisition Line")
    begin
    end;
}

