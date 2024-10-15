codeunit 132599 "ODataUtility Test"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ODataUtilityTest: Codeunit "ODataUtility Test";
        IsInitialized: Boolean;
        EventServiceName: Text[240];
        WebServiceHasBeenDisabledErr: Label 'You can''t edit this page in Excel because it''s not set up for it. To use the Edit in Excel feature, you must publish the web service called ''%1''. Contact your system administrator for help.', Comment = '%1 = Web service name';

    [Test]
    procedure TestEditWorksheetInExcelCreatesWebService()
    var
        TenantWebService: Record "Tenant Web Service";
        PaymentReconciliationJournal: Page "Payment Reconciliation Journal";
        ODataUtility: Codeunit ODataUtility;
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", Page::"Payment Reconciliation Journal");
        TenantWebService.DeleteAll();

        LibraryLowerPermissions.SetO365Basic();
        ODataUtility.EditWorksheetInExcel(PaymentReconciliationJournal.Caption, PaymentReconciliationJournal.ObjectId(false), '');

        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.RecordCount(TenantWebService, 1);
        TenantWebService.FindFirst();
        Assert.AreEqual(PaymentReconciliationJournal.Caption + '_Excel', TenantWebService."Service Name", 'The tenant web service has incorrect name');
    end;

    [Test]
    procedure TestEditWorksheetInExcelDisabledWebService()
    var
        TenantWebService: Record "Tenant Web Service";
        PaymentReconciliationJournal: Page "Payment Reconciliation Journal";
        ODataUtility: Codeunit ODataUtility;
        CreatedServiceName: Text[240];
    begin
        Init();

        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", Page::"Payment Reconciliation Journal");
        TenantWebService.DeleteAll();
        CreatedServiceName := 'TestServiceName';
        InsertTenantWebService(Page::"Payment Reconciliation Journal", CreatedServiceName, false, false, false);

        LibraryLowerPermissions.SetO365Basic();
        asserterror ODataUtility.EditWorksheetInExcel(PaymentReconciliationJournal.Caption, PaymentReconciliationJournal.ObjectId(false), '');
        Assert.ExpectedError(StrSubstNo(WebServiceHasBeenDisabledErr, CreatedServiceName));
    end;

    [Test]
    procedure TestEditWorksheetInExcelReuseWebService()
    var
        TenantWebService: Record "Tenant Web Service";
        PaymentReconciliationJournal: Page "Payment Reconciliation Journal";
        ODataUtility: Codeunit ODataUtility;
        CreatedServiceName: Text[240];
    begin
        Init();

        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", Page::"Payment Reconciliation Journal");
        TenantWebService.DeleteAll();
        CreatedServiceName := 'TestServiceName';
        InsertTenantWebService(Page::"Payment Reconciliation Journal", CreatedServiceName, false, false, true);

        LibraryLowerPermissions.SetO365Basic();
        ODataUtility.EditWorksheetInExcel(PaymentReconciliationJournal.Caption, PaymentReconciliationJournal.ObjectId(false), '');

        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.RecordCount(TenantWebService, 1);
        TenantWebService.FindFirst();
        Assert.AreEqual(CreatedServiceName, TenantWebService."Service Name", 'The tenant web service name has changed');
        Assert.AreEqual(CreatedServiceName, ODataUtilityTest.GetServiceName(), 'The service name given to the edit in excel event is incorrect');
    end;

    [Test]
    procedure TestEditWorksheetInExcelReuseSpecificWebService()
    var
        TenantWebService: Record "Tenant Web Service";
        PaymentReconciliationJournal: Page "Payment Reconciliation Journal";
        ODataUtility: Codeunit ODataUtility;
        CreatedServiceName: Text[240];
    begin
        Init();

        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", Page::"Payment Reconciliation Journal");
        TenantWebService.DeleteAll();
        CreatedServiceName := PaymentReconciliationJournal.Caption + '_Excel';
        InsertTenantWebService(Page::"Payment Reconciliation Journal", 'aaa', true, true, true);
        InsertTenantWebService(Page::"Payment Reconciliation Journal", CreatedServiceName, false, false, true);
        InsertTenantWebService(Page::"Payment Reconciliation Journal", 'zzz', true, true, true);

        LibraryLowerPermissions.SetO365Basic();
        ODataUtility.EditWorksheetInExcel(PaymentReconciliationJournal.Caption, PaymentReconciliationJournal.ObjectId(false), '');

        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.RecordCount(TenantWebService, 3);
        Assert.AreEqual(CreatedServiceName, ODataUtilityTest.GetServiceName(), 'The service name used is wrong'); // if there's a service called pageCaption_Excel then always use that one
    end;

    procedure GetServiceName(): Text[240]
    begin
        exit(EventServiceName);
    end;

    local procedure Init()
    begin
        if IsInitialized then
            exit;

        Assert.IsTrue(BindSubscription(ODataUtilityTest), 'Could not bind events');
        IsInitialized := true;
    end;

    local procedure InsertTenantWebService(PageId: Integer; ServiceName: Text[240]; ExcludeFieldsOutsideRepeater: Boolean; ExcludeNonEditableFlowFields: Boolean; Publish: Boolean)
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        TenantWebService.Validate("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.Validate("Object ID", PageId);
        TenantWebService.Validate(ExcludeFieldsOutsideRepeater, ExcludeFieldsOutsideRepeater);
        TenantWebService.Validate(ExcludeNonEditableFlowFields, ExcludeNonEditableFlowFields);
        TenantWebService.Validate("Service Name", ServiceName);
        TenantWebService.Validate(Published, Publish);
        TenantWebService.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ODataUtility, 'OnEditInExcelWithSearch', '', false, false)]
    local procedure OnEditInExcelWithSearch(ServiceName: Text[240])
    begin
        EventServiceName := ServiceName;
    end;
}

