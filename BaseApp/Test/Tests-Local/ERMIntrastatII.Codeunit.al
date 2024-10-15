codeunit 144063 "ERM Intrastat - II"
{
    // // [FEATURE] INTRASTAT.
    //  1. Verify VAT Entry - Document Number on Intrastat Journal Line after posting Purchase Invoice.
    //  2. Verify VAT Entry - Document Number on Intrastat Journal Line after posting Purchase Credit Memo.
    //  3. Verify Intrastat Journal - Get Entries with different Service Tariff No. Invoice in the same period.
    //  4. Verify Intrastat Journal - Get Entries with same Service Tariff No. between Invoice & credit memo in the same period.
    //  5. Verify that Program creates Purchase Entries on Intrastat Journal after posting of Transfer Order as Receipt in location for Country/Region Code=ES.
    //  6. Verify that Program creates Purchase Entries for a Specific Period after posting a Transfer Order with Warehouse location within that Period.
    //  7. Program generates correct Total Amount on Intrastat Journal if post a Sales Invoice with an Item line having Lot No.
    //  8. Verify Report - G/L Book - Print after posting the Purchase Credit Memo document.
    //  9. Verify Report - VAT Register - Print after posting the Purchase Credit Memo document.
    // 10. Verify Report - G/L Book - Print after posting the Sales Credit Memo document.
    // 11. Verify Report - VAT Register - Print after posting the Sales Credit Memo document.
    // 12. Verify Intrastat Journal - GetEntries after posting Purchase Order with VAT posting setup with Deductible percent lower than 100.
    // 13. Verify Intrastat Journal - GetEntries after posting Purchase Invoice with non-sero VAT and Purchase Credit Memo.
    // 14. Verify Intrastat Journal - GetEntries after posting Sales Order with VAT posting setup with Deductible percent lower than 100.
    // 15. Verify Intrastat Journal - GetEntries after posting Sales Invoice with non-sero VAT and Sales Credit Memo.
    // 
    //   Covers Test Cases for WI - 347669.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   PostedPurchaseInvoiceDocumentNoOnIntrastatJnl                                                 205276
    //   PostedPurchaseCreditMemoDocumentNoOnIntrastatJnl                                              333984
    //   PostedSalesInvoiceWithDifferentServiceTariffNo,
    //   PostedSalesInvoiceAndCrMemoWithSameServiceTariffNo                                           343672
    //   TransferOrderWithWarehouseShipment                                                           281781
    //   TransferOrderWithWarehouseShipmentAndPick                                                    276205
    //   SalesInvoiceWithItemChargeAndLotNo                                                           307849
    // 
    //   Covers Test Cases for WI - 349081.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   PostedPurchaseCreditMemoGLBookPrint, PostedPurchaseCreditMemoVATRegisterPrint,
    //   PostedSalesCreditMemoGLBookPrint, PostedSalesCreditMemoVATRegisterPrint                      346156
    // 
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   PostedPurchaseOrderAmountOnIntrastatJnlLowDeductible                                         66801
    //   PostedSalesOrderAmountOnIntrastatJnlLowDeductible                                            66801
    //   PostedPurchaseInvoiceAndCreditMemoAmountOnIntrastatJnl                                       66801
    //   PostedSalesInvoiceAndCreditMemoAmountOnIntrastatJnl                                          66801

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        DescriptionCap: Label 'Descr';
        FinalTotalCap: Label 'Final_TotalCaption';
        FinalTotalTxt: Label 'Final Total';
        FormatTxt: Label '########';
        GLBookEntryCreditAmountCap: Label 'GL_Book_Entry__Credit_Amount_';
        GLBookEntryDocumentTypeCap: Label 'GL_Book_Entry__Document_Type_';
        NameCap: Label 'Name';
        TotalDebitStartDebitCap: Label 'TotalDebit_StartDebit';
        ValueMustEqualMsg: Label 'Value must equal.';
        VATBookEntryBaseCap: Label 'VAT_Book_Entry_Base';
        VATRegisterTypeCap: Label 'VAT_Register_Type';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceDocumentNoOnIntrastatJnl()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify VAT Entry - Document Number on Intrastat Journal Line after posting Purchase Invoice.
        PostedPurchaseDocumentNoOnIntrastatJnl(PurchaseLine."Document Type"::Invoice, false, 1);  // Corrective Entry - False.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoDocumentNoOnIntrastatJnl()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify VAT Entry - Document Number on Intrastat Journal Line after posting Purchase Credit Memo.
        PostedPurchaseDocumentNoOnIntrastatJnl(PurchaseLine."Document Type"::"Credit Memo", false, -1);  // Corrective Entry - False.
    end;

    local procedure PostedPurchaseDocumentNoOnIntrastatJnl(DocumentType: Option; CorrectiveEntry: Boolean; SignMultiplier: Integer)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        IntrastatJnlBatchName: Code[10];
    begin
        Initialize;

        // [GIVEN] Create and Post Purchase Document, Intrastat Journal Batch.
        CreateAndPostPurchaseDocument(
          PurchaseLine, DocumentType, CreateEUVendor,
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Get Entries for Intrastat Journal Batch.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Purchases, true, CorrectiveEntry);

        // [THEN] Intrastat Journal Line has Document Number and Amount from posted document.
        VerifyIntrastatJnlLineDocumentNoAndAmount(
          IntrastatJnlBatchName, PurchaseLine."Service Tariff No.", FindVATEntry(PurchaseLine."Buy-from Vendor No."),
          SignMultiplier * PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithDifferentServiceTariffNo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Intrastat Journal - Get Entries with different Service Tariff No. Invoice in the same period.

        // Setup: Create and Post two Sales Invoice with different Service Tariff Number,Intrastat Journal Batch.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CreateEUCustomer, CreateServiceTariffNumber,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);  // VAT Percentage - 0, Deductible % - 100.
        DocumentNo2 := CreateAndPostSalesDocument(
            SalesLine2, SalesLine2."Document Type"::Invoice, CreateEUCustomer, CreateServiceTariffNumber,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);  // VAT Percentage - 0, Deductible % - 100.

        // Exercise: EU Service - True, Corrective Entry - False and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Sales, true, false);

        // Verify: Verify Intrastat Journal Line - Document Number and Amount.
        VerifyIntrastatJnlLineDocumentNoAndAmount(IntrastatJnlBatchName, SalesLine."Service Tariff No.", DocumentNo, -SalesLine.Amount);
        VerifyIntrastatJnlLineDocumentNoAndAmount(IntrastatJnlBatchName, SalesLine2."Service Tariff No.", DocumentNo2, -SalesLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceAndCrMemoWithSameServiceTariffNo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        DocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Intrastat Journal - Get Entries with same Service Tariff No. between Invoice & credit memo in the same period.

        // Setup: Create and Post Sales Invoice. Create Sales Credit Memo with same Tariff Number apply Entries and Post. Create Intrastat Journal Batch.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CreateEUCustomer, CreateServiceTariffNumber,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);  // VAT Percentage - 0, Deductible % - 100.
        CreateSalesCreditMemoUsingCopyDocument(SalesHeader, SalesLine."Sell-to Customer No.", SalesLine."Service Tariff No.", DocumentNo);
        SalesHeader.CalcFields(Amount);
        Amount := SalesLine.Amount - SalesHeader.Amount;
        ApplyEntriesAndPostSalesCreditMemo(SalesHeader);

        // Exercise: EU Service - True, Corrective Entry - False and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Sales, true, false);

        // Verify: Verify Intrastat Journal Line - Document Number and Amount.
        VerifyIntrastatJnlLineDocumentNoAndAmount(IntrastatJnlBatchName, SalesLine."Service Tariff No.", DocumentNo, -Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithWarehouseShipment()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlBatchName: Code[10];
        LocationCode: Code[10];
    begin
        // Verify that Program creates Purchase Entries on Intrastat Journal after posting of Transfer Order as Receipt in location for Country/Region Code=ES.

        // Setup: Create Warehouse Location, Item. Create and post Item Journal, Warehouse Shipment From Transfer Order, Post Warehouse Shipment and Transfer Order.
        Initialize;
        LocationCode := CreateWarehouseLocation(false);  // Require Receive - False.
        CreateItem(Item);
        CreateItemJournal(ItemJournalLine, Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", LocationCode);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateWarehouseShipmentFromTransferOrder(TransferHeader, LocationCode, Item."No.");
        PostWarehouseShipment(TransferHeader."No.");
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // Exercise: EU Service - False, Corrective Entry - False and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Purchases, false, false);

        // Verify: Verify Intrastat Journal Line - Item Number, Quantity and Amount.
        VerifyIntrastatJnlLineItemNoQuantityAndAmount(IntrastatJnlBatchName, ItemJournalLine."Item No.", ItemJournalLine."Unit Amount");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithWarehouseShipmentAndPick()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
        IntrastatJnlBatchName: Code[10];
        LocationCode: Code[10];
    begin
        // Verify that Program creates Purchase Entries for a Specific Period after posting a Transfer Order with Warehouse location within that Period.

        // Setup:  Create Warehouse Location, Item. Create Warehouse Receipt from Purchase Order. Create Warehouse Shipment from Transfer Order, Post Transfer Header.
        Initialize;
        LocationCode := CreateWarehouseLocation(true);  // Require Receive - True.
        CreateItem(Item);
        Amount := CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationCode);
        PostWarehouseReceiptAndRegisterWarehouseActivity(PurchaseHeader."No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        CreateWarehouseShipmentFromTransferOrder(TransferHeader, LocationCode, Item."No.");
        CreatePickAndPostWarehouseShipment(TransferHeader."No.");
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // Exercise: EU Service - False, Corrective Entry - False and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Purchases, false, false);

        // Verify: Verify Intrastat Journal Line - Item Number, Quantity and Amount.
        VerifyIntrastatJnlLineItemNoQuantityAndAmount(IntrastatJnlBatchName, Item."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ItemTrackingSummaryModalPageHandler,GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithItemChargeAndLotNo()
    var
        ItemJournalLine: Record "Item Journal Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Amount: Decimal;
        DocumentNo: Code[20];
        ItemNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Program generates correct Total Amount on INTRASTAT Journal if post a Sales Invoice with an Item line having Lot No.

        // Setup: Create and Post Item Journal, Create and Post Sales Invoice, Create Intrastat Journal Batch.
        Initialize;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        ItemNo := CreateItemWithTracking(VATBusinessPostingGroup.Code);
        CreateItemJournal(ItemJournalLine, ItemNo, ItemJournalLine."Entry Type"::Purchase, '');  // Blank Location.
        PostItemJournalLineWithItemTracking(ItemJournalLine);
        CreateSalesInvoiceWithItemChargeAssignment(SalesHeader, VATBusinessPostingGroup.Code, ItemNo);
        SalesHeader.CalcFields(Amount);
        Amount := SalesHeader.Amount;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: EU Service - True, Corrective Entry - False and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Sales, true, false);

        // Verify: Verify Intrastat Journal Line - Document Number and Amount.
        VerifyIntrastatJnlLineDocumentNoAndAmount(IntrastatJnlBatchName, SalesHeader."Service Tariff No.", DocumentNo, -Amount);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinalTotalAmountOnPurchaseInvoiceGLBookPrint()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report - G/L Book - Print Final Total Caption and Final Total Amount after Posting Purchase Invoice.

        // Setup.
        Initialize;
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateEUVendor,
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Exercise.
        RunGLBookPrintReport(PurchaseLine."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify Final Total - Caption and Amount on generated XML of Report - G/L Book - Print.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(FinalTotalCap, Format(FinalTotalTxt));
        LibraryReportDataset.AssertElementWithValueExists(TotalDebitStartDebitCap, PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoGLBookPrint()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report - G/L Book - Print after posting the Purchase Credit Memo document.

        // Setup.
        Initialize;
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateEUVendor,
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Exercise.
        RunGLBookPrintReport(PurchaseLine."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify Document Type, Buy from Vendor Number and Amount on generated XML of Report - G/L Book - Print.
        VerifyDocumentTypeNumberAndAmount(
          GLBookEntryDocumentTypeCap, Format(PurchaseLine."Document Type"), DescriptionCap, PurchaseLine."Buy-from Vendor No.",
          GLBookEntryCreditAmountCap, PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemoVATRegisterPrint()
    var
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATRegister: Record "VAT Register";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report - VAT Register - Print after posting the Purchase Credit Memo document.

        // Setup.
        Initialize;
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateEUVendor,
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Exercise.
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // Verify: Verify Document Type, Buy from Vendor Number and Amount on generated XML of Report - VAT Register - Print.
        VerifyDocumentTypeNumberAndAmount(
          VATRegisterTypeCap, Format(VATRegister.Type::Purchase), NameCap, PurchaseLine."Buy-from Vendor No.",
          VATBookEntryBaseCap, -PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoGLBookPrint()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Report - G/L Book - Print after posting the Sales Credit Memo document.

        // Setup.
        Initialize;
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::"Credit Memo", CreateEUCustomer, CreateServiceTariffNumber,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDec(10, 2), 100);  // Random VAT Percentage, Deductible % - 100.

        // Exercise.
        RunGLBookPrintReport(SalesLine."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");

        // Verify: Verify Document Type, Sell To Customer No and Amount on generated XML of Report - G/L Book - Print.
        VerifyDocumentTypeNumberAndAmount(
          GLBookEntryDocumentTypeCap, Format(SalesLine."Document Type"), DescriptionCap, SalesLine."Sell-to Customer No.",
          GLBookEntryCreditAmountCap, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemoVATRegisterPrint()
    var
        SalesLine: Record "Sales Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRegister: Record "VAT Register";
    begin
        // Verify Report - VAT Register - Print after posting the Sales Credit Memo document.

        // Setup.
        Initialize;
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::"Credit Memo", CreateEUCustomer, CreateServiceTariffNumber,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDec(10, 2), 100);  // Random VAT Percentage, Deductible % - 100.

        // Exercise.
        RunVATRegisterPrintReport(VATBookEntry."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // Verify: Verify Document Type, Sell To Customer No and Amount on generated XML of Report - VAT Register - Print.
        VerifyDocumentTypeNumberAndAmount(
          VATRegisterTypeCap, Format(VATRegister.Type::Sale), NameCap, SalesLine."Sell-to Customer No.",
          VATBookEntryBaseCap, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderAmountOnIntrastatJnlLowDeductible()
    var
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Amount in Intrastat Journal Line after posted Purchase Document with non-zero VAT with Deductible percent lower than 100.

        // Setup: Create and Post Purchase Document, Intrastat Journal Batch.
        Initialize;
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateEUVendor, CreateServiceTariffNumber,
          LibraryRandom.RandIntInRange(10, 90), VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: EU Service - True and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Purchases, true, false);

        // Verify: Verify Intrastat Journal Line - Source Entry Number and Amount.
        VerifyIntrastatJnlLineEntryNoAndAmount(
          IntrastatJnlBatchName, PurchaseLine."Service Tariff No.",
          FindVATEntryNo(PurchaseLine."Buy-from Vendor No.", VATEntry.Type::Purchase), PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesOrderAmountOnIntrastatJnlLowDeductible()
    var
        SalesLine: Record "Sales Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Amount in Intrastat Journal Line after posted Sales Document with non-zero VAT with Deductible percent lower than 100.

        // Setup: Create and Post Purchase Document, Intrastat Journal Batch.
        Initialize;
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateEUCustomer,
          CreateServiceTariffNumber, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandIntInRange(10, 90), LibraryRandom.RandIntInRange(10, 90));

        // Exercise: EU Service - True and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Sales, true, false);

        // Verify: Verify Intrastat Journal Line - Document Number and Amount.
        VerifyIntrastatJnlLineEntryNoAndAmount(
          IntrastatJnlBatchName, SalesLine."Service Tariff No.",
          FindVATEntryNo(SalesLine."Sell-to Customer No.", VATEntry.Type::Sale), -SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceAndCreditMemoAmountOnIntrastatJnl()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IntrastatJnlBatchName: Code[10];
        VendorNo: Code[20];
        PurchaseHeaderNo: Code[20];
        ServiceTariffNo: Code[10];
        AmountToValidate: Decimal;
    begin
        // Post Purchase Invoice and Apply Credit Memo with half Amount, then check that Amount in Intrastat Journal equals to rest Amount.

        // Setup: Create and Post Purchase Invoice, then create Credit memo and apply it, then create entries in Intrastat Journal.
        Initialize;
        VendorNo := CreateEUVendor;
        ServiceTariffNo := CreateServiceTariffNumber;
        PurchaseHeaderNo := CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Invoice, VendorNo, ServiceTariffNo,
            100, VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Deductible % - 100
        AmountToValidate := PurchaseLine.Amount;
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::"Credit Memo",
          VendorNo, ServiceTariffNo, 100, VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Deductible % - 100
        with PurchaseLine do begin
            Validate(Quantity, 1);
            Validate("Direct Unit Cost", AmountToValidate / 2);
            Modify;
        end;
        AmountToValidate -= PurchaseLine.Amount;
        with PurchaseHeader do begin
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", PurchaseHeaderNo);
            Modify;
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: EU Service - True and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Purchases, true, false);

        // Verify: Verify Intrastat Journal Line - Source Entry Number and Amount.
        VerifyIntrastatJnlLineEntryNoAndAmount(
          IntrastatJnlBatchName, ServiceTariffNo,
          FindVATEntryNo(PurchaseLine."Buy-from Vendor No.", VATEntry.Type::Purchase), AmountToValidate);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceAndCreditMemoAmountOnIntrastatJnl()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        IntrastatJnlBatchName: Code[10];
        CustomerNo: Code[20];
        SalesHeaderNo: Code[20];
        ServiceTariffNo: Code[10];
        AmountToValidate: Decimal;
        VATPercent: Decimal;
    begin
        // Post Sales Invoice and Apply Credit Memo with half Amount, then check that Amount in Intrastat Journal equals to rest Amount.

        // Setup: Create and Post Purchase Invoice, then create Credit memo and apply it, then create entries in Intrastat Journal.
        Initialize;
        CustomerNo := CreateEUCustomer;
        ServiceTariffNo := CreateServiceTariffNumber;
        VATPercent := LibraryRandom.RandIntInRange(10, 90);
        SalesHeaderNo := CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, ServiceTariffNo,
            VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercent, 100); // Deductible % - 100
        AmountToValidate := SalesLine.Amount;
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesLine."Document Type"::"Credit Memo", CustomerNo,
          ServiceTariffNo, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercent, 100); // Deductible % - 100
        with SalesLine do begin
            Validate(Quantity, 1);
            Validate("Unit Price", AmountToValidate / 2);
            Modify;
        end;
        AmountToValidate -= SalesLine.Amount;
        with SalesHeader do begin
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", SalesHeaderNo);
            Modify;
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: EU Service - True and Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(IntrastatJnlBatch.Type::Sales, true, false);

        // Verify: Verify Intrastat Journal Line - Source Entry Number and Amount.
        VerifyIntrastatJnlLineEntryNoAndAmount(
          IntrastatJnlBatchName, ServiceTariffNo,
          FindVATEntryNo(SalesLine."Sell-to Customer No.", VATEntry.Type::Sale), -AmountToValidate);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentVendForVendVATRegisterPrint()
    var
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxRepVendorVATRegNo: Text[20];
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 378554] Vendor's tax representative vendor VAT Registration No. is printed in VAT Fiscal Register report
        Initialize;

        // [GIVEN] Vendor "Vend1" with VAT Registration No. "VATRegNo1"
        // [GIVEN] Vendor "Vend2" with VAT Registration No. "VATRegNo2"
        // [GIVEN] Vendor "Vend2" specified as Tax Representative for vendor "Vend1"
        // [GIVEN] Posted Purchase Invoice for Vendor "Vend1"
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendorWithTaxRepresentVendor(TaxRepVendorVATRegNo),
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. "VATRegNo2" of tax representative vendor "Vend2" printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseLine."Buy-from Vendor No.", TaxRepVendorVATRegNo);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentVendEmptyForVendVATRegisterPrint()
    var
        RefVendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 378554] Empty VAT Registration No. is printed in VAT Fiscal Register report if Tax Representative No. not defined for Vendor with "Tax Representative Type" = Vendor
        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, Tax Representative Type = Vendor, but Tax Representative No. is not defined
        // [GIVEN] Posted Purchase Invoice for Vendor
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice,
          CreateVendorWithTaxRepresentative(RefVendor."Tax Representative Type"::Vendor, ''),
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] Empty VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseLine."Buy-from Vendor No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentContForVendVATRegisterPrint()
    var
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxRepContactVATRegNo: Text[20];
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 378554] Vendor's tax representative contact VAT Registration No. is printed in VAT Fiscal Register report
        Initialize;

        // [GIVEN] Vendor with VAT Registration No. "VATRegNo1"
        // [GIVEN] Contact with VAT Registration No. "VATRegNo2"
        // [GIVEN] Contact specified as Tax Representative for Vendor
        // [GIVEN] Posted Purchase Invoice for Vendor
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendorWithTaxRepresentVendor(TaxRepContactVATRegNo),
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. "VATRegNo2" of tax representative Contact printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseLine."Buy-from Vendor No.", TaxRepContactVATRegNo);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentContEmptyForVendVATRegisterPrint()
    var
        RefVendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 378554] Empty VAT Registration No. is printed in VAT Fiscal Register report if Tax Representative No. not defined for Vendor with "Tax Representative Type" = Contact
        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, Tax Representative Type = Contact, but Tax Representative No. is not defined
        // [GIVEN] Posted Purchase Invoice for Vendor
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice,
          CreateVendorWithTaxRepresentative(RefVendor."Tax Representative Type"::Contact, ''),
          CreateServiceTariffNumber, 100, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] Empty VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseLine."Buy-from Vendor No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentCustForCustVATRegisterPrint()
    var
        SalesLine: Record "Sales Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxRepCustomerVATRegNo: Text[20];
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 378554] Customer's tax representative customer VAT Registration No. is printed in VAT Fiscal Register report
        Initialize;

        // [GIVEN] Customer "Cust1" with VAT Registration No. "VATRegNo1"
        // [GIVEN] Customer "Cust2" with VAT Registration No. "VATRegNo2"
        // [GIVEN] Customer "Cust2" specified as Tax Representative for customer "Cust1"
        // [GIVEN] Posted Sales Invoice for customer "Cust1"
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, CreateCustomerWithTaxRepresentCustomer(TaxRepCustomerVATRegNo),
          CreateServiceTariffNumber, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesLine."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. "VATRegNo2" of tax representative customer "Cust1" printed in report
        VerifyCounterpartyVATRegistrationNo(SalesLine."Sell-to Customer No.", TaxRepCustomerVATRegNo);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentCustEmptyForCustVATRegisterPrint()
    var
        RefCustomer: Record Customer;
        SalesLine: Record "Sales Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 378554] Empty VAT Registration No. is printed in VAT Fiscal Register report if Tax Representative No. not defined for Customer with "Tax Representative Type" = Customer
        Initialize;

        // [GIVEN] Customer marked as Non-Resident, Tax Representative Type = Customer, but Tax Representative No. is not defined
        // [GIVEN] Posted Sales Invoice for Customer
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice,
          CreateCustomerWithTaxRepresentative(RefCustomer."Tax Representative Type"::Customer, ''),
          CreateServiceTariffNumber, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesLine."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] Empty VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(SalesLine."Sell-to Customer No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentContForCustVATRegisterPrint()
    var
        SalesLine: Record "Sales Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxRepContactVATRegNo: Text[20];
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 378554] Customer's tax representative contact VAT Registration No. is printed in VAT Fiscal Register report for Customer with "Tax Representative Type" = Contact
        Initialize;

        // [GIVEN] Customer with VAT Registration No. "VATRegNo1"
        // [GIVEN] Contact with VAT Registration No. "VATRegNo2"
        // [GIVEN] Contact specified as Tax Representative for Customer
        // [GIVEN] Posted Sales Invoice for Customer
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, CreateCustomerWithTaxRepresentContact(TaxRepContactVATRegNo),
          CreateServiceTariffNumber, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesLine."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. "VATRegNo2" of tax representative Contact printed in report
        VerifyCounterpartyVATRegistrationNo(SalesLine."Sell-to Customer No.", TaxRepContactVATRegNo);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentContEmptyForCustVATRegisterPrint()
    var
        RefCustomer: Record Customer;
        SalesLine: Record "Sales Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 378554] Empty VAT Registration No. is printed in VAT Fiscal Register report if Tax Representative No. not defined for Customer with "Tax Representative Type" = Contact
        Initialize;

        // [GIVEN] Customer marked as Non-Resident, Tax Representative Type = Contact, but Tax Representative No. is not defined
        // [GIVEN] Posted Sales Invoice for Customer
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice,
          CreateCustomerWithTaxRepresentative(RefCustomer."Tax Representative Type"::Contact, ''),
          CreateServiceTariffNumber, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, 100);

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesLine."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] Empty VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(SalesLine."Sell-to Customer No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrencyAmountInSalesVATBookForPurchInvWithReverseChargeAndFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBookEntry: Record "VAT Book Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Currency]
        // [SCENARIO 381905] The "Currency Amount" of "VAT Fiscal Register" report is positive when post Purchase Invoice with "Reverse Charge VAT" and Currency

        Initialize;

        // [GIVEN] Posted Purchase Invoice with "Operation Type" with "Reverse Sales VAT No. Series", "Reverse Charge VAT", FCY Amount = "X" and
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendorWithCurrency,
          CreateServiceTariffNumber, 0, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PurchaseHeader.Validate("Operation Type", FindOperationTypeWithReverseVATEntryNo);
        PurchaseHeader.Modify(true);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Sales VAT Book Entry generated for Posted Purchase Invoice with Amount "X"
        FindReverseEntryVATBookEntry(
          VATBookEntry, VATBookEntry.Type::Sale, VATBookEntry."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.");

        // [WHEN] Print VAT Fiscal Register report against Sales VAT Book Entry
        RunVATRegisterPrintReportWithSpecificVATBookEntry(VATBookEntry);

        // [THEN] "Currency Amount" is "X" in printed report "VAT Fiscal Register"
        // The Amount in Vendor Ledger Entry is negative but final result should be positive
        VerifyLedgerAmount(PurchaseLine."Buy-from Vendor No.", -GetVendLedgEntryAmount(PurchaseLine."Buy-from Vendor No.", InvNo));
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentVendBlankInVendFilledInDocVATRegisterPrint()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Vendor is printed in VAT Fiscal Register report if Tax Representative No. defined in Purchase Header

        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Vendor, "Tax Representative No." = new vendor with "VAT Registration No." = 123456
        CreateVendorWithVATRegistrationNumber(Vendor);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, 0, '', PurchaseHeader."Tax Representative Type"::Vendor, Vendor."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", Vendor."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentVendFromDocHasHigherPriorityThanFromCardVATRegisterPrint()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Tax Representative with type "Vendor" from Purchase Header has higher priority than from Vendor Card when print VAT Fiscal Register report

        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, "Tax Representative Type" = Vendor, "Tax Representative No." = Vendor "X"
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Vendor, "Tax Representative No." = Vendor "Y" with "VAT Registration No." = 123456
        CreateVendorWithVATRegistrationNumber(Vendor);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, Vendor."Tax Representative Type"::Vendor, LibraryPurchase.CreateVendorNo,
          PurchaseHeader."Tax Representative Type"::Vendor, Vendor."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", Vendor."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlankVATRegNoWhenRunVATRegisterPrintWithTaxRepresentativeReferToDeletedVendor()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] Blank VAT Registration No. is printed in VAT Fiscal Register report when Tax Representative No. refer to deleted vendor

        Initialize;

        // [GIVEN] Vendor "X" marked as Non-Resident, "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Vendor, "Tax Representative No." = Vendor "Y" with "VAT Registration No." = 123456
        CreateVendorWithVATRegistrationNumber(Vendor);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, 0, '', PurchaseHeader."Tax Representative Type"::Vendor, Vendor."No.");

        // [GIVEN] Vendor "Y" removed
        Vendor.Delete();
        Commit();

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] Blank VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchTaxRepresentContactBlankInContactFilledInDocVATRegisterPrint()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Contact is printed in VAT Fiscal Register report if Tax Representative No. defined in Purchase Header

        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact with "VAT Registration No." = 123456
        CreateContactWithVATRegistrationNumber(Contact);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, 0, '', PurchaseHeader."Tax Representative Type"::Contact, Contact."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", Contact."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchTaxRepresentContactFromDocHasHigherPriorityThanFromCardVATRegisterPrint()
    var
        Vendor: Record Vendor;
        VendorContact: Record Contact;
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Tax Representative with Type "Contact" from Purchase Header has higher priority than from Contact Card when print VAT Fiscal Register report

        Initialize;

        // [GIVEN] Vendor marked as Non-Resident, "Tax Representative Type" = Contact, "Tax Representative No." = Contact "X"
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact "Y" with "VAT Registration No." = 123456
        LibraryMarketing.CreateCompanyContact(VendorContact);
        CreateContactWithVATRegistrationNumber(Contact);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, Vendor."Tax Representative Type"::Contact, VendorContact."No.",
          PurchaseHeader."Tax Representative Type"::Contact, Contact."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", Contact."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchBlankVATRegNoWhenRunVATRegisterPrintWithTaxRepresentativeReferToDeletedContact()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Purchase] [Tax Representative]
        // [SCENARIO 255750] Blank VAT Registration No. is printed in VAT Fiscal Register report when Tax Representative No. refer to deleted contact

        Initialize;

        // [GIVEN] Vendor "X" marked as Non-Resident, "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Purchase Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact with "VAT Registration No." = 123456
        CreateContactWithVATRegistrationNumber(Contact);
        CreatePurchInvWithTaxRepresentative(
          PurchaseHeader, 0, '', PurchaseHeader."Tax Representative Type"::Contact, Contact."No.");

        // [GIVEN] Contact  removed
        Contact.Delete();
        Commit();

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Purchase Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.", VATBookEntry.Type::Purchase);

        // [THEN] Blank VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(PurchaseHeader."Buy-from Vendor No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentCustBlankInVendFilledInDocVATRegisterPrint()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Vendor is printed in VAT Fiscal Register report if Tax Representative No. defined in Sales Header

        Initialize;

        // [GIVEN] Customer with "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Customer, "Tax Representative No." = new customer with "VAT Registration No." = 123456
        CreateCustomerWithVATRegistrationNumber(Customer);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, 0, '', SalesHeader."Tax Representative Type"::Customer, Customer."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxRepresentCustFromDocHasHigherPriorityThanFromCardVATRegisterPrint()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Tax Representative with type "Customer" from Sales Header has higher priority than from Customer Card when print VAT Fiscal Register report

        Initialize;

        // [GIVEN] Customer with "Tax Representative Type" = Customer, "Tax Representative No." = Customer "X"
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Customer, "Tax Representative No." = Customer "Y" with "VAT Registration No." = 123456
        CreateCustomerWithVATRegistrationNumber(Customer);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, Customer."Tax Representative Type"::Customer, LibrarySales.CreateCustomerNo,
          SalesHeader."Tax Representative Type"::Customer, Customer."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlankVATRegNoWhenRunVATRegisterPrintWithTaxRepresentativeReferToDeletedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] Blank VAT Registration No. is printed in VAT Fiscal Register report when Tax Representative No. refer to deleted customer

        Initialize;

        // [GIVEN] Customer with Non-Resident, "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Customer, "Tax Representative No." = Customer "Y" with "VAT Registration No." = 123456
        CreateCustomerWithVATRegistrationNumber(Customer);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, 0, '', SalesHeader."Tax Representative Type"::Customer, Customer."No.");

        // [GIVEN] Customer "Y" removed
        Customer.Delete();
        Commit();

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] Blank VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxRepresentContactBlankInContactFilledInDocVATRegisterPrint()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Contact is printed in VAT Fiscal Register report if Tax Representative No. defined in Sales Header

        Initialize;

        // [GIVEN] Customer with "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact with "VAT Registration No." = 123456
        CreateContactWithVATRegistrationNumber(Contact);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, 0, '', SalesHeader."Tax Representative Type"::Contact, Contact."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", Contact."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxRepresentContactFromDocHasHigherPriorityThanFromCardVATRegisterPrint()
    var
        Customer: Record Customer;
        CustomerContact: Record Contact;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] VAT Registration No. of Tax Representative with Type "Contact" from Sales Header has higher priority than from Contact Card when print VAT Fiscal Register report

        Initialize;

        // [GIVEN] Customer with "Tax Representative Type" = Contact, "Tax Representative No." = Contact "X"
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact "Y" with "VAT Registration No." = 123456
        LibraryMarketing.CreateCompanyContact(CustomerContact);
        CreateContactWithVATRegistrationNumber(Contact);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, Customer."Tax Representative Type"::Contact, CustomerContact."No.",
          SalesHeader."Tax Representative Type"::Contact, Contact."No.");

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] VAT Registration No. printed in report is 123456
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", Contact."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlankVATRegNoWhenRunVATRegisterPrintWithTaxRepresentativeReferToDeletedContact()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [FEATURE] [Sales] [Tax Representative]
        // [SCENARIO 255750] Blank sales VAT Registration No. is printed in VAT Fiscal Register report when Tax Representative No. refer to deleted contact

        Initialize;

        // [GIVEN] Customer with "Tax Representative Type" and "Tax Representative No." are not defined
        // [GIVEN] Posted Sales Invoice with "Tax Representative Type" = Contact, "Tax Representative No." = Contact with "VAT Registration No." = 123456
        CreateContactWithVATRegistrationNumber(Contact);
        CreateSalesInvWithTaxRepresentative(
          SalesHeader, 0, '', SalesHeader."Tax Representative Type"::Contact, Contact."No.");

        // [GIVEN] Contact  removed
        Contact.Delete();
        Commit();

        // [WHEN] Print VAT Fiscal Register report on Posting Date of Sales Invoice
        RunVATRegisterPrintReport(
          VATBookEntry."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", VATBookEntry.Type::Sale);

        // [THEN] Blank VAT Registration No. printed in report
        VerifyCounterpartyVATRegistrationNo(SalesHeader."Sell-to Customer No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLBookPrintReportNoFollowingLineDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 393654] GL Book report should not copy last line description for next lines that should not have such description
        Initialize;

        // [GIVEN] Posted Sales Document for Customer "C" and Payment Method with Bill Code
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", CreateServiceTariffNumber, 100,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", 100);
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod);
        SalesHeader.Modify(True);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Issued Bank Receipt
        RunIssueBankReceipt(SalesLine."Sell-to Customer No.");
        Commit;

        // [WHEN] Run Report G/L Book Print for Customer "C"
        RunGLBookPrintReportForSourceNo(SalesLine."Sell-to Customer No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Last line for Sales Invoice should have Description = Customer.Name
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.AssertCurrentRowValueEquals(DescriptionCap, Customer.Name);

        // [THEN] Following lines for Bank receipt should have no description
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DescriptionCap, '');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DescriptionCap, '');
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryVariableStorage.Clear;
        IntrastatJnlTemplate.DeleteAll();
        ResetNoSeriesLastUsedDate;
    end;

    local procedure ApplyEntriesAndPostSalesCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.ApplyEntries.Invoke;  // Opens handler - ApplyCustomerEntriesModalPageHandler.
        SalesCreditMemo.Close;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; ServiceTariffNo: Code[10]; DeductiblePercent: Decimal; VATCalcType: Option): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, DocumentType, VendorNo, ServiceTariffNo, DeductiblePercent, VATCalcType);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; ServiceTariffNo: Code[10]; DeductiblePercent: Integer; VATCalcType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPercent: Decimal;
    begin
        VATPercent := LibraryRandom.RandIntInRange(5, 20);
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, ServiceTariffNo);
        CreateVATPostingSetup(
          VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATCalcType, VATPercent, false);
        VATPostingSetup.Validate("Deductible %", DeductiblePercent);
        VATPostingSetup.Modify();
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, CreateItemWithVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), '');  // Blank Location.
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; ServiceTariffNo: Code[10]; DeductiblePercent: Integer; VATCalcType: Option; VATPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, ServiceTariffNo);
        CreateVATPostingSetup(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group",
          VATCalcType, VATPercent, true);
        VATPostingSetup.Validate("Deductible %", DeductiblePercent);
        VATPostingSetup.Modify();
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; SellToCustomerNo: Code[20]; ServiceTariffNo: Code[10]; VATCalculationType: Option; VATPct: Decimal; DeductiblePercent: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType, SellToCustomerNo, ServiceTariffNo, DeductiblePercent,
          VATCalculationType, VATPct);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesCreditMemoUsingCopyDocument(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; ServiceTariffNo: Code[10]; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SellToCustomerNo, ServiceTariffNo);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", DocumentNo);
        SalesHeader.Modify(true);
        LibrarySales.CopySalesDocument(SalesHeader, DocumentType::"Posted Invoice", DocumentNo, false, true);  // Include Header - False and Recalculate Lines - True.
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithItemChargeAssignment(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; ItemNo: Code[20])
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemTrackingMode: Option "Assign Lot No.","Select Entries";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateEUCustomer, CreateServiceTariffNumber);
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        SalesLine.OpenItemTrackingLines;  // Opens handler - ItemTrackingLinesModalPageHandler.
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", ItemCharge."VAT Prod. Posting Group");
        VATPostingSetup."EU Service" := true;
        VATPostingSetup.Modify();
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::"Charge (Item)", ItemCharge."No.");
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine2, SalesLine2."Document Type",
          SalesLine2."Document No.", SalesLine2."Line No.", ItemCharge."No.");
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomerWithTaxRepresentCustomer(var TaxRepresentCustVATRegNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
        TaxRepresentCustomer: Record Customer;
    begin
        LibrarySales.CreateCustomer(TaxRepresentCustomer);
        TaxRepresentCustomer.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        TaxRepresentCustomer.Modify();
        TaxRepresentCustVATRegNo := TaxRepresentCustomer."VAT Registration No.";

        exit(CreateCustomerWithTaxRepresentative(Customer."Tax Representative Type"::Customer, TaxRepresentCustomer."No."));
    end;

    local procedure CreateCustomerWithTaxRepresentContact(var TaxRepresentContVATRegNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
        TaxRepresentContact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(TaxRepresentContact);
        TaxRepresentContact.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        TaxRepresentContact.Modify();
        TaxRepresentContVATRegNo := TaxRepresentContact."VAT Registration No.";
        exit(CreateCustomerWithTaxRepresentative(Customer."Tax Representative Type"::Contact, TaxRepresentContact."No."));
    end;

    local procedure CreateCustomerWithTaxRepresentative(TaxRepresentativeType: Integer; TaxRepresentativeNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
            Validate(Resident, Resident::"Non-Resident");
            Validate("Tax Representative Type", TaxRepresentativeType);
            Validate("Tax Representative No.", TaxRepresentativeNo);
            Modify;
            exit("No.");
        end;
    end;

    local procedure CreateEUCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CreateVATRegistrationNoFormat);
        Customer.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateEUVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateVATRegistrationNoFormat);
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateIntrastatJournalBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Type: Option; EUService: Boolean; CorrectiveEntry: Boolean)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate(Type, Type);
        IntrastatJnlBatch.Validate(Periodicity, IntrastatJnlBatch.Periodicity::Month);
        IntrastatJnlBatch.Validate("EU Service", EUService);
        IntrastatJnlBatch.Validate("Corrective Entry", CorrectiveEntry);
        IntrastatJnlBatch.Validate("Statistics Period", Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod));
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemJournal(var ItemJournalLine: Record "Item Journal Line"; No: Code[20]; EntryType: Option; LocationCode: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.DeleteAll();
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, No, LibraryRandom.RandIntInRange(10, 20));  // Random - Quantity.
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithTracking(VATBusPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, false);  // VAT Percent - 0.
        CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibraryItemTracking.AddLotNoTrackingInfo(Item);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVATProductPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        Location: Record Location;
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>%1', '');
        CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
        LibraryERM.FindCountryRegion(CountryRegion);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Country/Region Code", CountryRegion.Code);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreatePickAndPostWarehouseShipment(SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, WarehouseActivityLine."Source Document"::"Outbound Transfer", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; VendorNo: Code[20]; ServiceTariffNo: Code[10])
    var
        PaymentMethod: Record "Payment Method";
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.FindFirst;
        LibraryERM.FindPaymentMethod(PaymentMethod);
        // LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Transport Method", TransportMethod.Code);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 50, 2));  // Random - Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchInvWithTaxRepresentative(var PurchaseHeader: Record "Purchase Header"; VendorTaxReprType: Option; VendorTaxReprNo: Code[20]; DocTaxReprType: Option; DocTaxReprNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Invoice,
          CreateVendorWithTaxRepresentative(VendorTaxReprType, VendorTaxReprNo),
          CreateServiceTariffNumber, 0, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PurchaseHeader.Validate("Tax Representative Type", DocTaxReprType);
        PurchaseHeader.Validate("Tax Representative No.", DocTaxReprNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesInvWithTaxRepresentative(var SalesHeader: Record "Sales Header"; CustTaxReprType: Option; CustTaxReprNo: Code[20]; DocTaxReprType: Option; DocTaxReprNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesLine."Document Type"::Invoice, CreateCustomerWithTaxRepresentative(CustTaxReprType, CustTaxReprNo),
          CreateServiceTariffNumber, 0, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 100);
        SalesHeader.Validate("Tax Representative Type", DocTaxReprType);
        SalesHeader.Validate("Tax Representative No.", DocTaxReprNo);
        SalesHeader.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option; SellToCustomerNo: Code[20]; ServiceTariffNo: Code[10])
    var
        TransportMethod: Record "Transport Method";
        PaymentMethod: Record "Payment Method";
        NoSeries: Record "No. Series";
    begin
        TransportMethod.FindFirst;
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.Validate("Operation Type", LibraryERM.FindOperationType(NoSeries."No. Series Type"::Sales));
        SalesHeader.Validate("Transport Method", TransportMethod.Code);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Validate("Service Tariff No.", ServiceTariffNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Option; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, LibraryRandom.RandInt(10));  // Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceTariffNumber(): Code[10]
    var
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        exit(ServiceTariffNumber."No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATCalculationType: Option; VATPct: Decimal; IsSales: Boolean)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATIdentifier: Record "VAT Identifier";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATIdentifier(VATIdentifier);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Validate("VAT %", VATPct);
        if IsSales then
            VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.")
        else
            VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATRegistrationNoFormat(): Code[10]
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion);
        VATRegistrationNoFormat.Validate(Format, CopyStr(LibraryUtility.GenerateGUID, 1, 2) + FormatTxt);
        VATRegistrationNoFormat.Modify(true);
        exit(VATRegistrationNoFormat."Country/Region Code");
    end;

    local procedure CreateVendorWithTaxRepresentVendor(var TaxRepresentVendVATRegNo: Text[20]): Code[20]
    var
        RefVendor: Record Vendor;
        TaxRepresentVendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(TaxRepresentVendor);
        TaxRepresentVendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        TaxRepresentVendor.Modify();
        TaxRepresentVendVATRegNo := TaxRepresentVendor."VAT Registration No.";

        exit(CreateVendorWithTaxRepresentative(RefVendor."Tax Representative Type"::Vendor, TaxRepresentVendor."No."));
    end;

    local procedure CreateVendorWithTaxRepresentative(TaxRepresentativeType: Integer; TaxRepresentativeNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
            Validate(Resident, Resident::"Non-Resident");
            Validate("Tax Representative Type", TaxRepresentativeType);
            Validate("Tax Representative No.", TaxRepresentativeNo);
            Modify;
            exit("No.");
        end;
    end;

    local procedure CreateVendorWithCurrency(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithVATRegistrationNumber(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithVATRegistrationNumber(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Customer.Modify(true);
    end;

    local procedure CreateContactWithVATRegistrationNumber(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Contact.Modify(true);
    end;

    local procedure CreateWarehouseLocation(RequireReceive: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Pick According to FEFO", RequireReceive);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", RequireReceive);
        Location.Validate("Require Pick", RequireReceive);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        exit(Location.Code)
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        exit(PurchaseLine."Direct Unit Cost");
    end;

    local procedure CreateWarehouseShipmentFromTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ItemNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation, CreateLocation, Location.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure FindIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; DocumentNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure FindIntrastatJournalLineByEntryTypeAndNo(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; EntryType: Option; EntryNo: Integer)
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Source Type", EntryType);
        IntrastatJnlLine.SetRange("Source Entry No.", EntryNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst;
    end;

    local procedure FindVATEntry(BillToPayToNo: Code[20]): Code[20]
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.SetRange("Reverse Sales VAT", true);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.FindFirst;
        exit(VATEntry."Document No.")
    end;

    local procedure FindVATEntryNo(BillToPayToNo: Code[20]; VATEntryType: Option): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.SetRange("Reverse Sales VAT", false);
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.FindFirst;
        exit(VATEntry."Entry No.")
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceDocument: Option; SourceNo: Code[20]; ActivityType: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst;
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindReverseEntryVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; Type: Option; DocType: Option; VendNo: Code[20])
    begin
        VATBookEntry.SetRange("Document Type", DocType);
        VATBookEntry.SetRange("Sell-to/Buy-from No.", VendNo);
        VATBookEntry.SetRange(Type, Type);
        VATBookEntry.SetRange("Reverse VAT Entry", true);
        VATBookEntry.FindFirst;
    end;

    local procedure FindOperationTypeWithReverseVATEntryNo(): Code[10]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange("No. Series Type", NoSeries."No. Series Type"::Purchase);
        NoSeries.SetRange("Reverse Sales VAT No. Series", LibraryERM.FindOperationType(NoSeries."No. Series Type"::Sales));
        NoSeries.FindFirst;
        exit(NoSeries.Code);
    end;

    local procedure GetEntriesIntrastatJournal(Type: Option; EUService: Boolean; CorrectiveEntry: Boolean): Code[10]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        CreateIntrastatJournalBatch(IntrastatJnlBatch, Type, EUService, CorrectiveEntry);
        Commit();  // Commit required.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.GetEntries.Invoke;  // Opens handler - GetItemLedgerEntriesRequestPageHandler.
        IntrastatJournal.Close;
        exit(IntrastatJnlBatch.Name);
    end;

    local procedure GetVendLedgEntryAmount(VendNo: Code[20]; DocNo: Code[20]): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindFirst;
        VendLedgEntry.CalcFields(Amount);
        exit(VendLedgEntry.Amount);
    end;

    local procedure PostItemJournalLineWithItemTracking(ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournal: TestPage "Item Journal";
        ItemTrackingMode: Option "Assign Lot No.","Select Entries";
    begin
        ItemJournal.OpenEdit;
        ItemJournal.FILTER.SetFilter("Item No.", ItemJournalLine."Item No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        ItemJournal.ItemTrackingLines.Invoke;  // Opens handler - ItemTrackingLinesModalPageHandler.
        ItemJournal.Close;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostWarehouseReceiptAndRegisterWarehouseActivity(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst;
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostWarehouseShipment(SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure ResetNoSeriesLastUsedDate()
    var
        NoSeries: Record "No. Series";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        NoSeries.SetRange("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.FindFirst;
        NoSeriesLineSales.SetRange("Series Code", NoSeries.Code);
        NoSeriesLineSales.ModifyAll("Last Date Used", NoSeriesLineSales."Starting Date");

        NoSeries.SetRange("No. Series Type", NoSeries."No. Series Type"::Purchase);
        NoSeries.FindFirst;
        NoSeriesLinePurchase.SetRange("Series Code", NoSeries.Code);
        NoSeriesLinePurchase.ModifyAll("Last Date Used", NoSeriesLinePurchase."Starting Date");
    end;

    local procedure RunGLBookPrintReport(DocumentType: Option; SourceNo: Code[20])
    var
        GLBookEntry: Record "GL Book Entry";
        GLBookPrint: Report "G/L Book - Print";
    begin
        GLBookEntry.SetRange("Document Type", DocumentType);
        GLBookEntry.SetRange("Source No.", SourceNo);
        GLBookPrint.SetTableView(GLBookEntry);
        GLBookPrint.Run;
    end;

    local procedure RunVATRegisterPrintReport(DocumentType: Option; SellToBuyFromNo: Code[20]; Type: Option)
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        VATBookEntry.SetRange("Document Type", DocumentType);
        VATBookEntry.SetRange("Sell-to/Buy-from No.", SellToBuyFromNo);
        VATBookEntry.SetRange(Type, Type);
        VATBookEntry.FindFirst;
        RunVATRegisterPrintReportWithSpecificVATBookEntry(VATBookEntry);
    end;

    local procedure RunGLBookPrintReportForSourceNo(SourceNo: Code[20])
    var
        GLBookEntry: Record "GL Book Entry";
        GLBookPrint: Report "G/L Book - Print";
    begin
        GLBookEntry.SetRange("Source No.", SourceNo);
        GLBookPrint.SetTableView(GLBookEntry);
        GLBookPrint.Run;
    end;

    local procedure RunVATRegisterPrintReportWithSpecificVATBookEntry(var VATBookEntry: Record "VAT Book Entry")
    var
        NoSeries: Record "No. Series";
        VATRegisterPrint: Report "VAT Register - Print";
    begin
        VATBookEntry.CalcFields("No. Series");
        NoSeries.Get(VATBookEntry."No. Series");
        LibraryVariableStorage.Enqueue(NoSeries."VAT Register");
        Clear(VATRegisterPrint);
        VATRegisterPrint.SetTableView(VATBookEntry);
        VATRegisterPrint.Run;
    end;

    local procedure VerifyDocumentTypeNumberAndAmount(DocumentTypeCap: Text[50]; DocumentType: Text[50]; DescriptionCap: Text[50]; DescriptionNo: Code[20]; AmountCap: Text[50]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(DocumentTypeCap, DocumentType);
        LibraryReportDataset.AssertElementWithValueExists(DescriptionCap, DescriptionNo);
        LibraryReportDataset.AssertElementWithValueExists(AmountCap, Amount);
    end;

    local procedure VerifyIntrastatJnlLineItemNoQuantityAndAmount(JournalBatchName: Code[10]; ItemNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Item No.", ItemNo);
        TransferReceiptLine.FindFirst;
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, TransferReceiptLine."Document No.");
        IntrastatJnlLine.TestField("Item No.", ItemNo);
        IntrastatJnlLine.TestField(Quantity, TransferReceiptLine.Quantity);
        Assert.AreNearlyEqual(
          IntrastatJnlLine.Amount, TransferReceiptLine.Quantity * Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustEqualMsg);
    end;

    local procedure VerifyIntrastatJnlLineDocumentNoAndAmount(JournalBatchName: Code[10]; ServiceTariffNo: Code[10]; DocumentNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Service Tariff No.", ServiceTariffNo);
        IntrastatJnlLine.TestField(Amount, Amount);
    end;

    local procedure VerifyIntrastatJnlLineEntryNoAndAmount(JournalBatchName: Code[10]; ServiceTariffNo: Code[10]; EntryNo: Integer; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLineByEntryTypeAndNo(IntrastatJnlLine, JournalBatchName, IntrastatJnlLine."Source Type"::"VAT Entry", EntryNo);
        IntrastatJnlLine.TestField("Service Tariff No.", ServiceTariffNo);
        IntrastatJnlLine.TestField(Amount, Amount);
    end;

    local procedure VerifyCounterpartyVATRegistrationNo(AccountNo: Code[20]; ExpectedVATRegNo: Text[20])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(NameCap, AccountNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATReg', ExpectedVATRegNo);
    end;

    local procedure VerifyLedgerAmount(VendNo: Code[20]; ExpectedAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(NameCap, VendNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('LedgAmount', ExpectedAmount);
    end;

    local procedure RunIssueBankReceipt(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuingCustomerBill: Report "Issuing Customer Bill";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        IssuingCustomerBill.SetTableView(CustLedgerEntry);
        IssuingCustomerBill.SetPostingDescription(CustomerNo);
        IssuingCustomerBill.UseRequestPage(false);
        IssuingCustomerBill.Run;
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", CreateBill);
        PaymentMethod.Modify(true);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, LibraryERM.CreateBankAccountNo, PaymentMethod.Code);
        exit(PaymentMethod.Code);
    end;

    local procedure CreateBill(): Code[20]
    var
        Bill: Record Bill;
        SourceCode: Record "Source Code";
    begin
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Allow Issue", true);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", LibraryErm.CreateGLAccountNo());
        Bill.Validate("List No.", LibraryERM.CreateNoSeriesSalesCode);
        Bill.Validate("Temporary Bill No.", Bill."List No.");
        Bill.Validate("Final Bill No.", Bill."List No.");
        LibraryERM.CreateSourceCode(SourceCode);
        Bill.Validate("Bill Source Code", SourceCode.Code);
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemTracking: Variant;
        ItemTrackingMode: Option "Assign Lot No.","Select Entries";
    begin
        LibraryVariableStorage.Dequeue(ItemTracking);
        ItemTrackingMode := ItemTracking;
        if ItemTrackingMode = ItemTrackingMode::"Assign Lot No." then
            ItemTrackingLines."Assign Lot No.".Invoke
        else
            ItemTrackingLines."Select Entries".Invoke;  // Open handler - ItemTrackingSummaryModalPageHandler.
        ItemTrackingLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.StartingDate.SetValue(WorkDate);
        GetItemLedgerEntries.EndingDate.SetValue(WorkDate);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        ReportType: Option "Test Print";
    begin
        GLBookPrint.ReportType.SetValue(ReportType::"Test Print");
        GLBookPrint.StartingDate.SetValue(WorkDate);
        GLBookPrint.EndingDate.SetValue(WorkDate);
        GLBookPrint.PrintCompanyInformations.SetValue(false);
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        VATRegisterPrint.PeriodStartingDate.SetValue(WorkDate);
        VATRegisterPrint.PeriodEndingDate.SetValue(WorkDate);
        VATRegisterPrint.PrintCompanyInformations.SetValue(false);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

