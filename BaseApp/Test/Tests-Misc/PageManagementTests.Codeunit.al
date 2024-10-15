codeunit 135001 "Page Management Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Page Management]
    end;

    var
        Assert: Codeunit Assert;
        WrongPageCaptionErr: Label 'Wrong page caption';
        PageManagement: Codeunit "Page Management";
        WrongPageErr: Label 'Wrong page ID for table %1';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecord()
    var
        CompanyInformation: Record "Company Information";
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when record is provided to GetPageID
        // [GIVEN] A Record, which has a user defined page id
        CompanyInformation.Get();

        // [WHEN] The GetPageID function is called with that record
        PageID := PageManagement.GetPageID(CompanyInformation);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecordRef()
    var
        CIRecordRef: RecordRef;
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when RecordRef is provided to GetPageID
        // [GIVEN] A RecordRef, which has a user defined page id
        CIRecordRef.Open(DATABASE::"Company Information");
        CIRecordRef.FindFirst();

        // [WHEN] The GetPageID function is called with that RecordRef
        PageID := PageManagement.GetPageID(CIRecordRef);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecordID()
    var
        CIRecordRef: RecordRef;
        RecordID: RecordID;
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when RecordID is provided to GetPageID
        // [GIVEN] A RecordID, which has a user defined page id
        CIRecordRef.Open(DATABASE::"Company Information");
        CIRecordRef.FindFirst();
        RecordID := CIRecordRef.RecordId;

        // [WHEN] The GetPageID function is called with that RecordID
        PageID := PageManagement.GetPageID(RecordID);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecord()
    var
        Customer: Record Customer;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when Record is provided to GetPageID
        // [GIVEN] A Record, which has a metadata page id
        Customer.FindLast();

        // [WHEN] The GetPageID function is called with that record
        PageID := PageManagement.GetPageID(Customer);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Customer Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecordRef()
    var
        Item: Record Item;
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when RecordRef is provided to GetPageID
        // [GIVEN] A RecordRef, which has a metadata page id
        Item.SetFilter(Description, '<>%1', '');
        Item.FindFirst();
        DataTypeManagement.GetRecordRef(Item, RecordRef);

        // [WHEN] The GetPageID function is called with that RecordRef
        PageID := PageManagement.GetPageID(RecordRef);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Item Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecordID()
    var
        VendorRecordRef: RecordRef;
        RecordID: RecordID;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when RecordID is provided to GetPageID
        // [GIVEN] A RecordID, which has a metadata page id
        VendorRecordRef.Open(DATABASE::Vendor);
        VendorRecordRef.FindFirst();
        RecordID := VendorRecordRef.RecordId;

        // [WHEN] The GetPageID function is called with that RecordID
        PageID := PageManagement.GetPageID(RecordID);

        // [THEN] The correct page id is returned
        Assert.AreEqual(PAGE::"Vendor Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the sales order
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert();

        // [WHEN] The GetPageID function is called for a sales order
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales Order" page id is returned
        Assert.AreEqual(PAGE::"Sales Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the purchase quote
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader.Insert();

        // [WHEN] The GetPageID function is called for a purchase qoute
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase Quote" page id is returned
        Assert.AreEqual(PAGE::"Purchase Quote", PageID, '');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestGetPageIDForServiceInvHeader()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        LibraryUtility: Codeunit "Library - Utility";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the "Service Invoice Header" record
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateRandomCode(ServiceInvoiceHeader.FieldNo("No."),
            DATABASE::"Service Invoice Header");
        ServiceInvoiceHeader.Insert();

        // [WHEN] The GetPageID function is called for a service invoice header
        PageID := PageManagement.GetPageID(ServiceInvoiceHeader);

        // [THEN] "Posted Service Invoice" page id is returned
        Assert.AreEqual(PAGE::"Posted Service Invoice", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForTableID()
    var
        PageID: Integer;
    begin
        // [SCENARIO] The meta data list page ID is returned when Table ID is provided

        // [WHEN] The GetDefaultListPageID function is called with that table ID
        PageID := PageManagement.GetDefaultLookupPageID(DATABASE::Customer);

        // [THEN] The correct list page id is returned
        Assert.AreEqual(PAGE::"Customer Lookup", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageCaptionCustomerCard()
    var
        CustomerCard: Page "Customer Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] Function GetPageCaption should return caption of the "Customer Card" page for page ID = 21

        Assert.AreEqual(CustomerCard.Caption, PageManagement.GetPageCaption(PAGE::"Customer Card"), WrongPageCaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageCaptionNonExistingPage()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] Function GetPageCaption should return empty string for page ID = 0

        Assert.AreEqual('', PageManagement.GetPageCaption(0), WrongPageCaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDSimulatedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Simulated Production Order" page for simulated production order

        ProductionOrder.Status := ProductionOrder.Status::Simulated;
        Assert.AreEqual(
          PAGE::"Simulated Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Planned Production Order" page for planned production order

        ProductionOrder.Status := ProductionOrder.Status::Planned;
        Assert.AreEqual(
          PAGE::"Planned Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Firm Planned Prod. Order" page for firm planned production order

        ProductionOrder.Status := ProductionOrder.Status::"Firm Planned";
        Assert.AreEqual(
          PAGE::"Firm Planned Prod. Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDReleaseProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Released Production Order" page for released production order

        ProductionOrder.Status := ProductionOrder.Status::Released;
        Assert.AreEqual(
          PAGE::"Released Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDFinishedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Finished Production Order" page for finished production order

        ProductionOrder.Status := ProductionOrder.Status::Finished;
        Assert.AreEqual(
          PAGE::"Finished Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;
}

