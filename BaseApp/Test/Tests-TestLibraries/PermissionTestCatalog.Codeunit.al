codeunit 132218 "Permission Test Catalog"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LocalizedPermissionsTest: Codeunit "Localized Permissions Test";
        MustChangePermissionsErr: Label 'You must change permissions at least once in your tests (at least the execute step).';
        IsPermissionTestingEnabled: Boolean;
        IsD365BuildEnabled: Boolean;
        Initialized: Boolean;
        IsLoggingOn: Boolean;

    procedure InitializePermissionSetForTest(FunctionTestPermissions: TestPermissions): Boolean
    begin
        // initialize Permissionset level based on all available information
        // case 1 - Test Permission DISABLED - no change (SUPER)
        // case 2 - Build disabled for permission test - no change (SUPER)
        // case 3 - Build enabled for permission test and TestPermissions not Restrictive - no change(SUPER)
        // case 4 - Build enabled for permission test and TestPermissions Restrictive - O365 FULL ACCESS
        IsLoggingOn := false;

        if not InitializeBuildRelatedVariables then
            exit(false);

        // check if test permission DISABLED
        if FunctionTestPermissions = TESTPERMISSIONS::Disabled then
            exit;

        IsLoggingOn := true;

        // check if permission test level should be lowered to O365 Full Access
        if IsD365BuildEnabled then
            // Lower permission to D365 Full Access (Non-Restrictive, Restrictive)
            LibraryLowerPermissions.StartLoggingNAVPermissions('D365 Full Access')
        else
            LibraryLowerPermissions.StartLoggingNAVPermissions('SUPER');
    end;

    local procedure InitializeBuildRelatedVariables(): Boolean
    begin
        // inititalize variables related to Country/Region
        // 1. If Country/Region has D365 company in SNAP as in that case Demo Data is different
        // 2. If Country/Region is enabled for Permission testing
        IsD365BuildEnabled := LocalizedPermissionsTest.EnableD365Build;
        IsPermissionTestingEnabled := LocalizedPermissionsTest.EnablePermissionTests;

        Initialized := IsPermissionTestingEnabled;
        exit(Initialized);
    end;

    procedure GetPermissionErrors(FunctionTestPermissions: TestPermissions): Text
    var
        Disable: Boolean;
    begin
        // collect Errors if Lib was initialized
        if not Initialized then
            exit;

        if not IsLoggingOn then
            exit;

        LibraryLowerPermissions.StopLoggingNAVPermissions;

        LibraryLowerPermissions.OnGetDisableEnforcingPermissionChange(Disable);
        if Disable then
            exit;

        if (FunctionTestPermissions = TESTPERMISSIONS::Restrictive) and
           (not LibraryLowerPermissions.HasChangedPermissions)
        then
            exit(MustChangePermissionsErr);
    end;
}

