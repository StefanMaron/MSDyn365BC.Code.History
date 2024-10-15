codeunit 144018 "SCM Inventory Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Inventory] [Reports]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ProfitErr: Label 'Contribution Margin (Profit) column is not correct.';
        FieldInvisibleErr: Label 'The Field is invisible.';

    [Test]
    [HandlerFunctions('ItemStatusBySalespersonPageHandler')]
    [Scope('OnPrem')]
    procedure ItemStatusBySalespersonReportWithContributionMargin()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        UnitCostRevalued: Decimal;
        Quantity1: Decimal;
        Quantity2: Decimal;
        SalesAmount1: Decimal;
        SalesAmount2: Decimal;
        ExpectedProfit: Decimal;
    begin
        // Verify Item Status by Salesperson report for Contribution Margin column with cost adjustments.

        // Setup: Create Item, Create and Post Item Journal Line, Create and Post Sales Order.
        Initialize;
        CreateItem(Item);

        Quantity1 := LibraryRandom.RandDec(10, 2); // Use Random value for Sales Order 1 Quantity.
        Quantity2 := LibraryRandom.RandDec(10, 2); // Use Random value for Sales Order 2 Quantity.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity1 + Quantity2, WorkDate);

        SalesAmount1 := CreateAndPostSalesOrder(SalesLine, CreateCustomer, Item."No.", Quantity1);
        SalesAmount2 := CreateAndPostSalesOrder(SalesLine, CreateCustomer, Item."No.", Quantity2);

        // Setup: Post Revaluation Journal.
        UnitCostRevalued := UpdateUnitCostAndPostRevaluationJournal(Item."No.");

        // Setup: Run Adjust Cost - Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Exercise: Run report 10052 - Item Status by Salesperson.
        Commit();
        ValueEntry.SetRange("Item No.", Item."No.");
        REPORT.Run(REPORT::"Item Status by Salesperson", true, false, ValueEntry);

        // Verify: Check Contribution Margin (Profit) column is correct. The same as report 10049.
        LibraryReportDataset.LoadDataSetFile;
        ExpectedProfit := SalesAmount1 + SalesAmount2 - UnitCostRevalued * (Quantity1 + Quantity2);
        Assert.AreNearlyEqual(ExpectedProfit, LibraryReportDataset.Sum('Profit'), LibraryERM.GetAmountRoundingPrecision, ProfitErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvToGLReconcileReportStartsFromItemList()
    var
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [Item] [UI] [UT]
        // [SCENARIO 260822] "Inventory to G/L Reconcile" report must be able to start from Item List for #Suite app. area

        Initialize;

        LibraryApplicationArea.EnableFoundationSetup;

        ItemList.OpenEdit;
        Assert.IsTrue(ItemList."Inventory to G/L Reconcile".Visible, FieldInvisibleErr);

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationInboundOutboundOnSameDate()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PositiveQty: Decimal;
        NegativeQty: Decimal;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 259492] Both inbound and outbound item ledger entries are included in the "Inventory Valuation" report when entries are within the report period
        Initialize;

        PositiveQty := LibraryRandom.RandDecInRange(100, 200, 2);
        NegativeQty := LibraryRandom.RandDec(Round(PositiveQty, 1, '<') - 1, 2);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item "I", purchased 100 pcs on 21.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", PositiveQty, WorkDate);

        // [GIVEN] Sold 90 pcs on 21.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", NegativeQty, WorkDate);

        // [WHEN] Run "Inventory Valuation" report on 22.01
        RunInventoryValuationReport(Item."No.", WorkDate + 1);

        // [THEN] Report shows remaining quantity of 10 pcs
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.FindRow('Item__No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('RemainingQty', PositiveQty - NegativeQty);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationInboundLaterThanOutbound()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 259492] Inbound item ledger entry is not included in the "Inventory Valuation" report when it's posted later than report period, outbound entry is within period

        Initialize;

        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Item "I", purchased 100 pcs on 23.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, WorkDate + 2);
        Qty := LibraryRandom.RandDec(Round(Qty, 1, '<'), 2);

        // [GIVEN] Sold 90 pcs on 21.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, WorkDate);

        // [WHEN] Run "Inventory Valuation" report on 22.01
        RunInventoryValuationReport(Item."No.", WorkDate + 1);

        // [THEN] Report shows remaining quantity of -90 pcs
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.FindRow('Item__No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('RemainingQty', -Qty);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationOutboundPostedEarlierOnLaterDate()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 259492] Outbound item ledger entry is not included in the "Inventory Valuation" report when it's posted later than report period, inbound entry is within period

        Initialize;

        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Item "I", sold 90 pcs on 23.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, WorkDate + 2);
        Qty += LibraryRandom.RandDec(50, 2);

        // [GIVEN] Purchase 100 pcs on 21.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, WorkDate);

        // [WHEN] Run "Inventory Valuation" report on 22.01
        RunInventoryValuationReport(Item."No.", WorkDate + 1);

        // [THEN] Report shows remaining quantity of 100 pcs
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.FindRow('Item__No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('RemainingQty', Qty);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationOutboundPostedEarlierOnEarlierDate()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Valuation]
        // [SCENARIO 259492] Inbound item ledger entry is not included in the "Inventory Valuation" report when it's posted later than report period, oubbound entry is posted before inbound

        Initialize;

        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Item "I", sold 90 pcs on 21.01
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", Qty, WorkDate);

        // [GIVEN] Purchased 100 pcs on 23.01
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandDec(Round(Qty, 1, '<'), 2), WorkDate + 2);

        // [WHEN] Run "Inventory Valuation" report on 22.01
        RunInventoryValuationReport(Item."No.", WorkDate + 1);

        // [THEN] Report shows remaining quantity of -90 pcs
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.FindRow('Item__No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('RemainingQty', -Qty);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('InventoryValuationVerifyAARequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventroryValuationRequestPageElementsApplicationArea()
    begin
        // [SCENARIO 292447] All request page elements of Inventory Valuation report should be visible in SaaS
        Initialize;

        // [GIVEN] Enable foundation setup
        LibraryApplicationArea.EnableFoundationSetup;

        // [WHEN] Inventory Valuation report is being run
        Commit();
        RunInventoryValuationReport('', WorkDate);

        // [THEN] All 4 elements of requies page should be visible (verification inside InventoryValuationVerifyAARequestPageHandler)
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports");
        // Lazy Setup.
        LibraryVariableStorage.Clear;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports");
    end;

    [Scope('OnPrem')]
    procedure CreateItem(var Item: Record Item): Code[20]
    var
        UnitCost: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        UnitCost := LibraryRandom.RandDec(10, 2); // Use Random value for Unit Cost and Unit Price.
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Unit Price", 2 * UnitCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Option)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
        LibraryUtility.GenerateGUID;  // To avoid 'Item Journal Batch already exists' error.
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateCustomer(Customer);
        SalespersonPurchaser.FindFirst;
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Line Amount");
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ClearRevaluationJournalLines(ItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::" ");
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure ClearRevaluationJournalLines(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.SetupNewBatch;
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst;
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure RunInventoryValuationReport(ItemNo: Code[20]; ValuationDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryVariableStorage.Enqueue(ValuationDate);
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);
    end;

    [Scope('OnPrem')]
    procedure SelectGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        // Filter General Posting Setup so that errors are not generated due to mandatory fields.
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("COGS Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("COGS Account (Interim)", '<>''''');
        GeneralPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Credit Memo Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Credit Memo Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Direct Cost Applied Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Overhead Applied Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purchase Variance Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        GeneralPostingSetup.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure SelectVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        // Filter VAT Posting Setup so that errors are not generated due to mandatory fields.
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.FindFirst;
    end;

    local procedure UpdateUnitCostAndPostRevaluationJournal(ItemNo: Code[20]): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Revaluation Journal for Item.
        CreateRevaluationJournal(ItemJournalLine, ItemNo, FindItemLedgerEntryNo(ItemNo));
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Revalued)" + LibraryRandom.RandInt(100)); // Update Unit Cost Revalued with Random Value.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(ItemJournalLine."Unit Cost (Revalued)");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatusBySalespersonPageHandler(var ItemStatusBySalesperson: TestRequestPage "Item Status by Salesperson")
    begin
        ItemStatusBySalesperson.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    begin
        InventoryValuation.AsOfDate.SetValue(LibraryVariableStorage.DequeueDate);
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationVerifyAARequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    begin
        Assert.IsTrue(InventoryValuation.AsOfDate.Visible, FieldInvisibleErr);
        Assert.IsTrue(InventoryValuation.BreakdownByVariants.Visible, FieldInvisibleErr);
        Assert.IsTrue(InventoryValuation.BreakdownByLocation.Visible, FieldInvisibleErr);
        Assert.IsTrue(InventoryValuation.UseAdditionalReportingCurrency.Visible, FieldInvisibleErr);
    end;
}

