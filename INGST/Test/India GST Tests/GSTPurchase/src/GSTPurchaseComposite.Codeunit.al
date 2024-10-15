codeunit 18132 "GST Purchase Composite"
{
    Subtype = Test;
    //Scenario-355253 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [ITC Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderCompositeVendorWithITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355254 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceCompositeVendorWithITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355260 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [Without ITC Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
        NoOfLine: Integer;
        IntraState: Boolean;
        InputCreditAvailment: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
    begin
        GSTVendorType := GSTVendorType::Composite;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;
        InputCreditAvailment := false;
        LineDiscount := false;
        Exempted := false;
        NoOfLine := 2;

        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType, GSTGroupType, IntraState, false);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        Storage.Set('NoOfLine', (Format(NoOfLine)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355261 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [Without ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
        NoOfLine: Integer;
        IntraState: Boolean;
        InputCreditAvailment: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
    begin
        GSTVendorType := GSTVendorType::Composite;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;
        InputCreditAvailment := false;
        LineDiscount := false;
        Exempted := false;
        NoOfLine := 2;

        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType, GSTGroupType, IntraState, false);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        Storage.Set('NoOfLine', (Format(NoOfLine)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355081 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with invoice discount/line discount multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount ITC Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceCompositeVendorWitITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
        NoOfLine: Integer;
        IntraState: Boolean;
        InputCreditAvailment: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
    begin
        GSTVendorType := GSTVendorType::Composite;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;
        InputCreditAvailment := true;
        LineDiscount := true;
        Exempted := false;
        NoOfLine := 2;

        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType, GSTGroupType, IntraState, false);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        Storage.Set('NoOfLine', (Format(NoOfLine)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355185 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [invoice discount/line discount ITC,Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderCompositeVendorWithITCWithLineDiscountForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
        NoOfLine: Integer;
        IntraState: Boolean;
        InputCreditAvailment: Boolean;
        Exempted: Boolean;
        LineDiscount: Boolean;
    begin
        GSTVendorType := GSTVendorType::Composite;
        IntraState := true;
        GSTGroupType := GSTGroupType::Goods;
        InputCreditAvailment := true;
        LineDiscount := true;
        Exempted := false;
        NoOfLine := 2;

        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType, GSTGroupType, IntraState, false);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        Storage.Set('NoOfLine', (Format(NoOfLine)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355196 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available with invoice discount/line discount and multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [invoice discount/line discount ITC,Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseOrderCompositeVendorWithoutITCWithLineDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355197 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is Not available with invoice discount/line discount and multiple HSN code wise. through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Order] [invoice discount/line discount ITC,Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostGSTPurchaseInvoiceCompositeVendorWithoutITCWithLineDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"Fixed Asset", DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355082 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with invoice discount/line discount multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [Line Discount ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseInvoiceCompositeVendorWithITCWithDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355183 Check if the system is calculating GST in case of Intra-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Invoice] [Line Discount ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseOrderCompositeVendorWithITCWithDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355089 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available with invoice discount/line discount multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Invoice] [Line Discount ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseInvoiceCompositeVendorWithoutITCWithDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355090 Check if the system is calculating GST in case of Inter-State Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available with invoice discount/line discount multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [Line Discount ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseOrderCompositeVendorWithoutITCWithDiscountForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 4);
    end;

    //Scenario-355169 Check if the system is calculating GST in case of Inter-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available and multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseOrderCompositeVendorWithITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355170 Check if the system is calculating GST in case of Inter-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is available and multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseInvoiceCompositeVendorWithITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355177 Check if the system is calculating GST in case of Inter-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available and multiple HSN code wise through Purchase order
    //[FEATURE] [Fixed Assets Purchase Order] [Without ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseOrderCompositeVendorWithoutITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355178 Check if the system is calculating GST in case of Inter-state Purchase of Fixed Assets from Composite Vendor where Input Tax Credit is not available and multiple HSN code wise through Purchase Invoice
    //[FEATURE] [Fixed Assets Purchase Invoice] [Without ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseInvoiceCompositeVendorWithoutITCForFixedAsset()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //Scenario-355912 Check if the system is handling Purchase of Services from Composite Vendor/Supplier of exempted services with no GST Impact through Purchase Invoice
    //[FEATURE] [Service Purchase Invoice] [ITC, Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostInterStateGSTPurchaseInvoiceCompositeVendorWithITCForService()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::Invoice, DocumentNo, 3);
    end;

    //[Scenario 353787] Check if the system is handling Purchase of Goods from Composite Vendor/Supplier of exempted goods with no GST Impact  through Purchase Quote
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromQuoteForCompositeWithAvailmentIntraSate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: codeunit "Library - Purchase";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(true, false, false);
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Quote
        Storage.Set('NoOfLine', Format(2));
        CreatePurchaseDocument(
                PurchaseHeader,
                PurchaseLine,
                LineType::Item,
                DocumentType::Quote);

        //Make Quote to Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;


    //[Scenario 353799] Check if the system is handling Purchase of Goods from Composite Vendor/Supplier of exempted goods with no GST Impact through Purchase Order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForCompostiteWithAvailmentIntraSate()
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
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Order
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                         PurchaseHeader,
                         PurchaseLine,
                         LineType::Item,
                         DocumentType::Order);

        //Verified GST Ledger Entried
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 0);
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
            VendorStateCode := LibraryGST.CreateGSTStateCode(); //
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

            if (PurchaseHeader."GST Vendor Type" in [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ]) and
                        (not (PurchaseLine.Type in [PurchaseLine.Type::" ", PurchaseLine.Type::"Charge (Item)"])) then begin
                PurchaseLine.Validate("GST Assessable Value", LibraryRandom.RandInt(1000));
                if PurchaseLine.Type In [PurchaseLine.Type::Item, PurchaseLine.Type::"G/L Account"] then
                    PurchaseLine.Validate("Custom Duty Amount", LibraryRandom.RandInt(1000));
            end;
            PurchaseLine.VALIDATE("Direct Unit Cost", LibraryRandom.RandInt(1000));
            PurchaseLine.MODIFY(TRUE);
        end;
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

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
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