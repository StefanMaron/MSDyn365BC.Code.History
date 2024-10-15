codeunit 18191 "GST Sales Tests"
{
    Subtype = Test;
    // [Scenario 354292] Check if the system is calculating GST is case of Intra-State Sales of Goods to Registered Customer through Sale Orders
    // [FEATURE] [Goods Sales Order] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesOrderIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, TRUE);


        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354247] Check if the system is calculating GST is case of Intra-State Sales of Goods to Registered Customer through Sale Quote
    // [FEATURE] [Goods Sales Quote] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesQuoteIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, TRUE);


        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354318] Check if the system is calculating GST is case of Intra-State Sales of Services to Registered Customer through Sale Orders
    // [FEATURE] [Goods Sales Order] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerServiceSalesOrderIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Intra-StateJuridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account",
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354301] Check if the system is calculating GST is case of Inter-State Sales of Goods to Registered Customer through Sale Quotes
    // [FEATURE] [Goods Sales Quotes] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesQuotesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        //[THEN] Make Order from Quotes
        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354302] Check if the system is calculating GST is case of Inter-State Sales of Goods to Registered Customer through Sale Orders
    // [FEATURE] [Goods Orders] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesOrdersInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Inter-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 354303] Check if the system is calculating GST is case of Inter-State Sales of Goods to Registered Customer through Sale Invoices
    // [FEATURE] [Goods Invoices] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesInvoicesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Inter-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 354307] Check if the system is calculating GST is case of Inter-State Sales of Goods to Unregistered Customer through Sale Quotes
    // [FEATURE] [Goods Sales Quotes] [Inter-State GST,Unregistered  Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesQuotesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";

    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354308] Check if the system is calculating GST is case of Inter-State Sales of Goods to Unregistered Customer through Sale Orders
    // [FEATURE] [Goods Orders] [Inter-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesOrdersInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Inter-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);

    end;

    // [Scenario 354309] Check if the system is calculating GST is case of Inter-State Sales of Goods to Unregistered Customer through Sale Invoices
    // [FEATURE] [Goods Invoices] [Inter-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesInvoicesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Inter-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 354295] Check if the system is calculating GST is case of Intra-State Sales of Goods to Unregistered Customer through Sale Quotes
    // [FEATURE] [Goods Sales Quotes] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesQuotesIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Goods and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)

    end;

    // [Scenario 354298] Check if the system is calculating GST is case of Intra-State Sales of Goods to Unregistered Customer through Sale Orders
    // [FEATURE] [Goods Sales Order] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesOrderIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Intra-StateJuridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354299] Check if the system is calculating GST is case of Intra-State Sales of Goods to Unregistered Customer through Sale Invoices
    // [FEATURE] [Goods Sales Invoices] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerGoodsSalesInvoicesIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354328] Check if the system is calculating GST is case of Intra-State Sales of Services to Unregistered Customer through Sale Quotes
    // [FEATURE] [Service Sales Quotes] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnregisteredCustomerSalesServiceQuotesIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Service and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354331] Check if the system is calculating GST is case of Intra-State Sales of Services to Unregistered Customer through Sale Orders
    // [FEATURE] [Service Sales Order] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerServiceSalesOrderIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Intra-StateJuridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354332] Check if the system is calculating GST is case of Intra-State Sales of Services to Unregistered Customer through Sale Invoices
    // [FEATURE] [Service Sales Invoices] [Intra-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesServiceInvoicesIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354339] Check if the system is calculating GST is case of Inter-State Sales of Services to Unregistered Customer through Sale Quotes
    // [FEATURE] [Service Sales Quotes] [Inter-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesServiceQuotesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Service and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354341] Check if the system is calculating GST is case of Inter-State Sales of Services to Unregistered Customer through Sale Orders
    // [FEATURE] [Service Sales Order] [Inter-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesServiceOrderInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3)
    end;

    // [Scenario 354342] Check if the system is calculating GST is case of Inter-State Sales of Services to Unregistered Customer through Sale Invoices
    // [FEATURE] [Service Sales Invoices] [Inter-State GST,Unregistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesServiceInvoicesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3)
    end;

    // [Scenario 354318] Check if the system is calculating GST is case of Intra-State Sales of Services to Registered Customer through Sale Orders
    // [FEATURE] [Service Sales Order] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyRegisteredCustomerGSTSalesServiceOrderIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354327] Check if the system is calculating GST is case of Intra-State Sales of Services to Registered Customer through Sale Invoices
    // [FEATURE] [Service Sales Invoices] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyRegisteredCustomerGSTSalesServiceInvoicesIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 354336] Check if the system is calculating GST is case of Inter-State Sales of Services to Registered Customer through Sale Quotes
    // [FEATURE] [Service Sales Quotes] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyRegisteredCustomerGSTSalesServiceQuotesInterState()
    var

        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Service and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    // [Scenario 354337] Check if the system is calculating GST is case of Inter-State Sales of Services to Registered Customer through Sale Orders
    // [FEATURE] [Service Sales Order] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyRegisteredCustomerGSTSalesServiceOrderInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";


        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3)
    end;

    // [Scenario 354338] Check if the system is calculating GST is case of Inter-State Sales of Services to Registered Customer through Sale Invoices
    // [FEATURE] [Service Sales Invoices] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyRegisteredCustomerGSTSalesServiceInvoicesInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    //   [Scenario 354386] Check if the system is calculating GST in case of Export of Goods to SEZ Unit Customer without Payment of Duty through Sale Quote
    //   [FEATURE] [Export Goods Sale Quote Without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZUnitCustomerWithoutPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, TRUE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354388] Check if the system is calculating GST in case of Export of Goods to SEZ Unit Customer without Payment of Duty through Sale Order
    // [FEATURE] [Export Goods Sale Order Without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesSaleOrderOfExportSEZUnitCustomerWithoutPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2)
    end;

    // [Scenario 354389] Check if the system is calculating GST in case of Export of Goods to SEZ Unit Customer without Payment of Duty through Sales Invoices
    // [FEATURE] [Export Goods Sale Invoices] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportSEZUnitCustomerWithoutPaymentOfDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2)
    end;

    //   [Scenario 354357] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer with Payment of Duty through Sale Quote
    //   [FEATURE] [Export Services Sale Quote With Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZUnitCustomerWithPaymentOfDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354358] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer with Payment of Duty through Sale Order
    // [FEATURE] [Export Services Sale Order With Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesSaleOrderOfExportSEZUnitCustomerWithPaymentOfDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 354359] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer with Payment of Duty through Sales Invoices
    // [FEATURE] [Export Services Sale Invoices With Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportSEZUnitCustomerWithPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    //   [Scenario 354390] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer without Payment of Duty through Sale Quote
    //   [FEATURE] [Export Services Sale Quote Without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZUnitCustomerWithoutPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", TRUE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354391] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer without Payment of Duty through Sale Order
    // [FEATURE] [Export Services Sale Order Without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesSaleOrderOfExportSEZUnitCustomerWithoutPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2)
    end;

    // [Scenario 354392] Check if the system is calculating GST in case of Export of Services to SEZ Unit Customer without Payment of Duty through Sales Invoices
    // [FEATURE] [Export Services Sale Invoices Without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportSEZUnitCustomerWithoutPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10), SalesLine.Type::"G/L Account", TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2)
    end;
    //SeZ Unit
    // [Scenario 355642] Check if the system is calculating GST in case of Sales of Fixed Assets to SEZ Unit with Payment of Duty with Multiple HSN code wise through Sale Order
    // [FEATURE] [Export Services Sale Invoices With Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportSEZUnitCustomerWithPaymentofDutyWithFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Asset and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10), SalesLine.Type::"Fixed Asset", false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 355643] Check if the system is calculating GST in case of Sales of Fixed Assets to SEZ Unit with Payment of Duty with Multiple HSN code wise through Sales Invoices
    // [FEATURE] [Export Services Sale Invoices With Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoiceOfExportSEZUnitCustomerWithPaymentofDutyWithFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10), SalesLine.Type::"Fixed Asset", false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 355642] Check if the system is calculating GST in case of Sales of Fixed Assets to SEZ Unit without Payment of Duty with multiple HSN code wise through Sale Order
    // [FEATURE] [Services Sale Order without Payment of Duty] [SEZ Unit Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportSEZUnitCustomerWithoutPaymentofDutyWithFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Unit", GSTGroupType::Goods, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Asset and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10), SalesLine.Type::"Fixed Asset", true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    //   [Scenario 354393] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer without Payment of duty through Sale Quotes
    //   [FEATURE] [Export Goods Sale Quote] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZDevelopmentCustomerWithoutPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, TRUE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354394] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer without Payment of Duty through Sale Order
    // [FEATURE] [Export Goods Sale Order] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportSEZDevelopmentCustomerWithoutPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, TRUE, FALSE, FALSE, 1);



        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2)
    end;

    //   [Scenario 354360] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer with Payment of Duty through Sale Quote
    //   [FEATURE] [Export Goods Sale Quote with Payment of Duty ] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZDevelopmentCustomerWithPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354361] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer with Payment of Duty through Sale Order
    // [FEATURE] [Export Goods Sale Order with Payment of Duty] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportSEZDevelopmentCustomerWithPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 354363] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer with Payment of Duty through Sales Invoices
    // [FEATURE] [Export Goods Sale Invoices with Payment of Duty] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportSEZDevelopmentCustomerWithPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;
    //   [Scenario 354364] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer with Payment of Duty through Sale Quote
    //   [FEATURE] [Export Services Sale Quote with Payment of Duty ] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportSEZDevelopmentCustomerWithPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354365] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer with Payment of Duty through Sale Order
    // [FEATURE] [Export Goods Sale Services with Payment of Duty] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportSEZDevelopmentCustomerWithPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 354366] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer with Payment of Duty through Sales Invoices
    // [FEATURE] [Export Services Sale Invoices with Payment of Duty] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportSEZDevelopmentCustomerWithPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;


    // [Scenario 355681] Check if the system is calculating GST in case of Sales of Fixed Assets to SEZ Development Customer without Payment of Duty with multiple HSN code wise through Sale Order
    // [FEATURE] [Fixed Asset Sale Order] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfSEZDevelopmentCustomerWithoutPaymentofDutyWithFixedAssets()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", TRUE, FALSE, FALSE, 1);



        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4)
    end;

    // [Scenario 355680] Check if the system is calculating GST in case of Sales of Fixed Assets to SEZ Development Customer with Payment of Duty with multiple HSN code wise through Sale Order
    // [FEATURE] [Fixed Asset Sale Order] [SEZ Development Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfSEZDevelopmentCustomerWithPaymentofDutyWithFixedAssets()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"SEZ Development", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, FALSE, 2);


        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;
    ////Fixedasset
    //   [Scenario 354400] Check if the system is calculating GST in case of Export of Goods to Deemed Export Customer with Payment of Duty through Sale Order
    //   [FEATURE] [Export Goods Sale Order With Payment of Duty] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportOfDeemedExportCustomerWithPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354401] Check if the system is calculating GST in case of Export of Goods to Deemed Export Customer with Payment of Duty through Sales Invoices
    // [FEATURE] [Export Goods Sale Invoices With Payment of Duty ] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportOfDeemedExportCustomerWithPaymentofDutyWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Goods, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item, FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    //   [Scenario 354402] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer with Payment of Duty through Sale Quote
    //   [FEATURE] [Export Services Sale Quote with Payment of Duty ] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportOfDeemedExportCustomerWithPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    //   [Scenario 354407] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer with Payment of Duty through Sale Order
    //   [FEATURE] [Export Services Sale Order] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportOfDeemedExportCustomeWithPaymentofDutyrWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, FALSE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    //   [Scenario 354409] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer without Payment of Duty through Sale Quote
    //   [FEATURE] [Export Services Sale Quote without Payment of Duty] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesQuoteOfExportOfDeemedExportCustomerWithoutPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", TRUE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    //   [Scenario 354410] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer without Payment of Duty through Sale Order
    //   [FEATURE] [Export Services Sale Order without Payment of Duty] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportOfDeemedExportCustomerWithoutPaymentOfDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    //   [Scenario 354412] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer without Payment of Duty through Sales Invoices
    //   [FEATURE] [Export Services Sale Invoices without Payment of Duty] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesInvoicesOfExportOfDeemedExportCustomerWithoutPaymentofDutyWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account",
                            TRUE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354615] Check if the system is calculating Kerala Flood CESS on GST in case of Intra-State sale of Services through Sale Quotes
    // [FEATURE] [Services Sales Quotes] [Intra-State GST With Kerala Flood CESS ,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTWithKFCRegisteredCustomerServicesSalesQuotesInteraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        // [GIVEN] Created GST Setup
        InitializeKeralaCESS();
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Make Quote to Sales Order with GST and Line Type as Service and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", FALSE, FALSE, FALSE, 1);

        LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354643] Check if the system is calculating GST in case of Intra-State Sales of Services to Overseas Place of Supply to registered customer through Sale Orders
    // [FEATURE] [Services Sales Orders] [Intra-State Overseas Place of Supply,Registered,customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSaleOrderOfServiceToOverseasPlaceOfSupply()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        InitializeShareStep();
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account",
                            FALSE, TRUE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
        LibraryStorageBoolean.Remove('POS');

    end;

    // [Scenario 354669] Check if the system is calculating GST in case of Intra-State Sales of Services to Overseas Place of Supply to registered customer through Sale Invoices
    // [FEATURE] [Services Sales Invoices] [Intra-State Overseas Place of Supply,Registered customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSaleInvoicesOfServiceToOverseasPlaceOfSupply()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        InitializeShareStep();
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Intra-State Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account",
                            FALSE, TRUE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);

        LibraryStorageBoolean.Remove('POS');
    end;

    // [Scenario 354395] Check if the system is calculating GST in case of Export of Goods to SEZ Development Customer without Payment of Duty through Sale Invoice.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesInvoiceOfExportSEZDevelopmentCustomerWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Goods, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Item for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354396] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer without Payment of Duty through Sale Quote.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesQuoteOfExportSEZDevelopmentCustomerWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Service, false);
        InitializeShareStep(false, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    //[Scenario 354397] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer without Payment of Duty through Sale Order.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesOrderOfExportSEZDevelopmentCustomerWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Service, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Item for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354398] Check if the system is calculating GST in case of Export of Services to SEZ Development Customer without Payment of Duty through Sales Invoices
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesInvoiceOfExportSEZDevelopmentCustomerWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"SEZ Development", GSTGroupType::Service, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as GLAccount for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    //   [Scenario 355682] Check if the system is calculating GST in case of Inter-state sales of Fixed Assets to a Deemed Export Customer with Payment of Duty with multiple HSN code wise through Sale Order
    //   [FEATURE] [Export Services Sale Quote with Payment of Duty] [Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTOnSalesOrderOfExportOfDeemedExportCustomerWithPaymentofDutyWithFixedAssets()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Service, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", false, false, false, 1);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 354410] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer without Payment of Duty through Sale Order.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesOrderOfExportDeemedExportCustomerWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"Deemed Export", GSTGroupType::Service, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as GLAccount for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354415] Check if the system is calculating GST in case of Export of Goods to Deemed Export Customer without Payment of Duty through Sale Order.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesOrderOfExportDeemedCustomerWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"Deemed Export", GSTGroupType::Goods, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Item for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354416] Check if the system is calculating GST in case of Export of Goods to Deemed Export Customer without Payment of Duty through Sale Invoice.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesInvoiceOfExportDeemedCustomerWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"Deemed Export", GSTGroupType::Goods, false);
        InitializeShareStep(false, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Item for Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354409] Check if the system is calculating GST in case of Export of Services to Deemed Export Customer without Payment of Duty through Sale Quote.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTSalesQuoteOfExportDeemedCustomerWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::"Deemed Export", GSTGroupType::Service, false);
        InitializeShareStep(false, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            true, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    // [Scenario 354421] Check if the system is not calculating GST in case of GST Exempted Sales of Goods to Exempted Customer - Inter-State through Sale Order.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesOrderOfExemptedCustomeriWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Goods, false);
        InitializeShareStep(true, false);

        // [WHEN] Create and Post Sales Order with Line Type Item for Interstate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354423] Check if the system is not calculating GST in case of GST Exempted Sales of Goods to Exempted Customer - Inter-State through Sale Invoice.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesInvoiceOfExemptedCustomeriWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Goods, false);
        InitializeShareStep(true, false);

        // [WHEN] Create and Post Sales Invoice with Line Type item for Interstate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354515] Check if the system is not calculating GST in case of GST Exempted Sales of Services to Exempted Customer -Inter-State through Sale Order.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesOrderOfExemptedCustomeriWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Service, false);
        InitializeShareStep(true, false);

        // [WHEN] Create and Post Sales Order with Line Type GLAccount for Interstate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354516] Check if the system is not calculating GST in case of GST Exempted Sales of Services to Exempted Customer - Inter-State through Sale Invoice.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesInvoiceOfExemptedCustomeriWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Service, false);
        InitializeShareStep(true, false);

        // [WHEN] Create and Post Sales Invoice with Line Type GLAccount for Interstate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 2);
    end;

    // [Scenario 354417] Check if the system is not calculating GST in case of GST Exempted Sales of Goods to Exempted Customer - Inter-State through Sales Quotes.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesQuoteOfExemptedCustomeriWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Goods, false);
        InitializeShareStep(true, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    // [Scenario 354420] Check if the system is not calculating GST in case of GST Exempted Sales of Services to Exempted Customer - Inter-State through Sales Quotes.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTInterstateSalesQuoteOfExemptedCustomeriWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Service, false);
        InitializeShareStep(true, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    // [Scenario 354522] Check if the system is not calculating GST in case of GST Exempted Sales of Goods to Exempted Customer - Intra-State through Sales Quotes.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTIntrastateSalesQuoteOfExemptedCustomeriWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Goods, true);
        InitializeShareStep(true, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    // [Scenario 354531] Check if the system is not calculating GST in case of GST Exempted Sales of Services to Exempted Customer - Intra-State through Sale Quotes.
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTIntrastateSalesQuoteOfExemptedCustomeriWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomerType::Exempted, GSTGroupType::Service, true);
        InitializeShareStep(true, false);

        // [WHEN] Create Sales Quote and Convert to Order
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.QuoteMakeOrder(SalesHeader)
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsBlanketSalesOrderIntraState()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order",
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            false, false, false, 1);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyTaxTransactionForSales(SalesOrderHeader."No.");
    end;

    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerServiceBlanketSalesOrderIntraState()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Service, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order",
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyTaxTransactionForSales(SalesOrderHeader."No.");
    end;

    // [Scenario 355696] Check if the system is calculating GST in case of Inter-state Sales of goods to Registered Customer  with multiple HSN code wise, ship and invoice with Partial qty through Sale Orders
    // [FEATURE] [Goods Sales Order] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesOrderPartialQtyInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializePartialShipQty(true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 355697] Check if the system is calculating GST in case of Inter-state Sales of goods to Registered Customer  with multiple HSN code wise, ship and invoice  through Sale Invoices
    // [FEATURE] [Goods Sales Invoice] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesInvoiceInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::UnRegistered, GSTGroupType::Goods, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 355699] Check if the system is calculating GST in case of Inter-state Sales of goods to Unregistered Customer  with multiple HSN code wise, ship and invoice with Partial qty through Sale Orders
    // [FEATURE] [Goods Sales Order] [Inter-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnRegisteredCustomerGoodsSalesOrderPartialQtyInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializePartialShipQty(true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 355700] Check if the system is calculating GST in case of Inter-state Sales of goods to Unregistered Customer  with multiple HSN code wise, ship and invoice through Sale Invoices
    // [FEATURE] [Goods Sales Invoice] [Inter-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnRegisteredCustomerGoodsSalesInvoiceInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::UnRegistered, GSTGroupType::Goods, false);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 3);
    end;

    // [Scenario 355701] Check if the system is calculating GST in case of Intra-state Sales of goods to Registered Customer  with multiple HSN code wise, ship and invoice with Partial qty through Sale Orders
    // [FEATURE] [Goods Sales Order] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesOrderPartialQtyIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);
        InitializePartialShipQty(true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 355704] Check if the system is calculating GST in case of Intra-state Sales of goods to Registered Customer  with multiple HSN code wise, ship and invoice through Sale Invoices
    // [FEATURE] [Goods Sales Invoice] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTRegisteredCustomerGoodsSalesInvoiceIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::UnRegistered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 355699] Check if the system is calculating GST in case of Intra-state Sales of goods to Unregistered Customer  with multiple HSN code wise, ship and invoice with Partial qty through Sale Orders
    // [FEATURE] [Goods Sales Order] [Inter-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnRegisteredCustomerGoodsSalesOrderPartialQtyIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);
        InitializePartialShipQty(true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;

    // [Scenario 355706] Check if the system is calculating GST in case of Intra-state Sales of goods to Unregistered Customer  with multiple HSN code wise, ship and invoice through Sale Invoices
    // [FEATURE] [Goods Sales Invoice] [Intra-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure PostGSTUnRegisteredCustomerGoodsSalesInvoiceIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
        Partialship: Boolean;
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::UnRegistered, GSTGroupType::Goods, TRUE);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::Item,
                            FALSE, FALSE, FALSE, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.VerifyGLEntries(GLDocType::Invoice, PostedDocumentNo, 4);
    end;
    // [Scenario 355506	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Registered Customer with multiple HSN code wise through Sale Orders
    // [FEATURE] [Sales Order] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesofFixedAssetsOrdersIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2)
    end;

    // [Scenario 355507	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Registered Customer with multiple HSN code wise through Sale Invoice
    // [FEATURE] [Sales Invoice] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesInvoiceofFixedAssetsOrdersIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2)
    end;

    // [Scenario 355541	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Unregistered Customer with invoice discount/line discount and multiple HSN code wise through Sale Orders
    // [FEATURE] [Sales Order] [Intra-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesInvoiceofFixedAssetsOrdersIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, true);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2)
    end;

    // [Scenario 355542	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Unregistered Customer with invoice discount/line discount and multiple HSN code wise through Sale Invoice
    // [FEATURE] [Sales Invoice] [Intra-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnregisteredCustomerSalesInvoiceofFixedAssetsInvoiceIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Unregistered, GSTGroupType::Goods, true);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2);
    end;

    // [Scenario 355547	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Registered Customer with invoice discount/line discount with multiple HSN code wise through Sale Orders
    // [FEATURE] [Sales Invoice] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesOrderofFixedAssetsIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"G/L Account", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2);
    end;

    // [Scenario 355549	Check if the system is calculating GST is case of Intra-State Sales of Fixed Assets to Registered Customer with invoice discount/line discount with multiple HSN code wise through Sale Invoice
    // [FEATURE] [Sales Invoice] [Intra-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesOrderofFixedAssetsWithLineDiscountIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, true);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Intrastate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 2);
    end;

    // [Scenario 355553	Check if the system is calculating GST is case of Inter-State Sales of Fixed Assets to Registered Customer with invoice discount/line discount and multiple HSN code wise through Sale Orders
    // [FEATURE] [Sales Order] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesOrderofFixedAssetsWithLineDiscountInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;
    // [Scenario 355554	Check if the system is calculating GST is case of Inter-State Sales of Fixed Assets to Registered Customer with invoice discount/line discount and multiple HSN code wise through Sale Invoice
    // [FEATURE] [Sales Invoice] [Inter-State GST,Registered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTRegisteredCustomerSalesInvoiceofFixedAssetsWithLineDiscountInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Assets and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 355562	Check if the system is calculating GST is case of Inter-State Sales of Fixed Assets to Unregistered Customer with invoice discount/line discount and multiple HSN code wise through Sale Orders
    // [FEATURE] [Sales Order] [Inter-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnRegisteredCustomerSalesOrderofFixedAssetsWithLineDiscountInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Order with GST and Line Type as Fixed Assets and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 355564	Check if the system is calculating GST is case of Inter-State Sales of Fixed Assets to Unregistered Customer with invoice discount/line discount and multiple HSN code wise through Sale Invoice
    // [FEATURE] [Sales Invoice] [Inter-State GST,UnRegistered Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTUnRegisteredCustomerSalesInvoiceofFixedAssetsWithLineDiscountInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::Registered, GSTGroupType::Goods, false);
        InitializeShareStep(false, true);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Assets and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", false, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    // [Scenario 355683	Check if the system is calculating GST in case of Inter-state sales of Fixed Assets to a Deemed Export Customer with Payment of Duty with multiple HSN code wise through Sales Invoices
    // [FEATURE] [Sales Invoice] [Inter-State GST,Deemed Export Customer]
    [Test]
    [HandlerFunctions('TaxRatesPage')]
    procedure VerifyGSTDeemedExportCustomerSalesInvoiceofFixedAssetsWithPaymentDutyInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTCustomeType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        GLDocType: Enum "Gen. Journal Document Type";
    begin
        // [GIVEN] Created GST Setup
        CreateGSTSetup(GSTCustomeType::"Deemed Export", GSTGroupType::Goods, false);

        // [WHEN] Create and Post Sales Invoice with GST and Line Type as Fixed Assets and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            CopyStr(LibraryStorage.Get('HSNSACCode'), 1, 10),
                            SalesLine.Type::"Fixed Asset", true, false, false, 2);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries and Detailed GST Ledger Entries verified
        LibraryGST.GSTLedgerEntryCount(PostedDocumentNo, 1);
    end;

    local procedure CreateGSTSetup(GSTCustomerType: Enum "GST Customer Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        LocationStateCode: Code[10];
        CustomerNo: Code[20];
        LocationCode: Code[10];
        CustomerStateCode: Code[10];
        LocPan: Code[20];
        HSNSACCode: Code[10];
        GSTGroupCode: Code[10];
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
        LibraryStorage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);
        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.MODIFY(TRUE);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, FALSE);
        LibraryStorage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType, GSTGroup."GST Place Of Supply"::" ", false);
        LibraryStorage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::HSN);
        LibraryStorage.Set('HSNSACCode', HSNSACCode);

        if IntraState then begin
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
        end else begin
            CustomerStateCode := LibraryGST.CreateGSTStateCode();
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, CustomerStateCode, LocPan);
            LibraryStorage.Set('CustomerStateCode', CustomerStateCode);
            if GSTCustomerType in [GSTCustomerType::Export, GSTCustomerType::"SEZ Unit", GSTCustomerType::"SEZ Development"] then
                InitializeTaxRateParameters(IntraState, '', LocationStateCode)
            else
                InitializeTaxRateParameters(IntraState, CustomerStateCode, LocationStateCode);
        end;
        LibraryStorage.Set('CustomerNo', CustomerNo);

        CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);

        CreateTaxRate();
    end;

    local procedure InitializeKeralaCESS();
    var
        KeralaCESS: Boolean;
    begin
        KeralaCESS := true;
        LibraryStorageBoolean.Set('KeralaCESS', KeralaCESS)
    end;

    local procedure InitializeShareStep();
    var
        POS: Boolean;
    begin
        POS := true;
        LibraryStorageBoolean.Set('POS', POS)
    end;

    local procedure InitializePartialShipQty(PartialShip: Boolean);
    begin
        LibraryStorageBoolean.Set('PartialShip', PartialShip)
    end;

    local procedure InitializeShareStep(Exempted: Boolean; LineDiscount: Boolean)
    begin
        LibraryStorageBoolean.Set('Exempted', Exempted);
        LibraryStorageBoolean.Set('LineDiscount', LineDiscount);
    end;

    local procedure CreateSalesDocument(VAR SalesHeader: Record "Sales Header"; VAR SalesLine: Record "Sales Line"; DocumenType: Enum "Sales Document Type"; CustomerNo: Code[20]; LocationCode: Code[10]; GSTGroupCode: Code[20]; HSNSACCode: Code[10]; LineType: Enum "Sales Line Type"; WithoutPaymentofDuty: Boolean; PlaceofSupply: Boolean; AssessableValue: Boolean; NoOfLine: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LineTypeNo: Code[20];
        Amount: Decimal;
        LineNo: Integer;
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, DocumenType, LocationCode, WithoutPaymentofDuty, PlaceofSupply);

        for LineNo := 1 to NoOfLine do begin
            Amount := LibraryRandom.RandDec(1000, 2);
            case LineType of
                LineType::Item:
                    LineTypeNo := LibraryGST.CreateItemWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, TRUE, FALSE);
                LineType::"G/L Account":
                    LineTypeNo := LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, TRUE, FALSE);
                LineType::"Fixed Asset":
                    LineTypeNo := LibraryGST.CreateFixedAssetWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, TRUE, FALSE);
            end;
            CreateSalesLine(SalesHeader, SalesLine, LineType, LineTypeNo, LibraryRandom.RandDecInRange(2, 10, 0), Amount, AssessableValue);
        end;
    end;

    local procedure CreateSalesHeader(VAR SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; WithoutPaymentofDuty: Boolean; PlaceofSupply: Boolean)
    var
        POS: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.VALIDATE("Location Code", LocationCode);

        if WithoutPaymentofDuty then
            SalesHeader.Validate("GST Without Payment of Duty", TRUE);

        if LibraryStorageBoolean.ContainsKey('POS') then
            POS := LibraryStorageBoolean.Get('POS');
        if POS then begin
            SalesHeader.Validate("GST Invoice", TRUE);
            PlaceofSupply := POS;
            SalesHeader.Validate("POS Out Of India", TRUE);
        end;

        SalesHeader.MODIFY(TRUE);
    end;

    local procedure CreateSalesLine(VAR SalesHeader: Record "Sales Header"; VAR SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Qty: Decimal; Amount: Decimal; AssessableValue: Boolean)
    var
        LineDiscount: Boolean;
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Qty);
        SalesLine.VALIDATE(Quantity, Qty);

        if AssessableValue then begin
            SalesLine.VALIDATE("GST On Assessable Value", TRUE);
            SalesLine.VALIDATE("GST Assessable Value (LCY)", Amount);
        end;

        if LibraryStorageBoolean.ContainsKey('PartialShip') then begin
            if LibraryStorageBoolean.Get('PartialShip') then
                SalesLine.VALIDATE(SalesLine."Qty. to Ship", Qty / 2);
            SalesLine.Validate(SalesLine."Qty. to Invoice", Qty / 2);
            LibraryStorageBoolean.Remove('PartialShip');
        end;
        if LibraryStorageBoolean.ContainsKey('LineDiscount') then begin
            Evaluate(LineDiscount, Format(LibraryStorageBoolean.Get('LineDiscount')));
            if LineDiscount then begin
                SalesLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));
                LibraryGST.UpdateLineDiscAccInGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            end;
        end;

        SalesLine.VALIDATE("Unit Price", Amount);
        SalesLine.MODIFY(TRUE);
    end;

    procedure UpdateCustomerSetupWithGST(CustomerNo: Code[20]; GSTCustomerType: Enum "GST Customer Type"; StateCode: Code[10]; Pan: Code[20]);
    var
        Customer: Record Customer;
        State: Record State;
    begin
        Customer.Get(CustomerNo);
        if GSTCustomerType <> GSTCustomerType::Export then begin
            State.Get(StateCode);
            Customer.Validate("State Code", StateCode);
            Customer.Validate("P.A.N. No.", Pan);
            if not ((GSTCustomerType = GSTCustomerType::" ") OR (GSTCustomerType = GSTCustomerType::Unregistered)) then
                Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;

        Customer.Validate(Address, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Customer.Address)));
        Customer.Validate("GST Customer Type", GSTCustomerType);
        if GSTCustomerType = GSTCustomerType::Export then
            Customer.Validate("Currency Code", 'USD');
        Customer.Modify(true);
    end;

    local procedure CreateGSTComponentAndPostingSetup(IntraState: Boolean; LocationStateCode: Code[10]; GSTComponent: Record "Tax Component"; GSTcomponentcode: Text[30]);
    var
        POS: Boolean;
    begin
        if LibraryStorageBoolean.ContainsKey('POS') then
            POS := LibraryStorageBoolean.Get('POS');

        IF IntraState THEN begin
            if POS then begin
                GSTcomponentcode := 'IGST';
                LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
                LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
            end else begin
                GSTcomponentcode := 'CGST';
                LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
                LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

                GSTcomponentcode := 'UTGST';
                LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
                LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);

                GSTcomponentcode := 'SGST';
                LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
                LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
            end;
        end else begin
            GSTcomponentcode := 'IGST';
            LibraryGST.CreateGSTComponent(GSTComponent, GSTcomponentcode);
            LibraryGST.CreateGSTPostingSetup(GSTComponent, LocationStateCode);
        end;
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        GSTTaxPercent: Decimal;
        KFCCESS: Boolean;
        POS: Boolean;
    begin
        LibraryStorage.Set('FromStateCode', FromState);
        LibraryStorage.Set('ToStateCode', ToState);

        if LibraryStorageBoolean.ContainsKey('KeralaCESS') then
            KFCCESS := LibraryStorageBoolean.Get('KeralaCESS');

        if LibraryStorageBoolean.ContainsKey('POS') then
            POS := LibraryStorageBoolean.Get('POS');


        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);

        if IntraState then begin
            if POS then
                componentPerArray[4] := GSTTaxPercent
            else begin
                componentPerArray[1] := (GSTTaxPercent / 2);
                componentPerArray[2] := (GSTTaxPercent / 2);
                componentPerArray[3] := 0;
                if KFCCESS then
                    componentPerArray[6] := LibraryRandom.RandDecInRange(1, 4, 0);
            end;
        end else
            componentPerArray[4] := GSTTaxPercent;
    end;

    local procedure CreateTaxRate()
    var
        TaxtypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TaxtypeSetup.GET() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxtypeSetup.Code);
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatesPage(var TaxRate: TestPage "Tax Rates");
    var
        POS: Boolean;
    begin
        if LibraryStorageBoolean.ContainsKey('POS') then
            POS := LibraryStorageBoolean.Get('POS');
        TaxRate.AttributeValue1.SetValue(LibraryStorage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(LibraryStorage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(LibraryStorage.Get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(LibraryStorage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(Today);
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', Today));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]);
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]);
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]);
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]);
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]);
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]);
        if POS then
            TaxRate.AttributeValue13.SetValue(POS)
        else
            TaxRate.AttributeValue13.SetValue(POS);
        TaxRate.OK().Invoke();
        POS := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGST: Codeunit "Library GST";
        LibraryRandom: Codeunit "Library - Random";
        PostedDocumentNo: Code[20];
        LibraryStorage: Dictionary of [Text, Code[20]];
        LibraryStorageBoolean: Dictionary of [Text, Boolean];
        ComponentPerArray: array[20] of Decimal;
}