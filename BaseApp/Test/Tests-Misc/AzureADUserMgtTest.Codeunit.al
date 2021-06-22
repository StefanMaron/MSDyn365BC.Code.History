// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132907 AzureADUserMgtTest
{
    Permissions = TableData "User Property" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SaaS] [Azure AD User Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAzureADUserMgmt: Codeunit "Library - Azure AD User Mgmt.";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureADUserManagement: Codeunit "Azure AD User Management";
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        CompanyAdminRoleTemplateIdTok: Label '62e90394-69f5-4237-9190-012177145e10', Locked = true;
        DeviceUserCannotBeFirstUser: Label 'The device user cannot be the first user to log into the system.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersAsFirstUserThrowsError()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
        AzureADUserMgtTestLibrary: Codeunit "Azure AD User Mgt Test Library";
    begin
        // [SCENARIO] When device user signs in and its the first user on the system, an error is thrown
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.RUN(CODEUNIT::"Users - Create Super User");
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserManagement.SetTestInProgress(true);
        asserterror AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] Error suggesting device user cannot be the first user is thrown
        Assert.ExpectedError(DeviceUserCannotBeFirstUser);
        TearDown;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersAreAssignedDevicesPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
        AzureADUserMgtTestLibrary: Codeunit "Azure AD User Mgt Test Library";
    begin
        // [SCENARIO] When device user signs in, device plan is assigned to the user
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.RUN(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserManagement.SetTestInProgress(true);
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned devices plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsTrue(
        IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is not assigned');
        TearDown;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersWithEssentialPlanIsAssignedEssentialPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
        AzureADUserMgtTestLibrary: Codeunit "Azure AD User Mgt Test Library";
    begin
        // [SCENARIO] When device user who also happens to have a plan assigned signs in, device plan is not assigned to the user
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUserWithoutPlan(UserAuthenticationId, User."Full Name", '', User."Authentication Email");
        LibraryAzureADUserMgmt.AddUserPlan(UserAuthenticationId, PlanIds.GetEssentialPlanId(), '', 'Enabled');
        LibraryAzureADUserMgmt.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserManagement.SetTestInProgress(true);
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned essential plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsFalse(IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is assigned');
        Assert.IsTrue(IsUserInPlan(User."User Security ID", PlanIds.GetEssentialPlanId()), 'Essential plan is not assigned');
        TearDown;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeviceUsersWhoHadAdminRoleIsAssignedAdminPlan()
    var
        User: Record User;
        PlanIds: Codeunit "Plan Ids";
        UserAuthenticationId: Guid;
        AzureADUserMgtTestLibrary: Codeunit "Azure AD User Mgt Test Library";
    begin
        // [SCENARIO] When device user who also happens to have a plan assigned signs in, device plan is not assigned to the user
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] A user belonging to a device plan
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.AddUserToPlan(UserSecurityId(), PlanIds.GetEssentialPlanId());
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUserWithoutPlan(UserAuthenticationId, User."Full Name", '', User."Authentication Email");
        LibraryAzureADUserMgmt.AddUserRole(UserAuthenticationId, PlanIds.GetInternalAdminPlanId(), 'Global administrator', 'Global administrator', true);
        LibraryAzureADUserMgmt.AddGraphUserWithInDevicesGroup(UserAuthenticationId, User."User Name", '', '');

        // [WHEN] The user logs in (at first userlogin)
        AzureADUserManagement.SetTestInProgress(true);
        AzureADUserMgtTestLibrary.Run(User."User Security ID");

        // [THEN] User is assigned admin plan
        LibraryLowerPermissions.SetO365BusFull();
        Assert.IsFalse(IsUserInPlan(User."User Security ID", PlanIds.GetDevicePlanId()), 'Device plan is assigned');
        Assert.IsTrue(IsUserInPlan(User."User Security ID", PlanIds.GetInternalAdminPlanId()), 'Internal Admin plan is not assigned');
        TearDown;
    end;

    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureADDoesNotRemoveValidUserGroups()
    var
        User: Record User;
        AzureADPlan: Codeunit "Azure AD Plan";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        UserAuthenticationId: Guid;
        RainyCloudPlanId: Guid;
        UserGroupCode: Code[20];
    begin
        // [SCENARIO] Bug 195582: Get Users from Office 365 can wipe out the User Groups
        Initialize();

        // [GIVEN] At least a NAV user group in a plan exists
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.SetSecurity();

        RainyCloudPlanId := AzureADPlanTestLibrary.CreatePlan('Rainy Cloud');
        Assert.IsTrue(AzureADPlan.DoesPlanExist(RainyCloudPlanId), 'The plan does not exist');

        UserGroupCode := 'Test User Group';
        LibraryPermissions.CreateUserGroupInPlan(UserGroupCode, RainyCloudPlanId);

        // [GIVEN] A user associated with the plan. The user only exists in Azure AD
        UserAuthenticationId := LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUser(UserAuthenticationId, User."User Name", '', '', RainyCloudPlanId, 'Rainy Cloud', 'Enabled');

        // [GIVEN] CreateNewUsersFromAzureAD is invoked to create the user and assign the user group to it
        LibraryLowerPermissions.SetO365BusFull();
        LibraryLowerPermissions.SetSecurity();
        AzureADUserManagement.CreateNewUsersFromAzureAD(); // first call - creates the user
        AssertUserGroupHasOneMember(UserGroupCode, 'Prerequisite failed: Missing user group member.');

        // [WHEN] CreateNewUsersFromAzureAD is invoked a second time
        AzureADUserManagement.CreateNewUsersFromAzureAD(); // second call - should not delete the user's groups

        // Rollback SaaS test
        TearDown;

        // [THEN] The user group is still assigned to the user
        AssertUserGroupHasOneMember(UserGroupCode, 'Test failed: Missing user group member.');
    end;

    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureADWhenUserExists()
    var
        User: Record User;
        UserGroupPlan: Record "User Group Plan";
    begin
        // [SCENARIO] Creating new users from the Azure Active Directory Graph
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.SetSecurity();

        // [GIVEN] A user with a plan that contains user groups
        CreateUserWithPlanAndUserGroups(User, UserGroupPlan, 'Test User');

        // [WHEN] CreateNewUsersFromAzureAD invoked
        AzureADUserManagement.CreateNewUsersFromAzureAD();
        LibraryLowerPermissions.SetO365BusFull();

        // [THEN] The user is created
        // [THEN] User gets the User Groups of the plan
        ValidateUserGetsTheUserGroupsOfThePlan(User, UserGroupPlan);

        // Rollback SaaS test
        TearDown();
    end;

    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateMultipleNewUsersFromAzureADWhenUserExists()
    var
        Users: Array[200] of Record User;
        UserGroupPlan: Record "User Group Plan";
        AzureADPlan: codeunit "Azure AD Plan";
        i: Integer;
    begin
        // [SCENARIO] Creating new users from the Azure Active Directory Graph
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();

        // [GIVEN] 200 users with a plan that contains user groups
        for i := 1 to ArrayLen(Users) do begin
            CreateUserWithPlanAndUserGroups(Users[i], UserGroupPlan, StrSubstNo('Test User%1', i));
        end;

        // [WHEN] CreateNewUsersFromAzureAD invoked
        AzureADUserManagement.CreateNewUsersFromAzureAD();
        LibraryLowerPermissions.SetO365BusFull();

        // [THEN] All users are created
        // [THEN] All users get the User Groups of the plan
        for i := 1 to ArrayLen(Users) do begin
            ValidateUserGetsTheUserGroupsOfThePlan(Users[i], UserGroupPlan);
        end;
        // Rollback SaaS test
        TearDown;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureNoPermissions()
    var
        User: Record User;
        Plan: Query Plan;
        UserAuthenticationID: Text;
    begin
        // [SCENARIO] "Download" new users from the Graph, but have no permissions to create them locally
        Initialize;

        // [GIVEN] 1 existing user in the system
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddSecurity();
        LibraryPermissions.CreateUser(User, 'NAV Test User', false);

        // [GIVEN] A user created only in the cloud
        Plan.Open();
        Plan.Read();

        UserAuthenticationID := CreateGuid;
        LibraryAzureADUserMgmt.AddGraphUser(
          UserAuthenticationID, 'Cloud-Only', 'Cloud-Only Test User',
          'bla@nothing.dk', Plan.Plan_ID, Plan.Plan_Name, 'Enabled');

        // [WHEN] Not being neither SUPER nor SECURITY
        LibraryLowerPermissions.SetBanking();

        // [WHEN] CreateNewUsersFromAzureAD is invoked with no SUPER nor SECURITY permissions
        // [THEN] The user is not created - an error stating that there are not enough permissions is thrown
        asserterror AzureADUserManagement.CreateNewUsersFromAzureAD();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUsersFromAzureADNoGraph()
    var
        User: Record User;
        InitialUserCount: Integer;
        UserName: Code[50];
    begin
        // [SCENARIO] Attempting to create new users from the Graph when the graph is not initialized
        // It should result in an error, as the DotNet GraphQuery object cannot be initialized
        // in a non-SaaS environment
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.AddSecurity;

        // [GIVEN] 1 existing user in the system
        UserName := 'Cloud Test User';
        LibraryPermissions.CreateUser(User, UserName, false);
        InitialUserCount := User.Count;

        // [GIVEN] A user created only in the cloud
        // TODO - this is broken, creates the previous user in the cloud. We need to create the user ONLY in the cloud
        LibraryPermissions.CreateAzureActiveDirectoryUserCloudOnly(User);

        // [GIVEN] Not running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] CreateNewUsersFromAzureAD is invoked
        AzureADUserManagement.CreateNewUsersFromAzureAD;

        // [THEN] The user count remains the same
        Assert.AreEqual(InitialUserCount, User.Count, 'The user count should have remained the same');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOnDefaultRoleCenterIDReturnsDefaultIfNoAzureUserPresent()
    var
        User: Record User;
        Plan: Query Plan;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        // [SCENARIO] When singning in, if the plan is disabled, default rolecenter id returned
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;

        Plan.Open();
        Plan.Read();

        // [GIVEN] A user with a plan exists, plan status = disabled
        CreateUserWithSubscriptionPlan(User, Plan.Plan_ID, Plan.Plan_Name, 'Disabled');
        // [WHEN] GetAzureUserPlanRoleCenterId invoked (at first userlogin)
        // [THEN] Rolecenter ID 0 is returned
        LibraryLowerPermissions.SetO365Basic;
        Assert.AreEqual(9022, ConfPersonalizationMgt.DefaultRoleCenterID, 'Invalid Role Center Id');

        LibraryLowerPermissions.SetOutsideO365Scope;
        TearDown;
    end;

    local procedure Initialize()
    var
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService := true;

        Clear(AzureADUserManagement);
        AzureADUserManagement.SetTestInProgress(true);

        AzureADPlanTestLibrary.PopulatePlanTable();

        Clear(LibraryAzureADUserMgmt);
        LibraryAzureADUserMgmt.SetupMockGraphQuery();
        BindSubscription(LibraryAzureADUserMgmt);
        SetupAzureADMockPlans;
    end;

    local procedure TearDown()
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService := false;
        UnbindSubscription(LibraryAzureADUserMgmt);
    end;

    local procedure IsUserInPlan(UserAuthenticationId: Guid; PlanId: Guid): Boolean
    var
        UsersInPlan: Query "Users in Plans";
    begin
        UsersInPlan.SetRange(User_Security_ID, UserAuthenticationId);

        if UsersInPlan.Open() then
            while UsersInPlan.Read() do begin
                if UsersInPlan.Plan_ID = PlanId then
                    exit(true);
            end;
    end;

    local procedure CreateUserWithSubscriptionPlan(var User: Record User; PlanID: Guid; PlanName: Text; PlanStatus: Text)
    begin
        LibraryPermissions.CreateAzureActiveDirectoryUser(User, '');
        LibraryAzureADUserMgmt.AddGraphUser(GetUserAuthenticationId(User), User."User Name", '', '', PlanID, PlanName, PlanStatus);
    end;

    local procedure GetUserAuthenticationId(User: Record User): Guid
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Get(User."User Security ID");
        exit(UserProperty."Authentication Object ID");
    end;

    local procedure SetupAzureADMockPlans()
    var
        Plan: Query Plan;
    begin
        Plan.Open();
        while Plan.Read() do
            LibraryAzureADUserMgmt.AddSubscribedSkuWithServicePlan(CreateGuid, Plan.Plan_ID, Plan.Plan_Name);
    end;

    local procedure ValidateUserGetsTheUserGroupsOfThePlan(User: Record User; UserGroupPlan: Record "User Group Plan")
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Security ID", User."User Security ID");
        UserGroupMember.FindSet;
        UserGroupPlan.SetRange("Plan ID", UserGroupPlan."Plan ID");
        UserGroupPlan.FindSet;

        Assert.RecordCount(UserGroupMember, UserGroupPlan.Count);
        repeat
            Assert.AreEqual(UserGroupPlan."User Group Code", UserGroupMember."User Group Code", 'Only the enabled plan should be returned');
            UserGroupMember.Next;
        until UserGroupPlan.Next = 0;
    end;

    local procedure CreateUserWithPlanAndUserGroups(var User: Record User; var UserGroupPlan: Record "User Group Plan"; UserName: Text)
    var
        Plan: Query Plan;
    begin
        LibraryPermissions.CreateAzureActiveDirectoryUser(User, UserName);
        UserGroupPlan.FindFirst;

        Plan.SetRange(Plan_ID, UserGroupPlan."Plan ID");
        Plan.Open();
        Plan.Read();

        LibraryAzureADUserMgmt.AddGraphUser(GetUserAuthenticationId(User), User."User Name", '', '', Plan.Plan_ID, Plan.Plan_Name, 'Enabled');
    end;

    local procedure CreateUserWithPlan(var User: Record User; PlanID: Guid)
    var
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
        Plan: Query Plan;
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        LibraryPermissions.CreateAzureActiveDirectoryUser(User, 'Test User');
        UsersCreateSuperUser.AddUserAsSuper(User);

        Plan.SetRange(Plan_ID, PlanID);
        Plan.Open();
        Plan.Read();

        LibraryAzureADUserMgmt.AddGraphUser(GetUserAuthenticationId(User), User."User Name", '', '', Plan.Plan_ID, Plan.Plan_Name, 'Enabled');
    end;

    local procedure AssertUserGroupHasOneMember(UserGroupCode: Code[20]; ErrorMessage: Text)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        Assert.AreEqual(1, UserGroupMember.Count, ErrorMessage);
    end;

    local procedure InsertUserProperty(UserSecurityId: Guid)
    var
        UserProperty: Record "User Property";
    begin
        UserProperty.Init();
        UserProperty."User Security ID" := UserSecurityId;
        UserProperty."Authentication Object ID" := UserSecurityId;
        UserProperty.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotExistInTheAzureADGraph()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user is created, but not added to the Azure AD Graph
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.AddSecurity;
        LibraryPermissions.CreateUser(User, 'username_username', true);

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotHaveAnyRoles()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph, 
        // but the user does not have any roles
        LibraryAzureADUserMgmt.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItDoesNotHaveTheTenantAdminRole()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        LibraryAzureADUserMgmt.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has two roles, but none of them is the role corresponding to the tenant admin
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), 'template 1', 'description', 'display name 1', true);
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), 'template 2', 'description', 'display name 2', true);

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be false
        Assert.IsFalse(IsUserTenantAdmin, 'The user should not be a tenant admin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItHasOnlyTheTenantAdminRole()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        Initialize();

        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        LibraryAzureADUserMgmt.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has a single role, corresponding to the tenant admin
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), CompanyAdminRoleTemplateIdTok,
            'description', 'display name 1', true);

        InsertUserProperty(UserSecurityId());

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be true
        Assert.IsTrue(IsUserTenantAdmin, 'The user should be a tenant admin');

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestIsUserTenantAdminWhenItHasTheTenantAdminRoleAndOtherRoles()
    var
        User: Record User;
        IsUserTenantAdmin: Boolean;
    begin
        Initialize();

        // [GIVEN] A user corresponding to the current user exists in the Azure AD Graph
        LibraryAzureADUserMgmt.AddGraphUser(UserSecurityId(), 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [GIVEN] The user has a three roles, one of which is the tenant admin one
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), 'template 1', 'description', 'display name 1', true);
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), CompanyAdminRoleTemplateIdTok,
            'description', 'display name 2', true);
        LibraryAzureADUserMgmt.AddUserRole(UserSecurityId(), 'template 2', 'description', 'display name 3', true);

        InsertUserProperty(UserSecurityId());

        // [WHEN] Checking whether the user is a tenant admin
        IsUserTenantAdmin := AzureADUserManagement.IsUserTenantAdmin();

        // [THEN] The result should be true
        Assert.IsTrue(IsUserTenantAdmin, 'The user should be a tenant admin');

        TearDown();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateNewUserFromGraphUserWhenTheUserHasNoAssignedPlans()
    var
        User: Record User;
        GraphUser: DotNet UserInfo;
        UserId: Guid;
    begin
        Initialize();

        // [GIVEN] An Azure AD Graph User without a corresponding User record and that is not 
        // entitled from service plan
        UserId := CreateGuid();
        LibraryAzureADUserMgmt.AddGraphUser(GraphUser, UserId, 'username', 'surname', 'email@microsoft.com',
            CreateGuid(), 'Plan Service', 'Status');

        // [WHEN] Trying to create a new user from the graph user
        AzureADUserManagement.CreateNewUserFromGraphUser(GraphUser);

        // [THEN] The database should not contain a User corresponding to the graph user
        Assert.IsFalse(User.Get(UserId), 'The user should not have been created');

        TearDown();
    end;
}

