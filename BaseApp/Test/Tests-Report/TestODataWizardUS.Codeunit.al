codeunit 134767 "Test OData Wizard US"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Report Simplicity]
        Init();
    end;

    var
        Assert: Codeunit Assert;
        ODataUtility: Codeunit ODataUtility;
        LibraryUtility: Codeunit "Library - Utility";
        ObjectTypeVariable: Option ,,,,,,,,"Page","Query";
        ODataWizardTxt: Label 'Set Up Reporting Data';

    [Normal]
    [Scope('OnPrem')]
    procedure Init()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup(ODataWizardTxt, ODataWizardTxt, ODataWizardTxt, 0, ObjectType::Page, PAGE::"OData Setup Wizard", "Assisted Setup Group"::Customize, '', "Video Category"::Customize, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForPage()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        SelectText: Text;
    begin
        // [SCENARIO] Create new endpoint for page.
        TenantWebService.DeleteAll();

        ServiceName := 'Page22';

        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        ODataSetupWizard."Object ID".SetValue(PAGE::"Customer List");
        ODataSetupWizard.ServiceNameEdit.SetValue(ServiceName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No. field');
        Assert.AreEqual('No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        ODataSetupWizard.ODataColSubForm.Next();
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Page, ServiceName), 'Missing TenantWebService record');

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceColumns.Find('-'), 'Missing TenantWebServiceColumns record on FindFirst');
        Assert.AreEqual('No', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.IsTrue(TenantWebServiceColumns.Next() <> 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('Name', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);
        SelectText := '$select=No,Name,Responsibility_Center,Location_Code,Phone_No,Contact,Balance_LCY,Balance_Due_LCY,Sales_LCY,Payments_LCY';

        AssertODataUrls(ServiceRootUrl, ServiceName, SelectText, '', '', ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForQuery()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        SelectText: Text;
    begin
        // [SCENARIO] Create new endpoint for query.
        TenantWebService.DeleteAll();

        ServiceName := 'query100';

        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        ODataSetupWizard.ObjectTypeLookup.SetValue(OBJECTTYPE::Query);
        ODataSetupWizard."Object ID".SetValue(QUERY::"Top Customer Overview");
        ODataSetupWizard.ServiceNameEdit.SetValue(ServiceName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        ODataSetupWizard.ODataColSubForm.Next();
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No. field');
        Assert.AreEqual('No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        ODataSetupWizard.ODataColSubForm.Last();
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for CountryRegion field');
        Assert.AreEqual(
          'CountryRegionName', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for CountryRegion field');
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Query, ServiceName), 'Missing TenantWebService record');
        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceColumns.FindFirst(), 'Missing TenantWebServiceColumns record on FindFirst');
        Assert.AreEqual('Name', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.IsTrue(TenantWebServiceColumns.Next() <> 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('No', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.IsTrue(TenantWebServiceColumns.FindLast(), 'Missing TenantWebServiceColumns record on FindLast');
        Assert.AreEqual('CountryRegionName', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);
        SelectText := '$select=Name,No,CountryRegionName';

        AssertODataUrls(ServiceRootUrl, ServiceName, SelectText, '', '', ObjectTypeVariable::Query);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForPageEdit()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        SelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
        NavFilterText: Text;
    begin
        // [SCENARIO] Create endpoint for page and edit it.
        TenantWebService.DeleteAll();

        ServiceName := 'Page22Edit';
        NavFilterText := 'SORTING(No.) WHERE(No.=FILTER(<>01121212),Name=FILTER(>A),Credit Limit (LCY)=FILTER(>100),Blocked=FILTER(Ship|Invoice),Combine Shipments=FILTER(Yes))';

        CreateCustomerListEndpoint(ServiceName, NavFilterText, true, TenantWebService);

        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(2);  // Edit end point.
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard."Object ID".SetValue(PAGE::"Customer List");
        ODataSetupWizard.NameLookup.SetValue(ServiceName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No field');
        Assert.AreEqual('No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual(
          'Responsibility Center', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Responsibility_Center', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Page, ServiceName), 'The TenantWebService record was not found');

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.AreEqual(TenantWebServiceColumns.Find('-'), true, 'TenantWebServiceColumns record not found on FindFirst');
        Assert.AreEqual('Responsibility_Center', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.AreNotEqual(TenantWebServiceColumns.Next(), 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('Credit_Limit_LCY', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);
        SelectText := '$select=Responsibility_Center,Credit_Limit_LCY,Blocked,Last_Date_Modified,Combine_Shipments';
        ExpectedODataV3FilterText := '$filter=Credit_Limit_LCY gt 100M and (Blocked eq ''Ship''';
        ExpectedODataV4FilterText := '$filter=Credit_Limit_LCY gt 100 and (Blocked eq ''Ship''';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' or Blocked eq ''Invoice'') and Combine_Shipments eq true';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' or Blocked eq ''Invoice'') and Combine_Shipments eq true';

        AssertODataUrls(
          ServiceRootUrl, ServiceName, SelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText, ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForPageCopy()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        NewName: Text;
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        SelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
        NavFilterText: Text;
    begin
        // [SCENARIO] Test Copy From option of OData endpoint for Page data set.
        TenantWebService.DeleteAll();

        ServiceName := 'Page22';
        NewName := 'Page22Copy';
        NavFilterText := 'SORTING(No.) WHERE(No.=FILTER(<>01121212),Name=FILTER(>A),Credit Limit (LCY)=FILTER(>100),Blocked=FILTER(Ship|Invoice),Combine Shipments=FILTER(Yes))';

        CreateCustomerListEndpoint(ServiceName, NavFilterText, true, TenantWebService);

        // [GIVEN] The OData setup wizard.
        // [WHEN] User wants to create new oData endpoint by copying from another existing endpoint.
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(1);  // Copy end point.
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard."Object ID".SetValue(PAGE::"Customer List");
        ODataSetupWizard.NameLookup.SetValue(ServiceName);
        ODataSetupWizard.ServiceNameEdit.SetValue(NewName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No field');
        Assert.AreEqual('No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual(
          'Responsibility Center', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Responsibility_Center', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        // [THEN] The TenantWebService record is created.
        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Page, NewName), 'The TenantWebService record was not found');

        // [THEN] The TenantWebServiceColumns record are created.
        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.AreEqual(TenantWebServiceColumns.Find('-'), true, 'TenantWebServiceColumns record not found on FindFirst');
        Assert.AreEqual('Responsibility_Center', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.AreNotEqual(TenantWebServiceColumns.Next(), 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('Credit_Limit_LCY', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);
        SelectText := '$select=Responsibility_Center,Credit_Limit_LCY,Blocked,Last_Date_Modified,Combine_Shipments';
        ExpectedODataV3FilterText := '$filter=Credit_Limit_LCY gt 100M and (Blocked eq ''Ship''';
        ExpectedODataV4FilterText := '$filter=Credit_Limit_LCY gt 100 and (Blocked eq ''Ship''';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' or Blocked eq ''Invoice'') and Combine_Shipments eq true';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' or Blocked eq ''Invoice'') and Combine_Shipments eq true';

        // [THEN] The the endpoint URL has the correct $select clause.
        AssertODataUrls(ServiceRootUrl, NewName, SelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText, ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForQueryEdit()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        ExpectedODataSelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
    begin
        // [SCENARIO] Create endpoint for query and edit it.
        TenantWebService.DeleteAll();

        ServiceName := 'Query101Edit';

        // [GIVEN] The Tenant Web Service records with a filter.
        CreateSalesDashboardEndpointEnglishUS(ServiceName, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, QUERY::"Sales Dashboard", TenantWebService);

        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(2);  // Edit end point.
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard."Object ID".SetValue(QUERY::"Sales Dashboard");
        ODataSetupWizard.NameLookup.SetValue(ServiceName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Entry No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No field');
        Assert.AreEqual('Entry_No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual('Document No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Document_No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Last();
        Assert.AreEqual(
          'Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('SalesPersonName', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'Description', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Description', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'City', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('City', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('CountryRegionName', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Query, ServiceName), 'Missing TenantWebService record');

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.AreEqual(TenantWebServiceColumns.Find('-'), true, 'Missing TenantWebServiceColumns record on FindFirst');
        Assert.AreEqual('Posting_Date', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.IsTrue(TenantWebServiceColumns.Next() <> 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('Entry_Type', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, QUERY::"Sales Dashboard", TenantWebService);

        ExpectedODataSelectText := '$select=Posting_Date,Entry_Type,Quantity,Sales_Amount_Actual,Sales_Amount_Expected,';
        ExpectedODataSelectText := ExpectedODataSelectText + 'CountryRegionName,Customer_Posting_Group,SalesPersonName';
        ExpectedODataV3FilterText := '$filter=Posting_Date ge DateTime''2000-05-30T00:00:00.0000000'' and (Entry_Type eq ''Purchase''';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' or Entry_Type eq ''Sale'') and (Quantity gt -10M and Quantity lt 12345.67M)';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' and Sales_Amount_Expected ge 300M and Sales_Amount_Actual le 300M';
        ExpectedODataV3FilterText :=
          ExpectedODataV3FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        ExpectedODataV4FilterText := '$filter=Posting_Date ge 2000-05-30T00:00:00.0000000Z and (Entry_Type eq ''Purchase''';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' or Entry_Type eq ''Sale'') and (Quantity gt -10 and Quantity lt 12345.67)';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' and Sales_Amount_Expected ge 300 and Sales_Amount_Actual le 300';
        ExpectedODataV4FilterText :=
          ExpectedODataV4FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        AssertODataUrls(
          ServiceRootUrl, ServiceName, ExpectedODataSelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText,
          ObjectTypeVariable::Query);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardForQueryCopy()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        newName: Text;
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        ExpectedODataSelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
    begin
        // [SCENARIO] Test Copy scenario of OData endpoint for Query data set.
        TenantWebService.DeleteAll();

        ServiceName := 'Query101';
        newName := 'Query101Copy';

        // [GIVEN] The Tenant Web Service records with a filter.
        CreateSalesDashboardEndpointEnglishUS(ServiceName, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, QUERY::"Sales Dashboard", TenantWebService);

        // [GIVEN] The OData setup wizard.
        // [WHEN] User selects fields to be included in the $select=
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(1);  // Copy end point.
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard."Object ID".SetValue(QUERY::"Sales Dashboard");
        ODataSetupWizard.NameLookup.SetValue(ServiceName);
        ODataSetupWizard.ServiceNameEdit.SetValue(newName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Entry No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for No field');
        Assert.AreEqual('Entry_No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for No field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Next();
        Assert.AreEqual('Document No.', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Document_No', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(false);
        ODataSetupWizard.ODataColSubForm.Last();
        Assert.AreEqual(
          'Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('SalesPersonName', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Include.SetValue(true);
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'Description', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Description', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'City', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('City', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        ODataSetupWizard.ODataColSubForm.Previous();
        Assert.AreEqual(
          'Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('CountryRegionName', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsTrue(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page

        ODataSetupWizard.FinishAction.Invoke();

        // [THEN] The TenantWebService record is created.
        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Query, newName), 'Missing TenantWebService record');

        // [THEN] The TenantWebServiceColumns record are created.
        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.AreEqual(TenantWebServiceColumns.Find('-'), true, 'Missing TenantWebServiceColumns record on FindFirst');
        Assert.AreEqual('Posting_Date', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');
        Assert.IsTrue(TenantWebServiceColumns.Next() <> 0, 'Missing TenantWebServiceColumns record on Next');
        Assert.AreEqual('Entry_Type', TenantWebServiceColumns."Field Name", 'Unexpected value in TenantWebServiceColumns');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, QUERY::"Sales Dashboard", TenantWebService);

        ExpectedODataSelectText := '$select=Posting_Date,Entry_Type,Quantity,Sales_Amount_Actual,Sales_Amount_Expected,';
        ExpectedODataSelectText := ExpectedODataSelectText + 'CountryRegionName,Customer_Posting_Group,SalesPersonName';
        ExpectedODataV3FilterText := '$filter=Posting_Date ge DateTime''2000-05-30T00:00:00.0000000'' and (Entry_Type eq ''Purchase''';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' or Entry_Type eq ''Sale'') and (Quantity gt -10M and Quantity lt 12345.67M)';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' and Sales_Amount_Expected ge 300M and Sales_Amount_Actual le 300M';
        ExpectedODataV3FilterText :=
          ExpectedODataV3FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        ExpectedODataV4FilterText := '$filter=Posting_Date ge 2000-05-30T00:00:00.0000000Z and (Entry_Type eq ''Purchase''';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' or Entry_Type eq ''Sale'') and (Quantity gt -10 and Quantity lt 12345.67)';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' and Sales_Amount_Expected ge 300 and Sales_Amount_Actual le 300';
        ExpectedODataV4FilterText :=
          ExpectedODataV4FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        // [THEN] The the endpoint URL has the correct $select clause.
        AssertODataUrls(
          ServiceRootUrl, newName, ExpectedODataSelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText, ObjectTypeVariable::Query);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerListNoSelectNoFilter()
    var
        TenantWebService: Record "Tenant Web Service";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        NavFilterText: Text;
    begin
        // [SCENARIO] Test Creation of OData endpoint that has no select or filter.
        // The NavFilterText below is specific to the English-US regional settings.
        TenantWebService.DeleteAll();

        ServiceName := 'A';
        NavFilterText := '';

        CreateCustomerListEndpoint(ServiceName, NavFilterText, false, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);

        AssertODataUrls(ServiceRootUrl, ServiceName, '', '', '', ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerListNoFilter()
    var
        TenantWebService: Record "Tenant Web Service";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        ExpectedODataSelectText: Text;
        NavFilterText: Text;
    begin
        // [SCENARIO] Test Creation of OData endpoint that doesn't have a filter.
        // The NavFilterText below is specific to the English-US regional settings.
        TenantWebService.DeleteAll();

        ServiceName := 'B';
        NavFilterText := '';

        ExpectedODataSelectText := '$select=No,Name,Credit_Limit_LCY,Blocked,Combine_Shipments,Last_Date_Modified';

        CreateCustomerListEndpoint(ServiceName, NavFilterText, true, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);

        AssertODataUrls(ServiceRootUrl, ServiceName, ExpectedODataSelectText, '', '', ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerListEnglishUS()
    var
        TenantWebService: Record "Tenant Web Service";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        ExpectedODataSelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
        NavFilterText: Text;
    begin
        // [SCENARIO] Create OData endpoint for customer list page.
        // The NavFilterText below is specific to the English-US regional settings.
        TenantWebService.DeleteAll();

        ServiceName := 'C';
        NavFilterText := 'SORTING(No.) WHERE(No.=FILTER(01121212|01454545),Name=FILTER(@*e?*),Credit Limit (LCY)=FILTER(<=1,234,567.89),Blocked=FILTER(Ship|Invoice),Last Date Modified=FILTER(<>05/30/00),Combine Shipments=FILTER(Yes))';

        ExpectedODataSelectText := '$select=No,Name,Credit_Limit_LCY,Blocked,Combine_Shipments,Last_Date_Modified';
        ExpectedODataV3FilterText :=
          '$filter=(No eq ''01121212'' or No eq ''01454545'') and Name eq ''@*e?*'' and Credit_Limit_LCY le 1234567.89M and (Blocked eq ''Ship'' or Blocked eq ''Invoice'') and Last_Date_Modified ne DateTime''2000-05-30T00:00:00.0000000''';
        ExpectedODataV3FilterText := ExpectedODataV3FilterText + ' and Combine_Shipments eq true';

        ExpectedODataV4FilterText :=
          '$filter=(No eq ''01121212'' or No eq ''01454545'') and Name eq ''@*e?*'' and Credit_Limit_LCY le 1234567.89 and (Blocked eq ''Ship'' or Blocked eq ''Invoice'') and Last_Date_Modified ne 2000-05-30T00:00:00.0000000Z';
        ExpectedODataV4FilterText := ExpectedODataV4FilterText + ' and Combine_Shipments eq true';

        CreateCustomerListEndpoint(ServiceName, NavFilterText, true, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);

        AssertODataUrls(
          ServiceRootUrl, ServiceName, ExpectedODataSelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText,
          ObjectTypeVariable::Page);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesDashboardEnglishUS()
    var
        TenantWebService: Record "Tenant Web Service";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        ExpectedODataSelectText: Text;
        ExpectedODataV3FilterText: Text;
        ExpectedODataV4FilterText: Text;
    begin
        // [SCENARIO] Create OData endpoint for Sales Dashboard query.
        // The NavFilterText below is specific to the English-US regional settings.
        TenantWebService.DeleteAll();

        ServiceName := 'E';

        ExpectedODataSelectText := '$select=Entry_No,Posting_Date,Entry_Type,Quantity,Sales_Amount_Expected,Sales_Amount_Actual,CountryRegionName,Customer_Posting_Group';
        ExpectedODataV3FilterText :=
          '$filter=Entry_No ge 100 and Entry_No le 300 and Posting_Date ge DateTime''2000-05-30T00:00:00.0000000'' and (Entry_Type eq ''Purchase'' or Entry_Type eq ''Sale'')';
        ExpectedODataV3FilterText :=
          ExpectedODataV3FilterText +
          ' and (Quantity gt -10M and Quantity lt 12345.67M) and Sales_Amount_Expected ge 300M and Sales_Amount_Actual le 300M';
        ExpectedODataV3FilterText :=
          ExpectedODataV3FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        ExpectedODataV4FilterText :=
          '$filter=Entry_No ge 100 and Entry_No le 300 and Posting_Date ge 2000-05-30T00:00:00.0000000Z and (Entry_Type eq ''Purchase'' or Entry_Type eq ''Sale'')';
        ExpectedODataV4FilterText :=
          ExpectedODataV4FilterText +
          ' and (Quantity gt -10 and Quantity lt 12345.67) and Sales_Amount_Expected ge 300 and Sales_Amount_Actual le 300';
        ExpectedODataV4FilterText :=
          ExpectedODataV4FilterText + ' and CountryRegionName eq ''*e*'' and Customer_Posting_Group eq ''DOMESTIC''';

        CreateSalesDashboardEndpointEnglishUS(ServiceName, TenantWebService);
        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Query, QUERY::"Sales Dashboard", TenantWebService);

        AssertODataUrls(
          ServiceRootUrl, ServiceName, ExpectedODataSelectText, ExpectedODataV3FilterText, ExpectedODataV4FilterText,
          ObjectTypeVariable::Query);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCascadeDelete()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        ServiceName: Text[240];
    begin
        // [SCENARIO] Test Deletion of Tenant Web Service record and subordinates
        TenantWebService.DeleteAll();
        ServiceName := 'Cascade';

        // [GIVEN] The Tenant Web Service records and subordinates
        CreateCustomerListEndpoint(ServiceName, '', true, TenantWebService);
        Assert.IsTrue(TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName), 'Missing Tenant Web Service Record');

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceColumns.FindFirst(), 'Expected TenantWebServiceColumns record');

        TenantWebServiceFilter.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceFilter.FindFirst(), 'Expected TenantWebServiceFilter record');

        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceOData.FindFirst(), 'Expected TenantWebServiceOData record');

        // [WHEN] The Tenant Web Service record is deleted.
        TenantWebService.Delete(true);

        // [THEN] The subordinate records are also deleted.
        Assert.IsFalse(TenantWebServiceColumns.FindFirst(), 'Unexpected TenantWebServiceColumns record');
        Assert.IsFalse(TenantWebServiceFilter.FindFirst(), 'Unexpected TenantWebServiceFilter record');
        Assert.IsFalse(TenantWebServiceOData.FindFirst(), 'Unexpected TenantWebServiceOData record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardValidation()
    var
        TenantWebService: Record "Tenant Web Service";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceName: Text[240];
    begin
        // [SCENARIO]  Error scenarios are handled properly.
        TenantWebService.DeleteAll();
        ServiceName := 'page1';
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        ODataSetupWizard.ServiceNameEdit.SetValue(ServiceName);
        ODataSetupWizard.ObjectTypeLookup.SetValue(OBJECTTYPE::Page);
        asserterror ODataSetupWizard."Object ID".SetValue(PAGE::"Company Information");
        Assert.AreEqual('Validation error for Field: Object ID,  Message = ''Invalid page Id. Only pages of type List are valid.''',
          GetLastErrorText, 'Unexpected Error text');

        TenantWebService.Init();
        TenantWebService.Validate("Object Type", ObjectTypeVariable::Query);
        TenantWebService.Validate("Object ID", QUERY::"Top Customer Overview");
        TenantWebService.Validate(Published, true);
        TenantWebService.Validate("Service Name", 'Query100');
        TenantWebService.Insert(true);

        ServiceName := 'Query100';
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        asserterror ODataSetupWizard.ServiceNameEdit.SetValue(ServiceName);
        Assert.AreEqual('Validation error for Field: Control14,  Message = ''This name already exists.''',
          GetLastErrorText, 'Unexpected Name validation Error text');

        Clear(ODataSetupWizard);
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(1);  // Copy end point.
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard."Object ID".SetValue(PAGE::"Customer List");
        asserterror ODataSetupWizard.NameLookup.SetValue('sample');
        Assert.AreEqual('Validation error for Field: NameLookup,  Message = ''Use the lookup to select existing name.''',
          GetLastErrorText, 'Unexpected Error text');

        Clear(ODataSetupWizard);
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.BackAction.Invoke(); // just to exercise the Back button.
        ODataSetupWizard.NextAction.Invoke(); // Action selection step
        ODataSetupWizard.NextAction.Invoke(); // new action by default
        ODataSetupWizard.ServiceNameEdit.SetValue('TestName');
        ODataSetupWizard.ObjectTypeLookup.SetValue(OBJECTTYPE::Query);
        ODataSetupWizard."Object ID".SetValue(QUERY::"Top Customer Overview");
        ODataSetupWizard.NextAction.Invoke();
        ODataSetupWizard.ODataColSubForm.First();
        ODataSetupWizard.ODataColSubForm."Field Caption".Activate();
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Caption".Value, 'Unexpected Value for Name field');
        Assert.AreEqual('Name', ODataSetupWizard.ODataColSubForm."Field Name".Value, 'Unexpected Value for Name field');
        Assert.IsFalse(ODataSetupWizard.ODataColSubForm.Include.AsBoolean(), 'Unexpected Value for Included field');
        asserterror ODataSetupWizard.PublishAction.Invoke();
        Assert.AreEqual('Please select field(s) before publishing the data set.',
          GetLastErrorText, 'Unexpected Publish button validation Error text');

        ODataSetupWizard.FinishAction.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWizardNextValidation()
    var
        ODataSetupWizard: TestPage "OData Setup Wizard";
    begin
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        asserterror ODataSetupWizard.NextAction.Invoke();
        Assert.AreEqual('Please enter a Name for the data set.',
          GetLastErrorText, 'Unexpected Name validation Error text for new action');

        Clear(ODataSetupWizard);
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(1); // copy action
        ODataSetupWizard.NextAction.Invoke();
        asserterror ODataSetupWizard.NextAction.Invoke();
        Assert.AreEqual('Please enter a Name for the data set.',
          GetLastErrorText, 'Unexpected Name validation Error text for copy action');

        Clear(ODataSetupWizard);
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.ActionType.SetValue(2); // Edit action
        ODataSetupWizard.NextAction.Invoke();
        asserterror ODataSetupWizard.NextAction.Invoke();
        Assert.AreEqual('Please enter a Name for the data set.',
          GetLastErrorText, 'Unexpected Name validation Error text for edit action');

        Clear(ODataSetupWizard);
        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // new action by default
        ODataSetupWizard.ServiceNameEdit.SetValue('TestName');
        asserterror ODataSetupWizard.NextAction.Invoke();
        Assert.AreEqual('Please enter a data source for the data set.',
          GetLastErrorText, 'Unexpected Data source (Object Id) validation Error text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestODataObjectNameTransformation()
    var
        ODataUtility: Codeunit ODataUtility;
        ODataCandidateName: Text;
        ODataExpectedName: Text;
        ODataActualName: Text;
    begin
        // [GIVEN] A candidate OData object name that contains special characters in various combinations.
        ODataCandidateName := '-AB._CD__EF()G_.H_/:::I__';
        ODataExpectedName := '_AB__CD__EF_G_H_I';

        // [WHEN] The name is 'externalized'.
        ODataActualName := ODataUtility.ExternalizeName(ODataCandidateName);

        // [THEN] The name adheres to expected formatting.
        Assert.AreEqual(ODataExpectedName, ODataActualName, 'Object name conversion did not match the expected value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestODataObjectNameTransformationWithPercent()
    var
        ODataUtility: Codeunit ODataUtility;
        ODataCandidateName: Text;
        ODataExpectedName: Text;
        ODataActualName: Text;
    begin
        // [GIVEN] A candidate OData object name that contains special characters in various combinations.
        ODataCandidateName := 'AB%CD%';
        ODataExpectedName := 'ABPercentCDPercent';

        // [WHEN] The name is 'externalized'.
        ODataActualName := ODataUtility.ExternalizeName(ODataCandidateName);

        // [THEN] The name adheres to expected formatting.
        Assert.AreEqual(ODataExpectedName, ODataActualName, 'Object name conversion did not match the expected value.');
    end;

#if not CLEAN25
    [Test]
    [HandlerFunctions('SalesPriceFilterPageHandler')]
    [Scope('OnPrem')]
    procedure TestWizardForPageWithFilter()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        ODataSetupWizard: TestPage "OData Setup Wizard";
        ServiceRootUrl: Text;
        ServiceName: Text[240];
        SelectText: Text;
        FilterText: Text;
    begin
        // [SCENARIO] Create new endpoint for page with a filter.
        TenantWebService.DeleteAll();

        ServiceName := 'Page7002';

        ODataSetupWizard.Trap();
        ODataSetupWizard.OpenEdit();
        ODataSetupWizard.NextAction.Invoke(); // welcome page, click through it.
        ODataSetupWizard.NextAction.Invoke(); // select action page, click through it as we are creating new.
        ODataSetupWizard."Object ID".SetValue(PAGE::"Sales Prices");
        ODataSetupWizard.ServiceNameEdit.SetValue(ServiceName);
        ODataSetupWizard.NextAction.Invoke(); // select columns page should be open.
        ODataSetupWizard.AddFiltersAction.Invoke(); // // Add sales type filter (via. SalesPriceFilterPageHandler).
        ODataSetupWizard.PublishAction.Invoke();  // Finish Page
        ODataSetupWizard.FinishAction.Invoke();

        Assert.IsTrue(TenantWebService.Get(OBJECTTYPE::Page, ServiceName), 'Missing TenantWebService record');

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.IsTrue(TenantWebServiceColumns.Find('-'), 'Missing TenantWebServiceColumns record on FindFirst');

        ServiceRootUrl := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PAGE::"Customer List", TenantWebService);
        SelectText := '$select=SalesTypeFilter,SalesCodeFilterCtrl,ItemNoFilterCtrl,StartingDateFilter,CurrencyCodeFilterCtrl,FilterDescription,Sales_Type,Sales_Code,Item_No,Unit_of_Measure_Code,Minimum_Quantity,Unit_Price,Starting_Date,Ending_Date';
        FilterText := '$filter=Sales_Type eq ''Customer''';

        AssertODataUrls(ServiceRootUrl, ServiceName, SelectText, FilterText, FilterText, ObjectTypeVariable::Page);
    end;
#endif

    [Scope('OnPrem')]
    procedure CreateCustomerListEndpoint(ServiceNameParam: Text[240]; FilterTextParam: Text; AddColumnsParam: Boolean; var TenantWebService: Record "Tenant Web Service")
    begin
        AddTenantWebServiceRecord(ServiceNameParam, TenantWebService."Object Type"::Page, PAGE::"Customer List", TenantWebService);

        if AddColumnsParam then begin
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 1, 'No');  // CODE Datatype
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 2, 'Name');  // Text Datatype
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 20, 'Credit_Limit_LCY');  // Decimal Datatype
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 39, 'Blocked');  // Option Datatype
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 87, 'Combine_Shipments');  // Boolean Datatype
            AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 54, 'Last_Date_Modified');  // Date Datatype
        end;

        AddTenantWebServiceFilterRecord(TenantWebService.RecordId, DATABASE::Customer, FilterTextParam);
        AddTenantWebServiceODataRecord(TenantWebService.RecordId, ServiceNameParam, TenantWebService."Object Type"::Page);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDashboardEndpointEnglishUS(ServiceNameParam: Text[240]; var TenantWebService: Record "Tenant Web Service")
    var
        ItemLedgerFilterText: Text;
    begin
        // The NavFilterText below is specific to the English-US regional settings.

        AddTenantWebServiceRecord(ServiceNameParam, TenantWebService."Object Type"::Query, 101, TenantWebService);
        CreateSalesDashboardTenantWebServiceColumns(TenantWebService);

        ItemLedgerFilterText := 'SORTING(Entry No.) WHERE(Entry No.=FILTER(100..300),Posting Date=FILTER(>=05/30/00),Entry Type=FILTER(Purchase|Sale),';
        ItemLedgerFilterText := ItemLedgerFilterText + 'Quantity=FILTER(>-10&<12,345.67),Sales Amount (Expected)=FILTER(300..),Sales Amount (Actual)=FILTER(..300))';
        AddTenantWebServiceFilterRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", ItemLedgerFilterText);
        AddTenantWebServiceFilterRecord(TenantWebService.RecordId, DATABASE::"Country/Region", 'SORTING(Code) WHERE(Name=FILTER(*e*))');
        AddTenantWebServiceFilterRecord(
          TenantWebService.RecordId, DATABASE::Customer, 'SORTING(No.) WHERE(Customer Posting Group=FILTER(DOMESTIC))');
        AddTenantWebServiceODataRecord(TenantWebService.RecordId, ServiceNameParam, TenantWebService."Object Type"::Query);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDashboardTenantWebServiceColumns(TenantWebService: Record "Tenant Web Service")
    begin
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 1, 'Entry_No');  // Integer Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 3, 'Posting_Date');  // Date Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 4, 'Entry_Type');  // Option Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 12, 'Quantity');  // Decimal Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 5815, 'Sales_Amount_Expected');  // Decimal Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Item Ledger Entry", 5816, 'Sales_Amount_Actual');  // Decimal Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::"Country/Region", 2, 'CountryRegionName');  // Text Datatype
        AddTenantWebServiceColumnsRecord(TenantWebService.RecordId, DATABASE::Customer, 21, 'Customer_Posting_Group');  // Code Datatype
    end;

    [Scope('OnPrem')]
    procedure AddTenantWebServiceRecord(ServiceNameParam: Text[240]; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; ObjectIDParam: Integer; var TenantWebServiceParam: Record "Tenant Web Service")
    begin
        TenantWebServiceParam.Init();
        TenantWebServiceParam."Service Name" := ServiceNameParam;
        TenantWebServiceParam."Object Type" := ObjectTypeParam;
        TenantWebServiceParam."Object ID" := ObjectIDParam;
        TenantWebServiceParam.Published := true;
        TenantWebServiceParam.Insert();
    end;

    [Scope('OnPrem')]
    procedure AddTenantWebServiceFilterRecord(TenantWebServiceIDParam: RecordID; DataItemParam: Integer; FilterTextParam: Text)
    var
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        TenantWebServiceFilter.Init();
        TenantWebServiceFilter.TenantWebServiceID := TenantWebServiceIDParam;
        WebServiceManagement.SetTenantWebServiceFilter(TenantWebServiceFilter, FilterTextParam);
        TenantWebServiceFilter."Data Item" := DataItemParam;
        TenantWebServiceFilter.Insert();
    end;

    [Scope('OnPrem')]
    procedure AddTenantWebServiceColumnsRecord(TenantWebServiceIDParam: RecordID; DataItemParam: Integer; FieldNumberParam: Integer; FieldNameParam: Text[250])
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
    begin
        TenantWebServiceColumns.Init();
        TenantWebServiceColumns.TenantWebServiceID := TenantWebServiceIDParam;
        TenantWebServiceColumns."Data Item" := DataItemParam;
        TenantWebServiceColumns."Field Number" := FieldNumberParam;
        TenantWebServiceColumns."Field Name" := FieldNameParam;
        TenantWebServiceColumns.Include := true;
        TenantWebServiceColumns.Insert();
    end;

    [Scope('OnPrem')]
    procedure AddTenantWebServiceODataRecord(TenantWebServiceIDParam: RecordID; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query")
    var
        TenantWebServiceOData: Record "Tenant Web Service OData";
        WebServiceManagement: Codeunit "Web Service Management";
        SelectText: Text;
        ODataV3FilterText: Text;
        ODataV4FilterText: Text;
    begin
        TenantWebServiceOData.Init();
        TenantWebServiceOData.TenantWebServiceID := TenantWebServiceIDParam;
        ODataUtility.GenerateSelectText(ServiceNameParam, ObjectTypeParam, SelectText);
        ODataUtility.GenerateODataV3FilterText(ServiceNameParam, ObjectTypeParam, ODataV3FilterText);
        ODataUtility.GenerateODataV4FilterText(ServiceNameParam, ObjectTypeParam, ODataV4FilterText);
        WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
        WebServiceManagement.SetODataFilterClause(TenantWebServiceOData, ODataV3FilterText);
        WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, ODataV4FilterText);
        TenantWebServiceOData.Insert();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CalculateExpectedUrl(ExpectedServiceRootUrlParam: Text; ExpectedSelectTextParam: Text; ExpectedFilterTextParam: Text): Text
    var
        ExpectedUrl: Text;
        PreSelectTextConjunction: Text;
    begin
        if StrPos(ExpectedServiceRootUrlParam, '?') > 0 then
            PreSelectTextConjunction := '&'
        else
            PreSelectTextConjunction := '?';

        ExpectedUrl := ExpectedServiceRootUrlParam;

        if ExpectedSelectTextParam <> '' then begin
            ExpectedUrl := ExpectedUrl + PreSelectTextConjunction + ExpectedSelectTextParam;
            PreSelectTextConjunction := '&';
        end;

        if ExpectedFilterTextParam <> '' then
            ExpectedUrl := ExpectedUrl + PreSelectTextConjunction + ExpectedFilterTextParam;

        exit(ExpectedUrl);
    end;

    local procedure FillContactFields(var Contact: Record Contact)
    begin
        Contact."First Name" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."First Name")), 1, 19); // Use a length hardcore because Contact.Name has lenght 50 and combined - <FirstName> + ' ' + <MiddleName> + ' ' + <Surname>
        Contact."Middle Name" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Middle Name")), 1, 10);
        Contact.Surname :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.Surname)), 1, 19);
        Contact.Initials :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.Initials)), 1, MaxStrLen(Contact.Initials));
        Contact."E-Mail" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."E-Mail")), 1, MaxStrLen(Contact."E-Mail"));
        Contact."E-Mail 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."E-Mail 2")), 1, MaxStrLen(Contact."E-Mail 2"));
        Contact."Home Page" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Home Page")), 1, MaxStrLen(Contact."Home Page"));
        Contact."Phone No." :=
          CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(Contact."Phone No.")), 1, MaxStrLen(Contact."Phone No."));
        Contact."Mobile Phone No." :=
          CopyStr(LibraryUtility.GenerateRandomNumericText(MaxStrLen(Contact."Mobile Phone No.")), 1, MaxStrLen(Contact."Mobile Phone No."));
        Contact."Fax No." :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Fax No.")), 1, MaxStrLen(Contact."Fax No."));
        Contact.Address :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Address 2")), 1, MaxStrLen(Contact.Address));
        Contact.City :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.City)), 1, MaxStrLen(Contact.City));
        Contact."Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Post Code")), 1, MaxStrLen(Contact."Post Code"));
        Contact.County :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact.County)), 1, MaxStrLen(Contact.County));
        Contact."Job Title" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Contact."Job Title")), 1, MaxStrLen(Contact."Job Title"));
    end;

    local procedure VerifyNavContact(NavContact: Record Contact; ExchangeContact: Record Contact)
    begin
        NavContact.Get(NavContact."No.");
        NavContact.TestField("First Name", ExchangeContact."First Name");
        NavContact.TestField("Middle Name", ExchangeContact."Middle Name");
        NavContact.TestField(Surname, ExchangeContact.Surname);
        NavContact.TestField(Initials, ExchangeContact.Initials);
        NavContact.TestField("E-Mail", ExchangeContact."E-Mail");
        NavContact.TestField("E-Mail 2", ExchangeContact."E-Mail 2");
        NavContact.TestField("Home Page", ExchangeContact."Home Page");
        NavContact.TestField("Phone No.", ExchangeContact."Phone No.");
        NavContact.TestField("Mobile Phone No.", ExchangeContact."Mobile Phone No.");
        NavContact.TestField("Fax No.", ExchangeContact."Fax No.");
        NavContact.TestField(Address, ExchangeContact.Address);
        NavContact.TestField("Address 2", ExchangeContact."Address 2");
        NavContact.TestField(City, ExchangeContact.City);
        NavContact.TestField("Post Code", ExchangeContact."Post Code");
        NavContact.TestField(County, ExchangeContact.County);
        NavContact.TestField("Job Title", ExchangeContact."Job Title");
    end;

    local procedure AssertODataUrls(ServiceRootUrl: Text; ServiceName: Text; SelectText: Text; V3FilterText: Text; V4FilterText: Text; ObjectType: Integer)
    var
        ODataUtility: Codeunit ODataUtility;
        ExpectedODataV3Url: Text;
        ExpectedODataV4Url: Text;
        ActualODataV3Url: Text;
        ActualODataV4Url: Text;
    begin
        ExpectedODataV3Url := CalculateExpectedUrl(ServiceRootUrl, SelectText, V3FilterText);
        ActualODataV3Url := ODataUtility.GenerateODataV3Url(ServiceRootUrl, ServiceName, ObjectType);
        ExpectedODataV4Url := CalculateExpectedUrl(ServiceRootUrl, SelectText, V4FilterText);
        ActualODataV4Url := ODataUtility.GenerateODataV4Url(ServiceRootUrl, ServiceName, ObjectType);

        Assert.AreEqual(ExpectedODataV3Url, ActualODataV3Url, 'Unexpected URL');
        Assert.AreEqual(ExpectedODataV4Url, ActualODataV4Url, 'Unexpected URL');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateNavContactFromExchangeContact()
    var
        ExchangeContact: Record Contact;
        NavContact: Record Contact;
        ExchangeSync: Record "Exchange Sync";
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220798] Nav Contact must be updated by information from Exchange Contact

        // [GIVEN] Exchange Contact
        // [GIVEN] "First Name" = 'Ivan', "Middle Name" = 'Ivanovich', "Surname" = 'Ivanov',
        // [GIVEN] "Initials" = 'III', "E-mail" = 'privatemail@contoso.com', "E-mail 2" = 'workmail@contoso.com',
        // [GIVEN] "Home Page" = 'http://ivanov.ru', "Phone No." = '+1(234)567-89-01', "Mobile Phone No." = '+1(098)765-43-21',
        // [GIVEN] "Fax No." = '+5(678)901-23-45', "Address" = 'Lenina St.', "Address 2" = 'bld. 3',
        // [GIVEN] "City" = 'Moscow', "Post Code" = '123456', "County" = 'Moscowia',
        // [GIVEN] "Job Title" = 'Developer'
        FillContactFields(ExchangeContact);

        // [GIVEN] Navision Contact
        NavContact.Init();
        NavContact.Insert();

        // [WHEN] Invoike "O365 Contact Sync. Helper".TransferExchangeContactToNavContact
        O365ContactSyncHelper.TransferExchangeContactToNavContact(ExchangeContact, NavContact, ExchangeSync);

        // [THEN] Navision Contact
        // [THEN] "First Name" = 'Ivan', "Middle Name" = 'Ivanovich', "Surname" = 'Ivanov',
        // [THEN] "Initials" = 'III', "E-mail" = 'privatemail@contoso.com', "E-mail 2" = 'workmail@contoso.com',
        // [THEN] "Home Page" = 'http://ivanov.ru', "Phone No." = '+1(234)567-89-01', "Mobile Phone No." = '+1(098)765-43-21',
        // [THEN] "Fax No." = '+5(678)901-23-45', "Address" = 'Lenina St.', "Address 2" = 'bld. 3',
        // [THEN] "City" = 'Moscow', "Post Code" = '123456', "County" = 'Moscowia',
        // [THEN] "Job Title" = 'Developer'
        VerifyNavContact(NavContact, ExchangeContact);
    end;

#if not CLEAN25
    [FilterPageHandler]
    [Scope('OnPrem')]
    procedure SalesPriceFilterPageHandler(var SalesLineRecordRef: RecordRef): Boolean
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesLineRecordRef.GetTable(SalesPrice);
        SalesPrice.SetFilter("Sales Type", 'Customer');
        SalesLineRecordRef.SetView(SalesPrice.GetView());
        exit(true);
    end;
#endif
}

