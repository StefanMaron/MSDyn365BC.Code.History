codeunit 139321 "Teams Centralized Depl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Teams Centralized Deployment]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        TeamsCentralizedDeployment.Close();
        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenFinishedOnPrem()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        with TeamsCentralizedDeployment do begin
            Assert.IsFalse(ActionBack.Visible(), 'Back is visible');
            Assert.IsFalse(ActionDone.Visible(), 'Done is visible');
            Assert.IsFalse(ActionNext.Visible(), 'Next is visible');
            Assert.IsTrue(ActionOkay.Visible(), 'Okay is not visible');
            ActionOkay.Invoke();
        end;
        // [THEN] Status of the setup step is not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinishedOnSaaS()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TeamsCentralizedDeployment: TestPage "Teams Centralized Deployment";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [GIVEN] A newly setup company in Saas
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The Teams Centralized Deployment is completed
        TeamsCentralizedDeployment.Trap();
        Page.Run(Page::"Teams Centralized Deployment");
        with TeamsCentralizedDeployment do begin
            Assert.IsTrue(ActionNext.Visible(), 'Next is not visible');
            Assert.IsTrue(ActionBack.Visible(), 'Back is not visible');
            Assert.IsFalse(ActionBack.Enabled(), 'Back is enabled');
            Assert.IsFalse(ActionDone.Visible(), 'Done is visible');
            Assert.IsFalse(ActionOkay.Visible(), 'Okay is visible');
            ActionNext.Invoke();
            Assert.IsTrue(ActionNext.Visible(), 'Next is not visible');
            Assert.IsTrue(ActionBack.Visible(), 'Back is not visible');
            Assert.IsTrue(ActionBack.Enabled(), 'Back is not enabled');
            Assert.IsFalse(ActionDone.Visible(), 'Done is visible');
            Assert.IsFalse(ActionOkay.Visible(), 'Okay is visible');
            ActionNext.Invoke();
            Assert.IsFalse(ActionNext.Visible(), 'Next is visible');
            Assert.IsTrue(ActionBack.Visible(), 'Back is not visible');
            Assert.IsTrue(ActionBack.Enabled(), 'Back is not enabled');
            Assert.IsTrue(ActionDone.Visible(), 'Done is not visible');
            Assert.IsFalse(ActionOkay.Visible(), 'Okay is visible');
            
        end;
        TeamsCentralizedDeployment.ActionDone.Invoke();

        // [THEN] Status of the setup step is set to Completed
        if GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Teams Centralized Deployment") then
            Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Teams Centralized Deployment"), 'Teams Centralized Deployment Setup status should be completed.');
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;
}
