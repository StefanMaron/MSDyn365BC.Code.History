/// <summary>
/// This test verifies the LOGIN permission set can be used to log in and change language and company with BaseApp installed.
/// </summary>

codeunit 132913 "Login Permissions Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [HandlerFunctions('HandleSelectAvailableLanguages,StandardSessionSettingsHandler')]
    procedure ModifyLanguageWithLoginPermissionsOK()
    var
        WindowsLanguage: Record "Windows Language";
        UserSettingsPage: TestPage "User Settings";
    begin
        SetLanguageInUserPersonalization(1082);
        WindowsLanguage.Get(GlobalLanguage);
        Assert.IsTrue(LibraryLowerPermissions.CanLowerPermission(), 'The current user should have the ability to lower permissions.');

        LibraryLowerPermissions.SetExactPermissionSet('LOGIN');
        LibraryLowerPermissions.AddPermissionSet('Login Test - Execute');
        UserSettingsPage.OpenEdit();
        UserSettingsPage.LanguageName.AssistEdit();
        Assert.AreEqual(WindowsLanguage.Name,
          UserSettingsPage.LanguageName.Value(),
          'The Language field should change after selecting in the Lookup.');
        UserSettingsPage.OK().Invoke();
        Assert.AreEqual(WindowsLanguage.Name,
          GetLanguageFromUserPersonalization(),
          'The user''s Language should be updated in the User Personalization table after closing My Settings.');
    end;

    local procedure GetLanguageFromUserPersonalization(): Text
    var
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
    begin
        UserPersonalization.Get(UserSecurityId());
        WindowsLanguage.Get(UserPersonalization."Language ID");
        exit(WindowsLanguage.Name);
    end;

    local procedure SetLanguageInUserPersonalization(ID: Integer)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization."Language ID" := ID;
        UserPersonalization.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSelectAvailableLanguages(var WindowsLanguages: Page "Windows Languages"; var Response: Action)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.Get(GlobalLanguage);
        WindowsLanguages.SetRecord(WindowsLanguage);
        Response := ACTION::LookupOK;
    end;

    [SessionSettingsHandler]
    procedure StandardSessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;

}

