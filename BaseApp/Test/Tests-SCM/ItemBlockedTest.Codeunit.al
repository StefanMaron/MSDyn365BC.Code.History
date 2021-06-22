codeunit 134815 "Item Blocked Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Blocked]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        SalesBlockedErr: Label 'You cannot sell this item because the Sales Blocked check box is selected on the item card.';
        PurchasingBlockedErr: Label 'You cannot purchase this item because the Purchasing Blocked check box is selected on the item card.';
        AddingBlockedItemMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item No.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        PurchasingBlockedCopyFromItemErr: Label 'You cannot purchase item %1 because the Purchasing Blocked check box is selected on the item card.';

    [Test]
    [Scope('OnPrem')]
    procedure T100_ItemBlockedForSaleOnInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize;
        // [GIVEN] An item that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Create a line on the sales order with the item that is blocked for sale
        asserterror
          LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears: 'You cannot sell this item'
        Assert.ExpectedError(SalesBlockedErr);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T105_ItemBlockedForSaleOnCrMemo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize;
        // [GIVEN] An item that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Create a line on the sales credit memo with the item 'X' that is blocked for sale
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);
        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", Item."No.");
        Item.Find;
        Item.TestField("Sales Blocked");
        // [THEN] Credit Memo can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T106_ItemBlockedForSaleOnRetOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Return Order]
        Initialize;
        // [GIVEN] An item that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");

        // [WHEN] Create a line on the sales return order with the item 'X' that is blocked for sale
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);
        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", Item."No.");
        Item.Find;
        Item.TestField("Sales Blocked");
        // [THEN] Return order can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T110_ItemBlockedForSaleOnOrderDescriptionLookup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesOrderPage: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the sales order, where "Type" is 'Item'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrderPage.OpenEdit;
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrderPage.SalesLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesOrderPage.SalesLines."No.".Lookup;
        // [THEN] The item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesOrderPage.SalesLines.Description.Lookup;
        // [THEN] The item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T115_ItemBlockedForSaleOnRetOrderDescriptionLookup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesReturnOrderPage: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales] [Return Order] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the sales return order, where "Type" is 'Item'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        SalesReturnOrderPage.OpenEdit;
        SalesReturnOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrderPage.SalesLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesReturnOrderPage.SalesLines."No.".Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesReturnOrderPage.SalesLines.Description.Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T116_ItemBlockedForSaleOnCrMemoDescriptionLookup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for sales
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the sales credit memo, where "Type" is 'Item'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesCreditMemoPage.OpenEdit;
        SalesCreditMemoPage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemoPage.SalesLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesCreditMemoPage.SalesLines."No.".Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        SalesCreditMemoPage.SalesLines.Description.Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ItemBlockedForSaleOnJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize;
        // [GIVEN] An item that is blocked for sale
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type sale
        asserterror
          LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Sale, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears
        Assert.ExpectedError(SalesBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T125_ItemBlockedForSaleOnJournalWithNegAdj()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize;
        // [GIVEN] An item that is blocked for sale
        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type negative adjustment
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Line is created
        ItemJournalLine.Find;
        ItemJournalLine.TestField("Item No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T200_ItemBlockedForPurchaseOnInvoice()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Invoice]
        Initialize;
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [WHEN] Create a line in a purchase invoice with the item that is blocked for purchase
        asserterror
          LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears: 'You cannot purchase this item'
        Assert.ExpectedError(StrSubstNo(PurchasingBlockedCopyFromItemErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T205_ItemBlockedForPurchaseOnCrMemo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        Initialize;
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Create a line in a purchase credit memo with the item 'X' that is blocked for purchase
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId);
        // [THEN] Line is created, Item is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", Item."No.");
        Item.Find;
        Item.TestField("Purchasing Blocked");
        // [THEN] Credit Memo can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure T206_ItemBlockedForPurchaseOnRetOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Return Order]
        Initialize;
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // [WHEN] Create a line in a purchase return order with the item 'X' that is blocked for purchase
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Notification: 'You are adding a blocked item X to the document.'
        Assert.ExpectedMessage(StrSubstNo(AddingBlockedItemMsg, Item."No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId);
        // [THEN] Line is created, Item is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", Item."No.");
        Item.Find;
        Item.TestField("Purchasing Blocked");
        // [THEN] Return Order can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T210_ItemBlockedForPurchOnOrderDescriptionLookup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Order] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] New line is created on the purchase order, where "Type" is 'Item'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseOrderPage.OpenEdit;
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrderPage.PurchLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseOrderPage.PurchLines."No.".Lookup;
        // [THEN] The item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseOrderPage.PurchLines.Description.Lookup;
        // [THEN] The item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T215_ItemBlockedForPurchOnRetOrderDescriptionLookup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseReturnOrderPage: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase] [Return Order] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a line on the purchase return order, where "Type" is 'Item'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseReturnOrderPage.OpenEdit;
        PurchaseReturnOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrderPage.PurchLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseReturnOrderPage.PurchLines."No.".Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseReturnOrderPage.PurchLines.Description.Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure T216_ItemBlockedForPurchOnCrMemoDescriptionLookup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UI]
        Initialize;
        // [GIVEN] An item 'X' that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] Create a line on the purchase credit memo, where "Type" is 'Item'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseCreditMemoPage.OpenEdit;
        PurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemoPage.PurchLines.Type.Value('Item');

        // [WHEN] Lookup in "No." control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseCreditMemoPage.PurchLines."No.".Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must not be in the list');

        // [WHEN] Lookup in "Description" control
        LibraryVariableStorage.Enqueue(Item."No."); // to ItemListModalPageHandler
        PurchaseCreditMemoPage.PurchLines.Description.Lookup;
        // [THEN] The item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Item must be in the list (Description)');
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T220_ItemBlockedForPurchaseOnJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize;
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type purchase
        asserterror
          LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] An error appears
        Assert.ExpectedError(PurchasingBlockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T225_ItemBlockedForPurchaseOnJournalWithPosAdj()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize;
        // [GIVEN] An item that is blocked for purchase
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purchasing Blocked", true);
        Item.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type positive adjustment
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Line is created
        ItemJournalLine.Find;
        ItemJournalLine.TestField("Item No.", Item."No.");
    end;

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Item Blocked Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Item Blocked Test");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Item Blocked Test");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemLookup: TestPage "Item Lookup")
    begin
        ItemLookup.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText);
        LibraryVariableStorage.Enqueue(ItemLookup.First);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean;
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}

