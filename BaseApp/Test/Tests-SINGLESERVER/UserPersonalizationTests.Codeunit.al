codeunit 134991 "User Personalization Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [User] [Profile]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";
        Assert: Codeunit Assert;
        UserGroupAccountantTxt: Label 'USERGROUP-ACCOUNTANT';
        UserCassieTxt: Label 'USER-CASSIE';
        RoleCenterID: Integer;
        UserName: Code[50];

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('EditProfileIDHandler')]
    [Scope('OnPrem')]
    procedure TestFieldRoleCardPage()
    var
        User: Record User;
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        UserPersonalizationCard: TestPage "User Personalization Card";
    begin
        // [SCENARIO] The User can change the Role
        Initialize();

        UserPersonalization.DeleteAll();

        // [GIVEN] User Personalization 
        LibraryPermissions.CreateUser(User, 'Frank', false);
        CreateUserPersonalization(UserPersonalization, User."User Security ID", CreateProfileID());

        // [GIVEN] The new Role that we want to set
        AllProfile.SetFilter("Profile ID", '<>%1', UserPersonalization."Profile ID");
        AllProfile.SetFilter(Enabled, Format(true));
        AllProfile.FindFirst();
        RoleCenterID := AllProfile."Role Center ID";

        // [WHEN] The Role is changed to a different value
        UserPersonalizationCard.OpenEdit;
        UserPersonalizationCard.Role.AssistEdit();

        // [THEN] The new Role value is displayed in the page
        UserPersonalizationCard.Role.AssertEquals(AllProfile.Caption);

        UserPersonalizationCard.Close();

        // [THEN] The new "Profile ID" value is stored in the "User Personalization" table after that the page is closed
        UserPersonalization.FindFirst(); // reload values in the table because they have been changed in the page
        Assert.AreEqual(AllProfile."Profile ID", UserPersonalization."Profile ID", StrSubstno('The UserPersonalization."Profile ID" should be equal to %1', AllProfile."Profile ID"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('EditProfileIDHandler')]
    [Scope('OnPrem')]
    procedure TestFieldRoleListPage()
    var
        User: Record User;
        AllProfile: Record "All Profile";
        UserPersonalization: Record "User Personalization";
        UserPersonalizationList: TestPage "User Personalization List";
    begin
        // [SCENARIO] The User can change the Role
        Initialize();

        UserPersonalization.DeleteAll();

        // [GIVEN] User Personalization 
        LibraryPermissions.CreateUser(User, 'Frank', false);
        CreateUserPersonalization(UserPersonalization, User."User Security ID", CreateProfileID());

        // [GIVEN] The new Role that we want to set
        AllProfile.SetFilter("Profile ID", '<>%1', UserPersonalization."Profile ID");
        AllProfile.SetFilter(Enabled, Format(true));
        AllProfile.FindFirst();
        RoleCenterID := AllProfile."Role Center ID";

        // [WHEN] The Role is changed to a different value
        UserPersonalizationList.OpenEdit;
        UserPersonalizationList.GoToRecord(UserPersonalization);
        UserPersonalizationList.Role.AssistEdit();

        // [THEN] The new Role value is displayed in the page
        UserPersonalizationList.Role.AssertEquals(AllProfile.Caption);

        UserPersonalizationList.Close();

        // [THEN] The new "Profile ID" value is stored in the "User Personalization" table after that the page is closed
        UserPersonalization.FindFirst(); // reload values in the table because they have been changed in the page
        Assert.AreEqual(AllProfile."Profile ID", UserPersonalization."Profile ID", StrSubstno('The UserPersonalization."Profile ID" should be equal to %1', AllProfile."Profile ID"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('EditLanguageIDHandler')]
    [Scope('OnPrem')]
    procedure TestEditRegionCardPage()
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
        UserPersonalizationCard: TestPage "User Personalization Card";
        LocaleID: Integer;
    begin
        // [SCENARIO] The User can change the Region
        LocaleID := 1040; // Italy
        WindowsLanguage.Get(LocaleID);
        Initialize();

        UserPersonalization.DeleteAll();

        // [GIVEN] User Personalization 
        LibraryPermissions.CreateUser(User, 'Frank', false);
        CreateUserPersonalization(UserPersonalization, User."User Security ID", CreateProfileID());

        // [WHEN] The Region is changed to a different value
        UserPersonalizationCard.OpenEdit;
        UserPersonalizationCard.Region.AssistEdit();

        // [THEN] The new Region value is displayed in the page
        UserPersonalizationCard.Region.AssertEquals(WindowsLanguage.Name);

        UserPersonalizationCard.Close();

        // [THEN] The new "Locale ID" value is stored in the "User Personalization" table after that the page is closed
        UserPersonalization.FindFirst(); // reload values in the table because they have been changed in the page
        Assert.AreEqual(LocaleID, UserPersonalization."Locale ID", 'The UserPersonalization."Locale ID" should be equal to 1040');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('EditLanguageIDHandler')]
    [Scope('OnPrem')]
    procedure TestEditRegionListPage()
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
        UserPersonalizationList: TestPage "User Personalization List";
        LocaleID: Integer;
    begin
        // [SCENARIO] The User can change the Region
        LocaleID := 1040; // Italy
        WindowsLanguage.Get(LocaleID);
        Initialize();

        UserPersonalization.DeleteAll();

        // [GIVEN] User Personalization 
        LibraryPermissions.CreateUser(User, 'Frank', false);
        CreateUserPersonalization(UserPersonalization, User."User Security ID", CreateProfileID());

        // [WHEN] The Region is changed to a different value
        UserPersonalizationList.OpenEdit;
        UserPersonalizationList.GoToRecord(UserPersonalization);
        UserPersonalizationList.Region.AssistEdit();

        // [THEN] The new Region value is displayed in the page
        UserPersonalizationList.Region.AssertEquals(WindowsLanguage.Name);

        UserPersonalizationList.Close();

        // [THEN] The new "Locale ID" value is stored in the "User Personalization" table after that the page is closed
        UserPersonalization.FindFirst(); // reload values in the table because they have been changed in the page
        Assert.AreEqual(LocaleID, UserPersonalization."Locale ID", 'The UserPersonalization."Locale ID" should be equal to 1040');
    end;

    local procedure Initialize()
    var
        User: Record User;
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
        with UserPersonalization do begin
            SetRange("User SID", UserSID);
            if not FindFirst() then begin
                Reset();
                Init();
                "User SID" := UserSID;
                Insert();
            end else begin
                Clear("Profile ID");
                Clear("App ID");
                Clear(Scope);
                Modify();
            end;
        end;
    end;

    local procedure CreateProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        ProfileCard: TestPage "Profile Card";
    begin
        // Ensure it doesn't already exist
        DeleteProfile(AllObjWithCaption);

        ProfileCard.OpenNew;
        ProfileCard.ProfileIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.DescriptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.CaptionField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.RoleCenterIdField.SetValue(AllObjWithCaption."Object ID");
        ProfileCard.OK.Invoke;
    end;


    local procedure CreateProfileID(): Code[30]
    var
        ProfileCard: TestPage "Profile Card";
        ProfileID: Code[30];
    begin
        ProfileCard.OpenNew;
        ProfileCard.ProfileIdField.SetValue(LibraryUtility.GenerateGUID);
        ProfileCard.DescriptionField.SetValue(LibraryUtility.GenerateGUID);
        ProfileCard.CaptionField.SetValue(LibraryUtility.GenerateGUID);
        ProfileID := ProfileCard.ProfileIdField.Value;
        ProfileCard.OK.Invoke;
        exit(ProfileID);
    end;

    local procedure CreateUserPersonalization(var UserPersonalization: Record "User Personalization"; UserSID: Guid; ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetFilter(Enabled, Format(true));
        AllProfile.FindFirst();

        UserPersonalization.Init();
        UserPersonalization.Validate("User SID", UserSID);
        UserPersonalization.Validate("App ID", AllProfile."App ID");
        UserPersonalization.Validate(Scope, AllProfile.Scope);
        UserPersonalization.Validate("Profile ID", ProfileID);
        UserPersonalization.Validate(Company, CompanyName());
        UserPersonalization.Validate("Language ID", 1033); // English US
        UserPersonalization.Validate("Locale ID", 1033); // English US
        UserPersonalization.Insert(true);
    end;

    local procedure DeleteProfile(AllObjWithCaption: Record AllObjWithCaption)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetFilter("Profile ID", Format(AllObjWithCaption."Object ID"));
        if AllProfile.FindFirst then
            AllProfile.Delete(true);
    end;

    local procedure DeleteUser(UserName: Code[50])
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete(true);
            User.Delete(true);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditLanguageIDHandler(var WindowsLanguages: TestPage "Windows Languages")
    var
        WindowsLanguagesTable: Record "Windows Language";
    begin
        WindowsLanguagesTable.Get(1040); // Italian
        WindowsLanguages.GotoRecord(WindowsLanguagesTable);
        WindowsLanguages.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditProfileIDHandler(var AvailableRoles: TestPage "Available Roles")
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Role Center ID", RoleCenterID);
        AllProfile.FindFirst;
        AvailableRoles.GotoRecord(AllProfile);
        AvailableRoles.OK.Invoke;
    end;
}
