codeunit 18192 "GST TCS Transactions"
{
    Subtype = Test;

    var
        LibraryTCS: Codeunit "GST TCS Library";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGST: Codeunit "Library GST";
        LibraryRandom: Codeunit "Library - Random";
        LibraryStorage: Dictionary of [Text, Text];
        PostedDocumentNo: Code[20];
        TaxType: Code[10];
        ComponentPerArray: array[20] of Decimal;

    //[Scenario 354593]- Check if the system is calculating TCS and GST on Intra-State Sale of Goods through Sale Quotes.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSIntraStateSalesOfGoodsThroughSalesQuotes()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := true;
        GSTGroupType := GSTGroupType::Goods;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Quote with GST and Line Type as Item for Intrastate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        //[THEN] Quote to Make Order Conversion
        LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    //[Scenario 354633]- Check if the system is calculating TCS and GST on Inter-State Sale of Services to Unregistered Customer through Sale Orders.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfServicesThroughSalesOrdersForUnregisteredCust()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Unregistered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Service;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as Item for Intrastate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 5);
    end;

    //[Scenario 354600]- Check if the system is calculating TCS and GST on Intra-State Sale of Services through Sale Orders.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSIntraStateSalesOfServicesThroughSalesOrders()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := true;
        GSTGroupType := GSTGroupType::Service;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as G/L Account for Intrastate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 5);
    end;

    //[Scenario 354601]- Check if the system is calculating TCS and GST on Intra-State Sale of Services through Sale Invoices.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSIntraStateSalesOfServicesThroughSalesInvoices()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := true;
        GSTGroupType := GSTGroupType::Service;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as G/L Account for Intrastate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 5);
    end;

    //[Scenario 354599]- Check if the system is calculating TCS and GST on Intra-State Sale of Services through Sale Quotes.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSIntraStateSalesOfServicesThroughSalesQuotes()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Qty: Decimal;
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := true;
        GSTGroupType := GSTGroupType::Service;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post Sales Quote with GST and Line Type as Item for Intrastate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                           LibraryStorage.Get('CustomerNo'),
                           CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                           LibraryStorage.Get('GSTGroupCode'),
                           LibraryStorage.Get('HSNSACCode'),
                           SalesLine.Type::"G/L Account",
                           false, false, false, 1);

        //[THEN] Quote to Make Order Conversion
        LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    //[Scenario 354602]- Check if the system is calculating TCS and GST on Inter-State Sale of Goods through Sale Quotes.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfGoodsThroughSalesQuotes()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Qty: Decimal;
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post Sales Quote with GST and Line Type as Item for Interstate Transactions
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote,
                           LibraryStorage.Get('CustomerNo'),
                           CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                           LibraryStorage.Get('GSTGroupCode'),
                           LibraryStorage.Get('HSNSACCode'),
                           SalesLine.Type::Item,
                           false, false, false, 1);

        //[THEN] Quote to Make Order Conversion
        LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    //[Scenario 354604]- Check if the system is calculating TCS and GST on Inter-State Sale of Goods through Sale Orders.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfGoodsThroughSalesOrders()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 4);
    end;

    //[Scenario 354605]- Check if the system is calculating TCS and GST on Inter-State Sale of Goods through Sale Invoices.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfGoodsThroughSalesInvoices()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as Goods and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::Item,
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 4);
    end;

    //[Scenario 354608]- Check if the system is calculating TCS and GST on Inter-State Sale of Services through Sale Orders
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfServicesThroughSalesOrders()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Goods;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        // LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post Sales Order with GST and Line Type as Services and Interstate Juridisction
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
                            LibraryStorage.Get('CustomerNo'),
                            CopyStr(LibraryStorage.Get('LocationCode'), 1, 10),
                            LibraryStorage.Get('GSTGroupCode'),
                            LibraryStorage.Get('HSNSACCode'),
                            SalesLine.Type::"G/L Account",
                            false, false, false, 1);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries Verified
        LibraryGST.VerifyGLEntries(SalesHeader."Document Type"::Order, PostedDocumentNo, 4);
    end;

    //[Scenario 354607]- Check if the system is calculating TCS and GST on Inter-State Sale of Services through Sale Quotes.
    [TEST]
    [HandlerFunctions('GSTTCSTaxRatesPage')]
    procedure GSTTCSInterStateSalesOfServicesThroughSalesQuotes()
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        TCSPostingSetup: Record "TCS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        AssesseeCode: Record "Assessee Code";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationTan: Record Location;
        TCANNo: Record "T.C.A.N. No.";
        StateCode: Code[10];
        LocationCode: Code[10];
        Qty: Decimal;
        CustomerNo: Code[20];
        Intrastate: Boolean;
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
    begin
        GSTCustomerType := GSTCustomerType::Registered;
        IntraState := false;
        GSTGroupType := GSTGroupType::Service;

        // [GIVEN] Created GST and TCS Setup
        Initialize(GSTCustomerType, GSTGroupType, IntraState);
        InitializeSharedStep(false, false);
        CustomerNo := LibraryStorage.Get('CustomerNo');
        Customer.Get(CustomerNo);
        LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationCode := LibraryStorage.Get('LocationCode');
        //LibraryTCS.CreateGSTTCSSetup(Customer, TCSPostingSetup, ConcessionalCode);
        LocationTan.Get(LocationCode);
        TCANNo.FindFirst();
        LocationTan.Validate("T.C.A.N. No.", TCANNo.Code);
        LocationTan.Modify(true);
        LibraryTCS.UpdateCustomerWithNOCWithOutConcessionalGST(Customer, true, true);
        CreateTaxRateSetup(TCSPostingSetup."TCS Nature of Collection", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and Post Sales Quote with GST and Line Type as G/L Account for Interstate Transactions
        Qty := LibraryRandom.RandInt(5);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", SalesLine."No.", Qty);

        //[THEN] Quote to Make Order Conversion
        LibrarySales.QuoteMakeOrder(SalesHeader);
    end;

    procedure UpdateCustomerSetupWithGST(
        CustomerNo: Code[20];
        GSTCustomerType: Enum "GST Customer Type";
        StateCode: Code[10];
        Pan: Code[20])
    var
        Customer: Record Customer;
        State: Record State;
    begin
        Customer.Get(CustomerNo);
        if GSTCustomerType <> GSTCustomerType::Export then begin
            State.Get(StateCode);
            Customer.Validate("State Code", StateCode);
            Customer.Validate("P.A.N. No.", Pan);
            if not ((GSTCustomerType = GSTCustomerType::" ") or (GSTCustomerType = GSTCustomerType::Unregistered)) then
                Customer.Validate("GST Registration No.", LibraryGST.GenerateGSTRegistrationNo(State."State Code (GST Reg. No.)", Pan));
        end;
        Customer.Validate(Address, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Customer.Address)));
        Customer.Validate("GST Customer Type", GSTCustomerType);
        Customer.Modify(true);
    end;

    [PageHandler]
    procedure GSTTCSTaxRatesPage(var TaxRate: TestPage "Tax Rates")
    var
        Location: Record Location;
        AttributeCaption: Text[50];
        TCSPercentage: Decimal;
        NonPANTCSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        EffectiveDate: Date;
        TCSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        if TaxType = 'GST' then begin
            TaxRate.AttributeValue1.SetValue(LibraryStorage.Get('HSNSACCode'));
            TaxRate.AttributeValue2.SetValue(LibraryStorage.Get('GSTGroupCode'));
            TaxRate.AttributeValue3.SetValue(LibraryStorage.Get('FromStateCode'));
            TaxRate.AttributeValue4.SetValue(LibraryStorage.Get('ToStateCode'));
            TaxRate.AttributeValue5.SetValue(Today);
            TaxRate.AttributeValue6.SetValue(CalcDate('<10Y>', Today));
            TaxRate.AttributeValue7.SetValue(componentPerArray[1]);
            TaxRate.AttributeValue8.SetValue(componentPerArray[2]);
            TaxRate.AttributeValue9.SetValue(componentPerArray[4]);
            TaxRate.AttributeValue10.SetValue(componentPerArray[3]);
            TaxRate.AttributeValue11.SetValue(componentPerArray[5]);
            TaxRate.AttributeValue12.SetValue(componentPerArray[6]);
            TaxRate.OK().Invoke();
            Clear(TaxRate);
        end;
        if TaxType = 'TCS' then begin
            Evaluate(EffectiveDate, LibraryStorage.Get('EffectiveDate'));
            Evaluate(TCSPercentage, LibraryStorage.Get('TCSPercentage'));
            Evaluate(NonPANTCSPercentage, LibraryStorage.Get('NonPANTCSPercentage'));
            Evaluate(SurchargePercentage, LibraryStorage.Get('SurchargePercentage'));
            Evaluate(eCessPercentage, LibraryStorage.Get('eCessPercentage'));
            Evaluate(SHECessPercentage, LibraryStorage.Get('SHECessPercentage'));
            Evaluate(TCSThresholdAmount, LibraryStorage.Get('TCSThresholdAmount'));
            Evaluate(SurchargeThresholdAmount, LibraryStorage.Get('SurchargeThresholdAmount'));

            TaxRate.AttributeValue1.SetValue(LibraryStorage.Get('TCSNOCType'));
            TaxRate.AttributeValue2.SetValue(LibraryStorage.Get('TCSAssesseeCode'));
            TaxRate.AttributeValue3.SetValue(LibraryStorage.Get('TCSConcessionalCode'));
            TaxRate.AttributeValue4.SetValue(EffectiveDate);
            TaxRate.AttributeValue5.SetValue(TCSPercentage);
            TaxRate.AttributeValue6.SetValue(SurchargePercentage);
            TaxRate.AttributeValue7.SetValue(NonPANTCSPercentage);
            TaxRate.AttributeValue8.SetValue(eCessPercentage);
            TaxRate.AttributeValue9.SetValue(SHECessPercentage);
            TaxRate.AttributeValue10.SetValue(TCSThresholdAmount);
            TaxRate.AttributeValue11.SetValue(SurchargeThresholdAmount);
            TaxRate.OK().Invoke();
            TaxRate.OK().Invoke();
        end;
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates")
    var
        TCSPercentage: Decimal;
        NonPANTCSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        EffectiveDate: Date;
        TCSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
    begin
        Evaluate(EffectiveDate, LibraryStorage.Get('EffectiveDate'));
        Evaluate(TCSPercentage, LibraryStorage.Get('TCSPercentage'));
        Evaluate(NonPANTCSPercentage, LibraryStorage.Get('NonPANTCSPercentage'));
        Evaluate(SurchargePercentage, LibraryStorage.Get('SurchargePercentage'));
        Evaluate(eCessPercentage, LibraryStorage.Get('eCessPercentage'));
        Evaluate(SHECessPercentage, LibraryStorage.Get('SHECessPercentage'));
        Evaluate(TCSThresholdAmount, LibraryStorage.Get('TCSThresholdAmount'));
        Evaluate(SurchargeThresholdAmount, LibraryStorage.Get('SurchargeThresholdAmount'));

        TaxRate.AttributeValue1.SetValue(LibraryStorage.Get('TCSNOCType'));
        TaxRate.AttributeValue2.SetValue(LibraryStorage.Get('TCSAssesseeCode'));
        TaxRate.AttributeValue3.SetValue(LibraryStorage.Get('TCSConcessionalCode'));
        TaxRate.AttributeValue4.SetValue(EffectiveDate);
        TaxRate.AttributeValue5.SetValue(TCSPercentage);
        TaxRate.AttributeValue6.SetValue(SurchargePercentage);
        TaxRate.AttributeValue7.SetValue(NonPANTCSPercentage);
        TaxRate.AttributeValue8.SetValue(eCessPercentage);
        TaxRate.AttributeValue9.SetValue(SHECessPercentage);
        TaxRate.AttributeValue10.SetValue(TCSThresholdAmount);
        TaxRate.AttributeValue11.SetValue(SurchargeThresholdAmount);
        TaxRate.OK().Invoke();
    end;

    local procedure CreateSalesDocument(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        DocumenType: Enum "Sales Document Type";
        CustomerNo: Code[20];
        LocationCode: Code[10];
        GSTGroupCode: Code[20];
        HSNSACCode: Code[10];
        LineType: Enum "Sales Line Type";
        WithoutPaymentofDuty: Boolean;
        PlaceofSupply: Boolean;
        AssessableValue: Boolean;
        NoOfLine: Integer)
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
                    LineTypeNo := LibraryGST.CreateItemWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, true, false);
                LineType::"G/L Account":
                    LineTypeNo := LibraryGST.CreateGLAccWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, true, false);
                LineType::"Fixed Asset":
                    LineTypeNo := LibraryGST.CreateFixedAssetWithGSTDetails(VATPostingSetup, GSTGroupCode, HSNSACCode, true, false);
            end;
            CreateSalesLine(SalesHeader, SalesLine, LineType, LineTypeNo, LibraryRandom.RandDecInRange(2, 10, 0), Amount, AssessableValue);
        end;
    end;

    local procedure CreateSalesHeader(
        var SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        DocumentType: Enum "Sales Document Type";
        LocationCode: Code[10];
        WithoutPaymentofDuty: Boolean;
        PlaceofSupply: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Location Code", LocationCode);

        if WithoutPaymentofDuty then
            SalesHeader.Validate("GST Without Payment of Duty", true);

        if PlaceofSupply then begin
            SalesHeader.Validate("GST Invoice", true);
            SalesHeader.Validate("POS Out Of India", true);
        end;
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        Type: Enum "Sales Line Type";
        ItemNo: Code[20];
        Qty: Decimal;
        Amount: Decimal;
        AssessableValue: Boolean)
    var
        TCSNOCType: Code[10];
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Qty);
        SalesLine.Validate(Quantity, Qty);
        if AssessableValue then begin
            SalesLine.Validate("GST On Assessable Value", true);
            SalesLine.Validate("GST Assessable Value (LCY)", Amount);
        end;
        TCSNOCType := LibraryStorage.Get('TCSNOCType');
        SalesLine.Validate("TCS Nature of Collection", TCSNOCType);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure Initialize(
        GSTCustomerType: Enum "GST Customer Type";
        GSTGroupType: Enum "GST Group Type";
        IntraState: Boolean)
    var
        GSTGroup: Record "GST Group";
        HSNSAC: Record "HSN/SAC";
        GSTComponent: Record "Tax Component";
        CompanyInformation: Record "Company information";
        TaxTypeSetup: Record "Tax Type Setup";
        LocationStateCode: Code[10];
        CustomerNo: Code[20];
        LocationCode: Code[10];
        CustomerStateCode: Code[10];
        LocPan: Code[20];
        HSNSACCode: Code[10];
        GSTGroupCode: Code[20];
        LocationGSTRegNo: Code[15];
        CompInfoStateCode: Code[10];
        HsnSacType: Enum "GST Goods And Services Type";
        GSTcomponentcode: Text[30];
    begin
        FillCompanyInformation();
        CompanyInformation.Get();
        LocPan := LibraryStorage.Get('PANNo');
        LocationStateCode := LibraryGST.CreateInitialSetup();
        if CompanyInformation."State Code" = '' then begin
            CompanyInformation."State Code" := LocationStateCode;
            CompanyInformation.Modify(true);
        end;
        LibraryStorage.Set('LocationStateCode', LocationStateCode);

        LocationGSTRegNo := LibraryGST.CreateGSTRegistrationNos(LocationStateCode, LocPan);
        if CompanyInformation."GST Registration No." = '' then begin
            CompanyInformation."GST Registration No." := LocationGSTRegNo;
            CompanyInformation.Modify(true);
        end;

        LocationCode := LibraryGST.CreateLocationSetup(LocationStateCode, LocationGSTRegNo, false);
        LibraryStorage.Set('LocationCode', LocationCode);

        GSTGroupCode := LibraryGST.CreateGSTGroup(GSTGroup, GSTGroupType, GSTGroup."GST Place Of Supply"::" ", false);
        LibraryStorage.Set('GSTGroupCode', GSTGroupCode);

        HSNSACCode := LibraryGST.CreateHSNSACCode(HSNSAC, GSTGroupCode, HsnSacType::HSN);
        LibraryStorage.Set('HSNSACCode', HSNSACCode);

        if IntraState then begin
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, LocationStateCode, LocPan);
            InitializeTaxRateParameters(IntraState, LocationStateCode, LocationStateCode);
            CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
        end else begin
            CustomerStateCode := LibraryGST.CreateGSTStateCode();
            CustomerNo := LibraryGST.CreateCustomerSetup();
            UpdateCustomerSetupWithGST(CustomerNo, GSTCustomerType, CustomerStateCode, LocPan);
            LibraryStorage.Set('CustomerStateCode', CustomerStateCode);
            if GSTCustomerType in [GSTCustomerType::Export, GSTCustomerType::"SEZ Unit", GSTCustomerType::"SEZ Development"] then
                InitializeTaxRateParameters(IntraState, '', LocationStateCode)
            else begin
                InitializeTaxRateParameters(IntraState, CustomerStateCode, LocationStateCode);
                CreateGSTComponentAndPostingSetup(IntraState, LocationStateCode, GSTComponent, GSTcomponentcode);
            end;
        end;
        LibraryStorage.Set('CustomerNo', CustomerNo);

        if not TaxTypeSetup.Get() then
            exit;
        TaxType := TaxTypeSetup.Code;
        CreateGSTRate();
    end;

    local procedure InitializeSharedStep(Exempted: Boolean; LineDiscount: Boolean)
    begin
        LibraryStorage.Set('Exempted', Format(Exempted));
        LibraryStorage.Set('LineDiscount', Format(LineDiscount));
    end;

    local procedure InitializeTaxRateParameters(IntraState: Boolean; FromState: Code[10]; ToState: Code[10])
    var
        GSTTaxPercent: Decimal;
    begin
        LibraryStorage.Set('FromStateCode', FromState);
        LibraryStorage.Set('ToStateCode', ToState);

        GSTTaxPercent := LibraryRandom.RandDecInRange(10, 18, 0);
        if IntraState then begin
            componentPerArray[1] := (GSTTaxPercent / 2);
            componentPerArray[2] := (GSTTaxPercent / 2);
            componentPerArray[3] := 0;
        end else
            componentPerArray[4] := GSTTaxPercent;
    end;

    local procedure CreateGSTComponentAndPostingSetup(
        IntraState: Boolean;
        LocationStateCode: Code[10];
        GSTComponent: Record "Tax Component";
        GSTcomponentcode: Text[30])
    begin
        if IntraState then begin
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

    local procedure CreateTCSRate()
    var
        TCSSetup: Record "TCS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxType);
        PageTaxtype.TaxRates.Invoke();
    end;

    local procedure CreateGSTRate()
    var
        TaxTypeSetup: Record "Tax Type Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TaxType);
        PageTaxtype.TaxRates.Invoke();
    end;

    local procedure CreateTaxRateSetup(
        TCSNOC: Code[10];
        AssesseeCode: Code[10];
        ConcessionalCode: Code[10];
        EffectiveDate: Date)
    var
        TCSSetup: Record "TCS Setup";
    begin
        LibraryStorage.Set('TCSNOCType', TCSNOC);
        LibraryStorage.Set('TCSAssesseeCode', AssesseeCode);
        LibraryStorage.Set('TCSConcessionalCode', ConcessionalCode);
        LibraryStorage.Set('EffectiveDate', Format(EffectiveDate));
        GenerateTaxComponentsPercentage();
        TaxType := TCSSetup."Tax Type";
        CreateTCSRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        LibraryStorage.Set('TCSPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        LibraryStorage.Set('NonPANTCSPercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        LibraryStorage.Set('SurchargePercentage', Format(LibraryRandom.RandIntInRange(6, 10)));
        LibraryStorage.Set('eCessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        LibraryStorage.Set('SHECessPercentage', Format(LibraryRandom.RandIntInRange(2, 4)));
        LibraryStorage.Set('TCSThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
        LibraryStorage.Set('SurchargeThresholdAmount', Format(LibraryRandom.RandIntInRange(4000, 6000)));
    end;

    local procedure FillCompanyInformation()
    var
        CompInfo: Record "Company Information";
        GSTRegistrationNos: Record "GST Registration Nos.";
    begin
        CompInfo.Get();
        if CompInfo."State Code" = '' then
            CompInfo.Validate("State Code", LibraryGST.CreateGSTStateCode());
        LibraryStorage.Set('CompInfoStateCode', CompInfo."State Code");
        CompInfo.Validate("Circle No.", LibraryUtility.GenerateRandomText(30));
        CompInfo."P.A.N. No." := LibraryGST.CreatePANNos();
        LibraryStorage.Set('PANNo', CompInfo."P.A.N. No.");
        CompInfo.Validate("Ward No.", LibraryUtility.GenerateRandomText(30));
        CompInfo.Validate("Assessing Officer", LibraryUtility.GenerateRandomText(30));
        //CompInfo.Validate("Deductor Category", LibraryTCS.CreateDeductorCategory());
        CompInfo.Modify(true);
    end;
}