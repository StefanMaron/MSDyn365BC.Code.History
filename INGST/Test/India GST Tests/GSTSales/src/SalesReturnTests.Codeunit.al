codeunit 18193 "Sales Return Tests"
{
    Subtype = Test;

    var
        LibraryGST: Codeunit "Library GST";
        ComponentPerArray: array[20] of Decimal;
        Storage: Dictionary of [Text, Text[20]];
        StorageBoolean: Dictionary of [Text, Boolean];

    //[Scenario 354276] Check if the system is calculating GST is case of Inter-State Sales Return of Goods from Registered Customer through Sale Return Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForRegisteredCustomerInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354286] Check if the system is calculating GST is case of Inter-State Sales Return of Services from Registered Customer through Sale Return Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderOfServiceForRegisteredForInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";

        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Return Order from posted invoice
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;


    //[Scenario 354310] Check if the system is calculating GST is case of Inter-State Sales Return of Goods from Registered Customer through Sale Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoOfGoodsForRegisteredForInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354343] Check if the system is calculating GST is case of Inter-State Sales Return of Services from Registered Customer through Sale Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoOfServiceForRegisteredInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";

        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354278] Check if the system is calculating GST is case of Inter-State Sales Return of Goods from Unregistered Customer through Sale Return Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForUnRegisteredCustomerInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::UnRegistered, GSTGroupType::Goods, false, false);

        //[WHEN] Create and Post Sales Return Order
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354287] Check if the system is calculating GST is case of Inter-State Sales Return of Services from Unregistered Customer through Sale Return Orders
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderOfServiceForUnRegisteredForInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::UnRegistered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Return Order from posted invoice
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354312] Check if the system is calculating GST is case of Inter-State Sales Return of Goods from Registered Customer through Sale Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoOfGoodsForUnRegisteredForIntraState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::UnRegistered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354344] Check if the system is calculating GST is case of Inter-State Sales Return of Services from Unregistered Customer through Sale Credit Memos
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoOfServiceForUnRegisteredInterState()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::UnRegistered, GSTGroupType::Service, false, false);

        //[WHEN] Create and Post Sales Invoice
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 1);
    end;

    //[Scenario 354272] Check if the system is calculating GST is case of Intra-State Sales Return of Goods from Registered Customer through Sale Return Orders.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForRegisteredCustomerIntraStateGoods()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354275] Check if the system is calculating GST is case of Intra-State Sales Return of Goods from Unregistered Customer through Sale Return Orders.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForUnregisteredCustomerIntraStateGoods()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Unregistered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354283] Check if the system is calculating GST is case of Intra-State Sales Return of Services from Registered Customer through Sale Return Orders.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForRegisteredCustomerIntraStateServices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354284] Check if the system is calculating GST is case of Intra-State Sales Return of Services from Unregistered Customer through Sale Return Orders.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesReturnOrderForUnregisteredCustomerIntraStateServices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Unregistered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Return Order", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354296] Check if the system is calculating GST is case of Intra-State Sales Return of Goods from Registered Customer through Sale Credit Memos.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoForRegisteredCustomerIntraStateGoods()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354300] Check if the system is calculating GST is case of Intra-State Sales Return of Goods from Unregistered Customer through Sale Credit Memos.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoForUnregisteredCustomerIntraStateGoods()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Unregistered, GSTGroupType::Goods, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::Item, DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354333] Check if the system is calculating GST is case of Intra-State Sales Return of Services from Registered Customer through Sale Credit Memos.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoForRegisteredCustomerIntraStateServices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Registered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    //[Scenario 354334] Check if the system is calculating GST is case of Intra-State Sales Return of Services from Unregistered Customer through Sale Credit Memos.
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CustomerLedgerEntries')]
    procedure PostFromSalesCreditMemoForUnregisteredCustomerIntraStateServices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GSTGroupType: Enum "GST Group Type";
        GSTCustomerType: Enum "GST Customer Type";
        DocumentType: Enum "Sales Document Type";
        LineType: Enum "Sales Line Type";
        PostedInvoiceNo: Code[20];
    begin
        //[GIVEN] Created GST Setup
        InitializeShareStep(false, false);
        Initialize(GSTCustomerType::Unregistered, GSTGroupType::Service, true, false);

        //[WHEN] Create and Post Sales Journal
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, SalesLine, LineType::"G/L Account", DocumentType::Invoice);
        Storage.Set('PostedDocumentNo', PostedInvoiceNo);
        CreateAndPostSalesDocumentFromCopyDocument(SalesHeader, Storage.Get('CustomerNo'), DocumentType::"Credit Memo", Storage.Get('LocationCode'));

        //[THEN] Verify GST ledger Entries
        LibraryGST.GSTLedgerEntryCount(Storage.Get('ReverseDocumentNo'), 2);
    end;

    local procedure CreateAndPostSalesDocumentFromCopyDocument(VAR SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10])
    var
        LibrarySales: Codeunit "Library - Sales";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        ReverseDocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.VALIDATE("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CopyDocMgt.SetProperties(true, false, false, false, true, false, false);
        CopyDocMgt.CopySalesDocForInvoiceCancelling(Storage.Get('PostedDocumentNo'), SalesHeader);
        UpdateReferenceInvoiceNoAndVerify(SalesHeader);
        ReverseDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);
        Storage.set('ReverseDocumentNo', ReverseDocumentNo);
    end;

    local procedure UpdateSalesLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("Unit Price");
                SalesHeader.Modify(true);
            until SalesLine.Next() = 0;
    end;

    local procedure UpdateReferenceInvoiceNoAndVerify(var SalesHeader: Record "Sales Header")
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        ReferenceInvoiceNoMgt: codeunit "Reference Invoice No. Mgt.";
    begin
        UpdateSalesLine(SalesHeader);
        ReferenceInvoiceNo.Init();
        ReferenceInvoiceNo.Validate("Document No.", SalesHeader."No.");
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::"Credit Memo":
                ReferenceInvoiceNo.Validate("Document Type", ReferenceInvoiceNo."Document Type"::"Credit Memo");
            SalesHeader."Document Type"::"Return Order":
                ReferenceInvoiceNo.Validate("Document Type", ReferenceInvoiceNo."Document Type"::"Return Order");
        end;
        ReferenceInvoiceNo.Validate("Source Type", ReferenceInvoiceNo."Source Type"::Customer);
        ReferenceInvoiceNo.Validate("Source No.", SalesHeader."Sell-to Customer No.");
        ReferenceInvoiceNo.Validate("Reference Invoice Nos.", Storage.Get('PostedDocumentNo'));
        ReferenceInvoiceNo.Insert(true);
        ReferenceInvoiceNoMgt.UpdateReferenceInvoiceNoforCustomer(ReferenceInvoiceNo, ReferenceInvoiceNo."Document Type", ReferenceInvoiceNo."Document No.");
        ReferenceInvoiceNoMgt.VerifyReferenceNo(ReferenceInvoiceNo);
    end;

    [ModalPageHandler]
    procedure CustomerLedgerEntries(var CustomerLedEnt: TestPage "Customer Ledger Entries")
    var

    begin

    end;

    local procedure Initialize(GSTCustomerType: Enum "GST Customer Type"; GSTGroupType: Enum "GST Group Type"; IntraState: Boolean; ReverseCharge: Boolean)
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
        GSTGroupCode: Code[20];
        HSNSACCode: Code[10];
        LocationGSTRegNo: Code[20];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
    begin
        FillCompanyInformation();
        CompanyInformation.Get();
        if CompanyInformation."P.A.N. No." = '' then begin
            CompanyInformation."P.A.N. No." := LibraryGST.CreatePANNos();
            CompanyInformation.Modify();
        end else
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
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, false, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
        end else begin
            CustomerStateCode := LibraryGST.CreateGSTStateCode();

            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, false, CustomerStateCode, LocPan);

            if GSTCustomerType IN [GSTCustomerType::Export, GSTCustomerType::"SEZ Development", GSTCustomerType::"SEZ Unit"] then
                InitializeTaxRateParameters(IntraState, '', LocationStateCode)
            else
                InitializeTaxRateParameters(IntraState, CustomerStateCode, LocationStateCode);
        end;
        Storage.Set('CustomerNo', CustomerNo);

        CreateTaxRate(false);
        CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);

    end;

    local procedure CreateGSTComponentAndPostingSetup(IntraState: Boolean; LocationStateCode: Code[10]; GSTComponent: Record "Tax Component"; GSTcomponentcode: Text[30]);
    begin
        IF not IntraState THEN begin
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
    end;

    local procedure InitializeShareStep(Exempted: Boolean; LineDiscount: Boolean)
    begin
        StorageBoolean.Set('Exempted', Exempted);
        StorageBoolean.Set('LineDiscount', LineDiscount);
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        LibraryRandom: Codeunit "Library - Random";
        GSTTaxPercent: decimal;
    begin
        Storage.Set('FromStateCode', FromState);
        Storage.Set('ToStateCode', ToState);
        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);
        if IntraState then begin
            componentPerArray[1] := (GSTTaxPercent / 2);
            componentPerArray[2] := (GSTTaxPercent / 2);
            componentPerArray[3] := 0;
        end else
            componentPerArray[4] := GSTTaxPercent;
        // IF IntraState then begin
        //     componentPerArray[1] := 9;
        //     componentPerArray[2] := 9;
        //     componentPerArray[3] := 0;
        // end else
        //     componentPerArray[4] := 18;
    end;

    procedure CreateTaxRate(POS: boolean)
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
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    begin
        TaxRate.AttributeValue1.SetValue(Storage.Get('HSNSACCode'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('GSTGroupCode'));
        TaxRate.AttributeValue3.SetValue(Storage.get('FromStateCode'));
        TaxRate.AttributeValue4.SetValue(Storage.Get('ToStateCode'));
        TaxRate.AttributeValue5.SetValue(WorkDate());
        TaxRate.AttributeValue6.SetValue(CALCDATE('<10Y>', WorkDate()));
        TaxRate.AttributeValue7.SetValue(componentPerArray[1]); // SGST
        TaxRate.AttributeValue8.SetValue(componentPerArray[2]); // CGST
        TaxRate.AttributeValue9.SetValue(componentPerArray[4]); // IGST
        TaxRate.AttributeValue10.SetValue(componentPerArray[3]); // UTGST
        TaxRate.AttributeValue11.SetValue(componentPerArray[5]); // Cess
        TaxRate.AttributeValue12.SetValue(componentPerArray[6]); // KFC 
        TaxRate.AttributeValue13.SetValue(false);
        TaxRate.AttributeValue14.SetValue(false);
        TaxRate.OK().Invoke();
    end;

    procedure UpdateCustomerSetupWithGST(CustomerNo: Code[20]; GSTCustomerType: Enum "GST Customer Type"; AssociateEnterprise: boolean; StateCode1: Code[10]; Pan: Code[20]);
    var
        Customer: Record Customer;
        State: Record State;
    begin
        Customer.Get(CustomerNo);
        if (GSTCustomerType <> GSTCustomerType::Export) then begin
            State.Get(StateCode1);
            Customer.Validate("State Code", StateCode1);
            Customer.Validate("P.A.N. No.", Pan);
            if not ((GSTCustomerType = GSTCustomerType::" ") OR (GSTCustomerType = GSTCustomerType::Unregistered)) then
                Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;
        Customer.Validate("GST Customer Type", GSTCustomerType);
        Customer.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(VAR SalesHeader: Record "Sales Header";
                                                VAR SalesLine: Record "Sales Line";
                                                LineType: Enum "Sales Line Type";
                                                DocumentType: Enum "Sales Document Type"): Code[20];
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        CustomerNo: Code[20];
        LocationCode: Code[10];
        PostedDocumentNo: Code[20];
    begin
        CustomerNo := Storage.Get('CustomerNo');
        evaluate(LocationCode, Storage.Get('LocationCode'));
        CreateSalesHeaderWithGST(SalesHeader, CustomerNo, DocumentType, LocationCode);
        CreateSalesLineWithGST(SalesHeader, SalesLine, LineType, LibraryRandom.RandDecInRange(2, 10, 0), StorageBoolean.Get('Exempted'), StorageBoolean.Get('LineDiscount'));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, TRUE, TRUE);
        exit(PostedDocumentNo);
    end;

    local procedure CreateSalesHeaderWithGST(VAR SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.VALIDATE("Location Code", LocationCode);
        SalesHeader.MODIFY(TRUE);
    end;

    local procedure CreateSalesLineWithGST(VAR SalesHeader: Record "Sales Header"; VAR SalesLine: Record "Sales Line"; LineType: Enum "Sales Line Type"; Quantity: Decimal; Exempted: Boolean; LineDiscount: Boolean);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LineTypeNo: Code[20];
    begin
        case LineType of
            LineType::Item:
                LineTypeNo := LibraryGST.CreateItemWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), true, Exempted);
            LineType::"G/L Account":
                LineTypeNo := LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), true, FALSE);
            LineType::"Fixed Asset":
                LineTypeNo := LibraryGST.CreateFixedAssetWithGSTDetails(VATPostingSetup, (Storage.Get('GSTGroupCode')), (Storage.Get('HSNSACCode')), true, Exempted);
        end;

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, LineTypeno, Quantity);
        SalesLine.VALIDATE("VAT Prod. Posting Group", VATPostingsetup."VAT Prod. Posting Group");
        if LineDiscount then begin
            SalesLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 2));
            LibraryGST.UpdateLineDiscAccInGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        end;
        SalesLine.VALIDATE("Unit Price", LibraryRandom.RandInt(10000));
        SalesLine.MODIFY(TRUE);
    end;

    local procedure FillCompanyInformation()
    var
        CompInfo: Record "Company Information";
    begin
        CompInfo.Get();
        if CompInfo."State Code" = '' then
            CompInfo.Validate("State Code", LibraryGST.CreateGSTStateCode());
        if CompInfo."P.A.N. No." = '' then
            CompInfo.Validate("P.A.N. No.", LibraryGST.CreatePANNos());
        CompInfo.Modify(true);
    end;
}