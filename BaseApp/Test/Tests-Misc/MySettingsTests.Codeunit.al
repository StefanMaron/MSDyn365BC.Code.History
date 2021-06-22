codeunit 132905 MySettingsTests
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My Settings] [UI]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CorrectLanguageLoaded()
    var
        MySettingsPage: TestPage "My Settings";
    begin
        SetLanguageInUserPersonalization(1082);

        MySettingsPage.OpenView;
        Assert.AreEqual('Maltese (Malta)',
          MySettingsPage.Language.Value,
          'My Settings did not load correct language from User Personalization.');
        MySettingsPage.Close;
    end;

    [Test]
    [HandlerFunctions('HandleSelectAvailableLanguages,StandardSessionSettingsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyLanguageOK()
    var
        WindowsLanguage: Record "Windows Language";
        MySettingsPage: TestPage "My Settings";
    begin
        SetLanguageInUserPersonalization(1082);
        WindowsLanguage.Get(GlobalLanguage);

        MySettingsPage.OpenEdit;
        MySettingsPage.Language.AssistEdit;
        Assert.AreEqual(WindowsLanguage.Name,
          MySettingsPage.Language.Value,
          'The Language field should change after selecting in the Lookup.');
        MySettingsPage.OK.Invoke;
        Assert.AreEqual(WindowsLanguage.Name,
          GetLanguageFromUserPersonalization,
          'The user''s Language should be updated in the User Personalization table after closing My Settings.');
    end;

    [Test]
    [HandlerFunctions('HandleCancelAvailableLanguages')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyLanguageCancel()
    var
        MySettingsPage: TestPage "My Settings";
    begin
        SetLanguageInUserPersonalization(1082);

        MySettingsPage.OpenEdit;
        MySettingsPage.Language.AssistEdit;
        Assert.AreEqual('Maltese (Malta)',
          MySettingsPage.Language.Value,
          'Canceling the lookup should not modify the user''s language.');
        MySettingsPage.Close;
        Assert.AreEqual('Maltese (Malta)',
          GetLanguageFromUserPersonalization,
          'Closing My Settings should not modify user''s language.');
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleCancelAvailableLanguages(var WindowsLanguages: Page "Windows Languages"; var Response: Action)
    begin
        Response := ACTION::LookupCancel;
    end;

    local procedure GetLanguageFromUserPersonalization(): Text
    var
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
    begin
        UserPersonalization.Get(UserSecurityId);
        WindowsLanguage.Get(UserPersonalization."Language ID");
        exit(WindowsLanguage.Name);
    end;

    local procedure SetLanguageInUserPersonalization(ID: Integer)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId);
        UserPersonalization."Language ID" := ID;
        UserPersonalization.Modify();
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure StandardSessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;
}

