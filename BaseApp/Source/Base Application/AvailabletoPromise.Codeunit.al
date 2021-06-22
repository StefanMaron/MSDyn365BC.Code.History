codeunit 5790 "Available to Promise"
{
    Permissions = TableData "Prod. Order Line" = r,
                  TableData "Prod. Order Component" = r;

    trigger OnRun()
    begin
    end;

    var
        ChangedSalesLine: Record "Sales Line";
        ChangedAssemblyLine: Record "Assembly Line";
        OldRecordExists: Boolean;
        ReqShipDate: Date;
        AllFieldCalculated: Boolean;
        PrevItemNo: Code[20];
        PrevItemFilters: Text;

    procedure QtyAvailabletoPromise(var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; AvailabilityDate: Date; PeriodType: Option Day,Week,Month,Quarter,Year; LookaheadDateFormula: DateFormula) AvailableToPromise: Decimal
    begin
        OnBeforeQtyAvailableToPromise(Item, AvailabilityDate);

        ScheduledReceipt := CalcScheduledReceipt(Item);
        GrossRequirement := CalcGrossRequirement(Item);

        if AvailabilityDate <> 0D then
            GrossRequirement :=
              GrossRequirement +
              CalculateLookahead(
                Item, PeriodType,
                AvailabilityDate + 1,
                GetLookAheadPeriodEndDate(LookaheadDateFormula, PeriodType, AvailabilityDate));

        AvailableToPromise :=
          CalcAvailableInventory(Item) +
          (ScheduledReceipt - CalcReservedReceipt(Item)) -
          (GrossRequirement - CalcReservedRequirement(Item));

        OnAfterQtyAvailableToPromise(Item, ScheduledReceipt, GrossRequirement, AvailableToPromise);

        exit(AvailableToPromise);
    end;

    procedure CalcAvailableInventory(var Item: Record Item): Decimal
    var
        AvailableInventory: Decimal;
    begin
        CalcAllItemFields(Item);
        AvailableInventory := Item.Inventory - Item."Reserved Qty. on Inventory";
        OnAfterCalcAvailableInventory(Item, AvailableInventory);
        exit(AvailableInventory);
    end;

    procedure CalcGrossRequirement(var Item: Record Item) GrossRequirement: Decimal
    begin
        CalcAllItemFields(Item);
        OnBeforeCalcGrossRequirement(Item);

        with Item do begin
            GrossRequirement :=
              "Scheduled Need (Qty.)" +
              "Planning Issues (Qty.)" +
              "Planning Transfer Ship. (Qty)." +
              "Qty. on Sales Order" +
              "Qty. on Service Order" +
              "Qty. on Job Order" +
              "Trans. Ord. Shipment (Qty.)" +
              "Qty. on Asm. Component" +
              "Qty. on Purch. Return";

            OnAfterCalcGrossRequirement(Item, GrossRequirement);

            exit(GrossRequirement);
        end;
    end;

    procedure CalcReservedRequirement(var Item: Record Item) ReservedRequirement: Decimal
    begin
        CalcAllItemFields(Item);
        with Item do begin
            ReservedRequirement :=
              "Res. Qty. on Prod. Order Comp." +
              "Reserved Qty. on Sales Orders" +
              "Res. Qty. on Service Orders" +
              "Res. Qty. on Job Order" +
              "Res. Qty. on Outbound Transfer" +
              "Res. Qty. on  Asm. Comp." +
              "Res. Qty. on Purch. Returns";

            OnAfterCalcReservedRequirement(Item, ReservedRequirement);

            exit(ReservedRequirement);
        end;
    end;

    procedure CalcScheduledReceipt(var Item: Record Item) ScheduledReceipt: Decimal
    begin
        CalcAllItemFields(Item);
        OnBeforeCalcScheduledReceipt(Item);

        with Item do begin
            ScheduledReceipt :=
              "Scheduled Receipt (Qty.)" +
              "Planned Order Receipt (Qty.)" +
              "Qty. on Purch. Order" +
              "Trans. Ord. Receipt (Qty.)" +
              "Qty. in Transit" +
              "Qty. on Assembly Order" +
              "Qty. on Sales Return";

            OnAfterCalcScheduledReceipt(Item, ScheduledReceipt);

            exit(ScheduledReceipt);
        end;
    end;

    procedure CalcReservedReceipt(var Item: Record Item) ReservedReceipt: Decimal
    begin
        CalcAllItemFields(Item);

        with Item do begin
            ReservedReceipt :=
              "Reserved Qty. on Prod. Order" +
              "Reserved Qty. on Purch. Orders" +
              "Res. Qty. on Inbound Transfer" +
              "Res. Qty. on Assembly Order" +
              "Res. Qty. on Sales Returns";

            OnAfterCalcReservedReceipt(Item, ReservedReceipt);

            exit(ReservedReceipt);
        end;
    end;

    procedure EarliestAvailabilityDate(var Item: Record Item; NeededQty: Decimal; StartDate: Date; ExcludeQty: Decimal; ExcludeOnDate: Date; var AvailableQty: Decimal; PeriodType: Option Day,Week,Month,Quarter,Year; LookaheadDateFormula: DateFormula): Date
    var
        Date: Record Date;
        DummyItem: Record Item;
        AvailabilityAtDate: Record "Availability at Date" temporary;
        CalendarManagement: Codeunit "Calendar Management";
        QtyIsAvailable: Boolean;
        ExactDateFound: Boolean;
        ScheduledReceipt: Decimal;
        GrossRequirement: Decimal;
        AvailableQtyPeriod: Decimal;
        AvailableDate: Date;
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        AvailableQty := 0;

        Item.CopyFilter("Date Filter", DummyItem."Date Filter");
        Item.SetRange("Date Filter", 0D, GetLookAheadPeriodEndDate(LookaheadDateFormula, PeriodType, StartDate));
        CalculateAvailability(Item, AvailabilityAtDate);
        UpdateScheduledReceipt(AvailabilityAtDate, ExcludeOnDate, ExcludeQty);
        CalculateAvailabilityByPeriod(AvailabilityAtDate, PeriodType);

        Date.SetRange("Period Type", PeriodType);
        Date.SetRange("Period Start", 0D, StartDate);
        if Date.FindLast then begin
            AvailabilityAtDate.SetRange("Period Start", 0D, Date."Period Start");
            if AvailabilityAtDate.FindSet then
                repeat
                    if PeriodStart = 0D then
                        PeriodStart := AvailabilityAtDate."Period Start";
                    ScheduledReceipt += AvailabilityAtDate."Scheduled Receipt";
                    GrossRequirement += AvailabilityAtDate."Gross Requirement";
                until AvailabilityAtDate.Next = 0;
            AvailableQty := Item.Inventory - Item."Reserved Qty. on Inventory" + ScheduledReceipt - GrossRequirement;
            if AvailableQty >= NeededQty then begin
                QtyIsAvailable := true;
                AvailableDate := Date."Period End";
                PeriodEnd := Date."Period End";
            end else
                PeriodStart := 0D;
        end;

        if Format(LookaheadDateFormula) = '' then
            AvailabilityAtDate.SetRange("Period Start", StartDate + 1, CalendarManagement.GetMaxDate)
        else
            AvailabilityAtDate.SetRange("Period Start", StartDate + 1, CalcDate(LookaheadDateFormula, StartDate));

        AvailabilityAtDate."Period Start" := 0D;
        while AvailabilityAtDate.Next <> 0 do begin
            AvailableQtyPeriod := AvailabilityAtDate."Scheduled Receipt" - AvailabilityAtDate."Gross Requirement";
            if AvailabilityAtDate."Scheduled Receipt" <= AvailabilityAtDate."Gross Requirement" then begin
                AvailableQty := AvailableQty + AvailableQtyPeriod;
                AvailableDate := AvailabilityAtDate."Period End";
                if AvailableQty < NeededQty then
                    QtyIsAvailable := false;
            end else
                if QtyIsAvailable then
                    AvailabilityAtDate.FindLast
                else begin
                    AvailableQty := AvailableQty + AvailableQtyPeriod;
                    if AvailableQty >= NeededQty then begin
                        QtyIsAvailable := true;
                        AvailableDate := AvailabilityAtDate."Period End";
                        PeriodStart := AvailabilityAtDate."Period Start";
                        PeriodEnd := AvailabilityAtDate."Period End";
                        AvailabilityAtDate.FindLast;
                    end;
                end;
        end;

        if QtyIsAvailable then begin
            if PeriodType <> PeriodType::Day then begin
                Item.SetRange("Date Filter", PeriodStart, PeriodEnd);
                CalculateAvailability(Item, AvailabilityAtDate);
                if (ExcludeOnDate >= PeriodStart) and (ExcludeOnDate <= PeriodEnd) then
                    UpdateScheduledReceipt(AvailabilityAtDate, ExcludeOnDate, ExcludeQty);
            end;
            AvailabilityAtDate.SetRange("Period Start", PeriodStart, PeriodEnd);
            if AvailabilityAtDate.Find('+') then
                repeat
                    if (AvailableQty - AvailabilityAtDate."Scheduled Receipt") < NeededQty then begin
                        ExactDateFound := true;
                        AvailableDate := AvailabilityAtDate."Period Start";
                    end else
                        AvailableQty := AvailableQty - AvailabilityAtDate."Scheduled Receipt";
                until (AvailabilityAtDate.Next(-1) = 0) or ExactDateFound;
            if not ExactDateFound then begin
                AvailableDate := StartDate;
                if AvailabilityAtDate.Find then
                    AvailableQty := AvailableQty + AvailabilityAtDate."Scheduled Receipt";
            end;
        end else
            AvailableDate := 0D;

        DummyItem.CopyFilter("Date Filter", Item."Date Filter");
        exit(AvailableDate);
    end;

    procedure CalculateLookahead(var Item: Record Item; PeriodType: Option Day,Week,Month,Quarter,Year; StartDate: Date; EndDate: Date): Decimal
    var
        DummyItem: Record Item;
        AvailabilityAtDate: Record "Availability at Date" temporary;
        LookaheadQty: Decimal;
        Stop: Boolean;
    begin
        Item.CopyFilter("Date Filter", DummyItem."Date Filter");
        Item.SetRange("Date Filter", StartDate, EndDate);
        CalculateAvailability(Item, AvailabilityAtDate);
        CalculateAvailabilityByPeriod(AvailabilityAtDate, PeriodType);
        AvailabilityAtDate.SetRange("Period Start", 0D, StartDate - 1);
        if AvailabilityAtDate.FindSet then
            repeat
                LookaheadQty += AvailabilityAtDate."Gross Requirement" - AvailabilityAtDate."Scheduled Receipt";
            until AvailabilityAtDate.Next = 0;

        AvailabilityAtDate.SetRange("Period Start", StartDate, EndDate);
        if AvailabilityAtDate.FindSet then
            repeat
                if AvailabilityAtDate."Gross Requirement" > AvailabilityAtDate."Scheduled Receipt" then
                    LookaheadQty += AvailabilityAtDate."Gross Requirement" - AvailabilityAtDate."Scheduled Receipt"
                else
                    if AvailabilityAtDate."Gross Requirement" < AvailabilityAtDate."Scheduled Receipt" then
                        Stop := true;
            until (AvailabilityAtDate.Next = 0) or Stop;

        if LookaheadQty < 0 then
            LookaheadQty := 0;

        DummyItem.CopyFilter("Date Filter", Item."Date Filter");
        exit(LookaheadQty);
    end;

    procedure CalculateAvailability(var Item: Record Item; var AvailabilityAtDate: Record "Availability at Date")
    var
        Item2: Record Item;
    begin
        Item2.CopyFilters(Item);
        Item.SetRange("Bin Filter");
        Item.SetRange("Global Dimension 1 Filter");
        Item.SetRange("Global Dimension 2 Filter");

        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");

        AvailabilityAtDate.Reset();
        AvailabilityAtDate.DeleteAll();
        OldRecordExists := false;

        UpdateSchedRcptAvail(AvailabilityAtDate, Item);
        UpdatePurchReqRcptAvail(AvailabilityAtDate, Item);
        UpdatePurchOrderAvail(AvailabilityAtDate, Item);
        UpdateTransOrderRcptAvail(AvailabilityAtDate, Item);
        UpdateSchedNeedAvail(AvailabilityAtDate, Item);
        UpdatePlanningIssuesAvail(AvailabilityAtDate, Item);
        UpdateSalesOrderAvail(AvailabilityAtDate, Item);
        UpdateServOrderAvail(AvailabilityAtDate, Item);
        UpdateJobOrderAvail(AvailabilityAtDate, Item);
        UpdateTransOrderShptAvail(AvailabilityAtDate, Item);
        UpdateAsmOrderAvail(AvailabilityAtDate, Item);
        UpdateAsmCompAvail(AvailabilityAtDate, Item);

        OnAfterCalculateAvailability(AvailabilityAtDate, Item);

        Item.CopyFilters(Item2);
    end;

    procedure UpdateScheduledReceipt(var AvailabilityAtDate: Record "Availability at Date"; ReceiptDate: Date; ScheduledReceipt: Decimal)
    begin
        UpdateAvailability(AvailabilityAtDate, ReceiptDate, ScheduledReceipt, 0);
    end;

    procedure UpdateGrossRequirement(var AvailabilityAtDate: Record "Availability at Date"; ShipmentDate: Date; GrossRequirement: Decimal)
    begin
        UpdateAvailability(AvailabilityAtDate, ShipmentDate, 0, GrossRequirement);
    end;

    local procedure UpdateAvailability(var AvailabilityAtDate: Record "Availability at Date"; Date: Date; ScheduledReceipt: Decimal; GrossRequirement: Decimal)
    var
        RecordExists: Boolean;
    begin
        if (ScheduledReceipt = 0) and (GrossRequirement = 0) then
            exit;

        if OldRecordExists and (Date = AvailabilityAtDate."Period Start") then
            RecordExists := true
        else begin
            AvailabilityAtDate."Period Start" := Date;
            if AvailabilityAtDate.Find then
                RecordExists := true
            else begin
                AvailabilityAtDate.Init();
                AvailabilityAtDate."Period End" := Date;
            end;
        end;

        AvailabilityAtDate."Scheduled Receipt" += ScheduledReceipt;
        AvailabilityAtDate."Gross Requirement" += GrossRequirement;

        if RecordExists then
            AvailabilityAtDate.Modify
        else
            AvailabilityAtDate.Insert();

        OldRecordExists := true;
    end;

    local procedure CalculateAvailabilityByPeriod(var AvailabilityAtDate: Record "Availability at Date"; PeriodType: Option Day,Week,Month,Quarter,Year)
    var
        AvailabilityInPeriod: Record "Availability at Date";
        Date: Record Date;
    begin
        if PeriodType = PeriodType::Day then
            exit;

        if AvailabilityAtDate.FindSet then
            repeat
                Date.SetRange("Period Type", PeriodType);
                Date."Period Type" := PeriodType;
                Date."Period Start" := AvailabilityAtDate."Period Start";
                if Date.Find('=<') then begin
                    AvailabilityAtDate.SetRange("Period Start", Date."Period Start", Date."Period End");
                    AvailabilityInPeriod.Init();
                    AvailabilityInPeriod."Period Start" := Date."Period Start";
                    AvailabilityInPeriod."Period End" := NormalDate(Date."Period End");
                    repeat
                        AvailabilityInPeriod."Scheduled Receipt" += AvailabilityAtDate."Scheduled Receipt";
                        AvailabilityInPeriod."Gross Requirement" += AvailabilityAtDate."Gross Requirement";
                        AvailabilityAtDate.Delete();
                    until AvailabilityAtDate.Next = 0;
                    AvailabilityAtDate.SetRange("Period Start");
                    AvailabilityAtDate := AvailabilityInPeriod;
                    AvailabilityAtDate.Insert();
                end;
            until AvailabilityAtDate.Next = 0;
    end;

    procedure GetLookAheadPeriodEndDate(LookaheadDateFormula: DateFormula; PeriodType: Option; StartDate: Date): Date
    var
        CalendarManagement: Codeunit "Calendar Management";
    begin
        if Format(LookaheadDateFormula) = '' then
            exit(CalendarManagement.GetMaxDate);

        exit(AdjustedEndingDate(CalcDate(LookaheadDateFormula, StartDate), PeriodType));
    end;

    procedure AdjustedEndingDate(PeriodEnd: Date; PeriodType: Option Day,Week,Month,Quarter,Year): Date
    var
        Date: Record Date;
    begin
        if PeriodType = PeriodType::Day then
            exit(PeriodEnd);

        Date.SetRange("Period Type", PeriodType);
        Date.SetRange("Period Start", 0D, PeriodEnd);
        Date.FindLast;
        exit(NormalDate(Date."Period End"));
    end;

    procedure SetPromisingReqShipDate(OrderPromisingLine: Record "Order Promising Line")
    begin
        ReqShipDate := OrderPromisingLine."Requested Shipment Date";
    end;

    procedure SetChangedSalesLine(SalesLine: Record "Sales Line")
    begin
        ChangedSalesLine := SalesLine;
    end;

    procedure SetChangedAsmLine(AssemblyLine: Record "Assembly Line")
    begin
        ChangedAssemblyLine := AssemblyLine;
    end;

    local procedure CalcReqShipDate(SalesLine: Record "Sales Line"): Date
    begin
        if SalesLine."Requested Delivery Date" = 0D then
            exit(SalesLine."Shipment Date");

        SalesLine."Planned Delivery Date" := SalesLine."Requested Delivery Date";
        if Format(SalesLine."Shipping Time") <> '' then
            SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedDeliveryDate(SalesLine.FieldNo("Planned Delivery Date"))
        else
            SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedShptDate(SalesLine.FieldNo("Planned Delivery Date"));
        exit(SalesLine.CalcShipmentDate);
    end;

    local procedure CalcAllItemFields(var Item: Record Item)
    begin
        if AllFieldCalculated and (PrevItemNo = Item."No.") and (PrevItemFilters = Item.GetFilters) then
            exit;

        Item.CalcFields(
          Inventory, "Reserved Qty. on Inventory",
          "Scheduled Need (Qty.)",
          "Planning Issues (Qty.)",
          "Planning Transfer Ship. (Qty).",
          "Qty. on Sales Order",
          "Qty. on Service Order",
          "Qty. on Job Order",
          "Trans. Ord. Shipment (Qty.)",
          "Qty. on Asm. Component",
          "Qty. on Purch. Return",
          "Res. Qty. on Prod. Order Comp.",
          "Reserved Qty. on Sales Orders",
          "Res. Qty. on Service Orders",
          "Res. Qty. on Job Order",
          "Res. Qty. on Outbound Transfer",
          "Res. Qty. on  Asm. Comp.",
          "Res. Qty. on Purch. Returns");
        // Max function parameters is 20, hence split in 2
        Item.CalcFields(
          "Scheduled Receipt (Qty.)",
          "Planned Order Receipt (Qty.)",
          "Qty. on Purch. Order",
          "Trans. Ord. Receipt (Qty.)",
          "Qty. in Transit",
          "Qty. on Assembly Order",
          "Qty. on Sales Return",
          "Reserved Qty. on Purch. Orders",
          "Res. Qty. on Inbound Transfer",
          "Res. Qty. on Assembly Order",
          "Res. Qty. on Sales Returns",
          "Reserved Qty. on Prod. Order");

        AllFieldCalculated := true;
        PrevItemNo := Item."No.";
        PrevItemFilters := Item.GetFilters;
    end;

    procedure ResetItemNo()
    begin
        PrevItemNo := '';
    end;

    local procedure UpdateSchedRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with ProdOrderLine do
            if FindLinesWithItemToPlan(Item, true) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Due Date", "Remaining Qty. (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdatePurchReqRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        ReqLine: Record "Requisition Line";
    begin
        with ReqLine do begin
            if FindLinesWithItemToPlan(Item) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Due Date", "Quantity (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
        end;
    end;

    local procedure UpdatePurchOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Expected Receipt Date", "Outstanding Qty. (Base)" - "Reserved Qty. (Base)");
                until Next = 0;

            if FindLinesWithItemToPlan(Item, "Document Type"::"Return Order") then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Expected Receipt Date", "Outstanding Qty. (Base)" - "Reserved Qty. (Base)")
                until Next = 0;
        end;
    end;

    local procedure UpdateTransOrderRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        TransLine: Record "Transfer Line";
    begin
        with TransLine do
            if FindLinesWithItemToPlan(Item, true, false) then
                repeat
                    CalcFields("Reserved Qty. Inbnd. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Receipt Date",
                      "Outstanding Qty. (Base)" + "Qty. Shipped (Base)" - "Qty. Received (Base)" - "Reserved Qty. Inbnd. (Base)");
                until Next = 0;
    end;

    local procedure UpdateSchedNeedAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        with ProdOrderComp do
            if FindLinesWithItemToPlan(Item, true) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Due Date", "Remaining Qty. (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdatePlanningIssuesAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        PlanningComp: Record "Planning Component";
    begin
        with PlanningComp do
            if FindLinesWithItemToPlan(Item) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Due Date", "Expected Quantity (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdateSalesOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    if not IsSalesLineChanged(SalesLine) and
                       ((ReqShipDate = 0D) or (CalcReqShipDate(SalesLine) <= ReqShipDate))
                    then begin
                        CalcFields("Reserved Qty. (Base)");
                        UpdateGrossRequirement(AvailabilityAtDate, "Shipment Date", "Outstanding Qty. (Base)" - "Reserved Qty. (Base)")
                    end
                until Next = 0;

            if FindLinesWithItemToPlan(Item, "Document Type"::"Return Order") then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Shipment Date", "Outstanding Qty. (Base)" - "Reserved Qty. (Base)")
                until Next = 0;
        end;
    end;

    local procedure UpdateServOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        ServLine: Record "Service Line";
    begin
        with ServLine do
            if FindLinesWithItemToPlan(Item) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Needed by Date", "Outstanding Qty. (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdateJobOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        with JobPlanningLine do
            if FindLinesWithItemToPlan(Item) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Planning Date", "Remaining Qty. (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdateTransOrderShptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        TransLine: Record "Transfer Line";
    begin
        with TransLine do
            if FindLinesWithItemToPlan(Item, false, false) then
                repeat
                    CalcFields("Reserved Qty. Outbnd. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, "Shipment Date", "Outstanding Qty. (Base)" - "Reserved Qty. Outbnd. (Base)");
                until Next = 0;
    end;

    local procedure UpdateAsmOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        AsmHeader: Record "Assembly Header";
    begin
        with AsmHeader do
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    UpdateScheduledReceipt(AvailabilityAtDate, "Due Date", "Remaining Quantity (Base)" - "Reserved Qty. (Base)");
                until Next = 0;
    end;

    local procedure UpdateAsmCompAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        AsmLine: Record "Assembly Line";
    begin
        with AsmLine do
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    if not IsAsmLineChanged(AsmLine) then begin
                        CalcFields("Reserved Qty. (Base)");
                        UpdateGrossRequirement(AvailabilityAtDate, "Due Date", "Remaining Quantity (Base)" - "Reserved Qty. (Base)");
                    end;
                until Next = 0;
    end;

    local procedure IsSalesLineChanged(SalesLine: Record "Sales Line"): Boolean
    begin
        exit((ChangedSalesLine."Document Type" = SalesLine."Document Type") and
          (ChangedSalesLine."Document No." = SalesLine."Document No.") and
          (ChangedSalesLine."Line No." = SalesLine."Line No."));
    end;

    local procedure IsAsmLineChanged(AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(
          (ChangedAssemblyLine."Document Type" = AssemblyLine."Document Type") and
          (ChangedAssemblyLine."Document No." = AssemblyLine."Document No.") and
          (ChangedAssemblyLine."Line No." = AssemblyLine."Line No."));
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcScheduledReceipt(var Item: Record Item; var ScheduledReceipt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedRequirement(var Item: Record Item; var ReservedRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedReceipt(var Item: Record Item; var ReservedReceipt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterQtyAvailableToPromise(var Item: Record Item; ScheduledReceipt: Decimal; GrossRequirement: Decimal; var AvailableToPromise: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailableInventory(var Item: Record Item; var AvailableInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcGrossRequirement(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcScheduledReceipt(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyAvailableToPromise(var Item: Record Item; AvailabilityDate: Date)
    begin
    end;
}

