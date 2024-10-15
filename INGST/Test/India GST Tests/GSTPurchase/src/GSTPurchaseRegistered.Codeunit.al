codeunit 18134 "GST Purchase Registered"
{
    Subtype = Test;

    //Scenario-355068 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from SEZ Vendor where Input Tax Credit is not available with invoice discount/line discount multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount Not ITC,SEZ Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseInvoiceSEZVendorWithoutITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::SEZ, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    PurchaseLine.Type::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 6);
    end;

    //Scenario-354852 Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [Intra-State GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure VerifyGSTPurchaseOrderWithInputTaxCreditWithMultipleHSNCodeWiseForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    PurchaseLine.Type::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 5);
    end;

    //Scenario-354852 Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [Intra-State GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure VerifyGSTPurchaseInvoiceWithInputTaxCreditWithMultipleHSNCodeWiseForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 5);
    end;

    //Scenario-354852 Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [Intra-State GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure VerifyGSTPurchaseOrderWithInputTaxCreditWithMultipleHSNCodeWiseForInterstate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //Scenario-354852 Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [Intra-State GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseOrderWithAvailmentThroughPurchaseOrderMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 5);
    end;

    //Scenario-354861 Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice.
    // [FEATURE] [Fixed Assets Purchase Order] [Intra-State GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseInvoiceWithAvailmentThroughPurchaseOrderMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-354885 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [InterState GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseOrderWithAvailmentThroughPurchaseOrderMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified 
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 4);
    end;

    //Test Case-354886 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice.
    // [FEATURE] [Fixed Assets Purchase Order] [InterState GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseInvoiceWithAvailmentThroughPurchaseInvoiceMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Test Case-354890 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase order.
    // [FEATURE] [Fixed Assets Purchase Order] [InterState GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseOrderWithoutAvailmentThroughPurchaseOrderMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[WHEN] G.L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Order, DocumentNo, 3);
    end;

    //Test Case 354891 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Invoice.
    //[FEATURE] [Fixed Assets Purchase Invoice] [InterState GST,Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterstatePurchaseInvoiceWithoutAvailmentThroughPurchaseOrderMultipleLineForRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-355646 Check if the system is calculating GST in case of Intra-State Purchase of Services from Registered Vendor by Input Service Distributor where Input Tax Credit is available
    // [FEATURE] [Services Purchase Order] [Intra-State GST,Registered Vendor by Input Service Distributor(ISD)]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseOrderRegisteredVendorbyISDWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        GSTGroupType: Enum "GST Group Type";
        LineType: Enum "Purchase Line Type";
        DocumentType: Enum "Purchase Document Type";
    Begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, false);
        UpdateInputServiceDistributer(true, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355647 Check if the system is calculating GST in case of Intra-State Purchase of Services from Registered Vendor with Multiple Lines by Input Service Distributor where Input Tax Credit is available
    //[FEATURE] [MultipleLine Services Purchase Order] [Intra-State GST,Registered Vendor by Input Service Distributor(ISD)]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseOrderMultipleLineRegisteredVendorbyISDWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, false);
        UpdateInputServiceDistributer(true, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-355648 Check if the system is calculating GST in case of Intra-State Purchase of Services from Registered Vendor by Input Service Distributor where Input Tax Credit is not available
    // [FEATURE] [Services Purchase Order] [Intra-State GST,Registered Vendor by Input Service Distributor(ISD) Input Tax Credit is not available  ]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseOrderRegisteredVendorbyISDWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        DocumentType: Enum "Purchase Document Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        UpdateInputServiceDistributer(true, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355649 Check if the system is calculating GST in case of Intra-State Purchase of Services from Registered Vendor with Multiple lines by Input Service Distributor where Input Tax Credit is not available
    // [FEATURE] [MultipleLine Services Purchase Invoice] [Intra-State GST,Registered Vendor by Input Service Distributor(ISD) and Input Tax Credit is not available ]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntrastatePurchaseOrderMultipleLineRegisteredVendorbyISDWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    Begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        UpdateInputServiceDistributer(true, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-355650 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor by Input Service Distributor where Input Tax Credit is available
    //[FEATURE] [Services Purchase Invoice] [Inter-State GST,Registered Vendor by Input Service Distributor(ISD)]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterStatePurchaseOrderRegisteredVendorbyISDWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        DocumentType: Enum "Purchase Document Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        UpdateInputServiceDistributer(true, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355651 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor with Multiple Lines by Input Service Distributor where Input Tax Credit is available
    // [FEATURE] [MultipleLine Services Purchase Order] [Inter-State GST,Registered Vendor by Input Service Distributor(ISD)]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterStatePurchaseOrderMultipleLineRegisteredVendorbyISDWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        UpdateInputServiceDistributer(true, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
        PurchaseLine,
        LineType::"G/L Account", DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;
    ///a
    //Scenario-355652 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor by Input Service Distributor where Input Tax Credit is not available
    // [FEATURE] [Services Purchase Order] [Inter-State GST,Registered Vendor by Input Service Distributor(ISD) Input Tax Credit is not available  ]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterStatePurchaseOrderRegisteredVendorbyISDWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        UpdateInputServiceDistributer(true, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355653 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor with multiple lines by Input Service Distributor where Input Tax Credit is not available
    // [FEATURE] [MultipleLine Services Purchase Invoice] [Inter-State GST,Registered Vendor by Input Service Distributor(ISD) and Input Tax Credit is not available ]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure InterStatePurchaseInvoiceMultipleLineRegisteredVendorbyISDWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        UpdateInputServiceDistributer(true, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-354764 Check if the system is considering Discounts while calculating GST in case of Intra-State Purchase of Services from Registered vendor where ITC is available through Purchase Quote
    //[FEATURE] [Discounts Services Purchase Quote] [Intra-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseServicesQuoteWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        OrderNo: code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Quote);

        //Make Quote to Order
        OrderNo := LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
        LibraryGST.VerifyTaxTransactionForPurchase(OrderNo, DocumentType::Order);
    end;

    //Scenario-354765 Check if the system is considering Discounts while calculating GST in case of Intra-State Purchase of Services from Registered vendor where ITC is available through Purchase Order
    //[FEATURE] [Discounts Services Purchase Order] [Intra-State GST,Registered Vendor Input Tax Credit is not available]

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseServicesOrdereWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //Scenario-354766 Check if the system is considering Discounts while calculating GST in case of Intra-State Purchase of Services from Registered vendor where ITC is available through Purchase Invoice
    //[FEATURE] [Discounts Services Purchase Invoice] [Intra-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseServicesInvoiceeWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;
    //
    //Scenario-354767 Check if the system is considering Discounts while calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where ITC is avalable through Purchase Quote
    //[FEATURE] [Discounts Goods Purchase Quote] [Intra-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseQuoteGoodsWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        OrderNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                                PurchaseLine,
                                LineType::Item,
                                PurchaseHeader."Document Type"::Quote);

        //Make Quote to Order
        OrderNo := LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
        LibraryGST.VerifyTaxTransactionForPurchase(OrderNo, DocumentType::Order);
    end;
    //Scenario-354768 Check if the system is considering Discounts while calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where ITC is avalable through Purchase order
    //[FEATURE] [Discounts Goods Purchase Order] [Intra-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseOrdereGoodsWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-354769 Check if the system is considering Discounts while calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where ITC is avalable through Purchase Invoice
    //[FEATURE] [Discounts Goods Purchase Invoice] [Intra-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure IntraStatePurchaseInvoiceGoodsWithDiscountsRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and PostED Purchase Order with GST and Line Type as Services for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Scenario-354852] Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseOrderWithInputTaxCreditWithMultipleHSNCodeWiseForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (Format(2)));

        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Scenario-354861] Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseInvoiceWithInputTaxCreditWithMultipleHSNCodeWiseForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Scenario-354885] Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseOrderWithInputTaxCreditWithMultipleHSNCodeWiseForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //[Scenario-354886] Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseInvoiceWithInputTaxCreditWithMultipleHSNCodeWiseForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //[Scenario-354890] Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Order.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseOrderWithoutInputTaxCreditWithMultipleHSNCodeWiseForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Scenario-354891] Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromGSTPurchaseInvoiceWithoutInputTaxCreditWithMultipleHSNCodeWiseForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //Scenario-353800 Intra-State/Intra-Union Territory Purchase of Services from Registered Vendor where Input Tax Credit is not available through Purchase Quote.
    //[FEATURE] [Service Purchase Quote] [Intra-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromIntrastatePurchaseServicesQuoteForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        OrderNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as G/L Account for Intrastate Transactions.
        DocumentNo := CreatePurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            LineType::"G/L Account",
            PurchaseHeader."Document Type"::Quote);

        //Make Quote to Order
        OrderNo := LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
        LibraryGST.VerifyTaxTransactionForPurchase(OrderNo, DocumentType::Order);
    end;

    //Scenario-353803 Intra-State/Intra-Union Territory Purchase of Services from Registered Vendor where Input Tax Credit is not available through Purchase Order.
    //[FEATURE] [Service Purchase Order] [Intra-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromIntrastatePurchaseServicesOrderForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::"G/L Account",
                          PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-353868 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor where Input Tax Credit is not available through Purchase Quote.
    //[FEATURE] [Service Purchase Quote] [Inter-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesQuoteForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                                            PurchaseLine,
                                            LineType::"G/L Account",
                                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type");
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-353869 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor where Input Tax Credit is not available through Purchase order.
    //[FEATURE] [Service Purchase Order] [Inter-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesOrderForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::"G/L Account",
                          PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-353838 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Quotes.
    //[FEATURE] [Goods Purchase Quote] [Inter-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsQuoteForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type");
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-353839 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Orders.
    //[FEATURE] [Goods Purchase Order] [Inter-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsOrderForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::"G/L Account",
                          PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-353804 Intra-State/Intra-Union Territory Purchase of Services from Registered Vendor where Input Tax Credit is not available through Purchase Invoice.
    //[FEATURE] [Service Purchase Invoice] [Intra-State GST,Registered Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromIntrastatePurchaseServicesInvoiceForRegisteredVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as GLAccount for Intrastate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::"G/L Account",
                          PurchaseHeader."Document Type"::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-353815 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase Quote.
    //[FEATURE] [Goods Purchase Quote] [Intra-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsQuoteForRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type");
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-353816 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase Order.
    //[FEATURE] [Goods Purchase Order] [Inter-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsOrderForRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-353817 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase Invoice.
    //[FEATURE] [Goods Purchase Invoice] [Inter-State GST,Registered Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsInvoiceForRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //[Scenario 353781] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Quotes
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromQuoteForGoodsRegisteredWithoutAvailmentIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
        OrderNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create Purchase Order from Purchase Quote
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
            PurchaseLine,
            LineType::Item,
            DocumentType::Quote);

        //Make Quote to Order
        OrderNo := LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
        LibraryGST.VerifyTaxTransactionForPurchase(OrderNo, DocumentType::Order);
    end;

    //[Scenario 353782] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForRegisteredWithoutAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create Purchase Order
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                           PurchaseHeader,
                           PurchaseLine,
                           LineType::Item,
                           DocumentType::Order);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 353755] Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase Invoice Type-Debit Note
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForRegisteredWithDebitNoteAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
        InvoiceType: Enum "GST Invoice Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        Storage.Set('InvoiceType', format(InvoiceType::"Debit Note"));

        //[WHEN] Create and Post Purchase Invoice
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
        Storage.Set('InvoiceType', '');
    end;

    //[Scenario 353783] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Invoice
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForRegisteredWithoutAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Invoice
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 353774] Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Service from Registered Vendor where Input Tax Credit is available through Purchase Invoice Type-Supplementary 
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForRegisteredWithSupplementaryAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
        InvoiceType: Enum "GST Invoice Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        Storage.Set('InvoiceType', format(InvoiceType::Supplementary));

        //[WHEN] Create and Post Purchase Invoice
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                           PurchaseHeader,
                           PurchaseLine,
                           LineType::Item,
                           DocumentType::Invoice);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
        Storage.Set('InvoiceType', '');
    end;

    //[Scenario 353786] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Services from Registered Vendor where Input Tax Credit is available through Purchase Order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForRegisteredWithAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Purchase Order
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                           PurchaseHeader,
                           PurchaseLine,
                           LineType::Item,
                           DocumentType::Order);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //[Scenario 353789] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Services from Registered Vendor where Input Tax Credit is available through Purchase Quote
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromQuoteForServiceRegisteredWithoutAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: codeunit "Library - Purchase";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
        OrderNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create Purchase Order From Quote
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreatePurchaseDocument(
                           PurchaseHeader,
                           PurchaseLine,
                           LineType::"G/L Account",
                           DocumentType::Quote);

        //Make Quote to Order
        OrderNo := LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
        LibraryGST.VerifyTaxTransactionForPurchase(OrderNo, DocumentType::Order);
    end;

    //[Scenario 353784] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Invoice Type-Debit Note
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForRegisteredWithDebitNoteWihtoutAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
        InvoiceType: Enum "GST Invoice Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        Storage.Set('InvoiceType', format(InvoiceType::"Debit Note"));

        //[WHEN] Create and Post Purchase Journal
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                             PurchaseHeader,
                             PurchaseLine,
                             LineType::Item,
                             DocumentType::Invoice);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
        Storage.Set('InvoiceType', '');
    end;

    //[Scenario 353790] Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForServiceRegisteredWithAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Purchase Journal
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                           PurchaseHeader,
                           PurchaseLine,
                           LineType::Item,
                           DocumentType::Invoice);

        //[THEN] Verify GST ledger entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    // [Senerio 353537]	[Check After Change Pay to Vendor on Purchase Header]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,ChangeVendor')]
    procedure CheckAfterChangePaytoVendoronPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        PurchaseInvoiceType: enum "GST Invoice Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order
        DocumentType := DocumentType::Order;
        CreatePurchaseHeaderWithGST(
            PurchaseHeader,
            format(Storage.Get('VendorNo')),
            DocumentType,
            format(Storage.Get('LocationCode')),
            PurchaseInvoiceType::" ");

        //[WHEN] Vendor is Changed in Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryGST.CreateVendorSetup());
        PurchaseHeader.Modify(true);
    end;

    // [Senerio 357174]	[Check on purchase line, update type, no. and Qty]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckOnPurchaseLineUpdateTypeNumberandQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryRandom: Codeunit "Library - Random";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Invoice
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    // [Senerio 356402]	[Check  after Change order Address on purchase header document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckAfterChangeOrderAddressOnPurchaseHeaderDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        PurchaseLine, PurchaseLine2 : Record "Purchase Line";
        LibraryPurcahse: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        OrderAddressLbl: Label 'Order Address are not Equal', Locked = true;
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        LibraryPurcahse.CreateOrderAddress(OrderAddress, PurchaseHeader."Buy-from Vendor No.");
        OrderAddress.Validate("ARN No.", Format(Random(20)));
        OrderAddress.Modify(true);
        PurchaseHeader.Validate("Order Address Code", OrderAddress.Code);
        PurchaseHeader.Modify(true);
        PurchaseLine2.Reset();
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine2.SetRange("Document Type", PurchaseLine2."Document Type"::"Invoice");
        PurchaseLine2.FindFirst();
        Assert.AreEqual(PurchaseHeader."Order Address Code", PurchaseLine2."Order Address Code", OrderAddressLbl);
    end;

    //[Senerio 356418]	[Check after change Invoice type on header]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckAfterChangeInvoiceTypeOnHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"Non-GST");
        PurchaseHeader.Validate("GST Invoice", false);
        PurchaseHeader.Modify(true);
    end;

    //[Senerio 356419]	[Check after Change GST Group on line]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckAfterChangeGSTGroupOnLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Assert: Codeunit "Library Assert";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(2)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseLine.SetFilter("GST Group Code", '<>%1', '');
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    //[Senerio 356420] [Check Change Exempted on Purchase line]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckChangeExemptedonPurchaseline()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Assert: Codeunit "Library Assert";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(2)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseLine.Validate(Exempted, true);
        PurchaseLine.Modify(true);
        Assert.IsTrue(PurchaseLine.Exempted, 'Not Equal');
    end;
    //[Senerio 356428] [Check Validation for Custom Duty Amount and Assessable Value on Purchase line.]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckValidationforCustomDutyAmountandAssessableValueonPurchaseline()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseLine.Validate("GST Assessable Value", 0.0);
        PurchaseLine.Modify(true);
    end;

    //[Senerio 357173] [Check if change invoice type then document should be open and Invoice type - supplementary, updated on line also.]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckInvoiceTypeSupplementaryPurchaseline()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine, PurchaseLine2 : Record "Purchase Line";
        Assert: Codeunit "Library Assert";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        SupplementaryLbl: Label 'Supplementary if false', Locked = true;
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Goods, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::Supplementary);
        PurchaseHeader.Modify(true);
        PurchaseLine2.Reset();
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine2.SetRange("Document Type", PurchaseLine2."Document Type"::"Invoice");
        PurchaseLine2.FindFirst();
        Assert.IsTrue(PurchaseLine2.Supplementary, SupplementaryLbl);
    end;

    //[Senerio 356400] [Check After change Location Code and POS on Purchase Header]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckAfterChangeLocationCodeAndPOSonPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Assert: Codeunit "Library Assert";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        POSLbl: Label 'POS as Vendor State is false';
    begin
        //[GIVEN] Create GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);

        //[WHEN] Create  Purchase Order with validation
        Storage.Set('NoOfLine', (format(1)));
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", DocumentType::Invoice);
        PurchaseHeader.Validate("POS as Vendor State", true);
        PurchaseHeader.Modify(true);
        Assert.IsTrue(PurchaseHeader."POS as Vendor State", POSlbl);
    end;

    //[Senerio 356317] [Check Vendor related validation as PAN No, Registration No. GST Vendor type, Vendor State Code etc.]
    [Test]
    procedure CheckVendorRelatedValidations()
    var
        Vendor: Record Vendor;
        Assert: Codeunit "Library Assert";
        ErrorLbl: Label 'State Code must have a value in Vendor: No.=%1.', Comment = '%1 = Vendor No.';
        PanErr: Label 'PAN No. must be entered.', Locked = true;
    begin
        Vendor.Reset();
        Vendor.Get(LibraryGST.CreateVendorSetup());
        asserterror Vendor.Validate("GST Registration No.", Format(Random(15)));
        Assert.ExpectedError(StrSubstNo(ErrorLbl, Vendor."No."));
        Vendor.Reset();
        Vendor.Get(LibraryGST.CreateVendorSetup());
        Vendor.Validate("State Code", LibraryGST.CreateGSTStateCode());
        Vendor.Modify(true);
        asserterror Vendor.Validate("GST Registration No.", Format(Random(15)));
        Assert.ExpectedError(PanErr);
    end;

    //[Senerio 354996]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise. through Purchase order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForFixedAssetWithInputTaxCreditWithForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //[Senerio 354999]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForFixedAssetWithInputTaxCreditWithLineDiscountForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //[Senerio 355004]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with invoice discount/line discount & multiple HSN code wise through Purchase order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForFixedAssetWithLineDiscountForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 8);
    end;

    //[Senerio 355005]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with invoice discount/line discount&multiple HSN code wise through Purchase Invoice]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForFixedAssetWithLineDiscountForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 8);
    end;

    //[Senerio 355008]	[Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForFixedAssetWithLineDiscountWithITCForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Senerio 355009]	[Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForFixedAssetWithLineDiscountWithITCForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
        PurchaseLine,
        LineType::"Fixed Asset",
        DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 5);
    end;

    //[Senerio 355036]	[Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with invoice discount/line discount and multiple HSN code wise through Purchase order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForFixedAssetWithLineDiscountWithoutITCForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Order Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //[Senerio 355037]	[Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Registered Vendor where Input Tax Credit is not available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceForFixedAssetWithLineDiscountWithoutITCForInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, true);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Invoice with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 6);
    end;

    //[Senerio 353747]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseInvoiceRegisteredVendorForGoodsForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Order with Fixed Asset
        Storage.Set('NoOfLine', (format(2)));
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::Item,
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //[Senerio 353749] [Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase of Goods from Registered Vendor where Input Tax Credit is available through Purchase Quote]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromIntrastatePurchaseGoodsQuoteForRegisteredVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as GLAccount for Intrastate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type");
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario- 353859 Check if the system is calculating GST in case of Inter-State Purchase of Services from Registered Vendor where Input Tax Credit is available through Purchase Quotes
    //[FEATURE] [Purchase Quote] [Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseQuoteRegisterdVendorWithoutITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(
                         PurchaseHeader,
                         PurchaseLine,
                         LineType::Item,
                         DocumentType::Quote);

        //[THEN] Make Order from Quote
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type");
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario- 353840 Check if the system is calculating GST in case of Inter-State Purchase of Goods from Registered Vendor where Input Tax Credit is not available through Purchase Invoice
    //[FEATURE] [Purchase Invoice] [Without ITC Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceRegisterdVendorWithoutITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedInvoiceNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Interstate Transactions.
        PostedInvoiceNo := CreateAndPostPurchaseDocument(
                                PurchaseHeader,
                                PurchaseLine,
                                LineType::Item,
                                DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, PostedInvoiceNo, 3);

    end;

    [ConfirmHandler]
    procedure ChangeVendor(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateGSTSetup(GSTVendorType: Enum "GST Vendor Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean; ReverseCharge: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        LocationStateCode: Code[10];
        VendorNo: Code[20];
        GSTGroupCode: Code[20];
        LocationCode: Code[10];
        HSNSACCode: Code[10];
        VendorStateCode: Code[10];
        LocPan: Code[20];
        LocationGSTRegNo: Code[15];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
    begin
        CompanyInformation.Get();

        if CompanyInformation."P.A.N. No." = '' then begin
            CompanyInformation."P.A.N. No." := LibraryGST.CreatePANNos();
            CompanyInformation.Modify();
        end else
            LocPan := CompanyInformation."P.A.N. No.";
        LocPan := CompanyInformation."P.A.N. No.";
        LocationStateCode := LibraryGST.CreateInitialSetup();
        Storage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);
        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.MODIFY(TRUE);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, FALSE);
        Storage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType, GSTGroup."GST Place Of Supply"::"Bill-to Address", ReverseCharge);
        Storage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::HSN);
        Storage.Set('HSNSACCode', HSNSACCode);

        if IntraState then begin
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            VendorStateCode := LibraryGST.CreateGSTStateCode();
            VendorNo := LibraryGST.CreateVendorSetup();
            UpdateVendorSetupWithGST(VendorNo, GSTVendorType, false, VendorStateCode, LocPan);
            Storage.Set('VendorStateCode', VendorStateCode);
            if GSTVendorType in [GSTVendorType::Import, GSTVendorType::SEZ] then
                InitializeTaxRateParameters(IntraState, LocationStateCode, '')
            else begin
                InitializeTaxRateParameters(IntraState, VendorStateCode, LocationStateCode);
                CreateGSTComponentAndPostingSetup(IntraState, VendorStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        Storage.Set('VendorNo', VendorNo);

        CreateTaxRate(false);
        CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
    end;

    local procedure InitializeShareStep(InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean)
    begin
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        StorageBoolean.Set('Exempted', Exempted);
        StorageBoolean.Set('LineDiscount', LineDiscount);
    end;

    procedure UpdateVendorSetupWithGST(VendorNo: Code[20];
                        GSTVendorType: Enum "GST Vendor Type";
                        AssociateEnterprise: boolean;
                        StateCode: Code[10];
                        Pan: Code[20]);
    var
        Vendor: Record Vendor;
        State: Record State;
    begin
        Vendor.Get(VendorNo);
        if (GSTVendorType <> GSTVendorType::Import) then begin
            State.Get(StateCode);
            Vendor.Validate("State Code", StateCode);
            Vendor.Validate("P.A.N. No.", Pan);
            if not ((GSTVendorType = GSTVendorType::" ") OR (GSTVendorType = GSTVendorType::Unregistered)) then
                Vendor.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;
        Vendor.Validate("GST Vendor Type", GSTVendorType);
        if Vendor."GST Vendor Type" = vendor."GST Vendor Type"::Import then
            vendor.Validate("Associated Enterprises", AssociateEnterprise);
        Vendor.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header";
                           var PurchaseLine: Record "Purchase Line";
                           LineType: Enum "Purchase Line Type";
                           DocumentType: Enum "Purchase Document Type"): Code[20];
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        VendorNo: Code[20];
        LocationCode: Code[10];
        DocumentNo: Code[20];
        PurchaseInvoiceType: Enum "GST Invoice Type";
    begin
        Evaluate(VendorNo, Storage.Get('VendorNo'));
        Evaluate(LocationCode, Storage.Get('LocationCode'));
        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo, DocumentType, LocationCode, PurchaseInvoiceType::" ");
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        if not (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote) then begin
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, TRUE);
            exit(DocumentNo);
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header";
                          var PurchaseLine: Record "Purchase Line";
                          LineType: Enum "Purchase Line Type";
                          DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        LibraryRandom: Codeunit "Library - Random";
        VendorNo: Code[20];
        LocationCode: Code[10];
        PurchaseInvoiceType: Enum "GST Invoice Type";
    begin
        Evaluate(VendorNo, Storage.Get('VendorNo'));
        Evaluate(LocationCode, Storage.Get('LocationCode'));
        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo, DocumentType, LocationCode, PurchaseInvoiceType::" ");
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseHeaderWithGST(VAR PurchaseHeader: Record "Purchase Header";
                           VendorNo: Code[20];
                           DocumentType: Enum "Purchase Document Type";
                           LocationCode: Code[10];
                           PurchaseInvoiceType: Enum "GST Invoice Type")
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Overseas: Boolean;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.VALIDATE("Location Code", LocationCode);
        if Overseas then
            PurchaseHeader.Validate("POS Out Of India", true);
        if PurchaseInvoiceType in [PurchaseInvoiceType::"Debit Note", PurchaseInvoiceType::Supplementary] then
            PurchaseHeader.validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Invoice No."), Database::"Purchase Header"))
        else
            PurchaseHeader.validate("Vendor Cr. Memo No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Vendor Cr. Memo No."), Database::"Purchase Header"));
        if PurchaseHeader."GST Vendor Type" = PurchaseHeader."GST Vendor Type"::SEZ then begin
            PurchaseHeader."Bill of Entry No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.fieldno("Bill of Entry No."), Database::"Purchase Header");
            PurchaseHeader."Bill of Entry Date" := WorkDate();
            PurchaseHeader."Bill of Entry Value" := LibraryRandom.RandInt(1000);
        end;
        PurchaseHeader.MODIFY(TRUE);
    end;

    local procedure CreatePurchaseLineWithGST(VAR PurchaseHeader: Record "Purchase Header"; VAR PurchaseLine: Record "Purchase Line"; LineType: Enum "Purchase Line Type"; Quantity: Decimal; InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LineTypeNo: Code[20];
        LineNo: Integer;
        NoOfLine: Integer;
    begin
        Exempted := StorageBoolean.Get('Exempted');
        Evaluate(NoOfLine, Storage.Get('NoOfLine'));
        InputCreditAvailment := StorageBoolean.Get('InputCreditAvailment');
        for LineNo := 1 to NoOfLine do begin
            case LineType of
                LineType::Item:
                    LineTypeNo := LibraryGST.CreateItemWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, Exempted);
                LineType::"G/L Account":
                    LineTypeNo := LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, FALSE);
                LineType::"Fixed Asset":
                    LineTypeNo := LibraryGST.CreateFixedAssetWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), InputCreditAvailment, Exempted);
            end;

            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, LineTypeno, Quantity);

            PurchaseLine.VALIDATE("VAT Prod. Posting Group", VATPostingsetup."VAT Prod. Posting Group");
            if InputCreditAvailment then
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::Availment
            else
                PurchaseLine."GST Credit" := PurchaseLine."GST Credit"::"Non-Availment";

            if LineDiscount then begin
                PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));
                LibraryGST.UpdateLineDiscAccInGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            end;

            if ((PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ])) and (PurchaseLine.Type = PurchaseLine.Type::"Fixed Asset") then
                PurchaseLine.Validate("GST Assessable Value", LibraryRandom.RandInt(1000))
            else
                if (PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) then begin
                    PurchaseLine.Validate("GST Assessable Value", LibraryRandom.RandInt(1000));
                    PurchaseLine.Validate("Custom Duty Amount", LibraryRandom.RandInt(1000));
                end;
            PurchaseLine.VALIDATE("Direct Unit Cost", LibraryRandom.RandInt(1000));
            PurchaseLine.MODIFY(TRUE);
        end;
    end;

    local procedure UpdateInputServiceDistributer(InputServiceDistribute: Boolean; InputCreditAvailment: Boolean)
    var
        LocationCod: Code[10];
    begin
        InputCreditAvailment := InputCreditAvailment;
        StorageBoolean.Set('InputCreditAvailment', InputCreditAvailment);
        LocationCod := CopyStr(Storage.Get('LocationCode'), 1, 10);
        LibraryGST.UpdateLocationWithISD(LocationCod, InputServiceDistribute);
    end;

    local procedure CreateGSTComponentAndPostingSetup(IntraState: Boolean; LocationStateCode: Code[10]; GSTComponent: Record "Tax Component"; GSTcomponentcode: Text[30]);
    begin
        IF IntraState THEN begin
            GSTcomponentcode := 'CGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'UTGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

            GSTcomponentcode := 'SGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end else begin
            GSTcomponentcode := 'IGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end;
    end;

    Local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        LibraryRandom: Codeunit "Library - Random";
        GSTTaxPercent: Decimal;
    begin
        Storage.Set('FromStateCode', FromState);
        Storage.Set('ToStateCode', ToState);
        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);
        if IntraState then begin
            ComponentPerArray[1] := (GSTTaxPercent / 2);
            ComponentPerArray[2] := (GSTTaxPercent / 2);
            ComponentPerArray[3] := 0;
        end else
            ComponentPerArray[4] := GSTTaxPercent;
    end;

    procedure CreateTaxRate(POS: boolean)
    var
        TaxTypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TaxTypeSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxTypeSetup.Code);
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(Storage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(Storage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(WorkDate());
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', WorkDate()));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]);
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]);
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]);
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]);
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]);
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]);
        TaxRate.AttributeValue13.SetValue('');
        TaxRate.AttributeValue14.SetValue('');
        TaxRate.OK().Invoke();
    end;

    var
        LibraryGST: Codeunit "Library GST";
        Storage: Dictionary of [Text, Text];
        ComponentPerArray: array[20] of Decimal;
        StorageBoolean: Dictionary of [Text, Boolean];
}