codeunit 9520 "Mail Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        if not IsEnabled() then
            Error(MailingNotSupportedErr);
        if not DoSend() then
            Error(MailWasNotSendErr);
    end;

    var
        TempEmailModuleAccount: Record "Email Account" temporary;
        TempEmailItem: Record "Email Item" temporary;
        GraphMail: Codeunit "Graph Mail";
        SMTPMail: Codeunit "SMTP Mail";
        EmailFeature: Codeunit "Email Feature";
        ClientTypeManagement: Codeunit "Client Type Management";
        InvalidEmailAddressErr: Label 'The email address "%1" is not valid.', Comment = '%1 - Recipient email address';
        DoEdit: Boolean;
        HideMailDialog: Boolean;
        Cancelled: Boolean;
        MailSent: Boolean;
        MailingNotSupportedErr: Label 'The required email is not supported.';
        MailWasNotSendErr: Label 'The email was not sent.';
        FromAddressWasNotFoundErr: Label 'An email from address was not found. Contact an administrator.';
        SaveFileDialogTitleMsg: Label 'Save PDF file';
        SaveFileDialogFilterMsg: Label 'PDF Files (*.pdf)|*.pdf';
        OutlookSupported: Boolean;
        SMTPSupported: Boolean;
        CannotSendMailThenDownloadQst: Label 'Do you want to download the attachment?';
        CannotSendMailThenDownloadErr: Label 'You cannot send the email.\Verify that the email settings are correct.';
        GraphSupported: Boolean;
        HideEmailSendingError: Boolean;
        SMTPSetupTxt: Label 'SmtpSetup', Locked = true;
        NoScenarioDefinedErr: Label 'No email account defined for the scenario ''%1''. Please, register an account on the ''Email Accounts'' page and assign scenario ''%1'' to it on the ''Email Scenario Setup'' page. Mark one of the accounts as the default account to use it for all scenarios that are not explicitly defined.', Comment = '%1 - The email scenario, for example, Sales Invoice';
        NoDefaultScenarioDefinedErr: Label 'The default account is not selected. Please, register an account on the ''Email Accounts'' page and mark it as the default account on the ''Email Scenario Setup'' page.';
        EmailScenarioMsg: Label 'Sending email using scenario: %1.', Comment = '%1 - Email scenario (e. g. sales order)', Locked = true;
        EmailManagementCategoryTxt: Label 'EmailManagement', Locked = true;
        CurrentEmailScenario: Enum "Email Scenario";

    local procedure RunMailDialog(): Boolean
    var
        EmailDialog: Page "Email Dialog";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunMailDialog(TempEmailItem, OutlookSupported, SMTPSupported, ReturnValue, IsHandled, DoEdit, Cancelled);
        if IsHandled then
            exit(ReturnValue);

        EmailDialog.SetValues(TempEmailItem, OutlookSupported, SMTPSupported);

        if not (EmailDialog.RunModal() = ACTION::OK) then begin
            Cancelled := true;
            exit(false);
        end;
        EmailDialog.GetRecord(TempEmailItem);
        DoEdit := EmailDialog.GetDoEdit();
        exit(true);
    end;

    local procedure SendViaEmailModule(): Boolean
    var
        Email: Codeunit Email;
        Message: Codeunit "Email Message";
        ErrorMessageManagement: Codeunit "Error Message Management";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachmentNames: List of [Text];
        AttachmentStream: Instream;
        Index: Integer;
        ToList: List of [Text];
        CcList: List of [Text];
        BccList: List of [Text];
    begin
        RecipientStringToList(TempEmailItem."Send to", ToList);
        RecipientStringToList(TempEmailItem."Send CC", CcList);
        RecipientStringToList(TempEmailItem."Send BCC", BccList);

        Message.Create(ToList, TempEmailItem.Subject, TempEmailItem.GetBodyText(), true, CcList, BccList);

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        for Index := 1 to Attachments.Count() do begin
            Attachments.Get(Index, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            Message.AddAttachment(CopyStr(AttachmentNames.Get(Index), 1, 250), '', AttachmentStream);
        end;

        Session.LogMessage('0000CTW', StrSubstNo(EmailScenarioMsg, Format(CurrentEmailScenario)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailManagementCategoryTxt, 'EmailMessageID', Message.GetId());

        ClearLastError();
        Cancelled := false;
        if not HideMailDialog then begin
            Commit();
            MailSent := Email.OpenInEditorModally(Message, TempEmailModuleAccount) = Enum::"Email Action"::Sent;
            Cancelled := not MailSent;
        end else
            MailSent := Email.Send(Message, TempEmailModuleAccount);

        if not MailSent and not Cancelled and not HideEmailSendingError then
            ErrorMessageManagement.LogSimpleErrorMessage(GetLastErrorText());

        exit(MailSent);
    end;

    internal procedure RecipientStringToList(DelimitedRecipients: Text; var Recipients: List of [Text])
    var
        Seperators: Text;
    begin
        if DelimitedRecipients = '' then
            exit;

        Seperators := '; ,';
        Recipients := DelimitedRecipients.Split(Seperators.Split());
    end;

    local procedure SendViaSMTP(): Boolean
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachmentNames: List of [Text];
        AttachmentStream: Instream;
        Index: Integer;
        HtmlFormated: Boolean;
        SendToList: List of [Text];
        SendToCcList: List of [Text];
        SendToBccList: List of [Text];
        Seperators: Text;
    begin
        Seperators := '; ,';
        SendToList := TempEmailItem."Send to".Split(Seperators.Split());

        IF TempEmailItem."Message Type" = TempEmailItem."Message Type"::"From Email Body Template" THEN
            HtmlFormated := true;

        if SMTPMail.CreateMessage(TempEmailItem."From Name", TempEmailItem."From Address", SendToList, TempEmailItem.Subject, TempEmailItem.GetBodyText(), HtmlFormated) then begin
            OnSendViaSMTPOnBeforeSMTPMailAddAttachment(TempEmailItem, SMTPMail);
            
            TempEmailItem.GetAttachments(Attachments, AttachmentNames);
            for Index := 1 to Attachments.Count() do begin
                Attachments.Get(Index, Attachment);
                Attachment.CreateInStream(AttachmentStream);
                SMTPMail.AddAttachmentStream(AttachmentStream, AttachmentNames.Get(Index));
            end;

            if TempEmailItem."Send CC" <> '' then begin
                SendToCcList := TempEmailItem."Send CC".Split(Seperators.Split());
                SMTPMail.AddCC(SendToCcList);
            end;
            if TempEmailItem."Send BCC" <> '' then begin
                SendToBccList := TempEmailItem."Send BCC".Split(Seperators.Split());
                SMTPMail.AddBCC(SendToBccList);
            end;
        end;

        OnBeforeSentViaSMTP(TempEmailItem, SMTPMail);
        MailSent := SMTPMail.Send();
        OnAfterSentViaSMTP(TempEmailItem, SMTPMail, MailSent, HideEmailSendingError);
        if not MailSent and not HideEmailSendingError then
            ErrorMessageManagement.LogSimpleErrorMessage(SMTPMail.GetLastSendMailErrorText());
        exit(MailSent);
    end;

    local procedure SendViaGraph(): Boolean
    begin
        MailSent := GraphMail.SendMail(TempEmailItem);

        if not MailSent and not HideEmailSendingError then
            Error(GraphMail.GetGraphError());

        exit(MailSent);
    end;

    procedure GetLastGraphError(): Text
    begin
        exit(GraphMail.GetGraphError());
    end;

    procedure InitializeFrom(NewHideMailDialog: Boolean; NewHideEmailSendingError: Boolean)
    begin
        SetHideMailDialog(NewHideMailDialog);
        SetHideEmailSendingError(NewHideEmailSendingError);
    end;

    procedure SetHideMailDialog(NewHideMailDialog: Boolean)
    begin
        HideMailDialog := NewHideMailDialog;
    end;

    [Obsolete('Replaced with the SetHideEmailSendingError function', '17.0')]
    procedure SetHideSMTPError(NewHideSMTPError: Boolean)
    begin
        SetHideEmailSendingError(NewHideSMTPError);
    end;

    procedure SetHideEmailSendingError(NewHideEmailSendingError: Boolean)
    begin
        HideEmailSendingError := NewHideEmailSendingError;
    end;

    procedure CheckValidEmailAddresses(Recipients: Text)
    var
        TmpRecipients: Text;
        IsHandled: Boolean;
    begin
        // this event is obsolete
        IsHandled := false;
        OnBeforeCheckValidEmailAddress(Recipients, IsHandled);
        if IsHandled then
            exit;

        // please use this event
        IsHandled := false;
        OnBeforeCheckValidEmailAddresses(Recipients, IsHandled);
        if IsHandled then
            exit;

        if Recipients = '' then
            Error(InvalidEmailAddressErr, Recipients);

        TmpRecipients := DelChr(Recipients, '<>', ';');
        while StrPos(TmpRecipients, ';') > 1 do begin
            CheckValidEmailAddress(CopyStr(TmpRecipients, 1, StrPos(TmpRecipients, ';') - 1));
            TmpRecipients := CopyStr(TmpRecipients, StrPos(TmpRecipients, ';') + 1);
        end;
        CheckValidEmailAddress(TmpRecipients);
    end;

    [TryFunction]
    procedure CheckValidEmailAddress(EmailAddress: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckValidEmailAddr(EmailAddress, IsHandled);
        if IsHandled then
            exit;

        EmailAddress := DelChr(EmailAddress, '<>');

        if EmailAddress.StartsWith('@') or EmailAddress.EndsWith('@') then
            Error(InvalidEmailAddressErr, EmailAddress);

        if EmailAddress.Contains(' ') then
            Error(InvalidEmailAddressErr, EmailAddress);

        if EmailAddress.Split('@').Count() <> 2 then
            Error(InvalidEmailAddressErr, EmailAddress);
    end;

    [TryFunction]
    procedure ValidateEmailAddressField(var EmailAddress: Text)
    begin
        EmailAddress := DelChr(EmailAddress, '<>');

        if EmailAddress = '' then
            exit;

        CheckValidEmailAddress(EmailAddress);
    end;

    [Obsolete('Replaced with the IsAnyAccountRegistered in "Email Account" codeunit from "System Application".', '17.0')]
    procedure IsSMTPEnabled(): Boolean
    begin
        exit(SMTPMail.IsEnabled());
    end;

    [Scope('OnPrem')]
    procedure IsGraphEnabled(): Boolean
    begin
        if GraphMail.IsEnabled() then
            exit(GraphMail.HasConfiguration());
        exit(false);
    end;

    procedure IsEnabled(): Boolean
    var
        EmailAccount: Codeunit "Email Account";
    begin
        if EmailFeature.IsEnabled() then
            exit(EmailAccount.IsAnyAccountRegistered());

        OutlookSupported := false;

        SMTPSupported := IsSMTPEnabled();
        GraphSupported := IsGraphEnabled();

        if ClientTypeManagement.GetCurrentClientType() <> Clienttype::Windows then
            exit(SMTPSupported or GraphSupported);

        // Assume Outlook is supported - a false check takes long time.
        OutlookSupported := true;
        exit(true);
    end;

    procedure IsCancelled(): Boolean
    begin
        exit(Cancelled);
    end;

    procedure IsSent(): Boolean
    begin
        exit(MailSent);
    end;

    // Email Item needs to be passed by var so the attachments are available
    procedure Send(var ParmEmailItem: Record "Email Item"; EmailScenario: Enum "Email Scenario"): Boolean
    var
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
    begin
        ParmEmailItem.GetAttachments(Attachments, AttachmentNames);
        TempEmailItem := ParmEmailItem;
        TempEmailItem.SetAttachments(Attachments, AttachmentNames);
        QualifyFromAddress(EmailScenario);
        CurrentEmailScenario := EmailScenario;
        MailSent := false;
        exit(DoSend());
    end;

    [Obsolete('Replaced with the overload containing Email Scenario', '17.0')]
    procedure Send(ParmEmailItem: Record "Email Item"): Boolean
    begin
        Send(ParmEmailItem, Enum::"Email Scenario"::Default);
    end;

    local procedure DoSend(): Boolean
    begin
        if not CanSend() then
            exit(true);

        if EmailFeature.IsEnabled() then begin
            SendViaEmailModule();
            if Cancelled then
                exit(true);
            exit(IsSent());
        end;

        if not HideMailDialog then begin
            Cancelled := not RunMailDialog();
            if Cancelled then
                exit(true);
        end;

        if GraphSupported then
            exit(SendViaGraph());

        if SMTPSupported then
            exit(SendViaSMTP());

        exit(false);
    end;

    local procedure QualifyFromAddress(EmailScenario: Enum "Email Scenario")
    var
        TempPossibleEmailNameValueBuffer: Record "Name/Value Buffer" temporary;
        EmailScenarios: Codeunit "Email Scenario";
        MailForEmails: Codeunit Mail;
    begin
        OnBeforeQualifyFromAddress(TempEmailItem);

        if EmailFeature.IsEnabled() then begin
            // In case the email feature is enabled, try get the email account to use by the provided scenario
            if not EmailScenarios.GetEmailAccount(EmailScenario, TempEmailModuleAccount) then
                if EmailScenario = Enum::"Email Scenario"::Default then
                    Error(NoDefaultScenarioDefinedErr)
                else
                    Error(NoScenarioDefinedErr, EmailScenario);
            exit;
        end;

        if TempEmailItem."From Address" <> '' then
            exit;

        MailForEmails.CollectCurrentUserEmailAddresses(TempPossibleEmailNameValueBuffer);

        if GraphSupported then
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'GraphSetup') then
                exit;

        if SMTPSupported then begin
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'SMTPSetup') then
                exit;
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'UserSetup') then
                exit;
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'ContactEmail') then
                exit;
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'AuthEmail') then
                exit;
            if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, 'AD') then
                exit;
        end;

        if TempPossibleEmailNameValueBuffer.IsEmpty() then begin
            if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop] then
                Error(FromAddressWasNotFoundErr);
            TempEmailItem."From Address" := '';
            exit;
        end;

        if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, '') then
            exit;
    end;

    [Obsolete('From address is decided by the email scenario when using the email feature is enabled.', '17.0')]
    local procedure AssignFromAddressIfExist(var TempPossibleEmailNameValueBuffer: Record "Name/Value Buffer" temporary; FilteredName: Text): Boolean
    begin
        if FilteredName <> '' then
            TempPossibleEmailNameValueBuffer.SetFilter(Name, FilteredName);

        if not TempPossibleEmailNameValueBuffer.IsEmpty() then begin
            TempPossibleEmailNameValueBuffer.FindFirst();

            if TempPossibleEmailNameValueBuffer.Value <> '' then begin
                TempEmailItem."From Address" := TempPossibleEmailNameValueBuffer.Value;
                exit(true);
            end;
        end;

        TempPossibleEmailNameValueBuffer.Reset();
        exit(false);
    end;

    // Email Item needs to be passed by var so the attachments are available
    [Scope('OnPrem')]
    procedure SendMailOrDownload(var TempEmailItem: Record "Email Item" temporary; HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario")
    var
        MailManagement: Codeunit "Mail Management";
        OfficeMgt: Codeunit "Office Management";
    begin
        MailManagement.InitializeFrom(HideMailDialog, not IsBackground());
        if MailManagement.IsEnabled() then
            if MailManagement.Send(TempEmailItem, EmailScenario) then begin
                MailSent := MailManagement.IsSent();
                exit;
            end;

        if IsBackground() then
            exit;

        if not GuiAllowed or (OfficeMgt.IsAvailable() and not OfficeMgt.IsPopOut()) then
            Error(CannotSendMailThenDownloadErr);

        if not Confirm(StrSubstNo('%1\\%2', CannotSendMailThenDownloadErr, CannotSendMailThenDownloadQst)) then
            exit;

        DownloadPdfAttachment(TempEmailItem);

        OnAfterSendMailOrDownload(TempEmailItem, MailSent);
    end;

    [Obsolete('Replaced with the overload containing Email Scenario', '17.0')]
    [Scope('OnPrem')]
    procedure SendMailOrDownload(TempEmailItem: Record "Email Item" temporary; HideMailDialog: Boolean)
    begin
        SendMailOrDownload(TempEmailItem, HideMailDialog, Enum::"Email Scenario"::Default);
    end;

    procedure DownloadPdfAttachment(var TempEmailItem: Record "Email Item" temporary)
    var
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachmentNames: List of [Text];
        AttachemntName: Text;
        AttachmentStream: Instream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadPdfAttachment(TempEmailItem, IsHandled);
        if IsHandled then
            exit;

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        if Attachments.Count() > 0 then begin
            AttachemntName := AttachmentNames.Get(1);
            Attachments.Get(1, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            DownloadFromStream(AttachmentStream, SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, AttachemntName);
        end;
    end;

    [Scope('OnPrem')]
    procedure ImageBase64ToUrl(BodyText: Text): Text
    var
        Regex: DotNet Regex;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
        SearchText: Text;
        Base64: Text;
        MimeType: Text;
        MediaId: Guid;
    begin
        SearchText := '(.*<img src=\")data:image\/([a-z]+);base64,([a-zA-Z0-9\/+=]+)(\".*)';
        Regex := Regex.Regex(SearchText);
        while Regex.IsMatch(BodyText) do begin
            Base64 := Regex.Replace(BodyText, '$3', 1);
            MimeType := Regex.Replace(BodyText, '$2', 1);
            MemoryStream := MemoryStream.MemoryStream(Convert.FromBase64String(Base64));
            // 20160 =  14days * 24/hours/day * 60min/hour
            MediaId := ImportStreamWithUrlAccess(MemoryStream, Format(CreateGuid) + MimeType, 20160);

            BodyText := Regex.Replace(BodyText, '$1' + GetDocumentUrl(MediaId) + '$4', 1);
        end;
        exit(BodyText);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryGetSenderEmailAddress(var FromAddress: Text[250])
    begin
        FromAddress := GetSenderEmailAddress();
    end;

    [Obsolete('Sender will be chosen based on the scenario parameter to the Send function when using the email feature is enabled. To control which account will be used, use the overload containing Email Scenario.', '17.0')]
    procedure GetSenderEmailAddress(): Text[250]
    begin
        exit(GetSenderEmailAddress(Enum::"Email Scenario"::Default));
    end;

    procedure GetSenderEmailAddress(EmailScenario: Enum "Email Scenario"): Text[250]
    begin
        if not IsEnabled() then
            exit('');
        QualifyFromAddress(EmailScenario);

        OnAfterGetSenderEmailAddress(TempEmailItem);
        if EmailFeature.IsEnabled() then
            exit(TempEmailModuleAccount."Email Address")
        else
            exit(TempEmailItem."From Address");
    end;

    local procedure CanSend(): Boolean
    var
        CancelSending: Boolean;
    begin
        OnBeforeDoSending(CancelSending);
        exit(not CancelSending);
    end;

    local procedure IsBackground(): Boolean
    begin
        exit(ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Background]);
    end;

    [Obsolete('Not needed once email feature is enabled.', '17.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetSMTPCredentials(var SMTPMailSetup: Record "SMTP Mail Setup")
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SMTPSettingsList: JsonArray;
        SMTPSettings: JsonObject;
        RandomIndex: Integer;
        JToken: JsonToken;
        SMTPServerParameters: Text;
        VaultAuthentication: Text;
        VaultUserID: Text[250];
        VaultSMTPServerPort: Text;
        VaultSecureConnection: Text;
        VaultPasswordKey: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SMTPSetupTxt, SMTPServerParameters) then
            exit;

        if not SMTPSettingsList.ReadFrom(SMTPServerParameters) then
            exit;

        if SMTPSettingsList.Count() = 0 then
            exit;

        RandomIndex := Random(SMTPSettingsList.Count()) - 1;

        if not SMTPSettingsList.Get(RandomIndex, JToken) then
            exit;

        if not JToken.IsObject() then
            exit;

        SMTPSettings := JToken.AsObject();

        GetAsText(SMTPSettings, 'Server', SMTPMailSetup."SMTP Server");
        GetAsText(SMTPSettings, 'ServerPort', VaultSMTPServerPort);
        if VaultSMTPServerPort <> '' then
            Evaluate(SMTPMailSetup."SMTP Server Port", VaultSMTPServerPort);

        GetAsText(SMTPSettings, 'Authentication', VaultAuthentication);
        if VaultAuthentication <> '' then
            Evaluate(SMTPMailSetup.Authentication, VaultAuthentication);

        GetAsText(SMTPSettings, 'User', VaultUserID);
        SMTPMailSetup.Validate("User ID", VaultUserID);

        GetAsText(SMTPSettings, 'Password', VaultPasswordKey);
        SMTPMailSetup.SetPassword(VaultPasswordKey);

        GetAsText(SMTPSettings, 'SecureConnection', VaultSecureConnection);
        if VaultSecureConnection <> '' then
            Evaluate(SMTPMailSetup."Secure Connection", VaultSecureConnection);
    end;

    [NonDebuggable]
    local procedure GetAsText(JObject: JsonObject; PropertyKey: Text; var Result: Text): Boolean
    var
        JToken: JsonToken;
        JValue: JsonValue;
    begin
        if not JObject.Get(PropertyKey, JToken) then
            exit(false);

        if not JToken.IsValue() then
            exit(false);

        JValue := JToken.AsValue();
        if JValue.IsUndefined() or JValue.IsNull() then
            exit(false);

        Result := JValue.AsText();
        exit(true);
    end;

    local procedure FilterEventSubscription(var EventSubscription: Record "Event Subscription"; FunctionNameFilter: Text)
    begin
        EventSubscription.SetRange("Subscriber Codeunit ID", CODEUNIT::"Mail Management");
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", DATABASE::"Report Selections");
        EventSubscription.SetFilter("Published Function", '%1', FunctionNameFilter);
        EventSubscription.SetFilter("Active Manual Instances", '>%1', 0);
    end;

    procedure IsHandlingGetEmailBody(): Boolean
    begin
        if IsHandlingGetEmailBodyCustomer then
            exit(true);

        exit(IsHandlingGetEmailBodyVendor);
    end;

    procedure IsHandlingGetEmailBodyCustomer(): Boolean
    var
        EventSubscription: Record "Event Subscription";
        Result: Boolean;
    begin
        FilterEventSubscription(EventSubscription, 'OnAfterGetEmailBodyCustomer');
        Result := not EventSubscription.IsEmpty();
        exit(Result);
    end;

    procedure IsHandlingGetEmailBodyVendor(): Boolean
    var
        EventSubscription: Record "Event Subscription";
        Result: Boolean;
    begin
        FilterEventSubscription(EventSubscription, 'OnAfterGetEmailBodyVendor');
        Result := not EventSubscription.IsEmpty();
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, 77, 'OnAfterGetEmailBodyCustomer', '', false, false)]
    local procedure HandleOnAfterGetEmailBodyCustomer(CustomerEmailAddress: Text[250]; ServerEmailBodyFilePath: Text[250])
    begin
    end;

    [EventSubscriber(ObjectType::Table, 77, 'OnAfterGetEmailBodyVendor', '', false, false)]
    local procedure HandleOnAfterGetEmailBodyVendor(VendorEmailAddress: Text[250]; ServerEmailBodyFilePath: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSentViaSMTP(var TempEmailItem: Record "Email Item" temporary; var SMTPMail: Codeunit "SMTP Mail"; var MailSent: Boolean; HideSMTPError: Boolean)
    begin
    end;

    [Obsolete('Replaced by event OnBeforeCheckValidEmailAddresses', '15.3')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidEmailAddress(Recipients: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidEmailAddresses(Recipients: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidEmailAddr(EmailAddress: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoSending(var CancelSending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadPdfAttachment(var TempEmailItem: Record "Email Item" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQualifyFromAddress(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunMailDialog(var TempEmailItem: Record "Email Item"; OutlookSupported: Boolean; SMTPSupported: Boolean; var ReturnValue: Boolean; var IsHandled: Boolean; var DoEdit: Boolean; var Cancelled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSentViaSMTP(var TempEmailItem: Record "Email Item" temporary; var SMTPMail: Codeunit "SMTP Mail")
    begin
    end;

    #pragma warning disable AA0228
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendMailOnWinClient(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteTempAttachments(var EmailItem: Record "Email Item")
    begin
    end;
    #pragma warning restore AA0228

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSenderEmailAddress(var EmailItem: Record "Email Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendMailOrDownload(var TempEmailItem: Record "Email Item" temporary; var MailSent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendViaSMTPOnBeforeSMTPMailAddAttachment(var TempEmailItem: Record "Email Item" temporary; var SMTPMail: Codeunit "SMTP Mail")
    begin
    end;
}
