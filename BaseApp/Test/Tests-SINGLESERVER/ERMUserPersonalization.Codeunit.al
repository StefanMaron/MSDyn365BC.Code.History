codeunit 134912 "ERM User Personalization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User] [Profile]
    end;

    var
#if not CLEAN22
        LibraryPermissions: Codeunit "Library - Permissions";
#endif
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ProfileDefaultRCMustBeUniqueErr: Label 'There must be one default Role Center.';
        WrongExpectedRoleCenter: Label 'Unexpected Default Role Center.';
#if not CLEAN22
        UserGroupAccountantTxt: Label 'USERGROUP-ACCOUNTANT';
        UserGroupSalesTxt: Label 'USERGROUP-SALES';
#endif
        UserCassieTxt: Label 'USER-CASSIE';
#if not CLEAN22
        ProfileIdAccountantTxt: Label 'PROFILEID-ACCOUNTANT';
        ProfileIdSalesTxt: Label 'PROFILEID-SALES';
#endif
        ProfilesErr: Label 'Wrong profiles in the list.';
        NotDefaultRoleCenterIDErr: Label 'Default Role Center ID wasn''t assigned to a newly created Profile.';

    [Test]
    [Scope('OnPrem')]
    procedure RenameProfile()
    var
        AllProfile: Record "All Profile";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        UserPersonalization: Record "User Personalization";
        OriginalProfileID: Code[30];
        ProfileMetadataCountBefore: Integer;
        NewProfileID: Code[30];
    begin
        // Setup
        Initialize();

        OriginalProfileID := LibraryUtility.GenerateRandomText(MaxStrLen(AllProfile."Profile ID"));
        CreateNewProfile(OriginalProfileID, Page::"Business Manager Role Center", false);
        AllProfile.Get(AllProfile.Scope::Tenant, AllProfile."App ID", OriginalProfileID);

        if not UserPersonalization.FindFirst() then begin
            UserPersonalization.Init();
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Insert();
        end else begin
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Modify();
        end;

        TenantProfilePageMetadata."Profile ID" := AllProfile."Profile ID";
        TenantProfilePageMetadata."App ID" := AllProfile."App ID";
        TenantProfilePageMetadata.Owner := AllProfile.Scope;
        TenantProfilePageMetadata."Page ID" := Page::"Business Manager Role Center";
        TenantProfilePageMetadata.Insert();

        // Exercise: Rename profile and check that ProfileMetadata and USerPersonalzation entries are updated
        TenantProfilePageMetadata.SetRange("Profile ID", AllProfile."Profile ID");
        TenantProfilePageMetadata.SetRange("App ID", AllProfile."App ID");
        ProfileMetadataCountBefore := TenantProfilePageMetadata.Count();

        Assert.IsFalse(0 = ProfileMetadataCountBefore, 'There must be ProfileMetadata entries to rename.');

        NewProfileID := 'RenamedProfile';
        AllProfile.Rename(AllProfile.Scope::Tenant, AllProfile."App ID", NewProfileID);

        TenantProfilePageMetadata.SetRange("Profile ID", NewProfileID);
        Assert.AreEqual(
          ProfileMetadataCountBefore, TenantProfilePageMetadata.Count,
          'Renaming Profile must also rename all ProfileMetaData entries for that Profile');

        UserPersonalization.SetRange("Profile ID", NewProfileID);
        Assert.AreEqual(
          1, UserPersonalization.Count, 'Renaming Profile must also rename all UserPersonalization entries for that Profile');

        // Tear Down: Setup default values.
        UserPersonalization.FindFirst();
        UserPersonalization.Validate("Profile ID", '');
        UserPersonalization.Modify(true);

        AllProfile.Rename(AllProfile.Scope::Tenant, AllProfile."App ID", OriginalProfileID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultRoleCenterExist()
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Default Role Center", true);
        Assert.AreEqual(1, AllProfile.Count, ProfileDefaultRCMustBeUniqueErr);
        AllProfile.FindFirst();
        Assert.AreEqual(Page::"Order Processor Role Center", AllProfile."Role Center ID", WrongExpectedRoleCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetDefaultRoleCenterOnListPage()
    var
        DefaultProfile: Record "All Profile";
        AllProfile: Record "All Profile";
        ProfileList: TestPage "Profile List";
    begin
        // [FEATURE] [UI]
        EnsureDefaultRoleCenterExists();
        // [SCENARIO] Action 'Set Default Role Center' should set 'Default Role Center' to Yes in the current profile in the list

        // [GIVEN] A Profile 'A', where 'Default Role Center' is 'Yes'
        DefaultProfile.SetRange("Default Role Center", true);
        DefaultProfile.FindFirst();
        // [GIVEN] A Profile 'B', where 'Default Role Center' is 'No'
        AllProfile.SetRange("Default Role Center", false);
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindFirst();
        // [GIVEN] Open Profile List page and focus on Profile 'B'
        ProfileList.OpenView();
        ProfileList.GotoRecord(AllProfile);

        // [WHEN] Run action 'Set Default Role Center'
        ProfileList.SetDefaultRoleCenterAction.Invoke();

        // [THEN] the Profile 'B', where 'Default Role Center' is 'Yes'
        ProfileList.DefaultRoleCenterField.AssertEquals(true);
        // [THEN] the Profile 'A', where 'Default Role Center' is 'No'
        ProfileList.GotoRecord(DefaultProfile);
        ProfileList.DefaultRoleCenterField.AssertEquals(false);

        // Set back to the previous values
        DefaultProfile.Find();
        DefaultProfile."Default Role Center" := true;
        DefaultProfile.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProfileRoleCenterID()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ProfileCard: TestPage "Profile Card";
    begin
        // Check created Profile through page.

        // Setup.
        Initialize();
        FindAnyRoleCenter(AllObjWithCaption);

        // Exercise: Create a Profile.
        CreateProfile(AllObjWithCaption);

        // Verify: Verify created Role Center ID.
        ProfileCard.OpenView();
        ProfileCard.FILTER.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));
        ProfileCard.RoleCenterIdField.AssertEquals(AllObjWithCaption."Object ID");

        // Tear Down: Setup default values.
        DeleteProfile(AllObjWithCaption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewProfileDefaultRoleCenterID()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ProfileCard: TestPage "Profile Card";
    begin
        // [FEATURE] [Role Center]
        // [SCENARIO 299013] Create a new Profile with default 'Role Center ID'
        Initialize();
        FindAnyRoleCenter(AllObjWithCaption);

        // [GIVEN] Created a new Profile
        CreateProfileDefault(AllObjWithCaption);

        // [WHEN] Open its 'Profile Card'
        ProfileCard.OpenView();
        ProfileCard.FILTER.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));

        // [THEN] 'Role Center ID' is set for Default one
        Assert.AreEqual(Format(ConfPersonalizationMgt.DefaultRoleCenterID()), ProfileCard.RoleCenterIdField.Value, NotDefaultRoleCenterIDErr);
        DeleteProfile(AllObjWithCaption);
    end;

    internal procedure RestartSession()
    var
        UserPersonalization: Record "User Personalization";
        CurrentUserSessionSettings: SessionSettings;
        ProfileScope: Option System,Tenant;
    begin
        UserPersonalization.Get(UserSecurityId());

        CurrentUserSessionSettings.Init();
        CurrentUserSessionSettings.ProfileId := UserPersonalization."Profile ID";
        CurrentUserSessionSettings.ProfileAppId := UserPersonalization."App ID";
