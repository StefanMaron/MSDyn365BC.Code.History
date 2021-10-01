#if not CLEAN18
codeunit 135511 "Sales Invoice Line E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Sales] [Invoice]
    end;

    var
        InvoiceServiceNameTxt: Label 'salesInvoices';
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        InvoiceServiceLinesNameTxt: Label 'salesInvoiceLines';
        LineTypeFieldNameTxt: Label 'lineType';
        UoMComplexTypeNameTxt: Label 'unitOfMeasure';
        UoMComplexTypeCodeNameTxt: Label 'code';
        UoMIdTxt: Label 'unitOfMeasureId';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sales Invoice Line E2E Test");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sales Invoice Line E2E Test");

        LibrarySales.SetStockoutWarning(false);
        LibraryApplicationArea.EnableFoundationSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sales Invoice Line E2E Test");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFailsOnIDAbsense()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Call GET on the lines without providing a parent Invoice ID.
        // [GIVEN] the invoice API exposed
        Initialize();

        // [WHEN] we GET all the lines without an ID from the web service
        TargetURL :=
            LibraryGraphMgt.CreateTargetURLWithSubpage('', PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, InvoiceServiceLinesNameTxt);
        asserterror LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response text should be empty
        Assert.AreEqual('', ResponseText, 'Response JSON should be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInvoiceLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ResponseText: Text;
        TargetURL: Text;
        InvoiceId: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a unposted Invoice
        // [GIVEN] An invoice with lines.
        Initialize();
        InvoiceId := CreateSalesInvoiceWithLines(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LineNo1 := Format(SalesLine."Line No.");
        SalesLine.FindLast();
        LineNo2 := Format(SalesLine."Line No.");

        // [WHEN] we GET all the lines with the unposted invoice ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the lines returned should be valid (numbers and integration ids)
        VerifyInvoiceLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostedInvoiceLines()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ResponseText: Text;
        TargetURL: Text;
        PostedInvoiceId: Text;
        LineNo1: Text;
        LineNo2: Text;
    begin
        // [SCENARIO] Call GET on the Lines of a posted Invoice
        // [GIVEN] A posted invoice with lines.
        Initialize();
        PostedInvoiceId := CreatePostedSalesInvoiceWithLines(SalesInvoiceHeader);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        LineNo1 := Format(SalesInvoiceLine."Line No.");
        SalesInvoiceLine.FindLast();
        LineNo2 := Format(SalesInvoiceLine."Line No.");

        // [WHEN] we GET all the lines with the posted invoice ID from the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            PostedInvoiceId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the response text should contain the invoice ID
        VerifyInvoiceLines(ResponseText, LineNo1, LineNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        LineNoFromJSON: Text;
        InvoiceID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] POST a new line to an unposted Invoice
        // [GIVEN] An existing unposted invoice and a valid JSON describing the new invoice line
        Initialize();
        InvoiceID := CreateSalesInvoiceWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] the response text should contain the invoice ID and the change should exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesLine.FindFirst, 'The unposted invoice line should exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceLineWithSequence()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        LineNoFromJSON: Text;
        InvoiceID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] POST a new line to an unposted Invoice with a sequence number
        // [GIVEN] An existing unposted invoice and a valid JSON describing the new invoice line
        Initialize();
        InvoiceID := CreateSalesInvoiceWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        LineNo := 500;
        InvoiceLineJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceLineJSON, 'sequence', LineNo);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] the response text should contain the correct sequence and exist in the database
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');
        Assert.AreEqual(Format(LineNo), LineNoFromJSON, 'The sequence in the response does not exist of the one that was given.');

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesLine.FindFirst, 'The unposted invoice line should exist');
        Assert.AreEqual(SalesLine."Line No.", LineNo, 'The line should have the line no that was given.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceLinesWithUoM()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        UnitOfMeasure: Record "Unit of Measure";
        UoMJSON: Text;
        ResponseText: array[2] of Text;
        TargetURL: Text;
        InvoiceLineJSON: array[2] of Text;
        InvoiceID: Text;
    begin
        // [SCENARIO] POST a new line to an unposted Invoice with a unit of measure id and complex type
        // [GIVEN] an existing unposted invoice and 2 valid JSONs describing the new invoice lines
        Initialize();
        InvoiceID := CreateSalesInvoiceWithLines(SalesHeader);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] a unit of measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] a JSON with an invoice line with UoM Id
        InvoiceLineJSON[1] := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        InvoiceLineJSON[1] := LibraryGraphMgt.AddPropertytoJSON(InvoiceLineJSON[1], UoMIdTxt, UnitOfMeasure.SystemId);

        // [GIVEN] a JSON with UoM complex type
        UoMJSON := LibraryGraphMgt.AddPropertytoJSON('{}', UoMComplexTypeCodeNameTxt, UnitOfMeasure.Code);

        // [GIVEN] a JSON with an invoice line with UoM as complex type
        InvoiceLineJSON[2] := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        InvoiceLineJSON[2] := LibraryGraphMgt.AddComplexTypetoJSON(InvoiceLineJSON[2], UoMComplexTypeNameTxt, UoMJSON);
        Commit();

        // [WHEN] we POST the JSONs to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON[1], ResponseText[1]);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON[2], ResponseText[2]);

        // [THEN] the response texts should contain the correct Unit of Measure information
        VerifyUoMInJson(ResponseText[1], UnitOfMeasure);
        VerifyUoMInJson(ResponseText[2], UnitOfMeasure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoiceLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        LineNo: Integer;
        InvoiceLineID: Text;
        SalesQuantity: Integer;
        SalesQuantityFromJSON: Text;
    begin
        // [SCENARIO] PATCH a line of an unposted Invoice
        // [GIVEN] An unposted invoice with lines and a valid JSON describing the fields that we want to change
        Initialize();
        InvoiceLineID := CreateSalesInvoiceWithLines(SalesHeader);
        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LineNo := SalesLine."Line No.";

        SalesQuantity := 4;
        InvoiceLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] the line should be changed in the table and the response JSON text should contain our changed field
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesLine.FindFirst, 'The unposted invoice line should exist after modification');
        Assert.AreEqual(SalesLine.Quantity, SalesQuantity, 'The patch of Sales line quantity was unsuccessful');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'quantity', SalesQuantityFromJSON),
          'Could not find the quantity property in' + ResponseText);
        Assert.AreNotEqual('', SalesQuantityFromJSON, 'Quantity should not be blank in ' + ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoiceLineFailsOnSequenceChange()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        LineNo: Integer;
        InvoiceLineID: Text;
        NewSequence: Integer;
    begin
        // [SCENARIO] PATCH a line of an unposted Invoice will fail if sequence is modified
        // [GIVEN] An unposted invoice with lines and a valid JSON describing the fields that we want to change
        Initialize();
        InvoiceLineID := CreateSalesInvoiceWithLines(SalesHeader);
        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LineNo := SalesLine."Line No.";

        NewSequence := SalesLine."Line No." + 1;
        InvoiceLineJSON := LibraryGraphMgt.AddPropertytoJSON('', 'sequence', NewSequence);

        // [WHEN] we PATCH the line
        // [THEN] the request will fail
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo));
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyInvoiceLinesWithUoM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        UoMJSON: Text;
        ResponseText: array[2] of Text;
        TargetURL: Text;
        InvoiceLineJSON: array[2] of Text;
        InvoiceLineID: Text;
        LineNo: array[2] of Integer;
    begin
        // [SCENARIO] PATCH a line to an unposted Invoice with a unit of measure id and complex type
        // [GIVEN] an existing unposted invoice with lines and 2 valid JSONs describing the new invoice lines
        Initialize();
        InvoiceLineID := CreateSalesInvoiceWithLines(SalesHeader);
        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LineNo[1] := SalesLine."Line No.";
        SalesLine.FindLast();
        LineNo[2] := SalesLine."Line No.";

        // [GIVEN] a unit of measure
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] a JSON with an UoM Id
        InvoiceLineJSON[1] := LibraryGraphMgt.AddPropertytoJSON('', UoMIdTxt, UnitOfMeasure.SystemId);

        // [GIVEN] a JSON with UoM complex type
        UoMJSON := LibraryGraphMgt.AddPropertytoJSON('{}', UoMComplexTypeCodeNameTxt, UnitOfMeasure.Code);

        // [GIVEN] a JSON with a UoM as complex type
        InvoiceLineJSON[2] := LibraryGraphMgt.AddComplexTypetoJSON('', UoMComplexTypeNameTxt, UoMJSON);
        Commit();

        // [WHEN] we PATCH the JSONs to the web service
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo[1]));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON[1], ResponseText[1]);
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo[2]));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON[2], ResponseText[2]);

        // [THEN] the response texts should contain the correct Unit of Measure information
        VerifyUoMInJson(ResponseText[1], UnitOfMeasure);
        VerifyUoMInJson(ResponseText[2], UnitOfMeasure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteInvoiceLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResponseText: Text;
        TargetURL: Text;
        InvoiceId: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] DELETE a line from an unposted Invoice
        // [GIVEN] An unposted invoice with lines
        Initialize();
        InvoiceId := CreateSalesInvoiceWithLines(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LineNo := SalesLine."Line No.";

        Commit();

        // [WHEN] we DELETE the first line of that invoice
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceId, LineNo));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the line should no longer exist in the database
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", LineNo);
        Assert.IsFalse(SalesLine.FindFirst, 'The invoice line should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedInvoiceLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ResponseText: Text;
        TargetURL: Text;
        PostedInvoiceId: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] Call DELETE on a line of a posted Invoice
        // [GIVEN] A posted invoice with lines
        Initialize();
        PostedInvoiceId := CreatePostedSalesInvoiceWithLines(SalesInvoiceHeader);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        LineNo := SalesInvoiceLine."Line No.";

        // [WHEN] we DELETE the first line through the API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            PostedInvoiceId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(PostedInvoiceId, LineNo));
        asserterror LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the line should still exist, since it's not allowed to delete lines in posted invoices
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(SalesInvoiceLine.FindFirst, 'The invoice line should still exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateLineThroughPageAndAPI()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PageSalesLine: Record "Sales Line";
        ApiSalesLine: Record "Sales Line";
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
        PageRecordRef: RecordRef;
        ApiRecordRef: RecordRef;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        LineNoFromJSON: Text;
        InvoiceID: Text;
        LineNo: Integer;
        ItemQuantity: Integer;
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Create an invoice both through the client UI and through the API and compare their final values.
        // [GIVEN] An unposted invoice and a JSON describing the line we want to create
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        ItemNo := LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        InvoiceID := SalesHeader.SystemId;
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, ItemQuantity);
        Commit();

        // [WHEN] we POST the JSON to the web service and when we create an invoice through the client UI
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] the response text should be valid, the invoice line should exist in the tables and the two invoices have the same field values.
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'sequence', LineNoFromJSON), 'Could not find sequence');

        Evaluate(LineNo, LineNoFromJSON);
        ApiSalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        ApiSalesLine.SetRange("Document No.", SalesHeader."No.");
        ApiSalesLine.SetRange("Line No.", LineNo);
        Assert.IsTrue(ApiSalesLine.FindFirst, 'The unposted invoice line should exist');

        CreateInvoiceAndLinesThroughPage(SalesInvoice, CustomerNo, ItemNo, ItemQuantity);

        PageSalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        PageSalesLine.SetRange("Document No.", SalesInvoice."No.".Value);
        Assert.IsTrue(PageSalesLine.FindFirst, 'The unposted invoice line should exist');

        ApiRecordRef.GetTable(ApiSalesLine);
        PageRecordRef.GetTable(PageSalesLine);

        // Ignore these fields when comparing Page and API invoices
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Line No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("No."), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo(Subtype), DATABASE::"Sales Line");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, ApiSalesLine.FieldNo("Recalculate Invoice Disc."), DATABASE::"Sales Line"); // TODO: remove once other changes are checked in

        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API Invoice lines do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineUpdatesInvoiceDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Creating a line through API should update Discount Pct
        // [GIVEN] An unposted invoice for customer with invoice discount pct
        Initialize();
        CreateInvoiceWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Invoice discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineUpdatesInvoiceDiscountPct()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TargetURL: Text;
        InvoiceLineJSON: Text;
        ResponseText: Text;
        MinAmount: Decimal;
        DiscountPct: Decimal;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should update Discount Pct
        // [GIVEN] An unposted invoice for customer with invoice discount pct
        Initialize();
        CreateInvoiceWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        MinAmount := SalesHeader.Amount + Item."Unit Price" / 2;
        DiscountPct := LibraryRandom.RandDecInDecimalRange(1, 90, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, MinAmount, SalesHeader."Currency Code");
        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesQuantity := SalesLine.Quantity * 2;

        Commit();

        InvoiceLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Invoice discount is applied
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountPct, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineMovesInvoiceDiscountPct()
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
        // [GIVEN] An unposted invoice for customer with invoice discount pct
        Initialize();
        CreateInvoiceWithTwoLines(SalesHeader, Customer, Item);
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
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower Invoice discount is applied
        VerifyTotals(SalesHeader, DiscountPct1, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineRemovesInvoiceDiscountPct()
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
        // [GIVEN] An unposted invoice for customer with invoice discount pct
        Initialize();
        CreateInvoiceWithTwoLines(SalesHeader, Customer, Item);
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
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower Invoice discount is applied
        VerifyTotals(SalesHeader, 0, SalesHeader."Invoice Discount Calculation"::"%");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingLineKeepsInvoiceDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        TargetURL: Text;
        ResponseText: Text;
        InvoiceLineJSON: Text;
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Adding an invoice through API will keep Discount Amount
        // [GIVEN] An unposted invoice for customer with invoice discount amount
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        Commit();

        // [WHEN] We create a line through API
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Discount Amount is Kept
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingLineKeepsInvoiceDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        TargetURL: Text;
        InvoiceLineJSON: Text;
        ResponseText: Text;
        SalesQuantity: Integer;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Modifying a line through API should keep existing Discount Amount
        // [GIVEN] An unposted invoice for customer with invoice discount amt
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        InvoiceLineJSON := CreateInvoiceLineJSON(Item.SystemId, LibraryRandom.RandIntInRange(1, 100));

        SalesQuantity := 0;
        InvoiceLineJSON := LibraryGraphMgt.AddComplexTypetoJSON('{}', 'quantity', Format(SalesQuantity));
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Invoice discount is kept
        Assert.AreNotEqual('', ResponseText, 'Response JSON should not be blank');
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'itemId');
        VerifyTotals(SalesHeader, DiscountAmount, SalesHeader."Invoice Discount Calculation"::Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingLineKeepsInvoiceDiscountAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DiscountAmount: Decimal;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO] Deleting a line through API should update Discount Pct
        // [GIVEN] An unposted invoice for customer with invoice discount pct
        Initialize();
        SetupAmountDiscountTest(SalesHeader, DiscountAmount);
        Commit();

        FindFirstSalesLine(SalesHeader, SalesLine);

        // [WHEN] we DELETE the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, SalesLine."Line No."));
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] Lower Invoice discount is applied
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
        CreateInvoiceWithAllPossibleLineTypes(SalesHeader, ExpectedNumberOfLines);

        Commit();

        // [WHEN] we GET the lines
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] All lines are shown in the response
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'value', LinesJSON);
        LinesJSONManagement.InitializeCollection(LinesJSON);

        Assert.AreEqual(ExpectedNumberOfLines, LinesJSONManagement.GetCollectionCount, 'Four lines should be returned');
        VerifySalesInvoiceLinesForSalesHeader(SalesHeader, LinesJSONManagement);
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
        InvoiceLineJSON: Text;
    begin
        // [SCENARIO] Posting a line with description only will get a type item
        // [GIVEN] A post request with description only
        Initialize();
        CreateSalesInvoiceWithLines(SalesHeader);

        Commit();

        InvoiceLineJSON := '{"description":"test"}';

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Line of type Item is created
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesLine.FindLast();
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
        InvoiceLineJSON: Text;
    begin
        // [FEATURE] [Comment]
        // [SCENARIO] Posting a line with Type Comment and description will make a comment line
        // [GIVEN] A post request with type and description
        Initialize();
        CreateSalesInvoiceWithLines(SalesHeader);

        InvoiceLineJSON := '{"' + LineTypeFieldNameTxt + '":"Comment","description":"test"}';

        Commit();

        // [WHEN] we just POST a blank line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            InvoiceServiceLinesNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Line of type Item is created
        FindFirstSalesLine(SalesHeader, SalesLine);
        SalesLine.FindLast();
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
        InvoiceLineJSON: Text;
        InvoiceLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Invoice
        // [GIVEN] An unposted invoice with lines and a valid JSON describing the fields that we want to change
        Initialize();
        InvoiceLineID := CreateSalesInvoiceWithLines(SalesHeader);
        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        GetGLAccount(GLAccount);

        InvoiceLineJSON := StrSubstNo('{"accountId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(GLAccount.SystemId));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

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
        InvoiceLineJSON: Text;
        InvoiceLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Invoice
        // [GIVEN] An unposted invoice with lines and a valid JSON describing the fields that we want to change
        Initialize();
        CreateInvoiceWithAllPossibleLineTypes(SalesHeader, ExpectedNumberOfLines);
        InvoiceLineID := IntegrationManagement.GetIdWithoutBrackets(SalesHeader.SystemId);
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.SetRange(Type);

        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        LineNo := SalesLine."Line No.";
        LibraryInventory.CreateItem(Item);

        InvoiceLineJSON := StrSubstNo('{"itemId":"%1"}', IntegrationManagement.GetIdWithoutBrackets(Item.SystemId));
        Commit();

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            SalesHeader.SystemId,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(SalesHeader.SystemId, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

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
        InvoiceLineJSON: Text;
        InvoiceLineID: Text;
        LineNo: Integer;
    begin
        // [SCENARIO] PATCH a Type on a line of an unposted Invoice
        // [GIVEN] An unposted invoice with lines and a valid JSON describing the fields that we want to change
        Initialize();
        InvoiceLineID := CreateSalesInvoiceWithLines(SalesHeader);
        Assert.AreNotEqual('', InvoiceLineID, 'ID should not be empty');
        FindFirstSalesLine(SalesHeader, SalesLine);
        LineNo := SalesLine."Line No.";

        InvoiceLineJSON := StrSubstNo('{"%1":"%2"}', LineTypeFieldNameTxt, Format(SalesInvoiceLineAggregate."API Type"::Account));

        // [WHEN] we PATCH the line
        TargetURL := LibraryGraphMgt
          .CreateTargetURLWithSubpage(
            InvoiceLineID,
            PAGE::"Sales Invoice Entity",
            InvoiceServiceNameTxt,
            GetLineSubURL(InvoiceLineID, LineNo));
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceLineJSON, ResponseText);

        // [THEN] Line type is changed to Account
        FindFirstSalesLine(SalesHeader, SalesLine);
        Assert.AreEqual(SalesLine.Type::"G/L Account", SalesLine.Type, 'Type was not changed');
        Assert.AreEqual('', SalesLine."No.", 'No should be blank');

        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyIdsAreBlank(JsonObject);
    end;

    local procedure CreateInvoiceWithAllPossibleLineTypes(var SalesHeader: Record "Sales Header"; var ExpectedNumberOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
    begin
        CreateSalesInvoiceWithLines(SalesHeader);

        LibraryGraphDocumentTools.CreateSalesLinesWithAllPossibleTypes(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        ExpectedNumberOfLines := SalesLine.Count();
    end;

    local procedure CreateSalesInvoiceWithLines(var SalesHeader: Record "Sales Header"): Text
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        Commit();
        exit(SalesHeader.SystemId);
    end;

    local procedure CreatePostedSalesInvoiceWithLines(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LibraryInventory: Codeunit "Library - Inventory";
        PostedSalesInvoiceID: Text;
        NewNo: Code[20];
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        PostedSalesInvoiceID := SalesHeader.SystemId;
        NewNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        Commit();

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", NewNo);
        SalesInvoiceHeader.FindFirst();

        exit(PostedSalesInvoiceID);
    end;

    [Normal]
    local procedure CreateInvoiceLineJSON(ItemId: Guid; Quantity: Integer): Text
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

    local procedure CreateInvoiceAndLinesThroughPage(var SalesInvoice: TestPage "Sales Invoice"; CustomerNo: Text; ItemNo: Text; ItemQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesInvoice.OpenNew;
        SalesInvoice."Sell-to Customer No.".SetValue(CustomerNo);

        SalesInvoice.SalesLines.Last;
        SalesInvoice.SalesLines.Next;
        SalesInvoice.SalesLines.FilteredTypeField.SETVALUE(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(ItemNo);

        SalesInvoice.SalesLines.Quantity.SetValue(ItemQuantity);

        // Trigger Save
        SalesInvoice.SalesLines.Next;
        SalesInvoice.SalesLines.Previous();
    end;

    local procedure GetLineSubURL(InvoiceId: Text; LineNo: Integer): Text
    begin
        exit(InvoiceServiceLinesNameTxt +
          '(documentId=' + LibraryGraphMgt.StripBrackets(InvoiceId) + ',sequence=' + Format(LineNo) + ')');
    end;

    local procedure GetGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.FindFirst();
    end;

    local procedure VerifyInvoiceLines(ResponseText: Text; LineNo1: Text; LineNo2: Text)
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
          'Could not find the invoice lines in JSON');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON1, 'documentId');
        LibraryGraphMgt.VerifyIDFieldInJson(LineJSON2, 'documentId');
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON1, 'itemId', ItemId1);
        LibraryGraphMgt.GetObjectIDFromJSON(LineJSON2, 'itemId', ItemId2);
        Assert.AreNotEqual(ItemId1, ItemId2, 'Item Ids should be different for different items');
    end;

    local procedure VerifySalesInvoiceLinesForSalesHeader(var SalesHeader: Record "Sales Header"; var JSONManagement: Codeunit "JSON Management")
    var
        SalesLine: Record "Sales Line";
        JObject: DotNet JObject;
        CurrentIndex: Integer;
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
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

    local procedure CreateInvoiceWithTwoLines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInDecimalRange(1000, 3000, 2), LibraryRandom.RandDecInDecimalRange(1000, 3000, 2));
        LibrarySales.CreateCustomer(Customer);
        Quantity := LibraryRandom.RandIntInRange(1, 10);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
    end;

    local procedure VerifyTotals(var SalesHeader: Record "Sales Header"; ExpectedInvDiscValue: Decimal; ExpectedInvDiscType: Option)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesHeader.Find;
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount", "Recalculate Invoice Disc.");
        Assert.AreEqual(ExpectedInvDiscType, SalesHeader."Invoice Discount Calculation", 'Wrong invoice discount type');
        Assert.AreEqual(ExpectedInvDiscValue, SalesHeader."Invoice Discount Value", 'Wrong invoice discount value');
        Assert.IsFalse(SalesHeader."Recalculate Invoice Disc.", 'Recalculate inv. discount should be false');

        if ExpectedInvDiscValue = 0 then
            Assert.AreEqual(0, SalesHeader."Invoice Discount Amount", 'Wrong sales invoice discount amount')
        else
            Assert.IsTrue(SalesHeader."Invoice Discount Amount" > 0, 'Invoice discount amount value is wrong');

        // Verify Aggregate table
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);
        Assert.AreEqual(SalesHeader.Amount, SalesInvoiceEntityAggregate.Amount, 'Amount was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT", SalesInvoiceEntityAggregate."Amount Including VAT",
          'Amount Including VAT was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Amount Including VAT" - SalesHeader.Amount, SalesInvoiceEntityAggregate."Total Tax Amount",
          'Total Tax Amount was not updated on Aggregate Table');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Amount", SalesInvoiceEntityAggregate."Invoice Discount Amount",
          'Amount was not updated on Aggregate Table');
    end;

    local procedure FindFirstSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure SetupAmountDiscountTest(var SalesHeader: Record "Sales Header"; var DiscountAmount: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        CreateInvoiceWithTwoLines(SalesHeader, Customer, Item);
        SalesHeader.CalcFields(Amount);
        DiscountAmount := LibraryRandom.RandDecInDecimalRange(1, SalesHeader.Amount / 2, 2);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(DiscountAmount, SalesHeader);
    end;

    local procedure VerifyUoMInJson(JSONTxt: Text; UnitOfMeasure: Record "Unit of Measure")
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONUoMValue: Text;
        UoMCodeValue: Text;
        UoMIdValue: Text;
        UoMGUID: Guid;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);

        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, UoMComplexTypeNameTxt, JSONUoMValue),
          'Could not find the UnitOfMeasure complex type in' + JSONTxt);
        Assert.AreNotEqual('null', JSONUoMValue, 'UnitOfMeasure complex type should not be null in ' + JSONTxt);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, UoMIdTxt, UoMIdValue),
          'Could not find the UnitOfMeasureId in' + JSONTxt);
        UoMGUID := UoMIdValue;
        Assert.AreEqual(UnitOfMeasure.SystemId, UoMGUID, 'UnitOfMeasure Id should be ' + UoMIdValue);

        JSONManagement.InitializeObject(JSONUoMValue);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, UoMComplexTypeCodeNameTxt, UoMCodeValue),
          'Could not find the UnitOfMeasure code in' + JSONTxt);
        Assert.AreEqual(UnitOfMeasure.Code, UoMCodeValue, 'UnitOfMeasure code complex type should not be null in ' + JSONTxt);
    end;
}
#endif
