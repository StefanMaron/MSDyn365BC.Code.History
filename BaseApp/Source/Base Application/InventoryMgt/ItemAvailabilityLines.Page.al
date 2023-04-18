page 353 "Item Availability Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Item Availability Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the first period that item availability is shown for.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the type of period that item availability is shown for.';
                }
                field(GrossRequirement; "Gross Requirement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the total demand for the item. The gross requirement consists of independent demand (which include sales orders, service orders, transfer orders, and, if specified on the page, demand forecasts) and dependent demand (which include production order components for planned, firm planned, and released production orders and requisition and planning worksheets lines).';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(0)
                    end;
                }
                field(ScheduledRcpt; "Scheduled Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment orders.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(2);
                    end;
                }
                field(PlannedOrderRcpt; "Planned Order Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Order Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s availability figures for the planned order receipt.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(1);
                    end;
                }
                field(ProjAvailableBalance; "Projected Available Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Projected Available Balance';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(4);
                    end;
                }
                field("Item.Inventory"; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the inventory level of an item.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                    end;
                }
                field("Item.""Qty. on Purch. Order"""; Rec."Qty. on Purch. Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Purch. Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item are inbound on purchase orders, meaning listed on outstanding purchase order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowPurchLines(Item);
                    end;
                }
                field("Item.""Qty. on Sales Order"""; Rec."Qty. on Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Sales Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item are allocated to sales orders, meaning listed on outstanding sales orders lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSalesLines(Item);
                    end;
                }
                field("Item.""Qty. on Service Order"""; Rec."Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. on Service Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowServLines(Item);
                    end;
                }
                field("Item.""Qty. on Job Order"""; Rec."Qty. on Job Order")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Qty. on Job Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to jobs, meaning listed on outstanding job planning lines. The field is automatically updated based on the Remaining Qty. field in the Job Planning Lines window.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowJobPlanningLines(Item);
                    end;
                }
                field("Item.""Trans. Ord. Shipment (Qty.)"""; Rec."Trans. Ord. Shipment (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trans. Ord. Shipment (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Shipment (Qty.)"));
                    end;
                }
                field("Item.""Qty. in Transit"""; Rec."Qty. in Transit")
                {
                    ApplicationArea = Location;
                    Caption = 'Qty. in Transit';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that are currently in transit.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowTransLines(Item, Item.FieldNo("Qty. in Transit"));
                    end;
                }
                field("Item.""Trans. Ord. Receipt (Qty.)"""; Rec."Trans. Ord. Receipt (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trans. Ord. Receipt (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remain to be received but are not yet shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Receipt (Qty.)"));
                    end;
                }
                field("Item.""Qty. on Asm. Component"""; Rec."Qty. on Asm. Comp. Lines")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Qty. on Asm. Comp. Lines';
                    ToolTip = 'Specifies how many units of the item are allocated to assembly component orders.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
                    begin
                        ItemAvailFormsMgt.ShowAsmCompLines(Item);
                    end;
                }
                field("Item.""Qty. on Assembly Order"""; Rec."Qty. on Assembly Order")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Qty. on Assembly Order';
                    ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
                    begin
                        ItemAvailFormsMgt.ShowAsmOrders(Item);
                    end;
                }
                field(ExpectedInventory; "Expected Inventory")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Expected Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be available for the current assembly order on the due date.';
                    Visible = false;
                }
                field(QtyAvailable; "Available Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                    Visible = false;
                }
                field("Item.""Scheduled Receipt (Qty.)"""; Rec."Scheduled Receipt (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt (Qty.)';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item are scheduled for production orders. The program automatically calculates and updates the contents of the field, using the Remaining Quantity field on production order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSchedReceipt(Item);
                    end;
                }
                field("Item.""Scheduled Need (Qty.)"""; Rec."Scheduled Issue (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Issue (Qty.)';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies the sum of items from planned production orders.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSchedNeed(Item);
                    end;
                }
                field(PlannedOrderReleases; "Planned Order Releases")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Order Releases';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment order proposals, which include planned production orders and planning or requisition worksheets lines, that are calculated according to the starting date in the planning worksheet and production order or the order date in the requisition worksheet. This sum is not included in the projected available inventory. However, it indicates which quantities should be converted from planned to scheduled receipts.';
                    Visible = true;

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(3);
                    end;
                }
                field("Item.""Net Change"""; Rec."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies the net change in the inventory of the item during the period entered in the Date Filter field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get("Period Type", "Period Start") then;
        CalcAvailQuantities(Item);
    end;

    trigger OnInit()
    begin
        SetItemFilter();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Reset();
    end;

    var
        DateRec: Record Date;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        Item: Record Item;

    procedure SetLines(var NewItem: Record Item; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        Item.Copy(NewItem);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);

        OnAfterSet(Item, PeriodType.AsInteger(), AmountType);
    end;

    local procedure SetItemFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Item.SetRange("Date Filter", "Period Start", "Period End")
        else
            Item.SetRange("Date Filter", 0D, "Period End");
        OnAfterSetItemFilter(Item, "Period Start", "Period End");
    end;

    local procedure ShowItemAvailLineList(What: Integer)
    begin
        SetItemFilter();
        ItemAvailFormsMgt.ShowItemAvailLineList(Item, What);
    end;

    local procedure CalcAvailQuantities(var Item: Record Item)
    var
        DummyQtyAvailable: Decimal;
    begin
        SetItemFilter();
        ItemAvailFormsMgt.CalcAvailQuantities(
          Item, AmountType = AmountType::"Balance at Date",
          "Gross Requirement", "Planned Order Receipt", "Scheduled Receipt",
          "Planned Order Releases", "Projected Available Balance", "Expected Inventory", DummyQtyAvailable, "Available Inventory");

        Inventory := Item.Inventory;
        "Qty. on Purch. Order" := Item."Qty. on Purch. Order";
        "Qty. on Sales Order" := Item."Qty. on Sales Order";
        "Qty. on Service Order" := Item."Qty. on Service Order";
        "Qty. on Job Order" := Item."Qty. on Job Order";
        "Trans. Ord. Shipment (Qty.)" := Item."Trans. Ord. Shipment (Qty.)";
        "Qty. in Transit" := Item."Qty. in Transit";
        "Trans. Ord. Receipt (Qty.)" := Item."Trans. Ord. Receipt (Qty.)";
        "Qty. on Asm. Comp. Lines" := Item."Qty. on Asm. Component";
        "Qty. on Assembly Order" := Item."Qty. on Assembly Order";
        "Scheduled Receipt (Qty.)" := Item."Scheduled Receipt (Qty.)";
        "Scheduled Issue (Qty.)" := Item."Qty. on Component Lines";
        "Net Change" := Item."Net Change";

        OnAfterCalcAvailQuantities(Rec, Item);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcAvailQuantities(var ItemAvailabilityBuffer: Record "Item Availability Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var Item: Record Item; PeriodType: Integer; AmountType: Enum "Analysis Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilter(var Item: Record Item; PeriodStart: Date; PeriodEnd: Date)
    begin
    end;
}

