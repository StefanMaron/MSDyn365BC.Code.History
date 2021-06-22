codeunit 135537 "Purchase Invoice E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Invoice]
    end;

    var
        TempIgnoredFieldsForComparison: Record "Field" temporary;
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryGraphDocumentTools: Codeunit "Library - Graph Document Tools";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        InvoiceServiceNameTxt: Label 'purchaseInvoices';

    local procedure Initialize()
    begin
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
        // [SCENARIO 184721] Create posted and unposted Purchase invoices and use a GET method to retrieve them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;
        CreatePurchaseInvoices(InvoiceID1, InvoiceID2);
        Commit();

        // [WHEN] we GET all the invoices from the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
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
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Text;
        InvoiceDate: Date;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceWithComplexJSON: Text;
    begin
        // [SCENARIO 184721] Create posted and unposted Purchase invoices and use HTTP POST to delete them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;

        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        InvoiceDate := WorkDate;

        InvoiceWithComplexJSON := CreateInvoiceJSONWithAddress(Vendor, InvoiceDate);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] the response text should have the correct Id, invoice address and the invoice should exist in the table with currency code set by default
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find purchase invoice number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        LibraryGraphDocumentTools.VerifyPurchaseDocumentBuyFromAddress(Vendor, PurchaseHeader, ResponseText, false, false);

        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("No.", InvoiceNumber);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.SetRange("Document Date", InvoiceDate);
        Assert.IsTrue(PurchaseHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual('', PurchaseHeader."Currency Code", 'The invoice should have the LCY currency code set by default');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseInvoiceWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Text;
        ResponseText: Text;
        InvoiceNumber: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 184721] Create posted and unposted with specific currency set and use HTTP POST to create them
        Initialize;

        // [GIVEN] an Invoice with a non-LCY currencyCode set
        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";

        CurrencyCode := GetCurrencyCode;
        InvoiceJSON := CreateInvoiceJSON('vendorNumber', VendorNo, 'currencyCode', CurrencyCode);
        Commit();

        // [WHEN] we POST the JSON to the web service
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);

        // [THEN] the response text should contain the invoice ID and the integration record table should map the PurchaseInvoiceId with the ID
        Assert.AreNotEqual('', ResponseText, 'response JSON should not be blank');
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'number', InvoiceNumber),
          'Could not find Purchase invoice number');
        LibraryGraphMgt.VerifyIDInJson(ResponseText);

        // [THEN] the invoice should exist in the tables
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("No.", InvoiceNumber);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.IsTrue(PurchaseHeader.FindFirst, 'The unposted invoice should exist');
        Assert.AreEqual(CurrencyCode, PurchaseHeader."Currency Code", 'The invoice should have the correct currency code');
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
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        InvoiceIntegrationID: Text;
        InvoiceID: Text;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        InvoiceWithComplexJSON: Text;
        ComplexTypeJSON: Text;
    begin
        // [SCENARIO 184721] Create Purchase Invoice, use a PATCH method to change it and then verify the changes
        Initialize;
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [GIVEN] an order with the previously created vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] an item with unit price and unit cost
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));

        // [GIVEN] an line in the previously created order
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        InvoiceID := PurchaseHeader."No.";

        // [GIVEN] the invoice's unique ID
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("No.", InvoiceID);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.FindFirst;
        InvoiceIntegrationID := PurchaseHeader.SystemId;
        Assert.AreNotEqual('', InvoiceIntegrationID, 'ID should not be empty');

        if EmptyData then
            InvoiceJSON := '{}'
        else
            InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON(InvoiceJSON, 'vendorNumber', Vendor."No.");

        // [GIVEN] a JSON text with an Item that has the BillingPostalAddress complex type
        LibraryGraphDocumentTools.GetVendorAddressComplexType(ComplexTypeJSON, Vendor, EmptyData, PartiallyEmptyData);
        InvoiceWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(InvoiceJSON, 'buyFromAddress', ComplexTypeJSON);

        Commit();

        // [WHEN] we PATCH the JSON to the web service, with the unique Item ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(InvoiceIntegrationID, PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        // [THEN] the item should have the Unit of Measure as a value in the table
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("No.", InvoiceID);
        Assert.IsTrue(PurchaseHeader.FindFirst, 'The unposted invoice should exist');

        // [THEN] the response text should contain the invoice address
        LibraryGraphDocumentTools.VerifyPurchaseDocumentBuyFromAddress(Vendor, PurchaseHeader, ResponseText, EmptyData, PartiallyEmptyData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteInvoices()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        InvoiceID1: Text;
        InvoiceID2: Text;
        ID1: Text;
        ID2: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO 184721] Create posted and unposted Purchase invoices and use HTTP DELETE to delete them
        // [GIVEN] 2 invoices, one posted and one unposted
        Initialize;
        CreatePurchaseInvoices(InvoiceID1, InvoiceID2);

        PurchInvHeader.Get(InvoiceID1);
        ID1 := PurchInvHeader."Draft Invoice SystemId";
        Assert.AreNotEqual('', ID1, 'ID should not be empty');

        PurchaseHeader.Reset();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, InvoiceID2);
        ID2 := PurchaseHeader.SystemId;
        Assert.AreNotEqual('', ID2, 'ID should not be empty');

        // [WHEN] we DELETE the item from the web service, with the item's unique ID
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID1, PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);
        TargetURL := LibraryGraphMgt.CreateTargetURL(ID2, PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] the invoices shouldn't exist in the tables
        if PurchInvHeader.Get(InvoiceID1) then
            Assert.ExpectedError('The posted invoice should not exist');

        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, InvoiceID2) then
            Assert.ExpectedError('The unposted invoice should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateInvoiceThroughPageAndAPI()
    var
        PagePurchaseHeader: Record "Purchase Header";
        ApiPurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        ApiRecordRef: RecordRef;
        PageRecordRef: RecordRef;
        VendorNo: Text;
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

        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        InvoiceDate := WorkDate;

        // [GIVEN] a json describing our new invoice
        InvoiceWithComplexJSON := CreateInvoiceJSONWithAddress(Vendor, InvoiceDate);
        Commit();

        // [WHEN] we POST the JSON to the web service and create another invoice through the test page
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, InvoiceWithComplexJSON, ResponseText);

        CreateInvoiceThroughTestPage(PurchaseInvoice, Vendor, InvoiceDate);

        // [THEN] the invoice should exist in the table and match the invoice created from the page
        ApiPurchaseHeader.Reset();
        ApiPurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        ApiPurchaseHeader.SetRange("Document Type", ApiPurchaseHeader."Document Type"::Invoice);
        ApiPurchaseHeader.SetRange("Document Date", InvoiceDate);
        Assert.IsTrue(ApiPurchaseHeader.FindFirst, 'The unposted invoice should exist');

        // Ignore these fields when comparing Page and API Invoices
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiPurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        LibraryUtility.AddTempField(
          TempIgnoredFieldsForComparison, ApiPurchaseHeader.FieldNo("Posting Description"), DATABASE::"Purchase Header");
        LibraryUtility.AddTempField(TempIgnoredFieldsForComparison, ApiPurchaseHeader.FieldNo(Id), DATABASE::"Purchase Header");

        PagePurchaseHeader.Get(PagePurchaseHeader."Document Type"::Invoice, PurchaseInvoice."No.".Value);
        ApiRecordRef.GetTable(ApiPurchaseHeader);
        PageRecordRef.GetTable(PagePurchaseHeader);
        Assert.RecordsAreEqualExceptCertainFields(ApiRecordRef, PageRecordRef, TempIgnoredFieldsForComparison,
          'Page and API Invoice do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoDataIntegrationRecordIdsForInvoices()
    var
        IntegrationRecord: Record "Integration Record";
        PurchaseHeader: Record "Purchase Header";
        BlankGuid: Guid;
    begin
        // [SCENARIO 184722] Integration record ids should be set correctly.
        // [GIVEN] We have demo data applied correctly
        PurchaseHeader.SetRange(Id, BlankGuid);
        Assert.IsFalse(PurchaseHeader.FindFirst, 'No purchase headers should have null id');

        // [WHEN] We look through all purchase headers.
        // [THEN] The integration record for the purchase header should have the same record id.
        PurchaseHeader.Reset();
        if PurchaseHeader.Find('-') then begin
            repeat
                Assert.IsTrue(IntegrationRecord.Get(PurchaseHeader.SystemId), 'The PurchaseHeader id should exist in the integration record table');
                Assert.AreEqual(
                  IntegrationRecord."Record ID", PurchaseHeader.RecordId,
                  'The integration record for the PurchaseHeader should have the same record id as the PurchaseHeader.');
            until PurchaseHeader.Next <= 0
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceFailsWithoutVendorNoOrId()
    var
        Currency: Record Currency;
        ResponseText: Text;
        TargetURL: Text;
        InvoiceJSON: Text;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 184721] Create an invoice wihtout Vendor throws an error
        Initialize;

        // [GIVEN] a purchase invoice JSON with currency only
        Currency.SetFilter(Code, '<>%1', '');
        Currency.FindFirst;
        CurrencyCode := Currency.Code;
        InvoiceJSON := LibraryGraphMgt.AddPropertytoJSON('', 'currencyCode', CurrencyCode);
        Commit();

        // [WHEN] we POST the JSON to the web service
        // [THEN] an error is received
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Purchase Invoice Entity", InvoiceServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, InvoiceJSON, ResponseText);
    end;

    local procedure CreatePurchaseInvoices(var InvoiceID1: Text; var InvoiceID2: Text)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(WorkDate + 1);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        ModifyPurchaseHeaderPostingDate(PurchaseHeader, WorkDate);
        InvoiceID1 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        ModifyPurchaseHeaderPostingDate(PurchaseHeader, WorkDate);
        InvoiceID2 := PurchaseHeader."No.";
        Commit();
    end;

    local procedure CreateInvoiceJSONWithAddress(Vendor: Record Vendor; InvoiceDate: Date): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        InvoiceJSON: Text;
        ComplexTypeJSON: Text;
        InvoiceWithComplexJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, 'vendorNumber', Vendor."No.");
        JSONManagement.AddJPropertyToJObject(JObject, 'invoiceDate', InvoiceDate);
        InvoiceJSON := CreateInvoiceJSON('vendorNumber', Vendor."No.", 'invoiceDate', InvoiceDate);

        LibraryGraphDocumentTools.GetVendorAddressComplexType(ComplexTypeJSON, Vendor, false, false);
        InvoiceWithComplexJSON := LibraryGraphMgt.AddComplexTypetoJSON(InvoiceJSON, 'buyFromAddress', ComplexTypeJSON);
        exit(InvoiceWithComplexJSON);
    end;

    local procedure CreateInvoiceThroughTestPage(var PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor; DocumentDate: Date)
    begin
        PurchaseInvoice.OpenNew;
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");
        PurchaseInvoice."Document Date".SetValue(DocumentDate);
    end;

    local procedure ModifyPurchaseHeaderPostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure GetCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.SetFilter(Code, '<>%1', '');
        if Currency.FindFirst then
            exit(Currency.Code);
    end;

    local procedure CreateInvoiceJSON(PropertyName1: Text; PropertyValue1: Variant; PropetyName2: Text; PropertyValue2: Variant): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        InvoiceJSON: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JObject);

        JSONManagement.AddJPropertyToJObject(JObject, PropertyName1, PropertyValue1);
        JSONManagement.AddJPropertyToJObject(JObject, PropetyName2, PropertyValue2);
        InvoiceJSON := JSONManagement.WriteObjectToString;
        exit(InvoiceJSON);
    end;
}

