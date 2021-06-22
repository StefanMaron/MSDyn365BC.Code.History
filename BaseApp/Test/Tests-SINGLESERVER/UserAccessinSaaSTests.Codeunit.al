codeunit 139460 "User Access in SaaS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [SaaS]
    end;

    var
        Assert: Codeunit Assert;
        PermissionManager: Codeunit "Permission Manager";
        UserEuropeDcst1FullTok: Label 'EUROPE\DCST1';
        UserEuropeDcst2ExternalTok: Label 'EUROPE\DCST2';
        ErrorKeyNotSetErr: Label 'WebServiceKey has not been set.';
        LibraryPermissions: Codeunit "Library - Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        WsNeverExpiresToenter: Boolean;
        WsExpirationDateToEnter: DateTime;
        WsInvokeCancelToEnter: Boolean;
        UserGroupO365FullAccessTxt: Label 'D365 FULL ACCESS';
        NewUsersCannotLoginQst: Label 'You have not specified a user group that will be assigned automatically to new users. If users are not assigned a user group, they cannot sign in. \\Do you want to continue?';
        CannotEditForOtherUsersErr: Label 'You can only change your own web service access keys.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HideExternalUsersFromUserPersonalizationCard()
    var
        User: Record User;
        FullUserPersonalization: Record "User Personalization";
        ExternalUserPersonalization: Record "User Personalization";
        UserPersonalizationCard: TestPage "User Personalization Card";
    begin
        // [SCENARIO] External users should not be visible in SaaS (page User Personalization Card)
        Initialize;

        // [GIVEN] Two users, of which only one is external
        CreateUserWithPersonalization(FullUserPersonalization, UserEuropeDcst1FullTok, User."License Type"::"Full User");
        CreateUserWithPersonalization(ExternalUserPersonalization, UserEuropeDcst2ExternalTok, User."License Type"::"External User");

        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Opening the User Personalization Card
        UserPersonalizationCard.OpenView;

        // [THEN] The full user is visible
        Assert.IsTrue(UserPersonalizationCard.GotoRecord(FullUserPersonalization),
          'Full users should be visible in SaaS on page User Personalization Card');

        // [THEN] The external user is hidden
        Assert.IsFalse(UserPersonalizationCard.GotoRecord(ExternalUserPersonalization),
          'External users should not be visible in SaaS on page User Personalization Card');
        UserPersonalizationCard.Close;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowExternalUsersFromUserPersonalizationCard()
    var
        User: Record User;
        FullUserPersonalization: Record "User Personalization";
        ExternalUserPersonalization: Record "User Personalization";
        UserPersonalizationCard: TestPage "User Personalization Card";
    begin
        // [SCENARIO] External users should be visible on-prem and in PaaS (page User Personalization Card)
        Initialize;
        // [GIVEN] Two users, of which only one is external
        CreateUserWithPersonalization(FullUserPersonalization, UserEuropeDcst1FullTok, User."License Type"::"Full User");
        CreateUserWithPersonalization(ExternalUserPersonalization, UserEuropeDcst2ExternalTok, User."License Type"::"External User");

        // [GIVEN] on-prem or PaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Opening the User Personalization Card
        UserPersonalizationCard.OpenView;

        // [THEN] The full user is visible
        Assert.IsTrue(UserPersonalizationCard.GotoRecord(FullUserPersonalization),
          'Full users should be visible in PaaS and on-prem on page User Personalization Card');

        // [THEN] The external user is visible
        Assert.IsTrue(UserPersonalizationCard.GotoRecord(ExternalUserPersonalization),
          'External users should be visible in PaaS and on-prem on page User Personalization Card');
        UserPersonalizationCard.Close;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HideExternalUsersFromUserPersonalizationList()
    var
        User: Record User;
        FullUserPersonalization: Record "User Personalization";
        ExternalUserPersonalization: Record "User Personalization";
        UserPersonalizationList: TestPage "User Personalization List";
    begin
        // [SCENARIO] External users should not be visible in SaaS (page User Personalization List)
        Initialize;
        // [GIVEN] Two users, of which only one is external
        CreateUserWithPersonalization(FullUserPersonalization, UserEuropeDcst1FullTok, User."License Type"::"Full User");
        CreateUserWithPersonalization(ExternalUserPersonalization, UserEuropeDcst2ExternalTok, User."License Type"::"External User");

        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Opening the User Personalization Card
        UserPersonalizationList.OpenView;

        // [THEN] The full user is visible
        Assert.IsTrue(UserPersonalizationList.GotoRecord(FullUserPersonalization),
          'Full users should be visible in SaaS on page User Personalization List');

        // [THEN] The external user is hidden
        Assert.IsFalse(UserPersonalizationList.GotoRecord(ExternalUserPersonalization),
          'External users should not be visible in SaaS on page User Personalization List');
        UserPersonalizationList.Close;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowExternalUsersFromUserPersonalizationList()
    var
        User: Record User;
        FullUserPersonalization: Record "User Personalization";
        ExternalUserPersonalization: Record "User Personalization";
        UserPersonalizationList: TestPage "User Personalization List";
    begin
        // [SCENARIO] External users should be visible on-prem and in PaaS (page User Personalization List)
        Initialize;
        // [GIVEN] Two users, of which only one is external
        CreateUserWithPersonalization(FullUserPersonalization, UserEuropeDcst1FullTok, User."License Type"::"Full User");
        CreateUserWithPersonalization(ExternalUserPersonalization, UserEuropeDcst2ExternalTok, User."License Type"::"External User");

        // [GIVEN] on-prem or PaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Opening the User Personalization Card
        UserPersonalizationList.OpenView;

        // [THEN] The full user is visible
        Assert.IsTrue(UserPersonalizationList.GotoRecord(FullUserPersonalization),
          'Full users should be visible in PaaS and on-prem on page User Personalization List');

        // [THEN] The external user is visible
        Assert.IsTrue(UserPersonalizationList.GotoRecord(ExternalUserPersonalization),
          'External users should be visible in PaaS and on-prem on page User Personalization List');
        UserPersonalizationList.Close;
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAccessWebServiceKeyForAnotherUserInSaaS()
    begin
        // [SCENARIO] In SaaS, a user cannot access another user's web service key
        Initialize;
        // [GIVEN] Running in SaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The user cannnot see the other user's current web service key
        // [THEN] The action to change the web service access key is disabled
        asserterror TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, true);
        Assert.AreEqual(CannotEditForOtherUsersErr, GetLastErrorText(), 'User should not access another user''s web service key.');
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanAccessWebServiceKeyForSelfInSaaS()
    var
        TestUserPermissionsSubscbr: Codeunit "Test User Permissions Subscbr.";
    begin
        // [SCENARIO] In SaaS, a user can access his/her own web service key (read/edit)
        Initialize;
        TestUserPermissionsSubscbr.SetCanManageUser(UserSecurityId()); // admin of one's own
        BindSubscription(TestUserPermissionsSubscbr);
        
        // [GIVEN] Running in SaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user can see his/her own current web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserId(), true);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanAccessWebServiceKeyForAnotherUserOnPrem()
    begin
        // [SCENARIO] On-prem and in PaaS, a user can access another user's web service key (read/edit)
        Initialize;
        // [GIVEN] Running on-premise or in PaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user can see another user's current web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserEuropeDcst1FullTok, false);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,SetWebServiceAccessConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CanAccessWebServiceKeyForSelfOnPrem()
    begin
        // [SCENARIO] On-prem and in PaaS, a user can access his/her own web service key (read/edit)
        Initialize;
        // [GIVEN] Running on-premise or in PaaS
        // [WHEN] The current user opens another user's card
        // [THEN] The current user can see his/her own current web service key
        // [THEN] The action to change the web service access key is enabled
        TestWebServiceKeyAccessibility(UserId(), false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAddNewUserSaaS()
    begin
        // [SCENARIO] in SaaS, users can only be added through the Office 365 portal
        Initialize;
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] The admin attempts to add a new user through the UI of NAV
        asserterror CreateUserFromUI(UserEuropeDcst1FullTok);
        // [THEN] The user cannot be added
        Assert.ExpectedError('Page New - User Card has to close');
    end;

    [Test]
    [HandlerFunctions('NewUsersCannotLoginConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultUserGroupForNewUsersNotSetSaaS()
    var
        UserGroup: Record "User Group";
    begin
        // [SCENARIO] When removing the last default user group to be assigned to new users, Victor receives a warning that new users cannot login
        Initialize;
        // [GIVEN] User groups defined, and one is set as default
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        UserGroup.ModifyAll("Assign to All New Users", false, true);
        CreateGetDefaultUserGroup(UserGroup);
        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Victor tries to de-select all user groups from the defaults to be assigned to new users
        UserGroup.Validate("Assign to All New Users", false);
        // [THEN] A warning appears stating that new users will not be able to login, because they will not be assigned any user group/permissions
        // The warning is handled in NewUsersCannotLoginConfirmHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DefaultUserGroupForNewUsersNotSetPaaSOnPrem()
    var
        UserGroup: Record "User Group";
    begin
        // [SCENARIO] In PaaS and on-prem, when removing the last default user group to be assigned to new users, Victor does not receive a warning
        Initialize;
        // [GIVEN] User groups defined, and one is set as default
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        UserGroup.ModifyAll("Assign to All New Users", false, true);
        CreateGetDefaultUserGroup(UserGroup);
        // [GIVEN] PaaS or on-prem
        // Already set above
        // [WHEN] Victor tries to de-select all user groups from the defaults to be assigned to new users
        UserGroup.Validate("Assign to All New Users", false);
        // [THEN] The SaaS warning (stating that new users will not be able to login) does not appear
        // There is no confirmation handler assigned to this test. If the test succeeds, that is because no confirmation question was showed in ui
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUpdateUserAccessForSaaSWithExistingUserPersonalization()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserPersonalization: Record "User Personalization";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        Plan: Query Plan;
    begin
        // [SCENARIO] Upgraded user from 1.5 without user login entry
        Initialize;
        // [GIVEN] A existing user with no user login entry

        UserGroupMember.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, true);

        Plan.Open();
        Plan.Read();
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", Plan.Plan_ID, true);

        UserPersonalization.Validate("User SID", User."User Security ID");
        UserPersonalization.Insert(true);

        // [WHEN] UpdateUserAccessForSaaS
        PermissionManager.UpdateUserAccessForSaaS(User."User Security ID");

        // [THEN] No user plan/groups/permission are changed
        UserGroupMember.SetRange("User Security ID", User."User Security ID");
        Assert.RecordIsNotEmpty(UserGroupMember);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUpdateUserAccessForSaaSWithInvalidRoleCenter()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanID: Guid;
    begin
        // [SCENARIO] Upgraded user from 1.5 without 2.0 Plans in the db
        Initialize;
        // [GIVEN] A existing user with a plan that is missing a rolecenter (old plan)
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, true);

        // Create a Plan and update "User Plan" table
        PlanID := AzureADPlanTestLibrary.CreatePlan('TestPlan');
        AzureADPlanTestLibrary.ChangePlanRoleCenterID(PlanID, 0);
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanID, true);

        // [WHEN] UpdateUserAccessForSaaS
        PermissionManager.UpdateUserAccessForSaaS(User."User Security ID");

        // [THEN] No user plan/groups/permission are changed
        UserGroupMember.SetRange("User Security ID", User."User Security ID");
        Assert.RecordIsEmpty(UserGroupMember);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotAddNewUserOfLimitedLicenseTypeInSaaS()
    var
        DummyUser: Record User;
    begin
        // [SCENARIO] in SaaS, users of limited license type cannot be added
        Initialize;
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The an extension attempts to add a new user through the code
        asserterror CreateUserWithLicenseType(CreateGuid, DummyUser."License Type"::"Limited User");

        // [THEN] The user cannot be created
        Assert.ExpectedError('are supported in the online environment.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotModifyUserLicenseTypeToLimitedInSaaS()
    var
        User: Record User;
    begin
        // [SCENARIO] in SaaS, user's license type cannot be set to limited
        Initialize;
        // [GIVEN] NAV running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The an extension attempts to modify a user through the code
        LibraryPermissions.CreateUser(User, UserEuropeDcst1FullTok, false);
        User."License Type" := User."License Type"::"Limited User";
        asserterror User.Modify();

        // [THEN] The user cannot be modified
        Assert.ExpectedError('are supported in the online environment.');
    end;

    local procedure CreateUser(UserName: Code[50]): Guid
    var
        User: Record User;
    begin
        exit(CreateUserWithLicenseType(UserName, User."License Type"::"Full User"));
    end;

    local procedure CreateUserWithLicenseType(UserName: Text[250]; LicenseType: Option): Guid
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst then begin
            UserPersonalization.SetRange("User SID", User."User Security ID");
            if UserPersonalization.FindFirst then
                UserPersonalization.Delete(true);
            User.Validate("License Type", LicenseType);
            User.Modify(true);
        end else begin
            User.Init();
            User.Validate("User Name", UserName);
            User.Validate("License Type", LicenseType);
            User.Validate("User Security ID", CreateGuid);
            User.Insert(true);
        end;
        exit(User."User Security ID");
    end;

    local procedure CreateUserWithPersonalization(var UserPersonalization: Record "User Personalization"; UserName: Code[50]; LicenseType: Option)
    var
        User: Record User;
    begin
        CreateUserWithLicenseType(UserName, LicenseType);

        UserPersonalization.SetRange("User SID", User."User Security ID");
        if UserPersonalization.FindFirst then
            UserPersonalization.Delete(true);
        User.SetRange("User Name", UserName);
        User.FindFirst;
        UserPersonalization.Init();
        UserPersonalization.Validate("User SID", User."User Security ID");
        UserPersonalization.Validate(Company, CompanyName);
        UserPersonalization.Insert(true);
    end;

    local procedure CreateUserFromUI(UserName: Code[50])
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew;
        UserCardPage."Windows User Name".Value := UserName;
        UserCardPage.OK.Invoke;
    end;

    local procedure CreateGetDefaultUserGroup(var UserGroup: Record "User Group")
    begin
        if UserGroup.Get(UserGroupO365FullAccessTxt) then
            exit;
        UserGroup.Init();
        UserGroup.Code := UserGroupO365FullAccessTxt;
        UserGroup.Name := UserGroup.Code;
        UserGroup."Assign to All New Users" := true;
        UserGroup.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetWebServiceAccessHandler(var SetWebServiceAccess: TestPage "Set Web Service Access Key")
    begin
        if WsNeverExpiresToenter then
            SetWebServiceAccess.NeverExpires.SetValue(WsNeverExpiresToenter)
        else
            SetWebServiceAccess.ExpirationDate.SetValue(WsExpirationDateToEnter);

        if WsInvokeCancelToEnter then
            SetWebServiceAccess.Cancel.Invoke
        else
            SetWebServiceAccess.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SetWebServiceAccessConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NewUsersCannotLoginConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question <> NewUsersCannotLoginQst then
            exit;
        Reply := true;
    end;

    local procedure TestWebServiceKeyAccessibility(UserName: Code[50]; SoftwareAsAService: Boolean)
    var
        WsCompareKey: Text;
        ChangeWebServiceAccessKeyEnabled: Boolean;
    begin
        CreateUser(UserName);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(SoftwareAsAService);
        WebServiceAccessHelper(CreateDateTime(Today, 0T), true, false, UserName);
        GetUserWebServiceParametersFromUserCard(UserName, WsCompareKey, ChangeWebServiceAccessKeyEnabled);
        if SoftwareAsAService and (UserName <> UserId) then begin
            Assert.AreEqual(
              '*************************************', WsCompareKey, 'The Webservice Key should not be visible to another user in SaaS');
            Assert.AreEqual(false, ChangeWebServiceAccessKeyEnabled, 'Change Webservice Key should not be enabled');
        end else begin
            Assert.AreNotEqual('*************************************', WsCompareKey, ErrorKeyNotSetErr);
            Assert.AreEqual(true, ChangeWebServiceAccessKeyEnabled, 'Change Webservice Key should be enabled');
        end;
    end;

    local procedure WebServiceAccessHelper(KeyExpirationDate: DateTime; KeyNeverExpires: Boolean; InvokeCancel: Boolean; UserName: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        WsNeverExpiresToenter := KeyNeverExpires;
        WsExpirationDateToEnter := KeyExpirationDate;
        WsInvokeCancelToEnter := InvokeCancel;
        UserCardPage.OpenEdit;
        UserCardPage.FindFirstField("User Name", UserName);
        UserCardPage."User Name".AssertEquals(UserName);
        UserCardPage.WebServiceID.AssistEdit;
        UserCardPage.Close;
    end;

    local procedure GetUserWebServiceParametersFromUserCard(UserName: Code[50]; var WsCompareKey: Text; var ChangeWebServiceAccessKeyEnabled: Boolean)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenEdit;
        UserCardPage.FindFirstField("User Name", UserName);
        UserCardPage."User Name".AssertEquals(UserName);
        UserCardPage.WebServiceExpiryDate.AssertEquals('');
        WsCompareKey := UserCardPage.WebServiceID.Value;
        ChangeWebServiceAccessKeyEnabled := UserCardPage.ChangeWebServiceAccessKey.Enabled;
        UserCardPage.Close;
    end;

    local procedure Initialize()
    var
        UserPersonalization: Record "User Personalization";
        User: Record User;
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        UserPersonalization.DeleteAll(true);
        User.DeleteAll(true);
    end;
}

