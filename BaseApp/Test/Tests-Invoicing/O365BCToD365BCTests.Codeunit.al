codeunit 138956 "O365 BC To D365 BC Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [BC] [Trial]        
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        EvalCompanyName: Text[30];
        ThanksToExploreD365CaptionLbl: Label 'Thanks for choosing to explore Dynamics 365 Business Central!';
        EvaluationCompanyDoesNotExistsMsg: Label 'Sorry, but the evaluation company isn''t available right now so we can''t start Dynamics 365 Business Central. Please try again later.';
        BusinessCentralTrialVisibleInvNameTxt: Label 'BusinessCentralTrialVisibleForInv', Locked = true;

    [Test]
    [HandlerFunctions('MessageHandler,StandardSessionSettingsHandler')]
    [Scope('OnPrem')]
    procedure TestBusinessManagerRCContentForInvoicingUsers()
    var
        O365LinktoFinancials: TestPage "O365 Link to Financials";
    begin
        // [GIVEN] A clean Invoicing App
        LibraryVariableStorage.Clear;
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Invoicing user lands in MyCompany in Business Central
        EventSubscriberInvoicingApp.SetAppId('FIN');
        BindSubscription(EventSubscriberInvoicingApp);

        O365LinktoFinancials.OpenEdit;
        Assert.IsTrue(O365LinktoFinancials.TryOutLbl.Visible, 'Text not visible');
        Assert.IsTrue(O365LinktoFinancials.LinkToFinancials.Visible, 'Link not visible');
        Assert.AreEqual(ThanksToExploreD365CaptionLbl, O365LinktoFinancials.TryOutLbl.Caption, 'Incorrect Messaging for Invoicing Users');

        // [WHEN] Invoicing user tries link to financials and evaluation company does not exist
        // [THEN] Invoicing user gets a message that evaluation company does not exist
        LibraryVariableStorage.Enqueue(EvaluationCompanyDoesNotExistsMsg);
        O365LinktoFinancials.LinkToFinancials.DrillDown;

        // [WHEN] Invoicing user tries link to financials and evaluation company does exist
        // [THEN] Invoicing user session updates to evaluation company

        CreateEvalCompany;
        O365LinktoFinancials.LinkToFinancials.DrillDown;

        // Assert in Session handler
        UnbindSubscription(EventSubscriberInvoicingApp);
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestUserGetsEvaluationCompanyOnTileClick()
    var
        O365ToD365Trial: TestPage "O365 To D365 Trial";
    begin
        // [GIVEN] A clean Invoicing App that contains My Company and Cronus evaluation Company
        Init;
        CreateEvalCompany;
        LibraryLowerPermissions.SetInvoiceApp;

        O365ToD365Trial.OpenView;

        // [WHEN] User clicks on the button to try Business Central from Invoicing
        O365ToD365Trial.TryBusinessCentral.Invoke;

        // [THEN] Users lands in Evaluation company
        // Assert in Hyper link handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessCentralTrialTileVisibilityWithPermissions()
    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
    begin
        // [GIVEN] A clean Invoicing App
        Init;
        CreateEvalCompany;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User has permissions to access evaluation company
        // Current user is super

        // [THEN] Users see the tile
        Assert.IsTrue(O365SetupMgmt.UserHasPermissionsForEvaluationCompany, 'User cannot see the tile even though user has permissions');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessCentralTrialTileVisibilityWithReadPermissions()
    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
    begin
        // [GIVEN] A Invoicing user with Eval company
        Init;
        CreateEvalCompany;

        // [WHEN] User has only read permissions to access evaluation company
        LibraryLowerPermissions.SetRead;

        // [THEN] Users doesn't see the tile
        Assert.IsFalse(O365SetupMgmt.UserHasPermissionsForEvaluationCompany, 'User see the tile even though user has no permissions');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBusinessCentralTrialTileVisibilityWithNoPermissionsOnSalesHeader()
    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
    begin
        // [GIVEN] A Invoicing user with Eval company and no write permissions to Eval Company
        Init;
        CreateEvalCompany;

        // [WHEN] User has only read permissions to view customer and not sales header record
        LibraryLowerPermissions.SetCustomerView;

        // [THEN] Users doesn't see the tile
        Assert.IsFalse(O365SetupMgmt.UserHasPermissionsForEvaluationCompany, 'User see the tile even though user has no permissions');
    end;

    local procedure Init()
    begin
        DeleteCompany(EvalCompanyName);
        LibraryVariableStorage.Clear;
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        if IsInitialized then
            exit;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);

        IsInitialized := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(ExpectedMessage, Message, 'Message does not match');
    end;

    local procedure CreateEvalCompany()
    var
        Company: Record Company;
    begin
        EvalCompanyName := 'Test';
        Company.Name := EvalCompanyName;
        Company."Evaluation Company" := true;
        Company.Insert(true);
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, StrSubstNo('company=%1', EvalCompanyName)) > 0, 'Incorrect url');
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure StandardSessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        Assert.AreEqual(EvalCompanyName, TestSessionSettings.Company, 'Incorrect Company');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure DeleteCompany(CompanyName: Text[30])
    var
        Company: Record Company;
    begin
        Company.SetRange(Name, CompanyName);
        if Company.FindFirst then
            Company.Delete();
    end;

    local procedure SetupKeyVault()
    var
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyVaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', BusinessCentralTrialVisibleInvNameTxt);
        MockAzureKeyVaultSecretProvider.AddSecretMapping(BusinessCentralTrialVisibleInvNameTxt, 'FALSE');

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);
        AzureKeyVault.GetAzureKeyVaultSecret(BusinessCentralTrialVisibleInvNameTxt, TestSecret);

        Assert.AreEqual('FALSE', TestSecret, 'Could not configure keyvault');
    end;

    local procedure CleanupKeyVault()
    var
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);

        AzureKeyVault.GetAzureKeyVaultSecret(BusinessCentralTrialVisibleInvNameTxt, TestSecret);
        Assert.AreEqual('', TestSecret, 'Cleanup failed');
    end;
}

