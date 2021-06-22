codeunit 135536 "Sales Credit Memo E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Credit Memo]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        CreditMemoServiceNameTxt: Label 'salesCreditMemos';
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        GraphContactIdFieldTxt: Label 'contactId';
        CustomerIdFieldTxt: Label 'customerId';
        CustomerNameFieldTxt: Label 'customerName';
        CustomerNumberFieldTxt: Label 'customerNumber';
        DiscountAmountFieldTxt: Label 'discountAmount';

    local procedure Initialize()
    begin
        WorkDate := Today;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCreditMemos()
    var
        CreditMemoNo1: Text;
        CreditMemoNo2: Text;
        CreditMemoJSON1: Text;
        CreditMemoJSON2: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create posted and unposted sales credit memos and use a GET method to retrieve them
        // [GIVEN] 2 credit memos, one posted and one unposted
        Initialize;
        CreateSalesCreditMemos(CreditMemoNo1, CreditMemoNo2);
        Commit;

        // [WHEN] we GET all the credit memos from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 credit memos should exist in the response
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'number', CreditMemoNo1, CreditMemoNo2, CreditMemoJSON1, CreditMemoJSON2),
          'Could not find the credit memos in JSON');
        LibraryGraphMgt.VerifyIDInJson(CreditMemoJSON1);
        LibraryGraphMgt.VerifyIDInJson(CreditMemoJSON2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemos()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerNo: Text;
        CreditMemoDate: Date;
        ResponseText: Text;
        CreditMemoNumber: Text;
        TargetURL: Text;
        CreditMemoWithComplexJSON: Text;
    begin
        // [SCENARIO] Create posted and unposted Sales credit memos and use HTTP POST to delete them
        // [GIVEN] 2 credit memos, one posted and one unposted
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        CreditMemoDate := Today;

        CreditMemoWithComplexJSON := CreateCreditMemoJSONWithAddress(Customer, CreditMemoDate);
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoWithComplexJSON, ResponseText);

        // [THEN] the response text should have the correct Id, credit memo address and the credit memo should exist in the table with currency code set by default
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', CreditMemoNumber),
          'Could not find sales credit memo number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, false, false);

        GetSalesCreditMemoHeaderByCustomerNumberAndDate(
          CustomerNo, CreditMemoNumber, CreditMemoDate, SalesHeader, 'The unposted credit memo should exist');
        Assert.AreEqual('', SalesHeader."Currency Code", 'The credit memo should have the LCY currency code set by default');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CustomerNo: Text;
        ResponseText: Text;
        CreditMemoNumber: Text;
        TargetURL: Text;
        CreditMemoJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] Create posted and unposted with specific currency set and use HTTP POST to create them
        Initialize;

        // [GIVEN] an CreditMemo with a non-LCY currencyCode set
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', CustomerNo);
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        JSONManagement.AddJPropertyToJObject(JObject, 'currencyCode', CurrencyCode);
        CreditMemoJSON := JSONManagement.WriteObjectToString;
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoJSON, ResponseText);

        // [THEN] the response text should contain the credit memo ID and the integration record table should map the SalesCreditMemoID with the ID
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', CreditMemoNumber),
          'Could not find sales credit memo number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        // [THEN] the credit memo should exist in the tables
        GetSalesCreditMemoHeaderByCustomerAndNumber(CustomerNo, CreditMemoNumber, SalesHeader, 'The unposted credit memo should exist');
        Assert.AreEqual(CurrencyCode, SalesHeader."Currency Code", 'The credit memo should have the correct currency code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCreditMemos()
    begin
        TestMultipleModifyCreditMemos(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyModifyCreditMemos()
    begin
        TestMultipleModifyCreditMemos(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPartialModifyCreditMemos()
    begin
        TestMultipleModifyCreditMemos(false, true);
    end;

    local procedure TestMultipleModifyCreditMemos(EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CreditMemoID: Text;
        CreditMemoNo: Text;
        ResponseText: Text;
        TargetURL: Text;
        CreditMemoJSON: Text;
        CreditMemoWithComplexJSON: Text;
        ComplexTypeJSON: Text;
    begin
        // [SCENARIO] Create Sales CreditMemo, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        CreditMemoNo := SalesHeader."No.";

        // [GIVEN] the credit memo's unique ID
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo);
        CreditMemoID := SalesHeader.SystemId;
        Assert.AreNotEqual('', CreditMemoID, 'ID should not be empty');

        if EmptyData then
            CreditMemoJSON := '{}'
        else begin
            CreditMemoJSON := LibraryGraphMgt.AddPropertytoJSON(CreditMemoJSON, 'salesperson', SalespersonPurchaser.Code);
            CreditMemoJSON := LibraryGraphMgt.AddPropertytoJSON(CreditMemoJSON, 'customerNumber', Customer."No.");
        end;

        // [GIVEN] a JSON text with an Item that has the BillingPostalAddress complex type
        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, EmptyData, PartiallyEmptyData);
        CreditMemoWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(CreditMemoJSON, 'billingPostalAddress', ComplexTypeJSON);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(CreditMemoID, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, CreditMemoWithComplexJSON, ResponseText);

        // [THEN] the item should have the Unit of Measure as a value in the table
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo), 'The unposted credit memo should exist');
        if not EmptyData then
            Assert.AreEqual(SalesHeader."Salesperson Code", SalespersonPurchaser.Code, 'The patch of Sales Person code was unsuccessful');

        // [THEN] the response text should contain the credit memo address
        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, EmptyData, PartiallyEmptyData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        CreditMemoNo1: Text;
        CreditMemoNo2: Text;
        CreditMemoID1: Text;
        CreditMemoID2: Text;
    begin
        // [SCENARIO] Create posted and unposted sales credit memos and use HTTP DELETE to delete them
        // [GIVEN] 2 credit memos, one posted and one unposted
        Initialize;
        CreateSalesCreditMemos(CreditMemoNo1, CreditMemoNo2);

        SalesCrMemoHeader.Get(CreditMemoNo1);
        CreditMemoID1 := SalesCrMemoHeader."Draft Cr. Memo SystemId";
        Assert.AreNotEqual('', CreditMemoID1, 'ID should not be empty');

        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo2);
        CreditMemoID2 := SalesHeader.SystemId;
        Assert.AreNotEqual('', CreditMemoID2, 'ID should not be empty');

        // [WHEN] we DELETE the item from the web service, with the item's unique ID
        DeleteCreditMemoThroughAPI(CreditMemoID1);
        DeleteCreditMemoThroughAPI(CreditMemoID2);

        // [THEN] the credit memos shouldn't exist in the tables
        if SalesCrMemoHeader.Get(CreditMemoNo1) then
            Assert.ExpectedError('The posted credit memo should not exist');

        if SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", CreditMemoNo2) then
            Assert.ExpectedError('The unposted credit memo should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCreditMemoThroughPageAndAPI()
    var
        PageSalesHeader: Record "Sales Header";
        ApiSalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerNo: Text;
        CreditMemoDate: Date;
        CreditMemoWithComplexJSON: Text;
    begin
        // [SCENARIO] Create an credit memo both through the client UI and through the API
        // [SCENARIO] and compare them. They should be the same and have the same fields autocompleted wherever needed.
        // [GIVEN] An unposted credit memo
        Initialize;
        LibraryGraphDocumentTools.InitializeUIPage;

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        CreditMemoDate := Today;

        // [GIVEN] a json describing our new credit memo
        CreditMemoWithComplexJSON := CreateCreditMemoJSONWithAddress(Customer, CreditMemoDate);
        Commit;

        // [WHEN] we POST the JSON to the web service and create another credit memo through the test page
        CreateCreditMemoThroughAPI(CreditMemoWithComplexJSON);
        CreateCreditMemoThroughTestPage(SalesCreditMemo, Customer, CreditMemoDate);

        // [THEN] the credit memo should exist in the table and match the credit memo created from the page
        GetSalesCreditMemoHeaderByCustomerAndDate(CustomerNo, CreditMemoDate, ApiSalesHeader, 'The unposted credit memo should exist');
        PageSalesHeader.Get(PageSalesHeader."Document Type"::"Credit Memo", SalesCreditMemo."No.".Value);

        VerifyCreditMemosMatching(ApiSalesHeader, PageSalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCreditMemosAppliesDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
    begin
        // [SCENARIO] When an credit memo is created,the GET Method should update the credit memo and assign a total
        // [GIVEN] 2 credit memos, one posted and one unposted without totals assigned
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(
          SalesHeader, DiscountPct, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate credit memo disc. should be set');

        Commit;

        // [WHEN] we GET all the credit memos from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 1 credit memo should exist in the response and CreditMemo Discount Should be Applied
        VerifyGettingAgainKeepsETag(ResponseText, TargetURL);
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCreditMemosRedistributesDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
        DiscountAmt: Decimal;
    begin
        // [SCENARIO] When an credit memo is created, the GET Method should update the credit memo and assign a total
        // [GIVEN] 2 credit memos, one posted and one unposted with discount amount that should be redistributed
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(
          SalesHeader, DiscountPct, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.CalcFields(Amount);
        DiscountAmt := LibraryRandom.RandDecInRange(1, Round(SalesHeader.Amount / 2, 1), 1);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmt, SalesHeader);
        GetFirstSalesCreditMemoLine(SalesHeader, SalesLine);
        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate credit memo disc. should be set');
        Commit;

        // [WHEN] we GET all the credit memos from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the credit memo should exist in the response and CreditMemo Discount Should be Applied
        VerifyGettingAgainKeepsETag(ResponseText, TargetURL);
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountAmt, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCreditMemosWithContactId()
    var
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        CreditMemoID: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Create an credit memo with a contact with graph ID (GET method should return Graph Contact ID)
        // [GIVEN] One credit memo with contact ID
        Initialize;

        CreateSalesCreditMemoWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        CreditMemoID := SalesHeader.SystemId;

        // [WHEN] We get credit memo from web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(CreditMemoID, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The credit memo should contain the Contact ID
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemosWithGraphContactId()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        CreditMemoWithComplexJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        CreditMemoNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Posting an credit memo with Graph Contact ID (POST method should find the customer based on Contact ID)
        // [GIVEN] One credit memo with contact ID
        Initialize;
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        CreditMemoWithComplexJSON := CreateCreditMemoJSONWithContactId(GraphIntegrationRecord);

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        Commit;

        // [WHEN] We post an credit memo to web service
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoWithComplexJSON, ResponseText);

        // [THEN] The credit memo should have a customer found based on contact ID
        VerifyValidPostRequest(ResponseText, CreditMemoNumber);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(Customer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(CreditMemoNumber, SalesHeader."Document Type"::"Credit Memo", Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingContactIdUpdatesSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        SecondCustomer: Record Customer;
        SecondContact: Record Contact;
        SecondGraphIntegrationRecord: Record "Graph Integration Record";
        CreditMemoID: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        CreditMemoWithComplexJSON: Text;
        CreditMemoNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Create an credit memo with a contact with graph ID (Selecting a different contact will change sell-to customer)
        // [GIVEN] One credit memo with contact ID
        Initialize;

        CreateSalesCreditMemoWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        CreditMemoID := SalesHeader.SystemId;

        LibraryGraphDocumentTools.CreateContactWithGraphId(SecondContact, SecondGraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(SecondCustomer, SecondContact);

        TargetURL := LibraryGraphMgt.CreateTargetURL(CreditMemoID, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        CreditMemoWithComplexJSON := CreateCreditMemoJSONWithContactId(SecondGraphIntegrationRecord);

        Commit;

        // [WHEN] We Patch to web service
        LibraryGraphMgt.PatchToWebService(TargetURL, CreditMemoWithComplexJSON, ResponseText);

        // [THEN] The credit memo should have a new customer
        VerifyValidPostRequest(ResponseText, CreditMemoNumber);
        VerifyContactId(ResponseText, SecondGraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(SecondCustomer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(CreditMemoNumber, SalesHeader."Document Type"::"Credit Memo", SecondContact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoDataIntegrationRecordIdsForCreditMemos()
    var
        SalesHeader: Record "Sales Header";
        BlankGuid: Guid;
    begin
        // [SCENARIO] Integration record ids should be set correctly.
        // [GIVEN] We have demo data applied correctly
        SalesHeader.SetRange(Id, BlankGuid);
        Assert.IsFalse(SalesHeader.FindFirst, 'No sales headers should have null id');

        // [WHEN] We look through all sales headers.
        // [THEN] The integration record for the sales header should have the same record id.
        SalesHeader.Reset;
        if SalesHeader.Find('-') then begin
            repeat
                VerifySalesHeaderRegisteredInIntegrationTable(SalesHeader);
            until SalesHeader.Next <= 0
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCreditMemoSetManualDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        InvoiceDiscountAmount: Decimal;
        TargetURL: Text;
        CreditMemoJSON: Text;
        ResponseText: Text;
        CreditMemoID: Text;
    begin
        // [SCENARIO 184721] Create Credit Memo, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] an line in the previously created Credit memo
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.SetAutoCalcFields(Amount);
        SalesHeader.Find;
        CreditMemoID := SalesHeader."No.";
        InvoiceDiscountAmount := SalesHeader.Amount / 2;
        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        CreditMemoJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(InvoiceDiscountAmount, 0, 9));
        LibraryGraphMgt.PatchToWebService(TargetURL, CreditMemoJSON, ResponseText);

        // [THEN] Response contains the updated value
        VerifyValidPostRequest(ResponseText, CreditMemoID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, InvoiceDiscountAmount);

        // [THEN] Header value was updated
        SalesHeader.Find;
        SalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(InvoiceDiscountAmount, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearingManualDiscounts()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        TargetURL: Text;
        CreditMemoJSON: Text;
        ResponseText: Text;
        CreditMemoID: Text;
    begin
        // [SCENARIO 184721] Clearing manually set discount
        Initialize;

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [Given] a customer
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] an line in the previously created credit memo
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.SetAutoCalcFields(Amount);
        SalesHeader.Find;

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 2, SalesHeader);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        CreditMemoJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(0, 0, 9));
        LibraryGraphMgt.PatchToWebService(TargetURL, CreditMemoJSON, ResponseText);

        // [THEN] Discount should be removed
        CreditMemoID := SalesHeader."No.";
        VerifyValidPostRequest(ResponseText, CreditMemoID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, 0);

        // [THEN] Header value was updated
        SalesHeader.Find;
        SalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');
    end;

    local procedure CreateSalesCreditMemos(var CreditMemoNo1: Text; var CreditMemoNo2: Text)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.SetAllowDocumentDeletionBeforeDate(WorkDate + 1);
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate);
        CreditMemoNo1 := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate);
        CreditMemoNo2 := SalesHeader."No.";
        Commit;
    end;

    local procedure CreateCreditMemoJSONWithAddress(Customer: Record Customer; CreditMemoDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CreditMemoJSON: Text;
        ComplexTypeJSON: Text;
        CreditMemoWithComplexJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', Customer."No.");
        JSONManagement.AddJPropertyToJObject(JObject, 'creditMemoDate', CreditMemoDate);
        CreditMemoJSON := JSONManagement.WriteObjectToString;

        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, false, false);
        CreditMemoWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(CreditMemoJSON, 'billingPostalAddress', ComplexTypeJSON);
        exit(CreditMemoWithComplexJSON);
    end;

    local procedure CreateCreditMemoThroughTestPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; Customer: Record Customer; DocumentDate: Date)
    begin
        SalesCreditMemo.OpenNew;
        SalesCreditMemo."Sell-to Customer No.".SetValue(Customer."No.");
        SalesCreditMemo."Document Date".SetValue(DocumentDate);
    end;

    local procedure CreateCreditMemoThroughAPI(CreditMemoWithComplexJSON: Text)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoWithComplexJSON, ResponseText);
    end;

    local procedure DeleteCreditMemoThroughAPI(CreditMemoID: Text)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL(CreditMemoID, PAGE::"Sales Credit Memo Entity", CreditMemoServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
    end;

    local procedure VerifyGettingAgainKeepsETag(JSONText: Text; TargetURL: Text)
    var
        ETag: Text;
        NewResponseText: Text;
        NewETag: Text;
    begin
        Assert.IsTrue(LibraryGraphMgt.GetETagFromJSON(JSONText, ETag), 'Could not get etag');
        LibraryGraphMgt.GetFromWebService(NewResponseText, TargetURL);
        Assert.IsTrue(LibraryGraphMgt.GetETagFromJSON(NewResponseText, NewETag), 'Could not get ETag from new request');
        Assert.AreEqual(ETag, NewETag, 'Getting twice should not change ETags');
    end;

    local procedure GetFirstSalesCreditMemoLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
    end;

    local procedure CreateSalesCreditMemoWithGraphContactID(var SalesHeader: Record "Sales Header"; var GraphIntegrationRecord: Record "Graph Integration Record")
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
    end;

    local procedure CreateCreditMemoJSONWithContactId(GraphIntegrationRecord: Record "Graph Integration Record"): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CreditMemoJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, GraphContactIdFieldTxt, GraphIntegrationRecord."Graph ID");
        CreditMemoJSON := JSONManagement.WriteObjectToString;

        exit(CreditMemoJSON);
    end;

    local procedure ModifySalesHeaderPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure VerifyContactId(ResponseText: Text; ExpectedContactId: Text)
    var
        contactId: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, GraphContactIdFieldTxt, contactId);
        Assert.AreEqual(ExpectedContactId, contactId, 'Wrong contact id was returned');
    end;

    local procedure VerifyValidPostRequest(ResponseText: Text; var CreditMemoNumber: Text)
    begin
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', CreditMemoNumber),
          'Could not find sales credit memo number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    local procedure VerifyCustomerFields(ExpectedCustomer: Record Customer; ResponseText: Text)
    var
        IntegrationManagement: Codeunit "Integration Management";
        customerIdValue: Text;
        customerNameValue: Text;
        customerNumberValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, CustomerIdFieldTxt, customerIdValue);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, CustomerNameFieldTxt, customerNameValue);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, CustomerNumberFieldTxt, customerNumberValue);

        Assert.AreEqual(
          IntegrationManagement.GetIdWithoutBrackets(ExpectedCustomer.Id), UpperCase(customerIdValue), 'Wrong setting for Customer Id');
        Assert.AreEqual(ExpectedCustomer."No.", customerNumberValue, 'Wrong setting for Customer Number');
        Assert.AreEqual(ExpectedCustomer.Name, customerNameValue, 'Wrong setting for Customer Name');
    end;

    local procedure VerifyContactFieldsUpdatedOnSalesHeader(DocumentNumber: Text; DocumentType: Option; ExpectedContact: Record Contact)
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.IsTrue(SalesHeader.Get(DocumentType, DocumentNumber), 'Could not find the sales header for ' + DocumentNumber);
        Assert.AreEqual(ExpectedContact."No.", SalesHeader."Sell-to Contact No.", 'Wrong sell to contact no');
    end;

    local procedure VerifySalesHeaderRegisteredInIntegrationTable(var SalesHeader: Record "Sales Header")
    var
        IntegrationRecord: Record "Integration Record";
    begin
        Assert.IsTrue(IntegrationRecord.Get(SalesHeader.SystemId), 'The SalesHeader id should exist in the integration record table');
        Assert.AreEqual(
          IntegrationRecord."Record ID", SalesHeader.RecordId,
          'The integration record for the SalesHeader should have the same record id as the SalesHeader.');
    end;

    local procedure GetSalesCreditMemoHeaderByCustomerNumberAndDate(CustomerNo: Text; CreditMemoNo: Text; CreditMemoDate: Date; var SalesHeader: Record "Sales Header"; ErrorMessage: Text)
    begin
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("No.", CreditMemoNo);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Date", CreditMemoDate);
        Assert.IsTrue(SalesHeader.FindFirst, ErrorMessage);
    end;

    local procedure GetSalesCreditMemoHeaderByCustomerAndNumber(CustomerNo: Text; CreditMemoNo: Text; var SalesHeader: Record "Sales Header"; ErrorMessage: Text)
    begin
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("No.", CreditMemoNo);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.FindFirst, ErrorMessage);
    end;

    local procedure GetSalesCreditMemoHeaderByCustomerAndDate(CustomerNo: Text; CreditMemoDate: Date; var SalesHeader: Record "Sales Header"; ErrorMessage: Text)
    begin
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Date", CreditMemoDate);
        Assert.IsTrue(SalesHeader.FindFirst, ErrorMessage);
    end;

    local procedure VerifyCreditMemosMatching(var SalesHeader1: Record "Sales Header"; var SalesHeader2: Record "Sales Header")
    var
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        SalesHeader1RecordRef: RecordRef;
        SalesHeader2RecordRef: RecordRef;
    begin
        // Ignore these fields when comparing Page and API CreditMemos
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo("No."), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo("Posting Description"), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo(Id), DATABASE::"Sales Header");

        // Time zone will impact how the date from the page vs WebService is saved. If removed this will fail in snap between 12:00 - 1 AM
        if Time < 020000T then begin
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo("Order Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo("Shipment Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesHeader1.FieldNo("Posting Date"), DATABASE::"Sales Header");
        end;

        SalesHeader1RecordRef.GetTable(SalesHeader1);
        SalesHeader2RecordRef.GetTable(SalesHeader2);

        Assert.RecordsAreEqualExceptCertainFields(
          SalesHeader1RecordRef, SalesHeader2RecordRef, TempIgnoredFieldsForComparison, 'Credit Memos do not match');
    end;
}

