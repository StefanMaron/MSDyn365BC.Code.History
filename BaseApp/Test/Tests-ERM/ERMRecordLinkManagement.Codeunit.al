codeunit 134074 "ERM Record Link Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Record Link]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        RecordLinkCountErr: Label 'The only one record link expected';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Posted Sales Order with notification to a user produces record links without notification flag
        Initialize;

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader);
        VerifyNotificationOnRecordLink(SalesInvoiceHeader, false);
        // [THEN] Posted Sales Shipment has a note without notification ("Record Link".Notify = FALSE)
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader);
        VerifyNotificationOnRecordLink(SalesShipmentHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 375015] Posted Purchase Order with notification to a user produces record link without notification flag
        Initialize;

        // [GIVEN] Purchase Order with notification note ("Record Link".Notify = TRUE)
        CreatePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(PurchaseHeader, true);

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Purchase Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchInvHeader, false);
        // [THEN] Posted Purchase Receipt has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseReceiptHeader(PurchRcptHeader, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchRcptHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithNotification()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 375015] Posted Service Order with notification to a user produces record link without notification flag
        Initialize;

        // [GIVEN] Service Order with notification note ("Record Link".Notify = TRUE)
        UpdateServiceMgtSetup(true, true);
        CreateServiceOrder(ServiceHeader, ServiceHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(ServiceHeader, true);

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyNotificationOnRecordLink(ServiceInvoiceHeader, false);

        // [THEN] Posted Service Shipment has a note without notification ("Record Link".Notify = FALSE)
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader);
        VerifyNotificationOnRecordLink(ServiceShipmentHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveSalesOrderWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Archived Sales Order with notification to a user produces record links without notification flag
        Initialize;

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [WHEN] Archive Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [THEN] Archived Sales Order has a note without notification ("Record Link".Notify = FALSE)
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        VerifyNotificationOnRecordLink(SalesHeaderArchive, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrderWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 375015] Archived Purchase Order with notification to a user produces record link without notification flag
        Initialize;

        // [GIVEN] Purchase Order with notification note ("Record Link".Notify = TRUE)
        CreatePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(PurchaseHeader, true);

        // [WHEN] Archive Purchase Order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);

        // [THEN] Archived Purchase Order has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchaseHeaderArchive, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreSalesDocumentFromArchiveWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Restored from archive Sales Order with notification to a user produces record link without notification flag
        Initialize;

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [GIVEN] Archived Sales Order with note having notification flag
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        SetupNotificationOnRecordLink(SalesHeaderArchive, true);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Restore Sales Order
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // [THEN] Restored Sales Order has a note without notification ("Record Link".Notify = FALSE)
        SalesHeader.Find;
        VerifyNotificationOnRecordLink(SalesHeader, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Record Link Management");
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Record Link Management");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Record Link Management");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; DocumentType: Option)
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryInventory.CreateItem(Item);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."Item No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst;
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst;
    end;

    local procedure FindSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst;
    end;

    local procedure FindPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst;
    end;

    local procedure FindPurchaseReceiptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst;
    end;

    local procedure FindPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst;
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst;
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceShipmentHeader.FindFirst;
    end;

    local procedure SetupNotificationOnRecordLink(SourceRecord: Variant; NewNotification: Boolean)
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceRecord);
        RecRef.AddLink(LibraryUtility.GenerateGUID, LibraryUtility.GenerateGUID);
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst;
        RecordLink.Notify := NewNotification;
        RecordLink."To User ID" := UserId;
        RecordLink.Modify();
    end;

    local procedure UpdateServiceMgtSetup(CopyCommentsToInvoice: Boolean; CopyCommentsToShipment: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Copy Comments Order to Invoice" := CopyCommentsToInvoice;
        ServiceMgtSetup."Copy Comments Order to Shpt." := CopyCommentsToShipment;
        ServiceMgtSetup.Modify();
    end;

    local procedure VerifyNotificationOnRecordLink(RecVar: Variant; ExpectedNotification: Boolean)
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RecordLink.SetRange("To User ID", UserId);
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst;

        Assert.AreEqual(1, RecordLink.Count, RecordLinkCountErr);
        Assert.AreEqual(ExpectedNotification, RecordLink.Notify, RecordLink.FieldCaption(Notify));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

