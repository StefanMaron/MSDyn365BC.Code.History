codeunit 134610 "Test User Group Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [User Group] [Permission Set]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        GlobalSourcePermissionSetRoleID: Code[20];
        CopyToUserGroup: Code[20];
        CopyToPermissionSet: Code[20];
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        WrongUserGroupCodeErr: Label 'Wrong User Group Code.';
        WrongRoleIDErr: Label 'Wrong Role ID for User Group.';
        SubscriptionPlanTok: Label 'My subscription plan';
        XTestPermissionTxt: Label 'TEST PERMISSION';

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateSuperUser()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        Permission: Record Permission;
        Users: TestPage Users;
    begin
        // Tests codeunit 9000 - creation of an admin/SUPER user for currently logged in user.
        // Init: Not possible to delete existing users, so this will only give full coverage in a clean DB

        // Execute
        Users.OpenEdit;
        Users.AddMeAsSuper.Invoke;
        Users.Close;

        // Verify
        LibraryPermissions.GetMyUser(User);
        AccessControl.Get(User."User Security ID", 'SUPER');
        Permission.SetRange("Role ID", 'SUPER');
        Assert.IsTrue(Permission.Count >= 9, '');
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupOnDelete1()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        // Verify that the OnDelete trigger of table 9000 also deletes from table 9003.
        // Init
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        CreateUserGroupPermissionSet(UserGroupPermissionSet, UserGroup.Code, 'X');
        UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
        Assert.AreEqual(1, UserGroupPermissionSet.Count, '');

        // Execute
        UserGroup.Delete(true);

        // Verfiy
        Assert.AreEqual(0, UserGroupPermissionSet.Count, '');
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupOnDeleteFail()
    var
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
    begin
        // Verify that the OnDelete trigger of table 9000 prevents deletion if there are members.
        // Init
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.CreateUserGroupMember(UserGroup, UserGroupMember);

        // Execute + Verfiy
        asserterror UserGroup.Delete(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupOnDeleteFailsIfPartOfAPlan()
    var
        UserGroup: Record "User Group";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        // Verify that the OnDelete trigger of table 9000 prevents deletion if there are members.
        // Init
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.AddUserGroupToPlan(UserGroup.Code, AzureADPlanTestLibrary.CreatePlan(CreateGuid));

        // Execute + Verfiy
        asserterror UserGroup.Delete(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupIsUserMember()
    var
        User: Record User;
        UserGroup: Record "User Group";
    begin
        // Test function IsUserMember in table 9000
        // Init
        LibraryPermissions.GetMyUser(User);
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        Assert.IsFalse(UserGroup.IsUserMember(User, ''), '');
        LibraryPermissions.AddUserToUserGroup(UserGroup, User, '');

        // Execute / validate
        Assert.IsTrue(UserGroup.IsUserMember(User, ''), '');
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupSetMemberShip()
    var
        User: Record User;
        UserGroup: Record "User Group";
    begin
        // Test function SetUserGroupMemberShip in table 9000
        // Init
        LibraryPermissions.GetMyUser(User);
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        Assert.IsFalse(UserGroup.IsUserMember(User, ''), '');

        // Execute
        UserGroup.SetUserGroupMembership(User, true, '');
        Assert.IsTrue(UserGroup.IsUserMember(User, ''), '');
        UserGroup.SetUserGroupMembership(User, false, '');

        // Validate
        Assert.IsFalse(UserGroup.IsUserMember(User, ''), '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('UserLookupHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupMemberAddUsers()
    var
        User: Record User;
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
    begin
        // Tests the lookup and addition of a user as a new member.
        // Init
        Initialize;
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.CreateUser(User, '', false);
        UserGroupMember.SetRange("User Group Code", UserGroup.Code);
        Assert.AreEqual(0, UserGroupMember.Count, '');

        // Execution
        UserGroupMember.AddUsers('');

        // Verification
        Assert.AreEqual(1, UserGroupMember.Count, '');
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupMemberOnInsert()
    begin
        // Test the OnInsert trigger of table 9001
        VerifyUserGroupMemberInsertDelete(false);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupMemberOnDelete()
    begin
        // Test the OnDelete trigger of table 9001
        VerifyUserGroupMemberInsertDelete(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupPermissionSetOnInsert()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserSecurityID: Guid;
        UserGroupCode: Code[20];
    begin
        // [SCENARIO] OnInsert trigger of table 9003 "User Group Permission Set"

        // [GIVEN] User "U" in User Group "UG"
        CreateUserGroupWithUser(UserSecurityID, UserGroupCode);

        // [WHEN] Add new Permission Set "P" to group "UG"
        CreateUserGroupPermissionSet(UserGroupPermissionSet, UserGroupCode, CreatePermissionSet);

        // [THEN] User "U" has Permission Set "P"
        VerifyUserGroupAccessControlCount(UserGroupCode, UserSecurityID, 1);

        // Tear Down
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupPermissionSetOnDelete()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserSecurityID: Guid;
        UserGroupCode: Code[20];
    begin
        // [SCENARIO] OnDelete trigger of table 9003 "User Group Permission Set"

        // [GIVEN] User "U" in User Group "UG" with User Group Permission Set "P"
        CreateUserGroupWithUser(UserSecurityID, UserGroupCode);
        CreateUserGroupPermissionSet(UserGroupPermissionSet, UserGroupCode, CreatePermissionSet);

        // [WHEN] Delete User Gorup Permission Set "P"
        UserGroupPermissionSet.Delete(true);

        // [THEN] User "U" doesn't have Permission Set "P"
        VerifyUserGroupAccessControlCount(UserGroupCode, UserSecurityID, 0);

        // Tear Down
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupPermissionSetOnRename()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupAccessControl: Record "User Group Access Control";
        UserSecurityID: Guid;
        UserGroupCode: Code[20];
        NewRoleID: Code[20];
    begin
        // [SCENARIO 379087] OnRename trigger of table 9003 "User Group Permission Set"

        // [GIVEN] User "U" in User Group "UG" with User Group Permission Set "P"
        CreateUserGroupWithUser(UserSecurityID, UserGroupCode);
        CreateUserGroupPermissionSet(UserGroupPermissionSet, UserGroupCode, CreatePermissionSet);

        // [WHEN] Rename User Group Permission Set from "P" to "P2"
        NewRoleID := CreatePermissionSet;
        UserGroupPermissionSet.Rename(
          UserGroupPermissionSet."User Group Code", NewRoleID,
          UserGroupPermissionSet.Scope, UserGroupPermissionSet."App ID");

        // [THEN] User "U" doesn't have Permission Set "P"
        // [THEN] User "U" has Permission Set "P2"
        VerifyUserGroupAccessControlCount(UserGroupCode, UserSecurityID, 1);

        FilterUserGroupAccessControl(UserGroupAccessControl, UserGroupCode, UserSecurityID);
        UserGroupAccessControl.FindFirst;
        Assert.AreEqual(
          NewRoleID, UserGroupAccessControl."Role ID", UserGroupAccessControl.FieldCaption("Role ID"));

        // Tear Down
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('CopyUserGroupHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupsInvokeCopy()
    var
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroups: TestPage "User Groups";
    begin
        // Tests that invoking action Copy Permission Set starts report 9802.
        // Init
        CopyToUserGroup := CopyStr(GetGuidString, 1, 20);
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet."Role ID", UserGroup.Code);

        // Execute
        UserGroups.OpenEdit;
        UserGroups.GotoRecord(UserGroup);
        UserGroups.CopyUserGroup.Invoke;
        UserGroups.Close;

        // Verification: PageHandler is executed.
        UserGroup.Get(CopyToUserGroup);
        UserGroupPermissionSet.SetRange("User Group Code", UserGroup.Code);
        Assert.RecordCount(UserGroupPermissionSet, 1);
        UserGroupPermissionSet.FindFirst;
        Assert.AreEqual(PermissionSet."Role ID", UserGroupPermissionSet."Role ID", '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('ImportedMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupExportImport()
    var
        PermissionSet1: Record "Permission Set";
        PermissionSet2: Record "Permission Set";
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        UserGroupCount: Integer;
        UserGroupPermissionSetCount: Integer;
        i: Integer;
    begin
        // Exports and imports via xml port 9000
        // Verify preconditions: Tables are empty
        TestCleanup;
        Assert.AreEqual(0, UserGroup.Count, '');
        Assert.AreEqual(0, UserGroupPermissionSet.Count, '');

        // Init
        LibraryPermissions.CreatePermissionSet(PermissionSet1, '');
        LibraryPermissions.CreatePermissionSet(PermissionSet2, '');
        for i := 1 to 3 do begin
            LibraryPermissions.CreateUserGroup(UserGroup, '');
            LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet1."Role ID", UserGroup.Code);
            LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet2."Role ID", UserGroup.Code);
        end;

        UserGroupCount := UserGroup.Count;
        UserGroupPermissionSetCount := UserGroupPermissionSet.Count;
        Assert.AreEqual(3, UserGroupCount, '');
        Assert.AreEqual(6, UserGroupPermissionSetCount, '');
        FileName := FileManagement.ClientTempFileName('xml');

        // Execute
        FileName := UserGroup.ExportUserGroups(FileName);
        TestCleanup;
        Assert.AreEqual(0, UserGroup.Count, '');
        Assert.AreEqual(0, UserGroupPermissionSet.Count, '');
        UserGroup.ImportUserGroups(FileName);

        // Verify
        Assert.AreEqual(UserGroupCount, UserGroup.Count, '');
        Assert.AreEqual(UserGroupPermissionSetCount, UserGroupPermissionSet.Count, '');

        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOpenClosePermissionPageNoEdit1()
    begin
        // Ensure that open/close of an empty permission set does not inadvertedly creates a 0-permission
        VerifyOpenClosePermissionPageNoEdit(false);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOpenClosePermissionPageNoEdit2()
    begin
        // Ensure that open/close of a non-empty permission set does not inadvertedly creates a 0-permission
        VerifyOpenClosePermissionPageNoEdit(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOpenCloseAllPermissionPage1()
    begin
        // Ensure that open/close of an empty permission set does not inadvertedly creates a 0-permission
        VerifyOpenCloseAllPermissionPage(false);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOpenCloseAllPermissionPage2()
    begin
        // Ensure that open/close of an empty permission set does not inadvertedly creates a 0-permission
        VerifyOpenCloseAllPermissionPage(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionsPageInsertNewRecord1()
    begin
        // Tests insert of a new permission without inserting related tables
        VerifyPermissionsPageInsertNewRecord(false);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionsPageInsertNewRecordAddRelated()
    begin
        // Tests insert of a new permission and inserting related tables
        VerifyPermissionsPageInsertNewRecord(true);
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionsPageSecurityFilterAssistEdit()
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
        Permissions: TestPage Permissions;
    begin
        // Init;
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');
        Permission.SetRange("Role ID", PermissionSet."Role ID");
        Assert.AreEqual(0, Permission.Count, '');

        // Execute
        Permissions.OpenEdit;
        Permissions.CurrentRoleID.SetValue(PermissionSet."Role ID");
        Permissions."Security Filter".AssistEdit;

        // Verify is done by lookup-handler

        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionsPageAddRelatedTablesAction()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
    begin
        // Init
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, '', ZeroGUID);
        TenantPermission.SetRange("Role ID", TenantPermissionSet."Role ID");
        Assert.RecordIsEmpty(TenantPermission);

        // Execute
        TenantPermissions.OpenEdit;
        TenantPermissions.CurrentRoleID.SetValue(TenantPermissionSet."Role ID");
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue(TenantPermissions."Object Type".GetOption(1));
        TenantPermissions."Object ID".SetValue(DATABASE::"Sales Header");
        TenantPermissions.Control8.SetValue(TenantPermissions.Control8.GetOption(1));
        TenantPermissions.AddRelatedTablesAction.Invoke;
        TenantPermissions.Close;

        // Validate
        Assert.IsTrue(TenantPermission.Count > 1, 'Number of tenant permissions must be more than 1.');

        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserPage1()
    var
        User: Record User;
        PermissionSet: Record "Permission Set";
        AccessControl: Record "Access Control";
        PermissionSetbyUser: TestPage "Permission Set by User";
        MoreRecords: Boolean;
        FirstUserID: Text;
        SelectedPermissionSet: Code[20];
    begin
        // Test page 9816 which is a 'matrix'-like presentation of permission sets by users.
        // Init
        LibraryPermissions.CreateUsersUserGroupsPermissionSets;
        LibraryPermissions.GetMyUser(User);

        // Execute
        PermissionSetbyUser.OpenEdit;
        PermissionSetbyUser.ShowDomainName.SetValue(false);
        PermissionSetbyUser.SelectedCompany.SetValue(CompanyName);
        MoreRecords := PermissionSetbyUser.First;
        while MoreRecords and (CopyStr(PermissionSetbyUser."Role ID".Value, 1, 4) <> 'TEST') do
            MoreRecords := PermissionSetbyUser.Next;
        SelectedPermissionSet := PermissionSetbyUser."Role ID".Value;
        PermissionSet.Get(SelectedPermissionSet);

        AccessControl.SetRange("Company Name", CompanyName);
        AccessControl.SetRange("Role ID", PermissionSet."Role ID");
        Assert.AreEqual(0, AccessControl.Count, '');

        PermissionSetbyUser.AllUsersHavePermission.SetValue(true);
        PermissionSetbyUser.AllUsersHavePermission.SetValue(false);
        PermissionSetbyUser.Column1.SetValue(true);
        PermissionSetbyUser.Column2.SetValue(true);
        PermissionSetbyUser.Column3.SetValue(true);
        PermissionSetbyUser.Column4.SetValue(true);
        PermissionSetbyUser.Column5.SetValue(true);
        PermissionSetbyUser.Column6.SetValue(true);
        PermissionSetbyUser.Column7.SetValue(true);
        PermissionSetbyUser.Column8.SetValue(true);
        PermissionSetbyUser.Column9.SetValue(true);
        PermissionSetbyUser.Column10.SetValue(true);
        FirstUserID := PermissionSetbyUser.Column1.Caption;
        PermissionSetbyUser.ColumnRight.Invoke;
        while FirstUserID <> PermissionSetbyUser.Column1.Caption do begin
            PermissionSetbyUser.Column10.SetValue(true);
            FirstUserID := PermissionSetbyUser.Column1.Caption;
            PermissionSetbyUser.ColumnRight.Invoke;
        end;
        PermissionSetbyUser.AllColumnsLeft.Invoke;
        PermissionSetbyUser.ColumnLeft.Invoke;
        PermissionSetbyUser.AllColumnsRight.Invoke;

        // Validate
        Assert.AreEqual(User.Count, AccessControl.Count, '');
        PermissionSetbyUser.AllUsersHavePermission.SetValue(false);
        Assert.AreEqual(0, AccessControl.Count, '');
        PermissionSetbyUser.Close;
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetHandler,CopyPermissionSetSuccessMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserPageInvokeCopy()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetbyUser: TestPage "Permission Set by User";
        ZeroGUID: Guid;
    begin
        // Tests that invoking action Copy Permission Set starts report 9802.
        // Init
        LibraryVariableStorage.Clear;

        CopyToPermissionSet := CopyStr(GetGuidString, 1, 20);

        // Execute
        LibraryVariableStorage.Enqueue(CopyToPermissionSet);

        PermissionSetbyUser.OpenEdit;
        PermissionSetbyUser.First;
        PermissionSetbyUser.CopyPermissionSet.Invoke;
        PermissionSetbyUser.Close;

        // Verification: PageHandler is executed.

        TenantPermissionSet.Get(ZeroGUID, CopyToPermissionSet);
        TestCleanup;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestPermissionSetByUserGroupPage()
    var
        User: Record User;
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
        UserGroupPermissionSet: Record "User Group Permission Set";
        PermissionSetbyUserGroup: TestPage "Permission Set by User Group";
        MoreRecords: Boolean;
        FirstUserGroupCode: Text;
        LastUserGroupCode: Text;
        SelectedPermissionSet: Code[20];
    begin
        // Test page 9837 which is a 'matrix'-like presentation of permission sets by user groups.
        // Init
        LibraryPermissions.CreateUsersUserGroupsPermissionSets;
        UserGroup.FindFirst;
        LibraryPermissions.GetMyUser(User);

        // Execute
        PermissionSetbyUserGroup.OpenEdit;
        MoreRecords := PermissionSetbyUserGroup.First;
        while MoreRecords and (CopyStr(PermissionSetbyUserGroup."Role ID".Value, 1, 4) <> 'TEST') do
            MoreRecords := PermissionSetbyUserGroup.Next;
        SelectedPermissionSet := PermissionSetbyUserGroup."Role ID".Value;
        PermissionSet.Get(SelectedPermissionSet);

        UserGroupPermissionSet.SetRange("Role ID", PermissionSet."Role ID");
        Assert.AreEqual(0, UserGroupPermissionSet.Count, '');

        PermissionSetbyUserGroup.AllUsersHavePermission.SetValue(true);
        PermissionSetbyUserGroup.AllUsersHavePermission.SetValue(false);
        PermissionSetbyUserGroup.Column1.SetValue(true);
        PermissionSetbyUserGroup.Column2.SetValue(true);
        PermissionSetbyUserGroup.Column3.SetValue(true);
        PermissionSetbyUserGroup.Column4.SetValue(true);
        PermissionSetbyUserGroup.Column5.SetValue(true);
        PermissionSetbyUserGroup.Column6.SetValue(true);
        PermissionSetbyUserGroup.Column7.SetValue(true);
        PermissionSetbyUserGroup.Column8.SetValue(true);
        PermissionSetbyUserGroup.Column9.SetValue(true);
        PermissionSetbyUserGroup.Column10.SetValue(true);
        FirstUserGroupCode := PermissionSetbyUserGroup.Column1.Caption;
        LastUserGroupCode := FirstUserGroupCode;
        PermissionSetbyUserGroup.ColumnRight.Invoke;
        while LastUserGroupCode <> PermissionSetbyUserGroup.Column1.Caption do begin
            PermissionSetbyUserGroup.Column10.SetValue(true);
            LastUserGroupCode := PermissionSetbyUserGroup.Column1.Caption;
            PermissionSetbyUserGroup.ColumnRight.Invoke;
        end;
        LastUserGroupCode := PermissionSetbyUserGroup.Column10.Caption;
        PermissionSetbyUserGroup.AllColumnsLeft.Invoke;
        PermissionSetbyUserGroup.ColumnLeft.Invoke;
        PermissionSetbyUserGroup.AllColumnsRight.Invoke;

        // Validate
        Assert.AreEqual(UserGroup.Code, FirstUserGroupCode, '');
        UserGroup.FindLast;
        Assert.AreEqual(UserGroup.Code, LastUserGroupCode, '');
        Assert.AreEqual(UserGroup.Count, UserGroupPermissionSet.Count, '');
        PermissionSetbyUserGroup.AllUsersHavePermission.SetValue(false);
        Assert.AreEqual(0, UserGroupPermissionSet.Count, '');
        PermissionSetbyUserGroup.Close;
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserByUserGroupPage()
    var
        User: Record User;
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        PermissionSet: Record "Permission Set";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        UserbyUserGroup: TestPage "User by User Group";
        MoreRecords: Boolean;
        FirstUserGroupCode: Text;
        LastUserGroupCode: Text;
        PlanID: Guid;
    begin
        // Test page 9838 which is a 'matrix'-like presentation of users by user groups.
        // Init

        LibraryPermissions.CreateUsersUserGroupsPermissionSets;
        UserGroup.FindFirst;
        LibraryPermissions.GetMyUser(User);
        PlanID := AzureADPlanTestLibrary.CreatePlan(SubscriptionPlanTok);

        // find all permissions and give them to the user's plan
        if PermissionSet.FindSet then
            repeat
                LibraryPermissions.AddPermissionSetToPlan(PermissionSet."Role ID", PlanID);
            until PermissionSet.Next = 0;
        LibraryPermissions.AddUserToPlan(User."User Security ID", PlanID);

        // Execute
        UserbyUserGroup.OpenEdit;
        UserbyUserGroup.SelectedCompany.SetValue(CompanyName);
        MoreRecords := UserbyUserGroup.First;
        while MoreRecords and (UserbyUserGroup."User Name".Value <> User."User Name") do
            MoreRecords := UserbyUserGroup.Next;

        UserGroupMember.DeleteAll(true);
        Assert.AreEqual(0, UserGroupMember.Count, '');

        UserbyUserGroup.MemberOfAllGroups.SetValue(true);
        UserbyUserGroup.MemberOfAllGroups.SetValue(false);
        UserbyUserGroup.Column1.SetValue(true);
        UserbyUserGroup.Column2.SetValue(true);
        UserbyUserGroup.Column3.SetValue(true);
        UserbyUserGroup.Column4.SetValue(true);
        UserbyUserGroup.Column5.SetValue(true);
        UserbyUserGroup.Column6.SetValue(true);
        UserbyUserGroup.Column7.SetValue(true);
        UserbyUserGroup.Column8.SetValue(true);
        UserbyUserGroup.Column9.SetValue(true);
        UserbyUserGroup.Column10.SetValue(true);
        FirstUserGroupCode := UserbyUserGroup.Column1.Caption;
        LastUserGroupCode := FirstUserGroupCode;
        UserbyUserGroup.ColumnRight.Invoke;
        while LastUserGroupCode <> UserbyUserGroup.Column1.Caption do begin
            UserbyUserGroup.Column10.SetValue(true);
            LastUserGroupCode := UserbyUserGroup.Column1.Caption;
            UserbyUserGroup.ColumnRight.Invoke;
        end;
        LastUserGroupCode := UserbyUserGroup.Column10.Caption;
        UserbyUserGroup.AllColumnsLeft.Invoke;
        UserbyUserGroup.ColumnLeft.Invoke;
        UserbyUserGroup.AllColumnsRight.Invoke;

        // Validate
        Assert.AreEqual(UserGroup.Code, FirstUserGroupCode, '');
        UserGroup.FindLast;
        Assert.AreEqual(UserGroup.Code, LastUserGroupCode, '');
        Assert.AreEqual(UserGroup.Count, UserGroupMember.Count, '');
        UserbyUserGroup.MemberOfAllGroups.SetValue(false);
        Assert.AreEqual(0, UserGroupMember.Count, '');
        UserbyUserGroup.Close;
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('UserGroupMembersHandler,UserLookupHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUserGroupPage()
    begin
        // Uses a requesthandler that selects users by opening the users window.
        UserGroupPageSharedTest;
    end;

    local procedure UserGroupPageSharedTest()
    var
        User: Record User;
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroups: TestPage "User Groups";
        RecordExists: Boolean;
    begin
        // Test assignemt of members to a user group in different companies
        // Init
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.GetMyUser(User);

        // Execute
        UserGroups.OpenEdit;
        RecordExists := UserGroups.First;
        while RecordExists and (UserGroups.Code.Value <> UserGroup.Code) do
            RecordExists := UserGroups.Next;
        Assert.IsTrue(RecordExists, '');
        UserGroups.UserGroupMembers.Invoke;
        UserGroups.Close;

        // Validate
        UserGroupMember.SetRange("User Group Code", UserGroup.Code);
        UserGroupMember.SetRange("User Security ID", User."User Security ID");
        Assert.AreEqual(2, UserGroupMember.Count, '');
        UserGroupMember.SetRange("Company Name", '');
        Assert.AreEqual(1, UserGroupMember.Count, '');
        UserGroupMember.SetRange("Company Name", CompanyName);
        Assert.AreEqual(1, UserGroupMember.Count, '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerAdd,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestTenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // Verifies that report 9000 adds another permission set to the current
        // Init
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        LibraryPermissions.CreateTenantPermissionSet(DestTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        TenantPermission.SetRange("Role ID", DestTenantPermissionSet."Role ID");
        Assert.AreEqual(1, TenantPermission.Count, '');

        // Execute
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, DestTenantPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal; // triggers AddSubractPermissionSetHandler

        // Verify
        Assert.AreEqual(2, TenantPermission.Count, '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerAdd,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddTenantPermissionSetToSystemPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestPermissionSet: Record "Permission Set";
        TenantPermission: Record "Tenant Permission";
        Permission: Record Permission;
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // [SCENARIO 292106] Add tenant permission set to system permission set via report 9000 "Add/Subtract Permission Set"
        // [GIVEN] System permission set "PS1"
        LibraryPermissions.CreatePermissionSet(DestPermissionSet, '');
        // [GIVEN] Tenant permission set "PS2" with permissions "PS2_1", "PS2_2", "PS2_3"
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        // [WHEN] Run "Add/Substract Permission Set" report
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ZeroGuid, DestPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal; // triggers AddSubractPermissionSetHandler
        // [THEN] "PS1" has permissions "PS1_1", "PS1_2", "PS1_3" equal to "PS2_1", "PS2_2", "PS2_3"
        Permission.SetRange("Role ID", DestPermissionSet."Role ID");
        Assert.AreEqual(2, Permission.Count, '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerAdd,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddSystemPermissionSetToSystemPermissionSet()
    var
        SourcePermissionSet: Record "Permission Set";
        DestPermissionSet: Record "Permission Set";
        Permission: Record Permission;
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // [SCENARIO 292106] Add system permission set to system permission set via report 9000 "Add/Subtract Permission Set"
        // [GIVEN] System permission set "PS1"
        LibraryPermissions.CreatePermissionSet(DestPermissionSet, '');
        // [GIVEN] System permission set "PS2" with permissions "PS2_1", "PS2_2", "PS2_3"
        LibraryPermissions.CreatePermissionSet(SourcePermissionSet, '');
        LibraryPermissions.AddPermission(SourcePermissionSet."Role ID", Permission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddPermission(SourcePermissionSet."Role ID", Permission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        // [WHEN] Run "Add/Substract Permission Set" report
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ZeroGuid, DestPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourcePermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal; // triggers AddSubractPermissionSetHandler
        // [THEN] "PS1" has permissions "PS1_1", "PS1_2", "PS1_3" equal to "PS2_1", "PS2_2", "PS2_3"
        Permission.SetRange("Role ID", DestPermissionSet."Role ID");
        Assert.AreEqual(2, Permission.Count, '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('AddSubractPermissionSetHandlerSubtract,PermissionSetListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSubtractPermissionSet()
    var
        SourceTenantPermissionSet: Record "Tenant Permission Set";
        DestTenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        AddSubtractPermissionSet: Report "Add/Subtract Permission Set";
        ZeroGuid: Guid;
    begin
        // Verifies that report 9000 adds another permission set to the current
        // Init
        LibraryPermissions.CreateTenantPermissionSet(SourceTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, SourceTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.CreateTenantPermissionSet(DestTenantPermissionSet, '', ZeroGuid);
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Sales Header");
        LibraryPermissions.AddTenantPermission(
          ZeroGuid, DestTenantPermissionSet."Role ID", TenantPermission."Object Type"::"Table Data", DATABASE::"Purchase Header");
        TenantPermission.SetRange("Role ID", DestTenantPermissionSet."Role ID");
        Assert.AreEqual(2, TenantPermission.Count, '');

        // Execute
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGuid, DestTenantPermissionSet."Role ID");
        GlobalSourcePermissionSetRoleID := SourceTenantPermissionSet."Role ID";
        AddSubtractPermissionSet.SetDestination(AggregatePermissionSet);
        AddSubtractPermissionSet.RunModal; // triggers AddSubractPermissionSetHandler

        // Verify
        Assert.AreEqual(1, TenantPermission.Count, '');
        TestCleanup;
    end;

    [Test]
    [HandlerFunctions('UserGroupMembersVerifyCompanyNameFilterHandler')]
    [Scope('OnPrem')]
    procedure InitialCompanyNameFilterForUserGroupMembersPage()
    var
        UserGroup: Record "User Group";
    begin
        // [FEATURE] [UI] [User Group]
        // [SCENARIO 379966] Company Name filter of the User Group Members page should be initialized by current company

        // [GIVEN] Create new User Group
        LibraryPermissions.CreateUserGroup(UserGroup, '');

        // [WHEN] Page User Groups Members is being opened from User Groups page
        OpenUserGroupMembersFromUserGroupsPage(UserGroup.Code);

        // [THEN] Company Name filter field is initialized by current company name
        // Verification is inside the UserGroupMembersVerifyCompanyNameFilterHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportUserGroupWithAndWithoutPermissionsSets()
    var
        UserGroup: Record "User Group";
        UserGroupCode: array[3] of Code[20];
        RoleID: array[3] of Code[20];
        ResultXml: Text;
    begin
        // [SCENARIO 201784] XML file with exported User groups have to contain permissions sets if ones have been assigned to user group.

        TestCleanup;
        // [GIVEN] First User Group "UG1" with User Group Permission Set "UGPS1"
        UserGroupCode[1] := LibraryUtility.GenerateGUID;
        CreateUserGroupWithPermissionSet(RoleID[1], UserGroupCode[1]);

        // [GIVEN] Second User Group "UG2" without User Group Permission Set
        UserGroupCode[2] := LibraryUtility.GenerateGUID;
        LibraryPermissions.CreateUserGroup(UserGroup, UserGroupCode[2]);

        // [GIVEN] Third User Group "UG3" with User Group Permission Set "UGPS3"
        UserGroupCode[3] := LibraryUtility.GenerateGUID;
        CreateUserGroupWithPermissionSet(RoleID[3], UserGroupCode[3]);

        // [WHEN] Export User groups to XML
        ResultXml := ExportUserGroups(UserGroup);

        // [THEN] XML File contains records:
        // [THEN] "UG1" with "UGPS1"
        // [THEN] "UG2" without any User Group Permission Set
        // [THEN] "UG3" with "UGPS3"
        VerifyExportedUserGroups(ResultXml, UserGroupCode, RoleID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertPermissionSetsFromUserGroup()
    var
        InputFile: File;
        EntitlementsStream: InStream;
        UserGroupName: Text[20];
        PlanID: Guid;
        MembershipEntitlementsFile: Text[250];
    begin
        // [SCENARIO] Purpose of the test is to validate Method InsertPermissionSetsFromUserGroup
        // [GIVEN] Existing Plan, User Groups with related Permission Sets defined in MembershipEntitlementsets
        PlanID := CreateGuid;
        UserGroupName := InsertUserGroupAndPermissionset;
        MembershipEntitlementsFile := CreateMembershipEntitlementsFile(PlanID, UserGroupName);
        InputFile.Open(MembershipEntitlementsFile);
        InputFile.CreateInStream(EntitlementsStream);

        // [WHEN] XML Port Export/Import Plans is invoked
        XMLPORT.Import(XMLPORT::"Export/Import Plans", EntitlementsStream);

        // [THEN] Plan, Permissions and User Group Plans are inserted
        VerifyPlanUserGroupPermission(PlanID, UserGroupName, MembershipEntitlementsFile);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAddPermissionSetsAssignmentForUserGroupSetsCustomizedTrue()
    var
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
    begin
        // [SCENARIO] Purpose of the test is to verify that modifying(add) user group permission sets
        // sets the Customized field to TRUE
        // [GIVEN] A User Group and a permission set
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');

        // Execute
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet."Role ID", UserGroup.Code);

        // Verify
        UserGroup.Find;
        UserGroup.TestField(Customized, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRemovePermissionSetsAssignmentFromUserGroupSetsCustomizedTrue()
    var
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
    begin
        // [SCENARIO] Purpose of the test is to verify that modifying(remove) user group permission sets
        // sets the Customized field to TRUE
        // [GIVEN] A User Group and a permission set
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');

        // Execute
        LibraryPermissions.RemovePermissionSetFromUserGroup(PermissionSet."Role ID", UserGroup.Code);

        // Verify
        UserGroup.Find;
        UserGroup.TestField(Customized, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestModifyUserGroupDetailsSetsCustomizedTrue()
    var
        UserGroup: Record "User Group";
    begin
        // [SCENARIO] Purpose of the test is to verify that modifying a user group sets Customized
        // field to TRUE
        // [GIVEN] A User Group
        LibraryPermissions.CreateUserGroup(UserGroup, '');

        // Execute
        UserGroup.Modify(true);

        // Verify
        UserGroup.Find;
        UserGroup.TestField(Customized, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PermissionsObjectNameForTheZeroObjectID()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSets: TestPage "Permission Sets";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 217927] Page 9803 "Permissions" prints "Object Name" = "All objects of type..." for the "Object ID" = 0

        // [GIVEN] A new permission set
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID, ZeroGUID);
        PermissionSets.OpenView;
        PermissionSets.FILTER.SetFilter("App ID", ZeroGUID);
        PermissionSets.FILTER.SetFilter("Role ID", TenantPermissionSet."Role ID");
        // [GIVEN] Invoke Permissions page for the given permission set
        TenantPermissions.Trap;
        PermissionSets.Permissions.Invoke;
        // [GIVEN] Permissions page has been opened with a new record having "Object Type" = "Table Data", "Object ID" = 0, "Object Name" = "All objects of type Table Data"
        TenantPermissions."Object Type".AssertEquals('Table Data');
        TenantPermissions."Object ID".AssertEquals(0);
        TenantPermissions.ObjectName.AssertEquals('All objects of type Table Data');

        // [GIVEN] Set "Object ID" = 15 ("G/L Account"),
        TenantPermissions."Object ID".SetValue(DATABASE::"G/L Account");
        // [GIVEN] Step next, previous record (delayed insert)
        TenantPermissions.Next;
        TenantPermissions.Previous;
        // [GIVEN] "Object Name" = "Chart of Accounts"
        TenantPermissions.ObjectName.AssertEquals('G/L Account');
        // [GIVEN] A new record. Type "Object Type" = "Report", leave "Object ID" = 0
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue('Report');

        // [WHEN] Step next, previous record (delayed insert)
        TenantPermissions.Next;
        TenantPermissions.Previous;

        // [THEN] "Object Name" = "All objects of type Report"
        TenantPermissions.ObjectName.AssertEquals('All objects of type Report');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserCardPageIsUpdatedOnInsertNewUserGroup()
    var
        User: Record User;
        UserGroup: array[3] of Record "User Group";
        UserGroupPermissionSet: array[3] of Record "User Group Permission Set";
        UserCard: TestPage "User Card";
    begin
        // [SCENARIO 225576] User Card page is updated on insert\modify\delete user groups subpage
        LibraryPermissions.CreateUser(User, '', false);

        // [GIVEN] User group "A" with permission set "B"
        LibraryPermissions.CreateUserGroup(UserGroup[1], '');
        CreateUserGroupPermissionSet(UserGroupPermissionSet[1], UserGroup[1].Code, 'B');
        // [GIVEN] User group "B" with permission set "A"
        LibraryPermissions.CreateUserGroup(UserGroup[2], '');
        CreateUserGroupPermissionSet(UserGroupPermissionSet[2], UserGroup[2].Code, 'A');

        // [GIVEN] User card
        UserCard.OpenEdit;
        UserCard.GotoRecord(User);

        // [GIVEN] Add user group "A"
        UserCard.UserGroups.UserGroupCode.SetValue(UserGroup[1].Code);
        UserCard.UserGroups.Next;

        // [GIVEN] User permission set "B" has been added
        UserCard.Permissions.First;
        UserCard.Permissions.PermissionSet.AssertEquals(UserGroupPermissionSet[1]."Role ID");

        // [WHEN] Add user group "B"
        UserCard.UserGroups.LAST;
        UserCard.UserGroups.NEXT;
        UserCard.UserGroups.UserGroupCode.SetValue(UserGroup[2].Code);
        UserCard.UserGroups.Next;

        // [THEN] User permission set "A" has been added and is shown as first record in "User Permission Sets" subpage
        UserCard.Permissions.First;
        UserCard.Permissions.PermissionSet.AssertEquals(UserGroupPermissionSet[2]."Role ID");
        UserCard.Close;

        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PermissionsPageObjectNameIsUpdatedOnObjectIDChanged()
    var
        SalesHeader: Record "Sales Header";
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259473] Object Name is updated when Object ID is changed on Permissions Page.

        // [GIVEN] Permission Set.
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, '', ZeroGUID);

        // [GIVEN] Permissions Page for the Permission Set.
        TenantPermissions.OpenEdit;
        TenantPermissions.CurrentRoleID.SetValue(TenantPermissionSet."Role ID");

        // [GIVEN] Add new Permission on Page with Type Table Data.
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue(TenantPermissions."Object Type".GetOption(1)); // Type does not matter for test

        // [WHEN] Set Object ID as existing table number.
        TenantPermissions."Object ID".SetValue(DATABASE::"Sales Header");

        // [THEN] Object Name = Table Name.
        TenantPermissions.ObjectName.AssertEquals(SalesHeader.TableName);

        // Tear down.
        TestCleanup;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PermissionsPageObjectNameIsUpdatedOnObjectTypeChanged()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 262735] Object Name is updated when Object Type is changed on Permissions Page.

        // [GIVEN] Permission Set.
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, '', ZeroGUID);

        // [GIVEN] Permissions Page for the Permission Set.
        TenantPermissions.OpenEdit;
        TenantPermissions.CurrentRoleID.SetValue(TenantPermissionSet."Role ID");

        // [GIVEN] Add new Permission on Page with ID = 3 (Default Object Type is Table Data).
        TenantPermissions.New;
        TenantPermissions."Object ID".SetValue(CODEUNIT::"Service Info-Pane Management");

        // [WHEN] Set Object Type = Codeunit.
        TenantPermissions."Object Type".SetValue(TenantPermissions."Object Type".GetOption(4));

        // [THEN] Object Name = Codeunit Name.
        TenantPermissions.ObjectName.AssertEquals('Service Info-Pane Management');

        // Tear down.
        TestCleanup;
    end;

    local procedure Initialize()
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
    end;

    local procedure CreateUserGroupWithUser(var UserSecurityID: Guid; var UserGroupCode: Code[20])
    var
        User: Record User;
        UserGroup: Record "User Group";
    begin
        LibraryPermissions.GetMyUser(User);
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.AddUserToUserGroup(UserGroup, User, '');

        VerifyUserGroupAccessControlCount(UserGroupCode, UserSecurityID, 0);

        UserSecurityID := User."User Security ID";
        UserGroupCode := UserGroup.Code;
    end;

    local procedure CreateUserGroupPermissionSet(var UserGroupPermissionSet: Record "User Group Permission Set"; UserGroupCode: Code[20]; RoleID: Code[20])
    begin
        with UserGroupPermissionSet do begin
            Init;
            "User Group Code" := UserGroupCode;
            "Role ID" := RoleID;
            Insert(true);
        end;
    end;

    local procedure CreateUserGroupWithPermissionSet(var RoleID: Code[20]; UserGroupCode: Code[20])
    var
        UserGroup: Record "User Group";
        PermissionSet: Record "Permission Set";
    begin
        LibraryPermissions.CreateUserGroup(UserGroup, UserGroupCode);
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');
        RoleID := PermissionSet."Role ID";
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet."Role ID", UserGroup.Code);
    end;

    local procedure CreatePermissionSet(): Code[20]
    var
        PermissionSet: Record "Permission Set";
    begin
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');
        exit(PermissionSet."Role ID");
    end;

    [Scope('OnPrem')]
    procedure ExportUserGroups(UserGroup: Record "User Group"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        Environment: DotNet Environment;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"Export/Import User Groups", OutStr, UserGroup);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF16);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, Environment.NewLine));
    end;

    local procedure FilterUserGroupAccessControl(var UserGroupAccessControl: Record "User Group Access Control"; UserGroupCode: Code[20]; UserSecurityID: Guid)
    begin
        with UserGroupAccessControl do begin
            SetRange("User Group Code", UserGroupCode);
            SetRange("User Security ID", UserSecurityID);
        end;
    end;

    local procedure OpenUserGroupMembersFromUserGroupsPage(UserGroupCode: Code[20])
    var
        UserGroups: TestPage "User Groups";
    begin
        UserGroups.OpenEdit;
        UserGroups.FILTER.SetFilter(Code, UserGroupCode);
        UserGroups.UserGroupMembers.Invoke;
    end;

    local procedure VerifyOpenClosePermissionPageNoEdit(HasPermission: Boolean)
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
        Permissions: TestPage Permissions;
        OrgCount: Integer;
    begin
        // Ensure that open/close of an empty permission set does not inadvertedly creates a 0-permission
        LibraryPermissions.CreatePermissionSet(PermissionSet, '');
        if HasPermission then
            LibraryPermissions.AddPermission(PermissionSet."Role ID", Permission."Object Type"::"Table Data", DATABASE::Currency);
        PermissionSet.SetRecFilter;
        Permission.SetRange("Role ID", PermissionSet."Role ID");
        OrgCount := Permission.Count;
        if HasPermission then
            Assert.AreEqual(1, OrgCount, '')
        else
            Assert.AreEqual(0, OrgCount, '');

        // Execute
        Permissions.OpenEdit;
        Permissions.CurrentRoleID.Value := PermissionSet."Role ID";
        Permissions.Close;

        // Verify
        Assert.AreEqual(OrgCount, Permission.Count, '');
    end;

    local procedure VerifyOpenCloseAllPermissionPage(HasPermission: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
        MoreRecords: Boolean;
    begin
        // Ensure that open/close of an empty permission set does not inadvertedly creates a 0-permission using Show all

        // Execute
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, '', ZeroGUID);
        TenantPermissionSet.SetRecFilter;
        TenantPermission.SetRange("Role ID", TenantPermissionSet."Role ID");
        Assert.RecordIsEmpty(TenantPermission);

        TenantPermissions.OpenEdit;
        TenantPermissions.CurrentRoleID.SetValue(TenantPermissionSet."Role ID");
        TenantPermissions.Show.SetValue(TenantPermissions.Show.GetOption(2));

        MoreRecords := TenantPermissions.First;
        Assert.IsTrue(MoreRecords, '');
        if HasPermission then begin
            while MoreRecords and (TenantPermissions."Object ID".AsInteger < 4) do
                MoreRecords := TenantPermissions.Next;
            TenantPermissions.Control8.Value := TenantPermissions.Control8.GetOption(2);
            TenantPermissions.First;
        end;
        TenantPermissions.Close;

        // Verify
        if HasPermission then
            Assert.RecordCount(TenantPermission, 1)
        else
            Assert.RecordIsEmpty(TenantPermission);
    end;

    local procedure VerifyUserGroupMemberInsertDelete(IsDelete: Boolean)
    var
        User: Record User;
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupAccessControl: Record "User Group Access Control";
        PermissionSet: Record "Permission Set";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanID: Guid;
    begin
        // Test the OnDelete trigger of table 9001
        LibraryPermissions.GetMyUser(User);
        PlanID := AzureADPlanTestLibrary.CreatePlan(SubscriptionPlanTok);
        LibraryPermissions.AddUserToPlan(User."User Security ID", PlanID);
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        LibraryPermissions.CreatePermissionSet(PermissionSet, 'My permission set');
        LibraryPermissions.AddPermissionSetToPlan('My permission set', PlanID);
        LibraryPermissions.AddPermissionSetToUserGroup(PermissionSet."Role ID", UserGroup.Code);

        UserGroupMember.SetRange("User Group Code", UserGroup.Code);
        Assert.AreEqual(0, UserGroupMember.Count, '');

        UserGroupAccessControl.SetRange("User Group Code", UserGroup.Code);
        UserGroupAccessControl.SetRange("User Security ID", User."User Security ID");
        Assert.AreEqual(0, UserGroupAccessControl.Count, '');

        // Execution
        UserGroupMember."User Group Code" := UserGroup.Code;
        UserGroupMember."User Security ID" := User."User Security ID";
        UserGroupMember."Company Name" := CompanyName;
        UserGroupMember.Insert(true);

        // Verification
        UserGroupAccessControl.SetRange("User Group Code", UserGroup.Code);
        UserGroupAccessControl.SetRange("User Security ID", User."User Security ID");
        Assert.AreEqual(1, UserGroupAccessControl.Count, '');
        if IsDelete then begin
            UserGroupMember.Delete(true);
            Assert.AreEqual(0, UserGroupAccessControl.Count, '');
        end;
    end;

    local procedure VerifyPermissionsPageInsertNewRecord(InsertReleatedTables: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TenantPermission: Record "Tenant Permission";
        TenantPermissions: TestPage "Tenant Permissions";
        ZeroGUID: Guid;
    begin
        // Tests insert of a new permission and with or without inserting related tables
        // Init
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, '', ZeroGUID);
        TenantPermission.SetRange("Role ID", TenantPermissionSet."Role ID");
        Assert.RecordIsEmpty(TenantPermission);

        // Execute
        TenantPermissions.OpenEdit;
        TenantPermissions.CurrentRoleID.SetValue(TenantPermissionSet."Role ID");
        TenantPermissions.AddRelatedTables.SetValue(InsertReleatedTables);
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue(TenantPermissions."Object Type".GetOption(1)); // TableData
        TenantPermissions."Object ID".SetValue(DATABASE::"Sales Header");
        TenantPermissions.Control8.SetValue(TenantPermissions.Control8.GetOption(2));
        TenantPermissions.Control7.SetValue(TenantPermissions.Control7.GetOption(2));
        TenantPermissions.Control6.SetValue(TenantPermissions.Control6.GetOption(2));
        TenantPermissions.Control5.SetValue(TenantPermissions.Control5.GetOption(2));
        TenantPermissions.AllowAllIndirect.Invoke;
        TenantPermissions.AllowReadNo.Invoke;
        TenantPermissions.AllowInsertIndirect.Invoke;
        TenantPermissions.AllowModifyYes.Invoke;
        TenantPermissions.AllowDeleteYes.Invoke;
        TenantPermissions.New;
        TenantPermissions."Object Type".SetValue(TenantPermissions."Object Type".GetOption(3)); // Report
        TenantPermissions."Object ID".SetValue(REPORT::"Detail Trial Balance");
        TenantPermissions.Previous;

        // Verify
        if InsertReleatedTables then
            Assert.IsTrue(TenantPermission.Count > 2, 'Number of tenant permissions must be more than 2.')
        else
            Assert.RecordCount(TenantPermission, 2);

        TenantPermissions.Next;
        TenantPermissions.Control4.SetValue(TenantPermissions.Control4.GetOption(1));
        TenantPermissions.Previous;
        TenantPermissions.Close;

        if InsertReleatedTables then
            Assert.IsTrue(TenantPermission.Count > 1, 'Number of tenant permissions must be more than 1.')
        else
            Assert.RecordCount(TenantPermission, 1);
    end;

    local procedure VerifyUserGroupAccessControlCount(UserGroupCode: Code[20]; UserSecurityID: Guid; ExpectedCount: Integer)
    var
        UserGroupAccessControl: Record "User Group Access Control";
    begin
        FilterUserGroupAccessControl(UserGroupAccessControl, UserGroupCode, UserSecurityID);
        Assert.AreEqual(ExpectedCount, UserGroupAccessControl.Count, '');
    end;

    local procedure VerifyExportedUserGroups(ResultXml: Text; UserGroupCode: array[3] of Code[20]; RoleID: array[3] of Code[20])
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
    begin
        XMLDOMManagement.LoadXMLDocumentFromText(ResultXml, XmlDocument);
        XMLDOMManagement.FindNodes(XmlDocument.DocumentElement, '/UserGroups/UserGroup', XmlNodeList);
        // Verify first User Group
        Assert.AreEqual(UserGroupCode[1], XmlNodeList.ItemOf(0).SelectSingleNode('Code').InnerText, WrongUserGroupCodeErr);
        Assert.AreEqual(RoleID[1], XmlNodeList.ItemOf(0).SelectSingleNode('UserGroupPermissionSet/RoleId').InnerText, WrongRoleIDErr);

        // Verify second User Group
        Assert.AreEqual(UserGroupCode[2], XmlNodeList.ItemOf(1).SelectSingleNode('Code').InnerText, WrongUserGroupCodeErr);
        asserterror Assert.AreEqual(
            RoleID[2], XmlNodeList.ItemOf(1).SelectSingleNode('UserGroupPermissionSet/RoleId').InnerText, WrongRoleIDErr);

        // Verify third User Group
        Assert.AreEqual(UserGroupCode[3], XmlNodeList.ItemOf(2).SelectSingleNode('Code').InnerText, WrongUserGroupCodeErr);
        Assert.AreEqual(RoleID[3], XmlNodeList.ItemOf(2).SelectSingleNode('UserGroupPermissionSet/RoleId').InnerText, WrongRoleIDErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserLookupHandler(var UserLookup: TestPage "User Lookup")
    var
        RecordExists: Boolean;
    begin
        // Selects current user and clicks OK
        RecordExists := UserLookup.First;

        while RecordExists and (UserLookup."User Name".Value <> UserId) do
            RecordExists := UserLookup.Next;
        Assert.IsTrue(RecordExists, '');
        UserLookup.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    begin
        CopyPermissionSet.NewPermissionSet.Value := CopyToPermissionSet;
        CopyPermissionSet.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetSuccessMessageHandler(Message: Text[1024])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        CopiedRoleID: Code[20];
    begin
        CopiedRoleID := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TenantPermissionSet."Role ID"));
        Assert.ExpectedMessage(StrSubstNo(CopySuccessMsg, CopiedRoleID), Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyUserGroupHandler(var CopyUserGroup: TestRequestPage "Copy User Group")
    begin
        CopyUserGroup.NewUserGroupCode.Value := CopyToUserGroup;
        CopyUserGroup.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure UserGroupMembersHandler(var UserGroupMembers: TestPage "User Group Members")
    begin
        UserGroupMembers.SelectedCompany.SetValue('');
        UserGroupMembers.AddUsers.Invoke;
        UserGroupMembers.SelectedCompany.SetValue(CompanyName);
        UserGroupMembers.AddUsers.Invoke;
        UserGroupMembers.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure UserGroupMembersVerifyCompanyNameFilterHandler(var UserGroupMembers: TestPage "User Group Members")
    begin
        UserGroupMembers.SelectedCompany.AssertEquals(CompanyName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddSubractPermissionSetHandlerAdd(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set")
    begin
        AddSubractPermissionSetHandlerCommon(AddSubractPermissionSet, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddSubractPermissionSetHandlerSubtract(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set")
    begin
        AddSubractPermissionSetHandlerCommon(AddSubractPermissionSet, 2);
    end;

    local procedure AddSubractPermissionSetHandlerCommon(var AddSubractPermissionSet: TestRequestPage "Add/Subtract Permission Set"; SetOperationValue: Integer)
    begin
        Assert.IsTrue(AddSubractPermissionSet.DstnAggregatePermissionSet.Value <> GlobalSourcePermissionSetRoleID, '');
        AddSubractPermissionSet.SetOperation.SetValue(AddSubractPermissionSet.SetOperation.GetOption(SetOperationValue));
        AddSubractPermissionSet.SourceAggregatePermissionSet.AssistEdit;
        AddSubractPermissionSet.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ImportedMessageHandler(MessageText: Text)
    begin
        Assert.IsTrue(StrPos(MessageText, 'user groups with a total of') > 0, '');
    end;

    local procedure TestCleanup()
    var
        UserSetup: Record "User Setup";
        AccessControl: Record "Access Control";
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPlan: Record "User Group Plan";
    begin
        // When we add any user into User table Server switches authentication mode
        // and further tests fail with permission error until Server is restarted.
        // Automatic rollback in test isolation does not revert Server's authentication mode.
        // In this case we need manually clean up User table if test passed and User table
        // is modified during this test.
        // User Setup must cleaned too, due to reference to User table.
        DeleteAllUsers;
        UserSetup.DeleteAll;
        AccessControl.DeleteAll;
        UserGroupMember.DeleteAll;
        UserGroupAccessControl.DeleteAll;
        UserGroupPermissionSet.DeleteAll;
        UserGroupPlan.DeleteAll;
        UserGroup.DeleteAll;
    end;

    local procedure GetGuidString(): Text
    begin
        exit(DelChr(Format(CreateGuid), '=', '{-}'));
    end;

    local procedure DeleteAllUsers()
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        if User.FindFirst then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete;
            User.Delete;
        end;
    end;

    local procedure CreateMembershipEntitlementsFile(PlanID: Guid; UserGroupName: Text[50]): Text[250]
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        OutStream: OutStream;
        FileName: Text;
        PlanName: Text[50];
    begin
        FileName := FileManagement.ServerTempFileName('xml');
        PlanName := 'TEST PLAN';

        // Insert new plan in table because it is no longer possible to populate table Plan using an xml file
        AzureADPlanTestLibrary.CreatePlan(PlanID, PlanName, 9022, CreateGuid());

        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, '<?xml version="1.0" encoding="utf-8"?>');
        WriteLine(OutStream, '<entitlements>');
        WriteLine(OutStream, '<entitlement>');
        WriteLine(OutStream, '<type>Azure AD Plan</type>');
        WriteLine(OutStream, '<id>' + Format(PlanID) + '</id>');
        WriteLine(OutStream, '<name>' + PlanName + '</name>');
        WriteLine(OutStream, '<entitlementSetId>PROJECT_MADEIRA_PW</entitlementSetId>');
        WriteLine(OutStream, '<entitlementSetName>Dynamics 365 for Financials for IWs</entitlementSetName>');
        WriteLine(OutStream, '<isEvaluation>true</isEvaluation>');
        WriteLine(OutStream, '<roleCenterId>9022</roleCenterId>');
        WriteLine(OutStream, '<includeDynamicsExtensions>true</includeDynamicsExtensions>');
        WriteLine(OutStream, '<includeFreeRange>true</includeFreeRange>');
        WriteLine(OutStream, '<includeInfrastructure>false</includeInfrastructure>');
        WriteLine(OutStream, '<relatedUserGroup setId="' + UserGroupName + '"/>');
        WriteLine(OutStream, '<licenseGroup>Financials</licenseGroup>');
        WriteLine(OutStream, '</entitlement>');
        WriteLine(OutStream, '</entitlements>');

        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
        exit(FileName);
    end;

    local procedure InsertUserGroupAndPermissionset(): Text[20]
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        PermissionSet: Record "Permission Set";
    begin
        // User Group
        UserGroup.Init;
        UserGroup.Code := 'TEST USER GROUP';
        UserGroup.Name := 'TEST USER GROUP';
        UserGroup.Insert;

        // Permission
        PermissionSet.Init;
        PermissionSet."Role ID" := XTestPermissionTxt;
        PermissionSet.Insert;

        // User Group PermissionSet
        UserGroupPermissionSet.Init;
        UserGroupPermissionSet."Role ID" := PermissionSet."Role ID";
        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet.Insert;
        Commit;

        exit(UserGroup.Code)
    end;

    local procedure VerifyPlanUserGroupPermission(PlanID: Guid; UserGroupName: Text[50]; MembershipEntitlementsFile: Text)
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPlan: Record "User Group Plan";
        Plan: Query Plan;
        PlanPermissionSet: Record "Plan Permission Set";
    begin
        // verify User Group Plan exists
        UserGroupPlan.SetRange("Plan ID", PlanID);
        UserGroupPlan.SetRange("User Group Name", UserGroupName);
        Assert.IsTrue(UserGroupPlan.FindFirst, 'User Group Plan doesn''t exist');

        // verify Plan Permissionset
        LibraryXMLRead.Initialize(MembershipEntitlementsFile);
        UserGroupPermissionSet.SetRange("User Group Name", UserGroupName);
        Assert.IsTrue(UserGroupPermissionSet.FindFirst, 'User Group Permissionset doesnt exist');
        Assert.AreEqual(UserGroupPermissionSet."Role ID", XTestPermissionTxt, '');

        // verify Plan
        Plan.SetRange(Plan_ID, PlanID);
        Assert.IsTrue(Plan.Open(), 'Plan doesn''t exist');
        Plan.Read();
        LibraryXMLRead.VerifyNodeValue('roleCenterId', Plan.Role_Center_ID);

        // verify PlanPermissionset
        Assert.IsTrue(PlanPermissionSet.Get(PlanID, XTestPermissionTxt), 'PlanPermissionset doesn''t exist');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PermissionSetListHandler(var PermissionSetList: TestPage "Permission Set List")
    begin
        PermissionSetList.FILTER.SetFilter("Role ID", GlobalSourcePermissionSetRoleID);
        PermissionSetList.First;
        PermissionSetList.OK.Invoke;
    end;
}

