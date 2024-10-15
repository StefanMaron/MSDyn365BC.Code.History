codeunit 137410 "Extended Text Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Extended Text]
        IsInitialzied := false;
    end;

    var
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotFoundErr: Label 'Could not find an order line with the Extended Text.';
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ExtendedTxt: Label 'Test Extended Text';
        IsInitialzied: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Extended Text Documents");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();
        if IsInitialzied then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Extended Text Documents");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialzied := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Extended Text Documents");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderWithExtText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        CreateItemwithStock(Item, ExtendedTxt, Quantity);
        LibraryPatterns.MAKESalesQuote(SalesHeader, SalesLine, Item, '', '',
          Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        SalesOrder.Trap();

        // Exercise: Create Sales Order form Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);

        SalesOrder.Close();

        // Verify
        VerifySalesOrder(SalesLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderWithExtText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        CreateItemwithStock(Item, ExtendedTxt, Quantity);
        LibraryPatterns.MAKESalesBlanketOrder(SalesHeader, SalesLine, Item, '', '',
          Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
            TransferExtendedText.InsertSalesExtText(SalesLine);

        // Exercise: Create Sales Order form Sales Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", SalesHeader);

        // Verify
        VerifySalesOrder(SalesLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesBlanketOrderWithExtText()
    var
        ShippedItem: Record Item;
        NotShippedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtText: Text;
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 379977] Extended Text for Blanket Sales Order Line with "Qty. to Ship" = 0 should not be transferred to Sales Order Line.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Items "I1" and "I2" with Extended Texts "ET1" and "ET2" respectively.
        ExtText := LibraryUtility.GenerateRandomText(30);
        LibraryPatterns.MAKEItemWithExtendedText(NotShippedItem, ExtText, "Costing Method"::FIFO, 0);
        LibraryPatterns.MAKEItemWithExtendedText(ShippedItem, LibraryUtility.GenerateRandomText(30), "Costing Method"::FIFO, 0);

        // [GIVEN] Blanket Sales Order for Items "I1" and "I2", in which "Qty. to Ship" for "I1" = 0.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        CreateSalesLineWithExtText(SalesHeader, NotShippedItem."No.", LibraryRandom.RandInt(10), 0);
        CreateSalesLineWithExtText(
          SalesHeader, ShippedItem."No.", LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5));

        // [WHEN] Make a Sales Order from the Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", SalesHeader);

        // [THEN] Extended Text "ET1" is not present in the Sales Order.
        with SalesLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Description, ExtText);
            Assert.RecordIsEmpty(SalesLine);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteToOrderWithExtText()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryPatterns.MAKEItemWithExtendedText(Item, ExtendedTxt, Item."Costing Method"::FIFO, 0);
        LibraryPatterns.MAKEPurchaseQuote(PurchaseHeader, PurchaseLine,
          Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false) then
            TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // Exercise: Create Sales Order form Purchase Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order (Yes/No)", PurchaseHeader);

        // Verify
        VerifyPurchOrder(PurchaseLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchBlanketOrderWithExtText()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryPatterns.MAKEItemWithExtendedText(Item, ExtendedTxt, Item."Costing Method"::FIFO, 0);
        LibraryPatterns.MAKEPurchaseBlanketOrder(PurchaseHeader, PurchaseLine,
          Item, '', '', Quantity, WorkDate(), LibraryRandom.RandIntInRange(1, 10));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false) then
            TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // Exercise: Create Sales Order form Purchase Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Purch Ord. to Ord. (Y/N)", PurchaseHeader);

        // Verify
        VerifyPurchOrder(PurchaseLine."No.", ExtendedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderFromPurchBlanketOrderWithExtText()
    var
        ShippedItem: Record Item;
        NotShippedItem: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExtText: Text;
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 379977] Extended Text for Blanket Purchase Order Line with "Qty. to Receive" = 0 should not be transferred to Purchase Order Line.
        Initialize();

        // [GIVEN] Items "I1" and "I2" with Extended Texts "ET1" and "ET2" respectively.
        ExtText := LibraryUtility.GenerateRandomText(30);
        LibraryPatterns.MAKEItemWithExtendedText(NotShippedItem, ExtText, "Costing Method"::FIFO, 0);
        LibraryPatterns.MAKEItemWithExtendedText(ShippedItem, LibraryUtility.GenerateRandomText(30), "Costing Method"::FIFO, 0);

        // [GIVEN] Blanket Purchase Order for Items "I1" and "I2", in which "Qty. to Receive" for "I1" = 0.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithExtText(PurchHeader, NotShippedItem."No.", LibraryRandom.RandInt(10), 0);
        CreatePurchLineWithExtText(
          PurchHeader, ShippedItem."No.", LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(5));

        // [WHEN] Make a Purchase Order from the Blanket Order.
        CODEUNIT.Run(CODEUNIT::"Blnkt Purch Ord. to Ord. (Y/N)", PurchHeader);

        // [THEN] Extended Text "ET1" is not present in the Purchase Order.
        with PurchLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Description, ExtText);
            Assert.RecordIsEmpty(PurchLine);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertFinanceChargeMemoExtTextAndRollbackThroughError()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        ExtendedTextHeader: Record "Extended Text Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 274510] Inserting finance charge memo extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN] Finance Charge Memo "F" with void type line with extended text "No."
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, LibrarySales.CreateCustomerNo());
        LibraryERM.CreateFinanceChargeMemoLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::" ");
        FinanceChargeMemoLine.Validate("No.", ExtendedTextHeader."No.");
        FinanceChargeMemoLine.Modify(true);

        ExtendedTextHeader.Validate("Finance Charge Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.FinChrgMemoCheckIfAnyExtText(FinanceChargeMemoLine, true);

        // [WHEN] Insert extended text in "F" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertFinChrgMemoExtText(FinanceChargeMemoLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertPurchaseExtTextAndRollbackThroughError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExtendedTextHeader: Record "Extended Text Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 274510] Inserting purchase extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Purchase credit memo "P" with void type line with extended text "No."
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", ExtendedTextHeader."No.", 0);

        ExtendedTextHeader.Validate("Purchase Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, true);

        // [WHEN] Insert extended text in "P" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertReminderExtTextAndRollbackThroughError()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ExtendedTextHeader: Record "Extended Text Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 274510] Inserting reminder extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Reminder "M" with void type line with extended text "No."
        LibraryERM.CreateReminderHeader(ReminderHeader);
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::" ");
        ReminderLine.Validate("No.", ExtendedTextHeader."No.");
        ReminderLine.Modify(true);

        ExtendedTextHeader.Validate(Reminder, true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.ReminderCheckIfAnyExtText(ReminderLine, true);

        // [WHEN] Insert extended text in "M" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertReminderExtText(ReminderLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertSalesExtTextAndRollbackThroughError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtendedTextHeader: Record "Extended Text Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 274510] Inserting sales extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Sales credit memo "S" with void type line with extended text "No."
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", ExtendedTextHeader."No.", 0);

        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);

        // [WHEN] Insert extended text in "S" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertSalesExtText(SalesLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertServiceExtTextAndRollbackThroughError()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ExtendedTextHeader: Record "Extended Text Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        InsertedCode: Code[10];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 274510] Inserting service extended text by codeunit "Transfer Extended Text" does not commit transaction

        // [GIVEN] Extended Text from Standard Text
        CreateExtendedText(ExtendedTextHeader);

        // [GIVEN]  Service credit memo "S" with void type line with extended text "No."
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::" ", ExtendedTextHeader."No.");

        ExtendedTextHeader.Validate("Service Credit Memo", true);
        ExtendedTextHeader.Modify(true);

        // [GIVEN] Table "Area" is updated - a record "R" is inserted
        InsertedCode := CommitAndStartNewTransaction();

        TransferExtendedText.ServCheckIfAnyExtText(ServiceLine, true);

        // [WHEN] Insert extended text in "S" through codeunit "Transfer Extended Text" and  rollback transaction with ERROR function
        TransferExtendedText.InsertServExtText(ServiceLine);

        // [THEN] Table "Area" does not contain "R"
        RollbackTransactionThroughErrorAndVerify(InsertedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithResourceLineAndExtendedText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExtTextPurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Insert extended text for purchase line with resource
        Initialize();

        // [GIVEN] Resource with extended text
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Automatic Ext. Texts", true);
        Resource.Modify(true);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, ExtendedTextHeader."Table Name"::Resource, Resource."No.");
        ExtendedTextHeader.Validate("Purchase Order", true);
        ExtendedTextHeader.Modify(true);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);

        // [GIVEN] Purchase order with resource line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));

        // [WHEN] Insert extended text
        TransferExtendedText.PurchCheckIfAnyExtText(PurchaseLine, false);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);

        // [THEN] Purchase line with Extended text is inserted
        ExtTextPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        ExtTextPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(ExtTextPurchaseLine, 2);
        ExtTextPurchaseLine.SetRange(Description, ExtendedTextLine.Text);
        Assert.RecordIsNotEmpty(ExtTextPurchaseLine);
    end;

    local procedure CreateExtendedText(var ExtendedTextHeader: Record "Extended Text Header")
    var
        StandardText: Record "Standard Text";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibrarySales.CreateStandardText(StandardText);
        LibrarySmallBusiness.CreateExtendedTextHeader(
          ExtendedTextHeader, ExtendedTextHeader."Table Name"::"Standard Text", StandardText.Code);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CommitAndStartNewTransaction(): Code[10]
    var
        "Area": Record "Area";
    begin
        Commit();
        Area.Validate(Code, LibraryUtility.GenerateRandomCode(Area.FieldNo(Code), DATABASE::Area));
        Area.Validate(Text, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Area.Text)), 1, MaxStrLen(Area.Text)));
        Area.Insert(true);
        exit(Area.Code);
    end;

    local procedure RollbackTransactionThroughErrorAndVerify(InsertedCode: Code[10])
    var
        "Area": Record "Area";
    begin
        asserterror Error(LibraryUtility.GenerateRandomText(100));
        Area.SetRange(Code, InsertedCode);
        Assert.RecordIsEmpty(Area);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
    end;

    local procedure CreateItemwithStock(var Item: Record Item; ExtendedText: Text[50]; Quantity: Decimal)
    begin
        LibraryPatterns.MAKEItemWithExtendedText(Item, ExtendedText, Item."Costing Method"::FIFO, 0);
        LibraryPatterns.POSTPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), 0);
    end;

    local procedure CreateSalesLineWithExtText(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure CreatePurchLineWithExtText(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
        TransferExtendedText.InsertPurchExtText(PurchaseLine);
    end;

    local procedure VerifySalesOrder(ItemNo: Code[20]; ExtText: Text[50])
    var
        SalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
    begin
        ItemSalesLine.SetRange("Document Type", ItemSalesLine."Document Type"::Order);
        ItemSalesLine.SetRange("No.", ItemNo);
        ItemSalesLine.FindFirst();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", ItemSalesLine."Document No.");
        SalesLine.SetRange(Description, ExtText);
        Assert.IsFalse(SalesLine.IsEmpty, NotFoundErr);
    end;

    local procedure VerifyPurchOrder(ItemNo: Code[20]; ExtText: Text[50])
    var
        PurchLine: Record "Purchase Line";
        ItemPurchLine: Record "Purchase Line";
    begin
        ItemPurchLine.SetRange("Document Type", ItemPurchLine."Document Type"::Order);
        ItemPurchLine.SetRange("No.", ItemNo);
        ItemPurchLine.FindFirst();

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", ItemPurchLine."Document No.");
        PurchLine.SetRange(Description, ExtText);
        Assert.IsFalse(PurchLine.IsEmpty, NotFoundErr);
    end;
}

