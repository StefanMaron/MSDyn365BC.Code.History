// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

page 99000883 "Sales Order Planning"
{
    Caption = 'Sales Order Planning';
    DataCaptionExpression = Caption();
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number of the sales order line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Planning Status"; Rec."Planning Status")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the planning status of the production order, depending on the actual sales order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description of the item in the sales order line.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Planned Quantity"; Rec."Planned Quantity")
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
                          Rec."Sales Order No.", Rec."Sales Order Line No.");
                        SalesLine.ShowReservationEntries(true);
                    end;
                }
                field(Available; Rec.Available)
                {
                    ApplicationArea = Planning;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many of the actual items are available.';
                }
                field("Next Planning Date"; Rec."Next Planning Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the next planning date.';
                }
                field("Expected Delivery Date"; Rec."Expected Delivery Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the expected delivery date.';
                }
                field("Needs Replanning"; Rec."Needs Replanning")
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
                    RunPageLink = "No." = field("Item No.");
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
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Item No.", Open, "Variant Code");
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
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            if Item.Get(Rec."Item No.") then
                                ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByEvent());
                        end;
                    }
                    action("<Action31>")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = field("Item No.");
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
                            if Item.Get(Rec."Item No.") then
                                ItemAvailFormsMgt.ShowItemAvailFromItem(Item, ItemAvailFormsMgt.ByBOM());
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
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        ItemStatistics: Page "Item Statistics";
                    begin
                        if Item.Get(Rec."Item No.") then;
                        ItemStatistics.SetItem(Item);
                        ItemStatistics.RunModal();
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

                        LastShipmentDate := WorkDate();

                        SalesHeader.LockTable();
                        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.");

                        if Choice = 1 then begin
                            if Rec.Find('-') then
                                repeat
                                    if Rec."Expected Delivery Date" > LastShipmentDate then
                                        LastShipmentDate := Rec."Expected Delivery Date";
                                until Rec.Next() = 0;
                            SalesHeader.Validate("Shipment Date", LastShipmentDate);
                            SalesHeader.Modify();
                        end
                        else begin
                            SalesLine.LockTable();
                            if Rec.Find('-') then
                                repeat
                                    SalesLine.Get(
                                      SalesLine."Document Type"::Order,
                                      Rec."Sales Order No.",
                                      Rec."Sales Order Line No.");
                                    SalesLine."Shipment Date" := Rec."Expected Delivery Date";
                                    SalesLine.Modify();
                                until Rec.Next() = 0;
                        end;
                        BuildForm();
                    end;
                }
                action("&Create Prod. Order")
                {
                    AccessByPermission = TableData "Production Order" = R;
                    ApplicationArea = Manufacturing;
                    Caption = '&Create Prod. Order';
                    Image = CreateDocument;
                    ToolTip = 'Prepare to create a production order to fulfill the sales demand.';

                    trigger OnAction()
                    begin
                        CreateProdOrder();
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
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        SalesOrderLine: Record "Sales Line";
                        TrackingForm: Page "Order Tracking";
                    begin
                        SalesOrderLine.Get(
                          SalesOrderLine."Document Type"::Order,
                          Rec."Sales Order No.",
                          Rec."Sales Order Line No.");

                        TrackingForm.SetSalesLine(SalesOrderLine);
                        TrackingForm.RunModal();
                        BuildForm();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Create Prod. Order_Promoted"; "&Create Prod. Order")
                {
                }
                actionref("Order &Tracking_Promoted"; "Order &Tracking")
                {
                }
                actionref("Update &Shipment Dates_Promoted"; "Update &Shipment Dates")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                group("Category_Item Availability by")
                {
                    Caption = 'Item Availability by';

                    actionref("<Action6>_Promoted"; "<Action6>")
                    {
                    }
                    actionref("BOM Level_Promoted"; "BOM Level")
                    {
                    }
                    actionref("<Action31>_Promoted"; "<Action31>")
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildForm();
    end;

    var
        SalesHeader: Record "Sales Header";
        ReservEntry: Record "Reservation Entry";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewStatus: Enum "Production Order Status";
        NewOrderType: Enum "Create Production Order Type";

        Text000: Label 'All Lines to last Shipment Date,Each line own Shipment Date';
        Text001: Label 'There is nothing to plan.';

    procedure SetSalesOrder(SalesOrderNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
    end;

    procedure BuildForm()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        MakeLines();
        Rec.SetRange("Sales Order No.", SalesHeader."No.");
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
                Rec.Init();
                Rec."Sales Order No." := SalesLine."Document No.";
                Rec."Sales Order Line No." := SalesLine."Line No.";
                Rec."Item No." := SalesLine."No.";

                Rec."Variant Code" := SalesLine."Variant Code";
                Rec.Description := SalesLine.Description;
                Rec."Shipment Date" := SalesLine."Shipment Date";
                Rec."Planning Status" := Rec."Planning Status"::None;
                SalesLine.CalcFields("Reserved Qty. (Base)");
                Rec."Planned Quantity" := SalesLine."Reserved Qty. (Base)";
                ReservEntry.InitSortingAndFilters(false);
                SalesLine.SetReservationFilters(ReservEntry);
                ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                if ReservEntry.Find('-') then
                    repeat
                        if ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                            case ReservEntry2."Source Type" of
                                Database::"Item Ledger Entry":
                                    begin
                                        Rec."Planning Status" := Rec."Planning Status"::Inventory;
                                        Rec."Expected Delivery Date" := SalesLine."Shipment Date";
                                    end;
                                Database::"Requisition Line":
                                    begin
                                        ReqLine.Get(
                                          ReservEntry2."Source ID", ReservEntry2."Source Batch Name", ReservEntry2."Source Ref. No.");
                                        Rec."Planning Status" := Rec."Planning Status"::Planned;
                                        Rec."Expected Delivery Date" := ReqLine."Due Date";
                                    end;
                                Database::"Purchase Line":
                                    begin
                                        PurchLine.Get(
                                          ReservEntry2."Source Subtype", ReservEntry2."Source ID", ReservEntry2."Source Ref. No.");
                                        Rec."Planning Status" := Rec."Planning Status"::"Firm Planned";
                                        Rec."Expected Delivery Date" := PurchLine."Expected Receipt Date";
                                    end;
                                Database::"Prod. Order Line":
                                    begin
                                        ProdOrderLine.Get(
                                          ReservEntry2."Source Subtype", ReservEntry2."Source ID", ReservEntry2."Source Prod. Order Line");
                                        if ProdOrderLine."Due Date" > Rec."Expected Delivery Date" then
                                            Rec."Expected Delivery Date" := ProdOrderLine."Ending Date";
                                        if ((ProdOrderLine.Status.AsInteger() + 1) < Rec."Planning Status") or
                                           (Rec."Planning Status" = Rec."Planning Status"::None)
                                        then
                                            Rec."Planning Status" := ProdOrderLine.Status.AsInteger() + 1;
                                    end;
                            end;
                    until ReservEntry.Next() = 0;
                Rec."Needs Replanning" :=
                  (Rec."Planned Quantity" <> SalesLine."Outstanding Qty. (Base)") or
                  (Rec."Expected Delivery Date" > Rec."Shipment Date");
                CalculateDisposalPlan(SalesLine."Variant Code", SalesLine."Location Code");
                OnMakeLinesOnBeforeInsertSalesOrderPlanningLine(Rec, SalesLine);
                Rec.Insert();
            until SalesLine.Next() = 0;
    end;

    local procedure CalculateDisposalPlan(VariantCode: Code[20]; LocationCode: Code[10])
    var
        Item: Record Item;
    begin
        if not Rec."Needs Replanning" then
            exit;

        Item.Get(Rec."Item No.");
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(
          Inventory,
          "Qty. on Purch. Order",
          "Qty. on Sales Order",
          "Scheduled Receipt (Qty.)",
          "Planned Order Receipt (Qty.)",
          "Qty. on Component Lines");

        if Item.Type = Item.Type::Inventory then
            Rec.Available :=
              Item.Inventory -
              Item."Qty. on Sales Order" +
              Item."Qty. on Purch. Order" -
              Item."Qty. on Component Lines" +
              Item."Scheduled Receipt (Qty.)" +
              Item."Planned Order Receipt (Qty.)"
        else
            Rec.Available := 0;

        Rec."Next Planning Date" := WorkDate();

        CalculatePlanAndDelivDates(Item, Rec."Next Planning Date", Rec."Expected Delivery Date");
    end;

    local procedure CalculatePlanAndDelivDates(Item: Record Item; var NextPlanningDate: Date; var ExpectedDeliveryDate: Date)
    begin
        OnBeforeCalculatePlanAndDelivDates(Item);

        NextPlanningDate := CalcDate(Item."Lot Accumulation Period", NextPlanningDate);

        if (Rec.Available > 0) or (Rec."Planning Status" <> Rec."Planning Status"::None) then
            ExpectedDeliveryDate := CalcDate(Item."Safety Lead Time", WorkDate())
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
        CreateProdOrder: Boolean;
        EndLoop: Boolean;
        IsHandled: Boolean;
    begin
        xSalesPlanLine := Rec;

        OnCreateOrdersOnBeforeFindSet(Rec);

        if not Rec.FindSet() then
            exit;

        repeat
            SalesLine.Get(SalesLine."Document Type"::Order, Rec."Sales Order No.", Rec."Sales Order Line No.");
            SalesLine.TestField("Shipment Date");
            SalesLine.CalcFields("Reserved Qty. (Base)");

            IsHandled := false;
            OnCreateOrdersOnBeforeCreateProdOrder(Rec, SalesLine, IsHandled);
            if IsHandled then
                exit;

            if SalesLine."Outstanding Qty. (Base)" > SalesLine."Reserved Qty. (Base)" then begin
                if SKU.Get(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code") then
                    CreateProdOrder := SKU."Replenishment System" = SKU."Replenishment System"::"Prod. Order"
                else begin
                    Item.Get(SalesLine."No.");
                    CreateProdOrder := Item."Replenishment System" = Item."Replenishment System"::"Prod. Order";
                end;

                CreateOrder(CreateProdOrder, SalesLine, EndLoop, OrdersCreated);
            end;
        until (Rec.Next() = 0) or EndLoop;

        Rec := xSalesPlanLine;
    end;

    procedure Caption(): Text
    begin
        exit(StrSubstNo('%1 %2', SalesHeader."No.", SalesHeader."Bill-to Name"));
    end;

    procedure CreateProdOrder()
    var
        CreateOrderFromSales: Page "Create Order From Sales";
        NewOrderTypeOption: Option;
        ShowCreateOrderForm: Boolean;
        IsHandled: Boolean;
    begin
        ShowCreateOrderForm := true;
        IsHandled := false;
        NewOrderTypeOption := NewOrderType.AsInteger();
        OnBeforeCreateProdOrder(Rec, NewStatus, NewOrderTypeOption, ShowCreateOrderForm, IsHandled);
        NewOrderType := "Create Production Order Type".FromInteger(NewOrderTypeOption);
        if IsHandled then
            exit;

        if ShowCreateOrderForm then begin
            if CreateOrderFromSales.RunModal() <> ACTION::Yes then
                exit;

            CreateOrderFromSales.GetParameters(NewStatus, NewOrderType);
            OnCreateProdOrderOnAfterGetParameters(Rec, NewStatus, NewOrderType);
            Clear(CreateOrderFromSales);
        end;

        if not CreateOrders() then
            Message(Text001);

        Rec.SetRange("Planning Status");

        BuildForm();

        OnAfterCreateProdOrder(Rec);

        CurrPage.Update(false);
    end;

    local procedure CreateOrder(CreateProdOrder: Boolean; var SalesLine: Record "Sales Line"; var EndLoop: Boolean; var OrdersCreated: Boolean)
    var
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        OnBeforeCreateOrder(Rec, SalesLine, CreateProdOrder);

        if CreateProdOrder then begin
            OrdersCreated := true;
            CreateProdOrderFromSale.CreateProductionOrder(SalesLine, NewStatus, NewOrderType);
            if NewOrderType = NewOrderType::ProjectOrder then
                EndLoop := true;
        end;
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
    local procedure OnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var NewStatus: Enum "Production Order Status"; var NewOrderType: Option ItemOrder,ProjectOrder; var ShowCreateOrderForm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderOnAfterGetParameters(var SalesPlanningLine: Record "Sales Planning Line"; var NewStatus: Enum "Production Order Status"; var NewOrderType: Enum "Create Production Order Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateOrdersOnBeforeFindSet(var SalesPlanningLine: Record "Sales Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeInsertSalesOrderPlanningLine(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesSetOnAfterSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrdersOnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrder(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line"; var CreateProdOrder: Boolean);
    begin
    end;
}

