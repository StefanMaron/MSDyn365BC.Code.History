codeunit 138917 "O365 Language Settings Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Language] [UI]
    end;

    var
        Assert: Codeunit Assert;
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CorrectLanguageLoaded()
    var
        O365LanguageSettings: TestPage "O365 Language Settings";
    begin
        SetLanguageInUserPersonalization(1082);

        O365LanguageSettings.OpenView;
        Assert.AreEqual('Maltese (Malta)',
          O365LanguageSettings.Language.Value,
          'Language Settings did not load correct language from User Personalization.');
        O365LanguageSettings.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleSelectAvailableLanguages,HandleReSignInMessage')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyLanguage()
    var
        WindowsLanguage: Record "Windows Language";
        O365LanguageSettings: TestPage "O365 Language Settings";
    begin
        SetLanguageInUserPersonalization(1082);
        WindowsLanguage.Get(GlobalLanguage);

        O365LanguageSettings.OpenEdit;
        O365LanguageSettings.Language.AssistEdit;
        Assert.AreEqual(WindowsLanguage.Name,
          O365LanguageSettings.Language.Value,
          'The Language field should change after selecting in the Lookup.');
        O365LanguageSettings.Close;
        Assert.AreEqual(WindowsLanguage.Name,
          GetLanguageFromUserPersonalization,
          'The user''s Language should be updated in the User Personalization table after closing Language settings.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,HandleSelectAvailableLanguages,HandleReSignInMessage,HandleModalMySettings')]
    [Scope('OnPrem')]
    procedure ModifyLanguageInMySettingsForInvoicing()
    var
        WindowsLanguage: Record "Windows Language";
        SystemActionTriggers: Codeunit "System Action Triggers";
        BCO365MySettings: TestPage "BC O365 My Settings";
    begin
        // [GIVEN] An Invoicing app user with a nondefault language
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        SetLanguageInUserPersonalization(1082);

        // [WHEN] The user opens settings from the My Settings label in Business Central
        LibraryVariableStorage.Enqueue('Maltese (Malta)');
        SystemActionTriggers.OpenSettings;

        // [THEN] The language displayed in settings is correct
        // Verified in handler

        // [WHEN] The user changes the language (set to GLOBALLANGUAGE by the modalpagehandler)
        BCO365MySettings.OpenEdit;
        BCO365MySettings.Control30.Language.AssistEdit;
        WindowsLanguage.Get(GlobalLanguage);

        // [THEN] The language is correctly updated in the page and in the user personalization
        Assert.AreEqual(WindowsLanguage.Name,
          BCO365MySettings.Control30.Language.Value,
          'Unexpected language shown in settings.');
        Assert.AreEqual(WindowsLanguage.Name,
          GetLanguageFromUserPersonalization,
          'The user''s Language should be updated in the User Personalization table after closing Language settings.');
        BCO365MySettings.Close;

        // [THEN] The language is correctly updated even when reopening the page
        LibraryVariableStorage.Enqueue(WindowsLanguage.Name);
        SystemActionTriggers.OpenSettings;
        // Verified in handler for the page

        EventSubscriberInvoicingApp.Clear();
        UnbindSubscription(EventSubscriberInvoicingApp);
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleReSignInMessage(Message: Text)
    begin
        Assert.AreEqual(Message, 'You must sign out and then sign in again for the change to take effect.', 'Unexpected message.');
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

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleModalMySettings(var BCO365MySettings: TestPage "BC O365 My Settings")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText,
          BCO365MySettings.Control30.Language.Value,
          'Unexpected language shown in settings.');
    end;
}