#pragma warning disable AL0667
        CurrentUserSessionSettings.ProfileSystemScope := UserPersonalization.Scope = ProfileScope::System;
#pragma warning restore AL0667
        CurrentUserSessionSettings.LanguageId := UserPersonalization."Language ID";
        CurrentUserSessionSettings.LocaleId := UserPersonalization."Locale ID";
        CurrentUserSessionSettings.Timezone := UserPersonalization."Time Zone";

        CurrentUserSessionSettings.RequestSessionUpdate(true);
    end;

    [Test]
    [HandlerFunctions('RolesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyProfile()
    var
        OldAllProfile: Record "All Profile";
        NewAllProfile: Record "All Profile";
        ProfileID: Code[30];
    begin
        // Check that a Profile can be copied into a new profile.
        Initialize();

        OldAllProfile.SetRange(Enabled, true);
        OldAllProfile.FindFirst();
        // Setup : Generate a random code for the new profile in which existing profile will get copied.
        ProfileID :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(NewAllProfile.FieldNo("Profile ID"), DATABASE::"All Profile"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"All Profile", NewAllProfile.FieldNo("Profile ID")));

        // Exercise : Copy the profile into the new Profile.
        RunCopyProfile(OldAllProfile, ProfileID, NewAllProfile);

        // Verify : Verify the newly created Profile.
        VerifyProfile(OldAllProfile, ProfileID, NewAllProfile);

        // Cleanup
        NewAllProfile.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetCurrentProfileID()
    var
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        AllProfileAfter: Record "All Profile";
        AllObjWithCaption: Record AllObjWithCaption;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ProfileID: Code[30];
    begin
        // [SCENARIO] Setting the current profile ID works
        Initialize();

        // [GIVEN] A profile ID, set for the current user
        FindAnyRoleCenter(AllObjWithCaption);
        CreateProfile(AllObjWithCaption);
        ProfileID := Format(AllObjWithCaption."Object ID");

        // [WHEN] The profile ID is assigned
        AllProfile.SetRange("Profile ID", ProfileID);
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        // [THEN] The change is persisted
        ConfPersonalizationMgt.GetCurrentProfile(AllProfileAfter);
        Assert.AreEqual(ProfileID, AllProfileAfter."Profile ID", 'Unexpected profile ID in user personalization');
        Assert.AreEqual(AllProfile.Scope, AllProfileAfter.Scope, 'Unexpected profile scope in user personalization');
        Assert.AreEqual(AllProfile."App ID", AllProfileAfter."App ID", 'Unexpected profile app ID in user personalization');

        // Cleanup
        UserPersonalization.SetRange("Profile ID", Format(AllObjWithCaption."Object ID"));
        UserPersonalization.FindFirst();
        UserPersonalization.Validate("Profile ID", '');
        Clear(UserPersonalization."App ID");
        Clear(UserPersonalization.Scope);
        UserPersonalization.Modify(true);
        DeleteProfile(AllObjWithCaption);
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure UserGroupAssignedToUserUpdateProfileID()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Cassie: Guid;
    begin
        // [SCENARIO] Empty user Profile ID gets a value, when the user is added to a user group
        Initialize();

        // [GIVEN PROFILEID-ACCOUNTANT Profile]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);

        // [GIVEN] User with no rolecenter (i.e. Profile ID) assigned
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);

        // [WHEN] Assigning a user group to the user
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);

        // [THEN] The user is assigned the default role center of this user group
        Assert.AreEqual(ProfileIdAccountantTxt, GetProfileIDForUser(Cassie), 'Incorrect profile ID for Cassie');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteUser(UserCassieTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserGroupAssignedToUserDoNotUpdateProfileID()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Cassie: Guid;
    begin
        // [SCENARIO] Existing user Profile ID remains the same, when the user is added to a user group
        Initialize();

        // [GIVEN PROFILEID-ACCOUNTANT, PROFILEID-SALES Profiles]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);
        CreateNewProfile(ProfileIdSalesTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), false);

        // [GIVEN] User who already has a profile ID assigned in user personalization
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        AssignUserGroupAndProfileToUser(UserGroupSalesTxt, ProfileIdSalesTxt, Cassie);
        Assert.AreNotEqual('', GetProfileIDForUser(Cassie), 'Test prerequisite failed: Cassie should have a default profile');

        // [WHEN] Assigning a user group to the user
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);

        // [THEN] The user profile ID remains unchanged
        Assert.AreEqual(ProfileIdSalesTxt, GetProfileIDForUser(Cassie), 'Incorrect profile ID for Cassie');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteProfileById(ProfileIdSalesTxt);
        DeleteUser(UserCassieTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserProfileIdBecomesEmpty()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Cassie: Guid;
    begin
        // [SCENARIO] When last user group is removed from a user, its default profile becomes empty
        Initialize();

        // [GIVEN PROFILEID-ACCOUNTANT Profile]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);

        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);

        // [GIVEN] User group Accountant, assigned to Cassie
        // [GIVEN] Profile Bus-Accountant, the default of user group Accountant
        // [GIVEN] Cassie has profile ID Bus-Accountant
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);
        Assert.AreNotEqual('', GetProfileIDForUser(Cassie), 'Test prerequisite failed: Cassie should have a default profile');

        // [WHEN] Removing user group Accountant from Cassie
        LibraryPermissions.RemoveUserFromUserGroup(Cassie, UserGroupAccountantTxt);

        // [THEN] Cassie's profile ID becomes empty
        Assert.AreEqual('', GetProfileIDForUser(Cassie), 'Cassie should not have any profile set in user personalization');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteUser(UserCassieTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserProfileIdFallBack()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Cassie: Guid;
    begin
        // [SCENARIO] When a user group is removed from a user, its default profile changes to the next available
        Initialize();

        // [GIVEN PROFILEID-ACCOUNTANT, PROFILEID-SALES Profiles]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);
        CreateNewProfile(ProfileIdSalesTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), false);

        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);

        // [GIVEN] User group Accountant, assigned to Cassie
        // [GIVEN] Profile Bus-Accountant, the default of user group Accountant
        // [GIVEN] Cassie has profile ID Bus-Accountant
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);

        // [GIVEN] User group Sales, assigned to Cassie
        // [GIVEN] Profile Bus-Sales, the default of user group Sales
        AssignUserGroupAndProfileToUser(UserGroupSalesTxt, ProfileIdSalesTxt, Cassie);

        // [WHEN] Removing user group Accountant from Cassie
        LibraryPermissions.RemoveUserFromUserGroup(Cassie, UserGroupAccountantTxt);

        // [THEN] Cassie's profile ID falls back to the next available: Bus-Sales
        Assert.AreEqual(ProfileIdSalesTxt, GetProfileIDForUser(Cassie), 'Incorrect profile ID for Cassie');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteProfileById(ProfileIdSalesTxt);
        DeleteUser(UserCassieTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserProfileIdOnUserGroupModify()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Cassie: Guid;
    begin
        // [SCENARIO] When a user group membership is modified, the changes are propagated to user personalization
        Initialize();

        // [GIVEN PROFILEID-ACCOUNTANT, PROFILEID-SALES Profiles]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);
        CreateNewProfile(ProfileIdSalesTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), false);
        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);

        // [GIVEN] User group Accountant, assigned to Cassie
        // [GIVEN] Profile Bus-Accountant, the default of user group Accountant
        // [GIVEN] Cassie has profile ID Bus-Accountant
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);

        // [GIVEN] User group Sales, assigned to Cassie
        // [GIVEN] Profile Bus-Sales, the default of user group Sales
        LibraryPermissions.CreateUserGroupWithCode(UserGroupSalesTxt);
        AddProfileIDToUserGroup(ProfileIdSalesTxt, UserGroupSalesTxt);

        // [WHEN] Changing Cassie from Accountant to Sales
        LibraryPermissions.ChangeUserGroupOfUser(Cassie, UserGroupAccountantTxt, UserGroupSalesTxt);

        // [THEN] Cassie's profile ID is changed accordingly
        Assert.AreEqual(ProfileIdSalesTxt, GetProfileIDForUser(Cassie), 'Incorrect profile ID for Cassie');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteProfileById(ProfileIdSalesTxt);
        DeleteUser(UserCassieTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserProfileIdOnUserGroupModifyOnSaaS()
    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Cassie: Guid;
        PreviousSaaSTestability: Boolean;
    begin
        // [SCENARIO] When a user group membership is modified, the changes are propagated to user personalization
        Initialize();
        PreviousSaaSTestability := EnvironmentInfo.IsSaaS();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN PROFILEID-ACCOUNTANT, PROFILEID-SALES Profiles]
        CreateNewProfile(ProfileIdAccountantTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), true);
        CreateNewProfile(ProfileIdSalesTxt, ConfPersonalizationMgt.DefaultRoleCenterID(), false);

        // [GIVEN] User group Sales, assigned to Cassie
        LibraryPermissions.CreateUserGroupWithCode(UserGroupSalesTxt);

        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);

        // [GIVEN] User group Accountant, assigned to Cassie
        // [GIVEN] Profile Bus-Accountant, the default of user group Accountant
        // [GIVEN] Cassie has profile ID Bus-Accountant
        AssignUserGroupAndProfileToUser(UserGroupAccountantTxt, ProfileIdAccountantTxt, Cassie);

        // [GIVEN] Profile Bus-Sales, the default of user group Sales
        AddProfileIDToUserGroup(ProfileIdSalesTxt, UserGroupSalesTxt);

        // [WHEN] Changing Cassie from Accountant to Sales
        LibraryPermissions.ChangeUserGroupOfUser(Cassie, UserGroupAccountantTxt, UserGroupSalesTxt);

        // [THEN] Cassie's profile ID is not changed on SaaS
        Assert.AreEqual(ProfileIdAccountantTxt, GetProfileIDForUser(Cassie), 'Incorrect profile ID for Cassie');

        // Cleanup
        DeleteProfileById(ProfileIdAccountantTxt);
        DeleteProfileById(ProfileIdSalesTxt);
        DeleteUser(UserCassieTxt);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(PreviousSaaSTestability);
    end;
