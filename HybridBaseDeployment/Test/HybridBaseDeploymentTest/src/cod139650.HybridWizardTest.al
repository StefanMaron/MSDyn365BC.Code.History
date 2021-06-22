codeunit 139650 "Hybrid Wizard Tests"
{
    // [FEATURE] [Intelligent Edge Hybrid Wizard]
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InitializePage(var wizard: TestPage "Hybrid Cloud Setup Wizard"; IsSaas: Boolean; AgreePrivacy: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        assistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaas);
        assistedSetupTestLibrary.SetStatusToNotCompleted('58623bfa-0559-4bc2-ae1c-0979c29fd9e0', Page::"Hybrid Cloud Setup Wizard");
        wizard.Trap();

        Page.Run(Page::"Hybrid Cloud Setup Wizard");
        wizard.AgreePrivacy.SetValue(AgreePrivacy);
    end;

    local procedure Initialize()
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not Initialized then begin
            HybridDeploymentSetup.DeleteAll();
            HybridDeploymentSetup."Handler Codeunit ID" := Codeunit::"Library - Hybrid Management";
            HybridDeploymentSetup.Insert();
            BindSubscription(LibraryHybridManagement);
            HybridDeploymentSetup.Get();
        end;

        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TestWelcomePrivacyAgree()
    var
        wizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User starts wizard from Saas environment and doesn't accept privacy.

        // [GIVEN] User starts the wizard.
        InitializePage(wizard, true, false);

        // [THEN] Next is disabled.
        Assert.AreEqual(false, wizard.ActionNext.Enabled(), 'Next should be disabled when privacy is not accepted');

        // [GIVEN] User accepts privacy statement.
        wizard.AgreePrivacy.SetValue(true);

        // [THEN] Next is enabled.
        Assert.AreEqual(true, wizard.ActionNext.Enabled(), 'Next should be enabled when privacy is accepted');
    end;

    [Test]
    [HandlerFunctions('ProductsPageHandler,ConfirmYesHandler')]
    procedure TestStatusNotCompletedWhenNotFinished()
    var
        assistedSetup: Codeunit "Assisted Setup";
        wizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User starts wizard from Saas environment and exits wizard before finishing.

        // [GIVEN] User starts the wizard.
        InitializePage(wizard, true, true);

        with wizard do begin
            // [GIVEN] User clicks 'Next' on Welcome window.
            ActionNext.Invoke();

            // [WHEN] User selects a product and clicks 'Next' on Dynamics Product window.
            "Product Name".AssistEdit();
            ActionNext.Invoke();

            // [WHEN] User exists wizard before finishing.
            Close();
        end;

        // [THEN] Status of assisted setup remains not completed.
        Assert.IsFalse(assistedSetup.IsComplete('58623bfa-0559-4bc2-ae1c-0979c29fd9e0', Page::"Hybrid Cloud Setup Wizard"), 'Wizard status should not be completed.');
    end;

    [Test]
    procedure TestSaasWelcomeActions()
    var
        wizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User starts wizard from Saas environment.

        // [WHEN] User starts the wizard.
        InitializePage(wizard, true, true);

        // [THEN] The welcome window should open in saas mode.
        VerifySaasWelcomeWindow(wizard, 1);
    end;

    [Test]
    [HandlerFunctions('ProductsPageHandler')]
    procedure TestDynamicsProductWindow()
    var
        libraryHybridManagement: Codeunit "Library - Hybrid Management";
        wizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User starts wizard from saas environment and navigates to Dynamics Product window.

        // [GIVEN] User starts the wizard.
        InitializePage(wizard, true, true);

        with wizard do begin
            // [WHEN] User clicks 'Next' on Welcome window.
            ActionNext.Invoke();

            // [THEN] Dynamics Product window is displayed.
            VerifySaasDynamicsProductWindow(wizard, 1);

            // [WHEN] User clicks 'Next' with out selecting a product.
            asserterror ActionNext.Invoke();

            // [THEN] An error is displayed that a product must be selected.
            Assert.ExpectedError(SelectProductErr);

            // [WHEN] User selects a product
            "Product Name".AssistEdit();

            // [THEN] The product is correctly selected and the user can click 'Next'
            Assert.AreEqual(libraryHybridManagement.GetTestProductName(), "Product Name".Value(), 'Correct product name was not selected.');
            ActionNext.Invoke();
        end;
    end;

    [Test]
    [HandlerFunctions('ProductsPageHandler')]
    procedure TestNoSqlConnectionStringError()
    var
        wizard: TestPage "Hybrid Cloud Setup Wizard";
    begin
        // [SCENARIO] User navigates wizard with out entering SQL connection string.

        // [GIVEN] User starts the wizard.
        InitializePage(wizard, true, true);

        with wizard do begin
            // [GIVEN] User clicks 'Next' on Welcome window.
            ActionNext.Invoke();

            // [WHEN] User selects a product and clicks 'Next' on Dynamics Product window.
            "Product Name".AssistEdit();
            ActionNext.Invoke();

            // [WHEN] User clicks 'Next' on SQL Conection window.
            asserterror ActionNext.Invoke();

            // [THEN] Error message is displayed.
            Assert.ExpectedError(SqlConnectionStringMissingErr);
        end;
    end;

    local procedure VerifySaasWelcomeWindow(wizard: TestPage "Hybrid Cloud Setup Wizard"; executeNumber: Integer)
    begin
        with wizard do begin
            Assert.IsFalse(ActionBack.Enabled(), StrSubstNo('Welcome window ActionBack should be disabled. Run %1', executeNumber));
            Assert.IsTrue(ActionNext.Enabled(), StrSubstNo('Welcome window ActionNext should be enabled. Run %1', executeNumber));
            Assert.IsFalse(ActionFinish.Enabled(), StrSubstNo('Welcome window ActionFinish should be disabled. Run %1', executeNumber));
        end;
    end;

    local procedure VerifySaasDynamicsProductWindow(wizard: TestPage "Hybrid Cloud Setup Wizard"; executeNumber: Integer)
    begin
        with wizard do begin
            Assert.IsTrue(ActionBack.Enabled(), StrSubstNo('Dynamics Product window ActionBack should be enabled. Run %1', executeNumber));
            Assert.IsTrue(ActionNext.Enabled(), StrSubstNo('Dynamics Product window ActionNext should be enabled. Run %1', executeNumber));
            Assert.IsFalse(ActionFinish.Enabled(), StrSubstNo('Dynamics Product window ActionFinish should be disabled. Run %1', executeNumber));
        end;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(question: Text[1024]; var reply: Boolean)
    begin
        reply := true;
    end;

    [ModalPageHandler]
    procedure ProductsPageHandler(var productPage: TestPage "Hybrid Product Types")
    var
        libraryHybridManagement: Codeunit "Library - Hybrid Management";
    begin
        productPage.FindFirstField("Display Name", libraryHybridManagement.GetTestProductName());
        productPage.OK().Invoke();
    end;

    var
        Assert: Codeunit Assert;
        LibraryHybridManagement: Codeunit "Library - Hybrid Management";
        Initialized: Boolean;
        SqlConnectionStringMissingErr: Label 'Please enter a valid SQL connection string.';
        SelectProductErr: Label 'You must select a product to continue.';
}
