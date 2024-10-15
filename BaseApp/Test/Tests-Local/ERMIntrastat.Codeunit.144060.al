codeunit 144060 "ERM Intrastat"
{
    // // [FEATURE] [Intrastat]
    //  1. Test to verify Service Tariff No of Sales Invoice is also updated on Copied Sales Invoice Line.
    //  2. Test to verify warnings for blank Payment method, Transport Method and Service Tariff No. on the Report Sales Document test
    //  3. Test to verify Service Tariff No of Posted Sales Invoice also updated on VAT Entry.
    //  4. Test to verify error For Posting of Sales Invoice when transport Method is blank.
    //  5. Test to verify VAT Registration from Sales Invoice Customer also updated on Intrastat Journal Line when Shipment on Invoice False on Sales & Receivables Setup.
    //  6. Test to verify VAT Registration from Sales Invoice Customer also updated on Intrastat Journal Line when Shipment on Invoice True on Sales & Receivables Setup.
    //  7. Test to verify VAT Registration from Purchase Invoice Vendor also updated on Intrastat Journal Line when Receipt on Invoice True on Purchases & Payables Setup.
    //  8. Test to verify VAT Registration from Purchase Invoice Vendor also updated on Intrastat Journal Line when Receipt on Invoice False on Purchases & Payables Setup.
    //  9. Test to verify correct Amount of Purchase Invoice updated on Intrastat Journal Line, when EU Service is True on Intrastat Journal Batch.
    // 10. Test to verify Intrastat Journal Line not created for EU vendor purchase Invoice, when EU Service is false on Intrastat Journal Batch.
    // 11. Test to verify correct Amount of Sales Invoice updated on Intrastat Journal Line, when EU Service is false on Intrastat Journal Batch.
    // 12. Test to verify Intrastat Journal Line not created for EU Customer Sales Invoice, when EU Service is false on Intrastat Journal Batch.
    // 13. Verify Country/Region Code on Intrastat Jnl. Line updated from Customer's Ship-to Address.
    // 14. Verify Corrective Entry error while updating Corrective Entry.
    // 15. Verify EU Service error while updating EU Service.
    // 16. Verify message while updating Service Tariff Number on Sales Header.
    // 17. Verify Amount, Date, Service Tariff No and Transport Method, Payment Method Code of VAT Entry is successfully updated on Intrastat Jnl. Line.
    // 18. Verify Country/Region Code is successfully updated on Intrastat Jnl. Line.
    // 19. Verify Intrastat Journal Line not created for Intrastat Journal Batch Type Sales EU Service TRUE.
    // 20. Verify message while updating Service Tariff Number on Purchase Header.
    // 21. Verify VAT Registration from Buy-from Vendor No. of Purchase Invoice updated on Intrastat Jnl. Line.
    // 22. Verify VAT Registration from Sell-to Customer No. of Sales Invoice updated on Intrastat Jnl. Line.
    // 23. Verify that Total Weight on Intrastat Journal Page should be a rounded whole value.
    // 24. Verify Country/Region Code is successfully updated on Intrastat Jnl. Line from Country/Region's Intrastat Code.
    // 25. Verify that only one line is created from Posted Purchase Invoice on Intrastat Jnl. Line and Posted Purchase Credit Memo line should not found on Intrastat Jnl. Line.
    // 26. Verify that only one line is created from Posted Sales Invoice on Intrastat Jnl. Line and Posted Sales Credit Memo line should not found on Intrastat Jnl. Line.
    // 27. Verify negative value of Amount should be found on Intrastat Jnl. Line.
    // 28. Verify correct Date updated on Intrastat Journal Line from Sales Invoice Document Date, when EU Service is True on Intrastat Journal Batch.
    // 29. Verify that only one Intrastat line created for two lines of Purchase Invoice.
    // 30. Verify that only one Intrastat line created for two lines of Sales Invoice.
    // 31. Verify that Country/Region of Payment Code on Intrastat Jnl. Line must updated from Vendor's Country/Region Code.
    // 
    //   Covers Test Cases for WI - 347506, 347659.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   CopiedSalesInvoiceWithTariffNo                                                               202209
    //   WarningsOnReportSalesDocumentTest                                                     202210,202208
    //   PostedInvoiceServiceTariffOnVATEntry                                                  202212,202211
    //   PostedSalesInvoiceTransportMethodBlankError                                                  202216
    //   VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoiceFalse,
    //   VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoiceTrue                                     154587
    //   VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoiceTrue,
    //   VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoiceFalse                                     154588
    //   AmountIntrastatJnlLinePurchaseInvoiceEUServiceTrue                                    176440,202265
    //   IntrastatJnlLineEmptyPurchaseInvoiceEUServiceFalse                                           176441
    //   AmountIntrastatJnlLineSalesInvoiceEUServiceTrue                                              176444
    //   IntrastatJnlLineEmptySalesInvoiceEUServiceFalse                                              176445
    // 
    //   Covers Test Cases for WI - 347670.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   CountryCodeOnIntrastatJnlLineWithCustomerShipToAddress                                       201177
    //   IntrastatJnlLineCorrectiveEntryError                                                  202217,202234
    //   IntrastatJnlLineEUServiceError                                                        202217,202234
    //   SalesInvoiceServiceTariffNo                                                                  202218
    //   IntrastatJnlLineSalesInvoiceWithVATEntryEUServiceTrue                                        202213
    //   IntrastatJnlLineEUCountryCodeWithEUServiceTrue                                               202232
    // 
    //   Covers Test Cases for WI - 347671.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   IntrastatJnlLineEmptyPurchaseInvoiceWithTypeSales                                            202263
    //   PurchaseOrderServiceTariffNoMessage                                                          202235
    //   VATRegNoBuyFromVendorNoOnIntrastatJnlLineReceipt                                             260225
    //   VATRegNoFromSellToCustomerNoOnIntrastatJnlLineShipment                                       260226
    // 
    //   Covers Test Cases for WI - 347672.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   TotalWeightOnIntrastatJournalLine                                                            202285
    //   IntrastatJnlLineCountryRegionCodeFromCountryRegion                                           202245
    //   PurchaseInvoiceEntryOnIntrastatJnlLine                                                       202286
    //   SalesInvoiceEntryOnIntrastatJnlLine                                                          202287
    //   NegativeAmountOnIntrastatJnlLineFromPurchaseCrMemo                                           202267
    // 
    //   Covers Test Cases for WI - 347673.
    //   ---------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                           TFS ID
    //   ---------------------------------------------------------------------------------------------------
    //   DateOnIntrastatJnlLineFromSalesInvoiceDocumentDate                                           231969
    //   AmountOnIntrastatJnlLineFromMultiplePurchaseLines                                            219816
    //   AmountOnIntrastatJnlLineFromMultipleSalesLines                                               219817
    //   CountryOfPaymentCodeFromVendorCountryRegionCode                                              219561

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
    end;

    var
        CorrectiveEntryErr: Label 'You cannot change Corrective Entry when Intrastat Jnl. Lines for batch %1 exists.';
        EUServiceErr: Label 'You cannot change EU Service when Intrastat Jnl. Lines for batch %1 exists.';
        ErrorTextLbl: Label 'ErrorText_Number__Control97';
        FormatTxt: Label '########';
        PurchaseServiceTariffNumberMsg: Label 'You have changed Service Tariff No. on the purchase header, but it has not been changed on the existing purchase lines';
        ServiceTariffMustSpecifiedErrorMsg: Label '%1 must be specified.';
        ServiceTariffNumberMsg: Label 'You have changed Service Tariff No. on the sales header, but it has not been changed on the existing sales lines';
        TransportMethodErr: Label 'Transport Method must have a value in Sales Header';
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustSpecifiedErrorMsg: Label '%1 must be specified on header.';
        ValueMatchMsg: Label 'Values must match.';
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        IntrastatJnlBatchType: Option Purchase,Sales;
        IsInitialized: Boolean;
        FieldMustHaveValueErr: Label '%1 must have a value in %2', Comment = '%1 - field name; %2 - table name.';
        FileNotCreatedErr: Label 'Intrastat file was not created';
        FileWasCreatedSuccessfullyMsg: Label 'File was created successfully.';
        DocumentDateErr: Label 'Wrong Document Date value';
        DocumentNoErr: Label 'Wrong Document No. value';
        IntrastatJournalLineErr: Label 'Wrong %1 in Intrastat Journal', Comment = '%1 - field caption.';
        WrongPmtCountryErr: Label 'Wrong payment country specified in exported file.';

    [Test]
    [HandlerFunctions('CopySalesDocumentRequestPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CopiedSalesInvoiceWithTariffNo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceTariffNo: Code[20];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Setup: Create Sales Invoice with EU Customer, create another Sales Header.
        Initialize;
        CustomerNo := CreateEUCustomer;
        ServiceTariffNo := CreateSalesDocument(SalesHeader, CustomerNo, true, SalesHeader."Document Type"::Invoice, '');  // TRUE for EU Service.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, CustomerNo);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Required inside CopySalesDocumentRequestPageHandler.

        // Exercise: Copy from Posted Sales Invoice.
        CopySalesDoument(SalesHeader2);

        // Verify: Verify Service Tariff No of Sales Invoice is also updated on Copied Sales Invoice Line.
        FindSalesLine(SalesLine, SalesHeader2."Document Type", SalesHeader2."No.");
        SalesLine.TestField("Service Tariff No.", ServiceTariffNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarningsOnReportSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Invoice with EU Customer. Update Payment method, Transport Method and Service Tariff No. - Blank.
        Initialize;
        CreateSalesDocument(SalesHeader, CreateEUCustomer, true, SalesHeader."Document Type"::Invoice, '');  // TRUE for EU Service.
        UpdateSalesHeader(SalesHeader, '', '', '');  // Payment method, Transport Method, Service Tariff No. - Blank.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        UpdateSalesLineServiceTariffNo(SalesLine, '');  // Service Tariff No. - Blank.

        // Exercise: Run Report Sales Document test.
        RunSalesDocumentTest(SalesHeader."No.");  // Opens SalesDocumentTestRequestPageHandler.

        // Verify: Verify warnings for blank Payment method, Transport Method and Service Tariff No. on the Report Sales Document test.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorTextLbl, StrSubstNo(ValueMustSpecifiedErrorMsg, SalesHeader.FieldCaption("Payment Method Code")));
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorTextLbl, StrSubstNo(ValueMustSpecifiedErrorMsg, SalesHeader.FieldCaption("Transport Method")));
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorTextLbl, StrSubstNo(ServiceTariffMustSpecifiedErrorMsg, SalesLine.FieldCaption("Service Tariff No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvoiceServiceTariffOnVATEntry()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        ServiceTariffNo: Code[20];
    begin
        // Setup: Create Sales Invoice with EU Customer.
        Initialize;
        Customer.Get(CreateEUCustomer);
        ServiceTariffNo := CreateSalesDocument(SalesHeader, Customer."No.", true, SalesHeader."Document Type"::Invoice, '');  // TRUE for EU Service.

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Payment Method Code, Service Tariff No and Transport Method of Posted Sales Invoice is successfully updated on VAT Entry.
        SalesInvoiceHeader.Get(DocumentNo);
        FindVATEntry(VATEntry, DocumentNo);
        VATEntry.TestField("Payment Method", SalesInvoiceHeader."Payment Method Code");
        VATEntry.TestField("Service Tariff No.", ServiceTariffNo);
        VATEntry.TestField("Transport Method", SalesInvoiceHeader."Transport Method");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceTransportMethodBlankError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Sales Invoice with EU Customer. Update Payment method, Transport Method and Service Tariff No. - Blank.
        Initialize;
        CreateSalesDocument(SalesHeader, CreateEUCustomer, true, SalesHeader."Document Type"::Invoice, '');  // TRUE for EU Service.
        UpdateSalesHeader(SalesHeader, '', '', '');  // Payment method, Transport Method, Service Tariff No. - Blank.

        // Exercise: Post Sales Invoice.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify expected error: Transport Method must have a value in Sales Header.
        Assert.ExpectedError(TransportMethodErr);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDocNoInIntrastatJnlLine()
    var
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Vendor: Record Vendor;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376261] If you use the Get Entries function in the Intrastat Journal page for entries created with a purchase of EU services the Document No. field should be filled with Invoice No

        Initialize;

        // [GIVEN] Posted Purchase Invoice with VAT Setup having Reverse Charge "VAT Posting Type" and No = XXX, "Posting Date" = 10.11.12 and "EU Service" = TRUE
        Vendor.Get(CreateEUVendor);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Modify(true);

        CreatePurchaseDocument(PurchaseHeader, Vendor."No.", PurchaseHeader."Document Type"::Invoice, true, ''); // EU Service - True.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Intrastat Journal Batch with "Statistics Period" = 1211
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);  // EU Service - True.

        // [WHEN] Run "Get Entries" action for created Batch
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.

        // [THEN] Line is created in Intrastat Journal with "Document No." = XXX
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.RecordCount(IntrastatJnlLine, 1);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoiceFalse()
    begin
        VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoice(false);  // Shipment on Invoice  False on Sales & Receivables Setup.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoiceTrue()
    begin
        VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoice(true);  // Shipment on Invoice  True on Sales & Receivables Setup.
    end;

    local procedure VATRegistrationNoOnIntrastatJnlLineShipmentOnInvoice(ShipmentOnInvoice: Boolean)
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
    begin
        // Setup & Exercise: Update Shipment on Invoice on Sales & Receivables Setup. Create and Post Sales Invoice. Create Intrastat Journal Batch. Get Entries on Intrastat Journal.
        Initialize;
        UpdateSalesReceivablesSetupShipmentOnInvoice(ShipmentOnInvoice);
        Customer.Get(CreateEUCustomer);
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document date - Workdate.

        // Verify: Verify VAT Registration from Sales Invoice Customer also updated on Intrastat Journal Line.
        VerifyIntrastatJnlLineVATRegistrationNo(IntrastatJnlBatch.Name, DocumentNo, Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoiceTrue()
    begin
        VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoice(true);  // Receipt on Invoice True on Purchases & Payables Setup
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoiceFalse()
    begin
        VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoice(false);  // Receipt on Invoice False on Purchases & Payables Setup
    end;

    local procedure VATRegistrationNoOnIntrastatJnlLineReceiptOnInvoice(ReceiptOnInvoice: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup & Exercise: Update Receipt on Invoice on Purchases & Payables Setup. Create and Post Purchase Invoice. Create Intrastat Journal Batch. Get Entries on Intrastat Journal.
        Initialize;
        UpdatePurchasesPayablesSetupReceiptOnInvoice(ReceiptOnInvoice);
        Vendor.Get(CreateEUVendor);
        DocumentNo :=
          CreatePurchaseInvoiceIntrastatSetup(IntrastatJnlBatch, Vendor."No.", Vendor."No.", IntrastatJnlBatch.Type::Purchases, true, true);  // EU Service and VAT Posting Setup EU Service - TRUE.

        // Verify: Verify VAT Registration from Purchase Invoice Customer also updated on Intrastat Journal Line.
        VerifyIntrastatJnlLineVATRegistrationNo(IntrastatJnlBatch.Name, DocumentNo, Vendor."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmountIntrastatJnlLinePurchaseInvoiceEUServiceTrue()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchInvLine: Record "Purch. Inv. Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup & Exercise: Create and Post Purchase Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal.
        Initialize;
        Vendor.Get(CreateEUVendor);
        DocumentNo :=
          CreatePurchaseInvoiceIntrastatSetup(IntrastatJnlBatch, Vendor."No.", Vendor."No.", IntrastatJnlBatch.Type::Purchases, true, true);  // EU Service and VAT Posting Setup EU Service - TRUE.

        // Verify: Verify correct Amount of Purchase Invoice updated on Intrastat Journal Line, when EU Service is True on Intrastat Journal Batch.
        FindPurchaseInvoiceLine(PurchInvLine, DocumentNo);
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, PurchInvLine.Amount);
        VerifyIntrastatJnlLineDateWithPurchInvoiceDocumentDate(DocumentNo, IntrastatJnlBatch.Name);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineEmptyPurchaseInvoiceEUServiceFalse()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // Verify Intrastat Journal Line not created for EU vendor Purchase Invoice, when EU Service is FALSE on Intrastat Journal Batch.
        IntrastatJnlLineEmptyPurchaseInvoiceWithJournalBatchType(IntrastatJnlBatch.Type::Purchases, false);  // EU Service - FALSE.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineEmptyPurchaseInvoiceWithTypeSales()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // Verify Intrastat Journal Line not created for Intrastat Journal Batch Type Sales EU Service TRUE.
        IntrastatJnlLineEmptyPurchaseInvoiceWithJournalBatchType(IntrastatJnlBatch.Type::Sales, true);  // EU Service - TRUE.
    end;

    local procedure IntrastatJnlLineEmptyPurchaseInvoiceWithJournalBatchType(Type: Option; EUService: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup: Create EU Vendor.
        Initialize;
        Vendor.Get(CreateEUVendor);

        // Exercise: Create and Post Purchase Invoice. Create Intrastat Journal Batch with different Type. Get Entries on Intrastat Journal.
        DocumentNo := CreatePurchaseInvoiceIntrastatSetup(IntrastatJnlBatch, Vendor."No.", Vendor."No.", Type, EUService, true);  // VAT Posting Setup EU Service - TRUE.

        // Verify: Verify Intrastat Journal Line not created for Intrastat Journal Batch Type and EU Service.
        VerifyIntrastatJnlLineEmpty(IntrastatJnlBatch.Name, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmountIntrastatJnlLineSalesInvoiceEUServiceTrue()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
    begin
        // Setup & Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal
        Initialize;
        Customer.Get(CreateEUCustomer);
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify correct Amount of Sales Invoice updated on Intrastat Journal Line, when EU Service is True on Intrastat Journal Batch.
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, -SalesInvoiceLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineEmptySalesInvoiceEUServiceFalse()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
    begin
        // Setup & Exercise : Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service FALSE. Get Entries on Intrastat Journal
        Initialize;
        Customer.Get(CreateEUCustomer);
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", false, true, WorkDate);  // EU Service - FALSE, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify Intrastat Journal Line not created for EU Customer Sales Invoice, when EU Service is false on Intrastat Journal Batch.
        VerifyIntrastatJnlLineEmpty(IntrastatJnlBatch.Name, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CountryCodeOnIntrastatJnlLineWithCustomerShipToAddress()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ShipToAddress: Record "Ship-to Address";
        DocumentNo: Code[20];
    begin
        // Verify Country/Region Code on Intrastat Jnl. Line updated from Customer's Ship-to Address.

        // Setup: Create and Post Sales Invoice.
        Initialize;
        CreateCustomerShipToAddress(ShipToAddress);

        // Exercise: Create Intrastat Journal Batch and Get Entries on Intrastat Journal.
        DocumentNo :=
          CreateSalesInvoiceIntrastatSetup(
            IntrastatJnlBatch, ShipToAddress."Customer No.", ShipToAddress."Customer No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify Country/Region Code on Intrastat Jnl. Line updated from Customer's Ship-to Address.
        VerifyIntrastatJnlLineCountryRegionCode(IntrastatJnlBatch.Name, DocumentNo, ShipToAddress."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineCorrectiveEntryError()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ShipToAddress: Record "Ship-to Address";
    begin
        // Verify Corrective Entry error while updating Corrective Entry on Intrastat Journal Batch.

        // Setup: Create and Post Sales Invoice. Create Intrastat Journal Batch and Get Entries on Intrastat Journal.
        Initialize;
        CreateCustomerShipToAddress(ShipToAddress);
        CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, ShipToAddress."Customer No.", ShipToAddress."Customer No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Exercise.
        asserterror IntrastatJnlBatch.Validate("Corrective Entry", true);

        // Verify: Verify Corrective Entry error while updating Corrective Entry on Intrastat Journal Batch.
        Assert.ExpectedError(StrSubstNo(CorrectiveEntryErr, IntrastatJnlBatch.Name));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineEUServiceError()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ShipToAddress: Record "Ship-to Address";
    begin
        // Verify EU Service error while updating EU Service on Intrastat Journal Batch.

        // Setup: Create and Post Sales Invoice. Create Intrastat Journal Batch and Get Entries on Intrastat Journal.
        Initialize;
        CreateCustomerShipToAddress(ShipToAddress);
        CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, ShipToAddress."Customer No.", ShipToAddress."Customer No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Exercise.
        asserterror IntrastatJnlBatch.Validate("EU Service", false);

        // Verify: Verify EU Service error while updating EU Service on Intrastat Journal Batch.
        Assert.ExpectedError(StrSubstNo(EUServiceErr, IntrastatJnlBatch.Name));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceServiceTariffNo()
    var
        SalesHeader: Record "Sales Header";
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        // Verify message while updating Service Tariff Number on Sales Header.

        // Setup: Create Sales Invoice with EU Customer and update Service Tariff Number.
        Initialize;
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreateSalesDocument(SalesHeader, CreateEUCustomer, true, SalesHeader."Document Type"::Invoice, '');  // VAT Posting Setup EU Service - TRUE.
        SalesHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");

        // Exercise.
        SalesHeader.Modify(true);

        // Verify: Verification done in MessageHandler, Actual message:You have changed Service Tariff No. on the sales header, but it has not been changed on the existing sales lines. You must update the existing sales lines manually.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineSalesInvoiceWithVATEntryEUServiceTrue()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // Verify Amount, Date, Service Tariff No and Transport Method, Payment Method Code of VAT Entry is successfully updated on Intrastat Jnl. Line.

        // Setup.
        Initialize;
        Customer.Get(CreateEUCustomer);

        // Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal.
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify Amount, Date, Service Tariff No and Transport Method, Payment Method Code of VAT Entry is successfully updated on Intrastat Jnl. Line.
        FindVATEntry(VATEntry, DocumentNo);
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatch.Name, DocumentNo);
        IntrastatJnlLine.TestField(Amount, VATEntry.Base);
        IntrastatJnlLine.TestField(Date, VATEntry."Operation Occurred Date");
        IntrastatJnlLine.TestField("Service Tariff No.", VATEntry."Service Tariff No.");
        IntrastatJnlLine.TestField("Transport Method", VATEntry."Transport Method");
        IntrastatJnlLine.TestField("Payment Method", VATEntry."Payment Method");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineEUCountryCodeWithEUServiceTrue()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
    begin
        // Verify Country/Region Code is successfully updated on Intrastat Jnl. Line.

        // Setup.
        Initialize;
        Customer.Get(CreateEUCustomer);

        // Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal.
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify Country/Region Code is successfully updated on Intrastat Jnl. Line.
        VerifyIntrastatJnlLineCountryRegionCode(IntrastatJnlBatch.Name, DocumentNo, Customer."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('PurchaseServiceTariffNoMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderServiceTariffNo()
    var
        PurchaseHeader: Record "Purchase Header";
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        // Verify message while updating Service Tariff Number on Purchase Header.

        // Setup: Create Purchase Order with EU Vendor and update Service Tariff Number.
        Initialize;
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, PurchaseHeader."Document Type"::Order, true, '');  // VAT Posting Setup EU Service - TRUE.
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");

        // Exercise.
        PurchaseHeader.Modify(true);

        // Verify: Verification done in MessageHandler, Actual message:You have changed Service Tariff No. on the purchase header, but it has not been changed on the existing purchase lines. You must update the existing purchase lines manually.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATRegNoBuyFromVendorNoOnIntrastatJnlLineReceipt()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify VAT Registration from Buy-from Vendor No. of Purchase Invoice updated on Intrastat Jnl. Line.

        // Setup: Create Vendor.
        Initialize;
        Vendor.Get(CreateEUVendor);

        // Exercise: Create and Post Purchase Invoice. Create Intrastat Journal Batch. Get Entries on Intrastat Journal.
        DocumentNo :=
          CreatePurchaseInvoiceIntrastatSetup(
            IntrastatJnlBatch, Vendor."No.", CreateEUVendor, IntrastatJnlBatch.Type::Purchases, false, false);  // EU Service and VAT Posting Setup EU Service - FALSE.

        // Verify: Verify VAT Registration from Buy-from Vendor No. of Purchase Invoice updated on Intrastat Jnl. Line.
        VerifyIntrastatJnlLineVATRegistrationNo(IntrastatJnlBatch.Name, DocumentNo, Vendor."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATRegNoFromSellToCustomerNoOnIntrastatJnlLineShipment()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify VAT Registration from Sell-to Customer No. of Sales Invoice updated on Intrastat Jnl. Line.

        // Setup: Create Customer.
        Initialize;
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId);
        Customer.Get(CreateEUCustomer);

        // Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch. Get Entries on Intrastat Journal.
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", CreateEUCustomer, false, false, WorkDate);  // EU Service, VAT Posting Setup EU Service - FALSE and Document Date - Workdate.

        // Verify: Verify VAT Registration from Sell-to Customer No. of Sales Invoice updated on Intrastat Jnl. Line.
        VerifyIntrastatJnlLineVATRegistrationNo(IntrastatJnlBatch.Name, DocumentNo, Customer."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalWeightOnIntrastatJournalLine()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
        TotalWeight: Decimal;
    begin
        // Verify that Total Weight on Intrastat Journal Page should be a rounded whole value.

        // Setup.
        Initialize;
        IntrastatJournal.OpenEdit;

        // Exercise: Set values for Quantity and Net Weight on Intrastat Journal Page.
        IntrastatJournal.Quantity.SetValue(LibraryRandom.RandInt(10));
        IntrastatJournal."Net Weight".SetValue(LibraryRandom.RandDec(10, 2));
        TotalWeight := Round(IntrastatJournal."Net Weight".AsDEcimal * IntrastatJournal.Quantity.AsDEcimal, 1);

        // Verify: Verify that Total Weight on Intrastat Journal Page should be a rounded whole value.
        Assert.AreEqual(Format(TotalWeight), IntrastatJournal."Total Weight".Value, ValueMatchMsg);
        IntrastatJournal.Close;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineCountryRegionCodeFromCountryRegion()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
    begin
        // Verify Country/Region Code is successfully updated on Intrastat Jnl. Line from Country/Region's Intrastat Code.

        // Setup.
        Initialize;
        Customer.Get(CreateEUCustomer);
        CountryRegion.Get(Customer."Country/Region Code");

        // Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal.
        DocumentNo := CreateSalesInvoiceIntrastatSetup(IntrastatJnlBatch, Customer."No.", Customer."No.", true, true, WorkDate);  // EU Service, VAT Posting Setup EU Service - TRUE and Document Date - Workdate.

        // Verify: Verify Country/Region Code is successfully updated on Intrastat Jnl. Line from Country/Region's Intrastat Code.
        VerifyIntrastatJnlLineCountryRegionCode(IntrastatJnlBatch.Name, DocumentNo, CountryRegion."Intrastat Code");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,TemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceEntryOnIntrastatJnlLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify that only one line is created from Posted Purchase Invoice on Intrastat Jnl. Line and Posted Purchase Credit Memo line should not found on Intrastat Jnl. Line.

        // Setup: Create and Post Purchase Invoice, Purchase Credit Memo.
        Initialize;
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
        DocumentNo2 := CreateAndPostPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise: Create multiple Intrastat Journal Batch with EU service FALSE and Get Entries on Intrastat Journal.
        CreateMultipleIntrastatJnlBatchAndGetEntries(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases);

        // Verify: Verify that only one line is created from Posted Purchase Invoice on Intrastat Jnl. Line and Posted Purchase Credit Memo line should not found on Intrastat Jnl. Line.
        FindPurchaseInvoiceLine(PurchInvLine, DocumentNo);
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, PurchInvLine.Amount);
        VerifyIntrastatJnlLineEmpty(IntrastatJnlBatch.Name, DocumentNo2);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,TemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceEntryOnIntrastatJnlLine()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify that only one line is created from Posted Sales Invoice on Intrastat Jnl. Line and Posted Sales Credit Memo line should not found on Intrastat Jnl. Line.

        // Setup: Create and Post Sales Invoice, Sales Credit Memo.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice);
        DocumentNo2 := CreateAndPostSalesDocument(SalesHeader."Document Type"::"Credit Memo");

        // Exercise: Create multiple Intrastat Journal Batch with EU service FALSE and Get Entries on Intrastat Journal.
        CreateMultipleIntrastatJnlBatchAndGetEntries(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales);

        // Verify: Verify that only one line is created from Posted Sales Invoice on Intrastat Jnl. Line and Posted Sales Credit Memo line should not found on Intrastat Jnl. Line.
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, SalesInvoiceLine.Amount);
        VerifyIntrastatJnlLineEmpty(IntrastatJnlBatch.Name, DocumentNo2);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAmountOnIntrastatJnlLineFromPurchaseCrMemo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DocumentNo: Code[20];
    begin
        // Verify negative value of Amount should be found on Intrastat Jnl. Line.

        // Setup: Create and Post Purchase Credit Memo and modify Intrastat Journal Batch.
        Initialize;
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, false);  // EU Service - False.
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch, true);  // Corrective Entry - TRUE.

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify negative value of Amount should be found on Intrastat Jnl. Line.
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst;
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, -PurchCrMemoLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DateOnIntrastatJnlLineFromSalesInvoiceDocumentDate()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DocumentNo: Code[20];
    begin
        // Verify correct Date updated on Intrastat Journal Line from Sales Invoice Document Date, when EU Service is True on Intrastat Journal Batch.

        // Setup.
        Initialize;
        Customer.Get(CreateEUCustomer);

        // Exercise: Create and Post Sales Invoice. Create Intrastat Journal Batch with EU service TRUE. Get Entries on Intrastat Journal
        DocumentNo :=
          CreateSalesInvoiceIntrastatSetup(
            IntrastatJnlBatch, Customer."No.", Customer."No.", true, true,
            CalcDate('<' + Format(-LibraryRandom.RandInt(10)) + 'D>', WorkDate));  // EU Service and VAT Posting Setup EU Service - TRUE and Document date before Workdate.

        // Verify: Verify correct Date updated on Intrastat Journal Line from Sales Invoice Document Date, when EU Service is TRUE on Intrastat Journal Batch.
        VerifyIntrastatJnlLineDateWithSalesInvoiceDocumentDate(DocumentNo, IntrastatJnlBatch.Name);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLinePurchaseInvoiveWithMultipleLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that only one Intrastat line created for two lines of Purchase Invoice.

        IntrastatJnlLineDocumentTypeMultiplePurchaseLines(PurchaseHeader."Document Type"::Invoice, false, 1);  // Corrective Entry - FALSE.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLinePurchaseCreditMemoWithMultipleLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that only one Intrastat line created for two lines of Purchase Credit Memo.

        IntrastatJnlLineDocumentTypeMultiplePurchaseLines(PurchaseHeader."Document Type"::"Credit Memo", false, -1);  // Corrective Entry - FALSE.
    end;

    local procedure IntrastatJnlLineDocumentTypeMultiplePurchaseLines(DocumentType: Enum "Purchase Document Type"; CorrectiveEntry: Boolean; SignMultiplier: Integer)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that only one Intrastat line created for two lines of Purchase Document.

        // Setup: Create and Post Purchase Document with multiple lines and create Intrastat Journal Batch.
        Initialize;
        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, DocumentType, true, '');  // EU Service - TRUE.
        Amount := FindAndCreatePurchaseLine(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);  // EU Service - TRUE.
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch, CorrectiveEntry);

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify that only one Intrastat line created for two lines of Purchase Document.
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, SignMultiplier * Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineSalesInvoiceWithMultipleLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that only one Intrastat line created for two lines of Sales Invoice.

        IntrastatJnlLineDocumentTypeMultipleSalesLines(SalesHeader."Document Type"::Invoice, false, -1);  // Corrective Entry - FALSE.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineSalesCreditMemoWithMultipleLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify that only one Intrastat line created for two lines of Sales Credit Memo.

        IntrastatJnlLineDocumentTypeMultipleSalesLines(SalesHeader."Document Type"::"Credit Memo", false, 1);  // Corrective Entry - FALSE.
    end;

    local procedure IntrastatJnlLineDocumentTypeMultipleSalesLines(DocumentType: Enum "Sales Document Type"; CorrectiveEntry: Boolean; SignMultiplier: Integer)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that only one Intrastat line created for two lines of Sales Document.

        // Setup: Create and Post Sales Document with multiple lines and create Intrastat Journal Batch.
        Initialize;
        CreateSalesDocument(SalesHeader, CreateEUCustomer, true, DocumentType, '');  // EU Service - TRUE.
        Amount := FindAndCreateSalesLine(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, true);  // EU Service - TRUE.
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch, CorrectiveEntry);

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.

        // Verify: Verify that only one Intrastat line created for two lines of Sales Document.
        VerifyIntrastatJnlLine(IntrastatJnlBatch.Name, DocumentNo, SignMultiplier * Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CountryOfPaymentCodeFromVendorCountryRegionCode()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify that Country/Region of Payment Code on Intrastat Jnl. Line must updated from Vendor's Country/Region Code.

        // Setup: Create Vendor, create and post Purchase Invoice and create Intrastat Journal Batch.
        Initialize;
        Vendor.Get(CreateEUVendor);

        // Exercise: Create and Post Purchase Invoice. Create Intrastat Journal Batch with Type Purchase. Get Entries on Intrastat Journal.
        DocumentNo :=
          CreatePurchaseInvoiceIntrastatSetup(
            IntrastatJnlBatch, Vendor."No.", Vendor."No.", IntrastatJnlBatch.Type::Purchases, true, true);  // VAT Posting Setup EU Service and EU Service - TRUE.

        // Verify: Verify that Country/Region of Payment Code on Intrastat Jnl. Line must updated from Vendor's Country/Region Code.
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatch.Name, DocumentNo);
        IntrastatJnlLine.TestField("Country/Region of Payment Code", Vendor."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignementSaleModalPageHandler,GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLineSalesInvoiceWithItemCharge()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
        i: Integer;
        ItemNo11: Code[20];
        ItemNo12: Code[20];
        ItemNo31: Code[20];
        ItemNo32: Code[20];
    begin
        // Verify that count of Intrastat lines matches count of Sales Invoices.
        // Setup: Create and Post Sales Document with multiple lines and create Intrastat Journal Batch.
        Initialize;

        for i := 1 to 3 do begin
            CreateSalesDocument(SalesHeader, CreateEUCustomer, false, SalesHeader."Document Type"::Invoice, '');
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo, 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
            SalesLine.Modify(true);
            SalesLine.ShowItemChargeAssgnt();

            if i = 1 then begin
                ItemNo12 := SalesLine."No.";
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.FindFirst;
                ItemNo11 := SalesLine."No.";
            end;

            if i = 3 then begin
                ItemNo32 := SalesLine."No.";
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.FindFirst;
                ItemNo31 := SalesLine."No.";
            end;

            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch, false);

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;

        // Verify: Verify that only one Intrastat line created for two lines of Sales Document.
        DummyIntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        DummyIntrastatJnlLine.SetRange("Item No.", ItemNo11, ItemNo31);
        Assert.RecordCount(DummyIntrastatJnlLine, 3);

        DummyIntrastatJnlLine.Reset();
        DummyIntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        DummyIntrastatJnlLine.SetRange("Item No.", ItemNo12, ItemNo32);
        Assert.RecordIsEmpty(DummyIntrastatJnlLine);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler,MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskNoErrorOnSecondRun()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename1: Text;
        Filename2: Text;
    begin
        Initialize;

        // Setup. EU Service = FALSE, Corrective = FALSE
        CreateAndPrepareIntrastatJnlLine(
          IntrastatJnlLine, false, false, FindOrCreateIntrastatTransactionType, IntrastatJnlBatchType::Purchase, WorkDate);
        Commit();
        Filename1 := FileManagement.ServerTempFileName('txt');
        Filename2 := FileManagement.ServerTempFileName('txt');

        // Exercise
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(Filename1);
        Commit();
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(Filename2);

        // Verify
        Assert.IsTrue(FileManagement.ServerFileExists(Filename1), FileNotCreatedErr);
        Assert.IsTrue(FileManagement.ServerFileExists(Filename2), FileNotCreatedErr);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskErrorOnBlankTransactionType()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Filename: Text;
    begin
        Initialize;

        // Setup. EU Service = FALSE, Corrective = FALSE
        CreateAndPrepareIntrastatJnlLine(IntrastatJnlLine, false, false, '', IntrastatJnlBatchType::Purchase, WorkDate);
        Filename := FileManagement.ServerTempFileName('txt');

        // Exercise
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        asserterror RunIntrastatMakeDiskTaxAuth(Filename);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transaction Type"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceExportDocNoAndDocDate()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
    begin
        // [FEATURE] [Export] [EU Service]
        // [SCENARIO 412962] Intrastat journal line export in case of EU Service
        Initialize();
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);

        // [GIVEN] Intrastat journal line (batch "EU Service" = true) with "Partner VAT ID" = "X"
        CreateIntrastatJournalBatchWithCorrective(
           IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, false, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');

        // [WHEN] Export Intrastat journal to file
        FileName := FileManagement.ServerTempFileName('txt');
        Commit();
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Partner VAT ID is exported with "X" value
        VerifyDocNoDocDate(
            FileName, IntrastatJnlLine."Document No.", IntrastatJnlLine.Date, false, IntrastatJnlLine."Partner VAT ID");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitPriceAfterSalesOrder()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Unit Price" after Sales Order posting with Quantity = 1
        // [FEATURE] [Sales] [Order]
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, false, false, IntrastatJnlBatchType::Sales);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, WorkDate);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch, Item."No.", 1, Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitPriceAfterSalesReturnOrder()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Unit Price" after Sales Return Order posting with Quantity = 1
        // [FEATURE] [Sales] [Return Order]
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, false, true, IntrastatJnlBatchType::Sales);

        // [GIVEN] Item with "Unit Price" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Sales Return Order with Quantity = 1
        CreateAndPostSalesDoc(SalesHeader."Document Type"::"Return Order", CreateForeignCustomerNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, WorkDate);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch, Item."No.", -1, -Item."Unit Price");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitCostAfterPurchaseOrder()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Last Direct Cost" after Purchase Order posting with Quantity = 1
        // [FEATURE] [Purchase] [Order]
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, false, false, IntrastatJnlBatchType::Purchase);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, WorkDate);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch, Item."No.", 1, Item."Last Direct Cost");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatAmountIsUnitCostAfterPurchaseReturnOrder()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        // [SCENARIO 362690] Intrastat Journal Line Amount = Item."Last Direct Cost" after Purchase Return Order posting with Quantity = 1
        // [FEATURE] [Purchase] [Return Order]
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, false, false, IntrastatJnlBatchType::Purchase);

        // [GIVEN] Item with "Last Direct Cost" = "X"
        CreateItemWithTariffNo(Item);

        // [GIVEN] Create Post Purchase Return Order with Quantity = 1
        CreateAndPostPurchDoc(PurchaseHeader."Document Type"::Order, CreateForeignVendorNo, Item."No.", 1);

        // [WHEN] Run Intrastat "Get Item Ledger Entries" report
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, WorkDate);

        // [THEN] Intrastat Journal Line Amount = "X"
        VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch, Item."No.", 1, Item."Last Direct Cost");
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceCorrectiveExportDocNoAndDocDate()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        CorrIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
    begin
        // [FEATURE] [Export] [EU Service] [Corrective]
        // [SCENARIO 412962] Intrastat journal line export in case of EU Service and Corrective
        Initialize();
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);

        // [GIVEN] Intrastat journal line (batch "EU Service" = true, "Corrective Entry" = true) with "Partner VAT ID" = "X"
        CreateIntrastatJournalBatchWithCorrective(
            CorrIntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, true, IntrastatJnlBatchType::Purchase);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, false, IntrastatJnlBatchType::Purchase);

        // Create firstly Initial Doc, then Corrective Doc. The order is important here
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, CorrIntrastatJnlBatch, IntrastatJnlLine."Document No.", IntrastatJnlBatch.Name);

        // [WHEN] Export Intrastat journal to file
        FileName := FileManagement.ServerTempFileName('txt');
        Commit();
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Partner VAT ID is exported with "X" value
        VerifyDocNoDocDate(
            FileName, IntrastatJnlLine."Corrected Document No.", IntrastatJnlLine.Date, true, IntrastatJnlLine."Partner VAT ID");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceOrderIntrastatJournal()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Qty: Decimal;
        Amt: Decimal;
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize;
        CreateAndPostServiceOrder(Qty, Amt, ItemNo, CreateCustomer);

        // Exercise: Run Intrastat Journal - Get Entries.
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, false, false, IntrastatJnlBatchType::Purchase);
        IntrastatJnlBatch.Validate(Type, IntrastatJnlBatch.Type::Sales);
        IntrastatJnlBatch.Modify(true);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, WorkDate);

        // Verify.
        VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch, ItemNo, Qty, Amt);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceCorrectiveMandatoryProgressiveNo()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        DummyIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        CorrIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
    begin
        // Verify Progressive No. must be filled before export in case of EU Service = TRUE, Corrective = TRUE
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          CorrIntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, true, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(
          IntrastatJnlLine, CorrIntrastatJnlBatch, IntrastatJnlLine."Document No.", DummyIntrastatJnlBatch.Name);

        IntrastatJnlLine."Progressive No." := '';
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        asserterror RunIntrastatMakeDiskTaxAuth(FileName);
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Progressive No."), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceCorrectiveProgressiveNo()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        DummyIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        CorrIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
    begin
        // Verify exported Progressive No. in case of EU Service = TRUE, Corrective = TRUE
        Initialize;
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          CorrIntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, true, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(
          IntrastatJnlLine, CorrIntrastatJnlBatch, IntrastatJnlLine."Document No.", DummyIntrastatJnlBatch.Name);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        VerifyProgressiveNo(FileName, IntrastatJnlLine."Progressive No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceGenerateTwoLinesForDiffTariffNo()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        LinesCount: Integer;
        ExpectedAmount: Decimal;
        PostedPurchDocNo: Code[20];
    begin
        // Verify Get Entries function generates as many line as needed when Purch.Invoice has different Service Tariff Nos in each line

        // Setup
        Initialize;
        LinesCount := LibraryRandom.RandIntInRange(2, 5);
        ExpectedAmount := CreatePostPurchInvoiceDiffTariffNo(LinesCount, WorkDate, PostedPurchDocNo);

        // Exercise
        CreateAndPrepareIntrastatJnlLine(
          IntrastatJnlLine, true, false, FindOrCreateIntrastatTransactionType, IntrastatJnlBatchType::Purchase, WorkDate);

        // Verify
        VerifyIntrastatJnlLines(LinesCount, ExpectedAmount, IntrastatJnlLine, PostedPurchDocNo);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesWithQueueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestEUServiceGenerateTwoLinesForDiffTariffNoSales()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        LinesCount: Integer;
        ExpectedAmount: Decimal;
        PostedSalesDocNo: Code[20];
    begin
        // Verify Get Entries function generates as many line as needed when Purch.Invoice has different Service Tariff Nos in each line

        // Setup
        Initialize;
        LinesCount := LibraryRandom.RandIntInRange(2, 5);
        ExpectedAmount := -CreatePostSalesInvoiceDiffTariffNo(LinesCount, WorkDate, PostedSalesDocNo);

        // Exercise
        CreateAndPrepareIntrastatJnlLine(
          IntrastatJnlLine, true, false, FindOrCreateIntrastatTransactionType, IntrastatJnlBatchType::Sales, WorkDate);

        // Verify
        VerifyIntrastatJnlLines(LinesCount, ExpectedAmount, IntrastatJnlLine, PostedSalesDocNo);
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatExportPmtCountry()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        TextLine: Text;
        Country: Text;
    begin
        // [SCENARIO 376132] Last value of Intrastat export result (scambi.cee file) should be payment country
        Initialize;

        // [GIVEN] Created Intrastat Journal Line having "Country/Region of Payment Code" of "XX"
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, false, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        IntrastatJnlLine."Country/Region of Payment Code" := 'XX';
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Exporting Intrastat (Report 593 - Intrastat - Make Disk Tax Auth)
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Last value of exported file is "XX" ("Country/Region of Payment Code")
        TextLine := ReadTxtLineFromFile(FileName, 1);
        Evaluate(Country, CopyStr(TextLine, StrLen(TextLine) - 1, 2));
        Assert.AreEqual(IntrastatJnlLine."Country/Region of Payment Code", Country, WrongPmtCountryErr);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AmountInComplexIntrastatLineAfterRepeatativeGettingEntries()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ServiceTariffNumber: array[2] of Record "Service Tariff Number";
        PurchaseLine: array[3] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Service Tariff Number]
        // [SCENARIO 379201] If several lines of posted document are united in one Intrastat Line because of the same Service Tariff No., this Intrastat Line should not change its amount after reiterative pressing "Get Entries" button

        Initialize;

        // [GIVEN] Posted Purchase Invoice with 3 Lines
        CreatePurchInvHeader(PurchaseHeader, VATPostingSetup);

        // [GIVEN] Purchase Invoice Line 1 with Amount 10 and Service Tariff Number XXX
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber[1]);
        CreateSalesLineWithServiceTariffNo(PurchaseLine[1], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[1]."No.");

        // [GIVEN] Purchase Invoice Line 2 with Amount 50 and Service Tariff Number YYY
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber[2]);
        CreateSalesLineWithServiceTariffNo(PurchaseLine[2], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[2]."No.");

        // [GIVEN] Purchase Invoice Line 3 with Amount 30 and Service Tariff Number XXX
        CreateSalesLineWithServiceTariffNo(PurchaseLine[3], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[1]."No.");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Intrastat Journal Batch
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);  // EU Service - True

        // [GIVEN] Run "Get Entries" action for created Batch
        GetEntriesIntrastatJournal; // Opens GetItemLedgerEntriesRequestPageHandler

        // [GIVEN] Some manual changes in Intrastat Lines:
        // [GIVEN] "Item Description" in Line 1 = ZZ1
        // [GIVEN] "Item Description" in Line 2 = ZZ2
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindSet();
        SetRandomItemDescriptionToIntrastatLine(IntrastatJnlLine);
        IntrastatJnlLine.Next;
        SetRandomItemDescriptionToIntrastatLine(IntrastatJnlLine);

        // [GIVEN] Manually added Intrastat line in the same Batch
        LibraryInventory.CreateItem(Item);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatch, Item);

        // [WHEN] Run "Get Entries" action for created Batch the second time, confirm deletion of existing lines.
        GetEntriesIntrastatJournal; // Opens ConfirmHandler and replies TRUE

        // [THEN] Only 2 Intrastat Lines created for Invoice found in Batch:
        Assert.RecordCount(IntrastatJnlLine, 2);

        // [THEN] The first line, where Tariff Number = 'XXX', Amount = 40
        // [THEN] Manual change vanished from first line ("Item Description" is empty)
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        VerifyIntrastatJnlLineAmountAndItemDescription(
          IntrastatJnlLine, ServiceTariffNumber[1]."No.", PurchaseLine[1]."Direct Unit Cost" + PurchaseLine[3]."Direct Unit Cost", '');

        // [THEN] The second line, where Tariff Number = 'YYY', Amount = 50
        // [THEN] Manual change vanished from second line ("Item Description" is empty)
        VerifyIntrastatJnlLineAmountAndItemDescription(
          IntrastatJnlLine, ServiceTariffNumber[2]."No.", PurchaseLine[2]."Direct Unit Cost", '');
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ConfirmNegativeHandler')]
    [Scope('OnPrem')]
    procedure IntrastatLinesStayUntouchedIfNoDeletionConfirmationOn2ndRun()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ServiceTariffNumber: array[2] of Record "Service Tariff Number";
        PurchaseLine: array[3] of Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        ItemDescription: array[2] of Text[10];
    begin
        // [FEATURE] [Service Tariff Number]
        // [SCENARIO 379201] Intrastat Lines should stay untouched if their deletion was not confirmed after running "Get Entries"

        Initialize;

        // [GIVEN] Posted Purchase Invoice with 3 Lines
        CreatePurchInvHeader(PurchaseHeader, VATPostingSetup);

        // [GIVEN] Purchase Invoice Line 1 with Amount 10 and Service Tariff Number XXX
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber[1]);
        CreateSalesLineWithServiceTariffNo(PurchaseLine[1], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[1]."No.");

        // [GIVEN] Purchase Invoice Line 2 with Amount 50 and Service Tariff Number YYY
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber[2]);
        CreateSalesLineWithServiceTariffNo(PurchaseLine[2], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[2]."No.");

        // [GIVEN] Purchase Invoice Line 3 with Amount 30 and Service Tariff Number XXX
        CreateSalesLineWithServiceTariffNo(PurchaseLine[3], PurchaseHeader, VATPostingSetup, ServiceTariffNumber[1]."No.");

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Intrastat Journal Batch
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);  // EU Service - True.

        // [GIVEN] Run "Get Entries" action for created Batch.
        GetEntriesIntrastatJournal; // Opens GetItemLedgerEntriesRequestPageHandler

        // [GIVEN] Some manual changes in Intrastat Lines:
        // [GIVEN] "Item Description" in Line 1 = ZZ1
        // [GIVEN] "Item Description" in Line 2 = ZZ2
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindSet();
        ItemDescription[1] := SetRandomItemDescriptionToIntrastatLine(IntrastatJnlLine);
        IntrastatJnlLine.Next;
        ItemDescription[2] := SetRandomItemDescriptionToIntrastatLine(IntrastatJnlLine);

        // [GIVEN] Manually added Intrastat line in the same Batch
        LibraryInventory.CreateItem(Item);
        CreateIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatch, Item);

        // [WHEN] Run "Get Entries" action for created Batch the second time, do not confirm deletion of existing lines.
        GetEntriesIntrastatJournal; // Opens ConfirmNegativeHandler and replies FALSE

        // [THEN] Manually created Intrastat Lines found in Batch
        IntrastatJnlLine.SetRange("Document No.");
        IntrastatJnlLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(IntrastatJnlLine, 1);

        // [THEN] 2 Intrastat Lines are related to Invoice:
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.SetRange("Item No.");
        Assert.RecordCount(IntrastatJnlLine, 2);

        // [THEN] "Item Description" of the 1st line is ZZ1
        IntrastatJnlLine.FindSet();
        IntrastatJnlLine.TestField("Item Description", ItemDescription[1]);

        // [THEN] "Item Description" of the 2nd line is ZZ2
        IntrastatJnlLine.Next;
        IntrastatJnlLine.TestField("Item Description", ItemDescription[2]);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLinesInCorrectiveAndNonCorrectiveBatches()
    var
        IntrastatJnlBatch: array[2] of Record "Intrastat Jnl. Batch";
        SalesHeader: array[2] of Record "Sales Header";
        CustomerNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] [Item Charge] [Sales]
        // [SCENARIO 379467] Intrastat should suggest Item Charge Entries from Credit Memos for corrective Batches and should not for non-corrective Batches

        Initialize;

        // [GIVEN] Foreign Customer CCC (e.g. GB)
        CustomerNo := CreateForeignCustomerNo;

        // [GIVEN] Location LLL inside Italy
        LocationCode := CreateLocation;

        // [GIVEN] Posted Sales Credit Memo for Customer CCC with 2 lines
        // [GIVEN] Line 1: Item, Location CCC, Amount = 10
        CreateSalesDocument(SalesHeader[1], CustomerNo, false, SalesHeader[1]."Document Type"::"Credit Memo", LocationCode);
        // [GIVEN] Line 2: Charge (Item), Location CCC, Amount = 1
        CreateSalesLineWithItemChargeAndLocation(SalesHeader[1]);

        SalesHeader[1].CalcFields(Amount);
        LibrarySales.PostSalesDocument(SalesHeader[1], true, true);

        // [GIVEN] Posted Sales Invoice for Customer CCC with 2 lines
        // [GIVEN] Line 1: Item, Location CCC, Amount = 100
        CreateSalesDocument(SalesHeader[2], CustomerNo, false, SalesHeader[2]."Document Type"::Invoice, LocationCode);
        // [GIVEN] Line 2: Charge (Item), Location CCC, Amount = 21
        CreateSalesLineWithItemChargeAndLocation(SalesHeader[2]);

        SalesHeader[2].CalcFields(Amount);
        LibrarySales.PostSalesDocument(SalesHeader[2], true, true);

        // [WHEN] Get Entries on non-corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[1], IntrastatJnlBatch[1].Type::Sales, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[1], false);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[1], false);

        // [WHEN] Get Entries on corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[2], IntrastatJnlBatch[2].Type::Sales, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[2], true);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[2], false);

        // [THEN] 1 line in non-corrective Batch, Amount = 121
        VerifyNumberOfIntrastatLines(IntrastatJnlBatch[1], SalesHeader[2]."Last Posting No.", SalesHeader[1]."Last Posting No.", 1);
        VerifyAmountInIntrastatLine(IntrastatJnlBatch[1].Name, SalesHeader[2]."Last Posting No.", SalesHeader[2].Amount);

        // [THEN] 1 line in corrective Batch, Amount = 11
        VerifyNumberOfIntrastatLines(IntrastatJnlBatch[2], SalesHeader[1]."Last Posting No.", SalesHeader[2]."Last Posting No.", 1);
        VerifyAmountInIntrastatLine(IntrastatJnlBatch[2].Name, SalesHeader[1]."Last Posting No.", -SalesHeader[1].Amount);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLinesInCorrectiveAndNonCorrectiveBatchesForPurch()
    var
        IntrastatJnlBatch: array[2] of Record "Intrastat Jnl. Batch";
        PurchaseHeader: array[2] of Record "Purchase Header";
        VendorNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] [Item Charge] [Purchase]
        // [SCENARIO 379467] Intrastat should suggest Item Charge Entries from Purchase Credit Memos for corrective Batches and should not for non-corrective Batches

        Initialize;

        // [GIVEN] Foreign Vendor VVV (e.g. GB)
        VendorNo := CreateForeignVendorNo;

        // [GIVEN] Location LLL with "Country/Region Code" = 'IT'
        LocationCode := CreateLocation;

        // [GIVEN] Posted Purchase Credit Memo for Vendor VVV with 2 lines
        // [GIVEN] Line 1: Item, Location CCC
        CreatePurchaseDocument(PurchaseHeader[1], VendorNo, PurchaseHeader[1]."Document Type"::"Credit Memo", false, LocationCode);
        // [GIVEN] Line 2: Charge (Item), Location CCC
        CreatePurchaseLineWithItemChargeAndLocation(PurchaseHeader[1]);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, true);

        // [GIVEN] Posted Purchase Invoice for Vendor VVV with 2 lines
        // [GIVEN] Line 1: Item, Location CCC
        CreatePurchaseDocument(PurchaseHeader[2], VendorNo, PurchaseHeader[2]."Document Type"::Invoice, false, LocationCode);
        // [GIVEN] Line 2: Charge (Item), Location CCC
        CreatePurchaseLineWithItemChargeAndLocation(PurchaseHeader[2]);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, true);

        // [WHEN] Get Entries on non-corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[1], IntrastatJnlBatch[1].Type::Purchases, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[1], false);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[1], false);

        // [WHEN] Get Entries on corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[2], IntrastatJnlBatch[2].Type::Purchases, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[2], true);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[2], false);

        // [THEN] Non-corrective Batch contains 1 line about Purchase Invoice and does not contain lines about Purchase Credit Memo
        VerifyNumberOfIntrastatLines(
          IntrastatJnlBatch[1], PurchaseHeader[2]."Last Posting No.", PurchaseHeader[1]."Last Posting No.", 1);

        // [THEN] Corrective Batch contains 1 line about Purchase Credit Memo and does not contain lines about Purchase Invoice
        VerifyNumberOfIntrastatLines(
          IntrastatJnlBatch[2], PurchaseHeader[1]."Last Posting No.", PurchaseHeader[2]."Last Posting No.", 1);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJnlLinesInCorrectiveAndNonCorrectiveBatchesForServices()
    var
        IntrastatJnlBatch: array[2] of Record "Intrastat Jnl. Batch";
        ServiceHeader: array[2] of Record "Service Header";
        CustomerNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] [Item Charge] [Service]
        // [SCENARIO 379467] Intrastat should suggest Item Charge Entries from Service Credit Memos for corrective Batches and should not for non-corrective Batches

        Initialize;

        // [GIVEN] Foreign Customer CCC (e.g. GB)
        CustomerNo := CreateForeignCustomerNo;

        // [GIVEN] Location LLL with "Country/Region Code" = 'IT'
        LocationCode := CreateLocation;

        // [GIVEN] Posted Service Invoice for Customer CCC with 1 line
        // [GIVEN] Line 1: Service Item, Location CCC
        CreateServiceInvoice(ServiceHeader[1], CustomerNo, LocationCode);

        // [GIVEN] Posted Service Credit Memo for Customer CCC with 1 line
        // [GIVEN] Line 1: Item, Location CCC
        CreateServiceCreditMemo(ServiceHeader[2], CustomerNo, LocationCode);

        // [WHEN] Get Entries on non-corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[1], IntrastatJnlBatch[1].Type::Sales, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[1], false);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[1], false);

        // [WHEN] Get Entries on corrective Intrastat Journal with "Show Item Charge entries" = TRUE
        CreateIntrastatJournalBatch(IntrastatJnlBatch[2], IntrastatJnlBatch[2].Type::Sales, false);
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch[2], true);
        GetEntriesForIntrastatBatch(IntrastatJnlBatch[2], false);

        // [THEN] Non-corrective Batch contains 1 line about Service Invoice and does not contain lines about Service Credit Memo
        VerifyNumberOfIntrastatLines(
          IntrastatJnlBatch[1], ServiceHeader[1]."Last Posting No.", ServiceHeader[2]."Last Posting No.", 1);

        // [THEN] Corrective Batch contains 1 line about Service Credit Memo and does not contain lines about Service Invoice
        VerifyNumberOfIntrastatLines(
          IntrastatJnlBatch[2], ServiceHeader[2]."Last Posting No.", ServiceHeader[1]."Last Posting No.", 1);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler,GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntraCommunitySales()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesInvoiceNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379479] Drop shipment Intra-Community sales entry created in the Intrastat Journal by Get Entries function
        Initialize;

        // [GIVEN] Drop shipment sales order for customer with EU country "C1" and item "Item"
        ItemNo := CreateSalesOrdersWithDropShipment(SalesHeader);

        // [GIVEN] Drop shipment purchase order for vendor with EU country "C2"
        CreatePurchOrdersWithDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Post sales order
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Intrastat Journal Batch with Type = Sales
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, false);

        // [WHEN] Get Entries function with checkbox "Include Intra-Community Entries" is being run
        GetEntriesForIntrastatBatch(IntrastatJnlBatch, true);

        // [THEN] Shipment entry is created in the Intrastat Journal with item "Item"
        VerifyIntrastatJnlLineItemNo(IntrastatJnlBatch.Name, SalesInvoiceNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler,GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntraCommunityPurchase()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchInvoiceNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 379479] Drop shipment Intra-Community purchase entry created in the Intrastat Journal by Get Entries function
        Initialize;

        // [GIVEN] Drop shipment sales order for customer with EU country "C1" and item "Item"
        ItemNo := CreateSalesOrdersWithDropShipment(SalesHeader);

        // [GIVEN] Drop shipment purchase order for vendor with EU country "C2"
        CreatePurchOrdersWithDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Post sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Post purchase order
        PurchaseHeader.Find;
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Intrastat Journal Batch with Type = Purchase
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, false);

        // [WHEN] Get Entries function with checkbox "Include Intra-Community Entries" is being run
        GetEntriesForIntrastatBatch(IntrastatJnlBatch, true);

        // [THEN] Receipt entry is created in the Intrastat Journal with item "Item"
        VerifyIntrastatJnlLineItemNo(IntrastatJnlBatch.Name, PurchInvoiceNo, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportPmtCountryMultiLines()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine1: Record "Intrastat Jnl. Line";
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        TextLine: Text;
        Country: Text;
        LenCountryCode: Integer;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 220495] On export Intrastat Jnl. Lines to file via report 593 "Country/Region of Payment Code" in the end of each line
        Initialize;
        LenCountryCode := 2;

        // [GIVEN] Two Intrastat Jnl. Lines with "XX" and "XY" values in "Country/Region of Payment Code" fields
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, false, IntrastatJnlBatchType::Purchase);

        MockIntrastatJnlLineWithCountryRegion(IntrastatJnlLine1, IntrastatJnlBatch, LenCountryCode);
        MockIntrastatJnlLineWithCountryRegion(IntrastatJnlLine2, IntrastatJnlBatch, LenCountryCode);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via "Run Intrastat - Make Disk Tax Auth" report
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine2."Journal Template Name", IntrastatJnlLine2."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] First line of exported file contains "XX" in the end of line
        TextLine := ReadTxtLineFromFile(FileName, 1);
        Evaluate(Country, CopyStr(TextLine, StrLen(TextLine) - 1, LenCountryCode));
        Assert.AreEqual(IntrastatJnlLine1."Country/Region of Payment Code", Country, WrongPmtCountryErr);

        // [THEN] Second line of exported file contains "XY" in the end of line
        TextLine := ReadTxtLineFromFile(FileName, 2);
        Evaluate(Country, CopyStr(TextLine, StrLen(TextLine) - 1, LenCountryCode));
        Assert.AreEqual(IntrastatJnlLine2."Country/Region of Payment Code", Country, WrongPmtCountryErr);

        Erase(FileName);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesRoundAmountAndStatValueGroupedLines()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 227457] Export rounded amounts, statistical values and total amount of two similar Intrastat Journal Lines with EU Service = FALSE and Corrective Entry = FALSE
        Initialize;

        // [GIVEN] Intrastat Journal Line[1] with Amount = Statistical Value = 0.01
        // [GIVEN] Intrastat Journal Line[2] copied from Intrastat Journal Line[1]
        // [GIVEN] Intrastat Journal Line[2] Amount and Statistical Value being changed to 1.49
        // [GIVEN] EU Service = FALSE and Corrective Entry = FALSE
        MockIntrastatJnlLinesWithAmountAndStatisticalValueForGrouping(IntrastatJnlLine, false, false);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine[2]."Journal Template Name", IntrastatJnlLine[2]."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to ROUND(Line[1].Amount  + Line[2].Amount) = ROUND(0.01 + 1.49) = 2
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount + IntrastatJnlLine[2].Amount, 1)), 13), 1, 64, 13, 0);

        // [THEN] Amount in file on the 1st line equals to ROUND(Line[1].Amount  + Line[2].Amount) = ROUND(0.01 + 1.49) = 2
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount + IntrastatJnlLine[2].Amount, 1)), 13), 1, 175, 13, 0);

        // [THEN] Statistical Value in file on the 1st line equals to ROUND(Line[1]."Statistical Value" + Line[2]."Statistical Value") = ROUND(0.01 + 1.49) = 2
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(
            Format(Round(IntrastatJnlLine[1]."Statistical Value" + IntrastatJnlLine[2]."Statistical Value", 1)), 13), 1, 217, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesRoundAmountAndStatlValue()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 227457] Export rounded amounts, statistical values and total amount of two Intrastat Journal Lines with EU Service = FALSE and Corrective Entry = FALSE
        Initialize;

        // [GIVEN] Intrastat Journal Line[1] with Amount = Statistical Value = 0.01
        // [GIVEN] Intrastat Journal Line[2] with Amount = Statistical Value = 1.49
        // [GIVEN] EU Service = FALSE and Corrective Entry = FALSE
        MockIntrastatJnlLinesWithAmountAndStatisticalValue(IntrastatJnlLine, false, false, WorkDate);
        ModifyIntrastatJnlLinesTariffAndTotalWeight(IntrastatJnlLine);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine[2]."Journal Template Name", IntrastatJnlLine[2]."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to ROUND(Line[1].Amount)  + ROUND(Line[2].Amount) = ROUND(0.01) + ROUND(1.49) = 1
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1) + Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 64, 13, 0);

        // [THEN] Amount in file on the 1st line equals to ROUND(Line[1].Amount) = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1)), 13), 1, 175, 13, 0);

        // [THEN] Amount in file on the 2nd line equals to ROUND(Line[2].Amount) = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 280, 13, 0);

        // [THEN] Statistical Value in file on the 1st line equals to ROUND(Line[1]."Statistical Value") = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1]."Statistical Value", 1)), 13), 1, 217, 13, 0);

        // [THEN] Statistical Value in file on the 2nd line equals to ROUND(Line[2]."Statistical Value") = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2]."Statistical Value", 1)), 13), 1, 322, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesRoundAmountAndStatValueWithCorrectiveEntry()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 227457] Export rounded amounts, statistical values and total amount of two Intrastat Journal Lines with EU Service = FALSE and Corrective Entry = TRUE
        Initialize;

        // [GIVEN] Intrastat Journal Line[1] with Amount = 0.01
        // [GIVEN] Intrastat Journal Line[2] with Amount = 1.49
        // [GIVEN] EU Service = FALSE and Corrective Entry = TRUE
        MockIntrastatJnlLinesWithAmountAndStatisticalValue(IntrastatJnlLine, false, true, CalcDate('<+1M>', WorkDate));
        ModifyIntrastatJnlLinesTariffAndTotalWeight(IntrastatJnlLine);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine[2]."Journal Template Name", IntrastatJnlLine[2]."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to ROUND(Line[1].Amount)  + ROUND(Line[2].Amount) = ROUND(0.01) + ROUND(1.49) = 1
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1) + Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 82, 13, 0);

        // [THEN] Amount in file on the 1st line equals to ROUND(Line[1].Amount) = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1)), 13), 1, 181, 13, 0);

        // [THEN] Amount in file on the 2nd line equals to ROUND(Line[2].Amount) = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 266, 13, 0);

        // [THEN] Statistical Value in file on the 1st line equals to ROUND(Line[1]."Statistical Value") = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1]."Statistical Value", 1)), 13), 1, 203, 13, 0);

        // [THEN] Statistical Value in file on the 2nd line equals to ROUND(Line[2]."Statistical Value") = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2]."Statistical Value", 1)), 13), 1, 288, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesRoundAmountWithEUService()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 227457] Export rounded amounts, statistical values and total amount of two Intrastat Journal Lines with EU Service = TRUE and Corrective Entry = FALSE
        Initialize;

        // [GIVEN] Intrastat Journal Line[1] with Amount = 0.01
        // [GIVEN] Intrastat Journal Line[2] with Amount = 1.49
        // [GIVEN] EU Service = TRUE and Corrective Entry = FALSE
        MockIntrastatJnlLinesWithAmountAndStatisticalValue(IntrastatJnlLine, true, false, WorkDate);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine[2]."Journal Template Name", IntrastatJnlLine[2]."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to ROUND(Line[1].Amount)  + ROUND(Line[2].Amount) = ROUND(0.01) + ROUND(1.49) = 1
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1) + Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 100, 13, 0);

        // [THEN] Amount in file on the 1st line equals to ROUND(Line[1].Amount) = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1)), 13), 1, 175, 13, 0);

        // [THEN] Amount in file on the 2nd line equals to ROUND(Line[2].Amount) = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 263, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesRoundAmountWithEUServiceAndCorrectiveEntry()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 227457] Export rounded amounts, statistical values and total amount of two Intrastat Journal Lines with EU Service = TRUE and Corrective Entry = TRUE
        Initialize;

        // [GIVEN] Intrastat Journal Line[1] with Amount = 0.01
        // [GIVEN] Intrastat Journal Line[2] with Amount = 1.49
        // [GIVEN] EU Service = TRUE and Corrective Entry = TRUE
        MockIntrastatJnlLinesWithAmountAndStatisticalValue(IntrastatJnlLine, true, true, WorkDate);

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine[2]."Journal Template Name", IntrastatJnlLine[2]."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to ROUND(Line[1].Amount)  + ROUND(Line[2].Amount) = ROUND(0.01) + ROUND(1.49) = 1
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1) + Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 118, 13, 0);

        // [THEN] Amount in file on the 1st line equals to ROUND(Line[1].Amount) = ROUND(0.01) = 0
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[1].Amount, 1)), 13), 1, 194, 13, 0);

        // [THEN] Amount in file on the 2nd line equals to ROUND(Line[2].Amount) = ROUND(1.49) = 1
        LibrarySpesometro.VerifyValue(
          TextFile, FormatNum(Format(Round(IntrastatJnlLine[2].Amount, 1)), 13), 1, 301, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesServiceTariffNoSixChars()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 280801] "Service Tariff No." field of Intrastat Journal Line is cut to first 5 chars, then filled with trailing zeros up to 6 chars, when exported to file.
        Initialize;

        // [GIVEN] Intrastat Journal Line with "Service Tariff No." = "123456", length is 6 symbols.
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        IntrastatJnlLine."Service Tariff No." := Format(LibraryRandom.RandIntInRange(100000, 999999));
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] "Service Tariff No." in the file equals to "123450".
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, PadStr(CopyStr(IntrastatJnlLine."Service Tariff No.", 1, 5), 6, '0'), 1, 222, 6, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesServiceTariffNoFourChars()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileManagement: Codeunit "File Management";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 280801] "Service Tariff No." field of Intrastat Journal Line is filled with trailing zeros up to 6 chars, when exported to file.
        Initialize;

        // [GIVEN] Intrastat Journal Line with "Service Tariff No." = "1234", length is 4 symbols.
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        IntrastatJnlLine."Service Tariff No." := Format(LibraryRandom.RandIntInRange(1000, 9999));
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] "Service Tariff No." in the file equals to "123400".
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(
          TextFile, PadStr(CopyStr(IntrastatJnlLine."Service Tariff No.", 1, 5), 6, '0'), 1, 222, 6, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegNoCountryRegionInIntrastatJnlLine()
    var
        Customer: Record Customer;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DummyQty: Decimal;
        DummyAmt: Decimal;
        ItemNo: Code[10];
    begin
        // [SCENARIO 272246] The Intrastat Journal Line must contains VAT Registration No. and Country/Region Code from Customer of Service Shipment Header
        Initialize;

        // [GIVEN] Customer with "VAT Registration No." = "VATRegNo" and "Country/Region Code" = "CRC"
        CreateCustomerWithVATRegNoAndCountryRegion(Customer);

        // [GIVEN] Posted Service Invoice for Customer
        CreateAndPostServiceOrder(DummyQty, DummyAmt, ItemNo, Customer."No.");

        // [GIVEN] Intrastat Journal Batch
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, false);

        // [WHEN] Get Entries for Intrastat Journal
        GetEntriesForIntrastatBatch(IntrastatJnlBatch, false);

        // [THEN] "Intrastat Jnl. Line"."Partner VAT ID" = "VATRegNo"
        // [THEN] "Intrastat Jnl. Line"."Country/Region Code" = "CRC"
        VerifyIntrastatJnlLineVATRegNoCountryRegionCode(IntrastatJnlBatch, Customer, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesEUROX()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TextFile: BigText;
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 307017] Every line of Intrastat file starts with 'EUROX'.
        Initialize;

        // [GIVEN] Intrastat Journal Line.
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Purchases, true);
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Every line of file starts with constant sting 'EUROX'.
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(TextFile, 'EUROX', 1, 1, 5, 0);
        LibrarySpesometro.VerifyValue(TextFile, 'EUROX', 1, 133, 5, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesLineZeroAmountNormalBatch()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        CorrIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 315978] Intrastat Lines with zero Amount are not exported to intrastat file in case Intrastat Jnl Batch is not corrective.
        Initialize;

        // [GIVEN] Intrastat Journal Line with Amount = 0 for normal Batch.
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          CorrIntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, false, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(
          IntrastatJnlLine, CorrIntrastatJnlBatch, IntrastatJnlLine."Document No.", '');

        IntrastatJnlLine.Amount := 0;
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        asserterror RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Error "Amount must have a value" is thrown.
        Assert.ExpectedError(StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption(Amount), IntrastatJnlLine.TableCaption));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('MessageFromQueueHandler,IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatExportLinesLineZeroAmountCorrectiveBatch()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        CorrIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileName: Text;
        TextFile: BigText;
    begin
        // [FEATURE] [Export]
        // [SCENARIO 315978] Intrastat Lines with zero Amount are exported to intrastat file in case Intrastat Jnl Batch is corrective.
        Initialize;

        // [GIVEN] Intrastat Journal Line with Amount = 0 for Corrective Batch.
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          CorrIntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, true, true, IntrastatJnlBatchType::Purchase);
        MockIntrastatJnlLineAndPrepare(
          IntrastatJnlLine, CorrIntrastatJnlBatch, IntrastatJnlLine."Document No.", '');

        IntrastatJnlLine.Amount := 0;
        IntrastatJnlLine.Modify();

        FileName := FileManagement.ServerTempFileName('txt');
        Commit();

        // [WHEN] Export Intrastat Journal Lines to file via report "Run Intrastat - Make Disk Tax Auth"
        EnqueFilterIntrastatMakeDiskTaxAuth(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        RunIntrastatMakeDiskTaxAuth(FileName);

        // [THEN] Total Amount in file on the 0th line (header) equals to 0.
        // [THEN] Amount in file on the 1st line equals to 0.
        LibraryTextFileValidation.ReadTextFile(FileName, TextFile);
        LibrarySpesometro.VerifyValue(TextFile, FormatNum(Format(IntrastatJnlLine.Amount), 13), 1, 118, 13, 0);
        LibrarySpesometro.VerifyValue(TextFile, FormatNum(Format(IntrastatJnlLine.Amount), 13), 1, 194, 13, 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    procedure TotalWeightRounding()
    var
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        // [FEATURE] [Intrastat] [Export] [UT]
        // [SCENARIO 390312] Total Weight is rounded to integer
        Assert.AreEqual(1, IntraJnlManagement.RoundTotalWeight(1), '');
        Assert.AreEqual(1, IntraJnlManagement.RoundTotalWeight(1.123), '');
        Assert.AreEqual(2, IntraJnlManagement.RoundTotalWeight(1.789), '');
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Clear;
        LibraryReportDataset.Reset();
        LibrarySetupStorage.Restore;
        IntrastatJnlTemplate.DeleteAll(true);
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId);
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId);
        ResetNoSeriesLastUsedDate;

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        SetIntrastatCodeOnCountryRegion;
        SetTariffNoOnItems;

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, CreateEUVendor, DocumentType, false, '');  // EU Service - False.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostPurchInvoiceDiffTariffNo(LinesCount: Integer; PostingDate: Date; var PostedSalesDocNo: Code[20]) Amount: Decimal
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);

        for LinesCount := LinesCount downto 1 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, PurchLine.Type::Item,
              CreateItem(PurchHeader."VAT Bus. Posting Group", LibraryRandom.RandDec(10, 2)),
              LibraryRandom.RandDec(10, 2));
            PurchLine."Service Tariff No." := CreateServiceTariffNo;
            PurchLine.Modify(true);
        end;

        PurchHeader.CalcFields("Amount Including VAT");
        Amount := PurchHeader."Amount Including VAT";
        PostedSalesDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader, CreateEUCustomer, false, DocumentType, '');  // EU Service - False.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPrepareIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; EUService: Boolean; Corrective: Boolean; TransactionType: Code[10]; BatchType: Option; Date: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(IntrastatJnlBatch, IntrastatJnlTemplate.Name, WorkDate, EUService, Corrective, BatchType);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch, Date);
        SetMandatoryFieldsOnJnlLines(
          IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, TransactionType,
          FindOrCreateIntrastatTransactionSpecification, FindOrCreateIntrastatArea);
        Commit();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        CountryRegion.SetFilter("Intrastat Code", '<>''''');
        CountryRegion.FindFirst;
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerShipToAddress(var ShipToAddress: Record "Ship-to Address")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateEUCustomer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Country/Region Code", Customer."Country/Region Code");
        ShipToAddress.Modify(true);
    end;

    local procedure CreateCustomerWithVATRegNoAndCountryRegion(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CreateCountryRegion;
        Customer."VAT Registration No." :=
          LibraryUtility.GenerateRandomCode20(Customer.FieldNo("VAT Registration No."), DATABASE::Customer);
        Customer.Modify();
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

    local procedure CreateSalesInvoiceIntrastatSetup(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CustomerNo: Code[20]; BillToCustomerNo: Code[20]; EUService: Boolean; VATEUService: Boolean; DocumentDate: Date) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader, CustomerNo, VATEUService, SalesHeader."Document Type"::Invoice, '');
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateIntrastatJournalBatch(IntrastatJnlBatch, IntrastatJnlBatch.Type::Sales, EUService);

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateSalesLineWithServiceTariffNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; ServiceTariffNo: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Service Tariff No.", ServiceTariffNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceIntrastatSetup(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; VendorNo: Code[20]; PayToVendorNo: Code[20]; Type: Option; EUService: Boolean; VATEUService: Boolean) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::Invoice, VATEUService, '');
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateIntrastatJournalBatch(IntrastatJnlBatch, Type, EUService);

        // Exercise: Get Entries on Intrastat Journal.
        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.
    end;

    local procedure CreatePurchInvHeader(var PurchaseHeader: Record "Purchase Header"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        Vendor: Record Vendor;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PaymentMethod: Record "Payment Method";
        TransportMethod: Record "Transport Method";
    begin
        Vendor.Get(CreateEUVendor);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Modify(true);

        TransportMethod.FindFirst;
        PaymentMethod.FindFirst;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Transport Method", TransportMethod.Code);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify(true);
        CreateVATPostingSetup(
          VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine.Amount);
    end;

    local procedure CreateItem(VATBusPostingGroupCode: Code[20]; VATPct: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", CreateVATPostingSetupWithAccounts(VATBusPostingGroupCode, VATPct));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithTariffNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
            Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Last Direct Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Modify(true);
        end;
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
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateIntrastatJournalBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Type: Option; EUService: Boolean)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate(Type, Type);
        IntrastatJnlBatch.Validate(Periodicity, IntrastatJnlBatch.Periodicity::Month);
        IntrastatJnlBatch.Validate("EU Service", EUService);
        IntrastatJnlBatch.Validate("Statistics Period", Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod));
        IntrastatJnlBatch.Validate("File Disk No.", LibraryUtility.GenerateGUID);
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Item: Record Item)
    begin
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine."Country/Region Code" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine.Area := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transport Method" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Tariff No." := LibraryUTUtility.GetNewCode;
        IntrastatJnlLine."Country/Region of Origin Code" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Total Weight" := LibraryRandom.RandInt(100);
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine.Quantity := LibraryRandom.RandInt(10);
        IntrastatJnlLine.Amount := LibraryRandom.RandDec(100, 2);
        IntrastatJnlLine."Partner VAT ID" := LibraryUTUtility.GetNewCode;
        IntrastatJnlLine."Document No." := LibraryUTUtility.GetNewCode;
        IntrastatJnlLine.Date := WorkDate;
        IntrastatJnlLine."Service Tariff No." := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transaction Type" := '';
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateIntrastatJournalBatchWithCorrectiveAndTemplate(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; EUService: Boolean; CorrectiveEntry: Boolean; PostingDate: Date; BatchType: Option)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJournalBatchWithCorrective(
          IntrastatJnlBatch, IntrastatJnlTemplate.Name, PostingDate, EUService, CorrectiveEntry, BatchType);
    end;

    local procedure CreateIntrastatJournalBatchWithCorrective(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; JournalTemplateName: Code[10]; PostingDate: Date; EUService: Boolean; Corrective: Boolean; BatchType: Option)
    begin
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, JournalTemplateName);
        with IntrastatJnlBatch do begin
            Validate(Type, BatchType);
            Validate("Statistics Period", Format(PostingDate, 0, LibraryFiscalYear.GetStatisticsPeriod));
            Validate("File Disk No.", LibraryUtility.GenerateRandomCode(FieldNo("File Disk No."), DATABASE::"Intrastat Jnl. Batch"));
            Validate("EU Service", EUService);
            Validate("Corrective Entry", Corrective);
            Modify(true);
        end;
    end;

    local procedure CreateMultipleIntrastatJnlBatchAndGetEntries(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Type: Option): Code[10]
    var
        IntrastatJnlBatch2: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalBatch(IntrastatJnlBatch, Type, false);  // EU Service - False.
        CreateIntrastatJournalBatch(IntrastatJnlBatch2, Type, false);  // EU Service - False.
        UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch2, true);  // Corrective Entry - TRUE.

        GetEntriesIntrastatJournal;  // Opens GetItemLedgerEntriesRequestPageHandler.
        exit(IntrastatJnlBatch.Name);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; EUService: Boolean; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TransportMethod.FindFirst;
        PaymentMethod.FindFirst;
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        UpdateSalesHeader(SalesHeader, PaymentMethod.Code, TransportMethod.Code, ServiceTariffNumber."No.");
        CreateVATPostingSetup(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATPostingSetup."VAT Calculation Type"::"Normal VAT", EUService);
        CreateSalesLine(
          SalesHeader, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10), LocationCode);  // Random Quantity.
        exit(ServiceTariffNumber."No.");
    end;

    local procedure CreateSalesOrdersWithDropShipment(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateEUCustomer);
        CreateDropShipmentLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        exit(SalesLine."No.");
    end;

    local procedure CreatePurchOrdersWithDropShipment(var PurchHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateEUVendor);
        PurchHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchHeader.Modify(true);

        LibraryPurchase.GetDropShipment(PurchHeader);
    end;

    local procedure CreateDropShipmentLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        Item: Record Item;
    begin
        CreateItemWithTariffNo(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithItemChargeAndLocation(PurchaseHeader: Record "Purchase Header")
    var
        ItemCharge: Record "Item Charge";
        PurchaseLineWithItem: Record "Purchase Line";
        PurchaseLineWithItemCharge: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemCharge.FindFirst;

        LibraryCashFlowHelper.FindPurchaseLine(PurchaseLineWithItem, PurchaseHeader);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineWithItemCharge, PurchaseHeader, PurchaseLineWithItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLineWithItemCharge.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLineWithItemCharge.Modify(true);

        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, PurchaseLineWithItemCharge, ItemCharge,
          PurchaseHeader."Document Type",
          PurchaseLineWithItem."Document No.", PurchaseLineWithItem."Line No.",
          PurchaseLineWithItem."No.", 1, PurchaseLineWithItemCharge."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert();
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

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostSalesInvoiceDiffTariffNo(LinesCount: Integer; PostingDate: Date; var PostedSalesDocNo: Code[20]) Amount: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        for LinesCount := LinesCount downto 1 do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item,
              CreateItem(SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandDec(10, 2)),
              LibraryRandom.RandDec(10, 2));
            with SalesLine do begin
                Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(10, 100, 2));
                "Service Tariff No." := CreateServiceTariffNo;
                Modify(true);
            end;
        end;

        SalesHeader.CalcFields("Amount Including VAT");
        Amount := SalesHeader."Amount Including VAT";
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostServiceOrder(var Qty: Decimal; var Amt: Decimal; var ItemNo: Code[20]; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Qty := LibraryRandom.RandInt(5);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Modify();
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateItemWithTariffNo(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        Amt := ServiceLine.Amount;
        ItemNo := ServiceLine."No.";
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateSalesLineWithItemChargeAndLocation(SalesHeader: Record "Sales Header")
    var
        ItemCharge: Record "Item Charge";
        SalesLineWithItemCharge: Record "Sales Line";
        SalesLineWithItem: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemCharge.FindFirst;

        LibraryCashFlowHelper.FindSalesLine(SalesLineWithItem, SalesHeader);

        LibrarySales.CreateSalesLine(
          SalesLineWithItemCharge, SalesHeader, SalesLineWithItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLineWithItemCharge.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineWithItemCharge.Validate("Unit Cost", SalesLineWithItemCharge."Unit Price");
        SalesLineWithItemCharge.Modify(true);

        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineWithItemCharge, ItemCharge,
          SalesHeader."Document Type",
          SalesLineWithItem."Document No.", SalesLineWithItem."Line No.",
          SalesLineWithItem."No.", 1, SalesLineWithItemCharge."Unit Price");
        ItemChargeAssignmentSales.Insert();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; EUService: Boolean; LocationCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        TransportMethod.FindFirst;
        PaymentMethod.FindFirst;
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Transport Method", TransportMethod.Code);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreateVATPostingSetup(
          VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", EUService);
        CreatePurchaseLine(PurchaseHeader, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateServiceTariffNo(): Code[10]
    var
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        exit(ServiceTariffNumber."No.");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATCalculationType: Enum "Tax Calculation Type"; EUService: Boolean)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATIdentifier: Record "VAT Identifier";
    begin
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
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CopySalesDoument(var SalesHeader: Record "Sales Header")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Commit();  // Commit required.
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.RunModal;
    end;

    local procedure CreateVATPostingSetupWithAccounts(VATBusPostingGroupCode: Code[20]; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroup.Code);
        with VATPostingSetup do begin
            "VAT Calculation Type" := "VAT Calculation Type"::"Reverse Charge VAT";
            "VAT Identifier" := LibraryUtility.GenerateGUID;
            "VAT %" := VATPct;
            "EU Service" := true;
            "Purchase VAT Account" := LibraryERM.CreateGLAccountNo;
            "Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo;
            Modify;
            exit("VAT Prod. Posting Group");
        end;
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", FindCountryRegionCode);
        Vendor.Modify(true);

        UpdateNoSeriesFromVATBusProdGr(Vendor."VAT Bus. Posting Group");

        exit(Vendor."No.");
    end;

    local procedure EnqueFilterIntrastatMakeDiskTaxAuth(JournalTemplateName: Code[20]; JournalBatchName: Code[20])
    begin
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        LibraryVariableStorage.Enqueue(JournalBatchName);
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

    local procedure FilterIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; DocumentNo: Code[20])
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure FindAndCreatePurchaseLine(PurchaseHeader: Record "Purchase Header") Amount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
        Amount := CreatePurchaseLine(PurchaseHeader, PurchaseLine."No.");
        Amount += PurchaseLine.Amount;
    end;

    local procedure FindIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalBatchName: Code[10]; DocumentNo: Code[20])
    begin
        FilterIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure FindOrCreateIntrastatArea(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::Area));
    end;

    local procedure FindOrCreateIntrastatTransactionType(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Type"));
    end;

    local procedure FindOrCreateIntrastatTransportMethod(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
    end;

    local procedure FindOrCreateIntrastatTransactionSpecification(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Specification"));
    end;

    local procedure FindPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; DocumentNo: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst;
    end;

    local procedure FindAndCreateSalesLine(SalesHeader: Record "Sales Header") Amount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        Amount := CreateSalesLine(SalesHeader, SalesLine."No.", SalesLine.Quantity, '');
        Amount += SalesLine.Amount;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Line Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst;
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst;
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst;
    end;

    local procedure GetEntriesIntrastatJournal()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        LibraryVariableStorage.Enqueue(false); // IncludeIntraCommunity = FALSE
        Commit();  // Commit required.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.GetEntries.Invoke;
    end;

    local procedure GetEntriesForIntrastatBatch(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; IncludeIntraCommunity: Boolean)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        GetItemLedgerEntries.InitializeRequest(WorkDate, WorkDate, 0);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        LibraryVariableStorage.Enqueue(IncludeIntraCommunity);
        Commit(); // Commit required.
        GetItemLedgerEntries.Run;
    end;

    local procedure MockIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CorrectedDocNo: Code[20]; CorrectedJnlBatchName: Code[10])
    begin
        with IntrastatJnlLine do begin
            Init;
            "Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
            "Journal Batch Name" := IntrastatJnlBatch.Name;
            "Line No." := LibraryUtility.GetNewRecNo(IntrastatJnlLine, FieldNo("Line No."));
            "Document No." := LibraryUtility.GenerateRandomCode(FieldNo("Document No."), DATABASE::"Intrastat Jnl. Line");
            if CorrectedDocNo <> '' then begin
                "Corrected Document No." := CorrectedDocNo;
                "Corrected Intrastat Report No." := CorrectedJnlBatchName;
            end;
            "Country/Region Code" := 'IT';
            "Partner VAT ID" := '123123789';
            Amount := LibraryRandom.RandDec(1000, 2);
            Date := WorkDate;
            "Service Tariff No." := '123456';
            "Custom Office No." := '12345';
            "Reference Period" := Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod);
            "Progressive No." := '0';
            Insert;
        end;
    end;

    local procedure MockIntrastatJnlLineAndPrepare(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CorrectedDocNo: Code[20]; CorrectedJnlBatchName: Code[10])
    begin
        MockIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, CorrectedDocNo, CorrectedJnlBatchName);
        SetMandatoryFieldsOnJnlLines(
          IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, FindOrCreateIntrastatArea);
    end;

    local procedure MockIntrastatJnlLineWithCountryRegion(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; LenCountryCode: Integer)
    begin
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        IntrastatJnlLine."Country/Region of Payment Code" := LibraryUtility.GenerateRandomCodeWithLength(
            IntrastatJnlLine.FieldNo("Country/Region of Payment Code"), DATABASE::"Intrastat Jnl. Line", LenCountryCode);
        IntrastatJnlLine.Modify();
    end;

    local procedure MockIntrastatJnlLineWithAmountAndStatisticalValue(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Amount: Decimal; StatisticalValue: Decimal)
    begin
        MockIntrastatJnlLineAndPrepare(IntrastatJnlLine, IntrastatJnlBatch, '', '');
        IntrastatJnlLine.Amount := Amount;
        IntrastatJnlLine."Statistical Value" := StatisticalValue;
        IntrastatJnlLine."Group Code" := LibraryUtility.GenerateGUID;                     // needed for Corrective Entry when not EU Service
        IntrastatJnlLine."Corrected Intrastat Report No." := LibraryUtility.GenerateGUID; // needed for Corrective Entry when not EU Service
        IntrastatJnlLine.Modify();
    end;

    local procedure MockIntrastatJnlLinesWithAmountAndStatisticalValue(var IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line"; EUService: Boolean; CorrectiveEntry: Boolean; PostingDate: Date)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalBatchWithCorrectiveAndTemplate(
          IntrastatJnlBatch, EUService, CorrectiveEntry, PostingDate, IntrastatJnlBatchType::Sales);
        MockIntrastatJnlLineWithAmountAndStatisticalValue(IntrastatJnlLine[1], IntrastatJnlBatch, 0.01, 0.01);
        MockIntrastatJnlLineWithAmountAndStatisticalValue(IntrastatJnlLine[2], IntrastatJnlBatch, 1.49, 1.49);
    end;

    local procedure MockIntrastatJnlLinesWithAmountAndStatisticalValueForGrouping(var IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line"; EUService: Boolean; CorrectiveEntry: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalBatchWithCorrectiveAndTemplate(
          IntrastatJnlBatch, EUService, CorrectiveEntry, WorkDate, IntrastatJnlBatchType::Sales);
        MockIntrastatJnlLineWithAmountAndStatisticalValue(IntrastatJnlLine[1], IntrastatJnlBatch, 0.01, 0.01);
        ModifyIntrastatJnlLineTariffAndTotalWeight(IntrastatJnlLine[1], LibraryUtility.GenerateGUID, LibraryRandom.RandInt(3));

        IntrastatJnlLine[2] := IntrastatJnlLine[1];
        IntrastatJnlLine[2]."Line No." += 1;
        IntrastatJnlLine[2].Amount := 1.49;
        IntrastatJnlLine[2]."Statistical Value" := 1.49;
        IntrastatJnlLine[2].Insert();
    end;

    local procedure ModifyIntrastatJnlLineTariffAndTotalWeight(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TariffNo: Code[20]; TotalWeight: Integer)
    begin
        IntrastatJnlLine."Tariff No." := TariffNo;
        IntrastatJnlLine."Total Weight" := TotalWeight;
        IntrastatJnlLine.Modify();
    end;

    local procedure ModifyIntrastatJnlLinesTariffAndTotalWeight(var IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line")
    begin
        ModifyIntrastatJnlLineTariffAndTotalWeight(IntrastatJnlLine[1], LibraryUtility.GenerateGUID, LibraryRandom.RandInt(3));
        ModifyIntrastatJnlLineTariffAndTotalWeight(IntrastatJnlLine[2], LibraryUtility.GenerateGUID, LibraryRandom.RandInt(3));
    end;

    local procedure ReadTxtLineFromFile(FileName: Text; LineNo: Integer) TextLine: Text[1024]
    var
        File: File;
        I: Integer;
    begin
        File.WriteMode(false);
        File.TextMode(true);
        File.Open(FileName);
        for I := 0 to LineNo do
            File.Read(TextLine); // first line - file header info, other lines - documents info
        File.Close;
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(Filename: Text)
    var
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
    begin
        LibraryVariableStorage.Enqueue(FileWasCreatedSuccessfullyMsg);
        IntrastatMakeDiskTaxAuth.InitializeRequest(Filename);
        IntrastatMakeDiskTaxAuth.RunModal;
    end;

    local procedure RunIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal")
    begin
        IntrastatJournal.OpenEdit;
    end;

    local procedure RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Date: Date)
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', Date));
        LibraryVariableStorage.Enqueue(CalcDate('<CM>', Date));
        IntrastatJournal.GetEntries.Invoke;
        VerifyIntrastatJnlLinesExist(IntrastatJnlBatch);
        IntrastatJournal.Close;
    end;

    local procedure RunSalesDocumentTest(No: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesDocumentTest: Report "Sales Document - Test";
    begin
        Commit();  // Commit required.
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("No.", No);
        SalesDocumentTest.SetTableView(SalesHeader);
        SalesDocumentTest.Run;
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

    local procedure SetMandatoryFieldsOnJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; TransportMethod: Code[10]; TransactionType: Code[10]; TransactionSpecification: Code[10]; "Area": Code[10])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindSet();
        repeat
            IntrastatJnlLine.Validate("Transport Method", TransportMethod);
            IntrastatJnlLine.Validate("Transaction Type", TransactionType);
            IntrastatJnlLine.Validate("Net Weight", LibraryRandom.RandDecInRange(1, 10, 2));
            IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification);
            IntrastatJnlLine.Validate("Country/Region of Origin Code", CompanyInfo."Country/Region Code");
            IntrastatJnlLine.Validate(Area, Area);
            IntrastatJnlLine.Validate("Partner VAT ID", LibraryUtility.GenerateGUID);
            IntrastatJnlLine.Modify(true);
        until IntrastatJnlLine.Next = 0;
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

    local procedure UpdateIntrastatJnlBatchCorrectiveEntry(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CorrectiveEntry: Boolean)
    begin
        IntrastatJnlBatch.Validate("Corrective Entry", CorrectiveEntry);
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]; TransportMethod: Code[10]; ServiceTariffNo: Code[10])
    begin
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Transport Method", TransportMethod);
        SalesHeader.Validate("Service Tariff No.", ServiceTariffNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLineServiceTariffNo(var SalesLine: Record "Sales Line"; ServiceTariffNo: Code[10])
    begin
        SalesLine.Validate("Service Tariff No.", ServiceTariffNo);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupShipmentOnInvoice(ShipmentOnInvoice: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Shipment on Invoice", ShipmentOnInvoice);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetupReceiptOnInvoice(ReceiptOnInvoice: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Receipt on Invoice", ReceiptOnInvoice);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetRandomItemDescriptionToIntrastatLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Text[10]
    begin
        IntrastatJnlLine."Item Description" := CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10);
        IntrastatJnlLine.Modify();
        exit(IntrastatJnlLine."Item Description");
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        CreateItemWithTariffNo(Item);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine."Location Code" := LocationCode;
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(5));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);
        CreateItemWithTariffNo(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine."Location Code" := LocationCode;
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(5));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure UpdateNoSeriesFromVATBusProdGr(VATBusProdGroupCode: Code[20])
    var
        VATBusPostGroup: Record "VAT Business Posting Group";
        NoSeries: Record "No. Series";
        RevChargeNoSeries: Record "No. Series";
    begin
        VATBusPostGroup.Get(VATBusProdGroupCode);
        NoSeries.Get(VATBusPostGroup."Default Purch. Operation Type");

        RevChargeNoSeries.SetRange("No. Series Type", RevChargeNoSeries."No. Series Type"::Sales);
        RevChargeNoSeries.FindFirst;
        NoSeries.Validate("Reverse Sales VAT No. Series", RevChargeNoSeries.Code);
        NoSeries.Modify(true);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LibraryWarehouse.CreateLocation(Location);
        CompanyInfo.Get();
        Location.Validate("Country/Region Code", CompanyInfo."Country/Region Code");
        Location.Modify(true);

        if InventoryPostingGroup.FindSet then
            repeat
                InventoryPostingSetup.SetRange("Location Code", Location.Code);
                InventoryPostingSetup.SetRange("Invt. Posting Group Code", InventoryPostingGroup.Code);
                if not InventoryPostingSetup.FindFirst then
                    LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
                InventoryPostingSetup.Validate("Inventory Account", LibraryERM.CreateGLAccountNo);
                InventoryPostingSetup.Modify(true);
            until InventoryPostingGroup.Next = 0;

        exit(Location.Code);
    end;

    local procedure FormatNum(CodeField: Code[54]; Len: Integer): Code[54]
    begin
        exit(Format(CodeField, Len, StrSubstNo('<Text,%1><Filler Character,0>', Len)))
    end;

    local procedure VerifyIntrastatJnlLineDateWithPurchInvoiceDocumentDate(DocumentNo: Code[20]; JournalBatchName: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField(Date, PurchInvHeader."Document Date");
    end;

    local procedure VerifyIntrastatJnlLineDateWithSalesInvoiceDocumentDate(DocumentNo: Code[20]; JournalBatchName: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField(Date, SalesInvoiceHeader."Document Date");
    end;

    local procedure VerifyIntrastatJnlLineCountryRegionCode(JournalBatchName: Code[10]; DocumentNo: Code[20]; CountryRegionCode: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Country/Region Code", CountryRegionCode);
    end;

    local procedure VerifyIntrastatJnlLineVATRegistrationNo(JournalBatchName: Code[10]; DocumentNo: Code[20]; VATRegistrationNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField("Partner VAT ID", VATRegistrationNo);
    end;

    local procedure VerifyIntrastatJnlLine(JournalBatchName: Code[10]; DocumentNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        IntrastatJnlLine.TestField(Amount, Amount);
    end;

    local procedure VerifyIntrastatJnlLineEmpty(JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FilterIntrastatJournalLine(IntrastatJnlLine, JournalBatchName, DocumentNo);
        Assert.RecordIsEmpty(IntrastatJnlLine);
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        DummyIntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        DummyIntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.RecordIsNotEmpty(DummyIntrastatJnlLine);
    end;

    local procedure VerifyIntrastatJnlLineExpectedValues(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNo: Code[20]; ExpectedQty: Decimal; ExpectedAmount: Decimal)
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

    local procedure VerifyDocNoDocDate(FileName: Text; ExpDocNo: Code[20]; ExpDocDate: Date; Corrective: Boolean; ExpectedPartnerVATID: Text)
    var
        TextLine: Text[1024];
        DocumentNo: Code[20];
        DocumentDate: Text;
        StartPos: Integer;
    begin
        TextLine := ReadTxtLineFromFile(FileName, 1);

        if Corrective then
            StartPos := 88
        else
            StartPos := 69;

        Evaluate(DocumentNo, CopyStr(TextLine, StartPos, 15));
        DocumentDate := CopyStr(TextLine, StartPos + 15, 6);

        Assert.AreEqual(ExpDocNo, DocumentNo, DocumentNoErr);
        Assert.AreEqual(Format(ExpDocDate, 0, '<Day,2><Month,2><Year,2>'), DocumentDate, DocumentDateErr);
        Assert.AreEqual(PadStr(ExpectedPartnerVATID, 12, ' '), CopyStr(TextLine, StartPos - 38, 12), 'Partner VAT ID');
    end;

    local procedure VerifyProgressiveNo(FileName: Text; ExpProgrNo: Code[5])
    var
        TextLine: Text[1024];
        ProgressiveNo: Code[5];
    begin
        TextLine := ReadTxtLineFromFile(FileName, 1);
        Evaluate(ProgressiveNo, CopyStr(TextLine, 43, 5));

        Assert.AreEqual(ExpProgrNo, ProgressiveNo, DocumentNoErr);
    end;

    local procedure VerifyIntrastatJnlLines(ExpectedLineCount: Integer; ExpectedAmount: Decimal; IntrastatJnlLine: Record "Intrastat Jnl. Line"; DocumentNo: Code[20])
    begin
        with IntrastatJnlLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            SetRange("Document No.", DocumentNo);
            Assert.RecordCount(IntrastatJnlLine, ExpectedLineCount);
            CalcSums(Amount);
            Assert.AreEqual(ExpectedAmount, Amount, StrSubstNo(IntrastatJournalLineErr, FieldCaption(Amount)));
        end;
    end;

    local procedure VerifyNumberOfIntrastatLines(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; AcceptableDocNo: Code[20]; NotAcceptableDocNo: Code[20]; QtyOfLines: Integer)
    var
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        DummyIntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        DummyIntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        DummyIntrastatJnlLine.SetRange("Document No.", AcceptableDocNo);
        Assert.RecordCount(DummyIntrastatJnlLine, QtyOfLines);

        DummyIntrastatJnlLine.SetRange("Document No.", NotAcceptableDocNo);
        Assert.RecordCount(DummyIntrastatJnlLine, 0);
    end;

    local procedure VerifyAmountInIntrastatLine(IntrastatJnlBatchName: Code[10]; AcceptableDocNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        IntrastatJnlLine.SetFilter("Document No.", AcceptableDocNo);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField(Amount, Amount);
    end;

    local procedure VerifyIntrastatJnlLineAmountAndItemDescription(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ServiceTariffNo: Code[10]; Amount: Decimal; ItemDescription: Text[10])
    begin
        IntrastatJnlLine.SetRange("Service Tariff No.", ServiceTariffNo);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField(Amount, Amount);
        IntrastatJnlLine.TestField("Item Description", ItemDescription);
    end;

    local procedure VerifyIntrastatJnlLineItemNo(IntrastatJnlBatchName: Code[10]; InvoiceNo: Code[20]; ItemNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        FindIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlBatchName, InvoiceNo);
        IntrastatJnlLine.TestField("Item No.", ItemNo);
    end;

    local procedure VerifyIntrastatJnlLineVATRegNoCountryRegionCode(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Customer: Record Customer; ItemNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetRange("Item No.", ItemNo);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField("Partner VAT ID", Customer."VAT Registration No.");
        IntrastatJnlLine.TestField("Country/Region Code", Customer."Country/Region Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.ShowingItemCharges.SetValue(true);
        GetItemLedgerEntries.IncludeIntraCommunityEntries.SetValue(LibraryVariableStorage.DequeueBoolean);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocumentNo: Variant;
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CopySalesDocument.DocumentType.SetValue(Format(DocType::"Posted Invoice"));
        CopySalesDocument.DocumentNo.SetValue(DocumentNo);
        CopySalesDocument.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesWithQueueRequestPageHandler(var GetItemLedgerEntriesReqPage: TestRequestPage "Get Item Ledger Entries")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GetItemLedgerEntriesReqPage.StartingDate.SetValue(StartDate);
        GetItemLedgerEntriesReqPage.EndingDate.SetValue(EndDate);
        GetItemLedgerEntriesReqPage.CostRegulationPct.SetValue(0);
        GetItemLedgerEntriesReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskTaxAuthRequestPageHandler(var IntrastatMakeDiskTaxAuth: TestRequestPage "Intrastat - Make Disk Tax Auth")
    begin
        IntrastatMakeDiskTaxAuth."Intrastat Jnl. Batch".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        IntrastatMakeDiskTaxAuth."Intrastat Jnl. Batch".SetFilter(Name, LibraryVariableStorage.DequeueText);
        IntrastatMakeDiskTaxAuth.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateListModalPageHandler(var IntrastatJnlTemplateList: TestPage "Intrastat Jnl. Template List")
    begin
        IntrastatJnlTemplateList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignementSaleModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke;
        ItemChargeAssignmentSales.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ServiceTariffNumberMsg) > 0, ValueMatchMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageFromQueueHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PurchaseServiceTariffNoMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PurchaseServiceTariffNumberMsg) > 0, ValueMatchMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNegativeHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

