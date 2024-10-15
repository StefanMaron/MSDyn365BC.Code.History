codeunit 137353 "SCM Inventory Valuation - WIP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Inventory Valuation - WIP] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        isInitialized: Boolean;
        OriginalWorkDate: Date;

    [Test]
    [HandlerFunctions('ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS288092()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInv: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();

        // Setup.
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryERM.SetAllowPostingFromTo(WorkDate() - 30, WorkDate());
        SetupInventoryForReport(ParentItem, ChildItem, PurchaseHeader, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::FIFO,
          ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());

        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), 0);
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Invoice a purchase charge to the component item.
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindFirst();
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInv, PurchaseHeaderInv."Document Type"::Invoice, Vendor."No.");
        LibraryPatterns.ASSIGNPurchChargeToPurchRcptLine(PurchaseHeaderInv, PurchRcptLine, 1, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInv, true, true);

        // Exercise. Adjust and run Inventory Valuation - WIP report.
        LibraryERM.SetAllowPostingFromTo(WorkDate() + 1, WorkDate() + 30);
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Verify.
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate() - 30, WorkDate());
        VerifyInventoryValuationWIPReport(ProductionOrder, WorkDate() - 30, WorkDate(), false);
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate() + 1, WorkDate() + 30);
        VerifyInventoryValuationWIPReport(ProductionOrder, WorkDate() + 1, WorkDate() + 30, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS311446()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        EndingDate: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDecInRange(10, 100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        EndingDate := WorkDate() + LibraryRandom.RandInt(10);

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::FIFO,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());

        LibraryPatterns.POSTOutput(ProdOrderLine, LibraryRandom.RandDecInDecimalRange(1, Qty, 2), WorkDate(), 0);
        PostExplodedOutput(ProdOrderLine, EndingDate, ProdOrderLine.Quantity, 0);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Exercise. Adjust, revalue and run Inventory Valuation - WIP report.
        AdjustAndRevalueParent(ParentItem, ChildItem, EndingDate, "Inventory Value Calc. Per"::"Item Ledger Entry");
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate(), EndingDate);

        // Verify. Inventory Valuation - WIP report.
        VerifyInventoryValuationWIPReport(ProductionOrder, WorkDate(), EndingDate, false);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS315987()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        OutputDate: Date;
        InvoiceDate: Date;
        RevalDate: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        OutputDate := WorkDate() + LibraryRandom.RandInt(5);
        InvoiceDate := OutputDate + LibraryRandom.RandInt(5);
        RevalDate := InvoiceDate + LibraryRandom.RandInt(5);

        // Setup. Make BOM structure.
        SetupInventoryForReport(ParentItem, ChildItem, PurchaseHeader, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), 0);
        PostExplodedOutput(ProdOrderLine, OutputDate, ProdOrderLine.Quantity, 0);

        // Invoice the purchase with a different cost.
        InvoiceDiffPurchaseCost(PurchaseHeader, InvoiceDate);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Exercise. Adjust, revalue and run Inventory Valuation - WIP report.
        AdjustAndRevalueParent(ParentItem, ChildItem, RevalDate, "Inventory Value Calc. Per"::Item);

        // Verify.
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate(), InvoiceDate + 1);
        VerifyInventoryValuationWIPReport(ProductionOrder, WorkDate(), InvoiceDate + 1, false);

        RunInventoryValuationWIPReport(ProductionOrder."No.", InvoiceDate + 1, RevalDate + 1);
        VerifyInventoryValuationWIPReport(ProductionOrder, InvoiceDate + 1, RevalDate + 1, false);

        RunInventoryValuationWIPReport(ProductionOrder."No.", RevalDate + 1, RevalDate + 30);
        VerifyInventoryValuationWIPReport(ProductionOrder, RevalDate + 1, RevalDate + 30, false);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS252682()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        ExecuteUIHandlers();
        LibraryERM.SetAllowPostingFromTo(0D, 0D);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::FIFO,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());

        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), 0);
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Exercise. Adjust, revalue and run Inventory Valuation - WIP report.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate() - 30, WorkDate());

        // Verify. Inventory Valuation - WIP report.
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, WorkDate() - 30, WorkDate(), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS340491A()
    var
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        DirectUnitCost: Decimal;
        InvoiceDate: Date;
        TempDate: Date;
    begin
        // Also for SICILY 46166, 48268
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, 0D);
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        DirectUnitCost := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReport(ParentItem, ChildItem, PurchaseHeader, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());
        LibraryPatterns.MAKERouting(RoutingHeader, ParentItem, '', DirectUnitCost);
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Finish production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Exercise. Adjust, change G/L Setup and invoice the purchase at a different cost.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
        InvoiceDate := CalcDate('<+2M>', WorkDate());
        TempDate := CalcDate('<-CM>', InvoiceDate);
        LibraryERM.SetAllowPostingFromTo(TempDate, CalcDate('<CM>', TempDate));
        InvoiceDiffPurchaseCost(PurchaseHeader, InvoiceDate);
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the prod. order output.
        TempDate := CalcDate('<-CM>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueOfOutput', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month between the prod. output and the purchase invoicing.
        TempDate := CalcDate('<CM-1M>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the purchase invoicing.
        TempDate := CalcDate('<-CM>', InvoiceDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueOfOutput', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month after the purchase invoicing.
        TempDate := CalcDate('<+1M>', CalcDate('<+1M>', InvoiceDate));
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);

        // Tear down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS340491B()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        FinishDate: Date;
        TempDate: Date;
    begin
        // Also for SICILY 46166, 48268
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine,
          ParentItem."Costing Method"::Standard, ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Adjust, Revalue unit cost of comp.
        AdjustAndRevalueChild(ParentItem, ChildItem, WorkDate(), "Inventory Value Calc. Per"::"Item Ledger Entry");

        // Setup. Post consumption & output for production order.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the purchase and revaluation.
        TempDate := CalcDate('<-CM>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('Row should be found.', 42868);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month after.
        TempDate := CalcDate('<-CM>', CalcDate('<+1M>', WorkDate()));
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 42868);
        end;

        // Setup. Finish production order, change G/L Setup and adjust cost.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);
        FinishDate := CalcDate('<+2M>', WorkDate());
        TempDate := CalcDate('<-CM>', FinishDate);
        LibraryERM.SetAllowPostingFromTo(TempDate, CalcDate('<CM>', TempDate));
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Exercise. Verify Inventory Valuation - WIP report for the month before the production finishing.
        TempDate := CalcDate('<-CM>', CalcDate('<-1M>', FinishDate));
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueOfOutput', 42868);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the production finishing.
        TempDate := CalcDate('<-CM>', FinishDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueOfOutput', 42868);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month after.
        TempDate := CalcDate('<+1M>', CalcDate('<+1M>', FinishDate));
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);

        // Tear down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS326574()
    var
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        DirectUnitCost: Decimal;
        InvoiceDate: Date;
        TempDate: Date;
    begin
        // Also for VSTF 329005
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        DirectUnitCost := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReport(ParentItem, ChildItem, PurchaseHeader, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());
        LibraryPatterns.MAKERouting(RoutingHeader, ParentItem, '', DirectUnitCost);
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Refresh production order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);

        // Setup. Change work date to next months, penultimate date
        TempDate := CalcDate('<CM+1M-1D>', WorkDate());

        // Setup. Post production order.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, TempDate, ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, TempDate, ProdOrderLine.Quantity, 0);

        // Setup. Re-valuate the production item.
        TempDate := CalcDate('<CM>', WorkDate()); // last date of the month
        AdjustAndRevalueParent(ParentItem, ChildItem, TempDate, "Inventory Value Calc. Per"::Item);

        // Setup. Invoice purchase order after changing the cost.
        InvoiceDate := TempDate; // same as revaluation date
        InvoiceDiffPurchaseCost(PurchaseHeader, InvoiceDate);

        // Setup. Set Allow posting from
        TempDate := CalcDate('<1D>', InvoiceDate);
        LibraryERM.SetAllowPostingFromTo(TempDate, CalcDate('<CM>', TempDate));

        // Setup. Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the prod. order output.
        TempDate := CalcDate('<-1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month between the prod. output and the purchase invoicing.
        TempDate := CalcDate('<1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueOfOutput', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the purchase invoicing.
        TempDate := CalcDate('<1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);

        // Tear down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS291431()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        DirectUnitCost: Decimal;
        TempDate: Date;
    begin
        // Also for 285890
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        DirectUnitCost := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());
        LibraryPatterns.MAKERouting(RoutingHeader, ParentItem, '', DirectUnitCost);
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Post production order.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Setup. Post additional outputs (positive extra and then negative to undo it)
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);
        ItemLedgerEntry.SetRange("Item No.", ParentItem."No.");
        ItemLedgerEntry.FindLast();
        PostExplodedOutput(ProdOrderLine, WorkDate(), -ProdOrderLine.Quantity, ItemLedgerEntry."Entry No.");

        // Setup. Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Setup. Adjust and Revalue 2nd output
        AdjustAndRevalueParentAppliesTo(ParentItem, ChildItem, WorkDate(), "Inventory Value Calc. Per"::"Item Ledger Entry", ItemLedgerEntry."Entry No.");

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the prod. order output.
        TempDate := CalcDate('<-1M>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS336376()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        TempDate: Date;
        OrigWorkDate: Date;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Post production order.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Setup. Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Setup. Change G/L Setup
        OrigWorkDate := WorkDate();
        TempDate := CalcDate('<5W>', WorkDate());
        WorkDate := TempDate;
        LibraryERM.SetAllowPostingFromTo(TempDate, CalcDate('<CM>', TempDate));

        // Setup. Adjust cost
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the prod. order output.
        TempDate := CalcDate('<-CM>', OrigWorkDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month.
        TempDate := CalcDate('<1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month.
        TempDate := CalcDate('<1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,MsgHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS330586()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        TempDate: Date;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, false, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Post production order.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Setup. Revaluate parent Per Item
        AdjustAndRevalueParent(ParentItem, ChildItem, WorkDate() + 2, "Inventory Value Calc. Per"::Item);

        // Setup. Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the prod. order output.
        TempDate := CalcDate('<-CM>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month.
        TempDate := CalcDate('<1M>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler,MsgHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS341917()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        Qty: Decimal;
        QtyPer: Decimal;
        FirstOutputQty: Decimal;
        FirstOutputDate: Date;
        TempDate: Date;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, true,
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Setup. Post output 3 months from WORKDATE.
        TempDate := CalcDate('<3M>', WorkDate());
        FirstOutputQty := LibraryRandom.RandDec(Round(Qty, 1), 2);
        FirstOutputDate := TempDate;
        PostExplodedOutput(ProdOrderLine, TempDate, FirstOutputQty, 0);

        // Setup. Post consumption 3 months + 3D from WORKDATE.
        TempDate := CalcDate('<3M+3D>', WorkDate());
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, TempDate, ChildItem."Unit Cost");

        // Setup. Move workdate to 1 monh and 2 weeks after consumption posting
        WorkDate := CalcDate('<1M+2W>', TempDate);

        // Setup. Post remaining output.
        PostExplodedOutput(ProdOrderLine, WorkDate(), Qty - FirstOutputQty, 0);

        // Setup. Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Setup. Change G/L Setup
        TempDate := CalcDate('<CM+1D>', WorkDate());
        LibraryERM.SetAllowPostingFromTo(TempDate, 0D);

        // Setup. Adjust cost.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Setup. Revert change in GL Setup
        LibraryERM.SetAllowPostingFromTo(0D, 0D);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the FirstOutputDate.
        TempDate := CalcDate('<-CM>', FirstOutputDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month
        TempDate := CalcDate('<CM+1D>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month
        TempDate := CalcDate('<CM+1D>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the next month
        TempDate := CalcDate('<CM+1D>', TempDate);
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MsgHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TFS260910()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        QtyPer: Decimal;
        TempDate: Date;
    begin
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, true,
          InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::Standard,
          ChildItem."Costing Method"::Standard, true, Qty, QtyPer, WorkDate());

        // Setup. Post production order on WORKDATE.
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, WorkDate(), ChildItem."Unit Cost");
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the output.
        TempDate := CalcDate('<-CM>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Setup. Adjust cost.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Exercise. Verify Inventory Valuation - WIP report for the month containing the output.
        TempDate := CalcDate('<-CM>', WorkDate());
        RunInventoryValuationWIPReport(ProductionOrder."No.", TempDate, CalcDate('<CM>', TempDate));
        asserterror
        begin
            VerifyInventoryValuationWIPReport(ProductionOrder, TempDate, CalcDate('<CM>', TempDate), true);
            Assert.KnownFailure('ValueEntryCostPostedToGL', 48268);
        end;

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(InventorySetup, false, false,
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialOutputInFirstAndThirdPeriodButInvoicedInForthPeriod()
    var
        InventorySetup: Record "Inventory Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        QtyPer: Decimal;
        FirstOutputQty: Decimal;
        Output: Decimal;
        Consumption: Decimal;
        ExpectedOpenningBalance: Decimal;
        FirstOutputDate: Date;
        ConsumptionDate: Date;
    begin
        // For bug 49838 on Sicily.

        // Verify the Openning Balance on period 3 on Inventory Valuation - WIP Report after making output on period 1 & 3 but invoicing on period 4.
        Initialize();
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandDec(5, 2);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // Setup. Make BOM structure.
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine,
          ParentItem."Costing Method"::Standard, ChildItem."Costing Method"::FIFO, true, Qty, QtyPer, WorkDate());
        CalcStandardCost.CalcItem(ParentItem."No.", false);

        // Post output 3M from WORKDATE.
        FirstOutputQty := LibraryRandom.RandDec(Round(Qty, 1), 2);
        FirstOutputDate := CalcDate('<3M>', WorkDate()); // Value Not important for test(Period 1).
        LibraryPatterns.POSTOutput(ProdOrderLine, FirstOutputQty, FirstOutputDate, ParentItem."Standard Cost");

        // Post consumption 3M+3D from WORKDATE.
        ConsumptionDate := CalcDate('<3M+3D>', WorkDate()); // Value Not important for test - but need to the same period of FirstOutPutDate(Period 1).
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty * QtyPer, ConsumptionDate, ChildItem."Unit Cost");

        // Move workdate to 2M after consumption posting.
        WorkDate := CalcDate('<2M>', ConsumptionDate); // Value Not important for test - but need to the different period of FirstOutPutDate(Period 3).

        // Post remaining output in Period 3.
        LibraryPatterns.POSTOutput(ProdOrderLine, Qty - FirstOutputQty, WorkDate(), ParentItem."Standard Cost");

        // Finish the released production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Change G/L Setup.
        LibraryERM.SetAllowPostingFromTo(CalcDate('<CM+1D>', WorkDate()), 0D); // Value Not important for test - but need to the different period of outputing the remaining output(Period 4).

        // Adjust cost.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');

        // Revert change in GL Setup.
        LibraryERM.SetAllowPostingFromTo(0D, 0D);

        Output := -GetExpectedWIPCostAmount(ProductionOrder."No.", FirstOutputDate);
        Consumption := -GetExpectedWIPCostAmount(ProductionOrder."No.", ConsumptionDate);
        ExpectedOpenningBalance := Output + Consumption;

        // Exercise. Run Inventory Valuation - WIP Report for the period 3.
        RunInventoryValuationWIPReport(ProductionOrder."No.", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // Verify. Verify the Opening Balance of the period 3 on Inventory Valuation - WIP report.
        VerifyOpenningBalanceOnInventoryValuationWIPReport(ProductionOrder."No.", ExpectedOpenningBalance);

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment",
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationReportForNotCompletelyInvoicedFinishedPO()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Production Order] [Inventory Valuation Report]
        // [SCENARIO 376048] The Inventory Valuation Report should show balance for Finished Production Orders that are not Completely Invoiced
        Initialize();

        // [GIVEN] Not Completely Invoiced Finished Production Order for Item with "Unit Cost" = "X" and Quantity = "Y"
        Qty := LibraryRandom.RandInt(100);
        LibraryERM.SetAllowPostingFromTo(WorkDate() - 30, WorkDate());
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::FIFO,
          ChildItem."Costing Method"::FIFO, true, Qty, 1, WorkDate());
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty, WorkDate(), 0);
        PostExplodedOutput(ProdOrderLine, WorkDate(), ProdOrderLine.Quantity, 0);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [WHEN] Run Inventory Valuation Report
        RunInventoryValuationWIPReport(ProductionOrder."No.", CalcDate('<+1M>', WorkDate()), CalcDate('<+2M>', WorkDate()));

        // [THEN] Inventory Valuetion Report is created with Expected Openning Balance = - "X" * "Y"
        VerifyOpenningBalanceOnInventoryValuationWIPReport(ProductionOrder."No.", -ParentItem."Unit Cost" * Qty);
    end;

    [Test]
    [HandlerFunctions('InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPShowsOpeningBalanceWhenNoEntriesWithinPeriod()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Integer;
    begin
        // [SCENARIO] Report "Inventory Valuation - WIP" should show opening balance when there are consumption entries posted before the reporting period, and no value entries posted within the period

        Initialize();

        // [GIVEN] Create a manufactured item with one component.
        // [GIVEN] Purchase component with unit cost = "X"
        // [GIVEN] Create a released production order "PO"
        Qty := LibraryRandom.RandInt(100);
        SetupInventoryForReportWithoutPurchOrder(
          ParentItem, ChildItem, ProductionOrder, ProdOrderLine, ParentItem."Costing Method"::FIFO,
          ChildItem."Costing Method"::FIFO, true, Qty, 1, WorkDate());

        // [GIVEN] Post consumption of "Y" items from "PO", posting date is 25.01
        LibraryPatterns.POSTConsumption(ProdOrderLine, ChildItem, '', '', Qty, WorkDate(), 0);
        // [GIVEN] Post output from "PO", posting date is 27.01
        PostProdOrderOutput(ProductionOrder, ParentItem."No.", WorkDate() + 2);

        // [GIVEN] Finish the production order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate() + 2, true);

        // [GIVEN] Adjust cost of both component and manufactured items
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ChildItem."No.", ParentItem."No."), '');

        // [WHEN] Run the report "Inventory Valuation - WIP" with date filter on 26.01
        RunInventoryValuationWIPReport(ProductionOrder."No.", WorkDate() + 1, WorkDate() + 1);

        // [THEN] Opening balance in the report is "X" * "Y"
        ParentItem.Find();
        VerifyOpenningBalanceOnInventoryValuationWIPReport(ProductionOrder."No.", ParentItem."Unit Cost" * Qty);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Valuation - WIP");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then begin
            WorkDate := OriginalWorkDate;
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Valuation - WIP");
        OriginalWorkDate := WorkDate();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPatterns.SetNoSeries();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Valuation - WIP");
    end;

    [Normal]
    local procedure AdjustAndRevalueParent(ParentItem: Record Item; ChildItem: Record Item; RevalDate: Date; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, ParentItem, RevalDate, CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandIntInRange(3, 10));
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
    end;

    [Normal]
    local procedure AdjustAndRevalueParentAppliesTo(ParentItem: Record Item; ChildItem: Record Item; RevalDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, ParentItem, RevalDate, CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyAppliesToPostRevaluation(ItemJournalBatch, LibraryRandom.RandIntInRange(3, 10), AppliesToEntry);
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
    end;

    [Normal]
    local procedure AdjustAndRevalueChild(ParentItem: Record Item; ChildItem: Record Item; RevalDate: Date; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, ChildItem, RevalDate, CalculatePer, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandIntInRange(3, 10));
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + ChildItem."No.", '');
    end;

    [Normal]
    local procedure InvoiceDiffPurchaseCost(PurchaseHeader: Record "Purchase Header"; InvoiceDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost",
          PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify();
        PurchaseHeader.Validate("Posting Date", InvoiceDate);
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    [Normal]
    local procedure PostExplodedOutput(ProdOrderLine: Record "Prod. Order Line"; PostingDate: Date; OutputQty: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, PostingDate);
        with ItemJournalLine do begin
            SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
            SetRange("Journal Batch Name", ItemJournalBatch.Name);
            SetRange("Entry Type", "Entry Type"::Output);
            SetRange("Order Type", "Order Type"::Production);
            SetRange("Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Order Line No.", ProdOrderLine."Line No.");
            if FindSet() then
                repeat
                    ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
                    ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                    ProdOrderRoutingLine.SetRange("Operation No.", "Operation No.");
                    if ProdOrderRoutingLine.FindFirst() then begin
                        Validate("Setup Time", ProdOrderRoutingLine."Setup Time");
                        Validate("Run Time", ProdOrderRoutingLine."Run Time");
                        Validate("Output Quantity", OutputQty);
                        if OutputQty < 0 then
                            Validate("Applies-to Entry", AppliesToEntry);
                        Modify();
                    end;
                until Next() = 0;
        end;
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostProdOrderOutput(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrder."No.");

        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure GetExpectedWIPDistribution(var BOPCostPostedToGL: Decimal; var BOP: Decimal; var Output: Decimal; var Consumption: Decimal; var Capacity: Decimal; var EOP: Decimal; var ConsumptionPostedToGL: Decimal; var OutputPostedToGL: Decimal; var CapacityPostedToGL: Decimal; var Visible: Boolean; ProductionOrder: Record "Production Order"; StartDate: Date; EndDate: Date)
    var
        ValueEntry: Record "Value Entry";
        BOPConsumptionPostedToGL: Decimal;
        BOPOutputPostedToGL: Decimal;
        BOPCapacityPostedToGL: Decimal;
        Sign: Integer;
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.SetFilter("Posting Date", '<%1', StartDate);
        ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::" ");

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.CalcSums("Cost Posted to G/L", "Expected Cost Posted to G/L");
        BOPOutputPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.CalcSums("Cost Posted to G/L", "Expected Cost Posted to G/L");
        BOPCapacityPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Consumption);
        ValueEntry.CalcSums("Cost Posted to G/L", "Expected Cost Posted to G/L");
        BOPConsumptionPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";

        BOPCostPostedToGL := CalculateNetCost(0, BOPConsumptionPostedToGL, BOPOutputPostedToGL, BOPCapacityPostedToGL);

        ValueEntry.SetRange("Item Ledger Entry Type");
        ValueEntry.SetRange("Posting Date", StartDate, EndDate);
        if ValueEntry.IsEmpty() and ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.") then
            exit;

        Visible := true;

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        if ValueEntry.Count = 1 then begin
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
            if ValueEntry.Count = 1 then // If revaluation entry is the only output value entry.
                ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation)
            else
                ValueEntry.SetRange("Entry Type");
        end;
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)", "Cost Posted to G/L", "Expected Cost Posted to G/L");
        OutputPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";
        Output := ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
        ValueEntry.SetRange("Entry Type");

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)", "Cost Posted to G/L", "Expected Cost Posted to G/L");
        CapacityPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";
        Capacity := ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Consumption);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)", "Cost Posted to G/L", "Expected Cost Posted to G/L");
        ConsumptionPostedToGL := ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L";
        Consumption := ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";

        ValueEntry.SetFilter("Posting Date", '<%1', StartDate);
        ValueEntry.SetRange("Item Ledger Entry Type");
        if ValueEntry.FindSet() then
            repeat
                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::" " then
                    Sign := -1 // negating the capacity cost.
                else
                    Sign := 1;
                BOP += Sign * (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
            until ValueEntry.Next() = 0;

        EOP := CalculateNetCost(BOP, Consumption, Output, Capacity);
    end;

    local procedure GetExpectedWIPCostAmount(OrderNo: Code[20]; PostingDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Order No.", OrderNo);
            SetRange("Posting Date", PostingDate);
            FindFirst();
            if "Item Ledger Entry Type" = "Item Ledger Entry Type"::Output then
                exit("Cost Amount (Expected)");
            exit("Cost Amount (Actual)");
        end;
    end;

    local procedure CalculateNetCost(BOP: Decimal; Consumption: Decimal; Output: Decimal; Capacity: Decimal): Decimal
    begin
        exit(BOP + Consumption + Output - Capacity);
    end;

    [Normal]
    local procedure SetupInventoryForReport(var ParentItem: Record Item; var ChildItem: Record Item; var PurchaseHeader: Record "Purchase Header"; var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ParentCostingMethod: Enum "Costing Method"; ChildCostingMethod: Enum "Costing Method"; Invoice: Boolean; Qty: Decimal; QtyPer: Decimal; ReceiptDate: Date)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Make BOM structure.
        LibraryPatterns.MAKEItemSimple(ParentItem, ParentCostingMethod, LibraryRandom.RandDec(100, 2));
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify();
        LibraryPatterns.MAKEItemSimple(ChildItem, ChildCostingMethod, LibraryRandom.RandDec(100, 2));
        LibraryPatterns.MAKEProductionBOM(ProductionBOMHeader, ParentItem, ChildItem, QtyPer, '');

        // Receive and invoice component.
        LibraryPatterns.POSTPurchaseOrder(PurchaseHeader, ChildItem, '', '', Round(Qty * QtyPer, 1, '>'), ReceiptDate,
          LibraryRandom.RandDec(100, 2), true, Invoice);

        // Make prod order.
        LibraryPatterns.MAKEProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '',
          Qty, ReceiptDate);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure SetupInventoryForReportWithoutPurchOrder(var ParentItem: Record Item; var ChildItem: Record Item; var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ParentCostingMethod: Enum "Costing Method"; ChildCostingMethod: Enum "Costing Method"; Invoice: Boolean; Qty: Decimal; QtyPer: Decimal; ReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        SetupInventoryForReport(
          ParentItem, ChildItem, PurchaseHeader, ProductionOrder, ProdOrderLine,
          ParentCostingMethod, ChildCostingMethod, Invoice, Qty, QtyPer, ReceiptDate);
    end;

    local procedure RunInventoryValuationWIPReport(ProductionOrderNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        Commit();

        ProductionOrder.SetRange("No.", ProductionOrderNo);
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);
    end;

    [Normal]
    local procedure VerifyInventoryValuationWIPReport(ProductionOrder: Record "Production Order"; StartDate: Date; EndDate: Date; CostPosting: Boolean)
    var
        BOPCostPostedToGL: Decimal;
        BOP: Decimal;
        EOP: Decimal;
        Output: Decimal;
        Consumption: Decimal;
        Capacity: Decimal;
        ConsumptionPostedToGL: Decimal;
        OutputPostedToGL: Decimal;
        CapacityPostedToGL: Decimal;
        Visible: Boolean;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrder."No.");

        GetExpectedWIPDistribution(BOPCostPostedToGL, BOP, Output, Consumption, Capacity, EOP,
          ConsumptionPostedToGL, OutputPostedToGL, CapacityPostedToGL,
          Visible, ProductionOrder, StartDate, EndDate);

        if Visible then begin
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Row should be found.');
            LibraryReportDataset.AssertCurrentRowValueEquals('LastWIP', -BOP);
            LibraryReportDataset.AssertCurrentRowValueEquals('LastOutput', -Output);
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfCap', Capacity);
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfMatConsump', -Consumption);
            LibraryReportDataset.AssertCurrentRowValueEquals('AtLastDate', -EOP);

            // Verify expected and actual cost posted to GL are included in the report (if any).
            if CostPosting then begin
                LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfOutput', -OutputPostedToGL);
                LibraryReportDataset.AssertCurrentRowValueEquals('ValueEntryCostPostedtoGL',
                  -CalculateNetCost(BOPCostPostedToGL, ConsumptionPostedToGL, OutputPostedToGL, CapacityPostedToGL));
            end;
        end else
            Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'Report should be empty.')
    end;

    local procedure VerifyOpenningBalanceOnInventoryValuationWIPReport(ProductionOrderNo: Code[20]; ExpectedOpenningBalance: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrderNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LastWIP', ExpectedOpenningBalance);
    end;

    local procedure ExecuteUIHandlers()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        Message('');
        if Confirm('') then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPRequestPageHandler(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);

        InventoryValuationWIP.StartingDate.SetValue(StartDate);
        InventoryValuationWIP.EndingDate.SetValue(EndDate);

        InventoryValuationWIP.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;  // finish prod order confirmation.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 2; // Calc standard cost on all levels.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;
}

