#if not CLEAN21
codeunit 405 "Graph Mail"
{
    Permissions = TableData "Calendar Event" = rimd;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        Session.LogMessage('00001QJ', RefreshRefreshTokenMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
        GraphMailSetup.Get();
        GraphMailSetup.RenewRefreshToken();
        GraphMailSetup.Modify(true);
    end;

    var
        GraphMailFailedSendErr: Label 'Failed to send mail (retry %1): %2', Locked = true;
        GraphMailCategoryTxt: Label 'AL GraphMail', Locked = true;
        RefreshRefreshTokenMsg: Label 'Renewing refresh code', Locked = true;
        RefreshTokenMsg: Label 'Renew refresh code';
        RetryExceededMsg: Label 'Exceeded maximum number of retries', Locked = true;
        TestMessageTxt: Label 'Hello %1, this is a test message from Invoicing to show you what an email from you will look like to your customers.', Comment = '%1 = the name of the user (e.g. Joe)';
        LastErrorMsg: Text;
        ClientResourceNameTxt: Label 'MailerResourceId', Locked = true;
        EmailTooLargeTxt: Label 'The email was too large and could not be sent. Consider removing an attachment and try again.';
        EmailForbiddenTxt: Label 'The sender is not authorized to send mail. Check that they have a valid Exchange license, or change the sender in settings.';
        RefreshTokenKeyTxt: Label 'RefreshTokenKey', Locked = true;
        Err503Msg: Label '(503) Server Unavailable', Locked = true;
        Err401Msg: Label '(401) Unauthorized', Locked = true;
        Err403Msg: Label '(403) Forbidden', Locked = true;
        Err413Msg: Label '(413) Request Entity Too Large', Locked = true;

    [Scope('OnPrem')]
    procedure PrepareMessage(TempEmailItem: Record "Email Item" temporary): Text
    var
        JSONManagement: Codeunit "JSON Management";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        EmailAddressCollectionJsonArray: DotNet JArray;
        AttachmentCollectionJsonArray: DotNet JArray;
        PayloadJsonObject: DotNet JObject;
        MessageJsonObject: DotNet JObject;
        MessageContentJsonObject: DotNet JObject;
        EmailAddressJsonObject: DotNet JObject;
        ContentType: Text;
        MessageContent: Text;
        AttachmentNames: List of [Text];
        AttachmentStream: Instream;
        Index: Integer;
    begin
        MessageContent := TempEmailItem.GetBodyText();

        if TempEmailItem."Plaintext Formatted" then
            ContentType := 'text'
        else
            ContentType := 'html';

        MessageJsonObject := MessageJsonObject.JObject();

        AttachmentCollectionJsonArray := AttachmentCollectionJsonArray.JArray();

        if not TempEmailItem."Plaintext Formatted" then
            AddInlineImagesToAttachments(AttachmentCollectionJsonArray, MessageContent);

        MessageContentJsonObject := MessageContentJsonObject.JObject();
        JSONManagement.AddJPropertyToJObject(MessageContentJsonObject, 'content', MessageContent);
        JSONManagement.AddJPropertyToJObject(MessageContentJsonObject, 'contentType', ContentType);

        JSONManagement.AddJObjectToJObject(MessageJsonObject, 'body', MessageContentJsonObject);

        GetEmailAsJsonObject(EmailAddressJsonObject, TempEmailItem."From Name", TempEmailItem."From Address");
        JSONManagement.AddJObjectToJObject(MessageJsonObject, 'from', EmailAddressJsonObject);

        EmailAddressCollectionJsonArray := EmailAddressCollectionJsonArray.JArray();
        AddRecipients(EmailAddressCollectionJsonArray, TempEmailItem."Send to");
        JSONManagement.AddJArrayToJObject(MessageJsonObject, 'toRecipients', EmailAddressCollectionJsonArray);

        if TempEmailItem."Send CC" <> '' then begin
            EmailAddressCollectionJsonArray := EmailAddressCollectionJsonArray.JArray();
            AddRecipients(EmailAddressCollectionJsonArray, TempEmailItem."Send CC");
            JSONManagement.AddJArrayToJObject(MessageJsonObject, 'ccRecipients', EmailAddressCollectionJsonArray);
        end;

        if TempEmailItem."Send BCC" <> '' then begin
            EmailAddressCollectionJsonArray := EmailAddressCollectionJsonArray.JArray();
            AddRecipients(EmailAddressCollectionJsonArray, TempEmailItem."Send BCC");
            JSONManagement.AddJArrayToJObject(MessageJsonObject, 'bccRecipients', EmailAddressCollectionJsonArray);
        end;

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);

        for Index := 1 to Attachments.Count() do begin
            Attachments.Get(Index, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            AddAttachmentToMessage(AttachmentCollectionJsonArray, AttachmentNames.Get(Index), AttachmentStream);
        end;

        JSONManagement.AddJArrayToJObject(MessageJsonObject, 'attachments', AttachmentCollectionJsonArray);

        JSONManagement.AddJPropertyToJObject(MessageJsonObject, 'importance', 'normal');
        JSONManagement.AddJPropertyToJObject(MessageJsonObject, 'subject', TempEmailItem.Subject);

        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(PayloadJsonObject);
        JSONManagement.AddJObjectToJObject(PayloadJsonObject, 'message', MessageJsonObject);
        JSONManagement.AddJPropertyToJObject(PayloadJsonObject, 'saveToSentItems', 'true');

        exit(JSONManagement.WriteObjectToString());
    end;

    [Scope('OnPrem')]
    procedure SetupGraph(ShowSetup: Boolean): Boolean
    var
        GraphMailSetup: Record "Graph Mail Setup";
        IsSetupSuccessful: Boolean;
    begin
        if ShowSetup then begin
            if PAGE.RunModal(PAGE::"Graph Mail Setup") = ACTION::LookupOK then;
        end else begin
            if not GraphMailSetup.Get() then
                GraphMailSetup.Insert();

            IsSetupSuccessful := GraphMailSetup.Initialize(true);

            GraphMailSetup.Validate(Enabled, IsSetupSuccessful);
            GraphMailSetup.Modify(true);
        end;

        exit(IsEnabled());
    end;

    [Scope('OnPrem')]
    procedure SendMail(TempEmailItem: Record "Email Item" temporary): Boolean
    begin
        exit(SendMailWithRetry(TempEmailItem, 0));
    end;

    local procedure SendMailWithRetry(TempEmailItem: Record "Email Item" temporary; RetryCount: Integer) MailSent: Boolean
    var
        GraphMailSetup: Record "Graph Mail Setup";
        TokenCacheState: Text;
    begin
        if RetryCount > 2 then begin
            Session.LogMessage('00001TY', RetryExceededMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);
            exit;
        end;

        MailSent := TrySendMail(TempEmailItem, TokenCacheState);

        if not MailSent then begin
            LastErrorMsg := GetLastErrorText;
            Session.LogMessage('00001QK', StrSubstNo(GraphMailFailedSendErr, RetryCount, LastErrorMsg), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', GraphMailCategoryTxt);

            if HandleError(LastErrorMsg) then
                SendMailWithRetry(TempEmailItem, RetryCount + 1);
            exit;
        end;

        if GraphMailSetup.Get() then begin
            GraphMailSetup.SetRefreshToken(TokenCacheState);
            if GraphMailSetup.Modify() then;
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TrySendMail(TempEmailItem: Record "Email Item" temporary; var TokenCacheState: Text)
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        GraphMailSetup.Get();
        GraphMailSetup.SendMail(TempEmailItem, TokenCacheState);
    end;

    procedure GetGraphError(): Text
    begin
        if LastErrorMsg = '' then
            exit('');

        if StrPos(LastErrorMsg, Err413Msg) > 0 then
            exit(EmailTooLargeTxt);

        if StrPos(LastErrorMsg, Err403Msg) > 0 then
            exit(EmailForbiddenTxt);

        exit(LastErrorMsg);
    end;

    procedure GetGraphDomain(): Text
    var
        UrlHelper: Codeunit "Url Helper";
        Domain: Text;
    begin
        Domain := UrlHelper.GetGraphUrl();
        if Domain <> '' then
            exit(Domain);

        OnGetGraphDomain(Domain);
        if Domain = '' then
            Domain := 'https://graph.microsoft.com/';

        exit(Domain);
    end;

    procedure GetTestMessageBody(): Text
    var
        User: Record User;
    begin
        if User.Get(UserSecurityId()) then;

        exit(StrSubstNo(TestMessageTxt, User."Full Name"));
    end;

    procedure IsEnabled(): Boolean
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        if not GraphMailSetup.ReadPermission() then
            exit(false);

        if not GraphMailSetup.Get() then
            exit(false);

        if not GraphMailSetup.Enabled then
            exit(false);

        if GraphMailSetup."Sender Email" = '' then
            exit(false);

        if GraphMailSetup."Sender AAD ID" = '' then
            exit(false);

        if not IsolatedStorage.Contains(Format(RefreshTokenKeyTxt), DataScope::Company) then
            exit(false);

        if GraphMailSetup."Expires On" < CurrentDateTime() then
            exit(false);

        exit(true);
    end;

    [NonDebuggable]
    procedure HasConfiguration(): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Resource: Text;
    begin
        if AzureKeyVault.GetAzureKeyVaultSecret(ClientResourceNameTxt, Resource) then
            exit(Resource <> '');

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UserHasLicense(): Boolean
    var
        TempGraphMailSetup: Record "Graph Mail Setup" temporary;
    begin
        if not HasConfiguration() then
            exit(false);

        TempGraphMailSetup.Insert();
        exit(TempGraphMailSetup.Initialize(false));
    end;

    local procedure GetEmailAsJsonObject(var EmailJsonObject: DotNet JObject; Name: Text; Address: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        EmailAddressJsonObject: DotNet JObject;
    begin
        EmailJsonObject := EmailJsonObject.JObject();
        EmailAddressJsonObject := EmailAddressJsonObject.JObject();

        JSONManagement.AddJPropertyToJObject(EmailAddressJsonObject, 'address', Address);
        if Name <> '' then
            JSONManagement.AddJPropertyToJObject(EmailAddressJsonObject, 'name', Name);

        JSONManagement.AddJObjectToJObject(EmailJsonObject, 'emailaddress', EmailAddressJsonObject);
    end;

    local procedure AddRecipients(var RecipientCollectionJsonArray: DotNet JArray; RecipientList: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        JSONManagement: Codeunit "JSON Management";
        EmailJsonObject: DotNet JObject;
        Recipient: Text;
        I: Integer;
    begin
        if RecipientList = '' then
            exit;

        RecipientList := ConvertStr(RecipientList, ';', ',');

        for I := 1 to TypeHelper.GetNumberOfOptions(RecipientList) + 1 do begin
            Recipient := SelectStr(I, RecipientList);
            GetEmailAsJsonObject(EmailJsonObject, '', Recipient);
            JSONManagement.AddJObjectToJArray(RecipientCollectionJsonArray, EmailJsonObject);
        end;
    end;

    local procedure AddAttachmentToMessage(var AttachmentCollectionJsonArray: DotNet JArray; AttachmentName: Text; AttachmentStream: InStream)
    var
        JSONManagement: Codeunit "JSON Management";
        Base64Convert: Codeunit "Base64 Convert";
        AttachmentJsonObject: DotNet JObject;
    begin
        if AttachmentName = '' then
            exit;

        AttachmentJsonObject := AttachmentJsonObject.JObject();
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, '@odata.type', '#microsoft.graph.fileAttachment');
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'name', AttachmentName);
        JSONManagement.AddJPropertyToJObject(
          AttachmentJsonObject, 'contentBytes', Base64Convert.ToBase64(AttachmentStream));

        JSONManagement.AddJObjectToJArray(AttachmentCollectionJsonArray, AttachmentJsonObject);
    end;

    local procedure AddInlineAttachmentToMessage(var AttachmentCollectionJsonArray: DotNet JArray; ContentId: Text; AttachmentType: Text; AttachmentContent: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        AttachmentJsonObject: DotNet JObject;
    begin
        if AttachmentContent = '' then
            exit;

        AttachmentJsonObject := AttachmentJsonObject.JObject();
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, '@odata.type', '#microsoft.graph.fileAttachment');
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'contentBytes', AttachmentContent);
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'contentType', AttachmentType);
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'contentId', ContentId);
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'name', ContentId);
        JSONManagement.AddJPropertyToJObject(AttachmentJsonObject, 'isInline', 'true');

        JSONManagement.AddJObjectToJArray(AttachmentCollectionJsonArray, AttachmentJsonObject);
    end;

    local procedure AddInlineImagesToAttachments(var AttachmentCollectionJsonArray: DotNet JArray; var MessageContent: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        XmlNodeList: DotNet XmlNodeList;
        XmlElement: DotNet XmlElement;
        Regex: DotNet Regex;
        Match: DotNet Match;
        String: DotNet String;
        ItemSource: Text;
        ItemType: Text;
        ContentId: Text;
        ItemData: Text;
        I: Integer;
        DocumentModified: Boolean;
    begin
        if not XMLDOMManagement.LoadXMLDocumentFromText(MessageContent, XmlDocument) then
            exit; // document is not XML compliant

        if not XMLDOMManagement.FindNodes(XmlDocument, '//img[@src]', XmlNodeList) then
            exit;

        Regex := Regex.Regex('data:(.*);base64,(.*)');

        for I := 0 to XmlNodeList.Count - 1 do begin
            XmlElement := XmlNodeList.Item(I);
            ItemSource := XmlElement.GetAttribute('src');

            Match := Regex.Match(ItemSource);
            if not String.IsNullOrEmpty(Match.Value) then begin
                ItemType := Match.Groups.Item(1).Value;
                ItemData := Match.Groups.Item(2).Value;
                ContentId := Format(I);

                AddInlineAttachmentToMessage(AttachmentCollectionJsonArray, ContentId, ItemType, ItemData);

                XmlElement.SetAttribute('src', StrSubstNo('cid:%1', ContentId));
                DocumentModified := true;
            end;
        end;

        if DocumentModified then
            MessageContent := XmlDocument.OuterXml();
    end;

    local procedure HandleError(ErrorMessage: Text): Boolean
    var
        GraphMailSetup: Record "Graph Mail Setup";
        User: Record User;
    begin
        if StrPos(ErrorMessage, Err503Msg) > 0 then
            exit(true); // Problem with graph, retry

        if StrPos(ErrorMessage, Err401Msg) = 0 then
            exit(false);

        // If the current email setup matches the current user
        // try resetting the setup with a new refresh token
        if GraphMailSetup.Get() then
            if User.Get(UserSecurityId()) then
                if GraphMailSetup."Sender Email" = User."Contact Email" then
                    if GraphMailSetup.Delete(true) then
                        exit(SetupGraph(false));

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterOpenCompany()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        CalendarEvent: Record "Calendar Event";
        CalendarEventMangement: Codeunit "Calendar Event Mangement";
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Background then
            exit;

        if not CalendarEvent.WritePermission then
            exit;

        if not IsEnabled() then
            exit;

        if not GraphMailSetup.Get() then
            exit;

        if DT2Date(GraphMailSetup."Expires On") - 14 = Today then
            exit; // token was already refreshed today

        CalendarEventMangement.CreateCalendarEventForCodeunit(Today, RefreshTokenMsg, CODEUNIT::"Graph Mail");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGraphDomain(var GraphDomain: Text)
    begin
    end;
}
#endif
