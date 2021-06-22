page 99000883 "Sales Order Planning"
{
    Caption = 'Sales Order Planning';
    DataCaptionExpression = Caption;
    DataCaptionFields = "Sales Order No.";
    Editable = false;
    PageType = List;
    SourceTable = "Sales Planning Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number of the sales order line.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Planning Status"; "Planning Status")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the planning status of the production order, depending on the actual sales order.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description of the item in the sales order line.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Planned Quantity"; "Planned Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity planned in this line.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalesLine: Record "Sales Line";
                    begin
                        SalesLine.Get(
                          SalesLine."Document Type"::Order,
                          "Sales Order No.", "Sales Order Line No.");
                        SalesLine.ShowReservationEntries(true);
                    end;
                }
                field(Available; Available)
                {
                    ApplicationArea = Planning;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many of the actual items are available.';
                }
                field("Next Planning Date"; "Next Planning Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the next planning date.';
                }
                field("Expected Delivery Date"; "Expected Delivery Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the expected delivery date.';
                }
                field("Needs Replanning"; "Needs Replanning")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies if it is necessary or not to reschedule this line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Item No.", Open, "Variant Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                group("<Action8>")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("<Action6>")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        Promoted = true;
                        PromotedCategory = Process;
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            if Item.Get("Item No.") then
                                ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action("<Action31>")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = FIELD("Item No.");
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Planning;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            if Item.Get("Item No.") then
                                ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                }
                separator(Action30)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Planning;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ItemStatistics: Page "Item Statistics";
                    begin
                        if Item.Get("Item No.") then;
                        ItemStatistics.SetItem(Item);
                        ItemStatistics.RunModal;
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
                action("Update &Shipment Dates")
                {
                    ApplicationArea = Planning;
                    Caption = 'Update &Shipment Dates';
                    Ellipsis = true;
                    Image = UpdateShipment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Update the Shipment Date field on lines with any changes that were made since you opened the Sales Order Planning window.';

                    trigger OnAction()
                    var
                        SalesLine: Record "Sales Line";
                        Choice: Integer;
                        LastShipmentDate: Date;
                    begin
                        Choice := StrMenu(Text000);

                        if Choice = 0 then
                            exit;

                        LastShipmentDate := WorkDate;

                        SalesHeader.LockTable();
                        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.");

                        if Choice = 1 then begin
                            if Find('-') then
                                repeat
                                    if "Expected Delivery Date" > LastShipmentDate then
                                        LastShipmentDate := "Expected Delivery Date";
                                until Next = 0;
                            SalesHeader.Validate("Shipment Date", LastShipmentDate);
                            SalesHeader.Modify();
                        end
                        else begin
                            SalesLine.LockTable();
                            if Find('-') then
                                repeat
                                    SalesLine.Get(
                                      SalesLine."Document Type"::Order,
                                      "Sales Order No.",
                                      "Sales Order Line No.");
                                    SalesLine."Shipment Date" := "Expected Delivery Date";
                                    SalesLine.Modify();
                                until Next = 0;
                        end;
                        BuildForm;
                    end;
                }
                action("&Create Prod. Order")
                {
                    AccessByPermission = TableData "Production Order" = R;
                    ApplicationArea = Manufacturing;
                    Caption = '&Create Prod. Order';
                    Image = CreateDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Prepare to create a production order to fulfill the sales demand.';

                    trigger OnAction()
                    begin
                        CreateProdOrder;
                    end;
                }
                separator(Action32)
                {
                }
                action("Order &Tracking")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        SalesOrderLine: Record "Sales Line";
                        TrackingForm: Page "Order Tracking";
                    begin
                        SalesOrderLine.Get(
                          SalesOrderLine."Document Type"::Order,
                          "Sales Order No.",
                          "Sales Order Line No.");

                        TrackingForm.SetSalesLine(SalesOrderLine);
                        TrackingForm.RunModal;
                        BuildForm;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildForm();
    end;

    var
        Text000: Label 'All Lines to last Shipment Date,Each line own Shipment Date';
        Text001: Label 'There is nothing to plan.';
        SalesHeader: Record "Sales Header";
        ReservEntry: Record "Reservation Entry";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewStatus: Option Simulated,Planned,"Firm Planned",Released,Finished;
        NewOrderType: Option ItemOrder,ProjectOrder;

    procedure SetSalesOrder(SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
    end;

    procedure BuildForm()
    begin
        Reset();
        DeleteAll();
        MakeLines();
        SetRange("Sales Order No.", SalesHeader."No.");
    end;

    local procedure MakeLines()
    var
        SalesLine: Record "Sales Line";
        ProdOrderLine: Record "Prod. Order Line";
        PurchLine: Record "Purchase Line";
        ReqLine: Record "Requisition Line";
        ReservEntry2: Record "Reservation Entry";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        OnMakeLinesSetOnAfterSetFilters(SalesLine);
        if SalesLine.Find('-') then
            repeat
                Init;
                "Sales Order No." := SalesLine."Document No.";
                "Sales Order Line No." := SalesLine."Line No.";
                "Item No." := SalesLine."No.";

                "Variant Code" := SalesLine."Variant Code";
                Description := SalesLine.Description;
                "Shipment Date" := SalesLine."Shipment Date";
                "Planning Status" := "Planning Status"::None;
                SalesLine.CalcFields("Reserved Qty. (Base)");
                "Planned Quantity" := SalesLine."Reserved Qty. (Base)";
                ReservEntry.InitSortingAndFilters(false);
                SalesLine.SetReservationFilters(ReservEntry);
                ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                if ReservEntry.Find('-') then
                    repeat
                        if ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                            case ReservEntry2."Source Type" of
                                DATABASE::"Item Ledger Entry":
                                    begin
                                        "Planning Status" := "Planning Status"::Inventory;
                                        "Expected Delivery Date" := SalesLine."Shipment Date";
                                    end;
                                DATABASE::"Requisition Line":
                                    begin
                                        ReqLine.Get(
                                          ReservEntry2."Source ID", ReservEntry2."Source Batch Name", ReservEntry2."Source Ref. No.");
                                        "Planning Status" := "Planning Status"::Planned;
                                        "Expected Delivery Date" := ReqLine."Due Date";
                                    end;
                                DATABASE::"Purchase Line":
                                    begin
                                        PurchLine.Get(
                                          ReservEntry2."Source Subtype", ReservEntry2."Source ID", ReservEntry2."Source Ref. No.");
                                        "Planning Status" := "Planning Status"::"Firm Planned";
                                        "Expected Delivery Date" := PurchLine."Expected Receipt Date";
                                    end;
                                DATABASE::"Prod. Order Line":
                                    begin
                                        ProdOrderLine.Get(
                                          ReservEntry2."Source Subtype", ReservEntry2."Source ID", ReservEntry2."Source Prod. Order Line");
                                        if ProdOrderLine."Due Date" > "Expected Delivery Date" then
                                            "Expected Delivery Date" := ProdOrderLine."Ending Date";
                                        if ((ProdOrderLine.Status + 1) < "Planning Status") or
                                           ("Planning Status" = "Planning Status"::None)
                                        then
                                            "Planning Status" := ProdOrderLine.Status + 1;
                                    end;
                            end;
                    until ReservEntry.Next = 0;
                "Needs Replanning" :=
                  ("Planned Quantity" <> SalesLine."Outstanding Qty. (Base)") or
                  ("Expected Delivery Date" > "Shipment Date");
                CalculateDisposalPlan(SalesLine."Variant Code", SalesLine."Location Code");
                Insert();
            until SalesLine.Next() = 0;
    end;

    local procedure CalculateDisposalPlan(VariantCode: Code[20]; LocationCode: Code[10])
    var
        Item: Record Item;
    begin
        if not "Needs Replanning" then
            exit;

        Item.Get("Item No.");
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(
          Inventory,
          "Qty. on Purch. Order",
          "Qty. on Sales Order",
          "Scheduled Receipt (Qty.)",
          "Planned Order Receipt (Qty.)",
          "Scheduled Need (Qty.)");

        Available :=
          Item.Inventory -
          Item."Qty. on Sales Order" +
          Item."Qty. on Purch. Order" -
          Item."Scheduled Need (Qty.)" +
          Item."Scheduled Receipt (Qty.)" +
          Item."Planned Order Receipt (Qty.)";

        "Next Planning Date" := WorkDate;

        CalculatePlanAndDelivDates(Item, "Next Planning Date", "Expected Delivery Date");
    end;

    local procedure CalculatePlanAndDelivDates(Item: Record Item; var NextPlanningDate: Date; var ExpectedDeliveryDate: Date)
    begin
        OnBeforeCalculatePlanAndDelivDates(Item);

        NextPlanningDate := CalcDate(Item."Lot Accumulation Period", NextPlanningDate);

        if (Available > 0) or ("Planning Status" <> "Planning Status"::None) then
            ExpectedDeliveryDate := CalcDate(Item."Safety Lead Time", WorkDate)
        else
            ExpectedDeliveryDate :=
              CalcDate(Item."Safety Lead Time",
                CalcDate(Item."Lead Time Calculation", NextPlanningDate))
    end;

    local procedure CreateOrders() OrdersCreated: Boolean
    var
        xSalesPlanLine: Record "Sales Planning Line";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SKU: Record "Stockkeeping Unit";
        ProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
        CreateProdOrder: Boolean;
        EndLoop: Boolean;
    begin
        xSalesPlanLine := Rec;

        if not FindSet() then
            exit;

        repeat
            SalesLine.Get(SalesLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
            SalesLine.TestField("Shipment Date");
            SalesLine.CalcFields("Reserved Qty. (Base)");
            OnCreateOrdersOnBeforeCreateProdOrder(Rec, SalesLine);
            if SalesLine."Outstanding Qty. (Base)" > SalesLine."Reserved Qty. (Base)" then begin
                if SKU.Get(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code") then
                    CreateProdOrder := SKU."Replenishment System" = SKU."Replenishment System"::"Prod. Order"
                else begin
                    Item.Get(SalesLine."No.");
                    CreateProdOrder := Item."Replenishment System" = Item."Replenishment System"::"Prod. Order";
                end;

                if CreateProdOrder then begin
                    OrdersCreated := true;
                    ProdOrderFromSale.CreateProdOrder(SalesLine, NewStatus, NewOrderType);
                    if NewOrderType = NewOrderType::ProjectOrder then
                        EndLoop := true;
                end;
            end;
        until (Next = 0) or EndLoop;

        Rec := xSalesPlanLine;
    end;

    procedure Caption(): Text
    begin
        exit(StrSubstNo('%1 %2', SalesHeader."No.", SalesHeader."Bill-to Name"));
    end;

    procedure CreateProdOrder()
    var
        CreateOrderFromSales: Page "Create Order From Sales";
        ShowCreateOrderForm: Boolean;
        IsHandled: Boolean;
    begin
        ShowCreateOrderForm := true;
        IsHandled := false;
        OnBeforeCreateProdOrder(Rec, NewStatus, NewOrderType, ShowCreateOrderForm, IsHandled);
        if IsHandled then
            exit;

        if ShowCreateOrderForm then begin
            if CreateOrderFromSales.RunModal <> ACTION::Yes then
                exit;

            CreateOrderFromSales.ReturnPostingInfo(NewStatus, NewOrderType);
            Clear(CreateOrderFromSales);
        end;

        if not CreateOrders then
            Message(Text001);

        SetRange("Planning Status");

        BuildForm();

        OnAfterCreateProdOrder(Rec);

        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePlanAndDelivDates(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var NewStatus: Option Simulated,Planned,"Firm Planned",Released,Finished; var NewOrderType: Option ItemOrder,ProjectOrder; var ShowCreateOrderForm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesSetOnAfterSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrdersOnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line")
    begin
    end;
}

