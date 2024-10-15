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
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestO365CustomerEdit()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] A user with O365 Basic and Customer Edit permissions
        Initialize;
        LibraryLowerPermissions.SetCustomerEdit;
        ExcludedTables := ExcludedTables.List;
        InsertTablesExcludedFromCustomerCreate(ExcludedTables);

        // [THEN] The user can insert/delete Customers
        RecordRef.Open(DATABASE::Customer);
        LibraryPermissionsVerify.VerifyWritePermissionTrue(RecordRef);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetOutsideO365Scope;
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
        LibraryLowerPermissions.SetOutsideO365Scope;
        Initialize;

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

    [Test]
    [HandlerFunctions('PostedSalesShipmentEditOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedSalesShipmentEditFromCard()
    var
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Open "Posted Sales Shipment - Edit" from "Posted Sales Shipment" card with "D365 Sales Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Sales Doc, Edit" permission set.
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Open "Posted Sales Shipment - Edit" page from "Posted Sales Shipment" card.
        PostedSalesShipment.OpenView;
        PostedSalesShipment."Update Document".Invoke;

        // [THEN] "Posted Sales Shipment - Edit" opens.
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentEditOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedSalesShipmentEditFromList()
    var
        PostedSalesShipments: TestPage "Posted Sales Shipments";
    begin
        // [FEATURE] [Sales Shipment]
        // [SCENARIO 308913] Open "Posted Sales Shipment - Edit" from "Posted Sales Shipments" list with "D365 Sales Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Sales Doc, Edit" permission set.
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Open "Posted Sales Shipment - Edit" page from "Posted Sales Shipments" list.
        PostedSalesShipments.OpenView;
        PostedSalesShipments."Update Document".Invoke;

        // [THEN] "Posted Sales Shipment - Edit" opens.
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptEditOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnReceiptEditFromCard()
    var
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Open "Posted Return Receipt - Edit" from "Posted Return Receipt" card with "D365 Sales Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Sales Doc, Edit" permission set.
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Open "Posted Return Receipt - Edit" page from "Posted Return Receipt" card.
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt."Update Document".Invoke;

        // [THEN] "Posted Return Receipt - Edit" opens.
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptEditOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnReceiptEditFromList()
    var
        PostedReturnReceipts: TestPage "Posted Return Receipts";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 308913] Open "Posted Return Receipt - Edit" from "Posted Return Receipts" list with "D365 Sales Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Sales Doc, Edit" permission set.
        LibraryLowerPermissions.SetSalesDocsCreate;

        // [WHEN] Open "Posted Return Receipt - Edit" page from "Posted Return Receipts" list.
        PostedReturnReceipts.OpenView;
        PostedReturnReceipts."Update Document".Invoke;

        // [THEN] "Posted Return Receipt - Edit" opens.
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // mandatory fields for Customer creation
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Customer Nos." := NoSeries.Code;
        SalesReceivablesSetup.Modify(true);

        MarketingSetup.Get;
        MarketingSetup."Contact Nos." := NoSeries.Code;
        MarketingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromCustomerView(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Customer view scenario, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
        ExcludedTables.Add(DATABASE::"Type of Supply");
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromCustomerCreate(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Customer creation, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
        ExcludedTables.Add(DATABASE::"Type of Supply");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentEditOKModalPageHandler(var PostedSalesShipmentEdit: TestPage "Posted Sales Shipment - Update")
    begin
        PostedSalesShipmentEdit.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptEditOKModalPageHandler(var PostedReturnReceiptEdit: TestPage "Posted Return Receipt - Update")
    begin
        PostedReturnReceiptEdit.OK.Invoke;
    end;
}

