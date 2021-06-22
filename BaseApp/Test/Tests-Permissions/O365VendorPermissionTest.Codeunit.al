codeunit 139452 "O365 Vendor Permission Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [O365] [Permissions] [Vendor]
    end;

    var
        LibraryPermissionsVerify: Codeunit "Library - Permissions Verify";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestO365VendorEdit()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] A user with O365 Basic and Vendor Edit permissions
        Initialize;
        LibraryLowerPermissions.SetVendorEdit;
        ExcludedTables := ExcludedTables.List;
        InsertTablesExcludedFromVendorCreate(ExcludedTables);

        // [THEN] The user can insert/delete Vendors
        RecordRef.Open(DATABASE::Vendor);
        LibraryPermissionsVerify.VerifyWritePermissionTrue(RecordRef);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetOutsideO365Scope;
        RecordRefWithAllRelations.Open(DATABASE::Vendor);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestO365VendorView()
    var
        ExcludedTables: DotNet GenericList1;
        RecordRef: RecordRef;
        RecordRefWithAllRelations: RecordRef;
    begin
        // [GIVEN] An Vendor with related records and a user with O365 Basic and Vendor View
        LibraryLowerPermissions.SetOutsideO365Scope;
        Initialize;

        RecordRefWithAllRelations.Open(DATABASE::Vendor);
        LibraryPermissionsVerify.CreateRecWithRelatedFields(RecordRefWithAllRelations);
        ExcludedTables := ExcludedTables.List;
        InsertTablesExcludedFromVendorView(ExcludedTables);

        LibraryLowerPermissions.SetVendorView;
        RecordRef.Open(DATABASE::Vendor);

        // [THEN] The user can read from the record and related tables
        LibraryLowerPermissions.SetVendorView;
        LibraryPermissionsVerify.CheckReadAccessToRelatedTables(ExcludedTables, RecordRef);
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedPurchInvoiceUpdateFromCard()
    var
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] Open "Posted Purch. Invoice - Update" from "Posted Purchase Invoice" card with "D365 Purch Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Purch Doc, Edit" permission set.
        LibraryLowerPermissions.SetPurchDocsCreate;

        // [WHEN] Open "Posted Purch. Invoice - Update" page from "Posted Purchase Invoice" card.
        PostedPurchaseInvoice.OpenView;
        PostedPurchaseInvoice."Update Document".Invoke;

        // [THEN] "Posted Purch. Invoice - Update" opens.
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoiceUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedPurchInvoiceUpdateFromList()
    var
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 308913] Open "Posted Purch. Invoice - Update" from "Posted Purchase Invoices" list with "D365 Purch Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Purch Doc, Edit" permission set.
        LibraryLowerPermissions.SetPurchDocsCreate;

        // [WHEN] Open "Posted Purch. Invoice - Update" page from "Posted Purchase Invoices" list.
        PostedPurchaseInvoices.OpenView;
        PostedPurchaseInvoices."Update Document".Invoke;

        // [THEN] "Posted Purch. Invoice - Update" opens.
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnShptUpdateFromCard()
    var
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] Open "Posted Return Shpt. - Update" from "Posted Return Shipment" card with "D365 Purch Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Purch Doc, Edit" permission set.
        LibraryLowerPermissions.SetPurchDocsCreate;

        // [WHEN] Open "Posted Return Shpt. - Update" page from "Posted Return Shipment" card.
        PostedReturnShipment.OpenView;
        PostedReturnShipment."Update Document".Invoke;

        // [THEN] "Posted Return Shpt. - Update" opens.
    end;

    [Test]
    [HandlerFunctions('PostedReturnShptUpdateOKModalPageHandler')]
    [Scope('OnPrem')]
    procedure RunPostedReturnShptUpdateFromList()
    var
        PostedReturnShipments: TestPage "Posted Return Shipments";
    begin
        // [FEATURE] [Return Shipment]
        // [SCENARIO 308913] Open "Posted Return Shpt. - Update" from "Posted Return Shipments" list with "D365 Purch Doc, Edit".
        Initialize;

        // [GIVEN] A user with "D365 Purch Doc, Edit" permission set.
        LibraryLowerPermissions.SetPurchDocsCreate;

        // [WHEN] Open "Posted Return Shpt. - Update" page from "Posted Return Shipments" list.
        PostedReturnShipments.OpenView;
        PostedReturnShipments."Update Document".Invoke;

        // [THEN] "Posted Return Shpt. - Update" opens.
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        // mandatory fields for Vendor creation
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Vendor Nos." := NoSeries.Code;
        PurchasesPayablesSetup.Modify(true);

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := NoSeries.Code;
        MarketingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromVendorView(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Vendor view scenario, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
    end;

    [Scope('OnPrem')]
    procedure InsertTablesExcludedFromVendorCreate(var ExcludedTables: DotNet GenericList1)
    begin
        // list of tables important for Vendor creation, but tables are not in O365 permissionsets
        ExcludedTables.Add(DATABASE::"IC Partner");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceUpdateOKModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnShptUpdateOKModalPageHandler(var PostedReturnShptUpdate: TestPage "Posted Return Shpt. - Update")
    begin
        PostedReturnShptUpdate.OK.Invoke;
    end;
}

