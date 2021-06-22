codeunit 135534 "Sales Cr. Memo Line E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Credit Memo]
    end;

    var
        CreditMemoServiceNameTxt: Label 'salesCreditMemos';
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        CreditMemoServiceLinesNameTxt: Label 'salesCreditMemoLines';
        LineTypeFieldNameTxt: Label 'lineType';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySales.SetStockoutWarning(false);

        LibraryApplicationArea.EnableFoundationSetup;

        IsInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFailsOnIDAbsense()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Call GET on the lines without providing a parent Credit Memo ID.
        // [GIVEN] the credit memo API exposed
        Initialize;

        // [WHEN] we GET all the lines without an ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage('',
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response text should be empty
        Assert.AreEqual('', ResponseText, 'Response JSON should be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCreditMemoLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        CreditMemoID: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a unposted Credit Memo
        // [GIVEN] An credit memo with lines.
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        LineNo1 := Format(SalesLine."Line No.");
        SalesLine.FindLast;
        LineNo2 := Format(SalesLine."Line No.");

        // [WHEN] we GET all the lines with the unposted credit memo ID from the web service
        GetCreditMemoLinesThroughAPI(CreditMemoID, ResponseText);

        // [THEN] the lines returned should be valid (numbers and integration ids)
        VerifyCreditMemoLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostedCreditMemoLines()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ResponseText: Text;
        CreditMemoID: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a posted Credit Memo
        // [GIVEN] A posted credit memo with lines.
        Initialize;
        CreditMemoID := CreatePostedSalesCreditMemoWithLines(SalesCrMemoHeader);

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst;
        LineNo1 := Format(SalesCrMemoLine."Line No.");
        SalesCrMemoLine.FindLast;
        LineNo2 := Format(SalesCrMemoLine."Line No.");

        // [WHEN] we GET all the lines with the posted credit memo ID from the web service
        GetCreditMemoLinesThroughAPI(CreditMemoID, ResponseText);

        // [THEN] the response text should contain the credit memo ID
        VerifyCreditMemoLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        LineNoFromJSON: Text;
        CreditMemoID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] POST a new line to an unposted Credit Memo
        // [GIVEN] An existing unposted credit memo and a valid JSON describing the new credit memo line
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");
        Commit;

        // [WHEN] we POST the JSON to the web service
        CreateCreditMemoLinesThroughAPI(CreditMemoID, CreditMemoLineJSON, ResponseText);

        // [THEN] the response text should contain the credit memo ID and the change should exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        VerifySalesCreditMemoLineExists(SalesHeader, LineNo, 'The unposted credit memo line should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoLineWithSequence()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        LineNoFromJSON: Text;
        CreditMemoID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] POST a new line to an unposted Credit Memo with a sequence number
        // [GIVEN] An existing unposted credit memo and a valid JSON describing the new credit memo line
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");
        LineNo := 500;
        CreditMemoLineJSON := LibraryGraphMgt.AddPropertytoJSON(CreditMemoLineJSON, 'sequence', LineNo);
        Commit;

        // [WHEN] we POST the JSON to the web service
        CreateCreditMemoLinesThroughAPI(CreditMemoID, CreditMemoLineJSON, ResponseText);

        // [THEN] the response text should contain the correct sequence and exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');
        Assert.AreEqual(Format(LineNo), LineNoFromJSON, 'The sequence in the response does not exist of the one that was given.');

        Evaluate(LineNo, LineNoFromJSON);
        VerifySalesCreditMemoLineExists(SalesHeader, LineNo, 'The unposted credit memo line should exist');

        Evaluate(LineNo, LineNoFromJSON);
        VerifySalesCreditMemoLineExists(SalesHeader, LineNo, 'The unposted credit memo line should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCreditMemoLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        LineNo: Integer;
        CreditMemoID: Text;
        SalesQuantity: Integer;
        SalesQuantityFromJSON: Text;
    begin
        // [SCENARIO] PATCH a line of an unposted Credit Memo
        // [GIVEN] An unposted credit memo with lines and a valid JSON describing the fields that we want to change
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        Assert.AreNotEqual('', CreditMemoID, 'ID should not be empty');
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        SalesQuantity := 4;
        CreditMemoLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(CreditMemoID, LineNo, CreditMemoLineJSON, ResponseText);

        // [THEN] the line should be changed in the table and the response JSON text should contain our changed field
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');

        GetSalesCreditMemoLine(SalesHeader, SalesLine, LineNo, 'The unposted credit memo line should exist after modification');
        Assert.AreEqual(SalesLine.Quantity, SalesQuantity, 'The patch of Sales line quantity was unsuccessful');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'quantity', SalesQuantityFromJSON),
          'Could not find the quantity property in' + ResponseText);
        Assert.AreNotEqual('', SalesQuantityFromJSON, 'Quantity should not be blank in ' + ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyCreditMemoLineFailsOnSequenceChange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        LineNo: Integer;
        CreditMemoID: Text;
        NewSequence: Integer;
    begin
        // [SCENARIO] PATCH a line of an unposted Credit Memo will fail if sequence is modified
        // [GIVEN] An unposted credit memo with lines and a valid JSON describing the fields that we want to change
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        Assert.AreNotEqual('', CreditMemoID, 'ID should not be empty');
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        NewSequence := SalesLine."Line No." + 1;
        CreditMemoLineJSON := LibraryGraphMgt.AddPropertytoJSON('', 'sequence', NewSequence);

        // [WHEN] we PATCH the line
        // [THEN] the request will fail
        asserterror ModifyCreditMemoLinesThroughAPI(CreditMemoID, LineNo, CreditMemoLineJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCreditMemoLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CreditMemoID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] DELETE a line from an unposted Credit Memo
        // [GIVEN] An unposted credit memo with lines
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        Commit;

        // [WHEN] we DELETE the first line of that credit memo
        DeleteCreditMemoLineThroughAPI(CreditMemoID, LineNo);

        // [THEN] the line should no longer exist in the database
        SalesLine.Reset;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsFalse(SalesLine.FindFirst, 'The credit memo line should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedCreditMemoLine()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CreditMemoID: Text;
        LineNo: Integer;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Call DELETE on a line of a posted Credit Memo
        // [GIVEN] A posted credit memo with lines
        Initialize;
        CreditMemoID := CreatePostedSalesCreditMemoWithLines(SalesCrMemoHeader);

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst;
        LineNo := SalesCrMemoLine."Line No.";

        // [WHEN] we DELETE the first line through the API
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            CreditMemoID,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            GetLineSubURL(CreditMemoID, LineNo));
        asserterror LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the line should still exist, since it's not allowed to delete lines in posted credit memos
        SalesCrMemoLine.Reset;
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesCrMemoLine.FindFirst, 'The credit memo line should still exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateLineThroughPageAndAPI()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        ApiSalesLine: Record "Sales Line";
        PageSalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        LineNoFromJSON: Text;
        CreditMemoID: Text;
        LineNo: Integer;
        ItemQuantity: Integer;
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Create an credit memo both through the client UI and through the API and compare their final values.
        // [GIVEN] An unposted credit memo and a JSON describing the line we want to create

        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        ItemNo := LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        CreditMemoID := SalesHeader.Id;
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, ItemQuantity, SalesHeader."Document Date");
        Commit;

        // [WHEN] we POST the JSON to the web service and when we create an credit memo through the client UI
        CreateCreditMemoLinesThroughAPI(CreditMemoID, CreditMemoLineJSON, ResponseText);
        CreateCreditMemoAndLinesThroughPage(SalesCreditMemo, CustomerNo, ItemNo, ItemQuantity);

        // [THEN] the response text should be valid, the credit memo line should exist in the tables and the two credit memos have the same field values.
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        GetSalesCreditMemoLine(SalesHeader, ApiSalesLine, LineNo, 'The unposted credit memo line should exist');

        PageSalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        PageSalesLine.SetRange("Document No.", SalesCreditMemo."No.".Value);
        Assert.IsTrue(PageSalesLine.FindFirst, 'The unposted credit memo line should exist');

        VerifyCreditMemoLinesMatching(ApiSalesLine, PageSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineUpdatesCreditMemoDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        CreditMemoLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Creating a line through API should update Discount Pct
        // [GIVEN] An unposted credit memo for customer with credit memo discount pct
        Initialize;
        CreateCreditMemoWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");
        Commit;

        // [WHEN] We create a line through API
        CreateCreditMemoLinesThroughAPI(SalesHeader.Id, CreditMemoLineJSON, ResponseText);

        // [THEN] Credit Memo discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesCreditMemoDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        CreditMemoLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should update Discount Pct
        // [GIVEN] An unposted credit memo for customer with credit memo discount pct
        Initialize;
        CreateCreditMemoWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesQuantity := SalesLine.Quantity * 2;

        Commit;

        CreditMemoLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(SalesHeader.Id, SalesLine."Line No.", CreditMemoLineJSON, ResponseText);

        // [THEN] Credit Memo discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineMovesCreditMemoDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        MinAmount1: Decimal;
        DiscountPct1: Decimal;
        MinAmount2: Decimal;
        DiscountPct2: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An unposted credit memo for customer with credit memo discount pct
        Initialize;
        CreateCreditMemoWithTwoLines(SalesHeader, Customer, Item);
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
        Commit;

        // [WHEN] we DELETE the line
        DeleteCreditMemoLineThroughAPI(SalesHeader.Id, SalesLine."Line No.");

        // [THEN] Lower Credit Memo discount is applied
        VerifyTotals(SalesHeader, DiscountPct1, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineRemovesCreditMemoDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An unposted credit memo for customer with credit memo discount pct
        Initialize;
        CreateCreditMemoWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        FindFirstSalesLine(SalesHeader, SalesLine);

        MinAmount := SalesHeader.Amount - SalesLine."Line Amount" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(30, 50, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");

        CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);
        SalesHeader.Find;
        Assert.AreEqual(SalesHeader."Invoice Discount Value", DiscountPct, 'Discount Pct was not assigned');
        Commit;

        // [WHEN] we DELETE the line
        DeleteCreditMemoLineThroughAPI(SalesHeader.Id, SalesLine."Line No.");

        // [THEN] Lower Credit Memo discount is applied
        VerifyTotals(SalesHeader, 0, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineKeepsCreditMemoDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        TargetURL: Text;
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Adding an credit memo through API will keep Discount Amount
        // [GIVEN] An unposted credit memo for customer with credit memo discount amount
        Initialize;
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");

        Commit;

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.Id,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoLineJSON, ResponseText);

        // [THEN] Discount Amount is Kept
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineKeepsCreditMemoDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        CreditMemoLineJSON: Text;
        ResponseText: Text;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should keep existing Discount Amount
        // [GIVEN] An unposted credit memo for customer with credit memo discount amt
        Initialize;
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        CreditMemoLineJSON := CreateCreditMemoLineJSON(Item.Id, LibraryRandom.RandIntInRange(1, 100), SalesHeader."Document Date");

        SalesQuantity := 0;
        CreditMemoLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));
        Commit;

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(SalesHeader.Id, SalesLine."Line No.", CreditMemoLineJSON, ResponseText);

        // [THEN] Credit Memo discount is kept
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineKeepsCreditMemoDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An unposted credit memo for customer with credit memo discount pct
        Initialize;
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        Commit;

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we DELETE the line
        DeleteCreditMemoLineThroughAPI(SalesHeader.Id, SalesLine."Line No.");

        // [THEN] Lower Credit Memo discount is applied
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
        ResponseText: Text;
        LinesJSON: Text;
    begin
        // [SCENARIO] Getting a line through API lists all possible types
        // [GIVEN] An credit memo with lines of different types
        Initialize;
        CreateCreditMemoWithDifferentLineTypes(SalesHeader, ExpectedNumberOfLines);

        Commit;

        // [WHEN] we GET the lines
        GetCreditMemoLinesThroughAPI(SalesHeader.Id, ResponseText);

        // [THEN] All lines are shown in the response
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'value', LinesJSON);
        LinesJSONManagement.InitializeCollection(LinesJSON);

        Assert.AreEqual(ExpectedNumberOfLines, LinesJSONManagement.GetCollectionCount, 'Four lines should be returned');
        VerifySalesCreditMemoLinesForSalesHeader(SalesHeader, LinesJSONManagement);
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
        CreditMemoLineJSON: Text;
    begin
        // [SCENARIO] Posting a line with description only will get a type item
        // [GIVEN] A post request with description only
        Initialize;
        CreateSalesCreditMemoWithLines(SalesHeader);

        Commit;

        CreditMemoLineJSON := '{"description":"test"}';

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.Id,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoLineJSON, ResponseText);

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
        CreditMemoLineJSON: Text;
    begin
        // [FEATURE] [Comment]
        // [SCENARIO] Posting a line with Type Comment and description will make a comment line
        // [GIVEN] A post request with type and description
        Initialize;
        CreateSalesCreditMemoWithLines(SalesHeader);

        CreditMemoLineJSON := '{"' + LineTypeFieldNameTxt + '":"Comment","description":"test"}';

        Commit;

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.Id,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoLineJSON, ResponseText);

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
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        CreditMemoID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Credit Memo
        // [GIVEN] An unposted credit memo with lines and a valid JSON describing the fields that we want to change
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        Assert.AreNotEqual('', CreditMemoID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        GetGLAccount(GLAccount, SalesLine);
        CreditMemoLineJSON := StrSubstNo('{"accountId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(GLAccount.Id));

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(CreditMemoID, LineNo, CreditMemoLineJSON, ResponseText);

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
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        CreditMemoLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Credit Memo
        // [GIVEN] An unposted credit memo with lines and a valid JSON describing the fields that we want to change
        Initialize;
        CreateCreditMemoWithDifferentLineTypes(SalesHeader, ExpectedNumberOfLines);
        CreditMemoLineID := IntegrationManagement.GetIdWithoutBrackets(SalesHeader.Id);
        SalesLine.SetRange(Type, SalesLine.Type::"Fixed Asset");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst;
        SalesLine.SetRange(Type);

        Assert.AreNotEqual('', CreditMemoLineID, 'ID should not be empty');
        LineNo := SalesLine."Line No.";
        LibraryInventory.CreateItem(Item);

        CreditMemoLineJSON := StrSubstNo('{"itemId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(Item.Id));
        Commit;

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(SalesHeader.Id, LineNo, CreditMemoLineJSON, ResponseText);

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
        ResponseText: Text;
        CreditMemoLineJSON: Text;
        CreditMemoID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Credit Memo
        // [GIVEN] An unposted credit memo with lines and a valid JSON describing the fields that we want to change
        Initialize;
        CreditMemoID := CreateSalesCreditMemoWithLines(SalesHeader);
        Assert.AreNotEqual('', CreditMemoID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        CreditMemoLineJSON := StrSubstNo('{"%1":"%2"}', LineTypeFieldNameTxt, Format(SalesInvoiceLineAggregate."API Type"::Account));

        // [WHEN] we PATCH the line
        ModifyCreditMemoLinesThroughAPI(CreditMemoID, LineNo, CreditMemoLineJSON, ResponseText);

        // [THEN] Line type is changed to Account
        FindFirstSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(SalesLine.Type::"G/L Account", SalesLine.Type, 'Type was not changed');
        Assert.AreEqual('', SalesLine."No.", 'No should be blank');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    local procedure CreateCreditMemoWithDifferentLineTypes(var SalesHeader: Record "Sales Header"; var ExpectedNumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesCreditMemoWithLines(SalesHeader);
        CreateLinesWithDifferentTypes(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        ExpectedNumberOfLines := SalesLine.Count;
    end;

    local procedure CreateSalesCreditMemoWithLines(var SalesHeader: Record "Sales Header"): Text
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        Commit;
        exit(SalesHeader.Id);
    end;

    local procedure CreatePostedSalesCreditMemoWithLines(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LibraryInventory: Codeunit "Library - Inventory";
        PostedSalesCreditMemoID: Text;
        NewNo: Code[20];
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        PostedSalesCreditMemoID := SalesHeader.Id;
        NewNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        Commit;

        SalesCrMemoHeader.Reset;
        SalesCrMemoHeader.SetFilter("No.", NewNo);
        SalesCrMemoHeader.FindFirst;

        exit(PostedSalesCreditMemoID);
    end;

    [Normal]
    local procedure CreateCreditMemoLineJSON(ItemId: Guid; Quantity: Integer; ShipmentDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        IntegrationManagement: Codeunit "Integration Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'itemId', IntegrationManagement.GetIdWithoutBrackets(ItemId));
        JSONManagement.AddJObjectToJObject(JsonObject, 'quantity', Quantity);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'shipmentDate', ShipmentDate);

        exit(JSONManagement.WriteObjectToString);
    end;

    local procedure CreateCreditMemoAndLinesThroughPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; CustomerNo: Text; ItemNo: Text; ItemQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesCreditMemo.OpenNew;
        SalesCreditMemo."Sell-to Customer No.".SetValue(CustomerNo);

        SalesCreditMemo.SalesLines.Last;
        SalesCreditMemo.SalesLines.Next;
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLine.Type::Item);
        SalesCreditMemo.SalesLines."No.".SetValue(ItemNo);

        SalesCreditMemo.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesCreditMemo.SalesLines.Next;
        SalesCreditMemo.SalesLines.Previous();
    end;

    local procedure GetCreditMemoLinesThroughAPI(CreditMemoID: Text; var ResponseText: Text)
    var
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(CreditMemoID,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);
    end;

    local procedure CreateCreditMemoLinesThroughAPI(CreditMemoID: Text; CreditMemoLineJSON: Text; var ResponseText: Text)
    var
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            CreditMemoID,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            CreditMemoServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, CreditMemoLineJSON, ResponseText);
    end;

    local procedure ModifyCreditMemoLinesThroughAPI(CreditMemoID: Text; LineNo: Integer; CreditMemoLineJSON: Text; var ResponseText: Text)
    var
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            CreditMemoID,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            GetLineSubURL(CreditMemoID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, CreditMemoLineJSON, ResponseText);
    end;

    local procedure DeleteCreditMemoLineThroughAPI(CreditMemoID: Text; LineNo: Integer)
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            CreditMemoID,
            PAGE::"Sales Credit Memo Entity",
            CreditMemoServiceNameTxt,
            GetLineSubURL(CreditMemoID, LineNo));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
    end;

    local procedure GetLineSubURL(CreditMemoID: Text; LineNo: Integer): Text
    begin
        exit(CreditMemoServiceLinesNameTxt +
          '(documentId=' + LibraryGraphMgt.StripBrackets(CreditMemoID) + ',sequence=' + Format(LineNo) + ')');
    end;

    local procedure GetGLAccount(var GLAccount: Record "G/L Account"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.FindFirst;
        if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then begin
            VATPostingSetup.Init;
            VATPostingSetup."VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
            VATPostingSetup."VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
            VATPostingSetup.Insert;
            Commit;
        end;
    end;

    local procedure VerifyCreditMemoLines(ResponseText: Text; LineNo1: Text; LineNo2: Text)
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
          'Could not find the credit memo lines in JSON');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON1, 'documentId');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON2, 'documentId');
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON1, 'itemId', ItemId1);
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON2, 'itemId', ItemId2);
        Assert.AreNotEqual(ItemId1, ItemId2, 'Item Ids should be different for different items');
    end;

    local procedure VerifySalesCreditMemoLinesForSalesHeader(var SalesHeader: Record "Sales Header"; var JSONManagement: Codeunit "JSON Management")
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

    local procedure CreateCreditMemoWithTwoLines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInDecimalRange(1000, 3000, 2), LibraryRandom.RandDecInDecimalRange(1000, 3000, 2));
        LibrarySales.CreateCustomer(Customer);
        Quantity := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure VerifyTotals(var SalesHeader: Record "Sales Header"; ExpectedInvDiscValue: Decimal; ExpectedInvDiscType: Option)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount", "Recalculate Invoice Disc.");
        Assert.AreEqual(ExpectedInvDiscType, SalesHeader."Invoice Discount Calculation", 'Wrong credit memo discount type');
        Assert.AreEqual(ExpectedInvDiscValue, SalesHeader."Invoice Discount Value", 'Wrong credit memo discount value');
        Assert.IsFalse(SalesHeader."Recalculate Invoice Disc.", 'Recalculate Invoice Disc. should be false');

        if ExpectedInvDiscValue = 0 then
            Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Wrong sales credit memo discount amount')
        else
            Assert.IsTrue(SalesHeader."Invoice Discount Amount" > 0, 'CreditMemo discount amount value is wrong');

        // Verify Buffer table
        SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);
        Assert.AreEqual(SalesHeader.Amount, SalesCrMemoEntityBuffer.Amount, 'Amount was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT", SalesCrMemoEntityBuffer."Amount Including VAT",
          'Amount Including VAT was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT" - SalesHeader.Amount, SalesCrMemoEntityBuffer."Total Tax Amount",
          'Total Tax Amount was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Amount", SalesCrMemoEntityBuffer."Invoice Discount Amount",
          'Amount was not updated on Buffer Table');
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
        CreateCreditMemoWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        DiscountAmount := LibraryRandom.RandDecInDecimalRange(1, SalesHeader.Amount / 2, 2);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmount, SalesHeader);
    end;

    local procedure GetSalesCreditMemoLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineNo: Integer; ErrorMessage: Text)
    begin
        SalesLine.Reset;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesLine.FindFirst, ErrorMessage);
    end;

    local procedure VerifySalesCreditMemoLineExists(var SalesHeader: Record "Sales Header"; LineNo: Integer; ErrorMessage: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        GetSalesCreditMemoLine(SalesHeader, SalesLine, LineNo, ErrorMessage);
    end;

    local procedure VerifyCreditMemoLinesMatching(var SalesLine1: Record "Sales Line"; var SalesLine2: Record "Sales Line")
    var
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        SalesLine1RecordRef: RecordRef;
        SalesLine2RecordRef: RecordRef;
    begin
        // Ignore these fields when comparing Page and API credit memos
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesLine1.FieldNo("Line No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesLine1.FieldNo("Document No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesLine1.FieldNo("No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, SalesLine1.FieldNo(Subtype), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, SalesLine1.FieldNo("Recalculate Invoice Disc."), DATABASE::"Sales Line"); // TODO: remove once other changes are checked in

        SalesLine1RecordRef.GetTable(SalesLine1);
        SalesLine2RecordRef.GetTable(SalesLine2);

        Assert.RecordsAreEqualExceptCertainFields(SalesLine1RecordRef, SalesLine2RecordRef, TempIgnoredFieldsForComparison,
          'Credit Memo Lines do not match');
    end;

    local procedure CreateLinesWithDifferentTypes(var SalesHeader: Record "Sales Header")
    var
        SalesLineFixedAsset: Record "Sales Line";
        SalesLineResource: Record "Sales Line";
        SalesLineComment: Record "Sales Line";
        Resource: Record Resource;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        FixedAsset: Record "Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryResource.CreateResource(Resource, VATBusinessPostingGroup.Code);
        LibrarySales.CreateSalesLine(SalesLineResource, SalesHeader, SalesLineResource.Type::Resource, Resource."No.", 1);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibrarySales.CreateSalesLine(SalesLineFixedAsset, SalesHeader, SalesLineFixedAsset.Type::"Fixed Asset", FixedAsset."No.", 1);

        LibrarySales.CreateSalesLineSimple(SalesLineComment, SalesHeader);
        SalesLineComment.Type := SalesLineComment.Type::" ";
        SalesLineComment.Description := 'Thank you for your business!';
        SalesLineComment.Modify;
    end;
}

