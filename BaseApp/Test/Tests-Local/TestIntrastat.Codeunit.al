codeunit 134153 "Test Intrastat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        IsInitialized: Boolean;
        ReportedMustBeNoErr: Label '%1 must be equal to ''No''  in %2';
        FileNotCreatedErr: Label 'Intrastat file was not created';
        AdvChecklistErr: Label 'There are one or more errors. For details, see the journal error FactBox.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnSecondRunShipment()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename: Text;
    begin
        Initialize;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType);
        Commit();
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);
        Assert.IsTrue(FileManagement.ServerFileExists(Filename), FileNotCreatedErr);

        // Verify
        Commit();
        asserterror RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);
        Assert.ExpectedError(
          StrSubstNo(ReportedMustBeNoErr, IntrastatJnlBatch.FieldCaption("Reported Shipment"), IntrastatJnlBatch.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnSecondRunReceipt()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename: Text;
    begin
        Initialize;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType);
        Commit();
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);
        Assert.IsTrue(FileManagement.ServerFileExists(Filename), FileNotCreatedErr);

        // Verify
        Commit();
        asserterror RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);
        Assert.ExpectedError(
          StrSubstNo(ReportedMustBeNoErr, IntrastatJnlBatch.FieldCaption("Reported Receipt"), IntrastatJnlBatch.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnBlankTransactionType()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename: Text;
    begin
        Initialize;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch, FindOrCreateIntrastatTransportMethod, '');
        Commit();
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        asserterror RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);

        // Verify
#if CLEAN19
        VerifyAdvanvedChecklistError(IntrastatJnlLine,IntrastatJnlLine.FieldName("Transaction Type"));
#else
        VerifyTestfieldChecklistError(IntrastatJnlLine.FieldName("Transaction Type"));
