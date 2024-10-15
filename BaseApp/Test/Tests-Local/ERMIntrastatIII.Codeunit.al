codeunit 144064 "ERM Intrastat - III"
{
    // // [FEATURE] [Intrastat]
    // 
    //  1. Test to verify Country/Region of Origin Code of Item vendor of Vendor should be updated on Intrastat Journal Line.
    //  2. Test to verify negative Amount of Sales credit Memo should be updated Intrastat Journal Line after running Intrastat Monthly Report.
    //  3. Test to verify Amount of Sales Invoice should be updated Intrastat Journal Line after running Intrastat Monthly Report.
    //  4. Test to verify negative Amount of Purchase credit Memo should be updated Intrastat Journal Line after running Intrastat Monthly Report.
    //  5. Test to verify Amount of Purchase Invoice should be updated Intrastat Journal Line after running Intrastat Monthly Report.
    //  6. Test to verify two Intrastat Journal Lines for Sales Invoice created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.
    //  7. Test to verify two Intrastat Journal Lines for Sales Invoice created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.
    //  8. Test to verify two Intrastat Journal Lines for Sales Credit Memo created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.
    //  9. Test to verify two Intrastat Journal Lines for Sales Credit Memo created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.
    // 10. Test to verify two Intrastat Journal Lines for Purchase Invoice created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.
    // 11. Test to verify two Intrastat Journal Lines for Purchase Invoice created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.
    // 12. Test to verify two Intrastat Journal Lines for Purchase Credit Memo created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.
    // 13. Test to verify two Intrastat Journal Lines for Purchase Credit Memo created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.
    // 14. Test to verify two Lines with Partial Quantities of Purchase Order should be updated on Intrastat Journal Line.
    // 15. Test to verify two Lines with Partial Quantities of Sales Order should be updated on Intrastat Journal Line.
    // 16. Test to verify Intrastat Journal can get entries correctly with different Service Tariff No. between invoice & credit memo in the different period.
    // 17. Test to verify Intrastat Journal Lines will not be created, when Transfer Order created from Subcontracting Order posted with Ship Only.
    // 18. Test to verify Intrastat Journal Line created with zero Amount for Purchase Credit Memo for Receipt with Item Charge Assignment on different Period.
    // 19. Test to verify Intrastat Journal Line created with zero Amount for Purchase Credit Memo for Receipt with Item Charge Assignment on same Period.
    // 20. Test to verify Intrastat Journal Line created with Sales Credit Amount for Shipment with Item Charge Assignment on different Period.
    // 21. Test to verify Intrastat Journal Line created with Sales Credit Amount for Shipment with Item Charge Assignment on same Period.
    // 22. Verify "Reference Period" is filled after GetEntries on Intrastat Journal Line.
    // 
    //   Covers Test Cases for WI - 347662.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   ItemVendorCountryRegionOfOriginCodeOnIntrastat                                              152392
    //   PostedSalesCrMemoAmtIntrastatMonthlyReport                                                  154585
    //   PostedSalesInvAmtIntrastatMonthlyReport                                                     154585
    //   PostedPurchCrMemoAmtIntrastatMonthlyReport                                                  154586
    //   PostedPurchInvAmtIntrastatMonthlyReport                                                     154586
    //   IntrastatItemChargeOnSalesInvAddReportingCurr                                               155576
    //   IntrastatItemChargeOnSalesInvWithoutAddReportingCurr                                        155575
    //   IntrastatItemChargeOnSalesCrMemoAddReportingCurr                                            155576
    //   IntrastatItemChargeOnSalesCrMemoWithoutAddReportingCurr                                     155575
    //   IntrastatItemChargeOnPurchInvAddReportingCurr                                               155574
    //   IntrastatItemChargeOnPurchInvWithoutAddReportingCurr                                        155577
    //   IntrastatItemChargeOnPurchCrMemoAddReportingCurr                                            155574
    //   IntrastatItemChargeOnPurchCrMemoWithoutAddReportingCurr                                     155577
    //   MultiplePurchaseInvoiceWithPartialQtyOnIntrastat                                            236900
    //   MultipleSalesInvoiceWithPartialQtyOnIntrastat                                               236901
    // 
    //   Covers Test Cases for WI - 348903.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   IntrastatJnlWithDifferentServiceTariffNoAndStatsPeriod                                      345257
    //   EmptyIntrastatJnlLineWithShipTransferFromSubconOrder                                        250780
    //   IntrastatItemChargeOnPurchCrMemoDifferentPeriod                                             205112
    //   IntrastatItemChargeOnPurchCrMemoSamePeriod
    //   IntrastatItemChargeOnSalesCrMemoDifferentPeriod
    //   IntrastatItemChargeOnSalesCrMemoSamePeriod
    // 
    //   ReferencePeriodAfterGetEntries                                                              353517

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        AmountMustEqualMsg: Label 'Amount must be equal';
        FormatTxt: Label '########';
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        FileManagement: Codeunit "File Management";
        LibraryRandom: Codeunit "Library - Random";
        CountryRegionCodeCap: Label 'Intrastat_Jnl__Line__Country_Region_Code_';
        DocumentNoCap: Label 'Intrastat_Jnl__Line__Document_No__';
        TransportMethodCap: Label 'Intrastat_Jnl__Line__Transport_Method_';
        VATRegistrationNoCap: Label 'Intrastat_Jnl__Line__VAT_Registration_No__';
        TotRoundAmountCap: Label 'TotRoundAmount';
        RoundAmountCap: Label 'RoundAmount_Control1130125';
        LineMustNotExistMsg: Label 'Line must not exist';
        IncorrectLineErr: Label 'Incorrect line in exported file.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemVendorCountryRegionOfOriginCodeOnIntrastat()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
        ItemVendorCountryRegion: Code[10];
    begin
        // Verify Country/Region of Origin Code of Item vendor of Vendor should be updated on Intrastat Journal Line.

        // Setup: Create Purchase Credit Memo. Create Item vendor with Country/Region of Origin Code. Post Purchase Credit Memo.
        Initialize;
        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::"Credit Memo", false);  // EU Service - FALSE.
        ItemVendorCountryRegion := CreateItemVendor(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, false, true, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - False, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify Country/Region of Origin Code of Item vendor updated on Intrastat Journal Line.
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Country/Region of Origin Code", ItemVendorCountryRegion);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler,IntrastatMonthlyReportPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoAmtIntrastatMonthlyReport()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // Verify negative Amount of Sales credit Memo should be updated Intrastat Journal Line.

        // Setup: Create and Post Sales Credit Memo. Get Entries on Intrastat Journal.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::"Credit Memo", true, false);  // Invoice -TRUE, EU Service - FALSE.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, false, true, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - False, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // Exercise: Update mandatory fields required on Intrastat Journal Line and Run Intrastat Monthly Report.
        UpdateIntrastatJournalAndRunIntrastatMonthlyReport(IntrastatJnlBatchName, DocumentNo);

        // Verify: Verify negative Amount of Sales credit Memo updated on Intrastat Journal Line.
        VerifyIntrastatMonthlyReport(
          TotRoundAmountCap, -FindSalesCrMemoLine(DocumentNo, SalesCrMemoLine.Type::Item), Customer."Country/Region Code",
          Customer."VAT Registration No.", DocumentNo, SalesHeader."Transport Method");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler,IntrastatMonthlyReportPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvAmtIntrastatMonthlyReport()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Amount of Sales Invoice should be updated Intrastat Journal Line.

        // Setup: Create and Post Sales Invoice. Get Entries on Intrastat Journal.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);  // Invoice -TRUE, EU Service - TRUE.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges- TRUE
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // Exercise: Update mandatory fields required on Intrastat Journal Line and Run Intrastat Monthly Report.
        UpdateIntrastatJournalAndRunIntrastatMonthlyReport(IntrastatJnlBatchName, DocumentNo);

        // Verify: Verify Amount of Sales Invoice Line updated on Intrastat Journal Line.
        VerifyIntrastatMonthlyReport(
          RoundAmountCap, -FindSalesInvoiceLine(DocumentNo, SalesInvoiceLine.Type::Item), Customer."Country/Region Code",
          Customer."VAT Registration No.", DocumentNo, SalesHeader."Transport Method");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesCorrectiveBatchPurchCrMemo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatchName: Code[10];
    begin
        // [SCENARIO 293951] Intrastat Journal Line of Corrective Batch is not created for Purchase Credit Memo, that is not applied to any Invoice.
        Initialize;

        // [GIVEN] Create and Post Purchase Credit Memo. Get Entries on Intrastat Journal.
        CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::"Credit Memo", true);  // Invoice - TRUE.

        // [WHEN] Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // [THEN] Intrastat Journal Line is not created.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler,IntrastatMonthlyReportPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvAmtIntrastatMonthlyReport()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Amount of Purchase Invoice should be updated on Intrastat Journal Line.

        // Setup: Create and Post Purchase Invoice. Get Entries on Intrastat Journal.
        Initialize;
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);  // Invoice - TRUE.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Update mandatory fields required on Intrastat Journal Line and Run Intrastat Monthly Report.
        UpdateIntrastatJournalAndRunIntrastatMonthlyReport(IntrastatJnlBatchName, DocumentNo);

        // Verify: Verify Amount of Purchase Invoice updated on Intrastat Journal Line.
        VerifyIntrastatMonthlyReport(
          RoundAmountCap, FindPurchaseInvoiceLine(DocumentNo, PurchInvLine.Type::Item), Vendor."Country/Region Code",
          Vendor."VAT Registration No.", DocumentNo, PurchaseHeader."Transport Method");
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesInvAddReportingCurr()
    var
        Customer: Record Customer;
    begin
        // Verify two Intrastat Journal Lines created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.

        // Setup: Get Item Entries with Additional Reporting Currency of G/L Setup with Customer Currency.
        Initialize;
        CreateCustomerWithCurrency(Customer);
        IntrastatMultipleCustWithItemChargeOnInv(Customer."No.", Customer."Currency Code");  // Additional Reporting Currency of G/L Setup with Customer Currency.
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesInvWithoutAddReportingCurr()
    var
        Customer: Record Customer;
    begin
        // Verify two Intrastat Journal Lines created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.

        // Setup: Get Item Entries with Additional Reporting Currency Blank on G/L Setup.
        Initialize;
        CreateCustomerWithCurrency(Customer);
        IntrastatMultipleCustWithItemChargeOnInv(Customer."No.", '');  // Additional Reporting Currency Blank on G/L Setup.
    end;

    local procedure IntrastatMultipleCustWithItemChargeOnInv(CustomerNo: Code[20]; AdditionalReportingCurrency: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ItemCharge: Record "Item Charge";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        IntrastatJnlBatchName: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Create Multiple Customers with and without Currency. Create and Post Sales Orders. Create and Post Sales Invoice and assign Item Charge to them.
        OldAdditionalReportingCurrency := UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency);
        CreateAndPostSalesDocument(SalesHeader, CustomerNo, SalesHeader."Document Type"::Order, false, true);  // Invoice - FALSE, EU Service - TRUE.
        CreateAndPostSalesDocument(SalesHeader2, CreateEUCustomer, SalesHeader."Document Type"::Order, false, true);  // Invoice - FALSE, EU Service - TRUE.
        LibraryInventory.CreateItemCharge(ItemCharge);
        DocumentNo := CreateAndPostSalesInvoiceWithItemChargeAssignment(SalesHeader, ItemCharge."No.");
        DocumentNo2 := CreateAndPostSalesInvoiceWithItemChargeAssignment(SalesHeader2, ItemCharge."No.");

        // Calculate only lines of Item Type due to using EU Service intrastat batch.
        SalesInvoiceHeader.Get(DocumentNo);
        Amount := FindSalesInvoiceLine(DocumentNo, SalesInvoiceLine.Type::Item);
        Amount2 := FindSalesInvoiceLine(DocumentNo2, SalesInvoiceLine.Type::Item);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Intrastat Journal Lines created, for Customer with currency and Customer without currency.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader."Service Tariff No.", -Amount / SalesInvoiceHeader."Currency Factor");
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader2."Service Tariff No.", -Amount2);

        // Tear down.
        UpdateGLSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesCrMemoAddReportingCurr()
    var
        Customer: Record Customer;
    begin
        // Verify two Intrastat Journal Lines created, for Customer with currency and Customer without Currency with Additional Reporting Currency of G/L Setup with Customer Currency.

        // Setup: Get Item Entries with Additional Reporting Currency of G/L Setup with Customer Currency.
        Initialize;
        CreateCustomerWithCurrency(Customer);
        IntrastatMultipleCustWithItemChargeOnCrMemo(Customer."No.", Customer."Currency Code");  // Additional Reporting Currency of G/L Setup with Customer Currency.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesCrMemoWithoutAddReportingCurr()
    var
        Customer: Record Customer;
    begin
        // Verify two Intrastat Journal Lines created, for Customer with currency and Customer without Currency with Additional Reporting Currency Blank on G/L Setup.

        // Setup: Get Item Entries with Additional Reporting Currency Blank on G/L Setup.
        Initialize;
        CreateCustomerWithCurrency(Customer);
        IntrastatMultipleCustWithItemChargeOnCrMemo(Customer."No.", '');  // Additional Reporting Currency Blank on G/L Setup.
    end;

    local procedure IntrastatMultipleCustWithItemChargeOnCrMemo(CustomerNo: Code[20]; AdditionalReportingCurrency: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ItemCharge: Record "Item Charge";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        IntrastatJnlBatchName: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Create Multiple Customers with and without Currency. Create and Post Sales Return Orders. Create and Post Sales Credit Memo and assign Item Charge to them.
        OldAdditionalReportingCurrency := UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency);
        CreateAndPostSalesDocument(SalesHeader, CustomerNo, SalesHeader."Document Type"::"Return Order", false, true);  // Invoice - FALSE, EU Service - TRUE.
        CreateAndPostSalesDocument(SalesHeader2, CreateEUCustomer, SalesHeader."Document Type"::"Return Order", false, true);  // Invoice - FALSE, EU Service - TRUE.
        LibraryInventory.CreateItemCharge(ItemCharge);
        DocumentNo := CreateAndPostSalesCrMemoWithItemChargeAssignment(SalesHeader, ItemCharge."No.");
        DocumentNo2 := CreateAndPostSalesCrMemoWithItemChargeAssignment(SalesHeader2, ItemCharge."No.");

        // Calculate only lines of Item Type due to using EU Service intrastat batch.
        SalesCrMemoHeader.Get(DocumentNo);
        Amount := FindSalesCrMemoLine(DocumentNo, SalesCrMemoLine.Type::Item);
        Amount2 := FindSalesCrMemoLine(DocumentNo2, SalesCrMemoLine.Type::Item);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Intrastat Journal Lines created, for Customer with currency and Customer without currency.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader."Service Tariff No.", Amount / SalesCrMemoHeader."Currency Factor");
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader2."Service Tariff No.", Amount2);

        // Tear down.
        UpdateGLSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchInvAddReportingCurr()
    var
        Vendor: Record Vendor;
    begin
        // Verify two Intrastat Journal Lines created, for Customer with currency and Vendor without Vendor with Additional Reporting Currency of G/L Setup with Vendor Currency.

        // Setup: Get Item Entries with Additional Reporting Currency of G/L Setup with Vendor Currency.
        Initialize;
        CreateVendorWithCurrency(Vendor);
        IntrastatMultipleVendWithItemChargeOnInv(Vendor."No.", Vendor."Currency Code");  // Additional Reporting Currency of G/L Setup with Vendor Currency.
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchInvWithoutAddReportingCurr()
    var
        Vendor: Record Vendor;
    begin
        // Verify two Intrastat Journal Lines created, for Vendor with currency and Vendor without Currency with Additional Reporting Currency Blank on G/L Setup.

        // Setup: Get Item Entries with Additional Reporting Currency Blank on G/L Setup.
        Initialize;
        CreateVendorWithCurrency(Vendor);
        IntrastatMultipleVendWithItemChargeOnInv(Vendor."No.", '');  // Additional Reporting Currency Blank on G/L Setup.
    end;

    local procedure IntrastatMultipleVendWithItemChargeOnInv(VendorNo: Code[20]; AdditionalReportingCurrency: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        ItemCharge: Record "Item Charge";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        IntrastatJnlBatchName: Code[10];
        OldAdditionalReportingCurrency: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Create Multiple Vendors with and without Currency. Create and Post Purchase Orders. Create and Post Purchase Invoice and assign Item Charge to them.
        OldAdditionalReportingCurrency := UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency);
        CreateAndPostPurchaseDocument(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::Order, false);  // Invoice - FALSE.
        CreateAndPostPurchaseDocument(PurchaseHeader2, CreateEUVendor, PurchaseHeader."Document Type"::Order, false);  // Invoice - FALSE.
        LibraryInventory.CreateItemCharge(ItemCharge);
        DocumentNo := CreateAndPostPurchaseInvoiceWithItemChargeAssignment(PurchaseHeader, ItemCharge."No.");
        DocumentNo2 := CreateAndPostPurchaseInvoiceWithItemChargeAssignment(PurchaseHeader2, ItemCharge."No.");

        // Calculate only lines of Item Type due to using EU Service intrastat batch.
        PurchInvHeader.Get(DocumentNo);
        Amount := FindPurchaseInvoiceLine(DocumentNo, PurchInvLine.Type::Item);
        Amount2 := FindPurchaseInvoiceLine(DocumentNo2, PurchInvLine.Type::Item);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Intrastat Journal Lines created, for Vendor with currency and Vendor without currency.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader."Service Tariff No.", Amount / PurchInvHeader."Currency Factor");
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader2."Service Tariff No.", Amount2);

        // Tear down.
        UpdateGLSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchCrMemoAddReportingCurr()
    var
        Vendor: Record Vendor;
    begin
        // Verify two Intrastat Journal Lines created, for Vendor with currency and Vendor without Vendor with Additional Reporting Currency of G/L Setup with Vendor Currency.

        // Setup: Get Item Entries with Additional Reporting Currency of G/L Setup with Vendor Currency.
        Initialize;
        CreateVendorWithCurrency(Vendor);
        IntrastatMultipleVendWithItemChargeOnCrMemo(Vendor."No.", Vendor."Currency Code");  // Additional Reporting Currency of G/L Setup with Vendor Currency.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchCrMemoWithoutAddReportingCurr()
    var
        Vendor: Record Vendor;
    begin
        // Verify two Intrastat Journal Lines created, for Vendor with currency and Vendor without Currency with Additional Reporting Currency Blank on G/L Setup.

        // Setup: Get Item Entries with Additional Reporting Currency Blank on G/L Setup.
        Initialize;
        CreateVendorWithCurrency(Vendor);
        IntrastatMultipleVendWithItemChargeOnCrMemo(Vendor."No.", '');  // Additional Reporting Currency Blank on G/L Setup.
    end;

    local procedure IntrastatMultipleVendWithItemChargeOnCrMemo(VendorNo: Code[20]; AdditionalReportingCurrency: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        ItemCharge: Record "Item Charge";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        OldAdditionalReportingCurrency: Code[10];
        IntrastatJnlBatchName: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Create Multiple Vendors with and without Currency. Create and Post Purchase Return Orders. Create and Post Purchase Credit Memo and assign Item Charge to them.
        OldAdditionalReportingCurrency := UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency);
        CreateAndPostPurchaseDocument(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::"Return Order", false);  // Invoice - FALSE.
        CreateAndPostPurchaseDocument(PurchaseHeader2, CreateEUVendor, PurchaseHeader."Document Type"::"Return Order", false);  // Invoice - FALSE.
        LibraryInventory.CreateItemCharge(ItemCharge);
        DocumentNo := CreateAndPostPurchaseCrMemoWithItemChargeAssignment(PurchaseHeader, ItemCharge."No.");
        DocumentNo2 := CreateAndPostPurchaseCrMemoWithItemChargeAssignment(PurchaseHeader2, ItemCharge."No.");

        // Calculate only lines of Item Type due to using EU Service intrastat batch.
        PurchCrMemoHdr.Get(DocumentNo);
        Amount := FindPurchaseCrMemoLine(DocumentNo, PurchCrMemoLine.Type::Item);
        Amount2 := FindPurchaseCrMemoLine(DocumentNo2, PurchCrMemoLine.Type::Item);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Intrastat Journal Lines created, for Vendor with currency and Vendor without currency.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader."Service Tariff No.", -Amount / PurchCrMemoHdr."Currency Factor");
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader2."Service Tariff No.", -Amount2);

        // Tear down.
        UpdateGLSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePurchaseInvoiceWithPartialQtyOnIntrastat()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        PostedDocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify two Lines with Partial Quantities of Purchase Order should be updated on Intrastat Journal Line.

        // Setup: Create and Post Purchase Order. Create Multiple Purchase Invoice with Get Receipt Line. Post Purchase Invoice with Partial Quantity.
        Initialize;
        PostedDocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Order, false);  // Invoice - FALSE.
        DocumentNo := CreateAndUpdatePurchaseInvoiceWithGetReceiptLine(PurchaseHeader, PostedDocumentNo);
        DocumentNo2 := CreateAndUpdatePurchaseInvoiceWithGetReceiptLine(PurchaseHeader, PostedDocumentNo);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Lines with Partial Quantities of Purchase Order updated on Intrastat Journal Line.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader."Service Tariff No.", PurchaseLine.Amount / 2);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo2);
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, PurchaseHeader."Service Tariff No.", PurchaseLine.Amount / 2);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesInvoiceWithPartialQtyOnIntrastat()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        PostedDocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify two Lines with Partial Quantities of Sales Order should be updated on Intrastat Journal Line.

        // Setup: Create and Post Sales Order. Create Multiple Purchase Invoice with Get Receipt Line. Post Purchase Invoice with Partial Quantity.
        Initialize;
        PostedDocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Order, false, true);  // Invoice - FALSE, EU Service - TRUE.
        DocumentNo := CreateAndUpdateSalesInvoiceWithGetShipmentLine(SalesHeader, PostedDocumentNo);
        DocumentNo2 := CreateAndUpdateSalesInvoiceWithGetShipmentLine(SalesHeader, PostedDocumentNo);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify two Lines with Partial Quantities of Sales Order updated on Intrastat Journal Line.
        FindSalesLine(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::Order);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader."Service Tariff No.", -SalesLine.Amount / 2);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo2);
        VerifyIntrastatJnlLineAmount(IntrastatJnlLine, IntrastatJnlBatchName, SalesHeader."Service Tariff No.", -SalesLine.Amount / 2);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlWithDifferentServiceTariffNoAndStatsPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
        PostedSalesInvoice: Code[20];
    begin
        // Verify Intrastat Journal can get entries correctly with different Service Tariff No. between invoice & credit memo in the different period.

        // Setup: Create multiple Sales Invoice for Same Customer and Item with different Service Tariff No. Create Sales Credit Memo in different Period.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);  // Invoice -TRUE, EU Service - TRUE.
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesInvoiceLine.Type::Item);
        PostedSalesInvoice := CreateAndPostSalesInvoice(SalesInvoiceLine."Sell-to Customer No.", SalesInvoiceLine."No.");
        SelectSalesInvoiceLine(SalesInvoiceLine, PostedSalesInvoice, SalesInvoiceLine.Type::Item);
        DocumentNo := CreateAndPostSalesCreditMemoAppliedOnInvoice(SalesInvoiceLine."Document No.", SalesInvoiceLine."No.");
        SelectSalesCreditMemoLine(SalesCrMemoLine, DocumentNo, SalesCrMemoLine.Type::Item);

        // Exercise: Get Entries on Intrastat Journal for the period, when Credit Memo was posted; Corrective = TRUE.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, true, false,
            Format(CalcDate('<1M>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // Verify: Verify Intratsat Journal Line for Sales credit Memo created. As Cr.Memo is correcting the Invoice, Amount = ABS(Invoice Amount - Cr.Memo Amount).
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, SalesCrMemoLine."Service Tariff No.",
          Abs(SalesInvoiceLine.Amount - FindSalesCrMemoLine(DocumentNo, SalesCrMemoLine.Type::Item)));
    end;

    [Test]
    [HandlerFunctions('SubcontrTransferOrderPageHandler,CarryOutActionMsgRequisitionRequestPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmptyIntrastatJnlLineWithShipTransferFromSubconOrder()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Verify Intrastat Journal Lines will not be created, when Transfer Order created from Subcontracting Order posted with Ship Only.

        // Setup: Create and post Subcontracting Transfer Order.
        Initialize;
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code");
        CreateSubcontractingTransferOrder(VendorNo);
        PostSubcontractingTransferHeader(TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code");

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify Intrastat Journal Lines will not be created, when Transfer Order created from Subcontracting Order posted with Ship Only.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.IsFalse(IntrastatJnlLine.FindFirst, LineMustNotExistMsg)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReferencePeriodAfterGetEntries()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
        StatisticsPeriod: Code[10];
    begin
        // Verify "Reference Period" is filled after GetEntries on Intrastat Journal Line.
        Initialize;

        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, false);  // EU Service - FALSE.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        StatisticsPeriod := Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod);

        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, false, false, false, StatisticsPeriod, true);  // EU Service - False, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        Assert.AreEqual(StatisticsPeriod, IntrastatJnlLine."Reference Period", IntrastatJnlLine.FieldCaption("Reference Period"));
    end;

    [Test]
    [HandlerFunctions('PurchReceiptLinesPageHandler,ItemChargeAssignmentPurchPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchCrMemoSamePeriod()
    begin
        // Verify Intrastat Journal Line created with zero Amount for Purchase Credit Memo for Receipt with Item Charge Assignment on same Period.
        IntrastatItemChargeOnPurchCrMemo(WorkDate);  // Posting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('PurchReceiptLinesPageHandler,ItemChargeAssignmentPurchPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnPurchCrMemoDifferentPeriod()
    begin
        // Verify Intrastat Journal Line created with zero Amount for Purchase Credit Memo for Receipt with Item Charge Assignment on different Period.
        IntrastatItemChargeOnPurchCrMemo(CalcDate('<1M>', WorkDate));  // Posting Date more than WORKDATE.
    end;

    local procedure IntrastatItemChargeOnPurchCrMemo(PostingDate: Date)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        IntrastatJnlBatchName: Code[10];
    begin
        // Setup: Create and Post Purchase order, Create and Post Purchase Credit Memo for Receipt with Item Charge Assignment on same Period.
        Initialize;
        CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Order, true);  // Invoice - TRUE.
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");  // Required inside PurchReceiptLinesPageHandler.
        DocumentNo := CreateAndPostPurchaseCrMemoWithReceiptAndItemChargeAssignment(PurchaseHeader, PostingDate);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false, Format(PostingDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify Intrastat Journal Line created with zero Amount.
        VerifyIntrastatJnlLine(IntrastatJnlBatchName, DocumentNo, 0);

        // Tear down.
        UpdateNoSeriesLinePurchase(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler,ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesCrMemoDifferentPeriod()
    begin
        // Verify Intrastat Journal Line created with Sales Credit Amount for Shipment with Item Charge Assignment on different Period.
        IntrastatItemChargeOnSalesCrMemo(CalcDate('<1M>', WorkDate));  // Posting Date more than WORKDATE.
    end;

    [Test]
    [HandlerFunctions('SalesShipmentLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler,ItemChargeAssignmentSalesPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatItemChargeOnSalesCrMemoSamePeriod()
    begin
        // Verify Intrastat Journal Line created with Sales Credit Amount for Shipment with Item Charge Assignment on same Period.
        IntrastatItemChargeOnSalesCrMemo(WorkDate);  // Posting Date - WORKDATE.
    end;

    local procedure IntrastatItemChargeOnSalesCrMemo(PostingDate: Date)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Order, Create and Post Sales Credit Memo for Shipment with Item Charge Assignment.
        Initialize;
        CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Order, false, true);  // Invoice - FALSE, EU Service - TRUE.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");  // Required inside SalesShipmentLinesPageHandler.
        DocumentNo := CreateAndPostSalesCrMemoWithGetShipmentAndItemChargeAssignment(SalesHeader, PostingDate);

        // Exercise: Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, true, false, Format(PostingDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - TRUE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // Verify: Verify Intrastat Journal Line created with Sales Credit Memo Amount.
        VerifyIntrastatJnlLine(IntrastatJnlBatchName, DocumentNo, FindSalesCrMemoLine(DocumentNo, SalesCrMemoLine.Type::"Charge (Item)"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatTriangularSales()
    var
        SalesHeader: Record "Sales Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        FileName: Text;
        ItemNo: Code[20];
        TariffNo: Code[20];
    begin
        // [FEATURE] [EU 3-Party Trade] [Sales]
        // [SCENARIO] Run "Intrastat - Make Disk" for Sales Order with "EU 3-Party Trade" = Yes
        Initialize;

        // [GIVEN] Posted Sales Order with "EU 3-Party Trade" = Yes
        ItemNo := CreateSalesDocument(SalesHeader, CreateEUCustomer, false, SalesHeader."Document Type"::Invoice);
        UpdateSalesDocEU3PartyTrade(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Instrastat Journal Batch with "EU Service" = No, Intrastat Journal Line for Sales Order
        TariffNo := CreateIntrastatJnlLineItemEntry(IntrastatJnlBatch, FindItemLedgerEntryNo(ItemNo));
        Commit();

        // [WHEN] Run 'Intrastat - Make Disk Tax Auth'
        FileName := FileManagement.ServerTempFileName('txt');
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, FileName);

        // [THEN] "Tariff No." field is exported from 57 till 64 position
        // [THEN] Positions from 65 till 113 filled with initial values 0 and blank
        // [THEN] Exported line has 106 symbol length (TFS 422486)
        VerifyValueInIntrastatFile(FileName, TariffNo, 57, 8, 106);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatTriangularService()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        FileName: Text;
        TariffNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [EU 3-Party Trade] [Services]
        // [SCENARIO] Run "Intrastat - Make Disk" for Service Order with "EU 3-Party Trade" = Yes
        Initialize;

        // [GIVEN] Posted Service Order with "EU 3-Party Trade" = Yes
        ItemNo := CreateAndPostServiceInvoice;

        // [GIVEN] Instrastat Journal Batch with "EU Service" = No, Intrastat Journal Line for Service Order
        TariffNo := CreateIntrastatJnlLineItemEntry(IntrastatJnlBatch, FindItemLedgerEntryNo(ItemNo));
        Commit();

        // [WHEN] Run 'Intrastat - Make Disk Tax Auth'
        FileName := FileManagement.ServerTempFileName('txt');
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, FileName);

        // [THEN] "Tariff No." field is exported from 57 till 64 position
        // [THEN] Positions from 65 till 113 filled with initial values 0 and blank
        // [THEN] Exported line has 106 symbol length (TFS 422486)
        VerifyValueInIntrastatFile(FileName, TariffNo, 57, 8, 106);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,PurchReceiptLinesPageHandler,GetItemLedgerEntriesSetDatesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NotToShowItemCharges()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatchName: Code[10];
        PostingDate: Date;
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 377846] No Item Charge entries should be suggested to Intrastat if "Show Item Charge Entries" option is not active

        Initialize;

        // [GIVEN] Posted Purchase Invoice and Credit Memo
        CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Order, true);  // Invoice - TRUE
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");  // Required inside PurchReceiptLinesPageHandler
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate);
        CreateAndPostPurchaseCrMemoWithReceiptAndItemChargeAssignment(PurchaseHeader, PostingDate);

        // [WHEN] Get Entries on Intrastat Journal with "Show Item Charge Entries" option disabled
        IntrastatJnlBatchName :=
          GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false, Format(PostingDate, 0, LibraryFiscalYear.GetStatisticsPeriod), false);

        // [THEN] No Intrastat Journal Line created
        IntrastatJnlLine.Init();
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesNormalBatchFirstPeriodSalesInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Normal batch for period 0121. Sales Invoice posted in 0121, Sales Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Sales Invoice posted in 0121. Sales Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesInvoiceLine.Type::Item);
        DocumentNo := CreateAndPostSalesCreditMemoAppliedOnInvoice(SalesInvoiceLine."Document No.", SalesInvoiceLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Normal Batch for period 0121.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false,
            Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is created, Amount equals to Invoice Amount.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, SalesInvoiceLine."Service Tariff No.", -SalesInvoiceLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesCorrectiveBatchFirstPeriodSalesInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Corrective batch for period 0121. Sales Invoice posted in 0121, Sales Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Sales Invoice posted in 0121. Sales Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesInvoiceLine.Type::Item);
        DocumentNo := CreateAndPostSalesCreditMemoAppliedOnInvoice(SalesInvoiceLine."Document No.", SalesInvoiceLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Corrective Batch for period 0121.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, true, false,
            Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is not created.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesNormalBatchSecondPeriodSalesInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Normal batch for period 0221. Sales Invoice posted in 0121, Sales Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Sales Invoice posted in 0121. Sales Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesInvoiceLine.Type::Item);
        DocumentNo := CreateAndPostSalesCreditMemoAppliedOnInvoice(SalesInvoiceLine."Document No.", SalesInvoiceLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Normal Batch for period 0221.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false,
            Format(CalcDate('<1M>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is not created.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesCorrectiveBatchSecondPeriodSalesInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Corrective batch for period 0221. Sales Invoice posted in 0121, Sales Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Sales Invoice posted in 0121. Sales Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, CreateEUCustomer, SalesHeader."Document Type"::Invoice, true, true);
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, SalesInvoiceLine.Type::Item);
        DocumentNo := CreateAndPostSalesCreditMemoAppliedOnInvoice(SalesInvoiceLine."Document No.", SalesInvoiceLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Corrective Batch for period 0221.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, true, false,
            Format(CalcDate('<1M>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is created, Amount equals to Invoice Amount minus Credit Memo Amount.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, SalesInvoiceLine."Service Tariff No.",
          Abs(SalesInvoiceLine.Amount - FindSalesCrMemoLine(DocumentNo, SalesCrMemoLine.Type::Item)));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesNormalBatchFirstPeriodPurchaseInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Normal batch for period 0121. Purchase Invoice posted in 0121, Purchase Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Purchase Invoice posted in 0121. Purchase Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);
        SelectPurchaseInvoiceLine(PurchInvLine, DocumentNo, PurchInvLine.Type::Item);
        DocumentNo := CreateAndPostPurchaseCreditMemoAppliedOnInvoice(PurchInvLine."Document No.", PurchInvLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Normal Batch for period 0121.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false,
            Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is created, Amount equals to Invoice Amount.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, PurchInvLine."Service Tariff No.", PurchInvLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesCorrectiveBatchFirstPeriodPurchaseInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Corrective batch for period 0121. Purchase Invoice posted in 0121, Purchase Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Purchase Invoice posted in 0121. Purchase Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);
        SelectPurchaseInvoiceLine(PurchInvLine, DocumentNo, PurchInvLine.Type::Item);
        DocumentNo := CreateAndPostPurchaseCreditMemoAppliedOnInvoice(PurchInvLine."Document No.", PurchInvLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Corrective Batch for period 0121.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false,
            Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is not created.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesNormalBatchSecondPeriodPurchaseInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Normal batch for period 0221. Purchase Invoice posted in 0121, Purchase Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Purchase Invoice posted in 0121. Purchase Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);
        SelectPurchaseInvoiceLine(PurchInvLine, DocumentNo, PurchInvLine.Type::Item);
        DocumentNo := CreateAndPostPurchaseCreditMemoAppliedOnInvoice(PurchInvLine."Document No.", PurchInvLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Normal Batch for period 0221.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false,
            Format(CalcDate('<1M>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is not created.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GetEntriesCorrectiveBatchSecondPeriodPurchaseInvAndCrMemoDifferentPeriod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 293951] Get Intrastat Journal entries for Corrective batch for period 0221. Purchase Invoice posted in 0121, Purchase Credit Memo posted in 0221.
        Initialize;

        // [GIVEN] Purchase Invoice posted in 0121. Purchase Credit Memo posted in 0221 and applied to the Invoice.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);
        SelectPurchaseInvoiceLine(PurchInvLine, DocumentNo, PurchInvLine.Type::Item);
        DocumentNo := CreateAndPostPurchaseCreditMemoAppliedOnInvoice(PurchInvLine."Document No.", PurchInvLine."No.");

        // [WHEN] Get Entries on Intrastat Journal for Corrective Batch for period 0221.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, true, false,
            Format(CalcDate('<1M>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod), true);

        // [THEN] Intrastat Journal Line is created, Amount equals to Invoice Amount minus Credit Memo Amount.
        VerifyIntrastatJnlLineAmount(
          IntrastatJnlLine, IntrastatJnlBatchName, PurchInvLine."Service Tariff No.",
          Abs(PurchInvLine.Amount - FindPurchaseCrMemoLine(DocumentNo, PurchCrMemoLine.Type::Item)));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckTransportMethodIsNotValidatedForServiceItemTypeInPurchaseDocument()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        FileName: Text;
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-Inventoriable]
        // [SCENARIO 323469] Get Intrastat Journal entries for posted Purchase Invoice with Item and Item.Type = Service.

        Initialize;

        // [GIVEN] Purchase Invoice with Item.Type = Service is created and posted.
        // [GIVEN] PurchaseHeader."Transport Method" is blank .
        CreatePurchaseDocumentWithoutTransportMethodWithServiceTypeItem(
          PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);  // EU Service - TRUE.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // [THEN] Intrastat Journal Line was created with blank "Transport Method"
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Transport Method", '');

        // [THEN] 'Intrastat - Make Disk Tax Auth' run successfully
        FileName := FileManagement.ServerTempFileName('txt');
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlBatchName);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, FileName);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckTransportMethodIsNotValidatedForServiceItemTypeInSalesDocument()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        FileName: Text;
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Non-Inventoriable]
        // [SCENARIO 323469] Get Intrastat Journal entries for posted Sales Invoice with Item and Item.Type = Service.

        Initialize;

        // [GIVEN] Sales Invoice with Item.Type = Service is created and posted.
        // [GIVEN] SalesHeader."Transport Method" is blank.
        CreateSalesDocumentWithoutTransportMethodWithServiceTypeItem(
          SalesHeader, CreateEUCustomer, true, SalesHeader."Document Type"::Invoice);  // EU Service - TRUE.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // [THEN] Intrastat Journal Line was created with blank "Transport Method"
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Transport Method", '');

        // [THEN] 'Intrastat - Make Disk Tax Auth' run successfully
        FileName := FileManagement.ServerTempFileName('txt');
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlBatchName);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, FileName);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckTransportMethodIsValidatedForNonServiceItemTypeInPurchaseDocument()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Inventoriable]
        // [SCENARIO 323469] Get Intrastat Journal entries for posted Purchase Invoice with Inventoriable item.

        Initialize;

        // [GIVEN] Purchase Invoice is created with Transport Method Code and posted.
        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Invoice, true);  // EU Service - TRUE.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Purchases, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // [THEN] Intrastat Journal Line was created with "Transport Method" value of the Purchase Invoice.
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Transport Method", PurchaseHeader."Transport Method");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckTransportMethodIsValidatedForNonServiceItemTypeInSalesDocument()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        IntrastatJnlBatchName: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Inventoriable]
        // [SCENARIO 323469] Get Intrastat Journal entries for posted Sales Invoice with Inventoriable item.

        Initialize;

        // [GIVEN] Sales Invoice is created with Transport Method Code and posted.
        CreateSalesDocument(SalesHeader, CreateEUCustomer, true, SalesHeader."Document Type"::Invoice);  // EU Service - TRUE.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Get Entries on Intrastat Journal.
        IntrastatJnlBatchName := GetEntriesIntrastatJournal(
            IntrastatJnlBatch.Type::Sales, true, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod), true);  // EU Service - TRUE, CorrectiveEntry - FALSE, AmountsInAddCurrency - FALSE, ShowItemCharges - TRUE

        // [THEN] Intrastat Journal Line was created with "Transport Method" value of the Sales Invoice.
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Transport Method", SalesHeader."Transport Method");
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        IntrastatJnlTemplate.DeleteAll();
        LibraryVariableStorage.Clear;
        ResetNoSeriesLastUsedDate;
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

    local procedure CreateItemVendor(DocumentNo: Code[20]; BuyFromVendorNo: Code[20]): Code[10]
    var
        ItemVendor: Record "Item Vendor";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", DocumentNo);
        LibraryInventory.CreateItemVendor(ItemVendor, BuyFromVendorNo, PurchaseLine."No.");
        ItemVendor.Validate("Country/Region of Origin Code", CreateCountryRegion);
        ItemVendor.Modify(true);
        exit(ItemVendor."Country/Region of Origin Code")
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer)
    begin
        Customer.Get(CreateEUCustomer);
        Customer.Validate("Currency Code", CreateCurrencyWithExchangeRate);
        Customer.Modify(true);
        UpdateGLAccountOnCurrency(Customer."Currency Code");
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor)
    begin
        Vendor.Get(CreateEUVendor);
        Vendor.Validate("Currency Code", CreateCurrencyWithExchangeRate);
        Vendor.Modify(true);
        UpdateGLAccountOnCurrency(Vendor."Currency Code");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentMethodCode: Code[10]; TransportMethod: Code[10]; ServiceTariffNo: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Transport Method", TransportMethod);
        SalesHeader.Validate("Service Tariff No.", ServiceTariffNo);
        SalesHeader.Validate("Ship-to Country/Region Code", SalesHeader."Sell-to Country/Region Code");
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PaymentMethodCode: Code[10]; TransportMethod: Code[10]; ServiceTariffNo: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Validate("Transport Method", TransportMethod);
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; EUService: Boolean; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        SalesLine: Record "Sales Line";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TransportMethod.FindFirst;
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, PaymentMethod.Code, TransportMethod.Code, ServiceTariffNumber."No.");
        CreateVATPostingSetup(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATPostingSetup."VAT Calculation Type"::"Normal VAT", EUService);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        exit(SalesLine."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; EUService: Boolean)
    var
        PaymentMethod: Record "Payment Method";
        PurchaseLine: Record "Purchase Line";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TransportMethod.FindFirst;
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, PaymentMethod.Code, TransportMethod.Code, ServiceTariffNumber."No.");
        CreateVATPostingSetup(
          VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", EUService);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Invoice: Boolean): Code[20]
    begin
        CreatePurchaseDocument(PurchaseHeader, BuyFromVendorNo, DocumentType, true);  // EU Service - TRUE.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure CreateSubconLocationWithTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        Location: Record Location;
        Location2: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);  // Subcontracting Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);  // Manufacturing Location.
        CreateTransferRoute(TransferRoute, Location2.Code, Location.Code);
    end;

    local procedure CreateTransferRoute(var TransferRoute: Record "Transfer Route"; TransferFromCode: Code[20]; TransferToCode: Code[20])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryInventory.CreateTransferRoute(TransferRoute, TransferFromCode, TransferToCode);
        TransferRoute.Validate("In-Transit Code", Location.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateSubcontractingOrder(WorkCenterNo: Code[20]; SourceNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        SubcontractingWorksheet: TestPage "Subcontracting Worksheet";
    begin
        // Calculate Subcontracting Order from Subcontracting Worksheet.
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
        SubcontractingWorksheet.OpenEdit;
        SubcontractingWorksheet.FILTER.SetFilter("Prod. Order No.", GetProductionOrderNo(SourceNo));
        SubcontractingWorksheet.First;
        SubcontractingWorksheet."Due Date".SetValue(CalcDate('<-1D>', WorkDate));
        SubcontractingWorksheet.Close;

        // Carryout Action message from Subcontracting Worksheet to create Subcontracting Order.
        CarryOutActionMessageFromSubcontractingWorksheet;
    end;

    local procedure CreateSubcontractingOrderSetup(LocationCode: Code[10]; LocationCode2: Code[10]) VendorNo: Code[20]
    var
        ItemNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        VendorNo := CreateSubcontractingVendor(LocationCode);  // Subcontracting Location.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        ItemNo := CreateItemWithProdBOMAndRouting(WorkCenterNo, LocationCode2);  // Manufacturing Location.
        CreateReleasedProductionOrder(ItemNo, LocationCode2);
        CreateSubcontractingOrder(WorkCenterNo, ItemNo);
    end;

    local procedure CreateSubcontractingTransferOrder(VendorNo: Code[20])
    var
        SubcontractingOrder: TestPage "Subcontracting Order";
    begin
        // Create Transfer order from Subcontracting Order.
        SubcontractingOrder.OpenEdit;
        SubcontractingOrder.FILTER.SetFilter("No.", GetSubcontractingOrderNo(VendorNo));
        SubcontractingOrder.CreateTransfOrdToSubcontractor.Invoke;  // Transfer order post in SubcontrTransferOrderPageHandler.
        SubcontractingOrder.Close;
    end;

    local procedure GetProductionOrderNo(SourceNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst;
        exit(ProductionOrder."No.");
    end;

    local procedure CarryOutActionMessageFromSubcontractingWorksheet()
    var
        SubcontractingWorksheet: TestPage "Subcontracting Worksheet";
    begin
        Commit();  // Commit required for run batch report.
        SubcontractingWorksheet.OpenEdit;
        SubcontractingWorksheet.CarryOutActionMessage.Invoke;  // Call CarryOutActionMsgRequisitionRequestPageHandler.
        SubcontractingWorksheet.Close
    end;

    local procedure CreateSubcontractingVendor(SubcontractingLocationCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Subcontractor, true);
        Vendor.Validate("Subcontracting Location Code", SubcontractingLocationCode);
        Vendor.Modify(true);
        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", '');
        exit(Vendor."No.");
    end;

    local procedure CreateSubcontractingWorkCenter(SubcontractorNo: Code[20]): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(CreateWorkCenter);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(20, 2));
        WorkCenter.Validate("Unit Cost", WorkCenter."Direct Unit Cost");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Subcontractor No.", SubcontractorNo);
        WorkCenter.Modify(true);
        exit(WorkCenter."No.");
    end;

    local procedure CreateProductionRouting(var RoutingNo: Code[20]; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        OperationNo: Code[10];
    begin
        OperationNo := Format(LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", CreateWorkCenter);  // Blank for Version Code.
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine2, '', IncStr(OperationNo), RoutingLine.Type::"Work Center", WorkCenterNo);    // Blank for Version Code.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    local procedure CreateProductionBOMWithRouting(var Item: Record Item; WorkCenterNo: Code[20]; LocationCode: Code[10])
    var
        ItemVendor: Record "Item Vendor";
        ItemVendor2: Record "Item Vendor";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine2: Record "Production BOM Line";
        Vendor: Record Vendor;
        RoutingNo: Code[20];
    begin
        CreateProductionRouting(RoutingNo, WorkCenterNo);
        LibraryPurchase.CreateVendor(Vendor);

        // Create Production BOM and Item Vendor for each child item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CreateItemAndUpdateInventory(LocationCode), 1);  // Vesrion Code - Blank, Using 1 for Per Item.
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", ProductionBOMLine."No.");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine2, '', ProductionBOMLine.Type::Item, CreateItemAndUpdateInventory(LocationCode), 1);  // Vesrion Code - Blank, Using 1 for Per Item.
        LibraryInventory.CreateItemVendor(ItemVendor2, Vendor."No.", ProductionBOMLine2."No.");

        // Certified Production BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithProdBOMAndRouting(WorkCenterNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateProductionBOMWithRouting(Item, WorkCenterNo, LocationCode);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateReleasedProductionOrder(ItemNo: Code[20]; LocationCode: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo,
          LibraryRandom.RandInt(10));  // Using Random for Quantity.
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);  // Using booleans for Forward,CalcLines,CalcRoutings,CalcComponents and CreateInbRqst.
    end;

    local procedure GetSubcontractingOrderNo(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.SetRange("Subcontracting Order", true);
        PurchaseHeader.FindFirst;
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; Invoice: Boolean; EUService: Boolean): Code[20]
    begin
        CreateSalesDocument(SalesHeader, SellToCustomerNo, EUService, DocumentType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreateAndPostSalesInvoiceWithItemChargeAssignment(SalesHeader: Record "Sales Header"; ItemChargeNo: Code[20]): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Invoice and Get Shipment Line of Sales Order. Post Sales Invoice.
        CreateSalesHeader(
          SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", SalesHeader."Payment Method Code",
          SalesHeader."Transport Method", SalesHeader."Service Tariff No.");
        CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::"Charge (Item)", ItemChargeNo);
        LibrarySales.GetShipmentLines(SalesLine);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesLine."Document Type"::Invoice, SalesHeader2."No.", SalesLine."Line No.", ItemChargeNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader2, true, true));
    end;

    local procedure CreateAndPostSalesCrMemoWithItemChargeAssignment(SalesHeader: Record "Sales Header"; ItemChargeNo: Code[20]): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Credit Memo and Get Return Receipt Line of Sales Return Order. Post Sales Credit Memo.
        CreateSalesHeader(
          SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.",
          SalesHeader."Payment Method Code", SalesHeader."Transport Method", SalesHeader."Service Tariff No.");
        CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::"Charge (Item)", ItemChargeNo);
        GetReturnReceiptsForSales(SalesHeader2."No.", SalesHeader."Sell-to Customer No.");
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesLine."Document Type"::"Credit Memo", SalesHeader2."No.", SalesLine."Line No.",
          ItemChargeNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader2, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithItemChargeAssignment(PurchaseHeader: Record "Purchase Header"; ItemChargeNo: Code[20]): Code[20]
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Invoice and Get Receipt Line of Purchase Order. Post Purchase Invoice.
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Payment Method Code", PurchaseHeader."Transport Method", PurchaseHeader."Service Tariff No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemChargeNo);
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader."No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseHeader."No.", PurchaseLine."Line No.",
          ItemCharge."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseCrMemoWithItemChargeAssignment(PurchaseHeader: Record "Purchase Header"; ItemChargeNo: Code[20]): Code[20]
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Credit Memo and Get Shipment Line of Purchase Return Order. Post Purchase Credit Memo.
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Payment Method Code", PurchaseHeader."Transport Method", PurchaseHeader."Service Tariff No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemChargeNo);
        GetReturnShipmentsForPurchase(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseHeader."No.",
          PurchaseLine."Line No.", ItemCharge."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesCrMemoWithGetShipmentAndItemChargeAssignment(SalesHeader: Record "Sales Header"; PostingDate: Date): Code[20]
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Credit Memo and Get Shipment Line of Sales Order. Post Sales Credit Memo.
        CreateSalesHeader(
          SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.",
          SalesHeader."Payment Method Code", SalesHeader."Transport Method", SalesHeader."Service Tariff No.");
        SalesHeader2.Validate("Posting Date", PostingDate);
        SalesHeader2.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo);
        SalesLine.ShowItemChargeAssgnt();  // Opens ItemChargeAssignmentSalesPageHandler.
        exit(LibrarySales.PostSalesDocument(SalesHeader2, true, true));
    end;

    local procedure CreateAndPostPurchaseCrMemoWithReceiptAndItemChargeAssignment(PurchaseHeader: Record "Purchase Header"; PostingDate: Date): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Credit Memo and Get Reciept Line of Purchase Order. Post Purchase Credit Memo.
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Payment Method Code", PurchaseHeader."Transport Method", PurchaseHeader."Service Tariff No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo);
        PurchaseLine.ShowItemChargeAssgnt();  // Opens ItemChargeAssignmentPurchPageHandler.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesCreditMemoAppliedOnInvoice(No: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        SalesInvoiceHeader.Get(No);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Payment Method Code",
          SalesInvoiceHeader."Transport Method", SalesInvoiceHeader."Service Tariff No.");
        SalesHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate));
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", No);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseCreditMemoAppliedOnInvoice(No: Code[20]; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchInvHeader.Get(No);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."Payment Method Code",
          PurchInvHeader."Transport Method", PurchInvHeader."Service Tariff No.");
        PurchaseHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate));
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", No);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(SellToCustomerNo: Code[20]; No: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransportMethod: Record "Transport Method";
        PaymentMethod: Record "Payment Method";
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        TransportMethod.FindFirst;
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo,
          PaymentMethod.Code, TransportMethod.Code, ServiceTariffNumber."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Country/Region of Origin Code", CreateVATRegistrationNoFormat);
        Item.Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateIntrastatJournalBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Type: Option; EUService: Boolean; CorrectiveEntry: Boolean; AmountsInAddCurrency: Boolean; StatisticsPeriod: Code[10])
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate(Type, Type);
        IntrastatJnlBatch.Validate(Periodicity, IntrastatJnlBatch.Periodicity::Month);
        IntrastatJnlBatch.Validate("EU Service", EUService);
        IntrastatJnlBatch.Validate("Statistics Period", StatisticsPeriod);
        IntrastatJnlBatch.Validate("Corrective Entry", CorrectiveEntry);
        IntrastatJnlBatch.Validate("Amounts in Add. Currency", AmountsInAddCurrency);
        IntrastatJnlBatch.Validate(
          "File Disk No.", LibraryUtility.GenerateRandomCode(IntrastatJnlBatch.FieldNo("File Disk No."), DATABASE::"Intrastat Jnl. Batch"));
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateIntrastatJnlLineItemEntry(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ILENo: Integer): Code[20]
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        CreateIntrastatJournalBatch(
          IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, false, false, false, Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod));
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        ItemLedgerEntry.Get(ILENo);
        with IntrastatJnlLine do begin
            Type := Type::Shipment;
            Date := ItemLedgerEntry."Last Invoice Date";
            "Tariff No." := CopyStr(LibraryUtility.GenerateRandomText(8), 1, MaxStrLen("Tariff No."));
            "Country/Region Code" := GetIntrastatCountryCode(ItemLedgerEntry."Country/Region Code");
            "Transaction Type" := LibraryUtility.GenerateRandomCode(FieldNo("Transaction Type"), DATABASE::"Intrastat Jnl. Line");
            "Transport Method" := ItemLedgerEntry."Transport Method";
            "Source Type" := "Source Type"::"Item Entry";
            "Source Entry No." := ItemLedgerEntry."Entry No.";
            ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
            Amount := ItemLedgerEntry."Sales Amount (Actual)";
            Quantity := ItemLedgerEntry.Quantity;
            "Document No." := ItemLedgerEntry."Document No.";
            "Item No." := ItemLedgerEntry."Item No.";
            "Total Weight" := LibraryRandom.RandDecInRange(1, 10, 2);
            "Partner VAT ID" := LibraryUtility.GenerateGUID;
            Area := LibraryUtility.GenerateRandomCode(FieldNo(Area), DATABASE::"Intrastat Jnl. Line");
            "Transaction Specification" :=
              LibraryUtility.GenerateRandomCode(FieldNo("Transaction Specification"), DATABASE::"Intrastat Jnl. Line");
            Modify;
            exit("Tariff No.");
        end;
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATCalculationType: Enum "Tax Calculation Type"; EUService: Boolean)
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
        VATPostingSetup.Validate("EU Service", EUService);
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

    local procedure CreateAndUpdateSalesInvoiceWithGetShipmentLine(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Create Sales Invoice, Get Shipment Line from Sales Order. Update partial quantity on Sales Invoice and Post Sales Invoice.
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.", SalesHeader."Payment Method Code",
          SalesHeader."Transport Method", SalesHeader."Service Tariff No.");
        SalesLine.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);  // Opens GetShipmentLinesPageHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst;
        SalesLine.SetRange("No.", SalesShipmentLine."No.");
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine."Document Type"::Invoice);
        SalesLine.Validate(Quantity, SalesShipmentLine.Quantity / 2);  // Partial Quantity.
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndUpdatePurchaseInvoiceWithGetReceiptLine(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Create Purchase Invoice, Get Receipt Line from Purchase Order. Update partial quantity on Purchase Invoice and Post Purchase Invoice.
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Payment Method Code", PurchaseHeader."Transport Method", PurchaseHeader."Service Tariff No.");
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst;
        OpenPurchaseInvoiceAndGetReceiptLine(PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", PurchRcptLine."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."No.");
        PurchaseLine.Validate(Quantity, PurchRcptLine.Quantity / 2);  // Partial Quantity.
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateWorkCenter(): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        exit(WorkCenter."No.");
    end;

    local procedure CreateItemAndUpdateInventory(LocationCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LocationCode);
        exit(Item."No.");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, LibraryRandom.RandIntInRange(100, 200));  // Using Random for Quantity in large volume.
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostServiceInvoice(): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateEUCustomer);
        UpdateServiceDocEU3PartyTrade(ServiceHeader);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        with ServiceLine do begin
            Validate("Service Item Line No.", ServiceItemLine."Line No.");
            Validate(Quantity, LibraryRandom.RandInt(100));
            Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            Modify(true);
        end;
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(Item."No.");
    end;

    local procedure PostSubcontractingTransferHeader(TransferFromCode: Code[10]; TransferToCode: Code[10])
    var
        SubcontractingTransferHeader: Record "Transfer Header";
    begin
        SubcontractingTransferHeader.SetRange("Transfer-from Code", TransferFromCode);
        SubcontractingTransferHeader.SetRange("Transfer-to Code", TransferToCode);
        SubcontractingTransferHeader.FindFirst;

        // Ship the Subcontracting Transfer Order.
        LibraryInventory.PostTransferHeader(SubcontractingTransferHeader, true, false);
    end;

    local procedure FindIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; DocumentNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst;
    end;

    local procedure FindSalesInvoiceLine(DocumentNo: Code[20]; Type: Enum "Sales Line Type"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SelectSalesInvoiceLine(SalesInvoiceLine, DocumentNo, Type);
        exit(SalesInvoiceLine.Amount);
    end;

    local procedure FindSalesCrMemoLine(DocumentNo: Code[20]; Type: Enum "Sales Line Type"): Decimal
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SelectSalesCreditMemoLine(SalesCrMemoLine, DocumentNo, Type);
        exit(SalesCrMemoLine.Amount);
    end;

    local procedure FindPurchaseInvoiceLine(DocumentNo: Code[20]; Type: Enum "Purchase Line Type"): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, Type);
        PurchInvLine.FindFirst;
        exit(PurchInvLine.Amount);
    end;

    local procedure FindPurchaseCrMemoLine(DocumentNo: Code[20]; Type: Enum "Purchase Line Type"): Decimal
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetRange(Type, Type);
        PurchCrMemoLine.FindFirst;
        exit(PurchCrMemoLine.Amount);
    end;

    local procedure SelectSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, Type);
        SalesInvoiceLine.FindFirst;
    end;

    local procedure SelectSalesCreditMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, Type);
        SalesCrMemoLine.FindFirst;
    end;

    local procedure SelectPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; DocumentNo: Code[20]; Type: Enum "Purchase Line Type")
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, Type);
        PurchInvLine.FindFirst;
    end;

    local procedure GetReturnReceiptsForSales(No: Code[20]; SellToCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", No);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SellToCustomerNo);
        ReturnReceiptLine.FindFirst;
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure GetReturnShipmentsForPurchase(No: Code[20]; BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", No);
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        ReturnShipmentLine.FindFirst;
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure ResetNoSeriesLastUsedDate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        LibraryERM.FindVATPostingSetupSales(VATPostingSetup);
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");

        NoSeriesLineSales.SetRange("Series Code", VATBusinessPostingGroup."Default Sales Operation Type");
        NoSeriesLineSales.ModifyAll("Last Date Used", NoSeriesLineSales."Starting Date");
        NoSeriesLinePurchase.SetRange("Series Code", VATBusinessPostingGroup."Default Purch. Operation Type");
        NoSeriesLinePurchase.ModifyAll("Last Date Used", NoSeriesLinePurchase."Starting Date");
    end;

    local procedure UpdateIntrastatJournalLine(JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        "Area": Record "Area";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        EntryExitPoint: Record "Entry/Exit Point";
        TransactionType: Record "Transaction Type";
        TransactionSpecification: Record "Transaction Specification";
    begin
        TransactionType.FindFirst;
        EntryExitPoint.FindFirst;
        Area.FindFirst;
        TransactionSpecification.FindFirst;
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.Validate("Reference Period", Format(CalcDate('<-1Y>', WorkDate), 0, LibraryFiscalYear.GetStatisticsPeriod));  // Reference Period less than Statistics Period.
        IntrastatJnlLine.Validate("Transaction Type", TransactionType.Code);
        IntrastatJnlLine.Validate("Entry/Exit Point", EntryExitPoint.Code);
        IntrastatJnlLine.Validate(Area, Area.Code);
        IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification.Code);
        IntrastatJnlLine.Modify(true);
    end;

    local procedure UpdateGLAccountOnCurrency("Code": Code[10])
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        Currency.Get(Code);
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
    end;

    local procedure UpdateGLSetupAdditionalReportingCurrency(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;  // Assigning value to avoid running of Report Adjust Add. Reporting Currency.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateNoSeriesLinePurchase(No: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        PurchCrMemoHdr.Get(No);
        NoSeriesLinePurchase.SetRange("Series Code", PurchCrMemoHdr."Operation Type");
        NoSeriesLinePurchase.ModifyAll("Last Date Used", CalcDate('<-2M', WorkDate));
    end;

    local procedure UpdateSalesDocEU3PartyTrade(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("EU 3-Party Trade", true);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateServiceDocEU3PartyTrade(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Validate("EU 3-Party Trade", true);
        ServiceHeader.Modify(true);
    end;

    local procedure GetEntriesIntrastatJournal(Type: Option; EUService: Boolean; CorrectiveEntry: Boolean; AmountsInAddCurrency: Boolean; StatisticsPeriod: Code[10]; ShowItemCharges: Boolean): Code[10]
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        CreateIntrastatJournalBatch(IntrastatJnlBatch, Type, EUService, CorrectiveEntry, AmountsInAddCurrency, StatisticsPeriod);
        Commit();  // Commit required.
        LibraryVariableStorage.Enqueue(ShowItemCharges); // Show Item Charges
        IntrastatJournal.OpenEdit;
        IntrastatJournal.GetEntries.Invoke;  // Opens GetItemLedgerEntriesRequestPageHandler.
        IntrastatJournal.Close;
        exit(IntrastatJnlBatch.Name);
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            SetRange("Item No.", ItemNo);
            FindFirst;
            exit("Entry No.");
        end;
    end;

    local procedure UpdateIntrastatJournalAndRunIntrastatMonthlyReport(JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatMonthlyReport: Report "Intrastat - Monthly Report";
    begin
        UpdateIntrastatJournalLine(JournalBatchName, DocumentNo);
        Commit();  // Commit reqiured.
        Clear(IntrastatMonthlyReport);
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatMonthlyReport.SetTableView(IntrastatJnlLine);
        IntrastatMonthlyReport.Run;  // Opens handler - IntrastatMonthlyReportRequestPageHandler.
    end;

    local procedure OpenPurchaseInvoiceAndGetReceiptLine(No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke;  // Opens GetReceiptLinesPageHandler.
        PurchaseInvoice.Close;
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Filename: Text)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlBatch.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlBatch.SetRange(Name, IntrastatJnlBatch.Name);

        IntrastatMakeDiskTaxAuth.InitializeRequest(Filename);
        IntrastatMakeDiskTaxAuth.UseRequestPage(false);
        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlBatch);
        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlLine);
        IntrastatMakeDiskTaxAuth.RunModal;
    end;

    local procedure VerifyIntrastatJnlLine(JournalBatchName: Code[10]; DocumentNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        Assert.AreNearlyEqual(Amount, IntrastatJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision, AmountMustEqualMsg);
    end;

    local procedure VerifyIntrastatMonthlyReport(RoundAmountCap: Text[1024]; Amount: Decimal; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]; DocumentNo: Code[20]; TransportMethod: Code[10])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(RoundAmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(CountryRegionCodeCap, CountryRegionCode);
        LibraryReportDataset.AssertElementWithValueExists(VATRegistrationNoCap, VATRegistrationNo);
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoCap, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists(TransportMethodCap, TransportMethod);
    end;

    local procedure VerifyIntrastatJnlLineAmount(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; ServiceTariffNo: Code[10]; Amount: Decimal)
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Service Tariff No.", ServiceTariffNo);
        IntrastatJnlLine.FindFirst;
        Assert.AreNearlyEqual(Amount, IntrastatJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision, AmountMustEqualMsg);
    end;

    local procedure VerifyValueInIntrastatFile(FileName: Text; ExpValue: Code[20]; ExpValuePos: Integer; ExpValueLen: Integer; ExpStringLen: Integer)
    var
        TextLine: Text[1024];
        Value: Code[20];
    begin
        TextLine := ReadTxtLineFromFile(FileName);

        Evaluate(Value, CopyStr(TextLine, ExpValuePos, ExpValueLen));

        Assert.AreEqual(ExpValue, Value, IncorrectLineErr);
        Assert.AreEqual(ExpStringLen, StrLen(TextLine), IncorrectLineErr);
        Assert.AreEqual('000000000000000000000000000000000 0    ', CopyStr(TextLine, 65, 39), IncorrectLineErr);
    end;

    local procedure ReadTxtLineFromFile(FileName: Text) TextLine: Text[1024]
    var
        File: File;
    begin
        File.WriteMode(false);
        File.TextMode(true);
        File.Open(FileName);
        File.Read(TextLine); // first line - file header info
        File.Read(TextLine); // second line - document info
        File.Close;
    end;

    local procedure CreateItemWithVATProdPostingGroupAndServiceType(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        LibraryInventory.CreateServiceTypeItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Country/Region of Origin Code", CreateVATRegistrationNoFormat);
        Item.Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesDocumentWithoutTransportMethodWithServiceTypeItem(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; EUService: Boolean; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        SalesLine: Record "Sales Line";
        ServiceTariffNumber: Record "Service Tariff Number";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, PaymentMethod.Code, '', ServiceTariffNumber."No.");
        CreateVATPostingSetup(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATPostingSetup."VAT Calculation Type"::"Normal VAT", EUService);
        CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          CreateItemWithVATProdPostingGroupAndServiceType(VATPostingSetup."VAT Prod. Posting Group"));
        exit(SalesLine."No.");
    end;

    local procedure CreatePurchaseDocumentWithoutTransportMethodWithServiceTypeItem(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; EUService: Boolean)
    var
        PaymentMethod: Record "Payment Method";
        PurchaseLine: Record "Purchase Line";
        ServiceTariffNumber: Record "Service Tariff Number";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, PaymentMethod.Code, '', ServiceTariffNumber."No.");
        CreateVATPostingSetup(
          VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", EUService);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithVATProdPostingGroupAndServiceType(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesSetDatesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.StartingDate.SetValue(WorkDate);
        GetItemLedgerEntries.EndingDate.SetValue(CalcDate('<2M>', WorkDate));  // Ending Date greater than Posting Dates.
        GetItemLedgerEntries.ShowingItemCharges.SetValue(LibraryVariableStorage.DequeueBoolean);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.ShowingItemCharges.SetValue(LibraryVariableStorage.DequeueBoolean);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMonthlyReportPageHandler(var IntrastatMonthlyReport: TestRequestPage "Intrastat - Monthly Report")
    begin
        IntrastatMonthlyReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SubcontrTransferOrderPageHandler(var SubcontrTransferOrder: TestPage "Subcontr. Transfer Order")
    begin
        SubcontrTransferOrder.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgRequisitionRequestPageHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptLinesPageHandler(var PurchReceiptLines: TestPage "Purch. Receipt Lines")
    var
        BuyFromVendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        PurchReceiptLines.FILTER.SetFilter("Buy-from Vendor No.", BuyFromVendorNo);
        PurchReceiptLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinesPageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        SalesShipmentLines.FILTER.SetFilter("Sell-to Customer No.", SellToCustomerNo);
        SalesShipmentLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReceiptLines.Invoke;  // Opens PurchReceiptLinesPageHandler.
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.GetShipmentLines.Invoke;  // Opens SalesShipmentLinesPageHandler.
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

