codeunit 135514 "Sales Order Line E2E Test"
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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        OrderServiceLinesNameTxt: Label 'salesOrderLines';
        LineTypeFieldNameTxt: Label 'lineType';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sales Order Line E2E Test");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sales Order Line E2E Test");

        LibrarySales.SetStockoutWarning(false);
        LibraryApplicationArea.EnableFoundationSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sales Order Line E2E Test");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFailsOnIDAbsense()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Call GET on the lines without providing a parent order ID.
        // [GIVEN] the order API exposed
        Initialize();

        // [WHEN] we GET all the lines without an ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage('',
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response text should be empty
        Assert.AreEqual('', ResponseText, 'Response JSON should be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetOrderLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        OrderId: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a  order
        // [GIVEN] An order with lines.
        Initialize();
        OrderId := CreateSalesOrderWithLines(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.FindFirst;
        LineNo1 := Format(SalesLine."Line No.");
        SalesLine.FindLast;
        LineNo2 := Format(SalesLine."Line No.");

        // [WHEN] we GET all the lines with the  order ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the lines returned should be valid (numbers and integration ids)
        VerifyOrderLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOrderLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        OrderLineJSON: Text;
        LineNoFromJSON: Text;
        OrderId: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] POST a new line to an  order
        // [GIVEN] An existing  order and a valid JSON describing the new order line
        Initialize();
        OrderId := CreateSalesOrderWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] the response text should contain the order ID and the change should exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesLine.FindFirst, 'The order line should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyOrderLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        OrderLineJSON: Text;
        LineNo: Integer;
        OrderLineId: Text;
        SalesQuantity: Integer;
    begin
        // [SCENARIO] PATCH a line of an  order
        // [GIVEN] An  order with lines and a valid JSON describing the fields that we want to change
        Initialize();
        OrderLineId := CreateSalesOrderWithLines(SalesHeader);
        Assert.AreNotEqual('', OrderLineId, 'ID should not be empty');
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        SalesQuantity := 4;
        OrderLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderLineId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(OrderLineId, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] the line should be changed in the table and the response JSON text should contain our changed field
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');

        SalesLine.Reset();
        SalesLine.SetRange("Line No.", LineNo);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        Assert.IsTrue(SalesLine.FindFirst, 'The  order line should exist after modification');
        Assert.AreEqual(SalesLine.Quantity, SalesQuantity, 'The patch of Sales line quantity was unsuccessful');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        OrderId: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] DELETE a line from an  order
        // [GIVEN] An  order with lines
        Initialize();
        OrderId := CreateSalesOrderWithLines(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        Commit();

        // [WHEN] we DELETE the first line of that order
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(OrderId, LineNo));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the line should no longer exist in the database
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsFalse(SalesLine.FindFirst, 'The order line should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateLineThroughPageAndAPI()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PageSalesLine: Record "Sales Line";
        ApiSalesLine: Record "Sales Line";
        Customer: Record Customer;
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        SalesOrder: TestPage "Sales Order";
        PageRecordRef: RecordRef;
        ApiRecordRef: RecordRef;
        ResponseText: Text;
        TargetURL: Text;
        OrderLineJSON: Text;
        LineNoFromJSON: Text;
        OrderId: Text;
        LineNo: Integer;
        ItemQuantity: Integer;
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Create an order both through the client UI and through the API and compare their final values.
        // [GIVEN] An  order and a JSON describing the line we want to create
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        ItemNo := LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        OrderId := SalesHeader.SystemId;
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, ItemQuantity);
        Commit();

        // [WHEN] we POST the JSON to the web service and when we create an order through the client UI
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] the response text should be valid, the order line should exist in the tables and the two Orders have the same field values.
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        ApiSalesLine.SetRange("Document No.", SalesHeader."No.");
        ApiSalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        ApiSalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(ApiSalesLine.FindFirst, 'The  order line should exist');

        CreateOrderAndLinesThroughPage(SalesOrder, CustomerNo, ItemNo, ItemQuantity);
        PageSalesLine.SetRange("Document No.", SalesOrder."No.".Value);
        PageSalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        Assert.IsTrue(PageSalesLine.FindFirst, 'The  order line should exist');

        ApiRecordRef.GetTable(ApiSalesLine);
        PageRecordRef.GetTable(PageSalesLine);

        // Ignore these fields when comparing Page and API Orders
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Line No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo(Subtype), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Recalculate Invoice Disc."), DATABASE::"Sales Line"); // TODO: remove once other changes are checked in

        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API order lines do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineUpdatesOrderDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        TargetURL: Text;
        OrderLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Creating a line through API should update Discount Pct
        // [GIVEN] An  order for customer with order discount pct
        Initialize();
        CreateOrderWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] order discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesOrderDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TargetURL: Text;
        OrderLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should update Discount Pct
        // [GIVEN] An  order for customer with order discount pct
        Initialize();
        CreateOrderWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesQuantity := SalesLine.Quantity * 2;

        Commit();

        OrderLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] order discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineMovesOrderDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TargetURL: Text;
        ResponseText: Text;
        MinAmount1: Decimal;
        DiscountPct1: Decimal;
        MinAmount2: Decimal;
        DiscountPct2: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An  order for customer with order discount pct
        Initialize();
        CreateOrderWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        FindFirstSalesLine(SalesHeader, SalesLine);

        MinAmount1 := SalesHeader.Amount - 2 * SalesLine."Line Amount";
        DiscountPct1 := LibraryRandom.RandDecInDecimalRange(1, 20, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct1, MinAmount1, SalesHeader."Currency Code");

        MinAmount2 := SalesHeader.Amount - SalesLine."Line Amount" / 2;
        DiscountPct2 := LibraryRandom.RandDecInDecimalRange(30, 50, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct2, MinAmount2, SalesHeader."Currency Code");

        CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);
        SalesHeader.Find;
        Assert.AreEqual(SalesHeader."Invoice Discount Value", DiscountPct2, 'Discount Pct was not assigned');
        Commit();

        // [WHEN] we DELETE the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower order discount is applied
        VerifyTotals(SalesHeader, DiscountPct1, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineRemovesOrderDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TargetURL: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An  order for customer with order discount pct
        Initialize();
        CreateOrderWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        FindFirstSalesLine(SalesHeader, SalesLine);

        MinAmount := SalesHeader.Amount - SalesLine."Line Amount" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(30, 50, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");

        CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);
        SalesHeader.Find;
        Assert.AreEqual(SalesHeader."Invoice Discount Value", DiscountPct, 'Discount Pct was not assigned');
        Commit();

        // [WHEN] we DELETE the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower order discount is applied
        VerifyTotals(SalesHeader, 0, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineKeepsOrderDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Adding an order through API will keep Discount Amount
        // [GIVEN] An  order for customer with order discount amount
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Discount Amount is Kept
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineKeepsOrderDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        TargetURL: Text;
        OrderLineJSON: Text;
        ResponseText: Text;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should keep existing Discount Amount
        // [GIVEN] An  order for customer with order discount amt
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        OrderLineJSON := CreateOrderLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        SalesQuantity := 0;
        OrderLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] order discount is kept
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineKeepsOrderDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An  order for customer with order discount pct
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we DELETE the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower order discount is applied
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGettingLinesWithDifferentTypes()
    var
        SalesHeader: Record "Sales Header";
        JSONManagement: Codeunit "JSON Management";
        LinesJSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ExpectedNumberOfLines: Integer;
        TargetURL: Text;
        ResponseText: Text;
        LinesJSON: Text;
    begin
        // [SCENARIO] Getting a line through API lists all possible types
        // [GIVEN] An invoice with lines of different types
        Initialize();
        CreateOrderWithAllPossibleLineTypes(SalesHeader, ExpectedNumberOfLines);

        Commit();

        // [WHEN] we GET the lines
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] All lines are shown in the response
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'value', LinesJSON);
        LinesJSONManagement.InitializeCollection(LinesJSON);

        Assert.AreEqual(ExpectedNumberOfLines, LinesJSONManagement.GetCollectionCount, 'Four lines should be returned');
        VerifySalesOrderLinesForSalesHeader(SalesHeader, LinesJSONManagement);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingBlankLineDefaultsToItemType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
    begin
        // [SCENARIO] Posting a line with description only will get a type item
        // [GIVEN] A post request with description only
        Initialize();
        CreateSalesOrderWithLines(SalesHeader);

        Commit();

        OrderLineJSON := '{"description":"test"}';

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Line of type Item is created
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesLine.FindLast;
        Assert.AreEqual('', SalesLine."No.", 'No should be blank');
        Assert.AreEqual(SalesLine.Type, SalesLine.Type::Item, 'Wrong type is set');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingCommentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
    begin
        // [FEATURE] [Comment]
        // [SCENARIO] Posting a line with Type Comment and description will make a comment line
        // [GIVEN] A post request with type and description
        Initialize();
        CreateSalesOrderWithLines(SalesHeader);

        OrderLineJSON := '{"' + LineTypeFieldNameTxt + '":"Comment","description":"test"}';

        Commit();

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            OrderServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Line of type Item is created
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesLine.FindLast;
        Assert.AreEqual(SalesLine.Type, SalesLine.Type::" ", 'Wrong type is set');
        Assert.AreEqual('test', SalesLine.Description, 'Wrong description is set');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        LibraryGraphDocumentTools.VerifySalesObjectDescription(SalesLine, JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchingTheIdToAccountChangesLineType()
    var
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        IntegrationManagement: Codeunit "Integration Management";
        JsonObject: DotNet JObject;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
        OrderLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Order
        // [GIVEN] An unposted Order with lines and a valid JSON describing the fields that we want to change
        Initialize();
        OrderLineID := CreateSalesOrderWithLines(SalesHeader);
        Assert.AreNotEqual('', OrderLineID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.FindFirst;

        OrderLineJSON := StrSubstNo('{"accountId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(GLAccount.SystemId));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderLineID,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(OrderLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Line type is changed to Account
        FindFirstSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(SalesLine.Type::"G/L Account", SalesLine.Type, 'Type was not changed');
        Assert.AreEqual(GLAccount."No.", SalesLine."No.", 'G/L Account No was not set');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifySalesLineResponseWithSalesLine(SalesLine, JsonObject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchingTheIdToItemChangesLineType()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        IntegrationManagement: Codeunit "Integration Management";
        JsonObject: DotNet JObject;
        ExpectedNumberOfLines: Integer;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
        OrderLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Order
        // [GIVEN] An unposted Order with lines and a valid JSON describing the fields that we want to change
        Initialize();
        CreateOrderWithAllPossibleLineTypes(SalesHeader, ExpectedNumberOfLines);
        OrderLineID := IntegrationManagement.GetIdWithoutBrackets(SalesHeader.SystemId);
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
        SalesLine.SetRange(Type);

        Assert.AreNotEqual('', OrderLineID, 'ID should not be empty');
        LineNo := SalesLine."Line No.";
        LibraryInventory.CreateItem(Item);

        OrderLineJSON := StrSubstNo('{"itemId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(Item.SystemId));
        Commit();

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Line type is changed to Item and other fields are updated
        SalesLine.Find;
        Assert.AreEqual(SalesLine.Type::Item, SalesLine.Type, 'Type was not changed');
        Assert.AreEqual(Item."No.", SalesLine."No.", 'Item No was not set');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifySalesLineResponseWithSalesLine(SalesLine, JsonObject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchingTheTypeBlanksIds()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        TargetURL: Text;
        ResponseText: Text;
        OrderLineJSON: Text;
        OrderLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Order
        // [GIVEN] An unposted Order with lines and a valid JSON describing the fields that we want to change
        Initialize();
        OrderLineID := CreateSalesOrderWithLines(SalesHeader);
        Assert.AreNotEqual('', OrderLineID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        OrderLineJSON := StrSubstNo('{"%1":"%2"}', LineTypeFieldNameTxt, Format(SalesInvoiceLineAggregate."API Type"::Account));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            OrderLineID,
            PAGE::"Sales Order Entity",
            OrderServiceNameTxt,
            GetLineSubURL(OrderLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, OrderLineJSON, ResponseText);

        // [THEN] Line type is changed to Account
        FindFirstSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(SalesLine.Type::"G/L Account", SalesLine.Type, 'Type was not changed');
        Assert.AreEqual('', SalesLine."No.", 'No should be blank');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    local procedure CreateOrderWithAllPossibleLineTypes(var SalesHeader: Record "Sales Header"; var ExpectedNumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
    begin
        CreateSalesOrderWithLines(SalesHeader);

        LibraryGraphDocumentTools.CreateSalesLinesWithAllPossibleTypes(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        ExpectedNumberOfLines := SalesLine.Count();
    end;

    local procedure CreateSalesOrderWithLines(var SalesHeader: Record "Sales Header"): Text
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        Commit();
        exit(SalesHeader.SystemId);
    end;

    [Normal]
    local procedure CreateOrderLineJSON(ItemId: Guid; Quantity: Integer): Text
    var
        JSONManagement: Codeunit "JSON Management";
        IntegrationManagement: Codeunit "Integration Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'itemId', IntegrationManagement.GetIdWithoutBrackets(ItemId));
        JSONManagement.AddJObjectToJObject(JsonObject, 'quantity', Quantity);

        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure CreateOrderAndLinesThroughPage(var SalesOrder: TestPage "Sales Order"; CustomerNo: Text; ItemNo: Text; ItemQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesOrder.OpenNew;
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);

        SalesOrder.SalesLines.Last;
        SalesOrder.SalesLines.Next;
        SalesOrder.SalesLines.FilteredTypeField.SETVALUE(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(ItemNo);

        SalesOrder.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesOrder.SalesLines.Next;
        SalesOrder.SalesLines.Previous();
    end;

    local procedure GetLineSubURL(OrderId: Text; LineNo: Integer): Text
    begin
        exit(OrderServiceLinesNameTxt +
          '(documentId=' + LibraryGraphMgt.StripBrackets(OrderId) + ',sequence=' + Format(LineNo) + ')');
    end;

    local procedure VerifyOrderLines(ResponseText: Text; LineNo1: Text; LineNo2: Text)
    var
        LineJSON1: Text;
        LineJSON2: Text;
        ItemId1: Text;
        ItemId2: Text;
    begin
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'sequence', LineNo1, LineNo2, LineJSON1, LineJSON2),
          'Could not find the order lines in JSON');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON1, 'documentId');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON2, 'documentId');
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON1, 'itemId', ItemId1);
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON2, 'itemId', ItemId2);
        Assert.AreNotEqual(ItemId1, ItemId2, 'Item Ids should be different for different items');
    end;

    local procedure VerifySalesOrderLinesForSalesHeader(var SalesHeader: Record "Sales Header"; var JSONManagement: Codeunit "JSON Management")
    var
        SalesLine: Record "Sales Line";
        JObject: DotNet JObject;
        CurrentIndex: Integer;
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet;
        CurrentIndex := 0;

        repeat
            Assert.IsTrue(
              JSONManagement.GetJObjectFromCollectionByIndex(JObject, CurrentIndex),
              StrSubstNo('Could not find line %1.', SalesLine."Line No."));
            VerifySalesLineResponseWithSalesLine(SalesLine, JObject);
            CurrentIndex += 1;
        until SalesLine.Next = 0;
    end;

    local procedure VerifySalesLineResponseWithSalesLine(var SalesLine: Record "Sales Line"; var JObject: DotNet JObject)
    begin
        LibraryGraphDocumentTools.VerifySalesObjectDescription(SalesLine, JObject);
        LibraryGraphDocumentTools.VerifySalesIdsSet(SalesLine, JObject);
    end;

    local procedure VerifyIdsAreBlank(var JObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
        IntegrationManagement: Codeunit "Integration Management";
        itemId: Text;
        accountId: Text;
        ExpectedId: Text;
        BlankGuid: Guid;
    begin
        JSONManagement.InitializeObjectFromJObject(JObject);

        ExpectedId := IntegrationManagement.GetIdWithoutBrackets(BlankGuid);

        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'itemId', itemId), 'Could not find itemId');
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'accountId', accountId), 'Could not find accountId');

        Assert.AreEqual(UpperCase(ExpectedId), UpperCase(accountId), 'Account id should be blank');
        Assert.AreEqual(UpperCase(ExpectedId), UpperCase(itemId), 'Item id should be blank');
    end;

    local procedure CreateOrderWithTwoLines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInDecimalRange(1000, 3000, 2), LibraryRandom.RandDecInDecimalRange(1000, 3000, 2));
        LibrarySales.CreateCustomer(Customer);
        Quantity := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure VerifyTotals(var SalesHeader: Record "Sales Header"; ExpectedInvDiscValue: Decimal; ExpectedInvDiscType: Option)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount", "Recalculate Invoice Disc.");
        Assert.AreEqual(ExpectedInvDiscType, SalesHeader."Invoice Discount Calculation", 'Wrong order discount type');
        Assert.AreEqual(ExpectedInvDiscValue, SalesHeader."Invoice Discount Value", 'Wrong order discount value');
        Assert.IsFalse(SalesHeader."Recalculate Invoice Disc.", 'Recalculate inv. discount should be false');

        if ExpectedInvDiscValue = 0 then
            Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Wrong sales order discount amount')
        else
            Assert.IsTrue(SalesHeader."Invoice Discount Amount" > 0, 'order discount amount value is wrong');

        // Verify Aggregate table
        SalesOrderEntityBuffer.Get(SalesHeader."No.");
        Assert.AreEqual(SalesHeader.Amount, SalesOrderEntityBuffer.Amount, 'Amount was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT", SalesOrderEntityBuffer."Amount Including VAT",
          'Amount Including VAT was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT" - SalesHeader.Amount, SalesOrderEntityBuffer."Total Tax Amount",
          'Total Tax Amount was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Amount", SalesOrderEntityBuffer."Invoice Discount Amount",
          'Amount was not updated on Aggregate Table');
    end;

    local procedure FindFirstSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    local procedure SetupAmountDiscountTest(var SalesHeader: Record "Sales Header"; var DiscountAmount: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        CreateOrderWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        DiscountAmount := LibraryRandom.RandDecInDecimalRange(1, SalesHeader.Amount / 2, 2);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmount, SalesHeader);
    end;
}

