report 705 "Inventory Availability"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryAvailability.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Availability';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = WHERE(Type = CONST(Inventory));
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Vendor No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(TableItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(GetCurrentKey; GetCurrentKey)
            {
            }
            column(UseStockkeepingUnit; UseStockkeepingUnit)
            {
            }
            column(InventPostGroup_Item; "Inventory Posting Group")
            {
            }
            column(InvtReorder; Format(InvtReorder))
            {
            }
            column(ReorderPoint_Item; "Reorder Point")
            {
                IncludeCaption = true;
            }
            column(ProjAvailBalance; ProjAvailBalance)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlannedOrderReceipt; PlannedOrderReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BackOrderQty; BackOrderQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ScheduledReceipt; ScheduledReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossRequirement; GrossRequirement)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(InventoryAvailabilityCaption; InventoryAvailabilityCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BOMCaption; BOMCaptionLbl)
            {
            }
            column(GrossRequirementCaption; GrossRequirementCaptionLbl)
            {
            }
            column(ScheduledReceiptCaption; ScheduledReceiptCaptionLbl)
            {
            }
            column(PlannedOrderReceiptCaption; PlannedOrderReceiptCaptionLbl)
            {
            }
            column(QuantityOnBackOrderCaption; QuantityOnBackOrderCaptionLbl)
            {
            }
            column(ProjectedAvailableBalCaption; ProjectedAvailableBalCaptionLbl)
            {
            }
            column(ReorderCaption; ReorderCaptionLbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = FIELD("No."), "Location Code" = FIELD("Location Filter"), "Variant Code" = FIELD("Variant Filter");
                DataItemTableView = SORTING("Item No.", "Location Code", "Variant Code");
                column(AssemblyBOMStock_Item; Format(Item."Assembly BOM"))
                {
                }
                column(UnitofMeasure_Item; Item."Base Unit of Measure")
                {
                }
                column(InvtReorder2; Format(InvtReorder))
                {
                }
                column(ReordPoint_StockkeepUnit; "Reorder Point")
                {
                }
                column(ProjAvailBalance2; ProjAvailBalance)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(BackOrderQty2; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(PlannedOrderReceipt2; PlannedOrderReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ScheduledReceipt2; ScheduledReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GrossRequirement2; GrossRequirement)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VariantCode_StockkeepUnit; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(LocCode_StockkeepUnit; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(SKUPrintLoop; SKUPrintLoop)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SKUPrintLoop := SKUPrintLoop + 1;
                    if "Reordering Policy" in ["Reordering Policy"::Order, "Reordering Policy"::"Lot-for-Lot"] then
                        "Reorder Point" := 0;
                    CalcNeed(Item, "Location Code", "Variant Code", "Reorder Point");
                end;

                trigger OnPreDataItem()
                begin
                    if not UseStockkeepingUnit then
                        CurrReport.Break();

                    SKUPrintLoop := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not UseStockkeepingUnit then begin
                    if "Reordering Policy" in ["Reordering Policy"::Order, "Reordering Policy"::"Lot-for-Lot"] then
                        "Reorder Point" := 0;
                    CalcNeed(Item, GetFilter("Location Filter"), GetFilter("Variant Filter"), "Reorder Point");
                end;
            end;

            trigger OnPreDataItem()
            begin
                GetCurrentKey := CurrentKey;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseStockkeepingUnit; UseStockkeepingUnit)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want the report to list the availability of items by stockkeeping unit.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters;
    end;

    var
        AvailToPromise: Codeunit "Available to Promise";
        ItemFilter: Text;
        BackOrderQty: Decimal;
        InvtReorder: Boolean;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        ProjAvailBalance: Decimal;
        UseStockkeepingUnit: Boolean;
        SKUPrintLoop: Integer;
        GetCurrentKey: Text[250];
        InventoryAvailabilityCaptionLbl: Label 'Inventory Availability';
        PageCaptionLbl: Label 'Page';
        BOMCaptionLbl: Label 'BOM';
        GrossRequirementCaptionLbl: Label 'Gross Requirement';
        ScheduledReceiptCaptionLbl: Label 'Scheduled Receipt';
        PlannedOrderReceiptCaptionLbl: Label 'Planned Order Receipt';
        QuantityOnBackOrderCaptionLbl: Label 'Quantity on Back Order';
        ProjectedAvailableBalCaptionLbl: Label 'Projected Available Balance';
        ReorderCaptionLbl: Label 'Reorder';

    procedure CalcNeed(Item: Record Item; LocationFilter: Text[250]; VariantFilter: Text[250]; ReorderPoint: Decimal)
    begin
        with Item do begin
            SetFilter("Location Filter", LocationFilter);
            SetFilter("Variant Filter", VariantFilter);
            SetRange("Drop Shipment Filter", false);

            SetRange("Date Filter", 0D, WorkDate);
            CalcFields(
              "Qty. on Purch. Order",
              "Planning Receipt (Qty.)",
              "Scheduled Receipt (Qty.)",
              "Planned Order Receipt (Qty.)",
              "Purch. Req. Receipt (Qty.)",
              "Qty. in Transit",
              "Trans. Ord. Receipt (Qty.)",
              "Reserved Qty. on Inventory");
            BackOrderQty :=
              "Qty. on Purch. Order" + "Scheduled Receipt (Qty.)" + "Planned Order Receipt (Qty.)" +
              "Qty. in Transit" + "Trans. Ord. Receipt (Qty.)" +
              "Planning Receipt (Qty.)" + "Purch. Req. Receipt (Qty.)";

            SetRange("Date Filter", 0D, DMY2Date(31, 12, 9999));
            GrossRequirement :=
              AvailToPromise.CalcGrossRequirement(Item);
            ScheduledReceipt :=
              AvailToPromise.CalcScheduledReceipt(Item);

            CalcFields(
              Inventory,
              "Planning Receipt (Qty.)",
              "Planned Order Receipt (Qty.)",
              "Purch. Req. Receipt (Qty.)",
              "Res. Qty. on Req. Line");

            ScheduledReceipt := ScheduledReceipt - "Planned Order Receipt (Qty.)";

            PlannedOrderReceipt :=
              "Planned Order Receipt (Qty.)" +
              "Purch. Req. Receipt (Qty.)";

            ProjAvailBalance :=
              Inventory +
              ScheduledReceipt -
              GrossRequirement +
              "Purch. Req. Receipt (Qty.)" -
              "Res. Qty. on Req. Line";

            InvtReorder := ProjAvailBalance < ReorderPoint;
        end;
    end;

    procedure InitializeRequest(NewUseStockkeepingUnit: Boolean)
    begin
        UseStockkeepingUnit := NewUseStockkeepingUnit;
    end;
}

