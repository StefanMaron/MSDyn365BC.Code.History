codeunit 135513 "Sales Order E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Order]
    end;

    var
        OrderServiceNameTxt: Label 'salesOrders';
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
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
    procedure TestGetOrders()
    var
        SalesHeader: Record "Sales Header";
        OrderID: array[2] of Text;
        OrderJSON: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 184721] Create Sales Orders and use a GET method to retrieve them
        // [GIVEN] 2 orders in the table
        Initialize;
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderID[1] := SalesHeader."No.";

        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderID[2] := SalesHeader."No.";
        Commit();

        // [WHEN] we GET all the orders from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 orders should exist in the response
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'number', OrderID[1], OrderID[2], OrderJSON[1], OrderJSON[2]),
          'Could not find the orders in JSON');
        LibraryGraphMgt.VerifyIDInJson(OrderJSON[1]);
        LibraryGraphMgt.VerifyIDInJson(OrderJSON[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOrders()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerNo: Text;
        OrderDate: Date;
        ResponseText: Text;
        OrderNumber: Text;
        TargetURL: Text;
        OrderWithComplexJSON: Text;
    begin
        // [SCENARIO 184721] Create sales orders JSON and use HTTP POST to create them
        Initialize;

        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        OrderDate := Today;

        // [GIVEN] a JSON text with an order that contains the customer and an adress as complex type
        OrderWithComplexJSON := CreateOrderJSONWithAddress(Customer, OrderDate);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderWithComplexJSON, ResponseText);

        // [THEN] the response text should have the correct Id, order address and the order should exist in the table with currency code set by default
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', OrderNumber), 'Could not find sales order number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, false, false);

        SalesHeader.Reset();
        SalesHeader.SetRange("No.", OrderNumber);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Date", OrderDate);
        Assert.IsTrue(SalesHeader.FindFirst, 'The order should exist');
        Assert.AreEqual('', SalesHeader."Currency Code", 'The order should have the LCY currency code set by default');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOrderWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        CustomerNo: Text;
        ResponseText: Text;
        OrderNumber: Text;
        TargetURL: Text;
        OrderJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 184721] Create sales order with specific currency set and use HTTP POST to create it
        Initialize;

        // [GIVEN] an order with a non-LCY currencyCode set
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', CustomerNo);
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        JSONManagement.AddJPropertyToJObject(JObject, 'currencyCode', CurrencyCode);
        OrderJSON := JSONManagement.WriteObjectToString;
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderJSON, ResponseText);

        // [THEN] the response text should contain the correct Id and the order should be created
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', OrderNumber),
          'Could not find the sales order number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        SalesHeader.Reset();
        SalesHeader.SetRange("No.", OrderNumber);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.FindFirst, 'The order should exist');
        Assert.AreEqual(CurrencyCode, SalesHeader."Currency Code", 'The order should have the correct currency code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOrders()
    begin
        TestMultipleModifyOrders(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyModifyOrders()
    begin
        TestMultipleModifyOrders(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPartialModifyOrders()
    begin
        TestMultipleModifyOrders(false, true);
    end;

    local procedure TestMultipleModifyOrders(EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        OrderIntegrationID: Text;
        OrderID: Text;
        ResponseText: Text;
        TargetURL: Text;
        OrderJSON: Text;
        OrderWithComplexJSON: Text;
        ComplexTypeJSON: Text;
    begin
        // [SCENARIO 184721] Create sales order, use a PATCH method to change it and then verify the changes
        // [GIVEN] a customer with address
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] a SalesPerson
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        OrderID := SalesHeader."No.";

        // [GIVEN] the order's unique ID
        SalesHeader.Reset();
        SalesHeader.SetRange("No.", OrderID);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst;
        OrderIntegrationID := SalesHeader.SystemId;
        Assert.AreNotEqual('', OrderIntegrationID, 'ID should not be empty');

        if EmptyData then
            OrderJSON := '{}'
        else begin
            OrderJSON := LibraryGraphMgt.AddPropertytoJSON(OrderJSON, 'salesperson', SalespersonPurchaser.Code);
            OrderJSON := LibraryGraphMgt.AddPropertytoJSON(OrderJSON, 'customerNumber', Customer."No.");
        end;

        // [GIVEN] a JSON text with an order that has the BillingPostalAddress complex type
        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, EmptyData, PartiallyEmptyData);
        OrderWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(OrderJSON, 'billingPostalAddress', ComplexTypeJSON);

        Commit();

        // [WHEN] we PATCH the JSON to the web service, with the unique order ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(OrderIntegrationID, PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderWithComplexJSON, ResponseText);

        // [THEN] the order should have the Unit of Measure and address as a value in the table
        SalesHeader.Reset();
        SalesHeader.SetRange("No.", OrderID);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        Assert.IsTrue(SalesHeader.FindFirst, 'The sales order should exist in the table');
        if not EmptyData then
            Assert.AreEqual(SalesHeader."Salesperson Code", SalespersonPurchaser.Code, 'The patch of Sales Person code was unsuccessful');

        LibraryGraphDocumentTools.VerifyCustomerBillingAddress(Customer, SalesHeader, ResponseText, EmptyData, PartiallyEmptyData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteOrders()
    var
        SalesHeader: Record "Sales Header";
        OrderID: array[2] of Text;
        ID: array[2] of Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 184721] Create sales orders and use HTTP DELETE to delete them
        // [GIVEN] 2 orders in the table
        Initialize;
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderID[1] := SalesHeader."No.";
        ID[1] := SalesHeader.SystemId;
        Assert.AreNotEqual('', ID[1], 'ID should not be empty');

        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderID[2] := SalesHeader."No.";
        ID[2] := SalesHeader.SystemId;
        Assert.AreNotEqual('', ID[2], 'ID should not be empty');
        Commit();

        // [WHEN] we DELETE the orders from the web service, with the orders' unique IDs
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID[1], PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID[2], PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the orders shouldn't exist in the table
        if SalesHeader.Get(SalesHeader."Document Type"::Order, OrderID[1]) then
            Assert.ExpectedError('The order should not exist');

        if SalesHeader.Get(SalesHeader."Document Type"::Order, OrderID[2]) then
            Assert.ExpectedError('The order should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateOrderThroughPageAndAPI()
    var
        PageSalesHeader: Record "Sales Header";
        ApiSalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        LibrarySales: Codeunit "Library - Sales";
        SalesOrder: TestPage "Sales Order";
        ApiRecordRef: RecordRef;
        PageRecordRef: RecordRef;
        CustomerNo: Text;
        OrderDate: Date;
        ResponseText: Text;
        TargetURL: Text;
        OrderWithComplexJSON: Text;
    begin
        // [SCENARIO 184721] Create an order both through the client UI and through the API and compare them. They should be the same and have the same fields autocompleted wherever needed.
        Initialize;
        LibraryGraphDocumentTools.InitializeUIPage;

        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        OrderDate := Today;

        // [GIVEN] a json describing our new order
        OrderWithComplexJSON := CreateOrderJSONWithAddress(Customer, OrderDate);
        Commit();

        // [WHEN] we POST the JSON to the web service and create another order through the test page
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderWithComplexJSON, ResponseText);

        CreateOrderThroughTestPage(SalesOrder, Customer, OrderDate);

        // [THEN] the order should exist in the table and match the order created from the page
        ApiSalesHeader.Reset();
        ApiSalesHeader.SetRange("Document Type", ApiSalesHeader."Document Type"::Order);
        ApiSalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ApiSalesHeader.SetRange("Document Date", OrderDate);
        Assert.IsTrue(ApiSalesHeader.FindFirst, 'The order should exist');

        // Ignore these fields when comparing Page and API Orders
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

        PageSalesHeader.Get(PageSalesHeader."Document Type"::Order, SalesOrder."No.".Value);
        ApiRecordRef.GetTable(ApiSalesHeader);
        PageRecordRef.GetTable(PageSalesHeader);
        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API order do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOrdersAppliesDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
    begin
        // [SCENARIO 184721] When an order is created, the GET Method should update the order and assign a total
        // [GIVEN] an order without totals assigned
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(SalesHeader, DiscountPct, SalesHeader."Document Type"::Order);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Assert.IsTrue(SalesHeader."Recalculate Invoice Disc.", 'Setup error - recalculate Invoice disc. should be set');
        Commit();

        // [WHEN] we GET the order from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the order should exist in the response and Order Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOrdersRedistributesDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ResponseText: Text;
        TargetURL: Text;
        DiscountPct: Decimal;
        DiscountAmt: Decimal;
    begin
        // [SCENARIO 184721] When an order is created, the GET Method should update the order and redistribute the discount amount
        // [GIVEN] an order with discount amount that should be redistributed
        Initialize;
        LibraryGraphDocumentTools.CreateDocumentWithDiscountPctPending(SalesHeader, DiscountPct, SalesHeader."Document Type"::Order);
        SalesHeader.CalcFields(Amount);
        DiscountAmt := LibraryRandom.RandDecInRange(1, Round(SalesHeader.Amount / 2, 1), 1);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmt, SalesHeader);
        GetFirstSalesOrderLine(SalesHeader, SalesLine);
        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        Commit();

        // [WHEN] we GET the order from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Order Entity", OrderServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the order should exist in the response and Order Discount Should be Applied
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
        LibraryGraphDocumentTools.VerifySalesTotals(
          SalesHeader, ResponseText, DiscountAmt, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOrderSetManualDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        InvoiceDiscountAmount: Decimal;
        TargetURL: Text;
        OrderJSON: Text;
        ResponseText: Text;
        OrderID: Text;
    begin
        // [SCENARIO 184721] Create Sales Order, use a PATCH method to change it and then verify the changes
        Initialize;
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        OrderID := SalesHeader."No.";

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.SetAutoCalcFields(Amount);
        SalesHeader.Find;
        InvoiceDiscountAmount := SalesHeader.Amount / 2;

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Order Entity", OrderServiceNameTxt);
        OrderJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(InvoiceDiscountAmount, 0, 9));
        Commit();

        LibraryGraphMgt.PatchToWebService(TargetURL, OrderJSON, ResponseText);

        // [THEN] Response contains the updated value
        VerifyValidPostRequest(ResponseText, OrderID);
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
        OrderJSON: Text;
        ResponseText: Text;
        OrderID: Text;
    begin
        // [SCENARIO 184721] Clearing manually set discount
        Initialize;

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [Given] a customer
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] an order with the previously created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        OrderID := SalesHeader."No.";

        // [GIVEN] an line in the previously created order
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 2, SalesHeader);

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        OrderJSON := StrSubstNo('{"%1": %2}', DiscountAmountFieldTxt, Format(0, 0, 9));
        TargetURL := LibraryGraphMgt.CreateTargetURL(SalesHeader.SystemId, PAGE::"Sales Order Entity", OrderServiceNameTxt);
        Commit();

        LibraryGraphMgt.PatchToWebService(TargetURL, OrderJSON, ResponseText);

        // [THEN] Discount should be removed
        VerifyValidPostRequest(ResponseText, OrderID);
        LibraryGraphDocumentTools.VerifyValidDiscountAmount(ResponseText, 0);

        // [THEN] Header value was updated
        SalesHeader.Find;
        SalesHeader.CalcFields("Invoice Discount Amount");
        Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Invoice discount Amount was not set');
    end;

    local procedure CreateOrderJSONWithAddress(Customer: Record Customer; OrderDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        OrderJSON: Text;
        ComplexTypeJSON: Text;
        OrderWithComplexJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, 'customerNumber', Customer."No.");
        JSONManagement.AddJPropertyToJObject(JObject, 'orderDate', OrderDate);
        OrderJSON := JSONManagement.WriteObjectToString;

        LibraryGraphDocumentTools.GetCustomerAddressComplexType(ComplexTypeJSON, Customer, false, false);
        OrderWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(OrderJSON, 'billingPostalAddress', ComplexTypeJSON);
        exit(OrderWithComplexJSON);
    end;

    local procedure CreateOrderThroughTestPage(var SalesOrder: TestPage "Sales Order"; Customer: Record Customer; DocumentDate: Date)
    begin
        SalesOrder.OpenNew;
        SalesOrder."Sell-to Customer No.".SetValue(Customer."No.");
        SalesOrder."Document Date".SetValue(DocumentDate);
    end;

    local procedure GetFirstSalesOrderLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
    end;

    local procedure VerifyValidPostRequest(ResponseText: Text; var OrderNumber: Text)
    begin
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', OrderNumber),
          'Could not find sales Order number');
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
          IntegrationManagement.GetIdWithoutBrackets(ExpectedCustomer.SystemId), UpperCase(customerIdValue), 'Wrong setting for Customer Id');
        Assert.AreEqual(ExpectedCustomer."No.", customerNumberValue, 'Wrong setting for Customer Number');
        Assert.AreEqual(ExpectedCustomer.Name, customerNameValue, 'Wrong setting for Customer Name');
    end;
}