#endif

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure ShowTermsAndConditions()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LogInManagement: Codeunit LogInManagement;
        OldTestability: Boolean;
    begin
        // [SCENARIO] "Thirty Day Trial Dialog" page is shown when change company for the user in PROD
        Initialize();
        OldTestability := EnvironmentInfo.IsSaaS();

        // [GIVEN] SaaS, the company is not the evaluation company
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToEvaluation(false);

        // [WHEN] Open Company
        LogInManagement.CompanyOpen();

        // [THEN] "Thirty Day Trial Dialog" page is shown (ThirtyDayTrialDialogPageHandler)
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(OldTestability);
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HideTermsAndConditionsInSandbox()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LogInManagement: Codeunit LogInManagement;
    begin
        // [SCENARIO] "Thirty Day Trial Dialog" page is not shown when opening company for the user in Sandbox
        Initialize();

        // [GIVEN] Sandbox, SaaS, the company is not the evaluation company
        SetSandboxValue(true);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetCompanyToEvaluation(false);

        // [WHEN] Open Company
        LogInManagement.CompanyOpen();

        // [THEN] "Thirty Day Trial Dialog" page is not shown
        // No Handler

        SetSandboxValue(false);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure RenameUserGroupMemberCompanyName()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[2] of Record "User Group";
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to Company Name in User Group Member record make no changes to User's Personalization profile
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, 'Frank', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y - User is a member. User Personalization is created with Default Profile ID of X
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;
        UserGroup[1].Get(UserGroup[1].Code);
        VerifyUserPersonalization(User."User Security ID", UserGroup[1]."Default Profile ID");

        // [WHEN] Rename User Group Member with different value for company name
        UserGroupMember.Get(UserGroup[1].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroupMember."User Group Code", UserGroupMember."User Security ID", '');

        // [THEN] Profile didn't change
        VerifyUserPersonalization(User."User Security ID", UserGroup[1]."Default Profile ID");

        // Cleanup
        DeleteUser('Frank');
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeSingleUserGroupMembershipConfirmed()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[2] of Record "User Group";
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Code in a single User Group Member record changes User's Personalization profile is confirmed
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, 'Frank', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
        end;

        // [GIVEN] User is a member of Y. User Personalization is created with Default Profile ID of Y
        LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[2].Code);

        // [WHEN] Rename User Group Member with different value for User Group Code
        LibraryVariableStorage.Enqueue(true);
        UserGroupMember.Get(UserGroup[2].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[1].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile changed to the new group membership default
        UserGroup[1].Get(UserGroup[1].Code);
        VerifyUserPersonalization(User."User Security ID", UserGroup[1]."Default Profile ID");
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser('Frank');
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeSingleUserGroupMembershipDeclined()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[2] of Record "User Group";
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Code in a single User Group Member record changes User's Personalization profile is confirmed
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user, and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
        end;

        // [GIVEN] User is a member of Y. User Personalization is created with Default Profile ID of Y
        LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[2].Code);

        // [WHEN] Rename User Group Member with different value for User Group Code
        LibraryVariableStorage.Enqueue(false);
        UserGroupMember.Get(UserGroup[2].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[1].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile didn't change
        UserGroup[2].Get(UserGroup[2].Code);
        VerifyUserPersonalization(User."User Security ID", UserGroup[2]."Default Profile ID");
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserGroupMembershipNotRelatedToPersonalization()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[3] of Record "User Group";
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Membership not related to Personalization record make no changes to User's Personalization profile
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user, and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y - User is a member. User Personalization is created with Default Profile ID of X
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;

        // [GIVEN] User Group Z
        LibraryPermissions.CreateUserGroup(UserGroup[3], '');

        // [WHEN] Rename User Group Y Membership with User Group Code = Z
        UserGroupMember.Get(UserGroup[2].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[3].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile didn't change
        UserGroup[1].Get(UserGroup[1].Code);
        VerifyUserPersonalization(User."User Security ID", UserGroup[1]."Default Profile ID");

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserGroupMembershipNotUniquelyRelatedToPersonalization()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[3] of Record "User Group";
        DefProfileID: Code[30];
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Membership related, but not alone, to Personalization record make no changes to User's Personalization profile
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user, and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y with the same Default Profile ID. User is member X,Y.
        DefProfileID := CreateProfileID();
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(DefProfileID, UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;

        // [GIVEN] User Group Z
        LibraryPermissions.CreateUserGroup(UserGroup[3], '');

        // [WHEN] Rename User Group Y Membership with User Group Code = Z
        UserGroupMember.Get(UserGroup[2].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[3].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile didn't change
        VerifyUserPersonalization(User."User Security ID", DefProfileID);

        // Cleanup
        DeleteUser(User."User Name");
        DeleteProfileById(DefProfileID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameUserGroupMembershipRelatedToPersonalizationConfirmed()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[3] of Record "User Group";
        SystemProfileID: Code[30];
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Membership related to Personalization record make changes to User's Personalization profile if confirmed
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user, and a system Default Profile ID
        SystemProfileID := CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y with different Default Profile ID. User is member X,Y, Personalization associated with X
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;

        // [GIVEN] User Group Z
        LibraryPermissions.CreateUserGroup(UserGroup[3], '');

        // [WHEN] Rename User Group X Membership with User Group Code = Z
        LibraryVariableStorage.Enqueue(true);
        UserGroupMember.Get(UserGroup[1].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[3].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile changed
        VerifyUserPersonalization(User."User Security ID", SystemProfileID);
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenameUserGroupMembershipRelatedToPersonalizationDeclined()
    var
        User: Record User;
        UserGroupMember: Record "User Group Member";
        UserGroup: array[3] of Record "User Group";
        i: Integer;
    begin
        // [SCENARIO 295344] Changes to User Group Membership related to Personalization record don't make changes to User's Personalization profile if declined
        // [FEATURE] [User Group]
        Initialize();

        // [GIVEN] A user, and a system Default Profile ID
        CreateOrFindDefaultProfileID();
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] Two User Groups: X, Y with different Default Profile ID. User is member X,Y, Personalization associated with X
        for i := 1 to 2 do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;

        // [GIVEN] User Group Z
        LibraryPermissions.CreateUserGroup(UserGroup[3], '');

        // [WHEN] Rename User Group X Membership with User Group Code = Z
        LibraryVariableStorage.Enqueue(false);
        UserGroupMember.Get(UserGroup[1].Code, User."User Security ID", CompanyName);
        UserGroupMember.Rename(UserGroup[3].Code, UserGroupMember."User Security ID", CompanyName);

        // [THEN] Profile didn't change
        UserGroup[1].Get(UserGroup[1].Code);
        VerifyUserPersonalization(User."User Security ID", UserGroup[1]."Default Profile ID");
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
    end;

    [Test]
    [HandlerFunctions('AvailableProfilesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUserGroupPropagatedToPersonalization()
    var
        User: Record User;
        UserGroup: Record "User Group";
        UserGroups: TestPage "User Groups";
        PersonalizationProfileID: Code[30];
        PersonalizationProfileID1: Code[30];
    begin
        // [FEATURE] [User Group] [UI]
        // [SCENARIO 302198] Changes to User Group Default Profile ID change User's Personalization profile
        Initialize();

        // [GIVEN] A user
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] User Group with Default Profile ID
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        PersonalizationProfileID := CreateProfileID();
        AddProfileIDToUserGroup(PersonalizationProfileID, UserGroup.Code);
        LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup.Code);
        VerifyUserPersonalization(User."User Security ID", PersonalizationProfileID);

        // [WHEN] Change Default Profile ID for User Group
        PersonalizationProfileID1 := CreateProfileID();
        LibraryVariableStorage.Enqueue(PersonalizationProfileID1);
        UserGroups.OpenEdit();
        UserGroups.FILTER.SetFilter(Code, UserGroup.Code);
        UserGroups.YourProfileID.Lookup();

        // [THEN] User's Personalization change for new profile
        UserGroup.Get(UserGroup.Code);
        VerifyUserPersonalizationFromUserGroup(User."User Security ID", UserGroup);
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        DeleteProfileById(PersonalizationProfileID);
        DeleteProfileById(PersonalizationProfileID1);
    end;

    [Test]
    [HandlerFunctions('AvailableProfilesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeToUnrelatedUserGroupNotPropagatedToPersonalization()
    var
        User: Record User;
        UserGroup: array[2] of Record "User Group";
        UserGroups: TestPage "User Groups";
        PersonalizationProfileID: Code[30];
        i: Integer;
    begin
        // [FEATURE] [User Group] [UI]
        // [SCENARIO 302198] Changes to User Group Default Profile ID don't change User's Personalization profile
        Initialize();

        // [GIVEN] User
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] User Group "X" with "Default Profile ID" = "X-P"
        // [GIVEN] User Group "Y" with "Default Profile ID" = "Y-P"
        // [GIVEN] "Profile ID" = "X-P" in User personalization
        for i := 1 to ArrayLen(UserGroup) do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(CreateProfileID(), UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;
        UserGroup[1].Get(UserGroup[1].Code);
        PersonalizationProfileID := UserGroup[1]."Default Profile ID";
        VerifyUserPersonalization(User."User Security ID", PersonalizationProfileID);

        // [WHEN] Set "Default Profile ID" = "Y-New" in User Group "Y"
        LibraryVariableStorage.Enqueue(CreateProfileID());
        UserGroups.OpenEdit();
        UserGroups.FILTER.SetFilter(Code, UserGroup[2].Code);
        UserGroups.YourProfileID.Lookup();

        // [THEN] User's Personalization doesn't change for new profile
        VerifyUserPersonalization(User."User Security ID", PersonalizationProfileID);
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(UserGroup[i]."Default Profile ID");
        DeleteProfileById(UserGroup[2]."Default Profile ID");
    end;

    [Test]
    [HandlerFunctions('AvailableProfilesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeToNotSingleUserGroupNotPropagatedToPersonalization()
    var
        User: Record User;
        UserGroup: array[3] of Record "User Group";
        UserGroups: TestPage "User Groups";
        PersonalizationProfileID: array[3] of Code[30];
        i: Integer;
        OtherProfileID: Code[30];
    begin
        // [FEATURE] [User Group] [UI]
        // [SCENARIO 302198] Changes to User Group Default Profile ID don't change User's Personalization profile when there are other user groups with that profile.
        Initialize();

        // [GIVEN] User
        LibraryPermissions.CreateUser(User, '', false);
        EnsureUserPersonalizationExists(User."User Security ID");

        // [GIVEN] User Group "X" with "Default Profile ID" = "X-P"
        // [GIVEN] User Group "Y" with "Default Profile ID" = "Y-P"
        // [GIVEN] User Group "XX" with "Default Profile ID" = "X-P"
        // [GIVEN] "Profile ID" = "X-P" in User personalization
        PersonalizationProfileID[1] := CreateProfileID();
        PersonalizationProfileID[2] := CreateProfileID();
        PersonalizationProfileID[3] := PersonalizationProfileID[1];
        for i := 1 to ArrayLen(UserGroup) do begin
            LibraryPermissions.CreateUserGroup(UserGroup[i], '');
            AddProfileIDToUserGroup(PersonalizationProfileID[i], UserGroup[i].Code);
            LibraryPermissions.AddUserToUserGroupByCode(User."User Security ID", UserGroup[i].Code);
        end;
        VerifyUserPersonalization(User."User Security ID", PersonalizationProfileID[1]);

        // [WHEN] Set "Default Profile ID" = "X-New" in User Group "X"
        OtherProfileID := CreateProfileID();
        LibraryVariableStorage.Enqueue(OtherProfileID);
        UserGroups.OpenEdit();
        UserGroups.FILTER.SetFilter(Code, UserGroup[1].Code);
        UserGroups.YourProfileID.Lookup();

        // [THEN] User's Personalization doesn't change for new profile
        VerifyUserPersonalization(User."User Security ID", PersonalizationProfileID[1]);
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteUser(User."User Name");
        for i := 1 to 2 do
            DeleteProfileById(PersonalizationProfileID[i]);
        DeleteProfileById(OtherProfileID);
    end;

    [Test]
    [HandlerFunctions('AvailableProfilesPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUserGroupWithNoMembers()
    var
        UserGroup: Record "User Group";
        UserGroups: TestPage "User Groups";
        PersonalizationProfileID: Code[30];
        OtherProfileID: Code[30];
    begin
        // [FEATURE] [User Group] [UI]
        // [SCENARIO 302198] Change User Group's Default Profile ID
        Initialize();

        // [GIVEN] User Group with Default Profile ID
        LibraryPermissions.CreateUserGroup(UserGroup, '');
        OtherProfileID := CreateProfileID();
        AddProfileIDToUserGroup(OtherProfileID, UserGroup.Code);

        // [WHEN] Change Default Profile ID for User Group
        PersonalizationProfileID := CreateProfileID();
        LibraryVariableStorage.Enqueue(PersonalizationProfileID);
        UserGroups.OpenEdit();
        UserGroups.FILTER.SetFilter(Code, UserGroup.Code);
        UserGroups.YourProfileID.Lookup();
        UserGroups.Close();

        // [THEN] User group's default profile successfully changed
        UserGroup.Get(UserGroup.Code);
        UserGroup.TestField("Default Profile ID", PersonalizationProfileID);
        LibraryVariableStorage.AssertEmpty();

        // Cleanup
        DeleteProfileById(PersonalizationProfileID);
        DeleteProfileById(OtherProfileID);
    end;
#endif

    // Helper functions

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
    begin
        DeleteUser(UserCassieTxt);

        AllProfile.SetRange("App ID", AllProfile."App ID");
        if AllProfile.FindSet() then
            repeat
                AllProfile.Delete();
            until AllProfile.Next() = 0;

        EnsureUserPersonalizationExists(UserSecurityId());
    end;

    local procedure EnsureUserPersonalizationExists(UserSID: Guid)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.DeleteAll();

        UserPersonalization.Reset();
        UserPersonalization.Init();
        UserPersonalization."User SID" := UserSID;
        UserPersonalization.Insert();
    end;

    local procedure CreateProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        ProfileCard: TestPage "Profile Card";
    begin
        // Ensure it doesn't already exist
        DeleteProfile(AllObjWithCaption);

        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.DescriptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.CaptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.RoleCenterIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.OK().Invoke();
    end;

    local procedure CreateProfileDefault(AllObjWithCaption: Record AllObjWithCaption)
    var
        ProfileCard: TestPage "Profile Card";
    begin
        // Ensure it doesn't already exist
        DeleteProfile(AllObjWithCaption);

        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.DescriptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.CaptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.OK().Invoke();
    end;

    local procedure CreateProfileID(): Code[30]
    var
        ProfileCard: TestPage "Profile Card";
        ProfileID: Code[30];
    begin
        ProfileCard.OpenNew();
        ProfileCard.ProfileIdField.SetValue(LibraryUtility.GenerateGUID());
        ProfileCard.DescriptionField.SetValue(LibraryUtility.GenerateGUID());
        ProfileCard.CaptionField.SetValue(LibraryUtility.GenerateGUID());
        ProfileID := ProfileCard.ProfileIdField.Value();
        ProfileCard.OK().Invoke();
        exit(ProfileID);
    end;

    local procedure CreateUserPersonalization(var UserPersonalization: Record "User Personalization"; UserSID: Guid; ProfileID: Code[30])
    begin
        UserPersonalization.Init();
        UserPersonalization.Validate("User SID", UserSID);
        UserPersonalization.Validate("Profile ID", ProfileID);
        UserPersonalization.Insert(true);
    end;

    local procedure CreateUserPersonalization(var UserPersonalization: Record "User Personalization"; AppID: Guid; Scope: Option; UserSID: Guid; ProfileID: Code[30])
    begin
        UserPersonalization.Init();
        UserPersonalization.Validate("User SID", UserSID);
        UserPersonalization.Validate("App ID", AppID);
        UserPersonalization.Validate(Scope, Scope);
        UserPersonalization.Validate("Profile ID", ProfileID);
        UserPersonalization.CalcFields(Role);
        UserPersonalization.Insert(true);
    end;

    local procedure CreateOrFindDefaultProfileID(): Code[30]
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        DefProfileID: Code[30];
    begin
        AllProfile.SetRange("Default Role Center", true);
        if AllProfile.FindFirst() then
            DefProfileID := AllProfile."Profile ID"
        else begin
            DefProfileID := LibraryUtility.GenerateGUID();
            CreateNewProfile(DefProfileID, ConfPersonalizationMgt.DefaultRoleCenterID(), true);
        end;
        exit(DefProfileID);
    end;

    local procedure GetCurrentTimeZone(): Text[180]
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId());
        exit(UserPersonalization."Time Zone");
    end;

    local procedure SetTimeZone(TimeZone: Text[180])
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization.Validate("Time Zone", TimeZone);
        UserPersonalization.Modify(true);
    end;

    local procedure DeleteProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));
        if AllProfile.FindFirst() then
            AllProfile.Delete(true);
    end;

    local procedure RunCopyProfile(OldAllProfile: Record "All Profile"; NewProfileID: Code[30]; var NewAllProfile: Record "All Profile")
    var
        CopyProfileTestPage: TestPage "Copy Profile";
    begin
        NewAllProfile.SetRange("Profile ID", NewProfileID);
        Assert.RecordCount(NewAllProfile, 0);

        // Run Copy Profile.
        CopyProfileTestPage.OpenEdit();
        LibraryVariableStorage.Enqueue(OldAllProfile."Profile ID");
        CopyProfileTestPage.SourceProfileID.AssistEdit();
        CopyProfileTestPage.DestinationProfileID.Value := NewProfileID;
        CopyProfileTestPage.DestinationProfileCaption.Value := LibraryUtility.GenerateGUID();
        CopyProfileTestPage.OK().Invoke();

        Assert.RecordCount(NewAllProfile, 1);
        NewAllProfile.FindFirst();
        NewAllProfile.SetRange("Profile ID");
    end;

    local procedure VerifyProfile(OldAllProfile: Record "All Profile"; ProfileID: Code[30]; NewAllProfile: Record "All Profile")
    var
        AllProfileInDatabase: Record "All Profile";
        TableField: Record Field;
        RecRef1: RecordRef;
        RecRef2: RecordRef;
    begin
        // Get the profile from the DB
        AllProfileInDatabase.SetRange("Profile ID", ProfileID);
        Assert.RecordCount(AllProfileInDatabase, 1);
        AllProfileInDatabase.FindFirst();

        // Step 1: the profile from the DB is the same as the profile returned from the copy profile page
        TableField.SetRange("No.", -1);
        RecRef1.GetTable(AllProfileInDatabase);
        RecRef2.GetTable(NewAllProfile);
        Assert.RecordsAreEqualExceptCertainFields(RecRef1, RecRef2, TableField, 'Copied profile in DB is different from the one returned by the Copy Profile page.');

        // Step 2: the source profile and the destination profile have the same fields, except the one that have changed (profile ID, description, and default RC)
        TableField.SetRange(TableNo, Database::"All Profile");
        if OldAllProfile."Default Role Center" then begin
            Assert.IsFalse(NewAllProfile."Default Role Center", 'Copied profile should not be default.');
            TableField.SetFilter("No.", '%1|%2|%3', OldAllProfile.FieldNo("Profile ID"), OldAllProfile.FieldNo(Description), OldAllProfile.FieldNo("Default Role Center"));
        end else
            TableField.SetFilter("No.", '%1|%2', OldAllProfile.FieldNo("Profile ID"), OldAllProfile.FieldNo(Description));
        RecRef1.GetTable(OldAllProfile);
        RecRef2.GetTable(NewAllProfile);
        Assert.RecordsAreEqualExceptCertainFields(RecRef1, RecRef2, TableField, 'Copied profile is different from source profile.');
    end;

    local procedure FindAnyRoleCenter(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');  // Here RoleCenter is needed for Object Subtype.
        AllObjWithCaption.FindFirst();
    end;

    local procedure IsRoleCenterPageID(PageId: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
        AllObjWithCaption.SetRange("Object ID", PageId);
        exit(not AllObjWithCaption.IsEmpty());
    end;

    local procedure EnsureDefaultRoleCenterExists()
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange(Enabled, true);
        AllProfile.FindLast();
        SetProfileDefaultRoleCenter(AllProfile);
    end;

    local procedure SetProfileDefaultRoleCenter(var AllProfile: Record "All Profile")
    begin
        AllProfile.Validate("Default Role Center", true);
        AllProfile.Modify(true);
    end;

    local procedure VerifyProfileListPage(var ProfileListPage: TestPage "Profile List"; ExpectedProfilesCount: Integer)
    var
        I: Integer;
    begin
        ProfileListPage.First();
        repeat
            I += 1;
        until ProfileListPage.Next() = false;
        Assert.IsTrue(I = ExpectedProfilesCount, ProfilesErr);
    end;

    local procedure VerifyAvailableRolesPage(var Roles: TestPage Roles; ExpectedProfilesCount: Integer)
    var
        I: Integer;
    begin
        Roles.First();
        repeat
            I += 1;
        until Roles.Next() = false;
        Assert.IsTrue(I = ExpectedProfilesCount, ProfilesErr);
    end;

    local procedure VerifyUserPersonalization(UserSecurityID: Guid; ProfileID: Code[30])
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityID);
        UserPersonalization.TestField("Profile ID", ProfileID);
    end;

#if not CLEAN22
    local procedure VerifyUserPersonalizationFromUserGroup(UserSecurityID: Guid; UserGroup: Record "User Group")
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityID);
        UserPersonalization.TestField("Profile ID", UserGroup."Default Profile ID");
        UserPersonalization.TestField("App ID", UserGroup."Default Profile App ID");
        UserPersonalization.TestField(Scope, UserGroup."Default Profile Scope");
    end;

    local procedure AddProfileIDToUserGroup(ProfileID: Code[30]; UserGroupCode: Code[20])
    var
        UserGroup: Record "User Group";
        EmptyGuid: Guid;
    begin
        UserGroup.Get(UserGroupCode); // let it fail if not found
        UserGroup."Default Profile ID" := ProfileID;
        UserGroup."Default Profile Scope" := UserGroup."Default Profile Scope"::Tenant;
        UserGroup."Default Profile App ID" := EmptyGuid;
        UserGroup.Modify(true);
    end;
#endif

    local procedure GetProfileIDForUser(UserID: Guid): Code[30]
    var
        UserPersonalization: Record "User Personalization";
    begin
        if UserPersonalization.Get(UserID) then;
        exit(UserPersonalization."Profile ID");
    end;

#if not CLEAN22
    local procedure AssignUserGroupAndProfileToUser(UserGroupCode: Code[20]; ProfileID: Code[30]; User: Guid)
    begin
        LibraryPermissions.CreateUserGroupWithCode(UserGroupCode);
        AddProfileIDToUserGroup(ProfileID, UserGroupCode);
        LibraryPermissions.AddUserToUserGroupByCode(User, UserGroupCode);
    end;
#endif

    local procedure DeleteUser(UserName: Code[50])
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete(true);
            User.Delete(true);
        end;
    end;

    local procedure CreateNewProfile(ProfileID: Code[30]; RoleCenterID: Integer; IsDefault: Boolean)
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        Assert.RecordCount(AllProfile, 0);

        Clear(AllProfile);
        AllProfile.Init();
        AllProfile."Profile ID" := ProfileID;
        AllProfile.Description := ProfileID;
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Default Role Center" := IsDefault;
        AllProfile."Role Center ID" := RoleCenterID;
        AllProfile.Insert(true);

        if IsDefault then
            ConfPersonalizationMgt.SetOtherProfilesAsNonDefault(AllProfile);
    end;

    local procedure DeleteProfileById(ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        if AllProfile.FindFirst() then
            AllProfile.Delete();
    end;

    local procedure SetSandboxValue(Enable: Boolean)
    var
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        LibraryPermissions.SetTestTenantEnvironmentType(Enable);
    end;

    local procedure SetCompanyToEvaluation(IsEvaluationCompany: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();
    end;

    // Handlers

    [ModalPageHandler]
    procedure RolesModalPageHandler(var Roles: TestPage Roles)
    var
        ProfileId: Code[30];
        AllProfile: Record "All Profile";
    begin
        ProfileId := LibraryVariableStorage.DequeueText();
        AllProfile.SetRange(Scope, AllProfile.Scope::Tenant);
        AllProfile.SetRange("Profile ID", ProfileId);
        AllProfile.FindFirst();
        Roles.GoToRecord(AllProfile);
        Roles.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThirtyDayTrialDialogPageHandler(var ThirtyDayTrialDialog: TestPage "Thirty Day Trial Dialog")
    begin
        ThirtyDayTrialDialog.TermsAndConditionsCheckBox.SetValue(true);
        ThirtyDayTrialDialog.ActionStartTrial.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProfilesPageHandler(var Roles: TestPage Roles)
    begin
        Roles.Filter.SetFilter("Profile ID", LibraryVariableStorage.DequeueText());
        Roles.OK().Invoke();
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure RestartHandler(var SessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

