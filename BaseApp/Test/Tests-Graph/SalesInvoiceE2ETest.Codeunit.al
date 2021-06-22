codeunit 135510 "Sales Invoice E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Invoice]
    end;

    var
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        NumberFieldTxt: Label 'number';
        InvoiceServiceNameTxt: Label 'salesInvoices';
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        GraphContactIdFieldTxt: Label 'contactId';
        CustomerIdFieldTxt: Label 'customerId';
        CustomerNameFieldTxt: Label 'customerName';
        CustomerNumberFieldTxt: Label 'customerNumber';
        LibraryERM: Codeunit "Library - ERM";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CurrencyIdFieldTxt: Label 'currencyId';
        PaymentTermsIdFieldTxt: Label 'paymentTermsId';
        ShipmentMethodIdFieldTxt: Label 'shipmentMethodId';
        BlankGUID: Guid;
        DiscountAmountFieldTxt: Label 'discountAmount';

    local procedure Initialize()
    begin
        WorkDate := Today;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInvoices()
    var
        InvoiceID1: Text;
        InvoiceID2: Text;
        InvoiceJSON1: Text;
        InvoiceJSON2: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 184721] Create posted and unposted Sales invoices and use a GET method to retrieve them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;
        CreateSalesInvoices(InvoiceID1, InvoiceID2);
        Commit;

        // [WHEN] we GET all the invoices from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 invoices should exist in the response
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'number', InvoiceID1, InvoiceID2, InvoiceJSON1, InvoiceJSON2),
          'Could not find the invoices in JSON');
        LibraryGraphMgt.VerifyIDInJson(InvoiceJSON1);
        LibraryGraphMgt.VerifyIDInJson(InvoiceJSON2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoices()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerNo: Text;
        InvoiceDate: Date;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceWithComplexJSON: Text;
    begin
        // [SCENARIO 184721] Create posted and unposted Sales invoices and use HTTP POST to delete them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        InvoiceDate := Today;

        InvoiceWithComplexJSON := CreateInvoiceJSONWithAddress(Customer, InvoiceDate);
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] the response text should have the correct Id, invoice address and the invoice should exist in the table with currency code set by default
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find sales invoice number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, false, false);

        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", InvoiceNumber);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Date", InvoiceDate);
        Assert.IsTrue(SalesHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual('', SalesHeader."Currency Code", 'The invoice should have the LCY currency code set by default');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CustomerNo: Text;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 184721] Create posted and unposted with specific currency set and use HTTP POST to create them
        Initialize;

        // [GIVEN] an Invoice with a non-LCY currencyCode set
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', CustomerNo);
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        JSONManagement.AddJPropertyToJObject(JObject, 'currencyCode', CurrencyCode);
        InvoiceJSON := JSONManagement.WriteObjectToString;
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] the response text should contain the invoice ID and the integration record table should map the SalesInvoiceId with the ID
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find sales invoice number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        // [THEN] the invoice should exist in the tables
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", InvoiceNumber);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual(CurrencyCode, SalesHeader."Currency Code", 'The invoice should have the correct currency code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithEmail()
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CustomerNo: Text;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        Email: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 285872] Create posted and unposted with specific email set and use HTTP POST to create them
        Initialize;
        Email := 'test@microsoft.com';
        // [GIVEN] an Customer with  no email set
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Mail" := '';
        CustomerNo := Customer."No.";

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', CustomerNo);
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        JSONManagement.AddJPropertyToJObject(JObject, 'currencyCode', CurrencyCode);
        JSONManagement.AddJPropertyToJObject(JObject, 'email', Email);

        InvoiceJSON := JSONManagement.WriteObjectToString;
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] the response text should contain the invoice ID and the integration record table should map the SalesInvoiceId with the ID
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find sales invoice number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        // [THEN] the invoice should exist in the tables
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", InvoiceNumber);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual(Email, SalesHeader."Sell-to E-Mail", 'The invoice should have the correct email');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDates()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        DueDate: Date;
        InvoiceDate: Date;
        CustomerNo: Text;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
    begin
        // [SCENARIO 184721] Create unposted with specific document and due date set and use HTTP POST to create them
        Initialize;

        // [GIVEN] an Invoice with a document and due date set
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON('', CustomerNumberFieldTxt, CustomerNo);

        InvoiceDate := WorkDate;
        DueDate := CalcDate('<1D>', InvoiceDate);
        InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceJSON, 'invoiceDate', Format(InvoiceDate, 0, 9));
        InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceJSON, 'dueDate', Format(DueDate, 0, 9));
        Commit;

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] the response text should contain the invoice ID and the integration record table should map the SalesInvoiceId with the ID
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find sales invoice number');

        // [THEN] the invoice should exist in the tables
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", InvoiceNumber);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual(InvoiceDate, SalesHeader."Document Date", 'The invoice should have the correct document date');
        Assert.AreEqual(DueDate, SalesHeader."Due Date", 'The invoice should have the correct due date');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoices()
    begin
        TestMultipleModifyInvoices(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyModifyInvoices()
    begin
        TestMultipleModifyInvoices(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPartialModifyInvoices()
    begin
        TestMultipleModifyInvoices(false, true);
    end;

    local procedure TestMultipleModifyInvoices(EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InvoiceIntegrationID: Text;
        InvoiceID: Text;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        InvoiceWithComplexJSON: Text;
        ComplexTypeJSON: Text;
    begin
        // [SCENARIO 184721] Create Sales Invoice, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] a Sales Person purchaser
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        InvoiceID := SalesHeader."No.";

        // [GIVEN] the invoice's unique ID
        SalesHeader.Reset;
        SalesHeader.SetRange("No.", InvoiceID);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst;
        InvoiceIntegrationID := SalesHeader.Id;
        Assert.AreNotEqual('', InvoiceIntegrationID, 'ID should not be empty');

        if EmptyData then
            InvoiceJSON := '{}'
        else begin
            InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceJSON, 'salesperson', SalespersonPurchaser.Code);
            InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceJSON, 'customerNumber', Customer."No.");
        end;

        // [GIVEN] a JSON text with an Item that has the BillingPostalAddress complex type
        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, EmptyData, PartiallyEmptyData);
        InvoiceWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(InvoiceJSON, 'billingPostalAddress', ComplexTypeJSON);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(InvoiceIntegrationID, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] the item should have the Unit of Measure as a value in the table
        SalesHeader.Reset;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", InvoiceID);
        Assert.IsTrue(SalesHeader.FindFirst, 'The unposted invoice should exist');
        if not EmptyData then
            Assert.AreEqual(SalesHeader."Salesperson Code", SalespersonPurchaser.Code, 'The patch of Sales Person code was unsuccessful');

        // [THEN] the response text should contain the invoice address
        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, EmptyData, PartiallyEmptyData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithBlankIdEmptiesTheCodeAndTheId()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        InvoiceID: Text;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceWithBlanksJSON: Text;
    begin
        // [SCENARIO 184721] Create Sales Invoice with all the Ids filled, use a PATCH method to blank the Ids and the Codes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] a currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] payment Terms
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // [GIVEN] a shipment Method
        CreateShipmentMethod(ShipmentMethod);

        // [GIVEN] an invoice with the previously created customer and extra values
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader."Payment Terms Code" := PaymentTerms.Code;
        SalesHeader."Shipment Method Code" := ShipmentMethod.Code;
        SalesHeader.Modify;
        InvoiceID := SalesHeader.Id;
        Commit;

        // [GIVEN] that the extra values are not empty
        SalesInvoiceEntityAggregate.Reset;
        SalesInvoiceEntityAggregate.SetRange(Id, InvoiceID);
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindFirst, 'The unposted invoice should exist');
        Assert.AreNotEqual(BlankGUID, SalesInvoiceEntityAggregate."Currency Id", 'The Id of the currency should not be blank.');
        Assert.AreNotEqual('', SalesInvoiceEntityAggregate."Currency Code", 'The code of the currency should be not blank.');
        Assert.AreNotEqual(BlankGUID, SalesInvoiceEntityAggregate."Payment Terms Id", 'The Id of the payment terms should not be blank.');
        Assert.AreNotEqual('', SalesInvoiceEntityAggregate."Payment Terms Code", 'The code of the payment terms should not be blank.');
        Assert.AreNotEqual(
          BlankGUID, SalesInvoiceEntityAggregate."Shipment Method Id", 'The Id of the shipment method should not be blank.');
        Assert.AreNotEqual('', SalesInvoiceEntityAggregate."Shipment Method Code", 'The code of the shipment method should not be blank.');

        // [GIVEN] a json with blank Ids on the extra values
        InvoiceWithBlanksJSON := LibraryGraphMgt.AddPropertytoJSON('', CurrencyIdFieldTxt, BlankGUID);
        InvoiceWithBlanksJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceWithBlanksJSON, PaymentTermsIdFieldTxt, BlankGUID);
        InvoiceWithBlanksJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceWithBlanksJSON, ShipmentMethodIdFieldTxt, BlankGUID);
        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(InvoiceID, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceWithBlanksJSON, ResponseText);

        // [THEN] the item should have the extra values blanked
        SalesInvoiceEntityAggregate.Reset;
        SalesInvoiceEntityAggregate.SetRange(Id, InvoiceID);
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual(BlankGUID, SalesInvoiceEntityAggregate."Currency Id", 'The Id of the currency should be blanked.');
        Assert.AreEqual('', SalesInvoiceEntityAggregate."Currency Code", 'The code of the currency should be blanked.');
        Assert.AreEqual(BlankGUID, SalesInvoiceEntityAggregate."Payment Terms Id", 'The Id of the payment terms should be blanked.');
        Assert.AreEqual('', SalesInvoiceEntityAggregate."Payment Terms Code", 'The code of the payment terms should be blanked.');
        Assert.AreEqual(BlankGUID, SalesInvoiceEntityAggregate."Shipment Method Id", 'The Id of the shipment method should be blanked.');
        Assert.AreEqual('', SalesInvoiceEntityAggregate."Shipment Method Code", 'The code of the shipment method should be blanked.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoiceNumberForDraftInvoice()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        NewInvoiceNumber: Text;
        NewInvoiceNumberJSON: Text;
    begin
        // [SCENARIO 184721] Create draft invoice and issue a patch request to change the number
        // [GIVEN] 1 draft invoice and a json with a new number
        Initialize;
        LibrarySales.CreateSalesInvoice(SalesHeader);
        NewInvoiceNumber := CopyStr(CreateGuid, 1, MaxStrLen(SalesHeader."No."));
        NewInvoiceNumberJSON := LibraryGraphMgt.AddPropertytoJSON('', NumberFieldTxt, NewInvoiceNumber);
        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the new number we should get an error
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, NewInvoiceNumberJSON, ResponseText);
        Assert.AreNotEqual(0, StrPos(GetLastErrorText, 'read-only'), 'The string "read-only" should exist in the error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InvoiceID1: Text;
        InvoiceID2: Text;
        ID1: Text;
        ID2: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 184721] Create posted and unposted Sales invoices and use HTTP DELETE to delete them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;
        CreateSalesInvoices(InvoiceID1, InvoiceID2);

        SalesInvoiceHeader.Get(InvoiceID1);
        ID1 := SalesInvoiceHeader."Draft Invoice SystemId";
        Assert.AreNotEqual('', ID1, 'ID should not be empty');

        SalesHeader.Reset;
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceID2);
        ID2 := SalesHeader.SystemId;
        Assert.AreNotEqual('', ID2, 'ID should not be empty');

        // [WHEN] we DELETE the item from the web service, with the item's unique ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID1, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID2, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the invoices shouldn't exist in the tables
        if SalesInvoiceHeader.Get(InvoiceID1) then
            Assert.ExpectedError('The posted invoice should not exist');

        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceID2) then
            Assert.ExpectedError('The unposted invoice should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateInvoiceThroughPageAndAPI()
    var
        PageSalesHeader: Record "Sales Header";
        ApiSalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        SalesInvoice: TestPage "Sales Invoice";
        ApiRecordRef: RecordRef;
        PageRecordRef: RecordRef;
        CustomerNo: Text;
        InvoiceDate: Date;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceWithComplexJSON: Text;
    begin
        // [SCENARIO 184721] Create an invoice both through the client UI and through the API
        // [SCENARIO] and compare them. They should be the same and have the same fields autocompleted wherever needed.
        // [GIVEN] An unposted invoice
        Initialize;
        LibraryGraphDocumentTools.InitializeUIPage;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        InvoiceDate := Today;

        // [GIVEN] a json describing our new invoice
        InvoiceWithComplexJSON := CreateInvoiceJSONWithAddress(Customer, InvoiceDate);
        Commit;

        // [WHEN] we POST the JSON to the web service and create another invoice through the test page
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        CreateInvoiceThroughTestPage(SalesInvoice, Customer, InvoiceDate);

        // [THEN] the invoice should exist in the table and match the invoice created from the page
        ApiSalesHeader.Reset;
        ApiSalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ApiSalesHeader.SetRange("Document Type", ApiSalesHeader."Document Type"::Invoice);
        ApiSalesHeader.SetRange("Document Date", InvoiceDate);
        Assert.IsTrue(ApiSalesHeader.FindFirst, 'The unposted invoice should exist');

        // Ignore these fields when comparing Page and API Invoices
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Posting Description"), DATABASE::"Sales Header");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo(Id), DATABASE::"Sales Header");

        // Time zone will impact how the date from the page vs WebService is saved. If removed this will fail in snap between 12:00 - 1 AM
        if Time < 020000T then begin
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Shipment Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Posting Date"), DATABASE::"Sales Header");
            LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesHeader.FieldNo("Order Date"), DATABASE::"Sales Header");
        end;

        PageSalesHeader.Get(PageSalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value);
        ApiRecordRef.GetTable(ApiSalesHeader);
        PageRecordRef.GetTable(PageSalesHeader);
        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API Invoice do not match');

        // tear down
        LibraryApplicationArea.EnableFoundationSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInvoicesAppliesDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
    begin
        // [SCENARIO 184721] When an invoice is created,the GET Method should update the invoice and assign a total
        // [GIVEN] 2 invoices, one posted and one unposted without totals assigned
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(
          SalesHeader, DiscountPct, SalesHeader."Document Type"::Invoice);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate invoice disc. should be set');

        Commit;

        // [WHEN] we GET all the invoices from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 1 invoice should exist in the response and Invoice Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
        VerifyGettingAgainKeepsETag(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInvoicesRedistributesDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
        DiscountAmt: Decimal;
    begin
        // [SCENARIO 184721] When an invoice is created, the GET Method should update the invoice and assign a total
        // [GIVEN] 2 invoices, one posted and one unposted with discount amount that should be redistributed
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(
          SalesHeader, DiscountPct, SalesHeader."Document Type"::Invoice);
        SalesHeader.CalcFields(Amount);
        DiscountAmt := LibraryRandom.RandDecInRange(1, Round(SalesHeader.Amount / 2, 1), 1);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmt, SalesHeader);
        GetFirstSalesInvoiceLine(SalesHeader, SalesLine);
        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate invoice disc. should be set');
        Commit;

        // [WHEN] we GET all the invoices from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the invoice should exist in the response and Invoice Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountAmt, SalesHeader."Invoice Discount Calculation"::Amount);
        VerifyGettingAgainKeepsETag(ResponseText, TargetURL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInvoicesWithContactId()
    var
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        InvoiceID: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO 184721] Create an invoice with a contact with graph ID (GET method should return Graph Contact ID)
        // [GIVEN] One invoice with contact ID
        Initialize;

        CreateSalesInvoiceWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        InvoiceID := SalesHeader.Id;

        // [WHEN] We get invoice from web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(InvoiceID, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The invoice should contain the Contact ID
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoicesWithGraphContactId()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        GraphIntegrationRecord: Record "Graph Integration Record";
        InvoiceWithComplexJSON: Text;
        TargetURL: Text;
        ResponseText: Text;
        InvoiceNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO 184721] Posting an invoice with Graph Contact ID (POST method should find the customer based on Contact ID)
        // [GIVEN] One invoice with contact ID
        Initialize;
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        InvoiceWithComplexJSON := CreateInvoiceJSONWithContactId(GraphIntegrationRecord);

        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        Commit;

        // [WHEN] We post an invoice to web service
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] The invoice should have a customer found based on contact ID
        VerifyValidPostRequest(ResponseText, InvoiceNumber);
        VerifyContactId(ResponseText, GraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(Customer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(InvoiceNumber, SalesHeader."Document Type"::Invoice, Contact);
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
        InvoiceID: Code[20];
        TargetURL: Text;
        ResponseText: Text;
        InvoiceWithComplexJSON: Text;
        InvoiceNumber: Text;
    begin
        // [FEATURE] [Contact] [ID]
        // [SCENARIO 184721] Create an invoice with a contact with graph ID (Selecting a different contact will change sell-to customer)
        // [GIVEN] One invoice with contact ID
        Initialize;

        CreateSalesInvoiceWithGraphContactID(SalesHeader, GraphIntegrationRecord);
        InvoiceID := SalesHeader.Id;

        LibraryGraphDocumentTools.CreateContactWithGraphId(SecondContact, SecondGraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(SecondCustomer, SecondContact);

        TargetURL := LibraryGraphMgt.CreateTargetURL(InvoiceID, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        InvoiceWithComplexJSON := CreateInvoiceJSONWithContactId(SecondGraphIntegrationRecord);

        Commit;

        // [WHEN] We Patch to web service
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] The invoice should have a new customer
        VerifyValidPostRequest(ResponseText, InvoiceNumber);
        VerifyContactId(ResponseText, SecondGraphIntegrationRecord."Graph ID");
        VerifyCustomerFields(SecondCustomer, ResponseText);
        VerifyContactFieldsUpdatedOnSalesHeader(InvoiceNumber, SalesHeader."Document Type"::Invoice, SecondContact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoDataIntegrationRecordIdsForInvoices()
    var
        IntegrationRecord: Record "Integration Record";
        SalesHeader: Record "Sales Header";
        BlankGuid: Guid;
    begin
        // [SCENARIO 184722] Integration record ids should be set correctly.
        // [GIVEN] We have demo data applied correctly
        SalesHeader.SetRange(Id, BlankGuid);
        Assert.IsFalse(SalesHeader.FindFirst, 'No sales headers should have null id');

        // [WHEN] We look through all sales headers.
        // [THEN] The integration record for the sales header should have the same record id.
        SalesHeader.Reset;
        if SalesHeader.Find('-') then begin
            repeat
                Assert.IsTrue(IntegrationRecord.Get(SalesHeader.Id), 'The SalesHeader id should exist in the integration record table');
                Assert.AreEqual(
                  IntegrationRecord."Record ID", SalesHeader.RecordId,
                  'The integration record for the SalesHeader should have the same record id as the SalesHeader.');
            until SalesHeader.Next <= 0
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceFailsWithoutCustomerNoOrId()
    var
        Currency: Record Currency;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 184721] Create an invoice wihtout Customer throws an error
        Initialize;

        // [GIVEN] a sales invoice JSON with currency only
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON('', 'currencyCode', CurrencyCode);
        Commit;

        // [WHEN] we POST the JSON to the web service
        // [THEN] an error is received
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoiceSetManualDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        InvoiceDiscountAmount: Decimal;
        TargetURL: Text;
        InvoiceJSON: Text;
        ResponseText: Text;
        InvoiceID: Text;
    begin
        // [SCENARIO 184721] Create Sales Invoice, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount);
        InvoiceID := SalesHeader."No.";
        InvoiceDiscountAmount := SalesHeader.Amount / 2;
        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        InvoiceJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(InvoiceDiscountAmount, 0, 9));
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] Response contains the updated value
        VerifyValidPostRequest(ResponseText, InvoiceID);
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
        InvoiceJSON: Text;
        ResponseText: Text;
        InvoiceID: Text;
    begin
        // [SCENARIO 184721] Clearing manually set discount
        Initialize;

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [Given] a customer
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.Find;
        InvoiceID := SalesHeader."No.";
        SalesHeader.CalcFields(Amount);

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 2, SalesHeader);

        Commit;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.Id, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt);
        InvoiceJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(0, 0, 9));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] Discount should be removed
        VerifyValidPostRequest(ResponseText, InvoiceID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, 0);

        // [THEN] Header value was updated
        SalesHeader.SetAutoCalcFields("Invoice Discount Amount");
        SalesHeader.Find;
        Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');
    end;

    local procedure CreateSalesInvoices(var InvoiceID1: Text; var InvoiceID2: Text)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.SetAllowDocumentDeletionBeforeDate(WorkDate + 1);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate);
        InvoiceID1 := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        LibrarySales.CreateSalesInvoice(SalesHeader);
        ModifySalesHeaderPostingDate(SalesHeader, WorkDate);
        InvoiceID2 := SalesHeader."No.";
        Commit;
    end;

    local procedure CreateInvoiceJSONWithAddress(Customer: Record Customer; InvoiceDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        InvoiceJSON: Text;
        ComplexTypeJSON: Text;
        InvoiceWithComplexJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', Customer."No.");
        JSONManagement.AddJPropertyToJObject(JObject, 'invoiceDate', InvoiceDate);
        InvoiceJSON := JSONManagement.WriteObjectToString;

        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, false, false);
        InvoiceWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(InvoiceJSON, 'billingPostalAddress', ComplexTypeJSON);
        exit(InvoiceWithComplexJSON);
    end;

    local procedure CreateInvoiceThroughTestPage(var SalesInvoice: TestPage "Sales Invoice"; Customer: Record Customer; InvoiceDate: Date)
    begin
        SalesInvoice.OpenNew;
        SalesInvoice."Sell-to Customer No.".SetValue(Customer."No.");
        SalesInvoice."Document Date".SetValue(InvoiceDate);
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        with ShipmentMethod do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Shipment Method");
            Description := Code;
            Insert(true);
        end;
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

    local procedure GetFirstSalesInvoiceLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
    end;

    local procedure CreateSalesInvoiceWithGraphContactID(var SalesHeader: Record "Sales Header"; var GraphIntegrationRecord: Record "Graph Integration Record")
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        LibraryGraphDocumentTools.CreateContactWithGraphId(Contact, GraphIntegrationRecord);
        LibraryGraphDocumentTools.CreateCustomerFromContact(Customer, Contact);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
    end;

    local procedure CreateInvoiceJSONWithContactId(GraphIntegrationRecord: Record "Graph Integration Record"): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        InvoiceJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, GraphContactIdFieldTxt, GraphIntegrationRecord."Graph ID");
        InvoiceJSON := JSONManagement.WriteObjectToString;

        exit(InvoiceJSON);
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

    local procedure VerifyValidPostRequest(ResponseText: Text; var InvoiceNumber: Text)
    begin
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find sales invoice number');
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
}

