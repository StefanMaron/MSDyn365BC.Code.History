namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;

page 5417 "Item Avail. by UOM Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Item Unit of Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify the unit of measure.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(GrossRequirement; AdjustQty(GrossRequirement))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of all demand for the item.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(0);
                    end;
                }
                field(ScheduledRcpt; AdjustQty(ScheduledRcpt))
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
                field(PlannedOrderRcpt; AdjustQty(PlannedOrderRcpt))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity on planned production orders plus planning worksheet lines plus requisition worksheet lines.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(1);
                    end;
                }
                field("Item.Inventory"; AdjustQty(Item.Inventory))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the inventory level of an item.';

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                    end;
                }
                field(ProjAvailableBalance; AdjustQty(ProjAvailableBalance))
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
                field("Item.""Qty. on Purch. Order"""; AdjustQty(Item."Qty. on Purch. Order"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Purch. Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are inbound on purchase orders, meaning listed on outstanding purchase order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowPurchLines(Item);
                    end;
                }
                field("Item.""Qty. on Sales Order"""; AdjustQty(Item."Qty. on Sales Order"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Sales Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are allocated to sales orders, meaning listed on outstanding sales orders lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSalesLines(Item);
                    end;
                }
                field("Item.""Qty. on Service Order"""; AdjustQty(Item."Qty. on Service Order"))
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
                field("Item.""Qty. on Job Order"""; AdjustQty(Item."Qty. on Job Order"))
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
                field("Item.""Trans. Ord. Shipment (Qty.)"""; AdjustQty(Item."Trans. Ord. Shipment (Qty.)"))
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
                field("Item.""Qty. on Asm. Component"""; AdjustQty(Item."Qty. on Asm. Component"))
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
                field("Item.""Qty. on Assembly Order"""; AdjustQty(Item."Qty. on Assembly Order"))
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
                field("Item.""Qty. in Transit"""; AdjustQty(Item."Qty. in Transit"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. in Transit';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that are currently in transit.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowTransLines(Item, Item.FieldNo("Qty. in Transit"));
                    end;
                }
                field("Item.""Trans. Ord. Receipt (Qty.)"""; AdjustQty(Item."Trans. Ord. Receipt (Qty.)"))
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
                field(ExpectedInventory; AdjustQty(ExpectedInventory))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expected Inventory';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be available for the current assembly order on the due date.';
                    Visible = false;
                }
                field(QtyAvailable; AdjustQty(QtyAvailable))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Qty. on Hand';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                    Visible = false;
                }
                field("Item.""Scheduled Receipt (Qty.)"""; AdjustQty(Item."Scheduled Receipt (Qty.)"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt (Qty.)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are scheduled for production orders. The program automatically calculates and updates the contents of the field, using the Remaining Quantity field on production order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSchedReceipt(Item);
                    end;
                }
                field("Item.""Scheduled Need (Qty.)"""; AdjustQty(Item."Qty. on Component Lines"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Component Lines';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of items from planned production orders.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowSchedNeed(Item);
                    end;
                }
                field(PlannedOrderReleases; AdjustQty(PlannedOrderReleases))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Order Releases';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment order proposals, which include planned production orders and planning or requisition worksheets lines, that are calculated according to the starting date in the planning worksheet and production order or the order date in the requisition worksheet. This sum is not included in the projected available inventory. However, it indicates which quantities should be converted from planned to scheduled receipts.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(3);
                    end;
                }
                field("Item.""Net Change"""; AdjustQty(Item."Net Change"))
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
        CalcAvailQuantities(
          GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, QtyAvailable);
    end;

    trigger OnOpenPage()
    begin
        PeriodStart := 0D;
        PeriodEnd := DMY2Date(31, 12, 1999);
    end;

    protected var
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        AmountType: Enum "Analysis Amount Type";
        PeriodStart: Date;
        PeriodEnd: Date;
        ExpectedInventory: Decimal;
        QtyAvailable: Decimal;
        PlannedOrderReleases: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;
        ProjAvailableBalance: Decimal;

    local procedure AdjustQty(QtyInUoM: Decimal): Decimal;
    begin
        if Rec."Qty. per Unit of Measure" <> 0 then
            exit(QtyInUoM / Rec."Qty. per Unit of Measure");
    end;

    procedure Set(var NewItem: Record Item; NewAmountType: Enum "Analysis Amount Type")
    begin
        Item.Copy(NewItem);
        PeriodStart := Item.GetRangeMin("Date Filter");
        PeriodEnd := Item.GetRangeMax("Date Filter");
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetItemFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Item.SetRange("Date Filter", PeriodStart, PeriodEnd)
        else
            Item.SetRange("Date Filter", 0D, PeriodEnd);
        Item.SetRange("Unit of Measure Filter", Rec.Code);
    end;

    local procedure ShowItemAvailLineList(What: Integer)
    begin
        SetItemFilter();
        ItemAvailFormsMgt.SetQtyByUnitOfMeasure(Rec."Qty. per Unit of Measure");
        ItemAvailFormsMgt.ShowItemAvailLineList(Item, What);
    end;

    local procedure CalcAvailQuantities(var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal)
    var
        DummyQtyAvailable: Decimal;
    begin
        SetItemFilter();
        ItemAvailFormsMgt.CalcAvailQuantities(
          Item, AmountType = AmountType::"Balance at Date",
          GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, DummyQtyAvailable, AvailableInventory);
    end;
}

