codeunit 134835 "Test Item Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Find Item] [Description] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        EditableErr: Label '%1 should be editable';
        NotEditableErr: Label '%1 should NOT be editable';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Scope('OnPrem')]
    procedure TestValidateDescOnSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize;

        // Setup
        CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // Exercise and Verify Existing Item
        SalesLine.Validate(Description, Item.Description);

        SalesLine.TestField("No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptySalesLineConfirmYes()
    var
        Item: array [2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 308574] Validate Description in Sales Line when "No." <> '' confirmed
        Initialize;

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Sales Line with "No." = 'A'
        LibrarySales.CreateSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine,SalesHeader,SalesLine.Type::Item,Item[1]."No.",0);

        SalesLine.TestField("No.",Item[1]."No.");

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        LibraryVariableStorage.Enqueue(true);
        SalesLine.Validate(Description,Item[2].Description);

        // [THEN] Sales Line "No." = 'B'
        SalesLine.TestField("No.",Item[2]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptySalesLineConfirmNo()
    var
        Item: array [2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 308574] Validate Description in Sales Line when "No." <> '' not confirmed
        Initialize;

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Sales Line with "No." = 'A'
        LibrarySales.CreateSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine,SalesHeader,SalesLine.Type::Item,Item[1]."No.",0);

        SalesLine.TestField("No.",Item[1]."No.");

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        LibraryVariableStorage.Enqueue(false);
        SalesLine.Validate(Description,Item[2].Description);

        // [THEN] Sales Line "No." = 'A'
        SalesLine.TestField("No.",Item[1]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler1,ConfigTemplatesModalHandler,ItemCardModalHandler')]
    [Scope('OnPrem')]
    procedure TestAutoCreateItemFromDescriptionOnSalesLine()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RandomItemDescription: Text[50];
    begin
        Initialize;
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Create Item from Description" := true;
        SalesReceivablesSetup.Modify;

        // Setup
        RandomItemDescription := CopyStr(Format(CreateGuid), 1, 50);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // Exercise
        SalesLine.Validate(Description, RandomItemDescription);

        // Verify
        Item.SetRange(Description, RandomItemDescription);
        Assert.AreEqual(1, Item.Count, 'Item not created correctly from Description');

        // Clean up
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Create Item from Description" := false;
        SalesReceivablesSetup.Modify;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResolvingDescriptionWhenRetypingExistingValueSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize;

        // Setup
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate(Description, Item."No.");
        Assert.AreEqual(Item.Description, SalesLine.Description, 'Description not set correctly on first lookup');

        // Exercise
        SalesLine.Validate(Description, Item."No.");

        // Verify
        Assert.AreEqual(Item.Description, SalesLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", SalesLine."No.", 'No. was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        SalesQuote.OpenNew;
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);

        // Excercise
        SalesQuote.SalesLines.New;
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesQuote.SalesLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        SalesQuote.SalesLines.New;
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesQuote.SalesLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesQuote.SalesLines."Unit Price".Editable, StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesQuote.SalesLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesQuote.SalesLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        SalesQuote.SalesLines.New;
        SalesQuote.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType);
        SalesQuote.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesQuote.SalesLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesQuote.SalesLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesQuote.SalesLines."Unit Price".Editable, StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesQuote.SalesLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesQuote.SalesLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        SalesInvoice.OpenNew;
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);

        // Excercise
        SalesInvoice.SalesLines.New;
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesInvoice.SalesLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        SalesInvoice.SalesLines.New;
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesInvoice.SalesLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesInvoice.SalesLines."Unit Price".Editable, StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesInvoice.SalesLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesInvoice.SalesLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        SalesInvoice.SalesLines.New;
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType);
        SalesInvoice.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesInvoice.SalesLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesInvoice.SalesLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesInvoice.SalesLines."Unit Price".Editable, StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesInvoice.SalesLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesInvoice.SalesLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        SalesOrder.OpenNew;
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);

        // Excercise
        SalesOrder.SalesLines.New;
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesOrder.SalesLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        SalesOrder.SalesLines.New;
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesOrder.SalesLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesOrder.SalesLines."Unit Price".Editable, StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesOrder.SalesLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesOrder.SalesLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        SalesOrder.SalesLines.New;
        SalesOrder.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType);
        SalesOrder.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesOrder.SalesLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesOrder.SalesLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesOrder.SalesLines."Unit Price".Editable, StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesOrder.SalesLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesOrder.SalesLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoItemLookupInDescription()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        SalesCreditMemo.OpenNew;
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);

        // Excercise
        SalesCreditMemo.SalesLines.New;
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesCreditMemo.SalesLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        SalesCreditMemo.SalesLines.New;
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(SalesCreditMemo.SalesLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Unit Price".Editable, StrSubstNo(EditableErr, 'Unit Price'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(SalesCreditMemo.SalesLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        SalesCreditMemo.SalesLines.New;
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType);
        SalesCreditMemo.SalesLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(SalesCreditMemo.SalesLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit Price".Editable, StrSubstNo(NotEditableErr, 'Unit Price'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(SalesCreditMemo.SalesLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        SalesQuote.OpenNew;
        SalesQuote."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);
        SalesQuote.SalesLines.Next;
        SalesQuote.SalesLines.New;
        SalesQuote.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        SalesQuote.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesQuote.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesQuote.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        SalesInvoice.OpenNew;
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);
        SalesInvoice.SalesLines.Next;
        SalesInvoice.SalesLines.New;
        SalesInvoice.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        SalesInvoice.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesInvoice.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        SalesOrder.OpenNew;
        SalesOrder."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);
        SalesOrder.SalesLines.Next;
        SalesOrder.SalesLines.New;
        SalesOrder.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        SalesOrder.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesOrder.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoItemLookupOnBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        SalesCreditMemo.OpenNew;
        SalesCreditMemo."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo);
        SalesCreditMemo.SalesLines.Next;
        SalesCreditMemo.SalesLines.New;
        SalesCreditMemo.SalesLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        SalesCreditMemo.SalesLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesCreditMemo.SalesLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, SalesCreditMemo.SalesLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateDescOnPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize;

        // Setup
        CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // Exercise and Verify Existing Item
        PurchaseLine.Validate(Description, Item.Description);

        PurchaseLine.TestField("No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptyPurchaseLineConfirmYes()
    var
        Item: array [2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 308574] Validate Description in Purchase Line when "No." <> '' confirmed
        Initialize;

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Purchase Line with "No." = 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader,PurchaseHeader."Document Type"::Invoice,LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine,PurchaseHeader,PurchaseLine.Type::Item,Item[1]."No.",0);
        PurchaseLine.TestField("No.",Item[1]."No.");

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        LibraryVariableStorage.Enqueue(true);
        PurchaseLine.Validate(Description,Item[2].Description);

        // [THEN] Purchase Line "No." = 'B'
        PurchaseLine.TestField("No.",Item[2]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestValidateDescOnNotEmptyPurchaseLineConfirmNo()
    var
        Item: array [2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 308574] Validate Description in Purchase Line when "No." <> '' not confirmed
        Initialize;

        // [GIVEN] Item 'A' with Description 'ADescr'
        CreateItem(Item[1]);
        // [GIVEN] Item 'B' with Description 'BDescr'
        CreateItem(Item[2]);
        // [GIVEN] Purchase Line with "No." = 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader,PurchaseHeader."Document Type"::Invoice,LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine,PurchaseHeader,PurchaseLine.Type::Item,Item[1]."No.",0);
        PurchaseLine.TestField("No.",Item[1]."No.");

        // [WHEN] Validate description with 'BDescr'; Confirm = True
        LibraryVariableStorage.Enqueue(false);
        PurchaseLine.Validate(Description,Item[2].Description);

        // [THEN] Purchase Line "No." = 'A'
        PurchaseLine.TestField("No.",Item[1]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResolvingDescriptionWhenRetypingExistingValuePurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize;

        // [GIVEN] Item No. = "X", Description = "Test"
        CreateItem(Item);

        // [GIVEN] Purchser Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate(Description, Item."No.");
        Assert.AreEqual(Item.Description, PurchaseLine.Description, 'Description not set correctly on first lookup');

        // [WHEN] Validate Description in Purchase Line with "X"
        PurchaseLine.Validate(Description, Item."No.");

        // [THEN] No. in Purchase Line = "X"
        // [THEN] Description in Purchase Line = "Test"
        Assert.AreEqual(Item.Description, PurchaseLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", PurchaseLine."No.", '"No." not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceItemLookupInDescription()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        PurchaseInvoice.OpenNew;
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo);

        // Excercise
        PurchaseInvoice.PurchLines.New;
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(PurchaseInvoice.PurchLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        PurchaseInvoice.PurchLines.New;
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(PurchaseInvoice.PurchLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Direct Unit Cost".Editable, StrSubstNo(EditableErr, 'Direct Unit Cost'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(PurchaseInvoice.PurchLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        PurchaseInvoice.PurchLines.New;
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType);
        PurchaseInvoice.PurchLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(PurchaseInvoice.PurchLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Direct Unit Cost".Editable, StrSubstNo(NotEditableErr, 'Direct Unit Cost'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(PurchaseInvoice.PurchLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoItemLookupInDescription()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NoneExixtingItemNo: Code[20];
    begin
        Initialize;

        // Setup
        PurchaseCreditMemo.OpenNew;
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo);

        // Excercise
        PurchaseCreditMemo.PurchLines.New;
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Quantity.Editable, 'Quantity should be editable');

        // Excercise
        PurchaseCreditMemo.PurchLines.New;
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Verify
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Quantity.Editable, StrSubstNo(EditableErr, 'Quantity'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable, StrSubstNo(EditableErr, 'Direct Unit Cost'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Line Amount".Editable, StrSubstNo(EditableErr, 'Line Amount'));
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Line Discount %".Editable, StrSubstNo(EditableErr, 'Line Discount %'));

        // Setup nonexisting Item
        NoneExixtingItemNo := CopyStr(Format(CreateGuid), 1, 20);

        // Excercise
        PurchaseCreditMemo.PurchLines.New;
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType);
        PurchaseCreditMemo.PurchLines.Description.SetValue(NoneExixtingItemNo);

        // Verify
        Assert.IsFalse(PurchaseCreditMemo.PurchLines.Quantity.Editable, StrSubstNo(NotEditableErr, 'Quantity'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Unit of Measure Code".Editable, StrSubstNo(NotEditableErr, 'Unit of Measure Code'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Direct Unit Cost".Editable, StrSubstNo(NotEditableErr, 'Direct Unit Cost'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Line Amount".Editable, StrSubstNo(NotEditableErr, 'Line Amount'));
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Line Discount %".Editable, StrSubstNo(NotEditableErr, 'Line Discount %'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceItemLookupOnBlankLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        PurchaseInvoice.OpenNew;
        PurchaseInvoice."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo);
        PurchaseInvoice.PurchLines.Next;
        PurchaseInvoice.PurchLines.New;
        PurchaseInvoice.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        PurchaseInvoice.PurchLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseInvoice.PurchLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, PurchaseInvoice.PurchLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoItemLookupOnBlankLines()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ItemNo: Code[20];
    begin
        // I SaaS we rely on Type to be set to "Item" this did not happen when running the MultipleNewLines pattern
        // Bug 166321:[Ipad tablet] Entering invalid id for an item in an invoice gives weird error message

        Initialize;

        // Setup
        PurchaseCreditMemo.OpenNew;
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo);
        PurchaseCreditMemo.PurchLines.Next;
        PurchaseCreditMemo.PurchLines.New;
        PurchaseCreditMemo.PurchLines.Description.SetValue(LibraryInventory.CreateItemNo);

        // Excercise
        PurchaseCreditMemo.PurchLines.Previous();
        ItemNo := LibraryInventory.CreateItemNo;
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseCreditMemo.PurchLines.Description.SetValue(ItemNo);

        // Verify
        Assert.AreEqual(ItemNo, PurchaseCreditMemo.PurchLines."No.".Value, 'Item shoud be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferLineItemNoLookupInDescription()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
    begin
        Initialize;

        // Setup
        CreateItem(Item);
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferLine.Init;
        TransferLine.Validate("Document No.", TransferHeader."No.");

        // Exercise
        TransferLine.Validate(Description, Item."No.");

        // Verify
        Assert.AreEqual(Item.Description, TransferLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", TransferLine."Item No.", 'No. not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferLineItemNoLookupInDescriptionItemNotFound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TestGuid: Text[50];
    begin
        Initialize;

        // Setup
        TestGuid := CreateGuid;
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferLine.Init;
        TransferLine.Validate("Document No.", TransferHeader."No.");

        // Exercise
        TransferLine.Validate(Description, TestGuid);

        // Verify
        Assert.AreEqual(TestGuid, TransferLine.Description, 'Description not set correctly');
        Assert.AreEqual('', TransferLine."Item No.", 'No. not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineDescriptionWithItemNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 232112] Validate Description in Purchase Line with Item "No."
        Initialize;

        // [GIVEN] Item "A"
        CreateItem(Item);

        // [GIVEN] Purchase Invoice with item "A"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0);

        // [GIVEN] Item "B" with Description = 'B123'
        CreateItem(Item);

        // [WHEN] Validate Description in Purchase Line with Item "No." = "B"
        PurchaseLine.Validate(Description, Item."No.");

        // [THEN] Description in Purchase Line = 'B123'
        // [THEN] "No." in Purchase Line = "B"
        Assert.AreEqual(Item.Description, PurchaseLine.Description, 'Description not set correctly');
        Assert.AreEqual(Item."No.", PurchaseLine."No.", '"No." not set correctly');
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Item Lookup");
        Item.DeleteAll;
        LibraryApplicationArea.EnableFoundationSetup;
        LibrarySales.DisableWarningOnCloseUnpostedDoc;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Item Lookup");
        LibraryERMCountryData.CreateVATData;

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Item Lookup");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        Item.Modify(true);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler1(OptionString: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesModalHandler(var ConfigTemplates: TestPage "Config Templates")
    begin
        ConfigTemplates.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCardModalHandler(var ItemCard: TestPage "Item Card")
    var
        Item: Record Item;
    begin
        ItemCard.Type.SetValue(Item.Type::Service);
        ItemCard.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024];var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;
}

