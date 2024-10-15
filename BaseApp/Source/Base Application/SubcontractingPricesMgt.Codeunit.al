codeunit 12153 SubcontractingPricesMgt
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SubcontractorPrices: Record "Subcontractor Prices";
        PricelistUOM: Code[10];
        PricelistQtyPerUOM: Decimal;
        PricelistQty: Decimal;
        PricelistCost: Decimal;
        DirectCost: Decimal;

    procedure RoutingPricelistCost(var InSubcPrices: Record "Subcontractor Prices"; WorkCenter: Record "Work Center"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit; QtyUoM: Decimal; ProdQtyPerUom: Decimal; QtyBase: Decimal)
    begin
        PricelistQtyPerUOM := 0;
        PricelistQty := 0;
        PricelistCost := 0;
        DirectCost := 0;
        PricelistUOM := '';

        UnitCostCalculation := WorkCenter."Unit Cost Calculation";
        IndirCostPct := WorkCenter."Indirect Cost %";
        OvhdRate := WorkCenter."Overhead Rate";
        if WorkCenter."Specific Unit Cost" then
            DirUnitCost := (UnitCost - OvhdRate) / (1 + IndirCostPct / 100)
        else begin
            DirUnitCost := WorkCenter."Direct Unit Cost";
            UnitCost := WorkCenter."Unit Cost";
        end;

        if InSubcPrices."Start Date" = 0D then
            InSubcPrices."Start Date" := WorkDate;

        SubcontractorPrices.Reset;
        SubcontractorPrices.SetRange("Vendor No.", InSubcPrices."Vendor No.");
        SubcontractorPrices.SetFilter("Work Center No.", '%1|%2', InSubcPrices."Work Center No.", '');
        SubcontractorPrices.SetRange("Standard Task Code", InSubcPrices."Standard Task Code");
        SubcontractorPrices.SetFilter("Item No.", '%1|%2', InSubcPrices."Item No.", '');
        SubcontractorPrices.SetRange("Start Date", 0D, InSubcPrices."Start Date");
        SubcontractorPrices.SetFilter("End Date", '>=%1|%2', InSubcPrices."Start Date", 0D);
        if SubcontractorPrices.FindLast then begin
            if SubcontractorPrices."Unit of Measure Code" = InSubcPrices."Unit of Measure Code" then begin
                PricelistQtyPerUOM := ProdQtyPerUom;
                PricelistQty := QtyUoM;
                PricelistUOM := SubcontractorPrices."Unit of Measure Code";
            end else
                GetUOMPrice(InSubcPrices."Item No.", QtyBase);

            GetPriceByUOM;
            if PricelistCost <> 0 then begin
                ConvertPriceToUOM(InSubcPrices."Unit of Measure Code", ProdQtyPerUom);
                if SubcontractorPrices."Currency Code" <> '' then
                    ConvertPriceFromCurrency(SubcontractorPrices."Currency Code", InSubcPrices."Start Date");
                GLSetup.Get;
                DirectCost := Round(DirectCost, GLSetup."Unit-Amount Rounding Precision");
                DirUnitCost := DirectCost;
                UnitCost := (DirUnitCost * (1 + IndirCostPct / 100) + OvhdRate);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetUOMPrice(ItemNo: Code[20]; QtyBase: Decimal)
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ItemNo);
        PricelistQtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, SubcontractorPrices."Unit of Measure Code");

        if (PricelistQtyPerUOM = 1) and (SubcontractorPrices."Unit of Measure Code" = '') then
            PricelistUOM := Item."Base Unit of Measure"
        else
            PricelistUOM := SubcontractorPrices."Unit of Measure Code";

        PricelistQty := QtyBase / PricelistQtyPerUOM;
    end;

    [Scope('OnPrem')]
    procedure GetPriceByUOM()
    begin
        with SubcontractorPrices do begin
            SetRange("Minimum Quantity", 0, PricelistQty);
            SetRange("Unit of Measure Code", "Unit of Measure Code");
            if FindLast then begin
                PricelistCost := "Direct Unit Cost";
                if PricelistCost <> 0 then
                    if (PricelistCost * PricelistQty) < "Minimum Amount" then
                        PricelistCost := "Minimum Amount" / PricelistQty;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceToUOM(ProdUOM: Code[10]; ProdQtyPerUoM: Decimal)
    begin
        if ProdUOM <> PricelistUOM then begin
            DirectCost := PricelistCost / PricelistQtyPerUOM;
            DirectCost := DirectCost * ProdQtyPerUoM;
        end else
            DirectCost := PricelistCost;
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceToCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CurrencyCode);
        DirectCost := CurrExchRate.ExchangeAmtLCYToFCY(
            WorkDate, CurrencyCode, DirectCost,
            CurrExchRate.ExchangeRate(WorkDate, CurrencyCode));
        Currency.TestField("Unit-Amount Rounding Precision");
        DirectCost := Round(PricelistCost, Currency."Unit-Amount Rounding Precision");
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceFromCurrency(CurrencyCode: Code[10]; OrderDate: Date)
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CurrencyCode);
        DirectCost := CurrExchRate.ExchangeAmtFCYToLCY(
            OrderDate, CurrencyCode, DirectCost,
            CurrExchRate.ExchangeRate(OrderDate, CurrencyCode));
    end;

    procedure GetSubcPriceForReqLine(var ReqLine: Record "Requisition Line"; FixedUOM: Code[10])
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        OrderDate: Date;
    begin
        PricelistQtyPerUOM := 0;
        PricelistQty := 0;
        PricelistCost := 0;
        DirectCost := 0;
        PricelistUOM := '';

        with ReqLine do begin
            OrderDate := "Order Date";
            if OrderDate = 0D then
                OrderDate := WorkDate;

            SubcontractorPrices.SetRange("Vendor No.", "Vendor No.");
            SubcontractorPrices.SetFilter("Work Center No.", '%1|%2', "Work Center No.", '');
            SubcontractorPrices.SetRange("Standard Task Code", "Standard Task Code");
            SubcontractorPrices.SetRange("Variant Code", "Variant Code");
            SubcontractorPrices.SetFilter("Item No.", '%1|%2', "No.", '');
            SubcontractorPrices.SetRange("Start Date", 0D, OrderDate);
            SubcontractorPrices.SetFilter("End Date", '>=%1|%2', OrderDate, 0D);
            SubcontractorPrices.SetFilter("Currency Code", '%1|%2', "Currency Code", '');
            if FixedUOM <> '' then
                SubcontractorPrices.SetRange("Unit of Measure Code", FixedUOM);

            if SubcontractorPrices.FindLast then begin
                if SubcontractorPrices."Unit of Measure Code" = "Unit of Measure Code" then begin
                    PricelistQtyPerUOM := GetQtyForUOM;
                    PricelistQty := Quantity;
                    PricelistUOM := "Unit of Measure Code";
                end else
                    GetUOMPrice("No.", GetQtyBase);

                GetPriceByUOM;
                if PricelistCost <> 0 then begin
                    ConvertPriceToUOM("Unit of Measure Code", GetQtyForUOM);
                    if ("Currency Code" <> '') and
                       ("Currency Code" <> SubcontractorPrices."Currency Code")
                    then
                        ConvertPriceToCurrency("Currency Code")
                    else begin
                        GLSetup.Get;
                        DirectCost := Round(DirectCost, GLSetup."Unit-Amount Rounding Precision");
                    end;
                end;
            end else begin
                if FixedUOM <> '' then begin
                    SubcontractorPrices."Unit of Measure Code" := FixedUOM;
                    PricelistUOM := FixedUOM;
                    GetUOMPrice("No.", GetQtyBase);
                end;
                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.", "Operation No.");
                ProdOrderRtngLine.TestField(Type,
                  ProdOrderRtngLine.Type::"Work Center");
                DirectCost := ProdOrderRtngLine."Direct Unit Cost";
            end;
            "Direct Unit Cost" := DirectCost;
            "Pricelist Cost" := PricelistCost;
            "UoM for Pricelist" := PricelistUOM;
            "Base UM Qty/Pricelist UM Qty" := PricelistQtyPerUOM;
            if "Base UM Qty/Pricelist UM Qty" = 0 then
                "Base UM Qty/Pricelist UM Qty" := 1;
            if "Unit of Measure Code" = "UoM for Pricelist" then
                "Pricelist UM Qty/Base UM Qty" := Quantity
            else
                "Pricelist UM Qty/Base UM Qty" := GetQtyBase / "Base UM Qty/Pricelist UM Qty";
            if "Pricelist UM Qty/Base UM Qty" = 0 then
                "Pricelist UM Qty/Base UM Qty" := 1;
        end;
    end;
}

