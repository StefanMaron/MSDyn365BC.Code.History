codeunit 138890 "SmartList Designer Code Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenNotSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
    begin
        // [SCENARIO] IsEnabled is calculated when not in a SaaS configuration

        // [GIVEN] Config is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is false
        Assert.IsFalse(SmartListDesigner.IsEnabled(), 'IsEnabled should be false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
    begin
        // [SCENARIO] IsEnabled is calculated when in a SaaS configuration

        // [GIVEN] Config is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is true
        Assert.IsTrue(SmartListDesigner.IsEnabled(), 'IsEnabled should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenNoHandlerRegistered()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
        SmartListDesignerHandlerRec: Record "SmartList Designer Handler";
    begin
        // [SCENARIO] IsEnabled is calculated when in a SaaS configuration when no handler record exists yet

        // [GIVEN] Config is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] No SmartList Handler record exist
        SmartListDesignerHandlerRec.DeleteAll();

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is true
        Assert.IsTrue(SmartListDesigner.IsEnabled(), 'IsEnabled should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenHandlerRegisteredToBaseApp()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
        SmartListDesignerHandlerRec: Record "SmartList Designer Handler";
    begin
        // [SCENARIO] IsEnabled is calculated when in a SaaS configuration when a handler record exists for the 'Base Application' extension

        // [GIVEN] Config is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] SmartList Handler record exist for the 'Base Application' extension
        SmartListDesignerHandlerRec.DeleteAll();
        SmartListDesignerHandlerRec.Init();
        SmartListDesignerHandlerRec.HandlerExtensionId := '437DBF0E-84FF-417A-965D-ED2BB9650972';
        SmartListDesignerHandlerRec.Insert();

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is true
        Assert.IsTrue(SmartListDesigner.IsEnabled(), 'IsEnabled should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenHandlerRegisteredToNonInstalledExtension()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
        SmartListDesignerHandlerRec: Record "SmartList Designer Handler";
    begin
        // [SCENARIO] IsEnabled is calculated when in a SaaS configuration when a handler record exists for an extension which is not installed

        // [GIVEN] Config is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] SmartList Handler record exist for a random extension
        SmartListDesignerHandlerRec.DeleteAll();
        SmartListDesignerHandlerRec.Init();
        SmartListDesignerHandlerRec.HandlerExtensionId := CreateGuid();
        SmartListDesignerHandlerRec.Insert();

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is true
        Assert.IsTrue(SmartListDesigner.IsEnabled(), 'IsEnabled should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsEnabledWhenHandlerRegisteredToAnotherInstalledExtension()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
        SmartListDesignerHandlerRec: Record "SmartList Designer Handler";
        TestAppInfo: ModuleInfo;
    begin
        // [SCENARIO] IsEnabled is calculated when in a SaaS configuration when a handler record exists for an extension which is installed

        // [GIVEN] Config is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] SmartList Handler record exist for a different currently installed extension
        NavApp.GetCurrentModuleInfo(TestAppInfo);
        SmartListDesignerHandlerRec.DeleteAll();
        SmartListDesignerHandlerRec.Init();
        SmartListDesignerHandlerRec.HandlerExtensionId := TestAppInfo.Id();
        SmartListDesignerHandlerRec.Insert();

        // [WHEN] IsEnabled is invoked
        // [THEN] The result is false
        Assert.IsFalse(SmartListDesigner.IsEnabled(), 'IsEnabled should be false');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunForQueryThrowsWhenNotEnabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
    begin
        // [SCENARIO] RunForQuery is invoked when not in a SaaS configuration

        // [GIVEN] Config is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] RunForQuery is invoked
        // [THEN] An error is thrown
        asserterror SmartListDesigner.RunForQuery(CreateGuid());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunForTableThrowsWhenNotEnabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SmartListDesigner: Codeunit "SmartList Designer";
    begin
        // [SCENARIO] RunForTable is invoked when not in a SaaS configuration

        // [GIVEN] Config is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] RunForTable is invoked
        // [THEN] An error is thrown
        asserterror SmartListDesigner.RunForTable(888);

    end;

    var
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        IsInitialized: Boolean;
}