#endif
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportSalesOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitPriceAfterSalesOrder()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Unit Price" after Sales Order posting with Quantity = 1
        // [FEATURE] [Sales] [Order]
        Initialize;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLine(IntrastatJnlBatch, Item."No.", 1, Round(Item."Unit Price", 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitPriceAfterSalesReturnOrder()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Unit Price" after Sales Return Order posting with Quantity = 1
        // [FEATURE] [Sales] [Return Order]
        Initialize;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Return Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::"Return Order", CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLine(IntrastatJnlBatch, Item."No.", 1, Round(Item."Unit Price", 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitCostAfterPurchaseOrder()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Last Direct Cost" after Purchase Order posting with Quantity = 1
        // [FEATURE] [Purchase] [Order]
        Initialize;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLine(IntrastatJnlBatch, Item."No.", 1, Round(Item."Last Direct Cost", 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitCostAfterPurchaseReturnOrder()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Last Direct Cost" after Purchase Return Order posting with Quantity = 1
        // [FEATURE] [Purchase] [Return Order]
        Initialize;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Return Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLine(IntrastatJnlBatch, Item."No.", 1, Round(Item."Last Direct Cost", 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntrastatJournalStatisticalValueEditable()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 331036] Statistical Value is editable on Intrastat Journal page
        Initialize;
        RunIntrastatJournal(IntrastatJournal);
        Assert.IsTrue(IntrastatJournal."Statistical Value".Editable, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskStatisticalValue()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename: Text;
    begin
        // [FEATURE] [Report] [Export]
        // [SCENARIO 331036] 'Intrastat - Make Disk Tax Auth' report with Amount = 0 and given Statistical Value
        Initialize;

        // [GIVEN] Intrastat Journal Line has blank Item No., Amount = 0 and Statistical Value = 100, all mandatory fields are filled in.
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.Validate("Source Type", 0);
        IntrastatJnlLine.Validate("Item No.", '');
        IntrastatJnlLine.Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
        IntrastatJnlLine.Validate(Amount, 0);
        IntrastatJnlLine.Validate("Statistical Value", LibraryRandom.RandDecInRange(100, 200, 2));
        IntrastatJnlLine.Validate("Country/Region Code", FindCountryRegionCode);
        IntrastatJnlLine.Modify(true);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType);
        IntrastatJnlLine.Validate("Total Weight", LibraryRandom.RandIntInRange(100, 200));
        IntrastatJnlLine.Modify(true);

        // [WHEN] Run 'Intrastat - Make Disk Tax Auth' report
        Filename := FileManagement.ServerTempFileName('txt');
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);

        // [THEN] The file is created
        Assert.IsTrue(FileManagement.ServerFileExists(Filename), FileNotCreatedErr);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportSalesInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportSalesReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportSalesCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportSalesOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportSalesInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportSalesReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportSalesCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

#if not CLEAN17
    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskSalesOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesOrderAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDisktSalesInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskSalesReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskSalesCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostSalesCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;
#endif

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportPurchaseOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportPurchaseInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportPurchaseReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportPurchaseCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatFormReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportPurchaseOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportPurchaseInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportPurchaseReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportPurchaseCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);

        // Exercise
        REPORT.RunModal(REPORT::"Intrastat - Checklist");

        // Verify
        VerifyIntrastatCheckListReportDataSet(IntrastatJnlLine, TariffNo);
    end;

#if not CLEAN17
    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskPurchaseOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseOrderAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDisktPurchaseInvoice()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseInvoiceAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Receipt);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskPurchaseReturnOrder()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseReturnOrderAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskPurchaseCreditMemo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        Filename: Text;
    begin
        Initialize;

        // Setup
        TariffNo := SetupAndPostPurchaseCreditMemoAndPrepIntraJnlLines(IntrastatJnlLine);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlLine.Type::Shipment);

        // Verify
        VerifyIntrastatMakeDiskFile(Filename, TariffNo, IntrastatJnlLine);
    end;
#endif

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthCheckControlRequestPageHandler')]
    procedure IntrastatMakeDiskTaxAuthIntrastatJournalLineTypeControlVisibility()
    var
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 353162] Visibility of "Intrastat Journal Line Type" control on "Intrastat - Make Disk Tax Auth" request page.
        Initialize();

        // [GIVEN] Enabled Application Area Basic and Suite.
        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        // [WHEN] Run request page of "Intrastat - Make Disk Tax Auth" report.
        IntrastatMakeDiskTaxAuth.UseRequestPage(true);
        IntrastatMakeDiskTaxAuth.Run();

        // [THEN] Control "Intrastat Journal Line Type" is visible on the request page.
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Control "Intrastat Journal Line Type" must be visible.');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryVariableStorage.Clear;
        LibraryReportDataset.Reset();
        IntrastatSetup.DeleteAll();
        IntrastatJnlTemplate.DeleteAll(true);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        SetIntrastatCodeOnCountryRegion;
        SetTariffNoOnItems;
        CreateIntrastatFileSetup;

        IsInitialized := true;
        Commit();
    end;

    local procedure SetupAndPostSalesOrderAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SetupAndPostSalesDocumentAndPrepIntraJnlLines(IntrastatJnlLine, SalesHeader."Document Type"::Order));
    end;

    local procedure SetupAndPostSalesInvoiceAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SetupAndPostSalesDocumentAndPrepIntraJnlLines(IntrastatJnlLine, SalesHeader."Document Type"::Invoice));
    end;

    local procedure SetupAndPostSalesReturnOrderAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SetupAndPostSalesDocumentAndPrepIntraJnlLines(IntrastatJnlLine, SalesHeader."Document Type"::"Return Order"));
    end;

    local procedure SetupAndPostSalesCreditMemoAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SetupAndPostSalesDocumentAndPrepIntraJnlLines(IntrastatJnlLine, SalesHeader."Document Type"::"Credit Memo"));
    end;

    local procedure SetupAndPostSalesDocumentAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        CreateItemWithTariffNo(Item);
        CreateAndPostSalesDoc(
          DocumentType, CreateForeignCustomerNo, Item."No.", LibraryRandom.RandDec(10, 2));
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType);
        SetAdditionalFieldsOnJnlLine(IntrastatJnlLine, Item."Tariff No.");
        Commit();
        exit(Item."Tariff No.");
    end;

    local procedure SetupAndPostPurchaseOrderAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(SetupAndPostPurchaseDocumentAndPrepIntraJnlLines(IntrastatJnlLine, PurchaseHeader."Document Type"::Order));
    end;

    local procedure SetupAndPostPurchaseInvoiceAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(SetupAndPostPurchaseDocumentAndPrepIntraJnlLines(IntrastatJnlLine, PurchaseHeader."Document Type"::Invoice));
    end;

    local procedure SetupAndPostPurchaseReturnOrderAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(SetupAndPostPurchaseDocumentAndPrepIntraJnlLines(IntrastatJnlLine,
            PurchaseHeader."Document Type"::"Return Order"));
    end;

    local procedure SetupAndPostPurchaseCreditMemoAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(SetupAndPostPurchaseDocumentAndPrepIntraJnlLines(IntrastatJnlLine,
            PurchaseHeader."Document Type"::"Credit Memo"));
    end;

    local procedure SetupAndPostPurchaseDocumentAndPrepIntraJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        CreateItemWithTariffNo(Item);
        CreateAndPostPurchDoc(
          DocumentType, CreateForeignVendorNo, Item."No.", LibraryRandom.RandDec(10, 2));
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType);
        SetAdditionalFieldsOnJnlLine(IntrastatJnlLine, Item."Tariff No.");
        Commit();
        exit(Item."Tariff No.");
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; PostingDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(PostingDate, 0, '<Year,2><Month,2>'));
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Ship-to Country/Region Code", SalesHeader."Sell-to Country/Region Code");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchDoc(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateForeignCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", FindCountryRegionCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateForeignVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", FindCountryRegionCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithTariffNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Tariff No.", CreateTariffNo);
            Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Last Direct Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Modify(true);
        end;
    end;

    local procedure RunIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal")
    begin
        IntrastatJournal.OpenEdit;
    end;

    local procedure RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', WorkDate));
        LibraryVariableStorage.Enqueue(CalcDate('<CM>', WorkDate));
        IntrastatJournal.GetEntries.Invoke;
        VerifyIntrastatJnlLinesExist(IntrastatJnlBatch);
        IntrastatJournal.Close;
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(Filename: Text; IntraJnlLineType: Option)
    var
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
    begin
        IntrastatMakeDiskTaxAuth.InitializeRequest(Filename, IntraJnlLineType);
        IntrastatMakeDiskTaxAuth.UseRequestPage(false);
        IntrastatMakeDiskTaxAuth.RunModal;
    end;

    local procedure RunIntrastatJournalForm(Type: Option)
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(Type);
        IntrastatJournal.Form.Invoke;
    end;

    local procedure SetMandatoryFieldsOnJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; TransportMethod: Code[10]; TransactionType: Code[10])
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindSet();
        repeat
            IntrastatJnlLine.Validate("Transport Method", TransportMethod);
            IntrastatJnlLine.Validate("Transaction Type", TransactionType);
            IntrastatJnlLine.Validate("Net Weight", LibraryRandom.RandDecInRange(1, 10, 2));
            IntrastatJnlLine.Modify(true);
        until IntrastatJnlLine.Next = 0;
    end;

    local procedure SetAdditionalFieldsOnJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Tariff No.", TariffNo);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.Validate("Unit of Measure", FindOrCreateUnitOfMeasure);
        IntrastatJnlLine.Validate("Quantity 2",
          IntrastatJnlLine.Quantity * LibraryRandom.RandIntInRange(1, 2) * 5); // ex: BOX of 5 or 10 PCS
        IntrastatJnlLine.Modify(true);
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.IsFalse(IntrastatJnlLine.IsEmpty, 'No Intrastat Journal Lines exist');
    end;

    local procedure FindOrCreateIntrastatTransactionType(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Type"));
    end;

    local procedure FindOrCreateIntrastatTransportMethod(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
    end;

    local procedure FindCountryRegionCode(): Code[10]
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInfo.Get();
        with CountryRegion do begin
            SetFilter(Code, '<>%1', CompanyInfo."Country/Region Code");
            SetFilter("Intrastat Code", '<>%1', '');
            FindFirst;
            exit(Code);
        end;
    end;

    local procedure FindOrCreateUnitOfMeasure(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Unit of Measure"));
    end;

    local procedure CreateTariffNo() TariffNo: Code[8]
    var
        TariffNumber: Record "Tariff Number";
        TempTariffNo: Code[20];
    begin
        // TariffNo must be length 8 and unique
        TempTariffNo := LibraryUtility.GenerateGUID;
        TariffNo := CopyStr(TempTariffNo, StrLen(TempTariffNo) - MaxStrLen(TariffNo) + 1);
        TariffNumber.Init();
        TariffNumber.Validate("No.", TariffNo);
        TariffNumber.Insert(true);
        exit(TariffNumber."No.");
    end;

    local procedure SetIntrastatCodeOnCountryRegion()
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure SetTariffNoOnItems()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        Item.SetRange("Tariff No.", '');
        if not Item.IsEmpty() then
            Item.ModifyAll("Tariff No.", TariffNumber."No.");
    end;

    local procedure CreateIntrastatFileSetup()
    var
        IntrastatFileSetup: Record "Intrastat - File Setup";
    begin
        IntrastatFileSetup.Init();
        IntrastatFileSetup.Validate("Custom Code",
          LibraryUtility.GenerateRandomText(MaxStrLen(IntrastatFileSetup."Custom Code")));
        IntrastatFileSetup.Validate("Company Serial No.",
          LibraryUtility.GenerateRandomText(MaxStrLen(IntrastatFileSetup."Company Serial No.")));
        IntrastatFileSetup.Insert(true)
    end;

    local procedure VerifyIntrastatFormReportDataSet(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20])
    var
        CompanyInfo: Record "Company Information";
    begin
        FindIntrastatJnlLineFromTariffNo(IntrastatJnlLine, TariffNo);
        VerifyFieldsOnIntrastatJnlLineNotBlank(IntrastatJnlLine);

        CompanyInfo.Get();
        CompanyInfo.TestField("Business Identity Code");
        CompanyInfo.TestField("Registered Home City");

        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.RowCount > 0, 'Empty Dataset');
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('TariffNo_IntraJnlLine', TariffNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('TransacType_IntraJnlLine', IntrastatJnlLine."Transaction Type");
        LibraryReportDataset.AssertCurrentRowValueEquals('TransportMet_IntraJnlLine', IntrastatJnlLine."Transport Method");
        LibraryReportDataset.AssertCurrentRowValueEquals('BusinessIdCode_CompanyInfo', CompanyInfo."Business Identity Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('RegHomeCity_CompanyInfo', CompanyInfo."Registered Home City");
    end;

    local procedure VerifyIntrastatCheckListReportDataSet(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20])
    begin
        FindIntrastatJnlLineFromTariffNo(IntrastatJnlLine, TariffNo);
        VerifyFieldsOnIntrastatJnlLineNotBlank(IntrastatJnlLine);

        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.RowCount > 0, 'Empty Dataset');
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('IntrastatJnlLineTariffNo', TariffNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('IntrastatJnlLineTranType', IntrastatJnlLine."Transaction Type");
        LibraryReportDataset.AssertCurrentRowValueEquals('IntrastatJnlLinTranMethod', IntrastatJnlLine."Transport Method");
    end;

#if not CLEAN17
    local procedure VerifyIntrastatMakeDiskFile(Filename: Text; TariffNo: Code[20]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        Line: Text[1024];
        TransactionType: Text;
        TransportMethod: Text;
        UnitOfMeasure: Text;
        Quantity2Code: Text;
        TariffNoLength: Integer;
        TariffNoStartPos: Integer;
        TransactionTypeLength: Integer;
        TransactionTypeStartPos: Integer;
        TransportMethodLength: Integer;
        TransportMethodStartPos: Integer;
        UnitOfMeasureLength: Integer;
        UnitOfMeasureStartPos: Integer;
        Quantity2CodeLength: Integer;
        Quantity2CodeStartPos: Integer;
    begin
        FindIntrastatJnlLineFromTariffNo(IntrastatJnlLine, TariffNo);
        VerifyFieldsOnIntrastatJnlLineNotBlank(IntrastatJnlLine);

        // UPLOAD the file to the server so the library can access it
        Filename := FileManagement.UploadFileSilent(Filename);

        TariffNoLength := StrLen(TariffNo);
        TariffNoStartPos := 9;

        // Find line with Tariff No.
        Line := LibraryTextFileValidation.FindLineWithValue(CopyStr(Filename, 1, 1024), TariffNoStartPos, TariffNoLength, TariffNo);

        TransactionTypeLength := 2;
        TransactionTypeStartPos := 17;
        TransactionType := LibraryTextFileValidation.ReadValue(Line, TransactionTypeStartPos, TransactionTypeLength);

        TransportMethodLength := 1;
        TransportMethodStartPos := 25;
        TransportMethod := LibraryTextFileValidation.ReadValue(Line, TransportMethodStartPos, TransportMethodLength);

        UnitOfMeasureLength := 3;
        UnitOfMeasureStartPos := 70;
        UnitOfMeasure := LibraryTextFileValidation.ReadValue(Line, UnitOfMeasureStartPos, UnitOfMeasureLength);

        Quantity2CodeLength := 3;
        Quantity2CodeStartPos := 67;
        Quantity2Code := LibraryTextFileValidation.ReadValue(Line, Quantity2CodeStartPos, Quantity2CodeLength);

        Assert.AreEqual(CopyStr(IntrastatJnlLine."Transaction Type", 1, TransactionTypeLength), TransactionType,
          'Wrong value for Transaction Type in file');
        Assert.AreEqual(CopyStr(IntrastatJnlLine."Transport Method", 1, TransportMethodLength), TransportMethod,
          'Wrong value for Transport Method in file');
        Assert.AreEqual(CopyStr(IntrastatJnlLine."Unit of Measure", 1, UnitOfMeasureLength), UnitOfMeasure,
          'Wrong value for Unit Of Measure in file');
        Assert.AreEqual('AAE', Quantity2Code, 'Wrong value for Quantity 2 Code in file');
    end;
#endif

    local procedure VerifyFieldsOnIntrastatJnlLineNotBlank(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine.TestField("Transaction Type");
        IntrastatJnlLine.TestField("Transport Method");
        IntrastatJnlLine.TestField("Unit of Measure");
        IntrastatJnlLine.TestField("Quantity 2");
    end;

    local procedure FindIntrastatJnlLineFromTariffNo(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20])
    begin
        IntrastatJnlLine.SetFilter("Tariff No.", TariffNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure VerifyIntrastatJnlLine(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNo: Code[20]; ExpectedQty: Decimal; ExpectedAmount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            SetRange("Item No.", ItemNo);
            FindFirst;
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
        end;
    end;

    local procedure VerifyTestfieldChecklistError(FieldName: Text)
    begin
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FieldName);
    end;

    local procedure VerifyAdvanvedChecklistError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(AdvChecklistErr);
        VerifyBatchError(IntrastatJnlLine, FieldName);
    end;

    local procedure VerifyBatchError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
        Assert.AreEqual(1, ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Error), '');
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(FieldName, ErrorMessage.Description);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntriesReqPage: TestRequestPage "Get Item Ledger Entries")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GetItemLedgerEntriesReqPage.StartingDate.SetValue(StartDate);
        GetItemLedgerEntriesReqPage.EndingDate.SetValue(EndDate);
        GetItemLedgerEntriesReqPage.IndirectCostPctReq.SetValue(0);
        GetItemLedgerEntriesReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntratstatJnlFormReqPageHandler(var IntrastatFormReqPage: TestRequestPage "Intrastat - Form")
    var
        Type: Variant;
    begin
        LibraryVariableStorage.Dequeue(Type);
        IntrastatFormReqPage."Intrastat Jnl. Line".SetFilter(Type, Format(Type));
        IntrastatFormReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatJnlCheckListReqPageHandler(var IntrastatChecklistReqPage: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklistReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    procedure IntrastatMakeDiskTaxAuthCheckControlRequestPageHandler(var IntrastatMakeDiskTaxAuth: TestRequestPage "Intrastat - Make Disk Tax Auth")
    begin
        LibraryVariableStorage.Enqueue(IntrastatMakeDiskTaxAuth.IntrastatJnlLineType.Visible());
    end;
}

