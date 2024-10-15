codeunit 18133 "GST Purchase Import"
{
    Subtype = Test;

    //Scenario-355915 Check if the system is calculating GST in case of Import of Goods from Foreign Vendor where Input Tax Credit is available  through Purchase Invoice.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportofGoodsFromForeignVendorWithGSTCreditAvailmentThroughPurchaseInvoice()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                            PurchaseLine,
                                            LineType::Item,
                                            DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355916 Check if the system is calculating GST in case of Import of Services from Foreign Vendor where Input Tax Credit is available  through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportofServicesFromForeignVendorWithGSTCreditAvailmentThroughPurchaseInvoice()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355917 Check if the system is calculating GST in case of Import of Goods from Foreign Vendor where Input Tax Credit is not available  through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportofGoodsFromForeignVendorWithoutGSTCreditAvailmentThroughPurchaseInvoice()
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
        GSTVendorType := GSTVendorType::Import;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;
        InputCreditAvailment := false;
        LineDiscount := false;
        Exempted := false;
        NoOfLine := 1;

        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType, GSTGroupType, IntraState, false);
        InitializeShareStep(InputCreditAvailment, Exempted, LineDiscount);
        Storage.Set('NoOfLine', (Format(NoOfLine)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
              PurchaseHeader,
              PurchaseLine,
              LineType::"G/L Account",
              DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355919 Check if the system is calculating GST in case of Import of Services from Foreign Vendor where Input Tax Credit is not available  through Purchase Invoice.
    [Test]

    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportofServicesFromForeignVendorWithoutGSTCreditAvailmentThroughPurchaseInvoice()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                PurchaseLine,
                                                LineType::"G/L Account",
                                                DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355396 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase Order.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorwithMultipleHSNCodeWiseThroughPurchaseOrder()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355397 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorwithMultipleHSNCodeWiseThroughPurchaseInvoice()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355428 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is not available with invoice discount/line discount and multiple HSN code wise through Purchase order.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorWithoutITCWithMultipleHSNCodeThroughPurchaseOrder()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //Scenario-355429 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is not available with invoice discount/line discount and multiple HSN code wise through Purchase Invoice.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorWithoutITCWithMultipleHSNCodeThroughPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
    end;

    //Scenario-355437 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase order.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorWithoutITCThroughPurchaseOrder()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-355438 Check if the system is calculating GST in case of Import Purchase of Fixed Assets from Foreign Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Invoice.
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure ImportPurchaseofFixedAssetFromForeignVendorWithoutITCThroughPurchaseInvoice()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as FixedAsset for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"Fixed Asset",
                                                    DocumentType::Invoice);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-354127 Check if the system is calculating GST in case of Services from Associates Enterprises Vendor where Input Tax Credit is available through Purchase Quote.
    //[FEATURE] [Services Purchase Quote] [Inter-State GST,Associate Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesQuoteForAssociateVendorWithAvailment()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeAssociateVendor(true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type"::Quote);
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354128 Check if the system is calculating GST in case of Import of Goods from Associates Enterprises Vendor where Input Tax Credit is available through Purchase Order.
    //[FEATURE] [Goods Purchase Order] [Inter-State GST,Associate Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsOrderForAssociateVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeAssociateVendor(true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::Item,
                          PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-354129 Check if the system is calculating GST in case of Services from Associates Enterprises Vendor where Input Tax Credit is not available through Purchase Quote.
    //[FEATURE] [Services Purchase Quote] [Inter-State GST,Associate Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesQuoteForAssociateVendorWithoutAvailment()
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
        InitializeAssociateVendor(true);
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type"::Quote);
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354874 Check if the system is calculating GST in case of Import of Goods from Foreign Vendor where Input Tax Credit is available through Purchase Quote.
    //[FEATURE] [Goods Purchase Quote] [Inter-State GST,Import Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseGoodsQuoteForImportVendorWithAvailment()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created Purchase Quote with GST and Line Type as Item for Interstate Transactions.
        DocumentNo := CreatePurchaseDocument(PurchaseHeader,
                                PurchaseLine,
                                LineType::Item,
                                PurchaseHeader."Document Type"::Quote);

        //[THEN] Quote to Make Order
        LibraryGST.VerifyTaxTransactionForPurchase(DocumentNo, PurchaseLine."Document Type"::Quote);
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //Scenario-354889 Check if the system is calculating GST in case of Import of Services from Foreign Vendor where Input Tax Credit is available through Purchase Order.
    //[FEATURE] [Services Purchase Order] [Inter-State GST,Import Vendor Input Tax Credit is available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesOrderForImportVendorWithAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //Scenario-354118 Check if the system is calculating GST in case of Import of Service from Foreign Vendor where Input Tax Credit is not available through Purchase Order.
    //[FEATURE] [Services Purchase Order] [Inter-State GST,Import Vendor Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromInterstatePurchaseServicesOrderForImportVendorWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GSTVendorType: Enum "GST Vendor Type";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup 
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as GLAccount for Interstate Transactions.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader,
                                                    PurchaseLine,
                                                    LineType::"G/L Account",
                                                    PurchaseHeader."Document Type"::Order);

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 353900] Check if the system is calculating GST in case of Import of Services from Foreign Vendor where Input Tax Credit is available through Purchase Quote
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromQuoteForServiceImportWithAvailmentIntraSate()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);

        //[WHEN] Create Purchase Order from Purchase Quote
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

    //[Scenario 353905] Check if the system is calculating GST in case of Import of Goods from Foreign Vendor where Input Tax Credit is available through Purchase Order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForGoodsImportWithAvailmentInterSate()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Journal
        Storage.Set('NoOfLine', Format(1));
        DocumentNo := CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Order);

        //Verified GST Ledger Entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 1);
    end;

    //[Scenario 353914] Check if the system is calculating GST in case of Import of Goods from Foreign Vendor where Input Tax Credit is not available through Purchase Quote
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreatePurchaseOrderFromQuoteForGoodsImportWithAvailmentIntraSate()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Purchase Quote
        Storage.Set('NoOfLine', Format(1));
        CreatePurchaseDocument(
                PurchaseHeader,
                PurchaseLine,
                LineType::Item,
                DocumentType::Quote);


        //Make Quote to Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);
    end;

    //[Scenario 354113] Check if the system is calculating GST in case of Import of service from Foreign Vendor where Input Tax Credit is not available through Purchase Order with multiple line
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure PostFromPurchaseOrderForServiceImportWithoutAvailmentInterSate()
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
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Purchase Order
        Storage.Set('NoOfLine', Format(2));
        DocumentNo := CreateAndPostPurchaseDocument(
                          PurchaseHeader,
                          PurchaseLine,
                          LineType::"G/L Account",
                          DocumentType::Order);

        //Verified GST Ledger Entries
        LibraryGST.GSTLedgerEntryCount(DocumentNo, 2);
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
            if StorageBoolean.ContainsKey('AssociateEnterprise') then begin
                UpdateVendorSetupWithGST(VendorNo, GSTVendorType, StorageBoolean.Get('AssociateEnterprise'), VendorStateCode, LocPan);
                StorageBoolean.Remove('AssociateEnterprise')
            end else
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

    local procedure InitializeAssociateVendor(AssociateEnterprise: Boolean)
    begin
        StorageBoolean.Set('AssociateEnterprise', AssociateEnterprise);
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
            Vendor.Validate("Associated Enterprises", AssociateEnterprise);
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
        if PurchaseHeader."GST Vendor Type" IN [PurchaseHeader."GST Vendor Type"::Import, PurchaseHeader."GST Vendor Type"::SEZ] then begin
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