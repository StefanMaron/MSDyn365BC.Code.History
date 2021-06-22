codeunit 5321 "Exchange Web Services Server"
{

    trigger OnRun()
    begin
    end;

    var
        Service: DotNet ExchangeServiceWrapper;
        ProdEndpointTxt: Label 'https://outlook.office365.com/EWS/Exchange.asmx', Locked = true;
        ExpiredTokenErr: Label 'Trying to reconnect. Please close and reopen the add-in.';

    local procedure InitializeForVersion(AutodiscoveryEmail: Text[250]; var ServiceUri: Text; Credentials: DotNet ExchangeCredentials; Rediscover: Boolean; ExchangeVersion: DotNet ExchangeVersion) Result: Boolean
    var
        ServiceFactory: DotNet ServiceWrapperFactory;
    begin
        if IsNull(Service) then
            Service := ServiceFactory.CreateServiceWrapperForVersion(ExchangeVersion);

        if (ServiceUri = '') and not Rediscover then
            ServiceUri := GetEndpoint;
        Service.ExchangeServiceUrl := ServiceUri;

        if not IsNull(Credentials) then
            Service.SetNetworkCredential(Credentials);

        if (Service.ExchangeServiceUrl = '') or Rediscover then begin
            Result := Service.AutodiscoverServiceUrl(AutodiscoveryEmail);
            ServiceUri := Service.ExchangeServiceUrl;
        end else
            Result := true;
    end;

    [Scope('OnPrem')]
    procedure Initialize(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet ExchangeCredentials; Rediscover: Boolean) Result: Boolean
    var
        ExchangeVersion: DotNet ExchangeVersion;
    begin
        Result := InitializeForVersion(AutodiscoveryEmail, ServiceUri, Credentials, Rediscover, ExchangeVersion.Exchange2013);
    end;

    [Scope('OnPrem')]
    procedure InitializeAndValidate(AutodiscoveryEmail: Text[250]; var ServiceUri: Text; Credentials: DotNet ExchangeCredentials) Result: Boolean
    var
        ExchangeVersion: DotNet ExchangeVersion;
    begin
        if ServiceUri = '' then
            ServiceUri := GetEndpoint;

        if InitializeForVersion(AutodiscoveryEmail, ServiceUri, Credentials, false, ExchangeVersion.Exchange2013) then begin
            Result := ValidCredentials;

            // If the email address was not found in the exchange server (404 error) then attempt to discover the exchange service endpoint.
            if not Result and (StrPos(GetLastErrorText, '404') > 0) then
                if InitializeForVersion(AutodiscoveryEmail, ServiceUri, Credentials, true, ExchangeVersion.Exchange2013) and
                   ValidCredentials
                then begin
                    Result := true;
                    ServiceUri := Service.ExchangeServiceUrl;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure Initialize2010(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet ExchangeCredentials; Rediscover: Boolean) Result: Boolean
    var
        ExchangeVersion: DotNet ExchangeVersion;
    begin
        Result := InitializeForVersion(AutodiscoveryEmail, ServiceUri, Credentials, Rediscover, ExchangeVersion.Exchange2010);
    end;

    [Scope('OnPrem')]
    procedure InitializeWithCertificate(ApplicationID: Guid; Thumbprint: Text[40]; AuthenticationEndpoint: Text[250]; ExchangeEndpoint: Text[250]; ResourceUri: Text[250])
    var
        ServiceFactory: DotNet ServiceWrapperFactory;
    begin
        Service := ServiceFactory.CreateServiceWrapperWithCertificate(ApplicationID, Thumbprint, AuthenticationEndpoint, ResourceUri);
        Service.ExchangeServiceUrl := ExchangeEndpoint;
    end;

    [Scope('OnPrem')]
    procedure InitializeWithOAuthToken(Token: Text; ExchangeEndpoint: Text)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        if ExchangeEndpoint = '' then
            ExchangeEndpoint := GetEndpoint;

        AzureADMgt.CreateExchangeServiceWrapperWithToken(Token, Service);
        Service.ExchangeServiceUrl := ExchangeEndpoint;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ValidCredentials()
    var
        AzureADAuthFlow: Codeunit "Azure AD Auth Flow";
    begin
        if AzureADAuthFlow.CanHandle then
            if not Service.ValidateCredentials then
                Error('');
    end;

    [Scope('OnPrem')]
    procedure SetImpersonatedIdentity(Email: Text[250])
    begin
        Service.SetImpersonatedIdentity(Email);
    end;

    [Scope('OnPrem')]
    procedure InstallApp(ManifestPath: InStream)
    begin
        Service.InstallApp(ManifestPath);
    end;

    [Scope('OnPrem')]
    procedure CreateAppointment(var Appointment: DotNet IAppointment)
    begin
        Appointment := Service.CreateAppointment;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SendEmailMessageWithAttachment(Subject: Text; RecipientAddress: Text; BodyHTML: Text; AttachmentPath: Text; SenderAddress: Text)
    begin
        OnBeforeSendEmailMessageWithAttachment(Subject, RecipientAddress, BodyHTML, SenderAddress);
        Service.SendMessageAndSaveToSentItems(Subject, RecipientAddress, BodyHTML, AttachmentPath, SenderAddress, '');
    end;

    [Scope('OnPrem')]
    procedure SaveEmailToInbox(EmailMessage: Text)
    begin
        Service.SaveEmlMessageToInbox(EmailMessage);
    end;

    [Scope('OnPrem')]
    procedure SaveHTMLEmailToInbox(EmailSubject: Text; EmailBodyHTML: Text; SenderAddress: Text; SenderName: Text; RecipientAddress: Text)
    begin
        OnBeforeSaveHTMLEmailToInbox(EmailSubject, EmailBodyHTML, SenderAddress, SenderName, RecipientAddress);
        Service.SaveHtmlMessageToInbox(EmailSubject, EmailBodyHTML, SenderAddress, SenderName, RecipientAddress);
    end;

    [Scope('OnPrem')]
    procedure GetEmailFolder(FolderId: Text; var Folder: DotNet IEmailFolder): Boolean
    begin
        Folder := Service.GetEmailFolder(FolderId);
        exit(not IsNull(Folder));
    end;

    [Scope('OnPrem')]
    procedure IdenticalMailExists(SampleMessage: DotNet IEmailMessage; TargetFolder: DotNet IEmailFolder; var TargetMessage: DotNet IEmailMessage): Boolean
    var
        FindResults: DotNet IFindEmailsResults;
        Enumerator: DotNet IEnumerator;
        FolderOffset: Integer;
    begin
        TargetFolder.UseSampleEmailAsFilter(SampleMessage);
        FolderOffset := 0;
        repeat
            FindResults := TargetFolder.FindEmailMessages(50, FolderOffset);
            if FindResults.TotalCount > 0 then begin
                Enumerator := FindResults.GetEnumerator;
                while Enumerator.MoveNext do begin
                    TargetMessage := Enumerator.Current;
                    if SampleMessage.Subject = TargetMessage.Subject then
                        if SampleMessage.Body = TargetMessage.Body then begin
                            if CompareEmailAttachments(SampleMessage, TargetMessage) then
                                exit(true);
                        end;
                end;
                FolderOffset := FindResults.NextPageOffset;
            end;
        until not FindResults.MoreAvailable;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CompareEmailAttachments(LeftMsg: DotNet IEmailMessage; RightMsg: DotNet IEmailMessage): Boolean
    var
        LeftEnum: DotNet IEnumerator;
        RightEnum: DotNet IEnumerator;
        LeftAttrib: DotNet IAttachment;
        RightAttrib: DotNet IAttachment;
        LeftFlag: Boolean;
        RightFlag: Boolean;
    begin
        LeftEnum := LeftMsg.Attachments.GetEnumerator;
        RightEnum := RightMsg.Attachments.GetEnumerator;

        LeftFlag := LeftEnum.MoveNext;
        RightFlag := RightEnum.MoveNext;
        while LeftFlag and RightFlag do begin
            LeftAttrib := LeftEnum.Current;
            RightAttrib := RightEnum.Current;
            if (LeftAttrib.ContentId <> RightAttrib.ContentId) or (LeftAttrib.ContentType <> RightAttrib.ContentType) then
                exit(false);

            LeftFlag := LeftEnum.MoveNext;
            RightFlag := RightEnum.MoveNext;
        end;

        exit(LeftFlag = RightFlag);
    end;

    [TryFunction]
    local procedure TryGetEmailWithAttachments(var EmailMessage: DotNet IEmailMessage; ItemID: Text[250])
    begin
        EmailMessage := Service.GetEmailWithAttachments(ItemID);
    end;

    [Scope('OnPrem')]
    procedure GetEmailAndAttachments(ItemID: Text[250]; var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow; VendorNumber: Code[20])
    var
        EmailMessage: DotNet IEmailMessage;
        Attachments: DotNet IEnumerable;
        Attachment: DotNet IAttachment;
    begin
        if TryGetEmailWithAttachments(EmailMessage, ItemID) then begin
            if not IsNull(EmailMessage) then
                with TempExchangeObject do begin
                    Init;
                    Validate("Item ID", EmailMessage.Id);
                    Validate(Type, Type::Email);
                    Validate(Name, EmailMessage.Subject);
                    Validate(Owner, UserSecurityId);
                    SetBody(EmailMessage.TextBody);
                    SetContent(EmailMessage.Content);
                    SetViewLink(EmailMessage.LinkUrl);
                    if not Insert(true) then
                        Modify(true);

                    Attachments := EmailMessage.Attachments;
                    foreach Attachment in Attachments do begin
                        Init;
                        Validate(Type, Type::Attachment);
                        Validate("Item ID", Attachment.Id);
                        Validate(Name, Attachment.Name);
                        Validate("Parent ID", EmailMessage.Id);
                        Validate("Content Type", Attachment.ContentType);
                        Validate(InitiatedAction, Action);
                        Validate(VendorNo, VendorNumber);
                        Validate(IsInline, Attachment.IsInline);
                        SetContent(Attachment.Content);
                        if not Insert(true) then
                            Modify(true);
                    end;
                end else
                Error(ExpiredTokenErr)
        end else
            Error(ExpiredTokenErr)
    end;

    [Scope('OnPrem')]
    procedure GetEmailBody(ItemID: Text[250]) EmailBody: Text
    var
        EmailMessage: DotNet IEmailMessage;
    begin
        if TryGetEmailWithAttachments(EmailMessage, ItemID) and not IsNull(EmailMessage) then
            EmailBody := EmailMessage.TextBody
        else
            Error(ExpiredTokenErr)
    end;

    [TryFunction]
    local procedure TryEmailHasAttachments(var HasAttachments: Boolean; ItemID: Text[250])
    begin
        HasAttachments := Service.AttachmentsExists(ItemID);
    end;

    [Scope('OnPrem')]
    procedure EmailHasAttachments(ItemID: Text[250]): Boolean
    var
        HasAttachments: Boolean;
    begin
        if not TryEmailHasAttachments(HasAttachments, ItemID) then
            exit(false);
        exit(HasAttachments)
    end;

    procedure GetEndpoint() Endpoint: Text
    begin
        Endpoint := ProdEndpoint;
    end;

    procedure ProdEndpoint(): Text
    begin
        exit(ProdEndpointTxt);
    end;

    [Scope('OnPrem')]
    procedure GetCurrentUserTimeZone(): Text
    begin
        exit(Service.GetExchangeUserTimeZone);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveHTMLEmailToInbox(var EmailSubject: Text; var EmailBodyHTML: Text; var SenderAddress: Text; var SenderName: Text; var RecipientAddress: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailMessageWithAttachment(var Subject: Text; var RecipientAddress: Text; var BodyHTML: Text; var SenderAddress: Text)
    begin
    end;
}

