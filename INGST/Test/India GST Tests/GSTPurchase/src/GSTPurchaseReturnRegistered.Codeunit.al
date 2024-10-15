codeunit 18138 "GST Purchase Return Registered"
{
    Subtype = Test;

    //[Scenario-353866]	[Check if the system is calculating GST in case of Inter-State Purchase Return of Service to Registered Vendor where Input Tax Credit is available through Purchase Return orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorWithITCForServiceInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as G/L Account for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                                    PurchaseHeader,
                                    PurchaseLine,
                                    LineType::"G/L Account",
                                    DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario-353867] [Check if the system is calculating GST in case of Inter-State Purchase Return of Service to Registered Vendor where Input Tax Credit is available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoRegisterdVendorWithITCForServiceInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                                PurchaseHeader,
                                PurchaseLine,
                                LineType::"G/L Account",
                                DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario-353871] [Check if the system is calculating GST in case of Inter-State Purchase Return of Services to Registered Vendor where Input Tax Credit is not available through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorForServiceInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Service for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //[Scenario-353872] [Check if the system is calculating GST in case of Inter-State Purchase Return of Services to Registered Vendor where Input Tax Credit is not available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoRegisterdVendorForServiceInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Service for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                                    PurchaseHeader,
                                    PurchaseLine,
                                    LineType::"G/L Account",
                                    DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //[Scenario 353806] [Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase Return of Service to Registered Vendor where Input Tax Credit is Non-available through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorForServiceIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 353807] [Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase Return of Service to Registered Vendor where Input Tax Credit is Non-available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoRegisterdVendorForServiceIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 353795]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase Return of Service to Registered Vendor where Input Tax Credit is available through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorWithITCForServiceIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354205][Check if the system is calculating GST in case of Purchase Return Order for Imported Services where Input Tax Credit is available on purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderImportVendorWithITCForServiceIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    // [Scenario 354206] [Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services where Input Tax Credit is available through purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderImportVendorWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    // [Scenario 354208] [Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services where Input Tax Credit is available through purchase Credit Memo Copy with Document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoImportVendorWithITCForServiceWithCopyDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354143]	[Check if the system is calculating GST in case of Purchase Return Order for Imported Goods where Input Tax Credit is available on purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderImportGoodsWithITCForIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354167]	[Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Goods where Input Tax Credit is available through purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderImportedGoodsWithITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");
        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354168]	[Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Goods where Input Tax Credit is available through purchase Credit Memo Copy with Document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoImportedGoodsWithITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354170]	[Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Goods where Input Tax Credit is available through Credit Memo]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoImportedGoodsWithITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354171]	[Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Goods where Input Tax Credit is available through Purchase Credit Memo with get reversed posted document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfImportedGoodsUsingGetDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 355659]	[Check if the system is calculating GST in case of Intra-State Purchase Return/Credit Memo of Services from Registered Vendor with Multiple Lines by Input Service Distributor where Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseReturnOrderRegisterdVendorForServiceIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup and 
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        InitializeShareStep(false, false, false);
        UpdateInputServiceDistributer(true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Service for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 353785]	[Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Goods to Registered Vendor where Input Tax Credit is Non-available through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseReturnOrderOfGoodsFromRegisteredVendorWithoutInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Item.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 353808]	[Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Goods to Registered Vendor where Input Tax Credit is available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfGoodsFromRegisteredVendorWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Item.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 353810]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase Return of Service to Registered Vendor where Input Tax Credit is available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfServicesFromRegisteredVendorWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Services.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 353809]	[Check if the system is calculating GST in case of Intra-State/Intra-Union Territory Purchase Return of Service to Registered Vendor where Input Tax Credit is available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfGoodsFromRegisterVendorWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as G/L Account.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354124] [Check if the system is calculating GST in case of Intra-State Purchase Return of Services to Unregistered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderUnRegisterdVendorForServicesIntraStateReverseChargeWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as G/L Account for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 354126] [Check if the system is calculating GST in case of Intra-State Purchase Return of Services to Unregistered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoUnRegisterdVendorForServicesIntraStateReverseChargeWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as G/L Account for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //Scenario-353856 Check if the system is calculating GST in case of Inter-State Purchase Return of Goods to Registered Vendor where Input Tax Credit is not available through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [Without ITC Register Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseCreditMemoVendorWithoutITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Goods for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //Scenario-353850 Check if the system is calculating GST in case of Inter-State Purchase Return of Goods to Registered Vendor where Input Tax Credit is not available through Purchase Return Orders
    //[FEATURE] [Item Purchase Return Order] [Without ITC Register Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseReturnOrderVendorWithoutITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Goods for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;


    //Scenario- 354210 Check if the system is calculating GST in case of Purchase Credit Memo for Imported Services where Input Tax Credit is available
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [Import Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseCreditMemoImportVendorWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 5);
    end;

    //Scenario-354213 Check if the system is calculating GST in case of Purchase Return Order for Imported Services where Input Tax Credit is not available on purchase return order
    //[FEATURE] [Fixed Assets Purchase Return Order] [Without ITC Import Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseReturnOrderImportVendorWithoutITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Service for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //Scenario- 354216 Check if the system is calculating GST in case of Purchase Credit Memo for Imported Services where Input Tax Credit is not available
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [Without ITC Import Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseCreditMemoImportVendorWithoutITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //Scenario- 354214 Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services where Input Tax Credit is not available through purchase return order
    //[FEATURE] [Service Purchase Return Order] [Without ITC Import Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseReturnOrderImportVendorWithoutITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //Scenario- 354215 Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services where Input Tax Credit is not available through purchase Credit Memo Copy with Document
    //[FEATURE] [Fixed Assets Purchase Crdit Memo] [Without ITC Import Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseCreditMemoCopyDocumentImportVendorWithoutITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //Scenario-354862 Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase Return Order] [Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 5);
    end;

    //Scenario-354866 Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is available with multiple HSN code wise through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoRegisterdVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 5);
    end;

    //Scenario-354877 Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase Return Order] [Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderRegisterdVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"Fixed Asset", DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 7);
    end;

    //Scenario-354884 Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [Registered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoRegisterdVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Intrastate Transactions.
        CreateAndPostPurchaseDocument(PurchaseHeader,
                                    PurchaseLine,
                                    LineType::"Fixed Asset",
                                    DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 7);
    end;

    //Scenario- 354218 Check if the system is calculating GST in case of Purchase Return Order for Imported Services from Associates Enterprises Vendor where Input Tax Credit is available on purchase return order
    //[FEATURE] [Service Purchase Return Order] [ITC Associates Enterprises Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseReturnOrderAssociatedVendorWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    //Scenario- 354219 Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services from Assioiates Enterprises Vendor where Input Tax Credit is available through purchase return order 
    //[FEATURE] [Service Purchase Return Order] [ITC Associates Enterprises Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseReturnOrderAssociatedTypeVendorWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    //Scenario-354220  Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services from Associated Enterprises Vendor where Input Tax Credit is available through purchase Credit Memo Copy with Document
    //[FEATURE] [Service Purchase Credit Memo] [ITC Associates Enterprises Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseCreditMemoAssociatedVendorWithCopyDocumentWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    //Scenario- 354221 Check if the system is calculating GST in case of Purchase Credit Memo for Imported Services from Associate Enterprises Vendor where Input Tax Credit is available
    //[FEATURE] [Service Purchase Credit Memo] [ITC Associates Enterprises Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    Procedure PostGSTPurchaseCreditMemoAssociatedTypeVendorWithITCForService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, false);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Credit Memo with GST and Line Type as Servicefor Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;


    //[Scenario 353913] [Check if the system is calculating GST in case of Intra-State Purchase Return of Goods to Unregistered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchasCreditMemoUnRegisterdVendorForGoodsIntraStateReverseChargeWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Item for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 353910] [Check if the system is calculating GST in case of Intra-State Purchase Return of Goods to Unregistered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderUnRegisterdVendorForGoodsIntraStateWithoutITCReverseCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Service, true, true);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Item for Intrastate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;
    // [Scenario 354227] [Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services from Assiciates Enterprises Vendor where Input Tax Credit is not available through purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfImportedServiceFromAssociates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as G/L Account.
        CreateAndPostPurchaseDocument(PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    // [Scenario 354228] [Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services from Associated Enterprises Vendor where Input Tax Credit is not available through purchase Credit Memo Copy with Document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfImportedServiceFromAssociatesWithCopyDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    // [Scenario 354229] [Check if the system is calculating GST in case of Purchase Credit Memo for Imported Services from Associate Enterprises Vendor where Input Tax Credit is not available]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfImportedServiceFromAssociatesWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as G/L Account.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    // [Scenario 354231] [Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Services from Associates Enterprises Vendor where Input Tax Credit is not available through Purchase Credit Memo with get reversed posted document]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfImportedServiceFromAssociatesWithGetReversedDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as G/L Account.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    //Scenario-355087 Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is available with invoice discount /line discount & multiple HSN through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase Return Order] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderCompositeVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355167 Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is not available with invoice discount /line discount & multiple HSN through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase Return Order] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnOrderCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355088 Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is available with invoice/line discount & multiple HSN through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memos] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemosCompositeVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Inter-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355168 Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is not available with invoice/line discount & multiple HSN through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memos] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemosCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Order with GST and Line Type as Fixed Asset for Inter-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355187 Check if the system is calculating GST in case of Intra-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is available with invoice discount /line discount & multiple HSN through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase  Return Order] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnCompositeVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Intra-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355188 Check if the system is calculating GST in case of Intra-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is available with invoice/line discount & multiple HSN through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase  Credit Memo] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoCompositeVendorWithITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Intra-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355241 Check if the system is calculating GST in case of Intra-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is not available with invoice/line discount & multiple HSN through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase  Credit Memo] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Intra-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;

    //Scenario-355240 Check if the system is calculating GST in case of Intra-State Purchase Return of Fixed Assets to Composite Vendor where Input Tax Credit is not available with invoice discount /line discount & multiple HSN through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase  Return Order] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseReturnCompositeVendorWithoutITCForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Intra-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 4);
    end;
    //Scenario- 353812 Check if the system is handling Purchase Return of Goods to Composite Vendor/Supplier of exempted goods with no GST Impact through Purchase Credit Memo and copy document
    //[FEATURE] [Item Purchase Credit Memo] [Composite Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseCreditMemoCompositeVendorWithITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, true, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Goods for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 2);
    end;

    //Scenario- 353818 Check if the system is calculating GST in case of Inter-State Purchase Return of Goods to Registered Vendor where Input Tax Credit is available through Purchase Return Orders
    //[FEATURE] [Fixed Assets Purchase Return Order] [With ITC Register Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseRetrunOrderVendorWithoutITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Goods for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //Scenario- 353836 Check if the system is calculating GST in case of Inter-State Purchase Return of Goods to Registered Vendor where Input Tax Credit is available through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memo] [With ITC Register Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFormGSTPurchaseReturnOrderRegisterVendorWithITCForItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Return Order with GST and Line Type as Goods for Interstate Transactions.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //[Scenario 354135] Check if the system is calculating GST in case of Intra-State Purchase Return of Services to Registered Vendor where Input Tax Credit is available (Reverse Charge) through Purchase Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFromPurchaseCreditMemoForRegisteredWithAvailment()
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
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, true);

        //[WHEN] Create and Post Purchase Credit Memo
        Storage.Set('NoOfLine', Format(1));
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Credit Memo");

        //[THEN] Verify GST ledger entries
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 354140] Check if the system is calculating GST in case of Intra-State Purchase Return of Services to Registered Vendor where Input Tax Credit is not available (Reverse Charge) through Purchase Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFromPurchaseCreditMemoForRegisteredWithoutAvailmentIntraStateCopyDoc()
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

        //[WHEN] Create and Post Purchase Credit memo
        Storage.Set('NoOfLine', Format(1));
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Credit Memo");

        //[THEN] Verify GST ledger entries
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 3);
    end;

    //[Scenario 354520] Check if the system is calculating GST in case of Intra-State Return/Credit Note of Services for Overseas Place of Supply from Registered Vendor where Input Tax Credit is available through Purchase credit memo
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFromPurchaseCreditMemoForRegistredAndGoodsWithAvailmentIntraState()
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
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        StorageBoolean.set('PlaceofSupply', true);

        //[WHEN] Create and Post Purchase Journal
        Storage.Set('NoOfLine', Format(1));
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                         PurchaseHeader,
                         DocumentType::"Credit Memo");

        //[THEN] Verify GST ledger entries
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354521] Check if the system is calculating GST in case of Intra-State Return/Credit Note of Services for Overseas Place of Supply from Registered Vendor where Input Tax Credit is not available through Purchase credit memo
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFromPurchaseCreditMemoForRegistredAndGoodsWithoutAvailmentIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Service, true, false);
        StorageBoolean.set('PlaceofSupply', true);

        //[WHEN] Create and Post Purchase Journal
        Storage.Set('NoOfLine', Format(1));
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::"G/L Account", DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                         PurchaseHeader,
                         DocumentType::"Credit Memo");

        //[THEN] Verify GST ledger entries
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //[Scenario 354181] Check if the system is calculating GST in case of Purchase Credit Memo/Return Order for Imported Goods where Input Tax Credit is not available on purchase return order
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostFromPurchaseReturnOrderForGrpTypeGoodWithoutAvailment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTGroupType: Enum "GST Group Type";
        GSTVendorType: Enum "GST Vendor Type";
        DocumentType: Enum "Purchase Document Type";
        LineType: Enum "Sales Line Type";
    begin
        //[GIVEN] Create GST Setup
        InitializeShareStep(false, false, false);
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Purchase Return Order
        Storage.Set('NoOfLine', Format(1));
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LineType::Item, DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] Verify GST ledger entries
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Return Order", Storage.Get('ReverseDocumentNo'), 4);
    end;

    //Scenario-354913 Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Credit Memos
    //[FEATURE] [Fixed Assets Purchase Credit Memos] [Unregistered Vendor]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostGSTPurchaseCreditMemoUnregistredVendorForFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Unregistered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset for Intra-State Transactions.
        CreateAndPostPurchaseDocument(
                               PurchaseHeader,
                               PurchaseLine,
                               LineType::"Fixed Asset",
                               DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355007] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with invoice/line discount & multiple HSN through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Assets.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 8);
    end;

    //[Scenario 355039] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with invoice discount/line discount & multiple HSN through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromRegisteredVendorWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Assets.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355035] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is available with invoice discount/line discount & multiple HSN through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromRegisteredVendorWitLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Assets.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 5);
    end;

    //[Scenario 355053] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is available with invoice/line discount & multiple HSN through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromUnRegisteredVendorInterState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355001] [Check if the system is calculating GST in case of Inter-state Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is not available with multiple HSN code wise through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromUnRegisteredVendorWithoutITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Assets.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 5);
    end;

    //[Scenario 355047] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is not available with invoice/line discount & multiple HSN through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfFixedAssetFromUnRegisteredVendorWithoutITCIntraState()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Assets.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 12);
    end;

    //[Scenario 353813]	[Check if the system is handling Purchase Return of Goods to Composite Vendor/Supplier of exempted goods with no GST Impact through Purchase Credit Memo]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfGoodsFromCompositeVendorWithInputTaxCredit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Composite, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, true, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with no GST Impact and Line Type as Item.
        CreateAndPostPurchaseDocument(
                                    PurchaseHeader,
                                    PurchaseLine,
                                    LineType::Item,
                                    DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                    PurchaseHeader,
                    DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 353849] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Goods to Registered Vendor where Input Tax Credit is Non-available through Purchase Credit Memos]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseCreditMemoOfGoodsFromRegisteredVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, false);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::Item,
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                     PurchaseHeader,
                     DocumentType::"Credit Memo");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 4);
    end;

    // [Scenario 354223][Check if the system is calculating GST in case of Purchase Return Order for Imported Services from Associates Enterprises Vendor where Input Tax Credit is not available on purchase return order]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaseReturnOrderOfImportedServiceFromAssociates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Import, GSTGroupType::Service, false, true);
        InitializeAssociateVendor(false, false, false, true);
        Storage.Set('NoOfLine', (Format(1)));

        //[WHEN] Created and Posted Purchase Invocie with GST and Line Type as Goods.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"G/L Account",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
        StorageBoolean.Remove('AssociatedVendor');
    end;

    //[Scenario 355002] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is available with invoice discount/line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromRegisteredVendorWithITC()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355034] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is available with invoice discount/line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromRegisteredVendorWithITCWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 5);
    end;

    //[Scenario 355006] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with invoice/line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromRegisteredVendorWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 8);
    end;

    //[Scenario 355038] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Registered Vendor where Input Tax Credit is not available with invoice discount/line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromRegisteredVendorWithoutITCWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::Registered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355052] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is available with invoice /line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromUnRegisteredVendorWithITCWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, false, false);
        InitializeShareStep(true, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355056] [Check if the system is calculating GST in case of Inter-State Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is not available with invoice /line discount & Multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromUnRegisteredVendorWithoutITCWithDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, false, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 6);
    end;

    //[Scenario 355046] [Check if the system is calculating GST in case of Intra-State/ Intra-Union Territory Purchase Return of Fixed Assets to Unregistered Vendor where Input Tax Credit is not available with invoice /line discount & multiple HSN through Purchase Return Orders]
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VendorLedgerEntries')]
    procedure PostPurchaserReturnOrderOfFixedAssetFromUnRegisteredVendorWithoutITCWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
        GSTGroupType: Enum "GST Group Type";
        DocumentType: Enum "Document Type Enum";
        GSTVendorType: Enum "GST Vendor Type";
    begin
        //[GIVEN] Created GST Setup
        CreateGSTSetup(GSTVendorType::UnRegistered, GSTGroupType::Goods, true, false);
        InitializeShareStep(false, false, true);
        Storage.Set('NoOfLine', (Format(2)));

        //[WHEN] Created and Posted Purchase Invoice with GST and Line Type as Fixed Asset.
        CreateAndPostPurchaseDocument(
                            PurchaseHeader,
                            PurchaseLine,
                            LineType::"Fixed Asset",
                            DocumentType::Invoice);
        CreateAndPostPurchaseReturnFromCopyDocument(
                        PurchaseHeader,
                        DocumentType::"Return Order");

        //[THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(PurchaseHeader."Document Type"::"Credit Memo", Storage.Get('ReverseDocumentNo'), 12);
    end;

    local procedure CreateAndPostPurchaseReturnFromCopyDocument(VAR PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        LibraryPurchase: Codeunit "Library - Purchase";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReverseDocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Storage.Get('VendorNo'));
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Location Code", CopyStr(Storage.Get('LocationCode'), 1, MaxStrLen(PurchaseHeader."Location Code")));
        PurchaseHeader.Modify(true);
        CopyDocMgt.SetProperties(true, false, false, false, true, false, false);
        CopyDocMgt.CopyPurchaseDocForInvoiceCancelling(Storage.Get('PostedDocumentNo'), PurchaseHeader);
        UpdateReferenceInvoiceNoAndVerify(PurchaseHeader);
        ReverseDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Storage.set('ReverseDocumentNo', ReverseDocumentNo);
    end;

    local procedure UpdateReferenceInvoiceNoAndVerify(var PurchaseHeader: Record "Purchase Header")
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        ReferenceInvoiceNoMgt: codeunit "Reference Invoice No. Mgt.";
    begin
        UpdatePurchaseLine(PurchaseHeader);
        ReferenceInvoiceNo.Init();
        ReferenceInvoiceNo.Validate("Document No.", PurchaseHeader."No.");
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::"Credit Memo":
                ReferenceInvoiceNo.Validate("Document Type", ReferenceInvoiceNo."Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::"Return Order":
                ReferenceInvoiceNo.Validate("Document Type", ReferenceInvoiceNo."Document Type"::"Return Order");
        end;
        ReferenceInvoiceNo.Validate("Source Type", ReferenceInvoiceNo."Source Type"::Vendor);
        ReferenceInvoiceNo.Validate("Source No.", PurchaseHeader."Buy-from Vendor No.");
        ReferenceInvoiceNo.Validate("Reference Invoice Nos.", Storage.Get('PostedDocumentNo'));
        ReferenceInvoiceNo.Insert(true);
        ReferenceInvoiceNoMgt.UpdateReferenceInvoiceNoforVendor(ReferenceInvoiceNo, ReferenceInvoiceNo."Document Type", ReferenceInvoiceNo."Document No.");
        ReferenceInvoiceNoMgt.VerifyReferenceNo(ReferenceInvoiceNo);
    end;

    local procedure UpdatePurchaseLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.Validate("Direct Unit Cost");
                PurchaseLine.Modify(true);
            until PurchaseLine.Next() = 0;
    end;

    [ModalPageHandler]
    procedure VendorLedgerEntries(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin

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

    local procedure InitializeAssociateVendor(InputCreditAvailment: Boolean; Exempted: Boolean; LineDiscount: Boolean; AssociatedVendor: Boolean)
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Storage.Get('VendorNo')) and AssociatedVendor then begin
            Vendor.Validate("Associated Enterprises", true);
            Vendor.Modify();
        end;
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
        if Vendor."GST Vendor Type" = vendor."GST Vendor Type"::Import then begin
            Vendor.Validate("Currency Code", LibraryGST.CreateCurrencyCode());
            if StorageBoolean.ContainsKey('AssociatedVendor') then
                vendor.Validate("Associated Enterprises", AssociateEnterprise);
        end;
        Vendor.Modify(true);
    end;

    local procedure UpdateInputServiceDistributer(InputServiceDistribute: Boolean)
    var
        LocationCode: Code[10];
    begin
        LocationCode := CopyStr(Storage.Get('LocationCode'), 1, MaxStrLen(LocationCode));
        LibraryGST.UpdateLocationWithISD(LocationCode, InputServiceDistribute);
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
        VendorNo := Storage.Get('VendorNo');
        Evaluate(LocationCode, CopyStr(Storage.Get('LocationCode'), 1, MaxStrLen(LocationCode)));
        CreatePurchaseHeaderWithGST(PurchaseHeader, VendorNo, DocumentType, LocationCode, PurchaseInvoiceType::" ");
        CreatePurchaseLineWithGST(PurchaseHeader, PurchaseLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('InputCreditAvailment'), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        if not (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote) then begin
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, TRUE, TRUE);
            Storage.Set('PostedDocumentNo', DocumentNo);
            exit(DocumentNo);
        end;
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
        TaxTypeSetup.Get();
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
        Storage: Dictionary of [Text, Code[20]];
        ComponentPerArray: array[20] of Decimal;
        StorageBoolean: Dictionary of [Text, Boolean];
}