namespace Microsoft.Inventory.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

codeunit 5830 "Calc. Availability Overview"
{
    TableNo = "Availability Calc. Overview";

    trigger OnRun()
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        CopyOfAvailabilityCalcOverview.Copy(Rec);
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Copy(CopyOfAvailabilityCalcOverview);

        OpenWindow(Text000, Rec.Count);

        Item.Reset();
        Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
        Item.SetFilter("Location Filter", Rec.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", Rec.GetFilter("Variant Code"));
        Item.SetFilter("Date Filter", Rec.GetFilter(Date));
        Item.SetRange("Drop Shipment Filter", false);
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.Find('-') then begin
            OpenWindow(Text000, Item.Count);
            repeat
                UpdateWindow();
                Rec.SetRange("Matches Criteria");
                Rec."Item No." := Item."No.";
                if CheckItemInRange(Rec) then
                    if EntriesExist(Rec) then begin
                        Rec.Reset();
                        if Rec.FindLast() then;
                        SetEntryNo(Rec."Entry No.");
                        InsertEntry(Rec, Rec.Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, 0);
                    end;
                Rec.Copy(CopyOfAvailabilityCalcOverview);
            until Item.Next() = 0;
        end;
        Window.Close();
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
        StartDate := 0D;
        EndDate := DMY2Date(31, 12, 9999);
        if AvailabilityCalcOverview.GetFilter(Date) <> '' then begin
            StartDate := AvailabilityCalcOverview.GetRangeMin(Date);
            EndDate := AvailabilityCalcOverview.GetRangeMax(Date);
        end;

        Item.Reset();
        Item.SetFilter("No.", CopyOfAvailabilityCalcOverview.GetFilter("Item No."));
        Item.SetFilter("Location Filter", AvailabilityCalcOverview.GetFilter("Location Code"));
        Item.SetFilter("Variant Filter", AvailabilityCalcOverview.GetFilter("Variant Code"));
        Item.SetRange("Drop Shipment Filter", false);

        AvailabilityCalcOverview.SetRange("Matches Criteria");
        Item.Get(AvailabilityCalcOverview."Item No.");
        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetCurrentKey("Item No.");
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.DeleteAll();

        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.FindLast() then;
        SetEntryNo(AvailabilityCalcOverview."Entry No.");

        InsertEntry(AvailabilityCalcOverview, AvailabilityCalcOverview.Type::Item, 0D, '', '', 0, 0, 0, 0, '', Item.Description, 0);
        CopyOfAvailabilityCalcOverview := AvailabilityCalcOverview;

        FirstEntryNo := AvailabilityCalcOverview."Entry No.";
        AvailabilityCalcOverview.CopyFilters(CopyOfAvailabilityCalcOverview);
        GetInventoryDates(AvailabilityCalcOverview);
        GetSupplyDates(AvailabilityCalcOverview);
        GetDemandDates(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetCurrentKey("Item No.");
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.SetFilter(Date, CopyOfAvailabilityCalcOverview.GetFilter(Date));
        AvailabilityCalcOverview.SetFilter("Location Code", CopyOfAvailabilityCalcOverview.GetFilter("Location Code"));
        AvailabilityCalcOverview.SetFilter("Variant Code", CopyOfAvailabilityCalcOverview.GetFilter("Variant Code"));
        if not AvailabilityCalcOverview.FindFirst() then begin
            AvailabilityCalcOverview.SetRange(Date);
            AvailabilityCalcOverview.SetRange("Location Code");
            AvailabilityCalcOverview.SetRange("Variant Code");
            AvailabilityCalcOverview.DeleteAll();
        end else
            if DemandType = DemandType::" " then
                AvailabilityCalcOverview.ModifyAll(AvailabilityCalcOverview."Matches Criteria", true);
        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.Get(FirstEntryNo) then
            if AvailabilityCalcOverview.Next() = 0 then
                AvailabilityCalcOverview.Delete();
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

        Item.Get(AvailabilityCalcOverview."Item No.");

        AvailabilityCalcOverview.Reset();
        AvailabilityCalcOverview.SetRange("Item No.", AvailabilityCalcOverview."Item No.");
        AvailabilityCalcOverview.SetRange("Location Code", AvailabilityCalcOverview."Location Code");
        AvailabilityCalcOverview.SetRange("Variant Code", AvailabilityCalcOverview."Variant Code");
        AvailabilityCalcOverview.SetRange(Date, AvailabilityCalcOverview.Date);
        AvailabilityCalcOverview.SetRange(Level, 2, 3);
        AvailabilityCalcOverview.DeleteAll();

        AvailabilityCalcOverview.Reset();
        if AvailabilityCalcOverview.FindLast() then;
        SetEntryNo(AvailabilityCalcOverview."Entry No.");
        AvailabilityCalcOverview.TransferFields(CopyOfAvailabilityCalcOverview, false);
        FirstEntryNo := AvailabilityCalcOverview."Entry No.";

        Item.SetRange("Location Filter", AvailabilityCalcOverview."Location Code");
        Item.SetRange("Variant Filter", AvailabilityCalcOverview."Variant Code");
        Item.SetRange("Date Filter", AvailabilityCalcOverview.Date);
        GetSupplyEntries(AvailabilityCalcOverview);
        GetDemandEntries(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
        UpdateRunningTotals(AvailabilityCalcOverview);

        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
    end;

    local procedure GetInventoryDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FilterLinesWithItemToPlan(Item, false);
        if ItemLedgEntry.FindFirst() then
            repeat
                ItemLedgEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
                ItemLedgEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
                ItemLedgEntry.CalcSums(ItemLedgEntry."Remaining Quantity");
                ItemLedgEntry.SetRange(Positive, ItemLedgEntry.Positive);
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Inventory, 0D, ItemLedgEntry."Location Code", ItemLedgEntry."Variant Code",
                  ItemLedgEntry."Remaining Quantity", 0,
                  0, 0, '', '', 0);

                ItemLedgEntry.FindLast();
                ItemLedgEntry.SetFilter(ItemLedgEntry."Location Code", AvailabilityCalcOverview.GetFilter("Location Code"));
                ItemLedgEntry.SetFilter(ItemLedgEntry."Variant Code", AvailabilityCalcOverview.GetFilter("Variant Code"));
                ItemLedgEntry.SetRange(Positive);
            until ItemLedgEntry.Next() = 0;
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
        PurchLine.FilterLinesWithItemToPlan(Item, PurchLine."Document Type"::Order);
        if PurchLine.FindFirst() then
            repeat
                PurchLine.SetRange("Location Code", PurchLine."Location Code");
                PurchLine.SetRange("Variant Code", PurchLine."Variant Code");
                PurchLine.SetRange("Expected Receipt Date", PurchLine."Expected Receipt Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                PurchLine.FindLast();
                PurchLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                PurchLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                PurchLine.SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
            until PurchLine.Next() = 0;
    end;

    local procedure GetSalesRetOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FilterLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order");
        if SalesLine.FindFirst() then
            repeat
                SalesLine.SetRange("Location Code", SalesLine."Location Code");
                SalesLine.SetRange("Variant Code", SalesLine."Variant Code");
                SalesLine.SetRange("Shipment Date", SalesLine."Shipment Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                SalesLine.FindLast();
                SalesLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SalesLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                SalesLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until SalesLine.Next() = 0;
    end;

    local procedure GetProdOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.FilterLinesWithItemToPlan(Item, true);
        if ProdOrderLine.FindFirst() then
            repeat
                ProdOrderLine.SetRange("Location Code", ProdOrderLine."Location Code");
                ProdOrderLine.SetRange("Variant Code", ProdOrderLine."Variant Code");
                ProdOrderLine.SetRange("Due Date", ProdOrderLine."Due Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", ProdOrderLine."Due Date", ProdOrderLine."Location Code", ProdOrderLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                ProdOrderLine.FindLast();
                ProdOrderLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ProdOrderLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ProdOrderLine.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until ProdOrderLine.Next() = 0;
    end;

    local procedure GetTransOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.FilterLinesWithItemToPlan(Item, true, false);
        if TransLine.FindFirst() then
            repeat
                TransLine.SetRange("Transfer-to Code", TransLine."Transfer-to Code");
                TransLine.SetRange("Variant Code", TransLine."Variant Code");
                TransLine.SetRange("Receipt Date", TransLine."Receipt Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", TransLine."Receipt Date", TransLine."Transfer-to Code", TransLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                TransLine.FindLast();
                TransLine.SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
                TransLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                TransLine.SetFilter("Receipt Date", Item.GetFilter("Date Filter"));
            until TransLine.Next() = 0;
    end;

    local procedure GetSalesOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FilterLinesWithItemToPlan(Item, SalesLine."Document Type"::Order);
        if SalesLine.FindFirst() then
            repeat
                SalesLine.SetRange("Location Code", SalesLine."Location Code");
                SalesLine.SetRange("Variant Code", SalesLine."Variant Code");
                SalesLine.SetRange("Shipment Date", SalesLine."Shipment Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                SalesLine.FindLast();
                SalesLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SalesLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                SalesLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until SalesLine.Next() = 0;
    end;

    local procedure GetServOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ServLine: Record "Service Line";
    begin
        ServLine.FilterLinesWithItemToPlan(Item);
        if ServLine.FindFirst() then
            repeat
                ServLine.SetRange("Location Code", ServLine."Location Code");
                ServLine.SetRange("Variant Code", ServLine."Variant Code");
                ServLine.SetRange("Needed by Date", ServLine."Needed by Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", ServLine."Needed by Date", ServLine."Location Code", ServLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                ServLine.FindLast();
                ServLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ServLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ServLine.SetFilter("Needed by Date", Item.GetFilter("Date Filter"));
            until ServLine.Next() = 0;
    end;

    local procedure GetJobOrdersDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.FilterLinesWithItemToPlan(Item);
        if JobPlanningLine.FindFirst() then
            repeat
                JobPlanningLine.SetRange("Location Code", JobPlanningLine."Location Code");
                JobPlanningLine.SetRange("Variant Code", JobPlanningLine."Variant Code");
                JobPlanningLine.SetRange("Planning Date", JobPlanningLine."Planning Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", JobPlanningLine."Planning Date", JobPlanningLine."Location Code", JobPlanningLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                JobPlanningLine.FindLast();
                JobPlanningLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                JobPlanningLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                JobPlanningLine.SetFilter("Planning Date", Item.GetFilter("Date Filter"));
            until JobPlanningLine.Next() = 0;
    end;

    local procedure GetPurchRetOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.FilterLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order");
        if PurchLine.FindFirst() then
            repeat
                PurchLine.SetRange("Location Code", PurchLine."Location Code");
                PurchLine.SetRange("Variant Code", PurchLine."Variant Code");
                PurchLine.SetRange("Expected Receipt Date", PurchLine."Expected Receipt Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                PurchLine.FindLast();
                PurchLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                PurchLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                PurchLine.SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
            until PurchLine.Next() = 0;
    end;

    local procedure GetProdOrderCompDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.FilterLinesWithItemToPlan(Item, true);
        if ProdOrderComp.FindFirst() then
            repeat
                ProdOrderComp.SetRange("Location Code", ProdOrderComp."Location Code");
                ProdOrderComp.SetRange("Variant Code", ProdOrderComp."Variant Code");
                ProdOrderComp.SetRange("Due Date", ProdOrderComp."Due Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", ProdOrderComp."Due Date", ProdOrderComp."Location Code", ProdOrderComp."Variant Code", 0, 0, 0, 0, '', '', 0);

                ProdOrderComp.FindLast();
                ProdOrderComp.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ProdOrderComp.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ProdOrderComp.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until ProdOrderComp.Next() = 0;
    end;

    local procedure GetTransOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.FilterLinesWithItemToPlan(Item, false, false);
        if TransLine.FindFirst() then
            repeat
                TransLine.SetRange("Transfer-from Code", TransLine."Transfer-from Code");
                TransLine.SetRange("Variant Code", TransLine."Variant Code");
                TransLine.SetRange("Shipment Date", TransLine."Shipment Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", TransLine."Shipment Date", TransLine."Transfer-from Code", TransLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                TransLine.FindLast();
                TransLine.SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
                TransLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                TransLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until TransLine.Next() = 0;
    end;

    local procedure GetAsmOrderDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmLine: Record "Assembly Line";
    begin
        AsmLine.SetItemToPlanFilters(Item, AsmLine."Document Type"::Order);
        if AsmLine.FindFirst() then
            repeat
                AsmLine.SetRange("Location Code", AsmLine."Location Code");
                AsmLine.SetRange("Variant Code", AsmLine."Variant Code");
                AsmLine.SetRange("Due Date", AsmLine."Due Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", AsmLine."Due Date", AsmLine."Location Code", AsmLine."Variant Code", 0, 0, 0, 0, '', '', 0);

                AsmLine.FindLast();
                AsmLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                AsmLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                AsmLine.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until AsmLine.Next() = 0;
    end;

    local procedure GetAsmOrderSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader.SetItemToPlanFilters(Item, AsmHeader."Document Type"::Order);
        if AsmHeader.FindFirst() then
            repeat
                AsmHeader.SetRange("Location Code", AsmHeader."Location Code");
                AsmHeader.SetRange("Variant Code", AsmHeader."Variant Code");
                AsmHeader.SetRange("Due Date", AsmHeader."Due Date");

                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::"As of Date", AsmHeader."Due Date", AsmHeader."Location Code", AsmHeader."Variant Code", 0, 0, 0, 0, '', '', 0);

                AsmHeader.FindLast();
                AsmHeader.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                AsmHeader.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                AsmHeader.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until AsmHeader.Next() = 0;
    end;

    local procedure GetPurchOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order) then
            repeat
                PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                PurchLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Supply, PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code",
                  PurchLine."Outstanding Qty. (Base)", PurchLine."Reserved Qty. (Base)",
                  Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchHeader."Buy-from Vendor Name", 0);
            until PurchLine.Next() = 0;
    end;

    local procedure GetSalesRetOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                SalesLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Supply, SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code",
                  SalesLine."Outstanding Qty. (Base)", SalesLine."Reserved Qty. (Base)",
                  Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesHeader."Sell-to Customer Name", 0);
            until SalesLine.Next() = 0;
    end;

    local procedure GetProdOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
    begin
        if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Supply, ProdOrderLine."Due Date", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                    ProdOrderLine."Remaining Qty. (Base)", ProdOrderLine."Reserved Qty. (Base)",
                    Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrder.Description, 0);
            until ProdOrderLine.Next() = 0;
    end;

    local procedure GetTransOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        if TransLine.FindLinesWithItemToPlan(Item, true, false) then
            repeat
                TransHeader.Get(TransLine."Document No.");
                TransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Supply, TransLine."Receipt Date", TransLine."Transfer-to Code", TransLine."Variant Code",
                  TransLine."Outstanding Qty. (Base)", TransLine."Reserved Qty. Inbnd. (Base)",
                  Database::"Transfer Line", TransLine.Status, TransLine."Document No.", TransHeader."Transfer-from Name", 0);
            until TransLine.Next() = 0;
    end;

    local procedure GetAsmOrderSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmHeader.FindItemToPlanLines(Item, AsmHeader."Document Type"::Order) then
            repeat
                AsmHeader.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Supply, AsmHeader."Due Date", AsmHeader."Location Code", AsmHeader."Variant Code",
                  AsmHeader."Remaining Quantity (Base)", AsmHeader."Reserved Qty. (Base)",
                  Database::"Assembly Header", AsmHeader."Document Type".AsInteger(),
                  AsmHeader."No.", AsmHeader.Description, 0);
            until AsmHeader.Next() = 0;
    end;

    local procedure GetSalesOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                SalesLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code",
                  -SalesLine."Outstanding Qty. (Base)", -SalesLine."Reserved Qty. (Base)",
                  Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesHeader."Sell-to Customer Name", DemandType::Sales);
            until SalesLine.Next() = 0;
    end;

    local procedure GetServOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ServLine: Record "Service Line";
        ServHeader: Record "Service Header";
    begin
        if ServLine.FindLinesWithItemToPlan(Item) then
            repeat
                ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
                ServLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, ServLine."Needed by Date", ServLine."Location Code", ServLine."Variant Code",
                  -ServLine."Outstanding Qty. (Base)", -ServLine."Reserved Qty. (Base)",
                  Database::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServHeader."Ship-to Name", DemandType::Service);
            until ServLine.Next() = 0;
    end;

    local procedure GetJobOrdersDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
    begin
        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                Job.Get(JobPlanningLine."Job No.");
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, JobPlanningLine."Planning Date", JobPlanningLine."Location Code", JobPlanningLine."Variant Code",
                  -JobPlanningLine."Remaining Qty. (Base)", -JobPlanningLine."Reserved Qty. (Base)",
                  Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", Job."Bill-to Name", DemandType::Job);
            until JobPlanningLine.Next() = 0;
    end;

    local procedure GetPurchRetOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order") then
            repeat
                PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                PurchLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code",
                  -PurchLine."Outstanding Qty. (Base)", -PurchLine."Reserved Qty. (Base)",
                  Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchHeader."Buy-from Vendor Name", 0);
            until PurchLine.Next() = 0;
    end;

    local procedure GetProdOrderCompDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrder: Record "Production Order";
    begin
        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrder.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.");
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, ProdOrderComp."Due Date", ProdOrderComp."Location Code", ProdOrderComp."Variant Code",
                    -ProdOrderComp."Remaining Qty. (Base)", -ProdOrderComp."Reserved Qty. (Base)",
                    Database::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrder.Description, DemandType::Production);
            until ProdOrderComp.Next() = 0;
    end;

    local procedure GetTransOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        if TransLine.FindLinesWithItemToPlan(Item, false, false) then
            repeat
                TransHeader.Get(TransLine."Document No.");
                TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, TransLine."Shipment Date", TransLine."Transfer-from Code", TransLine."Variant Code",
                  -TransLine."Outstanding Qty. (Base)", -TransLine."Reserved Qty. Outbnd. (Base)",
                  Database::"Transfer Line", TransLine.Status, TransLine."Document No.", TransHeader."Transfer-to Name", 0);
            until TransLine.Next() = 0;
    end;

    local procedure GetAsmOrderDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        if AsmLine.FindItemToPlanLines(Item, AsmLine."Document Type"::Order) then
            repeat
                AsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                AsmLine.CalcFields("Reserved Qty. (Base)");
                InsertEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Demand, AsmLine."Due Date", AsmLine."Location Code", AsmLine."Variant Code",
                  -AsmLine."Remaining Quantity (Base)", -AsmLine."Reserved Qty. (Base)",
                  Database::"Assembly Line", AsmLine."Document Type".AsInteger(),
                  AsmLine."Document No.", AsmHeader.Description, DemandType::Assembly);
            until AsmLine.Next() = 0;
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
        exit(AsmHeader.ItemToPlanLinesExist(Item, AsmHeader."Document Type"::Order));
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
        exit(AsmLine.ItemToPlanLinesExist(Item, AsmLine."Document Type"::Order));
    end;

    local procedure ClosingEntryExists(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Option; LocationCode: Code[20]; VariantCode: Code[20]; ClosingDate: Date) Found: Boolean
    var
        CopyOfAvailabilityCalcOverview: Record "Availability Calc. Overview";
    begin
        CopyOfAvailabilityCalcOverview.Copy(AvailabilityCalcOverview);
        AvailabilityCalcOverview.SetRange("Item No.", Item."No.");
        AvailabilityCalcOverview.SetRange("Location Code", LocationCode);
        AvailabilityCalcOverview.SetRange("Variant Code", VariantCode);
        AvailabilityCalcOverview.SetRange(Date, ClosingDate);
        AvailabilityCalcOverview.SetRange(Type, NewType);
        Found := AvailabilityCalcOverview.FindFirst();
        AvailabilityCalcOverview.CopyFilters(CopyOfAvailabilityCalcOverview);
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
                if SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::Order) then
                    if DemandNo <> '' then begin
                        SalesLine.SetRange("Document No.", DemandNo);
                        Found := not SalesLine.IsEmpty();
                    end else
                        Found := true;
            DemandType::Production:
                if ProdOrderComp.LinesWithItemToPlanExist(Item, true) then
                    if DemandNo <> '' then begin
                        ProdOrderComp.SetRange("Prod. Order No.", DemandNo);
                        Found := not ProdOrderComp.IsEmpty();
                    end else
                        Found := true;
            DemandType::Service:
                if ServLine.LinesWithItemToPlanExist(Item) then
                    if DemandNo <> '' then begin
                        ServLine.SetRange("Document No.", DemandNo);
                        Found := not ServLine.IsEmpty();
                    end else
                        Found := true;
            DemandType::Job:
                if JobPlanningLine.LinesWithItemToPlanExist(Item) then
                    if DemandNo <> '' then begin
                        JobPlanningLine.SetRange("Job No.", DemandNo);
                        Found := not JobPlanningLine.IsEmpty();
                    end else
                        Found := true;
            DemandType::Assembly:
                if AsmLine.ItemToPlanLinesExist(Item, AsmLine."Document Type"::Order) then
                    if DemandNo <> '' then begin
                        AsmLine.SetRange("Document No.", DemandNo);
                        Found := not AsmLine.IsEmpty();
                    end else
                        Found := true;
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

    procedure InsertEntry(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; NewType: Integer; NewDate: Date; NewLocation: Code[10]; NewVariantCode: Code[10]; NewQuantityBase: Decimal; NewReservQtyBase: Decimal; NewSourceType: Integer; NewSourceOrderStatus: Integer; NewSourceID: Code[20]; NewDescription: Text[100]; NewDemandType: Option)
    var
        CopyOfItem: Record Item;
    begin
        if (NewDate <> 0D) and not (NewDate in [StartDate .. EndDate]) then
            exit;
        CopyOfItem.Copy(Item);
        if NewType in [AvailabilityCalcOverview.Type::"As of Date", AvailabilityCalcOverview.Type::Inventory] then
            if ClosingEntryExists(AvailabilityCalcOverview, NewType, NewLocation, NewVariantCode, NewDate) then begin
                if not AvailabilityCalcOverview."Matches Criteria" then begin
                    AvailabilityCalcOverview."Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                    AvailabilityCalcOverview.Modify();
                end;
                exit;
            end;

        if not (NewType in [AvailabilityCalcOverview.Type::Item, AvailabilityCalcOverview.Type::"As of Date"]) then
            if NewQuantityBase = 0 then
                exit;
        AvailabilityCalcOverview.Init();
        AvailabilityCalcOverview."Entry No." := GetEntryNo();
        AvailabilityCalcOverview.Type := NewType;
        AvailabilityCalcOverview."Item No." := Item."No.";
        AvailabilityCalcOverview.Date := NewDate;
        AvailabilityCalcOverview."Location Code" := NewLocation;
        AvailabilityCalcOverview."Variant Code" := NewVariantCode;
        AvailabilityCalcOverview.Quantity := NewQuantityBase;
        AvailabilityCalcOverview."Reserved Quantity" := NewReservQtyBase;

        if (DemandType = DemandType::" ") or
           (AvailabilityCalcOverview.Type = AvailabilityCalcOverview.Type::"As of Date") or
           ((DemandType = NewDemandType) and (DemandNo in ['', NewSourceID]))
        then
            AvailabilityCalcOverview."Matches Criteria" := NewDate in [StartDate .. EndDate];

        case NewType of
            AvailabilityCalcOverview.Type::Item:
                begin
                    AvailabilityCalcOverview.Level := 0;
                    AvailabilityCalcOverview."Matches Criteria" := true;
                end;
            AvailabilityCalcOverview.Type::Inventory:
                begin
                    AvailabilityCalcOverview."Attached to Entry No." := AvailabilityCalcOverview."Entry No.";
                    AvailabilityCalcOverview.Level := 1;
                    AvailabilityCalcOverview."Inventory Running Total" := AvailabilityCalcOverview.Quantity;
                    AvailabilityCalcOverview."Running Total" := AvailabilityCalcOverview.Quantity;
                end;
            AvailabilityCalcOverview.Type::"As of Date":
                begin
                    AvailabilityCalcOverview."Attached to Entry No." := AvailabilityCalcOverview."Entry No.";
                    AvailabilityCalcOverview.Level := 1;
                    CalcRunningTotals(
                      Item."No.", NewLocation, NewVariantCode, NewDate,
                      AvailabilityCalcOverview."Running Total", AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
                    AllocateToDemand(AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
                    if AvailabilityCalcOverview."Matches Criteria" then
                        AvailabilityCalcOverview."Matches Criteria" := CheckDemandInDate(AvailabilityCalcOverview);
                end;
            else
                AvailabilityCalcOverview."Attached to Entry No." := AttachedToEntryNo;
                AvailabilityCalcOverview.Level := 2;
        end;
        AvailabilityCalcOverview."Source Type" := NewSourceType;
        AvailabilityCalcOverview."Source Order Status" := NewSourceOrderStatus;
        AvailabilityCalcOverview."Source ID" := NewSourceID;
        AvailabilityCalcOverview.Description := NewDescription;

        OnInsertEntryOnBeforeInsert(AvailabilityCalcOverview);
        AvailabilityCalcOverview.Insert();
        Item.Copy(CopyOfItem);
    end;

    local procedure CalcRunningTotals(NewItem: Code[20]; NewLocation: Code[10]; NewVariant: Code[10]; NewDate: Date; var RunningTotal: Decimal; var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(NewItem);
        Item.SetRange("Location Filter", NewLocation);
        Item.SetRange("Variant Filter", NewVariant);
        Item.SetRange("Date Filter", 0D, NewDate);
        Item.CalcFields(
          Item."Reserved Qty. on Purch. Orders",
          Item."Reserved Qty. on Prod. Order",
          Item."Res. Qty. on Inbound Transfer",
          Item."Reserved Qty. on Sales Orders",
          Item."Res. Qty. on Service Orders",
          Item."Res. Qty. on Job Order",
          Item."Res. Qty. on Prod. Order Comp.",
          Item."Res. Qty. on Outbound Transfer",
          Item."Reserved Qty. on Inventory",
          Item."Res. Qty. on Assembly Order",
          Item."Res. Qty. on  Asm. Comp.",
          Item."Res. Qty. on Sales Returns",
          Item."Res. Qty. on Purch. Returns");
        Item.CalcFields(
          Item."Qty. on Purch. Order",
          Item."Scheduled Receipt (Qty.)",
          Item."Planned Order Receipt (Qty.)",
          Item."Trans. Ord. Receipt (Qty.)",
          Item."Qty. on Sales Order",
          Item."Qty. on Service Order",
          Item."Qty. on Job Order",
          Item."Qty. on Component Lines",
          Item."Trans. Ord. Shipment (Qty.)",
          Item.Inventory,
          Item."Qty. on Assembly Order",
          Item."Qty. on Asm. Component",
          Item."Qty. on Purch. Return",
          Item."Qty. on Sales Return");

        SupplyRunningTotal :=
          Item."Qty. on Purch. Order" - Item."Reserved Qty. on Purch. Orders" +
          Item."Qty. on Sales Return" - Item."Res. Qty. on Sales Returns" +
          Item."Scheduled Receipt (Qty.)" + Item."Planned Order Receipt (Qty.)" - Item."Reserved Qty. on Prod. Order" +
          Item."Trans. Ord. Receipt (Qty.)" - Item."Res. Qty. on Inbound Transfer" +
          Item."Qty. on Assembly Order" - Item."Res. Qty. on Assembly Order";
        DemandRunningTotal :=
          -Item."Qty. on Sales Order" + Item."Reserved Qty. on Sales Orders" -
          Item."Qty. on Purch. Return" + Item."Res. Qty. on Purch. Returns" -
          Item."Qty. on Component Lines" + Item."Res. Qty. on Prod. Order Comp." -
          Item."Qty. on Service Order" + Item."Res. Qty. on Service Orders" -
          Item."Qty. on Job Order" + Item."Res. Qty. on Job Order" -
          Item."Trans. Ord. Shipment (Qty.)" + Item."Res. Qty. on Outbound Transfer" -
          Item."Qty. on Asm. Component" + Item."Res. Qty. on  Asm. Comp.";
        InventoryRunningTotal := Item.Inventory - Item."Reserved Qty. on Inventory";

        RunningTotal := InventoryRunningTotal + SupplyRunningTotal + DemandRunningTotal;

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
        FirstEntryNo := AvailabilityCalcOverview."Entry No.";
        if AvailabilityCalcOverview.Date <> 0D then
            CalcRunningTotals(
              AvailabilityCalcOverview."Item No.", AvailabilityCalcOverview."Location Code", AvailabilityCalcOverview."Variant Code", CalcDate('<-1D>', AvailabilityCalcOverview.Date),
              RunningTotal, InventoryRunningTotal, SupplyRunningTotal, DemandRunningTotal);

        repeat
            RunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
            case AvailabilityCalcOverview.Type of
                AvailabilityCalcOverview.Type::Inventory:
                    InventoryRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
                AvailabilityCalcOverview.Type::Supply,
              AvailabilityCalcOverview.Type::"Supply Forecast":
                    SupplyRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
                AvailabilityCalcOverview.Type::Demand:
                    DemandRunningTotal += AvailabilityCalcOverview.Quantity - AvailabilityCalcOverview."Reserved Quantity";
            end;

            AvailabilityCalcOverview."Running Total" := RunningTotal;
            AvailabilityCalcOverview."Inventory Running Total" := InventoryRunningTotal;
            AvailabilityCalcOverview."Supply Running Total" := SupplyRunningTotal;
            AvailabilityCalcOverview."Demand Running Total" := DemandRunningTotal;
            AllocateToDemand(AvailabilityCalcOverview."Inventory Running Total", AvailabilityCalcOverview."Supply Running Total", AvailabilityCalcOverview."Demand Running Total");
            if DemandType = DemandType::" " then
                AvailabilityCalcOverview."Matches Criteria" := CopyOfAvailCalcOverview."Matches Criteria";

            OnUpdateRunningTotalsOnBeforeModify(AvailabilityCalcOverview);
            AvailabilityCalcOverview.Modify();
        until AvailabilityCalcOverview.Next() = 0;
        AvailabilityCalcOverview.Get(FirstEntryNo);
        if AvailabilityCalcOverview.Next() = 0 then;
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
    local procedure OnAfterCalcRunningTotals(var Item: Record Item; var RunningTotal: Decimal; var InventoryRunningTotal: Decimal; var SupplyRunningTotal: Decimal; var DemandRunningTotal: Decimal)
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

