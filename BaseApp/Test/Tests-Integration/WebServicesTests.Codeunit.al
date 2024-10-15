codeunit 139002 "Web Services Tests"
{
    Permissions = TableData "Web Service" = rimd,
                  TableData "Tenant Web Service" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Web Service] [UI]
    end;

    var
        PageServiceTxt: Label 'PageService';
        CodeunitServiceTxt: Label 'CodeunitService';
        QueryServiceTxt: Label 'QueryService';
        Assert: Codeunit Assert;
        Initialized: Boolean;
        UnpublishedPageTxt: Label 'UnpublishedPage';
        PageATxt: Label 'PageA';
        PageBTxt: Label 'PageB';
        PageCTxt: Label 'PageC';
        PageDTxt: Label 'PageD';
        PageETxt: Label 'PageE';
        PageFTxt: Label 'PageF';
        PageGTxt: Label 'PageG';
        PageHTxt: Label 'PageH';
        PageITxt: Label 'PageI';
        PageJTxt: Label 'PageJ';
        PageKTxt: Label 'PageK';
        PageLTxt: Label 'PageL';
        PageMTxt: Label 'PageM';
        PageNTxt: Label 'PageN';
        PageOTxt: Label 'PageO';
        PagePTxt: Label 'PageP';
        PageQTxt: Label 'PageQ';

    [Test]
    [Scope('OnPrem')]
    procedure TestUrlsAreSet()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Tests that the Urls are displayed on the Web Services page depending on the
        // Service type (OData vs SOAP).

        Initialize();
        WebServicesPage.OpenView;

        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageServiceTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageServiceTxt);

        WebServicesPage.GotoKey(WebService."Object Type"::Query, QueryServiceTxt);
        VerifyUrlMissingServiceName(WebServicesPage.SOAPUrl.Value, QueryServiceTxt);

        WebServicesPage.GotoKey(WebService."Object Type"::Codeunit, CodeunitServiceTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, CodeunitServiceTxt);

        WebServicesPage.GotoKey(WebService."Object Type"::Page, UnpublishedPageTxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, 'SOAP Url should be empty when not published: ' + CodeunitServiceTxt);

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithNoTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with no corresponding tenant
        // level service is correctly displayed.

        // System:     Page    PageA   n   true
        // Tenant:

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageATxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageATxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageATxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageATxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithMatchingPublishedTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding published
        // tenant level service is correctly displayed.

        // System:     Page    PageB   n   true
        // Tenant:     Page    PageB   n   true

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageBTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageBTxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageBTxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageBTxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonPublishedAppServiceWithMatchingPublishedTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a non-published application level service with a corresponding published
        // tenant level service is correctly displayed.

        // System:     Page    PageC   n   false
        // Tenant:     Page    PageC   n   true

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageCTxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, PageCTxt + ' web service record "SOAP Url" should be empty.');
        Assert.IsFalse(WebServicesPage.Published.AsBoolean, PageCTxt + ' web service record "Published" field should not be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageCTxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithMatchingNonPublishedTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding non-published
        // tenant level service is correctly displayed.

        // System:     Page    PageD   n   true
        // Tenant:     Page    PageD   n   false

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageDTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageDTxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageDTxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageDTxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithMatchingLessIDNonPublishedTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding non-published
        // tenant level service (but with different object IDs) is correctly displayed.

        // System:     Page    PageE   n    true
        // Tenant:     Page    PageE   n1   false

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageETxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageETxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageETxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageETxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithMatchingLessIDPublishedTenantService()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding published
        // tenant level service (but with different object IDs) is correctly displayed.

        // System:     Page    PageF   n    true
        // Tenant:     Page    PageF   n1   true

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageFTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageFTxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageFTxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageFTxt + ' all tenants should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisallowedAppServiceObject()
    var
        WebService: Record "Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that disallowed application objects are correctly displayed.

        // System:     Page    PageH   n    false   (Page.n may not be published)
        // System:     Page    PageI   n    true    (Previous record still 'wins')
        // Tenant:     Page    PageH   n    true
        // Tenant:     Page    PageI   n    true
        // Tenant:     Page    PageJ   n    true

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageHTxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, 'SOAP Url should be empty when not published: ' + PageHTxt);
        Assert.IsFalse(WebServicesPage.Published.AsBoolean, PageHTxt + ' web service record "Published" field should not be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageHTxt + ' all tenants should be checked.');

        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageITxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, 'SOAP Url should be empty when not published: ' + PageITxt);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, PageITxt + ' web service record "Published" field should be checked.');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, PageITxt + ' all tenants should be checked.');

        Assert.IsFalse(WebServicesPage.GotoKey(WebService."Object Type"::Page, PageJTxt), PageJTxt + ' should not be displayed.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedTenantService()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published tenant level service is correctly displayed.

        // System:
        // Tenant:     Page    PageL   n    true
        // Tenant:     Page    PageM   n1   false

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageLTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageLTxt);
        Assert.IsTrue(
          WebServicesPage.Published.AsBoolean, PageLTxt + ' web service record "Published" field should be checked.');

        WebServicesPage.GotoKey(TenantWebService."Object Type"::Page, PageMTxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, PageMTxt + ' web service record "SOAP Url" should be empty.');
        Assert.IsFalse(
          WebServicesPage.Published.AsBoolean, PageMTxt + ' web service record "Published" field should not be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithPublishedTenantService()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding published
        // tenant level service (but with different service names) is correctly displayed.

        // System:     Page    PageN   n    true
        // Tenant:     Page    PageO   n    true

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PageNTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageNTxt);
        Assert.IsTrue(
          WebServicesPage.Published.AsBoolean, PageNTxt + ' web service record "Published" field should be checked.');

        WebServicesPage.GotoKey(TenantWebService."Object Type"::Page, PageOTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PageOTxt);
        Assert.IsTrue(
          WebServicesPage.Published.AsBoolean, PageOTxt + ' web service record "Published" field should be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPublishedAppServiceWithNonPublishedTenantService()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that a published application level service with a corresponding non published
        // tenant level service (but with different service names) is correctly displayed.

        // System:     Page    PageP   n    true
        // Tenant:     Page    PageQ   n    false

        Initialize();
        WebServicesPage.OpenView;

        // Verify Web Service
        WebServicesPage.GotoKey(WebService."Object Type"::Page, PagePTxt);
        VerifyUrlHasServiceName(WebServicesPage.SOAPUrl.Value, PagePTxt);
        Assert.IsTrue(
          WebServicesPage.Published.AsBoolean, PagePTxt + ' web service record "Published" field should be checked.');

        WebServicesPage.GotoKey(TenantWebService."Object Type"::Page, PageQTxt);
        Assert.AreEqual('', WebServicesPage.SOAPUrl.Value, PageQTxt + ' web service record "SOAP Url" should be empty.');
        Assert.IsFalse(
          WebServicesPage.Published.AsBoolean, PageQTxt + ' web service record "Published" field should not be checked.');

        WebServicesPage.Close();
    end;

    local procedure Initialize()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
    begin
        if Initialized then
            exit;

        Initialized := true;

        with WebService do begin
            DeleteAll();

            // Add a Page for both OData and SOAP.
            Init();
            "Object Type" := "Object Type"::Page;
            "Service Name" := PageServiceTxt;
            "Object ID" := PAGE::"Customer List";
            Published := true;
            Insert();

            // Add a Codeunit for SOAP.
            Init();
            "Object Type" := "Object Type"::Codeunit;
            "Service Name" := CodeunitServiceTxt;
            "Object ID" := CODEUNIT::"CustVendBank-Update";
            Published := true;
            Insert();

            // Add a Query for OData.
            Init();
            "Object Type" := "Object Type"::Query;
            "Service Name" := QueryServiceTxt;
            "Object ID" := QUERY::"My Customers";
            Published := true;
            Insert();

            // Add an unpublished Page.
            Init();
            "Object Type" := "Object Type"::Page;
            "Service Name" := UnpublishedPageTxt;
            "Object ID" := PAGE::"Customer Ledger Entries";
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Company Information";
            "Service Name" := PageATxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Payment Terms";
            "Service Name" := PageBTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::Currencies;
            "Service Name" := PageCTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Finance Charge Terms";
            "Service Name" := PageDTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Customer Price Groups";
            "Service Name" := PageETxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::Languages;
            "Service Name" := PageFTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Chart of Accounts";
            "Service Name" := PageGTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Vendor Card";
            "Service Name" := PageHTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Vendor Card";
            "Service Name" := PageITxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Resource Groups";
            "Service Name" := PageKTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Job Card";
            "Service Name" := PageNTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Job List";
            "Service Name" := PagePTxt;
            Published := true;
            Insert();
        end;

        with TenantWebService do begin
            DeleteAll();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Payment Terms";
            "Service Name" := PageBTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::Currencies;
            "Service Name" := PageCTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Finance Charge Terms";
            "Service Name" := PageDTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Standard Text Codes";
            "Service Name" := PageETxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Countries/Regions";
            "Service Name" := PageFTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Chart of Accounts";
            "Service Name" := PageGTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Vendor Card";
            "Service Name" := PageHTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Vendor Card";
            "Service Name" := PageITxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Vendor Card";
            "Service Name" := PageJTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Resource Groups";
            "Service Name" := PageKTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Printer Selections";
            "Service Name" := PageLTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Rounding Methods";
            "Service Name" := PageMTxt;
            Published := false;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Job Card";
            "Service Name" := PageOTxt;
            Published := true;
            Insert();

            Init();
            "Object Type" := "Object Type"::Page;
            "Object ID" := PAGE::"Job List";
            "Service Name" := PageQTxt;
            Published := false;
            Insert();
        end;
    end;

    local procedure VerifyUrlHasServiceName(Url: Text; ServiceName: Text[240])
    begin
        Assert.IsTrue(
          StrPos(Url, ServiceName) > 1,
          StrSubstNo('Url was ''%1'' but should be populated and contain ServiceName ''%2''.', Url, ServiceName))
    end;

    local procedure VerifyUrlMissingServiceName(Url: Text; ServiceName: Text[240])
    begin
        Assert.AreEqual('Not applicable', Url, StrSubstNo('Url was ''%1'' but should be "Not applicable" for ''%2''.', Url, ServiceName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAllTenantsDefault()
    var
        WebServicesPage: TestPage "Web Services";
    begin
        // Test that the all tenants checkbox defaults to selected (and is enabled) if the tenant has write permissions
        // to the application database.
        WebServicesPage.OpenView;
        WebServicesPage.New;

        // Verify Web Service
        Assert.IsTrue(WebServicesPage."All Tenants".Enabled, 'All tenants should be enabled when user can write to app db');
        Assert.IsTrue(WebServicesPage."All Tenants".AsBoolean, 'All tenants should default checked when user can write to app db');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyUnselectAllTenants()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
        AutoServiceName: Text[240];
    begin
        // Test unselecting the all tenants checkbox will remove the system record and add a tenant record
        // if one doesn't already exist.
        AutoServiceName := CreateGuid();

        WebService.Init();
        WebService."Object Type" := WebService."Object Type"::Page;
        WebService."Object ID" := PAGE::"Purchase Quote";
        WebService."Service Name" := AutoServiceName;
        WebService.Published := true;
        WebService.Insert(true);

        Assert.IsFalse(
          TenantWebService.Get(TenantWebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should not exist in the Tenant Web Service table');

        WebServicesPage.OpenEdit;
        WebServicesPage.GotoKey(WebService."Object Type"::Page, AutoServiceName);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, AutoServiceName + ' web service record "Published" field should be checked.');
        Assert.IsTrue(
          WebServicesPage."All Tenants".AsBoolean, AutoServiceName + ' web service record "All Tenants" field should be checked.');
        WebServicesPage."All Tenants".Value := Format(false);
        WebServicesPage.Next();

        Assert.IsFalse(
          WebService.Get(WebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should no longer exist in the Web Service table');
        Assert.IsTrue(
          TenantWebService.Get(TenantWebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should exist in the Tenant Web Service table');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyUnselectAllTenantsExistingTenantRecord()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
        AutoServiceName: Text[240];
    begin
        // Test unselecting the all tenants checkbox will remove the system record and add a tenant record
        // if one doesn't already exist.
        AutoServiceName := CreateGuid();

        WebService.Init();
        WebService."Object Type" := WebService."Object Type"::Page;
        WebService."Object ID" := PAGE::"Purchase Quote";
        WebService."Service Name" := AutoServiceName;
        WebService.Published := true;
        WebService.Insert(true);

        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
        TenantWebService."Object ID" := PAGE::"Purchase Quote";
        TenantWebService."Service Name" := AutoServiceName;
        TenantWebService.Published := false;
        TenantWebService.Insert(true);

        Assert.IsTrue(
          TenantWebService.Get(TenantWebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should not exist in the Tenant Web Service table');

        WebServicesPage.OpenEdit;
        WebServicesPage.GotoKey(WebService."Object Type"::Page, AutoServiceName);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, AutoServiceName + ' web service record "Published" field should be checked.');
        Assert.IsTrue(
          WebServicesPage."All Tenants".AsBoolean, AutoServiceName + ' web service record "All Tenants" field should be checked.');
        WebServicesPage."All Tenants".Value := Format(false);
        WebServicesPage.Next();

        Assert.IsFalse(
          WebService.Get(WebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should no longer exist in the Web Service table');
        Assert.IsTrue(
          TenantWebService.Get(TenantWebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should exist in the Tenant Web Service table');
        Assert.IsFalse(
          TenantWebService.Published, AutoServiceName + ' tenant web service record "Published" field should not be checked.');

        WebServicesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifySelectAllTenants()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        WebServicesPage: TestPage "Web Services";
        AutoServiceName: Text[240];
    begin
        // Test selecting the all tenant checkbox will add a system record.
        AutoServiceName := CreateGuid();

        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
        TenantWebService."Object ID" := PAGE::"Purchase Quote";
        TenantWebService."Service Name" := AutoServiceName;
        TenantWebService.Published := true;
        TenantWebService.Insert(true);

        Assert.IsFalse(
          WebService.Get(WebService."Object Type"::Page, AutoServiceName), AutoServiceName + ' should not exist in the Web Service table');

        WebServicesPage.OpenEdit;
        WebServicesPage.GotoKey(WebService."Object Type"::Page, AutoServiceName);
        Assert.IsTrue(WebServicesPage.Published.AsBoolean, AutoServiceName + ' web service record "Published" field should be checked.');
        Assert.IsFalse(
          WebServicesPage."All Tenants".AsBoolean, AutoServiceName + ' web service record "All Tenants" field should not be checked.');
        WebServicesPage."All Tenants".Value := Format(true);
        WebServicesPage.Next();

        Assert.IsTrue(
          WebService.Get(WebService."Object Type"::Page, AutoServiceName), AutoServiceName + ' should exist in the Web Service table');
        Assert.IsTrue(
          TenantWebService.Get(TenantWebService."Object Type"::Page, AutoServiceName),
          AutoServiceName + ' should (still) exist in the Tenant Web Service table');

        WebServicesPage.Close();
    end;
}

