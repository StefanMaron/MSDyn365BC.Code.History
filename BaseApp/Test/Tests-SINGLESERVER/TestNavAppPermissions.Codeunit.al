codeunit 134611 "Test Nav App Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [NAV App] [Permissions]
    end;

    var
        User: Record User;
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        AppPermissionSet: Record "Tenant Permission Set";
        Permission: Record Permission;
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        NullGuid: Guid;
        PermissionRoles: array[2] of Code[20];
        TenantPermissionRoles: array[2] of Code[20];
        AppPermissionRoles: array[2] of Code[20];
        AppGUIDs: array[2] of Guid;

    local procedure InitializeData()
    var
        PublishedApplication: Record "Published Application";
        i: Integer;
    begin
        Clear(NullGuid); // Ensure the null GUID is cleared
        User.DeleteAll();

        // Need to add at least one super user.
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");

        // Set up 3 users
        for i := 1 to 3 do
            LibraryPermissions.CreateUser(User, LibraryUtility.GenerateRandomAlphabeticText(10, 0), false);

        // Set up 3 groups
        for i := 1 to 3 do
            LibraryPermissions.CreateUserGroup(
              UserGroup, LibraryUtility.GenerateRandomCode(UserGroup.FieldNo(Code), DATABASE::"User Group"));

        // Set up 2 system permission sets
        for i := 1 to 2 do begin
            PermissionRoles[i] := LibraryUtility.GenerateRandomCode(PermissionSet.FieldNo("Role ID"), DATABASE::"Permission Set");
            LibraryPermissions.CreatePermissionSet(PermissionSet, PermissionRoles[i]);
        end;

        // Add permissions to the new permission sets
        PermissionSet.Find('-');
        LibraryPermissions.AddPermission(PermissionRoles[1], Permission."Object Type"::Report, REPORT::Statement);
        LibraryPermissions.AddPermission(PermissionRoles[1], Permission."Object Type"::Report, REPORT::"Standard Statement");

        PermissionSet.Next;
        LibraryPermissions.AddPermission(PermissionRoles[2], Permission."Object Type"::Report, REPORT::"Sales - Quote");
        LibraryPermissions.AddPermission(PermissionRoles[2], Permission."Object Type"::Report, REPORT::"Standard Sales - Quote");

        // Set up 2 tenant permission sets (non-app)
        for i := 1 to 2 do begin
            TenantPermissionRoles[i] :=
              LibraryUtility.GenerateRandomCode(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Permission Set");
            LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, TenantPermissionRoles[i], NullGuid);
        end;

        // Add permissions to the new permission sets
        TenantPermissionSet.Find('-');
        LibraryPermissions.AddPermission(TenantPermissionRoles[1], Permission."Object Type"::Table, DATABASE::Customer);
        LibraryPermissions.AddPermission(TenantPermissionRoles[1], Permission."Object Type"::Table, DATABASE::Vendor);
        TenantPermissionSet.Next;
        LibraryPermissions.AddPermission(TenantPermissionRoles[2], Permission."Object Type"::Table, DATABASE::"Sales Header");
        LibraryPermissions.AddPermission(TenantPermissionRoles[2], Permission."Object Type"::Table, DATABASE::"Sales Invoice Header");

        // Set up 2 Nav App permission sets
        for i := 1 to 2 do begin
            AppPermissionRoles[i] := LibraryUtility.GenerateRandomCode(AppPermissionSet.FieldNo("Role ID"), DATABASE::"Permission Set");
            AppGUIDs[i] := CreateGuid;
            LibraryPermissions.CreateTenantPermissionSet(AppPermissionSet, AppPermissionRoles[i], AppGUIDs[i]);
        end;
        PublishedApplication.Init();
        PublishedApplication."Package ID" := AppGUIDs[1];
        PublishedApplication."Runtime Package ID" := AppGUIDs[1];
        PublishedApplication.ID := AppGUIDs[1];
        PublishedApplication.Name := LibraryUtility.GenerateGUID;
        PublishedApplication.Insert();

        PublishedApplication.Init();
        PublishedApplication."Package ID" := AppGUIDs[2];
        PublishedApplication."Runtime Package ID" := AppGUIDs[2];
        PublishedApplication.ID := AppGUIDs[2];
        PublishedApplication.Name := LibraryUtility.GenerateGUID;
        PublishedApplication.Insert();

        // Add permissions to the new permission sets
        AppPermissionSet.Get(AppGUIDs[1], AppPermissionRoles[1]);
        LibraryPermissions.AddPermission(AppPermissionRoles[1], Permission."Object Type"::Table, PAGE::"Customer Card");
        LibraryPermissions.AddPermission(AppPermissionRoles[1], Permission."Object Type"::Table, PAGE::"Vendor Card");
        AppPermissionSet.Next;
        LibraryPermissions.AddPermission(AppPermissionRoles[2], Permission."Object Type"::Table, PAGE::"Customer Statistics");
        LibraryPermissions.AddPermission(AppPermissionRoles[2], Permission."Object Type"::Table, PAGE::"Vendor Statistics");
    end;

    local procedure CreateSuperUser(): Guid
    var
        LibraryPermissions: Codeunit "Library - Permissions";
        UserPermissions: Codeunit "Users - Create Super User";
    begin
        LibraryPermissions.CreateUser(User, LibraryUtility.GenerateRandomAlphabeticText(10, 0), false);
        UserPermissions.AddUserAsSuper(User);

        exit(User."User Security ID");
    end;


    [Normal]
    [Scope('OnPrem')]
    procedure CleanupData()
    var
        User: Record User;
        UserSetup: Record "User Setup";
        AccessControl: Record "Access Control";
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        // When we add any user into User table Server switches authentication mode
        // and further tests fail with permission error until Server is restarted.
        // Automatic rollback in test isolation does not revert Server's authentication mode.
        // In this case we need manually clean up User table if test passed and User table
        // is modified during this test.
        // User Setup must cleaned too, due to reference to User table.
        User.SetFilter("User Name", '<>%1', UserId);
        User.DeleteAll();
        UserSetup.DeleteAll();
        AccessControl.DeleteAll();
        UserGroup.DeleteAll();
        UserGroupMember.DeleteAll();
        UserGroupAccessControl.DeleteAll();
        UserGroupPermissionSet.DeleteAll();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAggregatePermissionSetsTable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        // Test that the aggregate permission set table contains permission sets from the system
        // and the Nav App

        // Init
        InitializeData;

        // Execute

        // Verify

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, NullGuid, PermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, NullGuid, PermissionRoles[2]);

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, NullGuid, TenantPermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, NullGuid, TenantPermissionRoles[2]);

        // Ensure the App-level permissions are set appropriate and visibile in both tables.
        AppPermissionSet.Get(AppGUIDs[1], AppPermissionRoles[1]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, AppPermissionSet."App ID", AppPermissionSet."Role ID");
        AppPermissionSet.Get(AppGUIDs[2], AppPermissionRoles[2]);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, AppPermissionSet."App ID", AppPermissionSet."Role ID");

        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSets()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        PermissionSets: TestPage "Permission Sets";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets page
        // Init
        InitializeData;

        // Execute
        PermissionSets.OpenView;

        // Find a system permission set
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::System);
        AggregatePermissionSet.FindFirst;
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::System), AggregatePermissionSet."Role ID");

        // Find a tenant permission set

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", NullGuid);
        AggregatePermissionSet.FindFirst;
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::"User-Defined"), AggregatePermissionSet."Role ID");

        // Find the application permission sets

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst;
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::Extension), AggregatePermissionSet."Role ID");
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSets."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSets.PermissionSet.Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst;
        PointPermissionSetPageToRole(PermissionSets, Format(PermissionSetBuffer.Type::Extension), AggregatePermissionSet."Role ID");
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSets."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSets.PermissionSet.Value, 'Role ID mismatch');

        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSetsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets By User page
        // Init
        InitializeData;

        // Execute
        PermissionSetByUser.OpenView;

        // Verify

        // Find the application permission sets
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUser."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUser."Role ID".Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUser."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUser."Role ID".Value, 'Role ID mismatch');

        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestViewAggregatePermissionsSetsByUserGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUserGroup: TestPage "Permission Set by User Group";
    begin
        // Test that the aggregate permission sets are viewable in the Permission Sets By User Group page
        // Init
        InitializeData;

        // Execute
        PermissionSetByUserGroup.OpenView;

        // Verify
        // Find the application permission sets
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.FindFirst;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUserGroup."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUserGroup."Role ID".Value, 'Role ID mismatch');

        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.SetRange("App ID", AppGUIDs[2]);
        AggregatePermissionSet.FindFirst;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Assert.AreEqual(AggregatePermissionSet."App Name", PermissionSetByUserGroup."App Name".Value, 'App Name mismatched');
        Assert.AreEqual(AggregatePermissionSet."Role ID", PermissionSetByUserGroup."Role ID".Value, 'Role ID mismatch');

        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionSet()
    var
        PermissionSets: TestPage "Permission Sets";
    begin
        // Test that a permission set can be added through the Permission Set Page
        // Init
        InitializeData;

        // Execute
        PermissionSets.OpenEdit;
        PermissionSets.New;

        asserterror PermissionSets.PermissionSet.SetValue('MyRole');
        PermissionSets.Close;

        // Verify
        Assert.KnownFailure('Validation error for Field: PermissionSet', 281244);
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Column1.SetValue(true);
        PermissionSetByUser.Close;

        // Verify
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));

        PermissionSetByUser.Close;
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUserAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close;

        // Verify
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUser.Column2.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo('Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column2.Caption));

        PermissionSetByUser.Close;
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUserGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUserGroup: TestPage "Permission Set by User Group";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.Column1.Caption));
        PermissionSetByUserGroup.Column1.SetValue(true);
        PermissionSetByUserGroup.Close;

        // Verify
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID", PermissionSetByUserGroup.Column1.Caption));

        PermissionSetByUserGroup.Close;
        CleanupData;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionsByUserGroupAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUserGroup: TestPage "Permission Set by User Group";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.AllUsersHavePermission.Caption));
        PermissionSetByUserGroup.AllUsersHavePermission.SetValue(true);
        UserGroup.SetRange(Customized, false);
        Assert.RecordCount(UserGroup, 0);
        PermissionSetByUserGroup.Close;

        // Verify
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.AllUsersHavePermission.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID", PermissionSetByUserGroup.Column1.Caption));

        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column2.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID", PermissionSetByUserGroup.Column2.Caption));

        PermissionSetByUserGroup.Close;
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUser()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test removing a permission for a given user through the UI
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Column1.SetValue(true);
        PermissionSetByUser.Close;

        // Delete the permission
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        PermissionSetByUser.Column1.SetValue(false);
        PermissionSetByUser.Close;

        // Verify
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        PermissionSetByUser.Close;

        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUserAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close;

        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        PermissionSetByUser.AllUsersHavePermission.SetValue(false);
        PermissionSetByUser.Close;

        // Verify
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUser.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column1.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUser.Column2.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID", PermissionSetByUser.Column2.Caption));

        PermissionSetByUser.Close;
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemoveSUPERPermissionsByUserAll()
    var
        SuperPermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUser: TestPage "Permission Set by User";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsPermissionSetEnabled: Boolean;
    begin
        // [Scenario] User is not able to remove the SUPER permission set from all users.
        // Init
        InitializeData();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // Find SUPER permission set
        SuperPermissionSet.SetRange("Role ID", 'SUPER');
        SuperPermissionSet.SetRange(Scope, SuperPermissionSet.Scope::System);
        Assert.IsTrue(SuperPermissionSet.FindFirst(), 'Aggregate Permission Set must have a SUPER entry');

        // Execute
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(SuperPermissionSet);
        Evaluate(IsPermissionSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);

        // Verify
        Assert.IsFalse(
          IsPermissionSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        // Execute
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close;
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(SuperPermissionSet);
        Evaluate(IsPermissionSetEnabled, PermissionSetByUser.AllUsersHavePermission.Value);

        // Verify
        Assert.IsTrue(
          IsPermissionSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUser."Role ID",
            PermissionSetByUser.AllUsersHavePermission.Caption));

        // Execute
        asserterror PermissionSetByUser.AllUsersHavePermission.SetValue(false);

        // Verify
        Assert.AreEqual(1, PermissionSetByUser.AllUsersHavePermission.ValidationErrorCount(), 'Wrong number of validation errors');
        Assert.AreEqual('There should be at least one enabled ''SUPER'' user.', PermissionSetByUser.AllUsersHavePermission.GetValidationError(1), 'Wrong validation error message');

        PermissionSetByUser.Close;

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        CleanupData;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUserGroup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUserGroup: TestPage "Permission Set by User Group";
        PermSetEnabled: Boolean;
    begin
        // Test that users can be assigned Nav App permissions in the Permission Sets By User page
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.Column1.Caption));
        PermissionSetByUserGroup.Column1.SetValue(true);
        PermissionSetByUserGroup.Close;

        // Verify
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID", PermissionSetByUserGroup.Column1.Caption));
        PermissionSetByUserGroup.Column1.SetValue(false);
        PermissionSetByUserGroup.Close;

        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.Column1.Caption));

        PermissionSetByUserGroup.Close;
        CleanupData;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionsByUserGroupAll()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetByUserGroup: TestPage "Permission Set by User Group";
        PermSetEnabled: Boolean;
    begin
        // Test that permissions can be added to Nav App permissions in the Permission Sets By User page by selecting the item to select all
        // Init
        InitializeData;

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Execute
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.AllUsersHavePermission.Caption));
        PermissionSetByUserGroup.AllUsersHavePermission.SetValue(true);
        PermissionSetByUserGroup.Close;

        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.AllUsersHavePermission.Value);
        Assert.IsTrue(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.AllUsersHavePermission.Caption));
        PermissionSetByUserGroup.AllUsersHavePermission.SetValue(false);
        PermissionSetByUserGroup.Close;

        // Verify
        PermissionSetByUserGroup.OpenView;
        PermissionSetByUserGroup.GotoRecord(AggregatePermissionSet);
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.AllUsersHavePermission.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.AllUsersHavePermission.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column1.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.Column1.Caption));
        Evaluate(PermSetEnabled, PermissionSetByUserGroup.Column2.Value);
        Assert.IsFalse(
          PermSetEnabled,
          StrSubstNo(
            'Expected permission set %1 to not be enabled for %2', PermissionSetByUserGroup."Role ID",
            PermissionSetByUserGroup.Column2.Caption));

        PermissionSetByUserGroup.Close;
        CleanupData;
    end;

    [Normal]
    [HandlerFunctions('PermissionSetLookupHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetLookup()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AccessControl: Record "Access Control";
        User: Record User;
        UserPermissionSets: TestPage "User Permission Sets";
        PermissionSetByUser: TestPage "Permission Set by User";
    begin
        // Test the lookup page for aggregate permission sets
        // Init
        InitializeData;

        User.FindLast; // Find a record

        AggregatePermissionSet.SetRange("App ID", AppGUIDs[1]);
        AggregatePermissionSet.SetRange(Scope, AggregatePermissionSet.Scope::Tenant);
        AggregatePermissionSet.FindFirst;

        // Set the permission - should generate an AccessControl record
        PermissionSetByUser.OpenView;
        PermissionSetByUser.GotoRecord(AggregatePermissionSet);
        PermissionSetByUser.AllUsersHavePermission.SetValue(true);
        PermissionSetByUser.Close;

        // Execute
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.FindFirst;

        UserPermissionSets.OpenEdit;
        UserPermissionSets.FILTER.SetFilter("User Security ID", User."User Security ID");
        UserPermissionSets.GotoRecord(AccessControl);
        UserPermissionSets.PermissionSet.Lookup;

        UserPermissionSets.Close;

        CleanupData;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PermissionSetLookupHandler(var PermissionSetLookup: TestPage "Permission Set Lookup")
    begin
        PermissionSetLookup.Last;
        PermissionSetLookup.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [Scope('OnPrem')]
    procedure PointPermissionSetPageToRole(var PermissionSetsPage: TestPage "Permission Sets"; TypeText: Text; RoleId: Code[20])
    begin
        PermissionSetsPage.First;
        if PermissionSetsPage.PermissionSet.Value = RoleId then
            if PermissionSetsPage.Type.Value = TypeText then
                exit;

        while PermissionSetsPage.Next do
            if PermissionSetsPage.PermissionSet.Value = RoleId then
                if PermissionSetsPage.Type.Value = TypeText then
                    exit;

        Assert.Fail('Newly created tenant permission set not found.');
    end;
}

