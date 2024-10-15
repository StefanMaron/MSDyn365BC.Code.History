codeunit 144055 "ERM ES Intrastat"
{
    // // [FEATURE] [Intrastat]
    // 
    // Test for feature INTRSATAT:
    //   1. Test to verify Cost Regulations % field is updated from the Item Card on Intrastat Journal and Cost Regulation % and Statistical System are editable on Intrastat Journal.
    //   2. Test to verify caption of Make Diskette Action is Make Declaration on Intrastat journal.
    //   3. Test to verify Amount and Statistical Value on Intrastat Journal Line for Posted Sales Invoice.
    //   4. Test to verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line for Posted Sales Invoice.
    //   5. Test to verify Amount and Statistical Value for multiline Posted Sales Invoice with Item Charge consideration on Intrastat Journal Line.
    //   6. Test to verify Amount and Statistical Value for multiline Posted Sales Invoice with Item Charge consideration on Intrastat Journal Line.
    //   7. Test to verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line for Posted Purchase Invoice.
    //   8. Test to verify Amount and Statistical Value on Intrastat Journal Line for Posted Purchase Invoice.
    //   9. Test to verify error Amount must have a value in Intrastat Journal Line.
    //  10. Test to verify Amount in Intrastat Journal after posting a Purchase Order With Invoice Discount.
    //  11. Test to verify Amount in Intrastat Journal after posting a Purchase Return Order With Invoice Discount.
    //  12. Test to verify Amount in Intrastat Journal after posting a Sales Order With Invoice Discount.
    //  13. Test to verify Amount in Intrastat Journal after posting a Sales Return Order With Invoice Discount.
    // 
    //   Covers Test Cases for WI - 350238.
    //   ---------------------------------------------------------------------------------------------
    //   Test Function Name                                                                     TFS ID
    //   ---------------------------------------------------------------------------------------------
    //   IntrastatJournalWithCostRegulationPct                                                  281816
    //   MakeDeclarationCaptionIntrastatJournal                                          152005,154648
    //   IntrastatJournalForPostedSalesInvoice                                                  155586
    //   IntrastatJournalForPostedSalesInvoiceWithItemCharge                                    155585
    //   IntrastatJnlForPostedMultiLineSalesInvWithItemCharge                                   155587
    //   IntrastatJnlForPostedMultiLinePurchInvWithItemCharge                                   155590
    //   IntrastatJournalForPostedPurchaseInvoice                                               155589
    //   IntrastatJournalForPostedPurchInvWithItemCharge                                        155588
    //   MakeDeclarationForIntrastatJournalWithoutAmountError                                   281819
    // 
    //   Covers Test Cases for WI - 352096.
    //   ---------------------------------------------------------------------------------------------
    //   Test Function Name                                                                     TFS ID
    //   ---------------------------------------------------------------------------------------------
    //   IntrastatJournalForPurchaseOrderWithInvoiceDiscount                                    157107
    //   IntrastatJournalForPurchaseReturnWithInvoiceDiscount                                   157108
    //   IntrastatJournalForSalesOrderWithInvoiceDiscount                                       157105
    //   IntrastatJournalForSalesReturnWithInvoiceDiscount                                      157106

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustHaveValueErr: Label 'Amount must have a value in Intrastat Jnl. Line';
        ValueMustEqualMsg: Label 'Value must be equal';
        ValueMustEditableMsg: Label 'Value must be editable';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ReportedMustBeNoErr: Label 'Reported must be equal to ''No''  in Intrastat Jnl. Batch';
        TestFieldErrCodeTxt: Label 'TestField';
        TransactionTypeMustHaveValueErr: Label 'Transaction Type must have a value in Intrastat Jnl. Line';
        FileNotCreatedErr: Label 'Intrastat file was not created';
        LineSymbolIsLineFeedErr: Label 'The last symbol of %1 file is line feed', Comment = '%1 - number of file';
        FormatTotalWeightErr: Label 'Wrong formaing of Total Weight in Intrastat Jnl. Line.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalWithCostRegulationPct()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
        Amount: Decimal;
    begin
        // Test to verify Cost Regulations % field is updated from the Item Card on Intrastat Journal and Cost Regulation % and Statistical System are editable on Intrastat Journal.

        // Setup: Create Item with Cost Regulation %, create and post Sales Invoice.
        Initialize();
        CreateItem(Item);
        UpdateItemCostRegulationPct(Item);
        CreateSalesInvoice(SalesLine, Item."No.", LibraryRandom.RandInt(100));  // Random Unit Price.
        PostSalesInvoice(SalesLine."Document No.");
        Amount := Round(SalesLine.Amount * (1 + Item."Cost Regulation %" / 100), 1);  // Round to nearest whole value.

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Statistical System is editable on Intrastat Journal and Intrastat Journal Line is created with taking Cost regulation % in consideration.
        VerifyIntrastatJournalStatisticalSystemEditable(IntrastatJnlBatchName, Item."No.");
        VerifyFirstIntrastatJnlLine(IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", Amount, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure MakeDeclarationCaptionIntrastatJournal()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Test to verify caption of Make Diskette Action is Make Declaration on Intrastat journal.

        // Setup: Open Intrastat Journal.
        IntrastatJournal.OpenEdit;

        // Exercise: Invoke Make Declaration from Intrastat Journal.
        IntrastatJournal.CreateFile.Invoke;  // Opens  IntrastatMakeDeclarationCaptionRequestPageHandler.

        // Verify: Verification is done in IntrastatMakeDeclarationCaptionRequestPageHandler that Caption of Request Page is Edit - Intrastat - Make Declaration.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPostedSalesInvoice()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value on Intrastat Journal Line for Posted Sales Invoice.

        // Setup: Create and Post Sales Invoice.
        Initialize();
        CreateItem(Item);
        CreateSalesInvoice(SalesLine, Item."No.", LibraryRandom.RandInt(100));  // Random Unit Price.
        PostSalesInvoice(SalesLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine.Amount, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPostedSalesInvoiceWithItemCharge()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line for Posted Sales Invoice.

        // Setup: Create Sales Invoice with Item Charge Assignment and post Sales Invoice.
        Initialize();
        CreateItem(Item);
        CreateSalesInvoice(SalesLine, Item."No.", LibraryRandom.RandInt(100));  // Random Unit Price.
        CreateSalesItemChargeAssignment(SalesLine."Document No.", SalesLine."Document Type"::Invoice);
        PostSalesInvoice(SalesLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine.Amount, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ItemChargeAssignmentSalesPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlForPostedMultiLineSalesInvWithItemCharge()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value for multiline Posted Sales Invoice with Item Charge consideration on Intrastat Journal Line.

        // Setup: Create multiple Line Sales Invoice with Item Charge Assignment and post Sales Invoice.
        Initialize();
        CreateItem(Item);
        CreateSalesInvoice(SalesLine, Item."No.", LibraryRandom.RandInt(100));  // Random Unit Price.
        CreateSalesLine(
          SalesLine2, SalesLine."Document Type"::Invoice, SalesLine."Document No.", SalesLine2.Type::Item, Item."No.",
          LibraryRandom.RandInt(100));  // Random Unit Price.
        CreateSalesItemChargeAssignment(SalesLine."Document No.", SalesLine."Document Type"::Invoice);
        PostSalesInvoice(SalesLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine.Amount, SalesLine.Amount);
        VerifyLastIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine2.Amount, SalesLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ItemChargeAssignmentPurchPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlForPostedMultiLinePurchInvWithItemCharge()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value for multiline Posted Sales Invoice with Item Charge consideration on Intrastat Journal Line.

        // Setup: Create Purchase Invoice with Item Charge Assignment and post Sales Invoice.
        Initialize();
        CreateItem(Item);
        CreatePurchaseInvoice(PurchaseLine, Item."No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseLine2."Document Type"::Invoice, PurchaseLine."Document No.", PurchaseLine2.Type::Item, Item."No.");
        CreatePurchaseItemChargeAssignment(PurchaseLine."Document No.", PurchaseLine."Document Type"::Invoice);
        PostPurchaseInvoice(PurchaseLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, Item."No.", Item."Tariff No.", PurchaseLine.Amount, PurchaseLine.Amount);
        VerifyLastIntrastatJnlLine(
          IntrastatJnlBatchName, Item."No.", Item."Tariff No.", PurchaseLine2.Amount, PurchaseLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPostedPurchaseInvoice()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line for Posted Purchase Invoice.

        // Setup: Create and Post Purchase Invoice
        Initialize();
        CreateItem(Item);
        CreatePurchaseInvoice(PurchaseLine, Item."No.");
        PostPurchaseInvoice(PurchaseLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(IntrastatJnlBatchName, PurchaseLine."No.", Item."Tariff No.", PurchaseLine.Amount, PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ItemChargeAssignmentPurchPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPostedPurchInvWithItemCharge()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify Amount and Statistical Value on Intrastat Journal Line for Posted Purchase Invoice.

        // Setup: Create Purchase Invoice with Item Charge Assignment and post Purchase Invoice.
        Initialize();
        CreateItem(Item);
        CreatePurchaseInvoice(PurchaseLine, Item."No.");
        CreatePurchaseItemChargeAssignment(PurchaseLine."Document No.", PurchaseLine."Document Type"::Invoice);
        PostPurchaseInvoice(PurchaseLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical Value with Item Charge consideration on Intrastat Journal Line.
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, PurchaseLine."No.", Item."Tariff No.", PurchaseLine.Amount, PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MakeDeclarationForIntrastatJournalWithoutAmountError()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // Test to verify error Amount must have a value in Intrastat Journal Line.

        // Setup: Create and Post Sales Invoice.
        Initialize();
        CreateItem(Item);
        CreateSalesInvoice(SalesLine, Item."No.", 0);  // Unit Price - 0.
        PostSalesInvoice(SalesLine."Document No.");
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);
        UpdateIntrastatJnlLine(IntrastatJnlBatchName, Item."No.");

        // Exercise: Invoke Make Declaration from Intrastat Journal
        asserterror MakeDeclarationIntrastatJournal(IntrastatJnlBatchName, Item."No.");

        // Verify: Verify error, Amount must have a value in Intrastat Jnl. Line.
        Assert.ExpectedError(AmountMustHaveValueErr);
        Assert.ExpectedErrorCode(TestFieldErrCodeTxt);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,GetItemLedgerEntriesRequestPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPurchaseOrderWithInvoiceDiscount()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
        ItemChargeNo: Code[20];
        IntrastatJnlBatchName: Code[10];
        Amount: Decimal;
    begin
        // Test to verify amount in Intrastat Journal after posting a Purchase Order With Invoice Discount.

        // Setup: Create Purchase Order with Line Discount and Vendor Invoice Discount on Vendor with Item Charge Assignment.
        Initialize();
        DocumentNo := CreateMultiplePurchaseLineWithLineDiscount(PurchaseLine, PurchaseLine2, PurchaseLine."Document Type"::Order);
        Amount :=
          CreatePurchItemChargeAssignmentPostPurchDoc(
            ItemChargeNo, PurchaseLine."Document Type"::Order, DocumentNo, PurchaseLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical value on Intrastat Journal for different Items and Value Entries for different Items.
        Item.Get(PurchaseLine."No.");
        Item2.Get(PurchaseLine2."No.");

        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, PurchaseLine."No.", Item."Tariff No.", PurchaseLine.Amount, PurchaseLine.Amount);
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, PurchaseLine2."No.", Item2."Tariff No.", PurchaseLine2.Amount, PurchaseLine2.Amount);
        VerifyMultipleValueEntryForPurchase(Item."No.", ItemChargeNo, 0, Amount / 2, PurchaseLine.Amount);  // Cost Amount (Non-Invtbl.), Cost Amount (Actual).
        VerifyMultipleValueEntryForPurchase(Item2."No.", ItemChargeNo, 0, Amount / 2, PurchaseLine2.Amount);  // Cost Amount (Non-Invtbl.), Cost Amount (Actual).
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,GetItemLedgerEntriesRequestPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForPurchaseReturnWithInvoiceDiscount()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
        ItemChargeNo: Code[20];
        IntrastatJnlBatchName: Code[10];
        Amount: Decimal;
    begin
        // Test to verify amount in Intrastat Journal after posting a Purchase Return Order With Invoice Discount.

        // Setup: Create Purchase Return Order with Line Discount and Vendor Invoice Discount on Vendor with Item Charge Assignment.
        Initialize();
        DocumentNo :=
          CreateMultiplePurchaseLineWithLineDiscount(PurchaseLine, PurchaseLine2, PurchaseLine."Document Type"::"Return Order");
        Amount :=
          CreatePurchItemChargeAssignmentPostPurchDoc(
            ItemChargeNo, PurchaseLine."Document Type"::"Return Order", DocumentNo, PurchaseLine."Document No.");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical value on Intrastat Journal for different Items and Value Entries for different Items.
        Item.Get(PurchaseLine."No.");
        Item2.Get(PurchaseLine2."No.");
        VerifyFirstIntrastatJnlLine(IntrastatJnlBatchName, PurchaseLine."No.", Item."Tariff No.", PurchaseLine.Amount, PurchaseLine.Amount);
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, PurchaseLine2."No.", Item2."Tariff No.", PurchaseLine2.Amount, PurchaseLine2.Amount);
        VerifyMultipleValueEntryForPurchase(Item."No.", ItemChargeNo, -Amount / 2, 0, -PurchaseLine.Amount);  // Cost Amount (Non-Invtbl.), Cost Amount (Actual).
        VerifyMultipleValueEntryForPurchase(Item2."No.", ItemChargeNo, -Amount / 2, 0, -PurchaseLine2.Amount);  // Cost Amount (Non-Invtbl.), Cost Amount (Actual).
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,GetItemLedgerEntriesRequestPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForSalesOrderWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify Amount in Intrastat Journal after posting a Sales Order With Invoice Discount.
        IntrastatJournalForSalesWithInvoiceDiscount(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,GetItemLedgerEntriesRequestPageHandler,AmountStrMenuHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalForSalesReturnWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify Amount in Intrastat Journal after posting a Sales Return Order With Invoice Discount.
        IntrastatJournalForSalesWithInvoiceDiscount(SalesHeader."Document Type"::"Return Order");
    end;

    local procedure IntrastatJournalForSalesWithInvoiceDiscount(DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustomerNo: Code[20];
        ItemChargeNo: Code[20];
        IntrastatJnlBatchName: Code[10];
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create Sales Order or Return Order with Line Discount and Customer Invoice Discount on Customer with Item Charge Assignment.
        Initialize();
        CreateItem(Item);
        CreateItem(Item2);
        CustomerNo := CreateCustomer;
        CreateCustomerInvoiceAndSalesLineDiscount(Item."No.", Item2."No.", CustomerNo);
        DocumentNo := CreateSalesHeaderWithPaymentDiscount(DocumentType, CustomerNo);
        CreateSalesLine(SalesLine, DocumentType, DocumentNo, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Unit Price.
        CreateSalesLine(SalesLine2, DocumentType, DocumentNo, SalesLine.Type::Item, Item2."No.", LibraryRandom.RandDec(10, 2));  // Random Unit Price.
        Amount := CreateSalesItemChargeAssignment(SalesLine."Document No.", DocumentType);
        ItemChargeNo := FindSalesLine(DocumentType, DocumentNo);
        CalculateInvoiceDiscAndPostSalesDocument(DocumentType, DocumentNo);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(false);  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify Amount and Statistical value on Intrastat Journal for different Items and Value Entries for different Items for Sales Amount (Actual).
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine.Amount, SalesLine.Amount);
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine2."No.", Item2."Tariff No.", SalesLine2.Amount, SalesLine2.Amount);
        VerifyMultipleValueEntryForSales(DocumentType, Item."No.", ItemChargeNo, Amount / 2, SalesLine.Amount);
        VerifyMultipleValueEntryForSales(DocumentType, Item2."No.", ItemChargeNo, Amount / 2, SalesLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnSecondRun()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        IntrastatJournal: TestPage "Intrastat Journal";
        Filename: Text;
        "Count": Integer;
    begin
        // [SCENARIO] It should not to be possible to "Make Declaration" from one Intrastat Journal Batch having "Exported" flag
        Initialize();

        // [GIVEN] Intrastat Journal Batch having lines
        CreateItem(Item);
        IntrastatJnlBatch.SetFilter(Name, CreateIntrastatJournalBatch);
        IntrastatJnlBatch.FindFirst();

        for Count := 1 to 100 do
            MakeIntrastatJnlLine(IntrastatJnlBatch, Item."No.");

        Filename := FileManagement.ServerTempFileName('txt');

        // [GIVEN] Run Make Declaration (Report 593) for Intrastat Journal Batch
        IntrastatJnlBatch.SetFilter("Journal Template Name", IntrastatJnlBatch."Journal Template Name");

        OpenIntrastatJournal(IntrastatJournal, IntrastatJnlBatch.Name, Item."No.");
        IntrastatJournal.Close;
        Commit();

        RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlBatch);

        Assert.IsTrue(FileManagement.ServerFileExists(Filename), FileNotCreatedErr);

        // [WHEN] Run Make Declaration (Report 593) for the 2nd time
        asserterror RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlBatch);

        // [THEN] "Reported must be equal to 'No' in Intrastat Jnl. Batch" error appears
        Assert.ExpectedError(ReportedMustBeNoErr);
        Assert.ExpectedErrorCode(TestFieldErrCodeTxt);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnBlankTransactionType()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        "Count": Integer;
        Filename: Text;
    begin
        // [SCENARIO] "Make Declaration" action of Intrastat Journal should throw an error, while exporting lines having empty "Transaction Type"
        Initialize();

        // [GIVEN] Intrastat Journal Batch having lines with empty "Transaction Type"
        CreateItem(Item);
        IntrastatJnlBatch.SetFilter(Name, CreateIntrastatJournalBatch);
        IntrastatJnlBatch.FindFirst();

        for Count := 1 to 100 do
            MakeIntrastatJnlLine(IntrastatJnlBatch, Item."No.");

        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.ModifyAll("Transaction Type", '');

        Filename := FileManagement.ServerTempFileName('txt');

        // [WHEN] Making Declaration
        Commit();
        asserterror RunIntrastatMakeDiskTaxAuth(Filename, IntrastatJnlBatch);

        // [THEN] "Transaction Type must have a value in Intrastat Jnl. Line" error is thrown
        Assert.ExpectedError(TransactionTypeMustHaveValueErr);
        Assert.ExpectedErrorCode(TestFieldErrCodeTxt);
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
        Initialize();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineAmount(IntrastatJnlBatch, Item."No.", 1, Item."Unit Price");
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
        Initialize();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Return Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::"Return Order", CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineAmount(IntrastatJnlBatch, Item."No.", 1, Item."Unit Price");
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
        Initialize();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineAmount(IntrastatJnlBatch, Item."No.", 1, Item."Last Direct Cost");
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
        Initialize();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Return Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineAmount(IntrastatJnlBatch, Item."No.", 1, Item."Last Direct Cost");
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckForEmptylineIn1000LinesDeclarationFile()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        Zipfile: DotNet ZipFile;
        "Count": Integer;
        ExtractDirectory: Text;
        FileName: Text;
    begin
        // [FEATURE] [Intrastat Declaration]
        // [SCENARIO 376056] Intrastat Declaration file of 1000 lines should not have empty line in the end (1001)

        // [GIVEN] 2100 Intrastat Lines in the same Batch to be exported to 3 files (1000, 1000, 100)
        Initialize();
        CreateItem(Item);
        IntrastatJnlBatch.SetFilter(Name, CreateIntrastatJournalBatch);
        IntrastatJnlBatch.FindFirst();

        for Count := 1 to 2100 do
            MakeIntrastatJnlLine(IntrastatJnlBatch, Item."No.");

        IntrastatJnlBatch.Reported := false;
        IntrastatJnlBatch.Modify();

        // [WHEN] Export Intrastat Declaration (Report 593)
        Commit();
        FileName := FileManagement.ServerTempFileName('txt');
        RunIntrastatMakeDiskTaxAuth(FileName, IntrastatJnlBatch);

        // [THEN] File 1 has no empty line in the end
        ExtractDirectory := FileManagement.ServerTempFileName('tmp');
        Zipfile.ExtractToDirectory(FileName, ExtractDirectory);
        VerifyLastSymbolOfFile(ExtractDirectory, IntrastatJnlBatch."Statistics Period", 1);

        // [THEN] File 2 has no empty line in the end
        VerifyLastSymbolOfFile(ExtractDirectory, IntrastatJnlBatch."Statistics Period", 2);

        // [THEN] File 3 has no empty line in the end
        VerifyLastSymbolOfFile(ExtractDirectory, IntrastatJnlBatch."Statistics Period", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingDownTotalWeightWithDecimalPlacesOfIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 210322] The value of "Total Weight" of "Intrastat Jnl. Line" must be rounded down and formatted as decimal with 2 decimal places in table "Intrastat Jnl. Line" and page "Intrastat Journal"
        Initialize();

        // [GIVEN] "Intrastat Jnl. Line" with "Total Weight" = 1.234
        CreateaIntrastatJnlLineWithTotalWeight(IntrastatJnlLine, 1.234);
        Commit();

        // [WHEN] Open page "Intrastat Journal"
        IntrastatJournal.OpenView;
        IntrastatJournal.CurrentJnlBatchName.SetValue(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Value of "Total Weight" on the page formated as decimal - "1,23"
        IntrastatJournal."Total Weight".AssertEquals(Format(1.23));

        // [THEN] Value of "Total Weight" in the table formated as decimal - "1,23"
        Assert.AreEqual(Format(1.23), Format(IntrastatJnlLine."Total Weight"), FormatTotalWeightErr);

        // [THEN] Value of "Total Weight" in the table are equal - "1,234"
        IntrastatJnlLine.TestField("Total Weight", 1.234);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingUpTotalWeightWithDecimalPlacesOfIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 210322] The value of "Total Weight" of "Intrastat Jnl. Line" must be rounded up and formatted as decimal with 2 decimal places in table "Intrastat Jnl. Line" and page "Intrastat Journal"
        Initialize();

        // [GIVEN] "Intrastat Jnl. Line" with "Total Weight" = 1.236
        CreateaIntrastatJnlLineWithTotalWeight(IntrastatJnlLine, 1.236);
        Commit();

        // [WHEN] Open page "Intrastat Journal"
        IntrastatJournal.OpenView;
        IntrastatJournal.CurrentJnlBatchName.SetValue(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Value of "Total Weight" on the page formated as decimal - "1,24"
        IntrastatJournal."Total Weight".AssertEquals(Format(1.24));

        // [THEN] Value of "Total Weight" in the table formated as decimal - "1,24"
        Assert.AreEqual(Format(1.24), Format(IntrastatJnlLine."Total Weight"), FormatTotalWeightErr);

        // [THEN] Value of "Total Weight" in the table are equal - "1,236"
        IntrastatJnlLine.TestField("Total Weight", 1.236);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalGetItemLedgerEntriesShippedNotInvoicedSkipNotInvoiced()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // [SCENARIO 387998] Run Get Item Ledger Entries for shipped but not invoiced order with 'Skip not invoiced entries'
        Initialize();

        // [GIVEN] Sales order is shipped but not invoiced
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        CreateItem(Item);
        CreateSalesLine(
          SalesLine, SalesLine."Document Type"::Order, SalesHeader."No.",
          SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Get Entries on Intrastat Journal with 'Skip not invoiced entries' option
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(true);

        // [THEN] Intrastat Jnl. Line is not created
        FilterIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatchName, Item."No.");
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalGetItemLedgerEntriesShippedAndInvoicedSkipNotInvoiced()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // [SCENARIO 387998] Run Get Item Ledger Entries for shipped and invoiced order with 'Skip not invoiced entries'
        Initialize();

        // [GIVEN] Sales order is shipped and invoiced
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        CreateItem(Item);
        CreateSalesLine(
          SalesLine, SalesLine."Document Type"::Order, SalesHeader."No.",
          SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1000, 2000));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Get Entries on Intrastat Journal with 'Skip not invoiced entries' option
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(true);

        // [THEN] Intrastat Jnl. Line is created for relevant sales document
        VerifyFirstIntrastatJnlLine(
          IntrastatJnlBatchName, SalesLine."No.", Item."Tariff No.", SalesLine.Amount, SalesLine.Amount);
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();
        IntrastatJnlTemplate.DeleteAll(true);
        IntrastatSetup.DeleteAll();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        TariffNumber: Record "Tariff Number";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion);
        TariffNumber.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Country/Region of Origin Code", VATRegistrationNoFormat."Country/Region Code");
        Item.Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", VATRegistrationNoFormat."Country/Region Code");
        Customer.Validate("VAT Registration No.", VATRegistrationNoFormat.Format);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", VATRegistrationNoFormat."Country/Region Code");
        Vendor.Validate("VAT Registration No.", VATRegistrationNoFormat.Format);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; No: Code[20]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer);
        CreateSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesHeader."No.", SalesLine.Type::Item, No, UnitPrice);
    end;

    local procedure CreateMultiplePurchaseLineWithLineDiscount(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    var
        Item: Record Item;
        Item2: Record Item;
        VendorNo: Code[20];
    begin
        CreateItem(Item);
        CreateItem(Item2);
        VendorNo := CreateVendor;
        CreateVendorInvoiceAndPurchaseLineDiscount(Item."No.", Item2."No.", VendorNo);
        DocumentNo := CreatePurchaseHeaderWithPaymentDiscount(DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseLine, DocumentType, DocumentNo, PurchaseLine.Type::Item, Item."No.");
        CreatePurchaseLine(PurchaseLine2, DocumentType, DocumentNo, PurchaseLine.Type::Item, Item2."No.");
    end;

    local procedure CreatePurchItemChargeAssignmentPostPurchDoc(var ItemChargeNo: Code[20]; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; PurchaseHeaderNo: Code[20]) Amount: Decimal
    begin
        Amount := CreatePurchaseItemChargeAssignment(PurchaseHeaderNo, DocumentType);
        ItemChargeNo := FindPurchaseLine(DocumentType, DocumentNo);
        CalculateInvoiceDiscAndPostPurchaseDocument(DocumentType, DocumentNo);
    end;

    local procedure CreatePurchaseHeaderWithPaymentDiscount(DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesHeaderWithPaymentDiscount(DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        exit(SalesHeader."No.")
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor);
        CreatePurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseHeader."No.", PurchaseLine.Type::Item, No);
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchDoc(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateForeignCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("Country/Region Code", CreateCountryRegionCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateForeignVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateCountryRegionCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesItemChargeAssignment(No: Code[20]; DocumentType: Enum "Sales Document Type"): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(DocumentType, No);
        CreateSalesLine(
          SalesLine, DocumentType, SalesHeader."No.", SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo,
          LibraryRandom.RandInt(100));  // Random Unit Price.
        SalesLine.ShowItemChargeAssgnt();  // Opens ItemChargeAssignmentSalesPageHandler.
        exit(SalesLine.Amount);
    end;

    local procedure CreatePurchaseItemChargeAssignment(No: Code[20]; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Get(DocumentType, No);
        CreatePurchaseLine(PurchaseLine, DocumentType, No, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo);
        PurchaseLine.ShowItemChargeAssgnt();  // Opens ItemChargeAssignmentPurchPageHandler.
        exit(PurchaseLine.Amount);
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJournalBatch(): Code[10]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod));  // Statistics Period in Last Two digits of year and Month.
        IntrastatJnlBatch.Modify(true);
        exit(IntrastatJnlBatch.Name);
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

    local procedure CreateCustomerInvoiceDiscount("Code": Code[20]; CurrencyCode: Code[10])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Code, CurrencyCode, LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendorInvoiceDiscount("Code": Code[20]; CurrencyCode: Code[10])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Code, CurrencyCode, LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

#if not CLEAN19
    local procedure CreatePurchaseLineDiscount(ItemNo: Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, ItemNo, VendorNo, WorkDate, CurrencyCode, '', '', LibraryRandom.RandDec(10, 2));  // Blank Variant Code and unit Of Measure Code, Random Minimum Quantity.
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure CreateSalesLineDiscount("Code": Code[20]; SalesCode: Code[20]; CurrencyCode: Code[10])
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Code, SalesLineDiscount."Sales Type"::Customer, SalesCode,
          WorkDate, CurrencyCode, '', '', LibraryRandom.RandDec(10, 2));  // Blank Variant Code and unit Of Measure Code, Random Minimum Quantity.
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
    end;
#else
    local procedure CreatePurchaseLineDiscount(ItemNo: Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine, '', "Price Source Type"::Vendor, VendorNo, "Price Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Starting Date", WorkDate);
        PriceListLine.Validate("Minimum Quantity", LibraryRandom.RandDec(10, 2));
        PriceListLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateSalesLineDiscount("Code": Code[20]; SalesCode: Code[20]; CurrencyCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', "Price Source Type"::Customer, SalesCode, "Price Asset Type"::Item, "Code");
        PriceListLine.Validate("Currency Code", CurrencyCode);
        PriceListLine.Validate("Starting Date", WorkDate);
        PriceListLine.Validate("Minimum Quantity", LibraryRandom.RandDec(10, 2));
        PriceListLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;
#endif

    local procedure CreateCustomerInvoiceAndSalesLineDiscount(ItemNo: Code[20]; ItemNo2: Code[20]; CustomerNo: Code[20])
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        CreateCustomerInvoiceDiscount(CustomerNo, Currency.Code);
        CreateSalesLineDiscount(ItemNo, CustomerNo, Currency.Code);
        CreateSalesLineDiscount(ItemNo2, CustomerNo, Currency.Code);
    end;

    local procedure CreateVendorInvoiceAndPurchaseLineDiscount(ItemNo: Code[20]; ItemNo2: Code[20]; VendorNo: Code[20])
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        CreateVendorInvoiceDiscount(VendorNo, Currency.Code);
        CreatePurchaseLineDiscount(ItemNo, VendorNo, Currency.Code);
        CreatePurchaseLineDiscount(ItemNo2, VendorNo, Currency.Code);
    end;

    local procedure CalculateInvoiceDiscAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        PurchaseHeader.CalcInvDiscForHeader;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CalculateInvoiceDiscAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        SalesHeader.CalcInvDiscForHeader;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FilterIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
    end;

    local procedure FindPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        exit(PurchaseLine."No.");
    end;

    local procedure FindSalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        exit(SalesLine."No.");
    end;

    local procedure GetEntriesIntrastatJournal(SkipNotInvoices: Boolean) IntrastatJnlBatchName: Code[10]
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        LibraryVariableStorage.Enqueue(SkipNotInvoices);
        IntrastatJnlBatchName := CreateIntrastatJournalBatch;
        Commit();  // Commit required.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.GetEntries.Invoke;  // Opens GetItemLedgerEntriesRequestPageHandler.
        IntrastatJournal.Close;
    end;

    local procedure OpenIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal"; CurrentJnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        IntrastatJournal.FILTER.SetFilter("Item No.", ItemNo);
    end;

    local procedure PostSalesInvoice(No: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, No);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseInvoice(No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateIntrastatJnlLine(JournalBatchName: Code[10]; ItemNo: Code[20])
    var
        EntryExitPoint: Record "Entry/Exit Point";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TransactionType: Record "Transaction Type";
        TransportMethod: Record "Transport Method";
    begin
        FilterIntrastatJnlLine(IntrastatJnlLine, JournalBatchName, ItemNo);
        IntrastatJnlLine.FindFirst();
        TransactionType.FindFirst();
        TransportMethod.FindFirst();
        EntryExitPoint.FindFirst();
        IntrastatJnlLine.Validate("Transaction Type", TransactionType.Code);
        IntrastatJnlLine.Validate("Transport Method", TransportMethod.Code);
        IntrastatJnlLine.Validate("Entry/Exit Point", EntryExitPoint.Code);
        IntrastatJnlLine.Modify(true);
    end;

    local procedure UpdateItemCostRegulationPct(var Item: Record Item)
    begin
        Item.Validate("Cost Regulation %", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure MakeDeclarationIntrastatJournal(CurrentJnlBatchName: Code[10]; ItemNo: Code[20])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        Commit();  // Commit required.
        OpenIntrastatJournal(IntrastatJournal, CurrentJnlBatchName, ItemNo);
        IntrastatJournal.CreateFile.Invoke;  // Opens IntrastatMakeDeclarationRequestPageHandler.
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

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."Intrastat Code" := CountryRegion.Code;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure RunIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal")
    begin
        IntrastatJournal.OpenEdit;
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(Filename: Text; var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatMakeDeclaration: Report "Intrastat - Make Declaration";
    begin
        IntrastatMakeDeclaration.InitializeRequest(Filename);
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatMakeDeclaration.SetTableView(IntrastatJnlLine);
        IntrastatMakeDeclaration.Run();
    end;

    local procedure CreateItemWithTariffNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
        Item.Modify(true);
    end;

    local procedure MakeIntrastatJnlLine(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine."Country/Region Code" :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Country/Region Code"), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine.Area := LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo(Area), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine."Transaction Type" :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Transaction Type"), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine."Transport Method" :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Transport Method"), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine."Tariff No." :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Tariff No."), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine."Country/Region of Origin Code" :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Country/Region of Origin Code"), DATABASE::"Intrastat Jnl. Line");
        IntrastatJnlLine."Total Weight" := LibraryRandom.RandInt(100);
        IntrastatJnlLine."Item No." := ItemNo;
        IntrastatJnlLine.Quantity := LibraryRandom.RandInt(10);
        IntrastatJnlLine.Amount := LibraryRandom.RandDec(100, 2);
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateaIntrastatJnlLineWithTotalWeight(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TotalWeight: Decimal)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine."Total Weight" := TotalWeight;
        IntrastatJnlLine.Modify();
    end;

    local procedure VerifyFirstIntrastatJnlLine(JournalBatchName: Code[10]; ItemNo: Code[20]; TariffNo: Code[20]; StatisticalValue: Decimal; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FilterIntrastatJnlLine(IntrastatJnlLine, JournalBatchName, ItemNo);
        IntrastatJnlLine.FindFirst();
        VerifyIntrastatJnlLine(IntrastatJnlLine, TariffNo, StatisticalValue, Amount);
    end;

    local procedure VerifyLastIntrastatJnlLine(JournalBatchName: Code[10]; ItemNo: Code[20]; TariffNo: Code[20]; StatisticalValue: Decimal; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FilterIntrastatJnlLine(IntrastatJnlLine, JournalBatchName, ItemNo);
        IntrastatJnlLine.FindLast();
        VerifyIntrastatJnlLine(IntrastatJnlLine, TariffNo, StatisticalValue, Amount);
    end;

    local procedure VerifyIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20]; StatisticalValue: Decimal; Amount: Decimal)
    begin
        IntrastatJnlLine.TestField("Tariff No.", TariffNo);
        Assert.AreNearlyEqual(
          IntrastatJnlLine."Statistical Value", StatisticalValue, LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
        Assert.AreNearlyEqual(
          IntrastatJnlLine.Amount, Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
    end;

    local procedure VerifyIntrastatJournalStatisticalSystemEditable(CurrentJnlBatchName: Code[10]; ItemNo: Code[20])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        OpenIntrastatJournal(IntrastatJournal, CurrentJnlBatchName, ItemNo);
        Assert.IsTrue(IntrastatJournal."Statistical System".Editable, ValueMustEditableMsg);
    end;

    local procedure VerifyValueEntryForPurchase(ItemNo: Code[20]; ItemChargeNo: Code[20]; CostAmountNonInvtbl: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetFilter("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          CostAmountNonInvtbl, ValueEntry."Cost Amount (Non-Invtbl.)", LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
    end;

    local procedure VerifyValueEntryForSales(DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ItemChargeNo: Code[20]; SalesAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        if DocumentType = DocumentType::"Return Order" then
            SalesAmountActual := -SalesAmountActual;
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          SalesAmountActual, ValueEntry."Sales Amount (Actual)", LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
    end;

    local procedure VerifyMultipleValueEntryForPurchase(ItemNo: Code[20]; ItemChargeNo: Code[20]; Amount: Decimal; Amount2: Decimal; Amount3: Decimal)
    begin
        // Verify Cost Amount (Non-Invtbl.) and Cost Amount (Actual) for Value Entry.
        VerifyValueEntryForPurchase(ItemNo, ItemChargeNo, Amount, Amount2);
        VerifyValueEntryForPurchase(ItemNo, '', 0, Amount3);  // 0 - Cost Amount (Non-Invtbl.) and Blank Item Charge.
    end;

    local procedure VerifyMultipleValueEntryForSales(DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ItemChargeNo: Code[20]; Amount: Decimal; Amount2: Decimal)
    begin
        // Verify Sales Amount (Actual) for Value Entry.
        VerifyValueEntryForSales(DocumentType, ItemNo, ItemChargeNo, Amount);
        VerifyValueEntryForSales(DocumentType, ItemNo, '', Amount2);  // Blank Item Charge.
    end;

    local procedure VerifyIntrastatJnlLineAmount(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNo: Code[20]; ExpectedQty: Decimal; ExpectedAmount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            SetRange("Item No.", ItemNo);
            FindFirst();
            Assert.AreEqual(ExpectedQty, Quantity, FieldCaption(Quantity));
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
        end;
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        DummyIntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        DummyIntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.RecordIsNotEmpty(DummyIntrastatJnlLine);
    end;

    local procedure VerifyLastSymbolOfFile(FileName: Text; StatisticsPeriod: Code[10]; FileNo: Integer)
    var
        InFile: File;
        InStream: InStream;
        LastSymbol: Text[1];
        Line: Text;
        LineFeed: Char;
        LineFeedText: Text[1];
    begin
        FileName := FileManagement.CombinePath(FileName, 'Intrastat-%1-' + Format(FileNo) + '.txt');
        FileName := StrSubstNo(FileName, StatisticsPeriod);

        InFile.TextMode(true);
        InFile.Open(FileName);
        InFile.CreateInStream(InStream);
        InStream.Read(Line);
        InFile.Close;

        LineFeed := 10;
        LineFeedText := Format(LineFeed);
        LastSymbol := CopyStr(Line, StrLen(Line));
        Assert.AreNotEqual(LineFeedText, LastSymbol, StrSubstNo(LineSymbolIsLineFeedErr, FileNo));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.SkipNotInvoiced.SetValue(LibraryVariableStorage.DequeueBoolean);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDeclarationRequestPageHandler(var IntrastatMakeDeclaration: TestRequestPage "Intrastat - Make Declaration")
    begin
        IntrastatMakeDeclaration.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke;  // Opens AmountStrMenuHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke;  // Opens AmountStrMenuHandler.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure AmountStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Choice 1 for Equally.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CreateFileMessageHandler(Message: Text)
    begin
        Assert.AreEqual('One or more errors were found. You must resolve all the errors before you can proceed.', Message, '');
    end;
}

