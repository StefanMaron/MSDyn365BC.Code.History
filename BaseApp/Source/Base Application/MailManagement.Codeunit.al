codeunit 9520 "Mail Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        if not IsEnabled then
            Error(MailingNotSupportedErr);
        if not DoSend then
            Error(MailWasNotSendErr);
    end;

    var
        TempEmailItem: Record "Email Item" temporary;
        GraphMail: Codeunit "Graph Mail";
        SMTPMail: Codeunit "SMTP Mail";
        InvalidEmailAddressErr: Label 'The email address "%1" is not valid.';
        ClientTypeManagement: Codeunit "Client Type Management";
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
        OutlookNotAvailableContinueEditQst: Label 'Microsoft Outlook is not available.\\Do you want to continue to edit the email?';
        GraphSupported: Boolean;
        HideSMTPError: Boolean;
        EmailAttachmentTxt: Label 'Email.html', Locked = true;
        SMTPSetupTxt: Label 'SmtpSetup', Locked = true;

    local procedure RunMailDialog(): Boolean
    var
        EmailDialog: Page "Email Dialog";
    begin
        EmailDialog.SetValues(TempEmailItem, OutlookSupported, SMTPSupported);

        if not (EmailDialog.RunModal = ACTION::OK) then begin
            Cancelled := true;
            exit(false);
        end;
        EmailDialog.GetRecord(TempEmailItem);
        DoEdit := EmailDialog.GetDoEdit;
        exit(true);
    end;

    local procedure SendViaSMTP(): Boolean
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        SendToList: List of [Text];
        SendToCcList: List of [Text];
        SendToBccList: List of [Text];
    begin
        SendToList.Add(TempEmailItem."Send to");

        if SMTPMail.CreateMessage(TempEmailItem."From Name", TempEmailItem."From Address", SendToList, TempEmailItem.Subject, TempEmailItem.GetBodyText()) then begin
            SMTPMail.AddAttachment(TempEmailItem."Attachment File Path", TempEmailItem."Attachment Name");
            if TempEmailItem."Attachment File Path 2" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 2", TempEmailItem."Attachment Name 2");
            if TempEmailItem."Attachment File Path 3" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 3", TempEmailItem."Attachment Name 3");
            if TempEmailItem."Attachment File Path 4" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 4", TempEmailItem."Attachment Name 4");
            if TempEmailItem."Attachment File Path 5" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 5", TempEmailItem."Attachment Name 5");
            if TempEmailItem."Attachment File Path 6" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 6", TempEmailItem."Attachment Name 6");
            if TempEmailItem."Attachment File Path 7" <> '' then
                SMTPMail.AddAttachment(TempEmailItem."Attachment File Path 7", TempEmailItem."Attachment Name 7");

            if TempEmailItem."Send CC" <> '' then begin
                SendToCcList.Add(TempEmailItem."Send CC");
                SMTPMail.AddCC(SendToCcList);
            end;
            if TempEmailItem."Send BCC" <> '' then begin
                SendToBccList.Add(TempEmailItem."Send BCC");
                SMTPMail.AddBCC(SendToBccList);
            end;
        end;

        OnBeforeSentViaSMTP(TempEmailItem);
        MailSent := SMTPMail.Send;
        if not MailSent and not HideSMTPError then
            ErrorMessageManagement.LogSimpleErrorMessage(SMTPMail.GetLastSendMailErrorText);
        exit(MailSent);
    end;

    local procedure SendViaGraph(): Boolean
    begin
        MailSent := GraphMail.SendMail(TempEmailItem);

        if not MailSent and not HideSMTPError then
            Error(GraphMail.GetGraphError);

        exit(MailSent);
    end;

    procedure GetLastGraphError(): Text
    begin
        exit(GraphMail.GetGraphError);
    end;

    procedure InitializeFrom(NewHideMailDialog: Boolean; NewHideSMTPError: Boolean)
    begin
        SetHideMailDialog(NewHideMailDialog);
        SetHideSMTPError(NewHideSMTPError);
    end;

    procedure SetHideMailDialog(NewHideMailDialog: Boolean)
    begin
        HideMailDialog := NewHideMailDialog;
    end;

    procedure SetHideSMTPError(NewHideSMTPError: Boolean)
    begin
        HideSMTPError := NewHideSMTPError;
    end;

    local procedure SendMailOnWinClient(): Boolean
    var
        Mail: Codeunit Mail;
        FileManagement: Codeunit "File Management";
        ClientAttachmentFilePath: Text;
        ClientAttachmentFullName: Text;
    begin
        if Mail.TryInitializeOutlook then
            with TempEmailItem do begin
                if "Attachment File Path" <> '' then begin
                    ClientAttachmentFilePath := DownloadPdfOnClient("Attachment File Path");
                    ClientAttachmentFullName := FileManagement.MoveAndRenameClientFile(ClientAttachmentFilePath, "Attachment Name", '');
                end;
                OnBeforeSendMailOnWinClient(TempEmailItem);
                if Mail.NewMessageAsync("Send to", "Send CC", "Send BCC", Subject, GetBodyText, ClientAttachmentFullName, not HideMailDialog) then begin
                    FileManagement.DeleteClientFile(ClientAttachmentFullName);
                    MailSent := true;
                    exit(true)
                end;
            end;
        exit(false);
    end;

    local procedure DownloadPdfOnClient(ServerPdfFilePath: Text): Text
    var
        FileManagement: Codeunit "File Management";
        ClientPdfFilePath: Text;
    begin
        ClientPdfFilePath := FileManagement.DownloadTempFile(ServerPdfFilePath);
        Erase(ServerPdfFilePath);
        exit(ClientPdfFilePath);
    end;

    procedure CheckValidEmailAddresses(Recipients: Text)
    var
        TmpRecipients: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckValidEmailAddress(Recipients, IsHandled);
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
        i: Integer;
        NoOfAtSigns: Integer;
    begin
        EmailAddress := DelChr(EmailAddress, '<>');

        if EmailAddress = '' then
            Error(InvalidEmailAddressErr, EmailAddress);

        if (EmailAddress[1] = '@') or (EmailAddress[StrLen(EmailAddress)] = '@') then
            Error(InvalidEmailAddressErr, EmailAddress);

        for i := 1 to StrLen(EmailAddress) do begin
            if EmailAddress[i] = '@' then
                NoOfAtSigns := NoOfAtSigns + 1
            else
                if EmailAddress[i] = ' ' then
                    Error(InvalidEmailAddressErr, EmailAddress);
        end;

        if NoOfAtSigns <> 1 then
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

    procedure IsSMTPEnabled(): Boolean
    begin
        exit(SMTPMail.IsEnabled);
    end;

    [Scope('OnPrem')]
    procedure IsGraphEnabled(): Boolean
    begin
        exit(GraphMail.IsEnabled and GraphMail.HasConfiguration);
    end;

    procedure IsEnabled(): Boolean
    begin
        OutlookSupported := false;

        SMTPSupported := IsSMTPEnabled;
        GraphSupported := IsGraphEnabled;

        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Windows then
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

    procedure Send(ParmEmailItem: Record "Email Item"): Boolean
    begin
        TempEmailItem := ParmEmailItem;
        QualifyFromAddress;
        MailSent := false;
        exit(DoSend);
    end;

    local procedure DoSend(): Boolean
    begin
        if not CanSend then
            exit(true);
        Cancelled := true;
        if not HideMailDialog then begin
            if RunMailDialog then
                Cancelled := false
            else
                exit(true);
            if OutlookSupported then
                if DoEdit then begin
                    if SendMailOnWinClient then
                        exit(true);
                    OutlookSupported := false;
                    if not SMTPSupported then
                        exit(false);
                    if Confirm(OutlookNotAvailableContinueEditQst) then
                        exit(DoSend);
                end
        end;

        if GraphSupported then
            exit(SendViaGraph);

        if SMTPSupported then
            exit(SendViaSMTP);

        exit(false);
    end;

    local procedure QualifyFromAddress()
    var
        TempPossibleEmailNameValueBuffer: Record "Name/Value Buffer" temporary;
        MailForEmails: Codeunit Mail;
    begin
        OnBeforeQualifyFromAddress(TempEmailItem);

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

        if TempPossibleEmailNameValueBuffer.IsEmpty then begin
            if ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop] then
                Error(FromAddressWasNotFoundErr);
            TempEmailItem."From Address" := '';
            exit;
        end;

        if AssignFromAddressIfExist(TempPossibleEmailNameValueBuffer, '') then
            exit;
    end;

    local procedure AssignFromAddressIfExist(var TempPossibleEmailNameValueBuffer: Record "Name/Value Buffer" temporary; FilteredName: Text): Boolean
    begin
        if FilteredName <> '' then
            TempPossibleEmailNameValueBuffer.SetFilter(Name, FilteredName);
        if not TempPossibleEmailNameValueBuffer.IsEmpty then begin
            TempPossibleEmailNameValueBuffer.FindFirst;
            if TempPossibleEmailNameValueBuffer.Value <> '' then begin
                TempEmailItem."From Address" := TempPossibleEmailNameValueBuffer.Value;
                exit(true);
            end;
        end;

        TempPossibleEmailNameValueBuffer.Reset;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SendMailOrDownload(TempEmailItem: Record "Email Item" temporary; HideMailDialog: Boolean)
    var
        MailManagement: Codeunit "Mail Management";
        OfficeMgt: Codeunit "Office Management";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        MailManagement.InitializeFrom(HideMailDialog, not IsBackground);
        if MailManagement.IsEnabled then
            if MailManagement.Send(TempEmailItem) then begin
                MailSent := MailManagement.IsSent;
                DeleteTempAttachments(TempEmailItem);
                exit;
            end;

        if EnvInfoProxy.IsInvoicing then begin
            if MailManagement.IsGraphEnabled then
                Error(MailManagement.GetLastGraphError);

            Error(CannotSendMailThenDownloadErr);
        end;

        if IsBackground then
            exit;

        if not GuiAllowed or (OfficeMgt.IsAvailable and not OfficeMgt.IsPopOut) then
            Error(CannotSendMailThenDownloadErr);

        if not Confirm(StrSubstNo('%1\\%2', CannotSendMailThenDownloadErr, CannotSendMailThenDownloadQst)) then
            exit;

        DownloadPdfAttachment(TempEmailItem);
    end;

    procedure DownloadPdfAttachment(TempEmailItem: Record "Email Item" temporary)
    var
        FileManagement: Codeunit "File Management";
    begin
        with TempEmailItem do
            if "Attachment File Path" <> '' then
                FileManagement.DownloadHandler("Attachment File Path", SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, "Attachment Name")
            else
                if "Body File Path" <> '' then
                    FileManagement.DownloadHandler("Body File Path", SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, EmailAttachmentTxt);
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

    local procedure DeleteTempAttachments(var EmailItem: Record "Email Item")
    begin
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 2") then;
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 3") then;
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 4") then;
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 5") then;
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 6") then;
        if TryDeleteTempAttachment(EmailItem."Attachment File Path 7") then;

        OnAfterDeleteTempAttachments(EmailItem);
    end;

    [TryFunction]
    local procedure TryDeleteTempAttachment(var FilePath: Text[250])
    var
        FileManagement: Codeunit "File Management";
    begin
        if FilePath = '' then
            exit;
        FileManagement.DeleteServerFile(FilePath);
        FilePath := '';
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryGetSenderEmailAddress(var FromAddress: Text[250])
    begin
        FromAddress := GetSenderEmailAddress;
    end;

    procedure GetSenderEmailAddress(): Text[250]
    begin
        if not IsEnabled then
            exit('');
        QualifyFromAddress;

        OnAfterGetSenderEmailAddress(TempEmailItem);
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

    [Scope('OnPrem')]
    procedure GetSMTPCredentials(var SMTPMailSetup: Record "SMTP Mail Setup")
    var
        JSONManagement: Codeunit "JSON Management";
        AzureKeyVault: Codeunit "Azure Key Vault";
        SMTPServerParameter: DotNet JObject;
        SMTPServerParameters: Text;
        VaultAuthentication: Text;
        VaultUserID: Text[250];
        VaultSMTPServerPort: Text;
        VaultSecureConnection: Text;
        VaultPasswordKey: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SMTPSetupTxt, SMTPServerParameters) then
            exit;
        JSONManagement.InitializeCollection(SMTPServerParameters);
        if JSONManagement.GetCollectionCount = 0 then
            exit;
        JSONManagement.GetJObjectFromCollectionByIndex(
          SMTPServerParameter,
          Random(JSONManagement.GetCollectionCount) - 1);
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'Server', SMTPMailSetup."SMTP Server");
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'ServerPort', VaultSMTPServerPort);
        if VaultSMTPServerPort <> '' then
            Evaluate(SMTPMailSetup."SMTP Server Port", VaultSMTPServerPort);
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'Authentication', VaultAuthentication);
        if VaultAuthentication <> '' then
            Evaluate(SMTPMailSetup.Authentication, VaultAuthentication);
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'User', VaultUserID);
        SMTPMailSetup.Validate("User ID", VaultUserID);
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'Password', VaultPasswordKey);
        SMTPMailSetup.SetPassword(VaultPasswordKey);
        JSONManagement.GetStringPropertyValueFromJObjectByName(SMTPServerParameter, 'SecureConnection', VaultSecureConnection);
        if VaultSecureConnection <> '' then
            Evaluate(SMTPMailSetup."Secure Connection", VaultSecureConnection);
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
        Result := not EventSubscription.IsEmpty;
        exit(Result);
    end;

    procedure IsHandlingGetEmailBodyVendor(): Boolean
    var
        EventSubscription: Record "Event Subscription";
        Result: Boolean;
    begin
        FilterEventSubscription(EventSubscription, 'OnAfterGetEmailBodyVendor');
        Result := not EventSubscription.IsEmpty;
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
    local procedure OnBeforeCheckValidEmailAddress(Recipients: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoSending(var CancelSending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQualifyFromAddress(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSentViaSMTP(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendMailOnWinClient(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteTempAttachments(var EmailItem: Record "Email Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSenderEmailAddress(var EmailItem: Record "Email Item")
    begin
    end;
}

