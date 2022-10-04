#if not CLEAN20
codeunit 2850 "Native API - Language Handler"
{
    EventSubscriberInstance = Manual;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    var
        ClashWhileSettingTheLanguageTxt: Label 'Clash while setting the language. Something else is trying to change language at the same time.', Locked = true;
        LanguageFound: Boolean;
        CachedLanguageCode: Code[10];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Language", 'OnGetUserLanguageCode', '', false, false)]
    local procedure InvoicingAPIGetUserLanguageHandler(var UserLanguageCode: Code[10]; var Handled: Boolean)
    begin
        // Breaking handled pattern here - API subscriber must win, log a clash
        if Handled then
            Session.LogMessage('00001LJ', ClashWhileSettingTheLanguageTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'NativeInvoicingLanguageHanlder');

        // Performance optimization - Calling GetUserSelectedLanguageId is creating 1-2 SQL queries each time
        if not LanguageFound then begin
            CachedLanguageCode := GetUserSelectedLanguageCode();
            LanguageFound := true;
        end;

        UserLanguageCode := CachedLanguageCode;
        Handled := true;
    end;

    local procedure GetUserSelectedLanguageCode(): Code[10]
    var
        UserPersonalization: Record "User Personalization";
        Language: Codeunit Language;
        LanguageId: Integer;
    begin
        // <summary>
        // Gets the code of the language that the user has selected via personalization.
        // </summary>
        // <returns>The code of the selected language. If no language was selected, then it returns the code of the current user's language.</returns>

        UserPersonalization.SetRange("User ID", UserId);
        if not UserPersonalization.FindFirst() then begin
            UserPersonalization.SetRange("User ID", '');
            if not UserPersonalization.FindFirst() then;
        end;

        LanguageId := UserPersonalization."Language ID";
        if LanguageId = 0 then
            LanguageId := GlobalLanguage;

        exit(Language.GetLanguageCode(LanguageId));
    end;
}
#endif
