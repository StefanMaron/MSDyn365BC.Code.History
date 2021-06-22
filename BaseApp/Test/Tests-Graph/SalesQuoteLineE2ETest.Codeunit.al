codeunit 135529 "Sales Quote Line E2E Test"
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
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        QuoteServiceNameTxt: Label 'salesQuotes';
        QuoteServiceLinesNameTxt: Label 'salesQuoteLines';
        LineTypeFieldNameTxt: Label 'lineType';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySales.SetStockoutWarning(false);

        LibraryApplicationArea.EnableFoundationSetup;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuoteLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        QuoteId: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a quote
        // [GIVEN] A quote with lines.
        Initialize;
        QuoteId := CreateSalesQuoteWithLines(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesLine.FindFirst;
        LineNo1 := Format(SalesLine."Line No.");
        SalesLine.FindLast;
        LineNo2 := Format(SalesLine."Line No.");

        // [WHEN] we GET all the lines with the  quote ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            QuoteId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the lines returned should be valid (numbers and integration ids)
        VerifyQuoteLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostQuoteLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        QuoteLineJSON: Text;
        LineNoFromJSON: Text;
        QuoteId: Text;
        LineNo: Integer;
        SalesLineExists: Boolean;
    begin
        // [SCENARIO] POST a new line to a quote
        // [GIVEN] An existing  quote and a valid JSON describing the new quote line
        Initialize;
        QuoteId := CreateSalesQuoteWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        QuoteLineJSON := CreateQuoteLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            QuoteId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] the response text should contain the quote ID and the change should exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        SalesLineExists := FindSalesLine(SalesLine, LineNo, SalesHeader."No.");
        Assert.IsTrue(SalesLineExists, 'The quote line should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyQuoteLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        QuoteLineJSON: Text;
        LineNo: Integer;
        QuoteLineId: Text;
        SalesQuantity: Integer;
        SalesLineExists: Boolean;
    begin
        // [SCENARIO] PATCH a line of a quote
        // [GIVEN] a quote with lines and a valid JSON describing the fields that we want to change
        Initialize;
        QuoteLineId := CreateSalesQuoteWithLines(SalesHeader);
        Assert.AreNotEqual('', QuoteLineId, 'ID should not be empty');
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        SalesQuantity := 4;
        QuoteLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            QuoteLineId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(QuoteLineId, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] the line should be changed in the table and the response JSON text should contain our changed field
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');

        SalesLine.Reset();
        SalesLineExists := FindSalesLine(SalesLine, LineNo, SalesHeader."No.");
        Assert.IsTrue(SalesLineExists, 'The  quote line should exist after modification');
        Assert.AreEqual(SalesLine.Quantity, SalesQuantity, 'The patch of Sales line quantity was unsuccessful');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteQuoteLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        QuoteId: Text;
        LineNo: Integer;
        SalesLineExists: Boolean;
    begin
        // [SCENARIO] DELETE a line from a quote
        // [GIVEN] a quote with lines
        Initialize;
        QuoteId := CreateSalesQuoteWithLines(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesLine.FindFirst;
        LineNo := SalesLine."Line No.";

        Commit();

        // [WHEN] we DELETE the first line of that quote
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            QuoteId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(QuoteId, LineNo));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the line should no longer exist in the database
        SalesLine.Reset();
        SalesLineExists := FindSalesLine(SalesLine, LineNo, SalesHeader."No.");
        Assert.IsFalse(SalesLineExists, 'The quote line should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineUpdatesQuoteDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        TargetURL: Text;
        QuoteLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Creating a line through API should update Discount Pct
        // [GIVEN] A quote for customer with discount pct
        Initialize;
        CreateQuoteWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        QuoteLineJSON := CreateQuoteLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] quote discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesQuoteDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TargetURL: Text;
        QuoteLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should update Discount Pct
        // [GIVEN] A quote for customer with discount pct
        Initialize;
        CreateQuoteWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        QuoteLineJSON := CreateQuoteLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesQuantity := SalesLine.Quantity * 2;

        Commit();

        QuoteLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineMovesQuoteDiscountPct()
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
        // [GIVEN] A quote for customer with quote discount pct
        Initialize;
        CreateQuoteWithTwoLines(SalesHeader, Customer, Item);
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
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower discount is applied
        VerifyTotals(SalesHeader, DiscountPct1, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineRemovesQuoteDiscountPct()
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
        // [GIVEN] A quote for customer with discount pct
        Initialize;
        CreateQuoteWithTwoLines(SalesHeader, Customer, Item);
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
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower discount is applied
        VerifyTotals(SalesHeader, 0, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineKeepsQuoteDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        TargetURL: Text;
        ResponseText: Text;
        QuoteLineJSON: Text;
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Adding a quote through API will keep Discount Amount
        // [GIVEN] A quote for customer with discount amount
        Initialize;
        SetupAmountDiscountTest(SalesHeader, Item, DiscountAmount);
        QuoteLineJSON := CreateQuoteLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] Discount Amount is Kept
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineKeepsQuoteDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        TargetURL: Text;
        QuoteLineJSON: Text;
        ResponseText: Text;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should keep existing Discount Amount
        // [GIVEN] A quote for customer with discount amt
        Initialize;
        SetupAmountDiscountTest(SalesHeader, Item, DiscountAmount);
        QuoteLineJSON := CreateQuoteLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        SalesQuantity := 0;
        QuoteLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] discount is kept
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineKeepsQuoteDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DiscountAmount: Decimal;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] A quote for customer with discount pct
        Initialize;
        SetupAmountDiscountTest(SalesHeader, Item, DiscountAmount);
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we DELETE the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower discount is applied
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
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
        QuoteLineJSON: Text;
    begin
        // [SCENARIO] Posting a line with description only will get a type item
        // [GIVEN] A post request with description only
        Initialize;
        CreateSalesQuoteWithLines(SalesHeader);

        Commit();

        QuoteLineJSON := '{"description":"test"}';

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteLineJSON, ResponseText);

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
        QuoteLineJSON: Text;
    begin
        // [FEATURE] [Comment]
        // [SCENARIO] Posting a line with Type Comment and description will make a comment line
        // [GIVEN] A post request with type and description
        Initialize;
        CreateSalesQuoteWithLines(SalesHeader);

        QuoteLineJSON := '{"' + LineTypeFieldNameTxt + '":"Comment","description":"test"}';

        Commit();

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            QuoteServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, QuoteLineJSON, ResponseText);

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
    procedure TestPatchingTheTypeBlanksIds()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        TargetURL: Text;
        ResponseText: Text;
        QuoteLineJSON: Text;
        QuoteLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of a quote
        // [GIVEN] a quote with lines and a valid JSON describing the fields that we want to change
        Initialize;
        QuoteLineID := CreateSalesQuoteWithLines(SalesHeader);
        Assert.AreNotEqual('', QuoteLineID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        QuoteLineJSON := StrSubstNo('{"%1":"%2"}', LineTypeFieldNameTxt, Format(SalesInvoiceLineAggregate."API Type"::Account));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            QuoteLineID,
            PAGE::"Sales Quote Entity",
            QuoteServiceNameTxt,
            GetLineSubURL(QuoteLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, QuoteLineJSON, ResponseText);

        // [THEN] Line type is changed to Account
        FindFirstSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(SalesLine.Type::"G/L Account", SalesLine.Type, 'Type was not changed');
        Assert.AreEqual('', SalesLine."No.", 'No should be blank');
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    [Normal]
    local procedure CreateQuoteLineJSON(ItemId: Guid; Quantity: Integer): Text
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

    local procedure GetLineSubURL(QuoteId: Text; LineNo: Integer): Text
    begin
        exit(QuoteServiceLinesNameTxt +
          '(documentId=' + LibraryGraphMgt.StripBrackets(QuoteId) + ',sequence=' + Format(LineNo) + ')');
    end;

    local procedure VerifyQuoteLines(ResponseText: Text; LineNo1: Text; LineNo2: Text)
    var
        LineJSON1: Text;
        LineJSON2: Text;
        SequenceNumber1: Text;
        SequenceNumber2: Text;
    begin
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(
            ResponseText, 'sequence', LineNo1, LineNo2, LineJSON1, LineJSON2),
          'Could not find the quote lines in JSON');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON1, 'documentId');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON2, 'documentId');
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON1, 'sequence', SequenceNumber1);
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON2, 'sequence', SequenceNumber2);
        Assert.AreNotEqual(SequenceNumber1, SequenceNumber2, 'Sequence numbers should be different for different lines');
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

    local procedure CreateQuoteWithTwoLines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInDecimalRange(1000, 3000, 2), LibraryRandom.RandDecInDecimalRange(1000, 3000, 2));
        LibrarySales.CreateCustomer(Customer);
        Quantity := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure VerifyTotals(var SalesHeader: Record "Sales Header"; ExpectedInvDiscValue: Decimal; ExpectedInvDiscType: Option)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount", "Recalculate Invoice Disc.");
        Assert.AreEqual(ExpectedInvDiscType, SalesHeader."Invoice Discount Calculation", 'Wrong discount type');
        Assert.AreEqual(ExpectedInvDiscValue, SalesHeader."Invoice Discount Value", 'Wrong discount value');
        Assert.IsFalse(SalesHeader."Recalculate Invoice Disc.", 'Recalculate inv. discount should be false');

        if ExpectedInvDiscValue = 0 then
            Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Wrong sales discount amount')
        else
            Assert.IsTrue(SalesHeader."Invoice Discount Amount" > 0, 'discount amount value is wrong');

        // Verify Aggregate table
        SalesQuoteEntityBuffer.Get(SalesHeader."No.");
        Assert.AreEqual(SalesHeader.Amount, SalesQuoteEntityBuffer.Amount, 'Amount was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT", SalesQuoteEntityBuffer."Amount Including VAT",
          'Amount Including VAT was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT" - SalesHeader.Amount, SalesQuoteEntityBuffer."Total Tax Amount",
          'Total Tax Amount was not updated on Buffer Table');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Amount", SalesQuoteEntityBuffer."Invoice Discount Amount",
          'Amount was not updated on Buffer Table');
    end;

    local procedure FindFirstSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    local procedure SetupAmountDiscountTest(var SalesHeader: Record "Sales Header"; var Item: Record Item; var DiscountAmount: Decimal)
    var
        Customer: Record Customer;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        CreateQuoteWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        DiscountAmount := LibraryRandom.RandDecInDecimalRange(1, SalesHeader.Amount / 2, 2);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmount, SalesHeader);
    end;

    local procedure CreateSalesQuoteWithLines(var SalesHeader: Record "Sales Header"): Text
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(SalesHeader, Customer, Item, 2, 1);
        Commit();
        exit(SalesHeader.SystemId);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; LineNumber: Integer; QuoteNumber: Text): Boolean
    var
        DummySalesHeader: Record "Sales Header";
    begin
        SalesLine.SetRange("Document No.", QuoteNumber);
        SalesLine.SetRange("Document Type", DummySalesHeader."Document Type"::Quote);
        SalesLine.SetRange("Line No.", LineNumber);
        exit(SalesLine.FindFirst);
    end;
}

