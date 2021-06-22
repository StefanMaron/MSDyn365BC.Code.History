codeunit 5830 "Calc. Availability Overview"
{
    TableNo = "Availability Calc. Overview";

    trigger OnRun()
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        CopyOfAvailabilityCalcOverview.Copy(Rec);
        Reset;
        DeleteAll();
        Copy(CopyOfAvailabilityCalcOverview);

        OpenWindow(Text000, Count);

        Item.Reset();
        Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
        Item.SetFilter("Location Filter", GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", GetFilter(Date));
        Item.SetRange("Drop Shipment Filter", false);
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.Find('-') then begin
            OpenWindow(Text000, Item.Count);
            repeat
                UpdateWindow;
                SetRange("Matches Criteria");
                "Item No." := Item."No.";
                if CheckItemInRange(Rec) then
                    if EntriesExist(Rec) then begin
                        Reset;
                        if FindLast then;
                        SetEntryNo("Entry No.");
                        InsertEntry(Rec, Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, 0);
                    end;
                Copy(CopyOfAvailabilityCalcOverview);
            until Item.Next = 0;
        end;
        Window.Close;
    end;

    var
        Item: Record Item;
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        AttachedToEntryNo: Integer;
        EntryNo: Integer;
        DemandType: Option " ",Sales,Production,Job,Service,Assembly;
        DemandNo: Code[20];
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
        Text000: Label 'Calculating Availability Dates @1@@@@@@@';

    procedure CalculateItem(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
        CopyOfItem: Record Item;
        FirstEntryNo: Integer;
    begin
        CopyOfItem.Copy(Item);
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        with AvailabilityCalcOverview do begin
            StartDate := 0D;
            EndDate := DMY2Date(31, 12, 9999);
            if GetFilter(Date) <> '' then begin
                StartDate := GetRangeMin(Date);
                EndDate := GetRangeMax(Date);
            end;

            Item.Reset();
            Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
            Item.SetFilter("Location Filter", GetFilter("Location Code"));
            Item.SetFilter("Variant Filter", GetFilter("Variant Code"));
            Item.SetRange("Drop Shipment Filter", false);

            SetRange("Matches Criteria");
            Item.Get("Item No.");
            Reset;
            SetCurrentKey("Item No.");
            SetRange("Item No.", Item."No.");
            DeleteAll();

            Reset;
            if FindLast then;
            SetEntryNo("Entry No.");

            InsertEntry(AvailabilityCalcOverview, Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, 0);
            CopyOfAvailabilityCalcOverview := AvailabilityCalcOverview;

            FirstEntryNo := "Entry No.";
            CopyFilters(CopyOfAvailabilityCalcOverview);
            GetInventoryDates(AvailabilityCalcOverview);
            GetSupplyDates(AvailabilityCalcOverview);
            GetDemandDates(AvailabilityCalcOverview);

            Reset;
            SetCurrentKey("Item No.");
            SetRange("Item No.", Item."No.");
            SetFilter(Date, CopyOfAvailabilityCalcOverview.GetFilter(Date));
            SetFilter("Location Code", CopyOfAvailabilityCalcOverview.GetFilter("Location Code"));
            SetFilter("Variant Code", CopyOfAvailabilityCalcOverview.GetFilter("Variant Code"));
            if not FindFirst then begin
                SetRange(Date);
                SetRange("Location Code");
                SetRange("Variant Code");
                DeleteAll();
            end else
                if DemandType = DemandType::" " then
                    ModifyAll("Matches Criteria", true);
            Reset;
            if Get(FirstEntryNo) then
                if Next = 0 then
                    Delete;
        end;
        Item.Copy(CopyOfItem);
        AvailabilityCalcOverview.Copy(CopyOfAvailabilityCalcOverview);
    end;

    procedure CalculateDate(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
        FirstEntryNo: Integer;
    begin
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        AttachedToEntryNo := AvailabilityCalcOverview."Attached to Entry No.";

        with AvailabilityCalcOverview do begin
            Item.Get("Item No.");

            Reset;
            SetRange("Item No.", "Item No.");
            SetRange("Location Code", "Location Code");
            SetRange("Variant Code", "Variant Code");
            SetRange(Date, Date);
            SetRange(Level, 2, 3);
            DeleteAll();

            Reset;
            if FindLast then;
            SetEntryNo("Entry No.");
            TransferFields(CopyOfAvailabilityCalcOverview, false);
            FirstEntryNo := "Entry No.";
        end;

        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);
        GetSupplyEntries(AvailabilityCalcOverview);
        GetDemandEntries(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next = 0 then;
        UpdateRunningTotals(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next = 0 then;
    end;

    local procedure GetInventoryDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            FilterLinesWithItemToPlan(Item, false);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    CalcSums("Remaining Quantity");
                    SetRange(Positive, Positive);
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Inventory, 0D, "Location Code", "Variant Code",
                      "Remaining Quantity", 0,
                      0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", AvailabilityCalcOverview.GetFilter("Location Code"));
                    SetFilter("Variant Code", AvailabilityCalcOverview.GetFilter("Variant Code"));
                    SetRange(Positive);
                until Next = 0;
        end;
    end;

    local procedure GetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
        GetPurchOrderSupplyDates(AvailabilityCalcOverview);
        GetSalesRetOrderSupplyDates(AvailabilityCalcOverview);
        GetProdOrderSupplyDates(AvailabilityCalcOverview);
        GetTransOrderSupplyDates(AvailabilityCalcOverview);
        GetAsmOrderSupplyDates(AvailabilityCalcOverview);
    end;

    local procedure GetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
        GetSalesOrdersDemandDates(AvailabilityCalcOverview);
        GetServOrdersDemandDates(AvailabilityCalcOverview);
        GetJobOrdersDemandDates(AvailabilityCalcOverview);
        GetPurchRetOrderDemandDates(AvailabilityCalcOverview);
        GetProdOrderCompDemandDates(AvailabilityCalcOverview);
        GetTransOrderDemandDates(AvailabilityCalcOverview);
        GetAsmOrderDemandDates(AvailabilityCalcOverview);
    end;

    local procedure GetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfItem: Record Item;
    begin
        CopyOfItem.Copy(Item);
        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);

        GetPurchOrderSupplyEntries(AvailabilityCalcOverview);
        GetSalesRetOrderSupplyEntries(AvailabilityCalcOverview);
        GetProdOrderSupplyEntries(AvailabilityCalcOverview);
        GetTransOrderSupplyEntries(AvailabilityCalcOverview);
        GetAsmOrderSupplyEntries(AvailabilityCalcOverview);

        Item.Copy(CopyOfItem);
    end;

    local procedure GetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfItem: Record Item;
    begin
        CopyOfItem.Copy(Item);
        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);

        GetSalesOrdersDemandEntries(AvailabilityCalcOverview);
        GetServOrdersDemandEntries(AvailabilityCalcOverview);
        GetJobOrdersDemandEntries(AvailabilityCalcOverview);
        GetPurchRetOrderDemandEntries(AvailabilityCalcOverview);
        GetProdOrderCompDemandEntries(AvailabilityCalcOverview);
        GetTransOrderDemandEntries(AvailabilityCalcOverview);
        GetAsmOrderDemandEntries(AvailabilityCalcOverview);

        Item.Copy(Item);
    end;

    procedure EntriesExist(var AvailabilityCalcOverview: Record "Availability Calc. Overview"): Boolean
    var
        Item: Record Item;
    begin
        Item.Get(AvailabilityCalcOverview."Item No.");
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", AvailabilityCalcOverview.GetFilter(Date));

        exit(true in
          [InventoryExists(Item),
           SupplyExists(Item),
           DemandExists(Item)]);
    end;

    local procedure InventoryExists(var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        exit(ItemLedgEntry.LinesWithItemToPlanExist(Item, false));
    end;

    local procedure SupplyExists(var Item: Record Item): Boolean
    begin
        exit(true in
          [PurchOrderSupplyExists(Item),
           SalesRetOrderSupplyExists(Item),
           ProdOrderSupplyExists(Item),
           TransOrderSupplyExists(Item),
           AsmOrderSupplyExists(Item)]);
    end;

    local procedure DemandExists(var Item: Record Item): Boolean
    begin
        exit(true in
          [SalesOrderDemandExists(Item),
           ServOrderDemandExists(Item),
           JobOrderDemandExists(Item),
           PurchRetOrderDemandExists(Item),
           ProdOrderCompDemandExists(Item),
           TransOrderDemandExists(Item),
           AsmOrderDemandExists(Item)]);
    end;

    local procedure GetPurchOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::Order);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Expected Receipt Date", "Expected Receipt Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Expected Receipt Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetSalesRetOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::"Return Order");
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Shipment Date", "Shipment Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Shipment Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetProdOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        with ProdOrderLine do begin
            FilterLinesWithItemToPlan(Item, true);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Due Date", "Due Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Due Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Due Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetTransOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        with TransLine do begin
            FilterLinesWithItemToPlan(Item, true, false);
            if FindFirst then
                repeat
                    SetRange("Transfer-to Code", "Transfer-to Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Receipt Date", "Receipt Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Receipt Date", "Transfer-to Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Receipt Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetSalesOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::Order);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Shipment Date", "Shipment Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Shipment Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetServOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ServLine: Record "Service Line";
    begin
        with ServLine do begin
            FilterLinesWithItemToPlan(Item);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Needed by Date", "Needed by Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Needed by Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Needed by Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetJobOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        with JobPlanningLine do begin
            FilterLinesWithItemToPlan(Item);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Planning Date", "Planning Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Planning Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Planning Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetPurchRetOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::"Return Order");
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Expected Receipt Date", "Expected Receipt Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Expected Receipt Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetProdOrderCompDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        with ProdOrderComp do begin
            FilterLinesWithItemToPlan(Item, true);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Due Date", "Due Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Due Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Due Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetTransOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        with TransLine do begin
            FilterLinesWithItemToPlan(Item, false, false);
            if FindFirst then
                repeat
                    SetRange("Transfer-from Code", "Transfer-from Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Shipment Date", "Shipment Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Shipment Date", "Transfer-from Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetAsmOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmLine: Record "Assembly Line";
    begin
        with AsmLine do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::Order);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Due Date", "Due Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Due Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Due Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetAsmOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
    begin
        with AsmHeader do begin
            FilterLinesWithItemToPlan(Item, "Document Type"::Order);
            if FindFirst then
                repeat
                    SetRange("Location Code", "Location Code");
                    SetRange("Variant Code", "Variant Code");
                    SetRange("Due Date", "Due Date");

                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::"As of Date", "Due Date", "Location Code", "Variant Code", 0, 0, 0, 0, '', '', 0);

                    FindLast;
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    SetFilter("Due Date", Item.GetFilter("Date Filter"));
                until Next = 0;
        end;
    end;

    local procedure GetPurchOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        with PurchLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    PurchHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Supply, "Expected Receipt Date", "Location Code", "Variant Code",
                      "Outstanding Qty. (Base)", "Reserved Qty. (Base)",
                      DATABASE::"Purchase Line", "Document Type", "Document No.", PurchHeader."Buy-from Vendor Name", 0);
                until Next = 0;
        end;
    end;

    local procedure GetSalesRetOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        with SalesLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::"Return Order") then
                repeat
                    SalesHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Supply, "Shipment Date", "Location Code", "Variant Code",
                      "Outstanding Qty. (Base)", "Reserved Qty. (Base)",
                      DATABASE::"Sales Line", "Document Type", "Document No.", SalesHeader."Sell-to Customer Name", 0);
                until Next = 0;
        end;
    end;

    local procedure GetProdOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
    begin
        with ProdOrderLine do begin
            if FindLinesWithItemToPlan(Item, true) then
                repeat
                    ProdOrder.Get(Status, "Prod. Order No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Supply, "Due Date", "Location Code", "Variant Code",
                      "Remaining Qty. (Base)", "Reserved Qty. (Base)",
                      DATABASE::"Prod. Order Line", Status, "Prod. Order No.", ProdOrder.Description, 0);
                until Next = 0;
        end;
    end;

    local procedure GetTransOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        with TransLine do begin
            if FindLinesWithItemToPlan(Item, true, false) then
                repeat
                    TransHeader.Get("Document No.");
                    CalcFields("Reserved Qty. Inbnd. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Supply, "Receipt Date", "Transfer-to Code", "Variant Code",
                      "Outstanding Qty. (Base)", "Reserved Qty. Inbnd. (Base)",
                      DATABASE::"Transfer Line", Status, "Document No.", TransHeader."Transfer-from Name", 0);
                until Next = 0;
        end;
    end;

    local procedure GetAsmOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
    begin
        with AsmHeader do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Supply, "Due Date", "Location Code", "Variant Code",
                      "Remaining Quantity (Base)", "Reserved Qty. (Base)",
                      DATABASE::"Assembly Header", "Document Type",
                      "No.", Description, 0);
                until Next = 0;
        end;
    end;

    local procedure GetSalesOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        with SalesLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    SalesHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Shipment Date", "Location Code", "Variant Code",
                      -"Outstanding Qty. (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Sales Line", "Document Type", "Document No.", SalesHeader."Sell-to Customer Name", DemandType::Sales);
                until Next = 0;
        end;
    end;

    local procedure GetServOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ServLine: Record "Service Line";
        ServHeader: Record "Service Header";
    begin
        with ServLine do begin
            if FindLinesWithItemToPlan(Item) then
                repeat
                    ServHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Needed by Date", "Location Code", "Variant Code",
                      -"Outstanding Qty. (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Service Line", "Document Type", "Document No.", ServHeader."Ship-to Name", DemandType::Service);
                until Next = 0;
        end;
    end;

    local procedure GetJobOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
    begin
        with JobPlanningLine do begin
            if FindLinesWithItemToPlan(Item) then
                repeat
                    Job.Get("Job No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Planning Date", "Location Code", "Variant Code",
                      -"Remaining Qty. (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Job Planning Line", Status, "Job No.", Job."Bill-to Name", DemandType::Job);
                until Next = 0;
        end;
    end;

    local procedure GetPurchRetOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        with PurchLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::"Return Order") then
                repeat
                    PurchHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Expected Receipt Date", "Location Code", "Variant Code",
                      -"Outstanding Qty. (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Purchase Line", "Document Type", "Document No.", PurchHeader."Buy-from Vendor Name", 0);
                until Next = 0;
        end;
    end;

    local procedure GetProdOrderCompDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrder: Record "Production Order";
    begin
        with ProdOrderComp do begin
            if FindLinesWithItemToPlan(Item, true) then
                repeat
                    ProdOrder.Get(Status, "Prod. Order No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Due Date", "Location Code", "Variant Code",
                      -"Remaining Qty. (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Prod. Order Component", Status, "Prod. Order No.", ProdOrder.Description, DemandType::Production);
                until Next = 0;
        end;
    end;

    local procedure GetTransOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        with TransLine do begin
            if FindLinesWithItemToPlan(Item, false, false) then
                repeat
                    TransHeader.Get("Document No.");
                    CalcFields("Reserved Qty. Outbnd. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Shipment Date", "Transfer-from Code", "Variant Code",
                      -"Outstanding Qty. (Base)", -"Reserved Qty. Outbnd. (Base)",
                      DATABASE::"Transfer Line", Status, "Document No.", TransHeader."Transfer-to Name", 0);
                until Next = 0;
        end;
    end;

    local procedure GetAsmOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        with AsmLine do begin
            if FindLinesWithItemToPlan(Item, "Document Type"::Order) then
                repeat
                    AsmHeader.Get("Document Type", "Document No.");
                    CalcFields("Reserved Qty. (Base)");
                    InsertEntry(
                      AvailabilityCalcOverview,
                      AvailabilityCalcOverview.Type::Demand, "Due Date", "Location Code", "Variant Code",
                      -"Remaining Quantity (Base)", -"Reserved Qty. (Base)",
                      DATABASE::"Assembly Line", "Document Type",
                      "Document No.", AsmHeader.Description, DemandType::Assembly);
                until Next = 0;
        end;
    end;

    local procedure PurchOrderSupplyExists(var Item: Record Item): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        exit(PurchLine.LinesWithItemToPlanExist(Item, PurchLine."Document Type"::Order));
    end;

    local procedure SalesRetOrderSupplyExists(var Item: Record Item): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        exit(SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::"Return Order"));
    end;

    local procedure ProdOrderSupplyExists(var Item: Record Item): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        exit(ProdOrderLine.LinesWithItemToPlanExist(Item, true));
    end;

    local procedure TransOrderSupplyExists(var Item: Record Item): Boolean
    var
        TransLine: Record "Transfer Line";
    begin
        exit(TransLine.LinesWithItemToPlanExist(Item, true));
    end;

    local procedure AsmOrderSupplyExists(var Item: Record Item): Boolean
    var
        AsmHeader: Record "Assembly Header";
    begin
        exit(AsmHeader.LinesWithItemToPlanExist(Item, AsmHeader."Document Type"::Order));
    end;

    local procedure SalesOrderDemandExists(var Item: Record Item): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        exit(SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::Order));
    end;

    local procedure ServOrderDemandExists(var Item: Record Item): Boolean
    var
        ServLine: Record "Service Line";
    begin
        exit(ServLine.LinesWithItemToPlanExist(Item));
    end;

    local procedure JobOrderDemandExists(var Item: Record Item): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        exit(JobPlanningLine.LinesWithItemToPlanExist(Item));
    end;

    local procedure PurchRetOrderDemandExists(var Item: Record Item): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        exit(PurchLine.LinesWithItemToPlanExist(Item, PurchLine."Document Type"::"Return Order"));
    end;

    local procedure ProdOrderCompDemandExists(var Item: Record Item): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        exit(ProdOrderComp.LinesWithItemToPlanExist(Item, true));
    end;

    local procedure TransOrderDemandExists(var Item: Record Item): Boolean
    var
        TransLine: Record "Transfer Line";
    begin
        exit(TransLine.LinesWithItemToPlanExist(Item, false));
    end;

    local procedure AsmOrderDemandExists(var Item: Record Item): Boolean
    var
        AsmLine: Record "Assembly Line";
    begin
        exit(AsmLine.LinesWithItemToPlanExist(Item, AsmLine."Document Type"::Order));
    end;

    local procedure ClosingEntryExists(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Option; LocationCode: Code[20]; VariantCode: Code[20]; ClosingDate: Date) Found: Boolean
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        with AvailabilityCalcOverview do begin
            CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
            SetRange("Item No.", Item."No.");
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            SetRange(Date, ClosingDate);
            SetRange(Type, NewType);
            Found := FindFirst;
            CopyFilters(CopyOfAvailabilityCalcOverview);
        end;
    end;

    local procedure CheckItemInRange(var AvailabilityCalcOverview: Record "Availability Calc. Overview"): Boolean
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        ProdOrderComp: Record "Prod. Order Component";
        AsmLine: Record "Assembly Line";
        Found: Boolean;
    begin
        Item.Get(AvailabilityCalcOverview."Item No.");
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", AvailabilityCalcOverview.GetFilter(Date));

        case DemandType of
            DemandType::" ":
                Found := DemandExists(Item);
            DemandType::Sales:
                with SalesLine do
                    if LinesWithItemToPlanExist(Item, "Document Type"::Order) then begin
                        if DemandNo <> '' then begin
                            SetRange("Document No.", DemandNo);
                            Found := not IsEmpty;
                        end else
                            Found := true;
                    end;
            DemandType::Production:
                with ProdOrderComp do
                    if LinesWithItemToPlanExist(Item, true) then begin
                        if DemandNo <> '' then begin
                            SetRange("Prod. Order No.", DemandNo);
                            Found := not IsEmpty;
                        end else
                            Found := true;
                    end;
            DemandType::Service:
                with ServLine do
                    if LinesWithItemToPlanExist(Item) then begin
                        if DemandNo <> '' then begin
                            SetRange("Document No.", DemandNo);
                            Found := not IsEmpty;
                        end else
                            Found := true;
                    end;
            DemandType::Job:
                with JobPlanningLine do
                    if LinesWithItemToPlanExist(Item) then begin
                        if DemandNo <> '' then begin
                            SetRange("Job No.", DemandNo);
                            Found := not IsEmpty;
                        end else
                            Found := true;
                    end;
            DemandType::Assembly:
                with AsmLine do
                    if LinesWithItemToPlanExist(Item, "Document Type"::Order) then begin
                        if DemandNo <> '' then begin
                            SetRange("Document No.", DemandNo);
                            Found := not IsEmpty;
                        end else
                            Found := true;
                    end;
        end;

        exit(Found);
    end;

    local procedure CheckDemandInDate(AvailCalcOverview: Record "Availability Calc. Overview"): Boolean
    begin
        AvailCalcOverview.SetRange("Location Code", AvailCalcOverview."Location Code");
        AvailCalcOverview.SetRange("Variant Code", AvailCalcOverview."Variant Code");
        AvailCalcOverview.SetRange(Date, AvailCalcOverview.Date);
        exit(CheckItemInRange(AvailCalcOverview));
    end;

    local procedure InsertEntry(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Integer; NewDate: Date; NewLocation: Code[10]; NewVariantCode: Code[10]; NewQuantityBase: Decimal; NewReservQtyBase: Decimal; NewSourceType: Integer; NewSourceOrderStatus: Integer; NewSourceID: Code[20]; NewDescription: Text[100]; NewDemandType: Option)
    var
        CopyOfItem: Record Item;
    begin
        if (NewDate <> 0D) and not (NewDate in [StartDate .. EndDate]) then
            exit;
        CopyOfItem.Copy(Item);
        with AvailabilityCalcOverview do begin
            if NewType in [Type::"As of Date", Type::Inventory] then
                if ClosingEntryExists(AvailabilityCalcOverview, NewType, NewLocation, NewVariantCode, NewDate) then begin
                    if not "Matches Criteria" then begin
                        "Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                        Modify;
                    end;
                    exit;
                end;

            if not (NewType in [Type::Item, Type::"As of Date"]) then
                if NewQuantityBase = 0 then
                    exit;
            Init;
            "Entry No." := GetEntryNo;
            Type := NewType;
            "Item No." := Item."No.";
            Date := NewDate;
            "Location Code" := NewLocation;
            "Variant Code" := NewVariantCode;
            Quantity := NewQuantityBase;
            "Reserved Quantity" := NewReservQtyBase;

            if (DemandType = DemandType::" ") or
               (Type = Type::"As of Date") or
               ((DemandType = NewDemandType) and (DemandNo in ['', NewSourceID]))
            then
                "Matches Criteria" := NewDate in [StartDate .. EndDate];

            case NewType of
                Type::Item:
                    begin
                        Level := 0;
                        "Matches Criteria" := true;
                    end;
                Type::Inventory:
                    begin
                        "Attached to Entry No." := "Entry No.";
                        Level := 1;
                        "Inventory Running Total" := Quantity;
                        "Running Total" := Quantity;
                    end;
                Type::"As of Date":
                    begin
                        "Attached to Entry No." := "Entry No.";
                        Level := 1;
                        CalcRunningTotals(
                          Item."No.", NewLocation, NewVariantCode, NewDate,
                          "Running Total", "Inventory Running Total", "Supply Running Total", "Demand Running Total");
                        AllocateToDemand("Inventory Running Total", "Supply Running Total", "Demand Running Total");
                        if "Matches Criteria" then
                            "Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                    end;
                else
                    "Attached to Entry No." := AttachedToEntryNo;
                    Level := 2;
            end;
            "Source Type" := NewSourceType;
            "Source Order Status" := NewSourceOrderStatus;
            "Source ID" := NewSourceID;
            Description := NewDescription;

            OnInsertEntryOnBeforeInsert(AvailabilityCalcOverview);
            Insert;
        end;
        Item.Copy(CopyOfItem);
    end;

    local procedure CalcRunningTotals(NewItem: Code[20]; NewLocation: Code[10]; NewVariant: Code[10]; NewDate: Date; var RunningTotal: Decimal; var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    var
        Item: Record Item;
    begin
        with Item do begin
            Get(NewItem);
            SetRange("Location Filter", NewLocation);
            SetRange("Variant Filter", NewVariant);
            SetRange("Date Filter", 0D, NewDate);
            CalcFields(
              "Reserved Qty. on Purch. Orders",
              "Reserved Qty. on Prod. Order",
              "Res. Qty. on Inbound Transfer",
              "Reserved Qty. on Sales Orders",
              "Res. Qty. on Service Orders",
              "Res. Qty. on Job Order",
              "Res. Qty. on Prod. Order Comp.",
              "Res. Qty. on Outbound Transfer",
              "Reserved Qty. on Inventory",
              "Res. Qty. on Assembly Order",
              "Res. Qty. on  Asm. Comp.",
              "Res. Qty. on Sales Returns",
              "Res. Qty. on Purch. Returns");
            CalcFields(
              "Qty. on Purch. Order",
              "Scheduled Receipt (Qty.)",
              "Planned Order Receipt (Qty.)",
              "Trans. Ord. Receipt (Qty.)",
              "Qty. on Sales Order",
              "Qty. on Service Order",
              "Qty. on Job Order",
              "Scheduled Need (Qty.)",
              "Trans. Ord. Shipment (Qty.)",
              Inventory,
              "Qty. on Assembly Order",
              "Qty. on Asm. Component",
              "Qty. on Purch. Return",
              "Qty. on Sales Return");

            SupplyRunningTotal :=
              "Qty. on Purch. Order" - "Reserved Qty. on Purch. Orders" +
              "Qty. on Sales Return" - "Res. Qty. on Sales Returns" +
              "Scheduled Receipt (Qty.)" + "Planned Order Receipt (Qty.)" - "Reserved Qty. on Prod. Order" +
              "Trans. Ord. Receipt (Qty.)" - "Res. Qty. on Inbound Transfer" +
              "Qty. on Assembly Order" - "Res. Qty. on Assembly Order";
            DemandRunningTotal :=
              -"Qty. on Sales Order" + "Reserved Qty. on Sales Orders" -
              "Qty. on Purch. Return" + "Res. Qty. on Purch. Returns" -
              "Scheduled Need (Qty.)" + "Res. Qty. on Prod. Order Comp." -
              "Qty. on Service Order" + "Res. Qty. on Service Orders" -
              "Qty. on Job Order" + "Res. Qty. on Job Order" -
              "Trans. Ord. Shipment (Qty.)" + "Res. Qty. on Outbound Transfer" -
              "Qty. on Asm. Component" + "Res. Qty. on  Asm. Comp.";
            InventoryRunningTotal := Inventory - "Reserved Qty. on Inventory";

            RunningTotal := InventoryRunningTotal + SupplyRunningTotal + DemandRunningTotal;
        end;

        OnAfterCalcRunningTotals(Item, RunningTotal, InventoryRunningTotal, SupplyRunningTotal, DemandRunningTotal);
    end;

    local procedure UpdateRunningTotals(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        CopyOfAvailCalcOverview: Record "Availability Calc. Overview";
        FirstEntryNo: Integer;
        RunningTotal: Decimal;
        SupplyRunningTotal: Decimal;
        DemandRunningTotal: Decimal;
        InventoryRunningTotal: Decimal;
    begin
        CopyOfAvailCalcOverview.Copy(AvailabilityCalcOverview);
        with AvailabilityCalcOverview do begin
            FirstEntryNo := "Entry No.";
            if Date <> 0D then
                CalcRunningTotals(
                  "Item No.", "Location Code", "Variant Code", CalcDate('<-1D>', Date),
                  RunningTotal, InventoryRunningTotal, SupplyRunningTotal, DemandRunningTotal);

            repeat
                RunningTotal += Quantity - "Reserved Quantity";
                case Type of
                    Type::Inventory:
                        InventoryRunningTotal += Quantity - "Reserved Quantity";
                    Type::Supply,
                  Type::"Supply Forecast":
                        SupplyRunningTotal += Quantity - "Reserved Quantity";
                    Type::Demand:
                        DemandRunningTotal += Quantity - "Reserved Quantity";
                end;

                "Running Total" := RunningTotal;
                "Inventory Running Total" := InventoryRunningTotal;
                "Supply Running Total" := SupplyRunningTotal;
                "Demand Running Total" := DemandRunningTotal;
                AllocateToDemand("Inventory Running Total", "Supply Running Total", "Demand Running Total");
                if DemandType = DemandType::" " then
                    "Matches Criteria" := CopyOfAvailCalcOverview."Matches Criteria";

                OnUpdateRunningTotalsOnBeforeModify(AvailabilityCalcOverview);
                Modify;
            until Next = 0;
            Get(FirstEntryNo);
            if Next = 0 then;
        end;
    end;

    local procedure AllocateToDemand(var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    var
        RemQty: Decimal;
    begin
        RemQty := DemandRunningTotal;
        if RemQty < 0 then
            if InventoryRunningTotal > 0 then
                if -RemQty > InventoryRunningTotal then begin
                    RemQty += InventoryRunningTotal;
                    InventoryRunningTotal := 0;
                end else begin
                    InventoryRunningTotal += RemQty;
                    RemQty := 0;
                end;
        if RemQty < 0 then
            if SupplyRunningTotal > 0 then
                if -RemQty > SupplyRunningTotal then begin
                    RemQty += SupplyRunningTotal;
                    SupplyRunningTotal := 0;
                end else begin
                    SupplyRunningTotal += RemQty;
                    RemQty := 0;
                end;
        DemandRunningTotal := RemQty;
    end;

    local procedure GetEntryNo(): Integer
    begin
        EntryNo += 1;
        exit(EntryNo);
    end;

    local procedure SetEntryNo(NewEntryNo: Integer)
    begin
        EntryNo := NewEntryNo;
    end;

    procedure SetParam(NewDemandType: Option; NewDemandNo: Code[20])
    begin
        DemandType := NewDemandType;
        DemandNo := NewDemandNo;
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRunningTotals(var Item: Record Item; var RunningTotal : Decimal; var InventoryRunningTotal : Decimal; var SupplyRunningTotal : Decimal; var DemandRunningTotal : Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEntryOnBeforeInsert(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRunningTotalsOnBeforeModify(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    begin
    end;
}

