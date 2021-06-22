codeunit 134063 "ERM Intrastat Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        IntrastatJnlErr: Label 'Intrastat journal contains invalid values.';
        IntrastatJnlNotEmptyErr: Label 'Intrastat journal not empty.';
        IntrastatJnlEmptyErr: Label 'Intrastat journal empty.';

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistWithItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Checklist report with Item Journal Line posting data.

        // Setup: Create and post two Item Journal Lines.
        Initialize;
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateItem, ItemJournalLine."Entry Type"::Purchase, GetTransactionType, GetTransportMethod, GetCountryRegionCode);
        Quantity := ItemJournalLine.Quantity;
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::Sale, GetTransactionType, GetTransportMethod, '');

        // Exercise: Generate Intrastat Checklist.
        RunIntrastatChecklist(
          IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, ItemJournalLine."Item No.", ItemJournalLine."Transaction Type");

        // Verify: Verify values on Intrastat Checklist.
        VerifyValuesOnIntrastatChecklist(GetTariffNo(ItemJournalLine."Item No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistWithPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Checklist report with Purchase Order posting data.

        // Setup: Create and post two Purchase Orders.
        Initialize;
        PostTwoPurchaseDocuments(PurchaseLine, PurchaseLine."Document Type"::Order, Quantity);

        // Exercise: Generate Intrastat Checklist.
        RunIntrastatChecklist(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchaseLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Checklist.
        VerifyValuesOnIntrastatChecklist(GetTariffNo(PurchaseLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistWithPurchaseCreditMemo()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Checklist report with Purchase Credit Memo posting data.

        // Setup: Create and post two Purchase Credit Memos.
        Initialize;
        PostTwoPurchaseDocuments(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Quantity);

        // Exercise: Generate Intrastat Checklist.
        RunIntrastatChecklist(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, PurchaseLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Checklist.
        VerifyValuesOnIntrastatChecklist(GetTariffNo(PurchaseLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistPurchaseDocumentsMultipleBatches()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Run 'Intrastat - Checklist' for purchase documents having mutiple intrastat journal batches.

        // [GIVEN] Two posted Purchase Orders
        Initialize;
        PostTwoPurchaseDocuments(PurchaseLine, PurchaseLine."Document Type"::Order, Quantity);
        // [GIVEN] Two Intrastat Journal Batches: B1, B2
        CreateIntrastatLineMultipleBatches(IntrastatJnlLine, WorkDate);

        // [WHEN] Run 'Intrastat - Checklist' on on the Batch B2.
        RunGetItemEntriesAndIntrastatChecklist(
          IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchaseLine."No.", GetTransactionType);

        // [THEN] Company info is printed on the report header.
        VerifyCompanyNameIsOnIntrastatChecklist;
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistWithSalesOrder()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Checklist report with Sales Order posting data.

        // Setup: Create and post two Sales Orders.
        Initialize;
        PostTwoSalesDocuments(SalesLine, SalesLine."Document Type"::Order, Quantity);

        // Exercise: Generate Intrastat Checklist.
        RunIntrastatChecklist(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Checklist.
        VerifyValuesOnIntrastatChecklist(GetTariffNo(SalesLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistWithSalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Checklist report with Sales Credit Memo posting data.

        // Setup: Create and post two Sales Credit Memos.
        Initialize;
        PostTwoSalesDocuments(SalesLine, SalesLine."Document Type"::"Credit Memo", Quantity);

        // Exercise: Generate Intrastat Checklist.
        RunIntrastatChecklist(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, SalesLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Checklist.
        VerifyValuesOnIntrastatChecklist(GetTariffNo(SalesLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatChecklist')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistSalesDocumentMultipleBatches()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Run 'Intrastat - Checklist' for sales documents having mutiple intrastat journal batches.

        // [GIVEN] Two posted Sales Orders
        Initialize;
        PostTwoSalesDocuments(SalesLine, SalesLine."Document Type"::Order, Quantity);
        // [GIVEN] Two Intrastat Journal Batches: B1, B2
        CreateIntrastatLineMultipleBatches(IntrastatJnlLine, WorkDate);

        // [WHEN] Run 'Intrastat - Checklist' on on the Batch B2.
        RunGetItemEntriesAndIntrastatChecklist(
          IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesLine."No.", GetTransactionType);

        // [THEN] Company info is printed on the report header.
        VerifyCompanyNameIsOnIntrastatChecklist;
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormWithItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Form report with Item Journal Line posting data.

        // Setup: Create and post two Item Journal Lines.
        Initialize;
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateItem, ItemJournalLine."Entry Type"::Purchase, GetTransactionType, GetTransportMethod, GetCountryRegionCode);
        Quantity := ItemJournalLine.Quantity;
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::Sale, GetTransactionType, GetTransportMethod, '');

        // Exercise: Generate Intrastat Form.
        RunIntrastatForm(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, ItemJournalLine."Item No.", ItemJournalLine."Transaction Type");

        // Verify: Verify values on Intrastat Form.
        VerifyValuesOnIntrastatForm(GetTariffNo(ItemJournalLine."Item No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormWithPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Form report with Purchase Order posting data.

        // Setup: Create and post two Purchase Orders.
        Initialize;
        PostTwoPurchaseDocuments(PurchaseLine, PurchaseLine."Document Type"::Order, Quantity);

        // Exercise: Generate Intrastat Form.
        RunIntrastatForm(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchaseLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Form.
        VerifyValuesOnIntrastatForm(GetTariffNo(PurchaseLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormWithPurchaseCreditMemo()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Form report with Purchase Credit Memo posting data.

        // Setup: Create and post two Purchase Credit Memos.
        Initialize;
        PostTwoPurchaseDocuments(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Quantity);

        // Exercise: Generate Intrastat Form.
        RunIntrastatForm(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, PurchaseLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Form.
        VerifyValuesOnIntrastatForm(GetTariffNo(PurchaseLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormWithSalesOrder()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Form report with Sales Order posting data.

        // Setup: Create and post two Sales Orders.
        Initialize;
        PostTwoSalesDocuments(SalesLine, SalesLine."Document Type"::Order, Quantity);

        // Exercise: Generate Intrastat Form.
        RunIntrastatForm(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Form.
        VerifyValuesOnIntrastatForm(GetTariffNo(SalesLine."No."), Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [Scope('OnPrem')]
    procedure IntrastatFormWithSalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Quantity: Decimal;
    begin
        // Test Intrastat Form report with Sales Credit Memo posting data.

        // Setup: Create and post two Sales Credit Memos.
        Initialize;
        PostTwoSalesDocuments(SalesLine, SalesLine."Document Type"::"Credit Memo", Quantity);

        // Exercise: Generate Intrastat Form.
        RunIntrastatForm(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, SalesLine."No.", GetTransactionType);

        // Verify: Verify values on Intrastat Form.
        VerifyValuesOnIntrastatForm(GetTariffNo(SalesLine."No."), Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntrastatDefaultWithZeroAmount()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Amount: Decimal;
        Quantity: Integer;
    begin
        // Test default Intrastat report when Sales has zero amount.

        // Setup.
        Initialize;
        Item.Get(CreateItemWithNonZeroUnitPrice);

        CreateAndPostSalesDocumentWithUnitPrice(
          SalesLine, SalesLine."Document Type"::Order, Item."No.",
          GetTransactionType, GetTransportMethod, 0);
        Quantity := SalesLine.Quantity;
        Amount := Abs(Quantity * Item."Unit Price");

        // Exercise.
        CreateIntrastatLine(IntrastatJnlLine, Today);
        RunGetItemEntries(
          IntrastatJnlLine, WorkDate,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate), false);

        // Verify.
        VerifyValuesOnIntrastatJournal(IntrastatJnlLine, SalesLine."No.", Quantity, Amount);
    end;

    [Test]
    [HandlerFunctions('ReqPageHandlGetItemLedgEntries')]
    [Scope('OnPrem')]
    procedure IntrastatDontRecalcZerosWithZeroAmount()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        // Test Intrastat report with true 'Don't recalculate zero amounts' setting when Sales has zero amount.

        // Setup.
        Initialize;
        CreateAndPostSalesDocumentWithUnitPrice(
          SalesLine, SalesLine."Document Type"::Order, CreateItemWithNonZeroUnitPrice,
          GetTransactionType, GetTransportMethod, 0);
        Quantity := SalesLine.Quantity;

        // Exercise.
        CreateIntrastatLine(IntrastatJnlLine, Today);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(CalcDate('<6M>', WorkDate));
        RunGetItemEntries(
          IntrastatJnlLine, WorkDate,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate), true);

        // Verify.
        VerifyValuesOnIntrastatJournal(IntrastatJnlLine, SalesLine."No.", Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ReqPageHandlGetItemLedgEntries')]
    [Scope('OnPrem')]
    procedure IntrastatDontRecalcAndShowZerosWithZeroAmount()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Test Intrastat report with true 'Don't recalculate zero amounts' and true 'Don't show zero amounts' setting when Sales has zero amount.

        // Setup.
        Initialize;
        CreateAndPostSalesDocumentWithUnitPrice(
          SalesLine, SalesLine."Document Type"::Order, CreateItemWithNonZeroUnitPrice,
          GetTransactionType, GetTransportMethod, 0);

        // Exercise.
        CreateIntrastatLine(IntrastatJnlLine, Today);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(CalcDate('<6M>', WorkDate));
        RunGetItemEntries(
          IntrastatJnlLine, WorkDate,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate), true);

        // Verify.
        VerifyEmptyIntrastatJournal(IntrastatJnlLine, SalesLine."No.");
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Intrastat Reports");
        LibraryVariableStorage.Clear;
        IntrastatSetup.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Intrastat Reports");
        UpdateIntrastatCountryCode; // Required for Intrastat.
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.CreateTransportMethodTableData;
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Intrastat Reports");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Option; TransactionType: Code[10]; TransportMethod: Code[10]; CountryRegionCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDec(100, 2) * 100);
        ItemJournalLine.Validate("Transaction Type", TransactionType);
        ItemJournalLine.Validate("Transport Method", TransportMethod);
        ItemJournalLine.Validate("Country/Region Code", CountryRegionCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; ItemNo: Code[20]; TransactionType: Code[10]; TransportMethod: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Document With Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Transaction Type", TransactionType);
        PurchaseHeader.Validate("Transport Method", TransportMethod);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2) * 100);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; ItemNo: Code[20]; TransactionType: Code[10]; TransportMethod: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Document with Random Quantity and Unit Price.
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, ItemNo, TransactionType, TransportMethod);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesDocumentWithUnitPrice(var SalesLine: Record "Sales Line"; DocumentType: Option; ItemNo: Code[20]; TransactionType: Code[10]; TransportMethod: Code[10]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Document with Random Quantity and Unit Price.
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, ItemNo, TransactionType, TransportMethod);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; ItemNo: Code[20]; TransactionType: Code[10]; TransportMethod: Code[10])
    begin
        // Create Sales Document with Random Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer);
        SalesHeader.Validate("Transaction Type", TransactionType);
        SalesHeader.Validate("Transport Method", TransportMethod);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2) * 100);
    end;

    local procedure CreateAndUpdateIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; JournalTemplateName: Code[10]; JournalDate: Date)
    begin
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, JournalTemplateName);
        IntrastatJnlBatch.Validate("Statistics Period", Format(JournalDate, 0, '<Year><Month,2>'));  // Take Value in YYMM format.
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryRegionCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryRegionCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateIntrastatLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateAndUpdateIntrastatBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name, JournalDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
    end;

    local procedure CreateIntrastatLineMultipleBatches(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        // Create Batch 1
        CreateAndUpdateIntrastatBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name, JournalDate);
        // Create Batch 2
        CreateAndUpdateIntrastatBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name, JournalDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Net Weight", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithNonZeroUnitPrice(): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Net Weight", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(1, 100)); // Creating integer because value is not important
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>%1', '');
        CountryRegion.FindFirst;
        exit(CountryRegion.Code);
    end;

    local procedure GetTransactionType(): Code[10]
    var
        TransactionType: Record "Transaction Type";
    begin
        TransactionType.FindFirst;
        exit(TransactionType.Code);
    end;

    local procedure GetTransportMethod(): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.FindFirst;
        exit(TransportMethod.Code);
    end;

    local procedure GetTariffNo(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Tariff No.");
    end;

    local procedure PostTwoSalesDocuments(var SalesLine: Record "Sales Line"; DocumentType: Option; var Quantity: Decimal)
    begin
        CreateAndPostSalesDocument(SalesLine, DocumentType, CreateItem, GetTransactionType, GetTransportMethod);
        Quantity := SalesLine.Quantity;
        CreateAndPostSalesDocument(SalesLine, DocumentType, SalesLine."No.", '', '');
    end;

    local procedure PostTwoPurchaseDocuments(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; var Quantity: Decimal)
    begin
        CreateAndPostPurchaseDocument(PurchaseLine, DocumentType, CreateItem, GetTransactionType, GetTransportMethod);
        Quantity := PurchaseLine.Quantity;
        CreateAndPostPurchaseDocument(PurchaseLine, DocumentType, PurchaseLine."No.", '', '');
    end;

    local procedure RunIntrastatChecklist(IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; ItemNo: Code[20]; TransactionType: Code[10])
    begin
        CreateIntrastatLine(IntrastatJnlLine, WorkDate);
        RunGetItemEntriesAndIntrastatChecklist(IntrastatJnlLine, Type, ItemNo, TransactionType);
    end;

    local procedure RunGetItemEntriesAndIntrastatChecklist(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; ItemNo: Code[20]; TransactionType: Code[10])
    var
        IntrastatChecklist: Report "Intrastat - Checklist";
    begin
        RunGetItemEntries(IntrastatJnlLine, WorkDate, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate), false);

        Commit();
        Clear(IntrastatChecklist);
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        IntrastatJnlLine.SetRange("Transaction Type", TransactionType);
        IntrastatJnlLine.SetRange(Type, Type);
        IntrastatChecklist.SetTableView(IntrastatJnlLine);
        IntrastatChecklist.Run;
    end;

    local procedure RunIntrastatForm(IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; ItemNo: Code[20]; TransactionType: Code[10])
    var
        IntrastatForm: Report "Intrastat - Form";
    begin
        CreateIntrastatLine(IntrastatJnlLine, Today);
        RunGetItemEntries(IntrastatJnlLine, WorkDate, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate), false);
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        IntrastatJnlLine.SetRange("Transaction Type", TransactionType);
        IntrastatJnlLine.SetRange(Type, Type);

        Commit();
        Clear(IntrastatForm);
        IntrastatForm.SetTableView(IntrastatJnlLine);
        IntrastatForm.Run;
    end;

    local procedure RunGetItemEntries(IntrastatJnlLine: Record "Intrastat Jnl. Line"; StartDate: Date; EndDate: Date; UseReqPage: Boolean)
    var
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        GetItemLedgerEntries.InitializeRequest(StartDate, EndDate, 0);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        if UseReqPage then
            Commit
        else
            GetItemLedgerEntries.UseRequestPage(false);
        GetItemLedgerEntries.Run;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        ItemJournalBatch.Modify(true);
    end;

    local procedure VerifyValuesOnIntrastatChecklist(TariffNo: Code[10]; Quantity: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineQty', Quantity);
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineTariffNo', TariffNo);
    end;

    local procedure VerifyCompanyNameIsOnIntrastatChecklist()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationName: Variant;
    begin
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetLastRow;
        CompanyInformationName := CompanyInformation.Name;
        LibraryReportDataset.FindCurrentRowValue('CompanyName', CompanyInformationName);
    end;

    local procedure VerifyValuesOnIntrastatJournal(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemNo: Code[20]; Quantity: Decimal; Amount: Decimal)
    begin
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        if IntrastatJnlLine.FindFirst then begin
            Assert.AreEqual(Quantity, IntrastatJnlLine.Quantity, IntrastatJnlErr);
            Assert.AreEqual(Amount, IntrastatJnlLine.Amount, IntrastatJnlErr)
        end else
            Assert.Fail(IntrastatJnlEmptyErr);
    end;

    local procedure VerifyEmptyIntrastatJournal(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(IntrastatJnlLine.IsEmpty, IntrastatJnlNotEmptyErr);
    end;

    local procedure VerifyValuesOnIntrastatForm(TariffNo: Code[10]; Quantity: Decimal)
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.Get(TariffNo);

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Quantity_IntraJnlLine', Quantity);
        LibraryReportDataset.AssertElementWithValueExists('TariffNo_IntraJnlLine', TariffNo);
        LibraryReportDataset.AssertElementWithValueExists('ItemDesc_IntraJnlLine', TariffNumber.Description);
    end;

    local procedure UpdateIntrastatCountryCode()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        if CountryRegion."Intrastat Code" = '' then begin
            CountryRegion."Intrastat Code" := CountryRegion.Code;
            CountryRegion.Modify(true);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerIntrastatChecklist(var IntrastatChecklist: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklist.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerIntrastatForm(var IntrastatForm: TestRequestPage "Intrastat - Form")
    begin
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReqPageHandlGetItemLedgEntries(var GetItemLedgEntries: TestRequestPage "Get Item Ledger Entries")
    var
        SkipRecalcForZeros: Variant;
        SkipZeros: Variant;
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(SkipRecalcForZeros);
        LibraryVariableStorage.Dequeue(SkipZeros);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GetItemLedgEntries.SkipRecalcForZeros.SetValue(SkipRecalcForZeros);
        GetItemLedgEntries.SkipZeros.SetValue(SkipZeros);
        GetItemLedgEntries.StartingDate.SetValue(StartDate);
        GetItemLedgEntries.EndingDate.SetValue(EndDate);
        GetItemLedgEntries.OK.Invoke;
    end;
}

