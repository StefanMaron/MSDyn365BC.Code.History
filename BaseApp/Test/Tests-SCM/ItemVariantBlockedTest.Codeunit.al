codeunit 134817 "Item Variant Blocked Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Variant] [Blocked]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        SalesBlockedErr: Label 'You cannot sell this %1 because the %2 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Field Caption';
        JournalPurchasingBlockedErr: Label 'You cannot purchase this %1 because the %2 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Field Caption';
        ItemVariantPurchasingBlockedErr: Label 'You cannot purchase Item Variant %1, Item %2 because the %3 check box is selected on the Item Variant card.', Comment = '%1 - Variant Code, %2 = Item No., %3 - Blocked Field Caption';
        BlockedItemVariantNotificationMsg: Label 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item Variant Code, %2 - Item No.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;

    [Test]
    procedure ItemVariantBlockedForSaleOnInvoice()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Create a line on the sales invoice with the item that is blocked for sale
        asserterror CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] An error appears: 'You cannot sell this item'
        Assert.ExpectedError(StrSubstNo(SalesBlockedErr, ItemVariant.TableCaption(), ItemVariant.FieldCaption("Sales Blocked")));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForSaleOnCrMemo()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Create a line on the sales credit memo with the item 'X' that is blocked for sale
        CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);

        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemVariant."Item No.");
        SalesLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Sales Blocked");

        // [THEN] Credit Memo can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForSaleOnRetOrder()
    var
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Return Order]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Sales Return Order
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");

        // [WHEN] Create a line on the sales return order with the item 'X' that is blocked for sale
        CreateItemSalesLineWithItemVariant(SalesLine, SalesHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesLine.RecordId);

        // [THEN] Line is created, Item is blocked for sale
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemVariant."Item No.");
        SalesLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Sales Blocked");

        // [THEN] Return Order can be posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    procedure ItemVariantBlockedForSaleOnJournal()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type sale
        asserterror CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Sale, ItemVariant);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(SalesBlockedErr, ItemVariant.TableCaption(), ItemVariant.FieldCaption("Sales Blocked")));
    end;

    [Test]
    procedure ItemVariantBlockedForSaleOnJournalWithNegAdj()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Sales] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for sales
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Sales Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type negative adjustment
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::"Negative Adjmt.", ItemVariant);

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", ItemVariant."Item No.");
        ItemJournalLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure ItemVariantBlockedForPurchaseOnInvoice()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Invoice]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Invoice
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [WHEN] Create a line on the purchase invoice with the item variant that is blocked for sale
        asserterror CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] An error appears: 'You cannot purchase this item variant'
        Assert.ExpectedError(StrSubstNo(ItemVariantPurchasingBlockedErr, ItemVariant.Code, ItemVariant."Item No.", ItemVariant.FieldCaption("Purchasing Blocked")));
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForPurchaseOnCrMemo()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Credit Memo
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Create a line in a purchase credit memo with the item with item variant 'X' that is blocked for purchase
        CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId());

        // [THEN] Line is created, Item Variant is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", ItemVariant."Item No.");
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Purchasing Blocked");

        // [THEN] Credit Memo can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    procedure ItemVariantBlockedForPurchaseOnRetOrder()
    var
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Return Order]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] Purchase Return Order
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");

        // [WHEN] Create a line in a purchase return order with the item with item variant 'X' that is blocked for purchase
        CreateItemPurchaseLineWithItemVariant(PurchaseLine, PurchaseHeader, ItemVariant);

        // [THEN] Notification: 'You are adding a blocked item variant X to the document.'
        Assert.ExpectedMessage(StrSubstNo(BlockedItemVariantNotificationMsg, ItemVariant.Code, ItemVariant."Item No."), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseLine.RecordId());

        // [THEN] Line is created, Item Variant is blocked for purchasing
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("No.", ItemVariant."Item No.");
        PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        ItemVariant.Find();
        ItemVariant.TestField("Purchasing Blocked");

        // [THEN] Return Order can be posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantBlockedForPurchaseOnJournal()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();

        // [GIVEN] An item that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Trying to create a new journal line of entry type purchase
        asserterror CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::Purchase, ItemVariant);

        // [THEN] An error appears
        Assert.ExpectedError(StrSubstNo(JournalPurchasingBlockedErr, ItemVariant.TableCaption(), ItemVariant.FieldCaption("Purchasing Blocked")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantBlockedForPurchaseOnJournalWithPosAdj()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Purchase] [Journal]
        Initialize();

        // [GIVEN] An item variant that is blocked for purchase
        CreateItemVariant(ItemVariant);
        ItemVariant.Validate("Purchasing Blocked", true);
        ItemVariant.Modify(true);

        // [GIVEN] A journal template and a journal batch
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Create a new journal line of entry type positive adjustment
        CreateItemJournalLineWithItemVariant(ItemJournalLine, ItemJournalBatch, Enum::"Item Ledger Entry Type"::"Positive Adjmt.", ItemVariant);

        // [THEN] Line is created
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Item No.", ItemVariant."Item No.");
        ItemJournalLine.TestField("Variant Code", ItemVariant.Code);
    end;

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Blocked Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Item Blocked Test");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Item Blocked Test");
    end;

    local procedure CreateItemVariant(var ItemVariant: Record "Item Variant")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    procedure CreateItemSalesLineWithItemVariant(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemVariant: Record "Item Variant")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemVariant."Item No.", 0);
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        SalesLine.Modify();
    end;

    procedure CreateItemPurchaseLineWithItemVariant(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemVariant: Record "Item Variant")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemVariant."Item No.", 0);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
    end;

    procedure CreateItemJournalLineWithItemVariant(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemLedgerEntryType, ItemVariant."Item No.", 0);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean;
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}

