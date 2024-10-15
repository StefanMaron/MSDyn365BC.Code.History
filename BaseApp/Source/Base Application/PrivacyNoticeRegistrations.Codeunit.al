codeunit 1357 "Privacy Notice Registrations"
{
    var
        MicrosoftOneDriveTxt: Label 'Microsoft OneDrive', Locked = true; // Product names are not translated and it's important this entry exists.
        MicrosoftExchangeTxt: Label 'Microsoft Exchange', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", 'OnRegisterPrivacyNotices', '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := MicrosoftOneDriveTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftOneDriveTxt;
        if not TempPrivacyNotice.Insert() then;

        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := MicrosoftExchangeTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftExchangeTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    procedure GetOneDrivePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftOneDriveTxt);
    end;

    procedure GetExchangePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftExchangeTxt);
    end;
}
