codeunit 139453 "O365 Customer Permission Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Permissions]
    end;

    var
        LibraryPermissionsVerify: Codeunit "Library - Permissions Verify";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedSalesShipmentUpdateFromCard()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Edit Posted Sales Shipment with "Posted Sales Shipment - Update" from "Posted Sales Shipment" card with "D365 Sales Doc, Post" permission set.
        Initialize();
        CreateAndPostSalesOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Package Tracking No."

        // [GIVEN] A user with "D365 Sales Doc, Post" permission set.
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Open "Posted Sales Shipment - Update" page from "Posted Sales Shipment" card. Set new value for "Package Tracking No.", press OK.
        PostedSalesShipment.OpenView();
        PostedSalesShipment."Update Document".Invoke();

        // [THEN] "Posted Sales Shipment - Update" opens, Posted Sales Shipment is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedSalesShipmentUpdateFromList()
    var
        PostedSalesShipments: TestPage "Posted Sales Shipments";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Edit Posted Sales Shipment with "Posted Sales Shipment - Update" from "Posted Sales Shipment" list with "D365 Sales Doc, Post" permission set.
        Initialize();
        CreateAndPostSalesOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Package Tracking No."

        // [GIVEN] A user with "D365 Sales Doc, Post" permission set.
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Open "Posted Sales Shipment - Update" page from "Posted Sales Shipments" list. Set new value for "Package Tracking No.", press OK.
        PostedSalesShipments.OpenView();
        PostedSalesShipments."Update Document".Invoke();

        // [THEN] "Posted Sales Shipment - Update" opens, Posted Sales Shipment is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnReceiptUpdateFromCard()
    var
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Edit Posted Return Receipt with "Posted Return Receipt - Update" from "Posted Return Receipt" card with "D365 Sales Doc, Post" permission set.
        Initialize();
        CreateAndPostSalesReturnOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Package Tracking No."

        // [GIVEN] A user with "D365 Sales Doc, Post" permission set.
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Open "Posted Return Receipt - Update" page from "Posted Return Receipt" card. Set new value for "Package Tracking No.", press OK.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt."Update Document".Invoke();

        // [THEN] "Posted Return Receipt - Update" opens, Posted Return Receipt is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnReceiptUpdateFromList()
    var
        PostedReturnReceipts: TestPage "Posted Return Receipts";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Edit Posted Return Receipt with "Posted Return Receipt - Update" from "Posted Return Receipts" list with "D365 Sales Doc, Post" permission set.
        Initialize();
        CreateAndPostSalesReturnOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Package Tracking No."

        // [GIVEN] A user with "D365 Sales Doc, Post" permission set.
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Open "Posted Return Receipt - Update" page from "Posted Return Receipts" list. Set new value for "Package Tracking No.", press OK.
        PostedReturnReceipts.OpenView();
        PostedReturnReceipts."Update Document".Invoke();

        // [THEN] "Posted Return Receipt - Update" opens, Posted Return Receipt is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedServiceShptUpdateFromCard()
    var
        PostedServiceShipment: TestPage "Posted Service Shipment";
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] Edit Posted Service Shipment with "Posted Service Shpt. - Update" from "Posted Service Shipment" card with "D365PREM SMG, VIEW" permission set.
        Initialize();
        CreateAndPostServiceOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Additional Information"

        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set.
        LibraryLowerPermissions.SetO365ServiceMgtRead();

        // [WHEN] Open "Posted Service Shpt. - Update" page from "Posted Service Shipment" card. Set new value for "Additional Information", press OK.
        PostedServiceShipment.OpenView();
        PostedServiceShipment."Update Document".Invoke();

        // [THEN] "Posted Service Shpt. - Update" opens, Posted Service Shipment is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedServiceShptUpdateFromList()
    var
        PostedServiceShipments: TestPage "Posted Service Shipments";
    begin
        // [FEATURE] [Service Shipment]
        // [SCENARIO 308913] Edit Posted Service Shipment with "Posted Service Shpt. - Update" from "Posted Service Shipments" list with "D365PREM SMG, VIEW" permission set.
        Initialize();
        CreateAndPostServiceOrder();
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());  // "Additional Information"

        // [GIVEN] A user with "D365PREM SMG, VIEW" permission set.
        LibraryLowerPermissions.SetO365ServiceMgtRead();

        // [WHEN] Open "Posted Service Shpt. - Update" page from "Posted Service Shipments" list. Set new value for "Additional Information", press OK.
        PostedServiceShipments.OpenView();
        PostedServiceShipments."Update Document".Invoke();

        // [THEN] "Posted Service Shpt. - Update" opens, Posted Service Shipment is updated.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestO365CustomerEdit()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // Test was moved to the end of the codeunit, because LibraryPermissionsVerify.CreateRecWithRelatedFields() removes demo data.

        // [GIVEN] A user with O365 Basic and Customer Edit permissions
        Initialize();
        LibraryLowerPermissions.SetCustomerEdit;
        ExcludedTables := ExcludedTables.List;
        InsertTablesExcludedFromCustomerCreate(ExcludedTables);

        // [THEN] The user can insert/delete Customers
        RecordRef.Open(DATABASE::Customer);
        LibraryPermissionsVerify.VerifyWritePermissionTrue(RecordRef);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetOutsideO365Scope();
        RecordRefWithAllRelations.Open(DATABASE::Customer);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestO365CustomerView()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] An Customer with related records and a user with O365 Basic and Customer View
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        RecordRefWithAllRelations.Open(DATABASE::Customer);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        ExcludedTables := ExcludedTables.List;
        InsertTablesExcludedFromCustomerView(ExcludedTables);

        LibraryLowerPermissions.SetCustomerView;
        RecordRef.Open(DATABASE::Customer);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetCustomerView;
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        MarketingSetup: Record "Marketing Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Customer Permission Test");
        LibraryUtility.GetGlobalNoSeriesCode();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        // mandatory fields for Customer creation
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify(true);

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify(true);

        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(Database::"Marketing Setup");

        Commit();
        IsInitialized := true;
    end;

    local procedure CreateAndPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostServiceOrder() OrderNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        OrderNo := ServiceHeader."No.";
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromCustomerView(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Customer view scenario, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromCustomerCreate(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Customer creation, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentUpdateOKModalPageHandler(var PostedSalesShipmentUpdate: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesShipmentUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptUpdateOKModalPageHandler(var PostedReturnReceiptUpdate: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptUpdate."Package Tracking No.".SetValue(LibraryVariableStorage.DequeueText());
        PostedReturnReceiptUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceShptUpdateOKModalPageHandler(var PostedServiceShptUpdate: TestPage "Posted Service Shpt. - Update")
    begin
        PostedServiceShptUpdate."Additional Information".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceShptUpdate.OK().Invoke();
    end;
}

