codeunit 135530 "Sales Quote E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Quote]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        QuoteServiceNameTxt: Label 'salesQuotes';
        GraphContactIdFieldTxt: Label 'contactId';
        CustomerIdFieldTxt: Label 'customerId';
        CustomerNameFieldTxt: Label 'customerName';
        CustomerNumberFieldTxt: Label 'customerNumber';
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        DiscountAmountFieldTxt: Label 'discountAmount';

    local procedure Initialize()
    begin
        WorkDate := Today;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuotes()
    var
        SalesHeader: Record "Sales Header";
        QuoteID: array[2] of Text;
        QuoteJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create Sales Quotes and use a GET method to retrieve them
        // [GIVEN] 2 quotes in the table
        Initialize;
        CreateSalesQuoteWithLines(SalesHeader);
        QuoteID[1] := SalesHeader."No.";

        CreateSalesQuoteWithLines(SalesHeader);
        QuoteID[2] := SalesHeader."No.";
        Commit;

        // [WHEN] we GET all the quotes from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 quotes should exist in the response
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'number', QuoteID[1], QuoteID[2], QuoteJSON[1], QuoteJSON[2]),
          'Could not find the quotes in JSON');
        LibraryGraphMgt.VerifyIDInJson(QuoteJSON[1]);
        LibraryGraphMgt.VerifyIDInJson(QuoteJSON[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostQuotes()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerNo: Text;
        QuoteDate: Date;
        ResponseText: Text;
        QuoteNumber: Text;
        TargetURL: Text;
        QuoteWithComplexJSON: Text;
        QuoteExists: Boolean;
    begin
        // [SCENARIO] Create sales quotes JSON and use HTTP POST to create them
        Initialize;

        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        Commit;
        CustomerNo := Customer."No.";
        QuoteDate := Today;

        // [GIVEN] a JSON text with a quote that contains the customer and an adress as complex type
        QuoteWithComplexJSON := CreateQuoteJSONWithAddress(Customer, QuoteDate);
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteWithComplexJSON, ResponseText);

        // [THEN] the response text should have the correct Id, quote address and the quote should exist in the table with currency code set by default
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', QuoteNumber), 'Could not find sales quote number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, false, false);

        QuoteExists := FindSalesHeader(SalesHeader, CustomerNo, QuoteNumber);
        Assert.IsTrue(QuoteExists, 'The quote should exist');
        Assert.AreEqual('', SalesHeader."Currency Code", 'The quote should have the LCY currency code set by default');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostQuoteWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CustomerNo: Text;
        ResponseText: Text;
        QuoteNumber: Text;
        TargetURL: Text;
        QuoteJSON: Text;
        CurrencyCode: Code[10];
        QuoteExists: Boolean;
    begin
        // [SCENARIO] Create sales quote with specific currency set and use HTTP POST to create it
        Initialize;

        // [GIVEN] a quote with a non-LCY currencyCode set
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', CustomerNo);
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        JSONManagement.AddJPropertyToJObject(JObject, 'currencyCode', CurrencyCode);
        QuoteJSON := JSONManagement.WriteObjectToString;
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteJSON, ResponseText);

        // [THEN] the response text should contain the correct Id and the quote should be created
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', QuoteNumber),
          'Could not find the sales quote number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        QuoteExists := FindSalesHeader(SalesHeader, CustomerNo, QuoteNumber);
        Assert.IsTrue(QuoteExists, 'The quote should exist');
        Assert.AreEqual(CurrencyCode, SalesHeader."Currency Code", 'The quote should have the correct currency code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyQuotes()
    begin
        TestMultipleModifyQuotes(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyModifyQuotes()
    begin
        TestMultipleModifyQuotes(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPartialModifyQuotes()
    begin
        TestMultipleModifyQuotes(false, true);
    end;

    local procedure TestMultipleModifyQuotes(EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        QuoteIntegrationID: Text;
        QuoteNumber: Text;
        ResponseText: Text;
        TargetURL: Text;
        QuoteJSON: Text;
        QuoteWithComplexJSON: Text;
        ComplexTypeJSON: Text;
    begin
        // [SCENARIO] Create sales quote, use a PATCH method to change it and then verify the changes
        // [GIVEN] a customer with address
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] a salesperson
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] a quote with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an line in the previously created quote
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        QuoteNumber := SalesHeader."No.";

        // [GIVEN] the quote's unique ID
        FindSalesHeader(SalesHeader, '', QuoteNumber);
        QuoteIntegrationID := SalesHeader.Id;
        Assert.AreNotEqual('', QuoteIntegrationID, 'ID should not be empty');

        if EmptyData then
            QuoteJSON := '{}'
        else begin
            QuoteJSON := LibraryGraphMgt.AddPropertytoJSON(QuoteJSON, 'salesperson', SalespersonPurchaser.Code);
            QuoteJSON := LibraryGraphMgt.AddPropertytoJSON(QuoteJSON, 'customerNumber', Customer."No.");
        end;

        // [GIVEN] a JSON text with an quote that has the BillingPostalAddress complex type
        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, EmptyData, PartiallyEmptyData);
        QuoteWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(QuoteJSON, 'billingPostalAddress', ComplexTypeJSON);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique quote ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(QuoteIntegrationID, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteWithComplexJSON, ResponseText);

        // [THEN] the quote should have the Unit of Measure and address as a value in the table
        FindSalesHeader(SalesHeader, '', QuoteNumber);
        Assert.IsTrue(SalesHeader.FindFirst, 'The sales quote should exist in the table');
        if not EmptyData then
            Assert.AreEqual(SalesHeader."Salesperson Code", SalespersonPurchaser.Code, 'The patch of Sales Person code was unsuccessful');

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, EmptyData, PartiallyEmptyData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteQuotes()
    var
        SalesHeader: Record "Sales Header";
        QuoteID: array[2] of Text;
        ID: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create sales quotes and use HTTP DELETE to delete them
        // [GIVEN] 2 quotes in the table
        Initialize;
        CreateSalesQuoteWithLines(SalesHeader);
        QuoteID[1] := SalesHeader."No.";
        ID[1] := SalesHeader.Id;
        Assert.AreNotEqual('', ID[1], 'ID should not be empty');

        CreateSalesQuoteWithLines(SalesHeader);
        QuoteID[2] := SalesHeader."No.";
        ID[2] := SalesHeader.Id;
        Assert.AreNotEqual('', ID[2], 'ID should not be empty');
        Commit;

        // [WHEN] we DELETE the quotes from the web service, with the quotes' unique IDs
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID[1], PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID[2], PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the quotes shouldn't exist in the table
        if SalesHeader.Get(SalesHeader."Document Type"::Quote, QuoteID[1]) then
            Assert.ExpectedError('The quote should not exist');

        if SalesHeader.Get(SalesHeader."Document Type"::Quote, QuoteID[2]) then
            Assert.ExpectedError('The quote should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateQuoteThroughPageAndAPI()
    var
        PageSalesHeader: Record "Sales Header";
        ApiSalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        LibrarySales: Codeunit "Library - Sales";
        SalesQuote: TestPage "Sales Quote";
        ApiRecordRef: RecordRef;
        PageRecordRef: RecordRef;
        CustomerNo: Text;
        QuoteDate: Date;
        ResponseText: Text;
        TargetURL: Text;
        QuoteWithComplexJSON: Text;
        QuoteExists: Boolean;
    begin
        // [SCENARIO] Create a quote both through the client UI and through the API and compare them. They should be the same and have the same fields autocompleted wherever needed.
        Initialize;
        LibraryGraphDocumentTools.InitializeUIPage;

        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        QuoteDate := Today;

        // [GIVEN] a json describing our new quote
        QuoteWithComplexJSON := CreateQuoteJSONWithAddress(Customer, QuoteDate);
        Commit;

        // [WHEN] we POST the JSON to the web service and create another quote through the test page
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteWithComplexJSON, ResponseText);

        CreateQuoteThroughTestPage(SalesQuote, Customer, QuoteDate);

        // [THEN] the quote should exist in the table and match the quote created from the page
        QuoteExists := FindSalesHeader(ApiSalesHeader, CustomerNo, '');
        ApiSalesHeader.SetFilter("Document Date", '=%1', QuoteDate);
        Assert.IsTrue(QuoteExists, 'The quote should exist');

        // Ignore these fields when comparing Page and API Quotes
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Posting Description"), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo(Id), DATABASE::"Sales Header");

        // Time zone will impact how the date from the page vs WebService is saved. If removed this will fail in snap between 12:00 - 1 AM
        if Time < 020000T then begin
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Order Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Shipment Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Posting Date"), DATABASE::"Sales Header");
        end;

        PageSalesHeader.Get(PageSalesHeader."Document Type"::Quote, SalesQuote."No.".Value);
        ApiRecordRef.GetTable(ApiSalesHeader);
        PageRecordRef.GetTable(PageSalesHeader);
        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API quote do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuotesAppliesDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
    begin
        // [SCENARIO] When a quote is created, the GET Method should update the quote and assign a total
        // [GIVEN] a quote without totals assigned
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(SalesHeader, DiscountPct, SalesHeader."Document Type"::Quote);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate Invoice disc. should be set');
        Commit;

        // [WHEN] we GET the quote from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the quote should exist in the response and Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuotesRedistributesDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
        DiscountAmt: Decimal;
    begin
        // [SCENARIO] When a quote is created, the GET Method should update the quote and redistribute the discount amount
        // [GIVEN] a quote with discount amount that should be redistributed
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(SalesHeader, DiscountPct, SalesHeader."Document Type"::Quote);
        SalesHeader.CalcFields(Amount);
        DiscountAmt := LibraryRandom.RandDecInRange(1, Round(SalesHeader.Amount / 2, 1), 1);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmt, SalesHeader);
        GetFirstSalesQuoteLine(SalesHeader, SalesLine);
        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Commit;

        // [WHEN] we GET the quote from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the quote should exist in the response and Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountAmt, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuotesWithContactId()
    var
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        QuoteID: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Create a quote with a contact with graph ID (GET method should return Graph Contact ID)
        // [GIVEN] One Quote with contact ID
        Initialize;

        CreateSalesQuoteWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        QuoteID := SalesHeader.Id;

        // [WHEN] We get Quote from web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(QuoteID, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Quote should contain the Contact ID
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostQuotesWithGraphContactId()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        QuoteWithComplexJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        QuoteNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Posting a Quote with Graph Contact ID (POST method should find the customer based on Contact ID)
        // [GIVEN] One Quote with contact ID
        Initialize;
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        QuoteWithComplexJSON := CreateQuoteJSONWithContactId(GraphIntegrationRecord);

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        Commit;

        // [WHEN] We post a quote to web service
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteWithComplexJSON, ResponseText);

        // [THEN] The Quote should have a customer found based on contact ID
        VerifyValidPostRequest(ResponseText, QuoteNumber);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(Customer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(QuoteNumber, SalesHeader."Document Type"::Quote, Contact);
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
        QuoteID: Code[20];
        CustomerNo: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        QuoteWithComplexJSON: Text;
        QuoteNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO] Create a quote with a contact with graph ID (Selecting a different contact will change sell-to customer)
        // [GIVEN] One quote with contact ID
        Initialize;

        CreateSalesQuoteWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        QuoteID := SalesHeader.Id;
        CustomerNo := SalesHeader."Sell-to Customer No.";

        LibraryGraphDocumentTools.CreateContactWithGraphId(SecondContact, SecondGraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(SecondCustomer, SecondContact);

        // Creating the second contact will update the header due to the bug
        SalesHeader.Find;
        SalesHeader."Sell-to Customer No." := CustomerNo;
        SalesHeader.Modify;

        TargetURL := LibraryGraphMgt.CreateTargetURL(QuoteID, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        QuoteWithComplexJSON := CreateQuoteJSONWithContactId(SecondGraphIntegrationRecord);

        Commit;

        // [WHEN] We Patch to web service
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteWithComplexJSON, ResponseText);

        // [THEN] The Quote should have a new customer
        VerifyValidPostRequest(ResponseText, QuoteNumber);
        VerifyContactId(ResponseText, SecondGraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(SecondCustomer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(QuoteNumber, SalesHeader."Document Type"::Quote, SecondContact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyQuoteSetManualDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        InvoiceDiscountAmount: Decimal;
        TargetURL: Text;
        QuoteJSON: Text;
        ResponseText: Text;
        QuoteID: Text;
    begin
        // [SCENARIO 184721] Create Sales Quote, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] an line in the previously created quote
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.SetAutoCalcFields(Amount);
        SalesHeader.Find;
        QuoteID := SalesHeader."No.";
        InvoiceDiscountAmount := SalesHeader.Amount / 2;
        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        QuoteJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(InvoiceDiscountAmount, 0, 9));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteJSON, ResponseText);

        // [THEN] Header value was updated
        SalesHeader.Find;
        SalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(InvoiceDiscountAmount, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');

        // [THEN] Response contains the updated value
        VerifyValidPostRequest(ResponseText, QuoteID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, InvoiceDiscountAmount);
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
        QuoteJSON: Text;
        ResponseText: Text;
        QuoteID: Text;
    begin
        // [SCENARIO 184721] Clearing manually set discount
        Initialize;

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [Given] a customer
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] an line in the previously created quote
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        QuoteID := SalesHeader."No.";

        SalesHeader.SetAutoCalcFields(Amount);
        SalesHeader.Find;

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 2, SalesHeader);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Quote Entity", QuoteServiceNameTxt);
        QuoteJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(0, 0, 9));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteJSON, ResponseText);

        // [THEN] Header value was updated
        SalesHeader.Find;
        SalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');

        // [THEN] Discount should be removed
        VerifyValidPostRequest(ResponseText, QuoteID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, 0);
    end;

    local procedure CreateQuoteJSONWithAddress(Customer: Record Customer; DocumentDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        QuoteJSON: Text;
        ComplexTypeJSON: Text;
        QuoteWithComplexJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', Customer."No.");
        JSONManagement.AddJPropertyToJObject(JObject, 'documentDate', DocumentDate);
        QuoteJSON := JSONManagement.WriteObjectToString;

        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, false, false);
        QuoteWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(QuoteJSON, 'billingPostalAddress', ComplexTypeJSON);
        exit(QuoteWithComplexJSON);
    end;

    local procedure CreateQuoteThroughTestPage(var SalesQuote: TestPage "Sales Quote"; Customer: Record Customer; DocumentDate: Date)
    begin
        SalesQuote.OpenNew;
        SalesQuote."Sell-to Customer No.".SetValue(Customer."No.");
        SalesQuote."Document Date".SetValue(DocumentDate);
    end;

    local procedure GetFirstSalesQuoteLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
    end;

    local procedure CreateSalesQuoteWithGraphContactID(var SalesHeader: Record "Sales Header"; var GraphIntegrationRecord: Record "Graph Integration Record")
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
    end;

    local procedure CreateQuoteJSONWithContactId(GraphIntegrationRecord: Record "Graph Integration Record"): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        QuoteJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, GraphContactIdFieldTxt, GraphIntegrationRecord."Graph ID");
        QuoteJSON := JSONManagement.WriteObjectToString;

        exit(QuoteJSON);
    end;

    local procedure VerifyValidPostRequest(ResponseText: Text; var QuoteNumber: Text)
    begin
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', QuoteNumber),
          'Could not find sales quote number');
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

    local procedure VerifyContactId(ResponseText: Text; ExpectedContactId: Text)
    var
        contactId: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, GraphContactIdFieldTxt, contactId);
        Assert.AreEqual(ExpectedContactId, contactId, 'Wrong contact id was returned');
    end;

    local procedure CreateSalesQuoteWithLines(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(SalesHeader, Customer, Item, 1, 1);
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Text; QuoteNumber: Text): Boolean
    begin
        SalesHeader.Reset;
        if QuoteNumber <> '' then
            SalesHeader.SetRange("No.", QuoteNumber);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if CustomerNo <> '' then
            SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        exit(SalesHeader.FindFirst);
    end;
}

