codeunit 134621 "Graph Syncing Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphSync: Codeunit "Library - Graph Sync";
        ContactIntegrationMappingCode: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure GraphSyncingIsDisabledForOnPremCompany()
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // Exercise
        CompanyInformation.OpenView;

        // Verify
        MarketingSetup.Get();
        MarketingSetup.TestField("Sync with Microsoft Graph", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GraphSyncingIsEnabledForSaaSCompany()
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Exercise
        CompanyInformation.OpenView;

        // Verify
        MarketingSetup.Get();
        MarketingSetup.TestField("Sync with Microsoft Graph", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GraphSubscriptionMgmtManuallyBoundForSaaSCompany()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Exercise
        CompanyInformation.OpenView;

        // Verify
        AssertSubscribersOnGraphSubscriptionMgmtAreStaticAutomaticBound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MappingNotFoundForIntegrationTableMappingWithoutIntegrationTableFields()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Initialize;

        // Exercise
        CreateIntegrationTableMapping(IntegrationTableMapping, ContactIntegrationMappingCode);

        // Verify
        AssertIntegrationMappingNotFound;

        // Teardown
        IntegrationTableMapping.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MappingExistsForIntegrationTableMappingWithIntegrationTableFields()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Initialize;

        // Setup
        CreateIntegrationTableMapping(IntegrationTableMapping, ContactIntegrationMappingCode);

        // Exercise
        CreateIntegrationFieldMapping(IntegrationFieldMapping, IntegrationTableMapping.Name);

        // Verify
        AssertIntegrationMappingExists;

        // Teardown
        IntegrationTableMapping.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactIntegrationMappingNotFoundForOnPremDemoCompany()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        AssertCurrentCompanyIsDemoCompany;

        // Exercise
        CompanyInformation.OpenView;

        // Verify
        AssertIntegrationMappingNotFound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactIntegrationMappingNotFoundForSaaSDemoCompany()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        AssertCurrentCompanyIsDemoCompany;

        // Exercise
        CompanyInformation.OpenView;

        // Verify
        AssertIntegrationMappingNotFound;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotEnableSyncInMarketingSetupIfSyncIsNotAllowed()
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // Exercise
        MarketingSetup.Get();
        MarketingSetup.Validate("Sync with Microsoft Graph", true);

        // Verify
        MarketingSetup.TestField("Sync with Microsoft Graph", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncInMarketingSetupCanBeEnabledIfSyncIsAllowed()
    var
        MarketingSetup: Record "Marketing Setup";
        CompanyInformation: Record "Company Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();

        // Exercise
        MarketingSetup.Get();
        MarketingSetup.Validate("Sync with Microsoft Graph", true);

        // Verify
        MarketingSetup.TestField("Sync with Microsoft Graph", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GraphSyncEnabledReturnsTrueWhenBusinessProfileSyncIsEnabled()
    var
        MarketingSetup: Record "Marketing Setup";
        CompanyInformation: Record "Company Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();

        MarketingSetup.Get();
        MarketingSetup.Validate("Sync with Microsoft Graph", false);
        MarketingSetup.Modify();

        // Exercise
        CompanyInformation.Validate("Sync with O365 Bus. profile", true);
        CompanyInformation.Modify();

        // Verify
        Assert.IsTrue(GraphSyncRunner.IsGraphSyncEnabled, 'Graph sync should be enabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessProfileSyncEnabledWhenGraphSyncEnabled()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize;

        // Setup & Exercise
        EnableGraphSync;

        // Verify
        CompanyInformation.Get();
        CompanyInformation.TestField("Sync with O365 Bus. profile", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessProfileSyncDisabledWhenGraphSyncDisabled()
    var
        CompanyInformation: Record "Company Information";
        MarketingSetup: Record "Marketing Setup";
    begin
        Initialize;

        // Setup
        EnableGraphSync;

        // Exercise
        MarketingSetup.Get();
        MarketingSetup.Validate("Sync with Microsoft Graph", false);
        MarketingSetup.Modify(true);

        // Verify
        CompanyInformation.Get();
        CompanyInformation.TestField("Sync with O365 Bus. profile", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GraphSyncNotEnabledWhenBusinessProfileSyncEnabled()
    var
        CompanyInformation: Record "Company Information";
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Initialize;

        // Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();

        // Exercise
        CompanyInformation.Validate("Sync with O365 Bus. profile", true);
        CompanyInformation.Modify(true);

        // Verify
        MarketingSetup.Get();
        MarketingSetup.TestField("Sync with Microsoft Graph", false);
    end;

    local procedure Initialize()
    var
        PermissionManager: Codeunit "Permission Manager";
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        LibraryGraphSync.RegisterTestConnections;
        Clear(PermissionManager);
        LibraryGraphSync.DeleteAllIntegrationRecords;
        LibraryGraphSync.DeleteAllContactIntegrationMappingDetails;
        ContactIntegrationMappingCode := GraphDataSetup.GetMappingCodeForTable(DATABASE::Contact);
    end;

    local procedure CreateIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; NewName: Code[20])
    begin
        with IntegrationTableMapping do begin
            Init;
            Name := NewName;
            Insert;
        end;
    end;

    local procedure CreateIntegrationFieldMapping(var IntegrationFieldMapping: Record "Integration Field Mapping"; IntegrationTableMappingName: Code[20])
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        SynchronizeConnectionName: Text;
    begin
        GraphConnectionSetup.RegisterConnections;
        SynchronizeConnectionName := GraphConnectionSetup.GetSynchronizeConnectionName(DATABASE::Contact);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SynchronizeConnectionName, true);

        with IntegrationFieldMapping do begin
            Init;
            "Integration Table Mapping Name" := IntegrationTableMappingName;
            "Field No." := Contact.FieldNo(Name);
            "Integration Table Field No." := GraphContact.FieldNo(GivenName);
            Insert;
        end;
    end;

    local procedure AssertSubscribersOnGraphSubscriptionMgmtAreStaticAutomaticBound()
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetRange("Subscriber Codeunit ID", CODEUNIT::"Graph Subscription Management");
        EventSubscription.SetRange(Active, true);
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        Assert.RecordIsNotEmpty(EventSubscription);
    end;

    local procedure AssertIntegrationMappingExists()
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        Assert.IsTrue(GraphDataSetup.IntegrationMappingExists(ContactIntegrationMappingCode),
          'Contact integration table and field mapping do not exist.');
    end;

    local procedure AssertIntegrationMappingNotFound()
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        Assert.IsFalse(GraphDataSetup.IntegrationMappingExists(ContactIntegrationMappingCode),
          'Contact integration table and field mapping exists.');
    end;

    local procedure AssertCurrentCompanyIsDemoCompany()
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        Assert.IsTrue(CompanyInformationMgt.IsDemoCompany, StrSubstNo('%1 is not a demo company.', CompanyName));
    end;

    local procedure EnableGraphSync()
    var
        CompanyInformation: Record "Company Information";
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        CompanyInformation.Get();
        CompanyInformation."Demo Company" := false;
        CompanyInformation.Modify();

        MarketingSetup.Get();
        MarketingSetup.Validate("Sync with Microsoft Graph", true);
        MarketingSetup.Modify(true);
    end;
}

