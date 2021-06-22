codeunit 138888 "SmartList Designer Page Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSmartListSetupPageDoesNotShowWhenNotConfigured()
    var
        designerPage: TestPage "SmartList Designer";
    begin
        // [SCENARIO] User opens up designer page in a non-saas environment

        // [GIVEN] User opens the page
        // [WHEN] The environment config is not SaaS
        InitializePage(designerPage, false);

        // [THEN] The setup page does not appear
        Assert.IsFalse(SetupOpened, 'The setup window should not have opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSmartListPageThrowExceptionForUnauthorizedUserWhenConfigured()
    var
        designerPage: TestPage "SmartList Designer";
    begin
        // [SCENARIO] User opens up designer page in a non-saas environment

        // [GIVEN] User without access to System object 9600 (SmartListDesigner API) opens the page
        // [WHEN] The environment config is SaaS
        // [THEN] The page throw an exception
        asserterror InitializePage(designerPage, true);
    end;

    local procedure InitializePage(var designerPage: TestPage "SmartList Designer"; IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        Initialize();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaas);

        designerPage.Trap();
        Page.Run(PAGE::"SmartList Designer");
    end;

    local procedure Initialize()
    var
        SmartListSetupTable: Record "SmartList Designer Setup";
    begin
        if not IsInitialized then begin
            SmartListSetupTable.DeleteAll();
        end;
        SetupOpened := false;

        IsInitialized := true;
    end;

    var
        Assert: Codeunit Assert;
        SetupOpened: Boolean;
        IsInitialized: Boolean;
}