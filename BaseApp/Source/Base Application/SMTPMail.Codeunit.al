codeunit 400 "SMTP Mail"
{
    Permissions = TableData "SMTP Mail Setup" = r;

    var
        SmtpMailSetup: Record "SMTP Mail Setup";
        SmtpClient: DotNet SmtpClient;
        BodyBuilder: Dotnet MimeBodyBuilder;
        Email: DotNet MimeMessage;
        SmtpAddress: DotNet MimeMailboxAddress;
        CancellationToken: DotNet CancellationToken;
        ITransferProgress: Dotnet ITransferProgress;
        HtmlFormattedBody: Boolean;
        SendResult: Text;
        SendErr: Label 'The email couldn''t be sent. %1', Comment = '%1 = a more detailed error message';
        RecipientErr: Label 'Could not add recipient %1.', Comment = '%1 = email address';
        BodyErr: Label 'Could not add text to email body.';
        AttachErr: Label 'Could not add an attachment to the email.';
        SmtpServerErrorMsg: Label 'The mail system returned the following error: "%1".', Comment = '%1=an error message';
        AttachmentDoesNotExistTxt: Label 'Attachment %1 does not exist or cannot be accessed from the program.', Comment = '%1=file name';
        EmailFailedCheckSetupMsg: Label 'Check your email setup. If you turned on multi-factor authentication for the email address, you might need to set up an app password.';
        EmailFailedCheckRecipientMsg: Label 'Check the recipient''s email address.';
        EmailFailedWithErrorCodeMsg: Label 'We received the following error code: %1.', Comment = '%1=the SMTP error code returned';
        EmailFailedCheckSendAsMsg: Label 'Check your smtp Send As permissions.';
        SendAsTroubleshootingUrlTxt: Label 'https://aka.ms/EmailSetupHelp', Locked = true;
        InvoicingTroubleshootingUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2082472', Locked = true;
        BusinessCentralTroubleshootingUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2082540', Locked = true;
        SmtpConnectTelemetryErrorMsg: Label 'Unable to connect to SMTP server. Authentication email from: %1, send as: %2, %3, smtp server: %4, server port: %5, error code: %6', Comment = '%1=the from address, %2=is send as enabled, %3=the send as email, %4=the smtp server, %5=the server port, %6=error code';
        SmtpAuthenticateTelemetryErrorMsg: Label 'Unable to connect to SMTP server. Authentication email from: %1, smtp server: %2, server port: %3, error code: %4', Comment = '%1=the from address, %2=the smtp server, %3=the server port, %4=error code';
        SmtpSendTelemetryErrorMsg: Label 'Unable to send email. Send from: %1. Send to: %2, send as: %3, %4, subject: %5, error code: %6', Comment = '%1=the from address, %2=the to address, %3=is send as enabled, %4=the send as email, %5=the subject of the email, %6=error code';
        SmtpConnectedTelemetryMsg: Label 'Connected to SMTP server. Smtp server: %1, server port: %2', Comment = '%1=the smtp server, %2=the server port';
        SmtpAuthenticateTelemetryMsg: Label 'Authenticated to SMTP server.  Authentication email from: %1, smtp server: %2, server port: %3', Comment = '%1=the from address, %2=the smtp server, %3=the server port';
        SmtpSendTelemetryMsg: Label 'Email sent. Send from: %1, send to: %2, send as: %3, %4, subject: %5', Comment = '%1=the from address, %2=the to address, %3=is send as enabled, %4=the send as email, %5=the subject of the email';
        DetailsActionLbl: Label 'Details';
        ReadMoreActionLbl: Label 'Read more';
        SmtpCategoryLbl: Label 'SMTP', Locked = true;

    /// <summary>
    /// Initializes variables for creating an SMTP email.
    /// </summary>
    procedure Initialize()
    var
        MimeMessage: DotNet MimeMessage;
    begin
        SmtpClient := SmtpClient.SmtpClient();
        BodyBuilder := BodyBuilder.BodyBuilder();
        Email := MimeMessage.MimeMessage();
        HtmlFormattedBody := false;
    end;

    /// <summary>
    /// Adds the mailbox that this email is being sent from.
    /// </summary>
    /// <param name="FromName">The name of the email sender</param>
    /// <param name="FromAddress">The address of the default sender or, when using the Send As or Send on Behalf functionality, the address of the substitute sender</param>
    /// <remarks>
    /// See https://aka.ms/EmailSetupHelp to learn about the Send As functionality.
    /// </remarks>
    procedure AddFrom(FromName: Text; FromAddress: Text)
    var
        MailboxAddress: DotNet MimeMailboxAddress;
    begin
        MailboxAddress := MailboxAddress.MailboxAddress(FromName, FromAddress);
        Email.From.Add(MailboxAddress);
    end;

    /// <summary>
    /// Tries to parse the given addresses into InternetAddressList.
    /// </summary>
    /// <param name="InternetAddressList">The list of addresses output</param>
    /// <param name="Addresses">The list of addresses to parse</param>
    /// <returns>True if no errors occurred during parsing.</returns>
    [TryFunction]
    local procedure TryParseInternetAddressList(InternetAddressList: DotNet InternetAddressList; Addresses: List of [Text])
    var
        InternetAddress: DotNet InternetAddress;
        Address: Text;
        ErrorMessage: Text;
    begin
        foreach Address in Addresses do begin
            if InternetAddress.TryParse(Address, InternetAddress) then
                InternetAddressList.Add(InternetAddress)
            else
                ErrorMessage := GetLastErrorText();
        end;

        if ErrorMessage <> '' then
            Error(ErrorMessage);
    end;

    /// <summary>
    /// Tries to add the given mailbox to "To"/"Cc"/"Bcc" list.
    /// </summary>
    /// <param name="InternetAddressList">The list of addresses output</param>
    /// <param name="InternetAddress">The address to add to the list</param>
    /// <returns>True if no errors occurred during parsing.</returns>
    [TryFunction]
    local procedure TryAddAddress(InternetAddressList: DotNet InternetAddressList; Mailbox: DotNet InternetAddress)
    begin
        InternetAddressList.Add(Mailbox);
    end;

    /// <summary>
    /// Adds the recipients that this email is being sent to.
    /// </summary>
    /// <param name="Recipients">The recipient(s)</param>
    procedure AddRecipients(Recipients: List of [Text])
    begin
        AddToInternetAddressList(Email."To", Recipients);
    end;

    /// <summary>
    /// Adds the cc recipients that this email is being sent to.
    /// </summary>
    /// <param name="Recipients">The cc recipient(s)</param>
    procedure AddCC(Recipients: List of [Text])
    begin
        AddToInternetAddressList(Email.Cc, Recipients);
    end;

    /// <summary>
    /// Adds the bcc recipients that this email is being sent to.
    /// </summary>
    /// <param name="Recipients">The bcc recipient(s)</param>
    procedure AddBCC(Recipients: List of [Text])
    begin
        AddToInternetAddressList(Email.Bcc, Recipients);
    end;

    local procedure AddToInternetAddressList(InternetAddressList: DotNet InternetAddressList; Recipients: List of [Text])
    var
        ErrorMessage: Text;
    begin
        CheckValidEmailAddresses(FormatListToString(Recipients, ';'));

        if not TryParseInternetAddressList(InternetAddressList, Recipients) then begin
            ErrorMessage := GetLastErrorText();
        end;

        if ErrorMessage <> '' then
            ShowErrorNotification(StrSubstNo(RecipientErr, FormatListToString(Recipients, ';')), ErrorMessage);
    end;

    /// <summary>
    /// Adds the subject of this email.
    /// </summary>
    /// <param name="Subject">The subject</param>
    procedure AddSubject(Subject: Text)
    begin
        Email.Subject := Subject;
    end;

    /// <summary>
    /// Adds the html text to the body of this email.
    /// </summary>
    /// <param name="Body">The body</param>
    procedure AddBody(Body: Text)
    begin
        BodyBuilder.HtmlBody := Body;

        ConvertBase64ImagesToContentId();
        HtmlFormattedBody := true;
    end;

    /// <summary>
    /// Adds the plain text to the body of this email.
    /// </summary>
    /// <param name="Body">The body</param>
    procedure AddTextBody(Body: Text)
    begin
        BodyBuilder.TextBody := Body;
        HtmlFormattedBody := false;
    end;

    /// <summary>
    /// Appends additional html text to the body of this email.
    /// </summary>
    /// <param name="BodyPart">The body part to append</param>
    procedure AppendBody(BodyPart: Text)
    begin
        BodyBuilder.HtmlBody := BodyBuilder.HtmlBody + BodyPart;

        ConvertBase64ImagesToContentId();
        HtmlFormattedBody := true;
    end;

    /// <summary>
    /// Appends additional plain text to the body of this email.
    /// </summary>
    /// <param name="BodyPart">The body part to append</param>
    procedure AppendTextBody(BodyPart: Text)
    begin
        BodyBuilder.TextBody := BodyBuilder.TextBody + BodyPart;
        HtmlFormattedBody := false;
    end;

    /// <summary>
    /// Gets the name and the address that the email is being sent from.
    /// </summary>
    /// <returns>The name and address</returns>
    /// <remarks>
    /// If there is a name and address, they are returned in the following format: '"name" <address>'
    /// </remarks>
    procedure GetFrom(): Text
    begin
        exit(Email.From.ToString());
    end;

    /// <summary>
    /// Gets the addresses that the email is being sent to.
    /// </summary>
    /// <param name="Recipients">The list to add the recipients to</param>
    procedure GetRecipients(var Recipients: List of [Text])
    var
        Recipient: DotNet MimeMailboxAddress;
    begin
        foreach Recipient in Email."To" do begin
            Recipients.Add(Recipient.Address);
        end;
    end;

    /// <summary>
    /// Gets the addresses that the email is being sent to as cc.
    /// </summary>
    /// <param name="Recipients">The list to add the cc recipients to</param>
    procedure GetCC(var Recipients: List of [Text])
    var
        Recipient: DotNet MimeMailboxAddress;
    begin
        foreach Recipient in Email."Cc" do begin
            Recipients.Add(Recipient.Address);
        end;
    end;

    /// <summary>
    /// Gets the addresses that the email is being sent to as bcc.
    /// </summary>
    /// <param name="Recipients">The list to add the bcc recipients to</param>
    procedure GetBCC(var Recipients: List of [Text])
    var
        Recipient: DotNet MimeMailboxAddress;
    begin
        foreach Recipient in Email."Bcc" do begin
            Recipients.Add(Recipient.Address);
        end;
    end;

    /// <summary>
    /// Gets the subject of the email.
    /// </summary>
    /// <returns>The subject</returns>
    procedure GetSubject(): Text
    begin
        exit(Email.Subject);
    end;

    /// <summary>
    /// Gets the body of the email.
    /// </summary>
    /// <returns>The body</returns>
    procedure GetBody(): Text
    begin
        if IsBodyHtmlFormatted() then
            exit(BodyBuilder.HtmlBody)
        else
            exit(BodyBuilder.TextBody);
    end;

    /// <summary>
    /// Gets the number of linked resources in the email.
    /// </summary>
    /// <returns>The number of linked resources</returns>
    /// <remark>
    /// This counts the base64 strings in the body that were converted to Content ID.
    /// </remark>
    [Scope('OnPrem')]
    procedure GetLinkedResourcesCount(): Integer
    begin
        exit(BodyBuilder.LinkedResources.Count());
    end;

    /// <summary>
    /// Get if the body is HTML formatted.
    /// </summary>
    /// <returns>True if the body is HTML formatted.</returns>
    procedure IsBodyHtmlFormatted(): Boolean
    begin
        exit(HtmlFormattedBody);
    end;

    /// <summary>
    /// Creates the email with the name and address it is being sent from, the recipient, subject, and body.
    /// </summary>
    /// <param name="FromName">The name of the email sender</param>
    /// <param name="FromAddress">The address of the default sender or, when using the Send As or Send on Behalf functionality, the address of the substitute sender</param>
    /// <param name="Recipient">The recipient of the mail</param>
    /// <param name="Subject">The subject of the mail</param>
    /// <param name="Body">The body of the mail</param>
    /// <param name="HtmlFormatted">Whether the body is html formatted</param>
    [Obsolete('This method is obsolete. A new CreateMessage overload is available, with the following parameters (FromName: Text; FromAddress: Text; Recipients: List of [Text]; Subject: Text; Body: Text).')]
    [TryFunction]
    procedure CreateMessage(FromName: Text; FromAddress: Text; Recipient: Text; Subject: Text; Body: Text; HtmlFormatted: Boolean)
    var
        Recipients: List of [Text];
        Seperators: Text;
    begin
        Seperators := '; ,';
        Recipients := Recipient.Split(Seperators.Split());
        CreateMessage(FromName, FromAddress, Recipients, Subject, Body, HtmlFormatted);
    end;

    /// <summary>
    /// Creates the email with the name and address it is being sent from, the recipients, subject, and body.
    /// </summary>
    /// <param name="FromName">The name of the email sender</param>
    /// <param name="FromAddress">The address of the default sender or, when using the Send As or Send on Behalf functionality, the address of the substitute sender</param>
    /// <param name="Recipients">The recipient(s) of the mail</param>
    /// <param name="Subject">The subject of the mail</param>
    /// <param name="Body">The body of the mail</param>
    [TryFunction]
    procedure CreateMessage(FromName: Text; FromAddress: Text; Recipients: List of [Text]; Subject: Text; Body: Text)
    begin
        CreateMessage(FromName, FromAddress, Recipients, Subject, Body, false);
    end;

    /// <summary>
    /// Creates the email with the name and address it is being sent from, the recipients, subject, and body.
    /// </summary>
    /// <param name="FromName">The name of the email sender</param>
    /// <param name="FromAddress">The address of the default sender or, when using the Send As or Send on Behalf functionality, the address of the substitute sender</param>
    /// <param name="Recipients">The recipient(s) of the mail</param>
    /// <param name="Subject">The subject of the mail</param>
    /// <param name="Body">The body of the mail</param>
    /// <param name="HtmlFormatted">Whether the body is html formatted</param>
    [TryFunction]
    procedure CreateMessage(FromName: Text; FromAddress: Text; Recipients: List of [Text]; Subject: Text; Body: Text; HtmlFormatted: Boolean)
    var
        MailboxAddress: DotNet MimeMailboxAddress;
    begin
        Initialize();
        OnBeforeCreateMessage(FromName, FromAddress, Recipients, Subject, Body);

        SendResult := '';

        if Recipients.Count() <> 0 then
            CheckValidEmailAddresses(FormatListToString(Recipients, ';'));
        CheckValidEmailAddresses(FromAddress);
        SmtpMailSetup.GetSetup;
        SmtpMailSetup.TestField("SMTP Server");

        AddFrom(FromName, FromAddress);
        AddRecipients(Recipients);
        AddSubject(Subject);

        if HtmlFormatted then
            AddBody(Body)
        else
            AddTextBody(Body);

        HtmlFormattedBody := HtmlFormatted;
    end;

    /// <summary>
    /// Sends the email by connecting to the server specified in the SMTP email setup.
    /// </summary>
    /// <returns>
    /// True if the email was sent.
    /// False if there were any exceptions while connecting or sending.
    /// </returns>
    procedure Send(): Boolean
    var
        Result: Boolean;
        SMTPErrorCode: Text;
    begin
        SendResult := '';
        OnBeforeSend(SmtpMailSetup);
        Result := TryConnect();
        if not Result then begin
            SendResult := GetLastErrorText();
            SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
            SendTraceTag('00009UM', SmtpCategoryLbl, Verbosity::Error,
                StrSubstNo(SmtpConnectTelemetryErrorMsg, SmtpMailSetup."User ID", SmtpMailSetup."Allow Sender Substitution", SmtpMailSetup."Send As", SmtpMailSetup."SMTP Server", SmtpMailSetup."SMTP Server Port", SMTPErrorCode),
                DataClassification::EndUserIdentifiableInformation);
        end
        else begin
            SendTraceTag('00009UN', SmtpCategoryLbl, Verbosity::Normal,
                StrSubstNo(SmtpConnectedTelemetryMsg, SmtpMailSetup."SMTP Server", SmtpMailSetup."SMTP Server Port"),
                DataClassification::EndUserIdentifiableInformation);

            if SmtpMailSetup.Authentication <> SmtpMailSetup.Authentication::Anonymous then begin
                Result := TryAuthenticate();

                if not Result then begin
                    SendResult := GetLastErrorText();
                    SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
                    SendTraceTag('00009XS', SmtpCategoryLbl, Verbosity::Error,
                        StrSubstNo(SmtpAuthenticateTelemetryErrorMsg, SmtpMailSetup."User ID", SmtpMailSetup."SMTP Server", SmtpMailSetup."SMTP Server Port", SMTPErrorCode),
                        DataClassification::EndUserIdentifiableInformation);
                end
                else begin
                    SendTraceTag('00009XT', SmtpCategoryLbl, Verbosity::Normal,
                        StrSubstNo(SmtpAuthenticateTelemetryMsg, SmtpMailSetup."User ID", SmtpMailSetup."SMTP Server", SmtpMailSetup."SMTP Server Port"), DataClassification::EndUserIdentifiableInformation);
                end;
            end;

            if Result then begin
                Email.Body := BodyBuilder.ToMessageBody();

                Result := TrySend();
                if not Result then begin
                    SendResult := GetLastErrorText();
                    SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
                    SendTraceTag('00009UO', SmtpCategoryLbl, Verbosity::Error,
                    StrSubstNo(SmtpSendTelemetryErrorMsg, SmtpMailSetup."User ID", Email."To".ToString(), SmtpMailSetup."Allow Sender Substitution", SmtpMailSetup."Send As", GetSubject(), SMTPErrorCode),
                    DataClassification::EndUserIdentifiableInformation);
                end
                else
                    SendTraceTag('00009UP', SmtpCategoryLbl, Verbosity::Normal,
                    StrSubstNo(SmtpSendTelemetryMsg, SmtpMailSetup."User ID", Email."To".ToString(), SmtpMailSetup."Allow Sender Substitution", SmtpMailSetup."Send As", GetSubject()),
                    DataClassification::EndUserIdentifiableInformation);
            end;
        end;

        Clear(BodyBuilder);
        Clear(Email);
        Initialize();

        OnAfterSend(SendResult);

        exit(Result);
    end;

    /// <summary>
    /// Tries to send the email.
    /// </summary>
    /// <returns>True if there are no exceptions.</returns>
    [TryFunction]
    local procedure TrySend()
    begin
        SmtpClient.Send(Email, CancellationToken, ITransferProgress);
    end;

    /// <summary>
    /// Tries to connect to the SMTP server.
    /// </summary>
    /// <returns>True if there are no exceptions.</returns>
    [TryFunction]
    local procedure TryConnect()
    var
        SecureSocketOptions: DotNet SecureSocketOptions;
    begin
        if SMTPMailSetup."Secure Connection" then
            SecureSocketOptions := SecureSocketOptions.Auto
        else
            SecureSocketOptions := SecureSocketOptions.None;

        SmtpClient.Connect(SMTPMailSetup."SMTP Server", SMTPMailSetup."SMTP Server Port", SecureSocketOptions, CancellationToken)
    end;

    /// <summary>
    /// Tries to connect to the SMTP server.
    /// </summary>
    /// <returns>True if there are no exceptions.</returns>
    [TryFunction]
    local procedure TryAuthenticate()
    var
        Password: Text;
    begin
        Password := SmtpMailSetup.GetPassword();
        SmtpClient.Authenticate(SmtpMailSetup."User ID", Password, CancellationToken);
    end;

    /// <summary>
    /// Sends the email, and if it fails, shows an error notification.
    /// </summary>
    procedure SendShowError()
    var
        DetailedErrorText: Text;
        SMTPErrorCode: Text;
    begin
        if not Send then begin
            SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
            DetailedErrorText := StrSubstNo(SendErr, GetFriendlyMessageFromSmtpErrorCode(SMTPErrorCode));

            ShowErrorNotificationWithTroubleshooting(
              DetailedErrorText,
              SendResult,
              IsSmtpAuthErrorCode(SMTPErrorCode),
              IsSmtpSendAsErrorCode(SMTPErrorCode));
        end;
    end;

    /// <summary>
    /// Adds an attachment to the email through a path with a name.
    /// </summary>
    /// <param name="AttachmentPath">The stream of the attachment to attach</param>
    /// <param name="AttachmentName">The name of the attachment</param>
    /// <returns>True if successfully added</returns>
    [Scope('OnPrem')]
    procedure AddAttachment(AttachmentPath: Text; FileName: Text): Boolean
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        AttachmentStream: InStream;
        Result: Boolean;
    begin
        if AttachmentPath = '' then
            exit;
        if not Exists(AttachmentPath) then
            Error(AttachmentDoesNotExistTxt, AttachmentPath);

        FileName := FileManagement.StripNotsupportChrInFileName(FileName);
        FileName := DelChr(FileName, '=', ';'); // Used for splitting multiple file names in Mail .NET component

        FileManagement.IsAllowedPath(AttachmentPath, false);

        FileManagement.BLOBImportFromServerFile(TempBlob, AttachmentPath);
        TempBlob.CreateInStream(AttachmentStream);

        if FileName = '' then begin
            FileName := FileManagement.GetFileName(AttachmentPath);
        end;

        Result := TryAddAttachment(FileName, AttachmentStream);

        if not Result then begin
            ShowErrorNotification(AttachErr, GetLastErrorText());
        end;

        exit(Result);
    end;

    /// <summary>
    /// Adds an attachment to the email through an InStream with a name.
    /// </summary>
    /// <param name="AttachmentStream">The stream of the attachment to attach</param>
    /// <param name="AttachmentName">The name of the attachment</param>
    /// <returns>True if successfully added.</returns>
    procedure AddAttachmentStream(AttachmentStream: InStream; AttachmentName: Text): Boolean
    var
        FileManagement: Codeunit "File Management";
        Result: Boolean;
    begin
        AttachmentName := FileManagement.StripNotsupportChrInFileName(AttachmentName);

        Result := TryAddAttachment(AttachmentName, AttachmentStream);

        exit(Result);
    end;

    /// <summary>
    /// Try function for adding an attachment
    /// </summary>
    /// <remarks>
    /// Possible exceptions are ArgumentNullException and ArgumentException.
    /// For more information, see the Mimekit documentation.
    /// </remarks>
    [TryFunction]
    local procedure TryAddAttachment(FileName: Text; AttachmentStream: InStream)
    begin
        BodyBuilder.Attachments.Add(FileName, AttachmentStream)
    end;

    /// <summary>
    /// Validates that the SMTP Mail Setup is correct.
    /// </summary>
    /// <returns>True if SMTPMailSetup's "SMTP Server" is not empty.</returns>
    procedure IsEnabled(): Boolean
    begin
        SMTPMailSetup.GetSetup;
        exit(not (SMTPMailSetup."SMTP Server" = ''));
    end;

    /// <summary>
    /// Check if the given recipients contain valid addresses.
    /// </summary>
    /// <param name="Recipients">The address(es) of recipient(s)</param>
    /// <remarks>
    /// If there are multiple addresses, they should be in the following format: 'address1; address2; address3'.
    /// </remarks>
    procedure CheckValidEmailAddresses(Recipients: Text)
    var
        MailManagement: Codeunit "Mail Management";
    begin
        MailManagement.CheckValidEmailAddresses(Recipients);
    end;

    /// <summary>
    /// Formats a list into a semicolon separated string.
    /// </summary>
    /// <returns>Semicolon separated string of list of texts.</returns>
    local procedure FormatListToString(List: List of [Text]; Delimiter: Text) String: Text
    var
        Value: Text;
        Counter: Integer;
    begin
        String += List.Get(1);

        for Counter := 2 to List.Count() do begin
            String += StrSubstNo('%1 %2', Delimiter, List.Get(Counter));
        end;
    end;

    /// <summary>
    /// Searches the body of the email for <c>img</c> elements with a base64-encoded source and transforms these into inline attachments using ContentID. The body will be replaced.
    /// </summary>
    /// <returns>True if all images which look like they are base64-encoded have been successfully coverted, false if one or more fail.</returns>
    local procedure ConvertBase64ImagesToContentId(): Boolean
    var
        Base64ImgRegexPattern: DotNet Regex;
        Document: XmlDocument;
        ReadOptions: XmlReadOptions;
        WriteOptions: XmlWriteOptions;
        ImageElements: XmlNodeList;
        ImageElement: XmlNode;
        ImageElementAttribute: XmlAttribute;
        MemoryStream: DotNet MemoryStream;
        Encoding: DotNet Encoding;
        Base64ImgMatch: DotNet Match;
        String: DotNet String;
        MimeUtils: DotNet MimeUtils;
        MimeContentType: DotNet MimeContentType;
        MimeEntity: DotNet MimeEntity;
        DocumentSource: Text;
        ImageElementValue: Text;
        Base64Img: Text;
        Filename: Text;
        MediaType: Text;
        MediaSubtype: Text;
        ContentId: Text;
        Counter: Integer;
    begin
        if BodyBuilder.HtmlBody = '' then
            exit(true);

        ReadOptions.PreserveWhitespace(true);
        MemoryStream := MemoryStream.MemoryStream(Encoding.UTF8().GetBytes(BodyBuilder.HtmlBody));

        if not XmlDocument.ReadFrom(MemoryStream, ReadOptions, Document) then
            exit(false);

        // Get all <img> elements
        ImageElements := Document.GetDescendantElements('img');

        if ImageElements.Count() = 0 then
            exit(true); // No images to convert

        Base64ImgRegexPattern := Base64ImgRegexPattern.Regex('data:(.*);base64,(.*)');
        foreach ImageElement in ImageElements do begin
            if ImageElement.AsXmlElement().Attributes().Get('src', ImageElementAttribute) then begin
                ImageElementValue := ImageElementAttribute.Value();
                Base64ImgMatch := Base64ImgRegexPattern.Match(ImageElementValue);

                if not String.IsNullOrEmpty(Base64ImgMatch.Value) then begin
                    MediaType := Base64ImgMatch.Groups.Item(1).Value();
                    MediaSubtype := MediaType.Split('/').Get(2);
                    MediaType := MediaType.Split('/').Get(1);
                    Base64Img := Base64ImgMatch.Groups.Item(2).Value();

                    Filename := MimeUtils.GenerateMessageId() + '.jpg';

                    MimeContentType := MimeContentType.ContentType(MediaType, MediaSubtype);
                    MimeContentType.Name := Filename;

                    ContentId := CreateGuid();
                    ContentId := ContentId.Replace('-', '');
                    ContentId := DelChr(ContentId, '<>', '{}');

                    if TryAddLinkedResources(Filename, Base64Img, MimeContentType, MimeEntity) then begin
                        MimeEntity.ContentId := ContentId;
                        ImageElementAttribute.Value(StrSubstNo('cid:%1', ContentId));
                    end
                    else
                        exit(false);
                end;
            end;
        end;
        WriteOptions.PreserveWhitespace(true);
        Document.WriteTo(WriteOptions, DocumentSource);
        BodyBuilder.HtmlBody := DocumentSource;
        exit(true);
    end;

    /// <summary>
    /// Tries to load the xmlreader into the document.
    /// </summary>
    /// <returns>True if there is no error.</returns>
    [TryFunction]
    local procedure TryReadDocument(var Document: DotNet XmlDocument; Reader: DotNet XmlReader)
    begin
        Document.Load(Reader);
    end;

    /// <summary>
    /// Tries to add the base64 image to linked resources.
    /// </summary>
    /// <returns>True if there is no error./returns>
    [TryFunction]
    local procedure TryAddLinkedResources(Filename: Text; Base64Img: Text; ContentType: DotNet MimeContentType; var MimeEntity: DotNet MimeEntity)
    var
        Convert: DotNet Convert;
    begin
        MimeEntity := BodyBuilder.LinkedResources.Add(Filename, Convert.FromBase64String(Base64Img), ContentType);
    end;

    /// <summary>
    /// Gets the last error message that occured.
    /// </summary>
    /// <returns>The last error message, blank if there was no error.</returns>
    procedure GetLastSendMailErrorText(): Text
    begin
        exit(SendResult);
    end;

    [Scope('OnPrem')]
    procedure GetSmtpErrorCodeFromResponse(ErrorResponse: Text): Text
    var
        TextPosition: Integer;
    begin
        TextPosition := StrPos(ErrorResponse, 'failed with this message:');

        if TextPosition = 0 then
            exit('');

        ErrorResponse := CopyStr(ErrorResponse, TextPosition + StrLen('failed with this message:'));
        ErrorResponse := DelChr(ErrorResponse, '<', ' ');

        TextPosition := StrPos(ErrorResponse, ' ');
        if TextPosition <> 0 then
            ErrorResponse := CopyStr(ErrorResponse, 1, TextPosition - 1);

        exit(ErrorResponse);
    end;

    [Scope('OnPrem')]
    procedure GetFriendlyMessageFromSmtpErrorCode(ErrorCode: Text): Text
    begin
        case true of
            IsSmtpAuthErrorCode(ErrorCode):
                exit(EmailFailedCheckSetupMsg);
            IsSmtpRecipientErrorCode(ErrorCode):
                exit(EmailFailedCheckRecipientMsg);
            IsSmtpSendAsErrorCode(ErrorCode):
                exit(EmailFailedCheckSendAsMsg);
            ErrorCode = '':
                exit('');
            else
                exit(StrSubstNo(EmailFailedWithErrorCodeMsg, ErrorCode));
        end;
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleSMTPRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        RecRef: RecordRef;
    begin
        SMTPMailSetup.GetSetup;
        RecRef.GetTable(SMTPMailSetup);

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if SMTPMailSetup."SMTP Server" = '' then
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId, SMTPMailSetup.TableCaption, '', PAGE::"SMTP Mail Setup");
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSend(var SMTPMailSetup: Record "SMTP Mail Setup")
    begin
    end;

    local procedure ShowErrorNotification(ErrorMessage: Text; SmtpResult: Text)
    begin
        ShowErrorNotificationWithTroubleshooting(ErrorMessage, SmtpResult, false, false);
    end;

    local procedure ShowErrorNotificationWithTroubleshooting(ErrorMessage: Text; SmtpResult: Text; IncludeTroubleshooting: Boolean; IncludeSendAsTroubleshooting: Boolean)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
    begin
        if GuiAllowed then begin
            Notification.Message := ErrorMessage;
            Notification.Scope := NOTIFICATIONSCOPE::LocalScope;
            Notification.AddAction(DetailsActionLbl, CODEUNIT::"SMTP Mail", 'ShowNotificationDetail');
            if IncludeTroubleshooting then
                AddTroubleshootingLinksToNotification(Notification);
            if IncludeSendAsTroubleshooting then
                AddSendAsTroubleshootingLinksToNotification(Notification);
            Notification.SetData('Details', StrSubstNo(SmtpServerErrorMsg, SmtpResult));
            NotificationLifecycleMgt.SendNotification(Notification, SMTPMailSetup.RecordId);
        end;
        Error(SmtpServerErrorMsg, SmtpResult);
    end;

    procedure ShowNotificationDetail(Notification: Notification)
    begin
        Message(Notification.GetData('Details'));
    end;

    procedure GetO365SmtpServer(): Text[250]
    begin
        exit('smtp.office365.com')
    end;

    procedure GetOutlookSmtpServer(): Text[250]
    begin
        exit('smtp-mail.outlook.com')
    end;

    procedure GetGmailSmtpServer(): Text[250]
    begin
        exit('smtp.gmail.com')
    end;

    procedure GetYahooSmtpServer(): Text[250]
    begin
        exit('smtp.mail.yahoo.com')
    end;

    procedure GetDefaultSmtpPort(): Integer
    begin
        exit(587);
    end;

    procedure GetYahooSmtpPort(): Integer
    begin
        exit(465);
    end;

    procedure GetDefaultSmtpAuthType(): Integer
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        exit(SMTPMailSetup.Authentication::Basic);
    end;

    [Scope('OnPrem')]
    procedure OpenNotificationHyperlink(Notification: Notification)
    begin
        if Notification.HasData('TroubleshootingURL') then
            HyperLink(Notification.GetData('TroubleshootingURL'));
        if Notification.HasData('SendAsTroubleshootingURL') then
            HyperLink(Notification.GetData('SendAsTroubleshootingURL'));
    end;

    [Scope('OnPrem')]
    procedure AddTroubleshootingLinksToNotification(var TargetNotification: Notification)
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        // Currently the only troubleshooting scenario we have in the help is Multi-Factor Authentication.

        if EnvInfoProxy.IsInvoicing then
            TargetNotification.SetData('TroubleshootingURL', InvoicingTroubleshootingUrlTxt)
        else
            TargetNotification.SetData('TroubleshootingURL', BusinessCentralTroubleshootingUrlTxt);

        TargetNotification.AddAction(ReadMoreActionLbl, CODEUNIT::"SMTP Mail", 'OpenNotificationHyperlink');
    end;

    local procedure AddSendAsTroubleshootingLinksToNotification(var TargetNotification: Notification)
    begin
        TargetNotification.SetData('SendAsTroubleshootingURL', SendAsTroubleshootingUrlTxt);
        TargetNotification.AddAction(ReadMoreActionLbl, Codeunit::"SMTP Mail", 'OpenNotificationHyperlink');
    end;

    local procedure ApplyDefaultSmtpConnectionSettings(var SMTPMailSetupConfig: Record "SMTP Mail Setup")
    begin
        SMTPMailSetupConfig.Authentication := GetDefaultSmtpAuthType;
        SMTPMailSetupConfig."Secure Connection" := true;
    end;

    procedure ApplyOffice365Smtp(var SMTPMailSetupConfig: Record "SMTP Mail Setup")
    begin
        // This might be changed by the Microsoft Office 365 team.
        // Current source: http://technet.microsoft.com/library/dn554323.aspx
        SMTPMailSetupConfig."SMTP Server" := GetO365SmtpServer;
        SMTPMailSetupConfig."SMTP Server Port" := GetDefaultSmtpPort;
        ApplyDefaultSmtpConnectionSettings(SMTPMailSetupConfig);
    end;

    procedure ApplyOutlookSmtp(var SMTPMailSetupConfig: Record "SMTP Mail Setup")
    begin
        // This might be changed.
        SMTPMailSetupConfig."SMTP Server" := GetOutlookSmtpServer;
        SMTPMailSetupConfig."SMTP Server Port" := GetDefaultSmtpPort;
        ApplyDefaultSmtpConnectionSettings(SMTPMailSetupConfig);
    end;

    procedure ApplyGmailSmtp(var SMTPMailSetupConfig: Record "SMTP Mail Setup")
    begin
        // This might be changed.
        SMTPMailSetupConfig."SMTP Server" := GetGmailSmtpServer;
        SMTPMailSetupConfig."SMTP Server Port" := GetDefaultSmtpPort;
        ApplyDefaultSmtpConnectionSettings(SMTPMailSetupConfig);
    end;

    procedure ApplyYahooSmtp(var SMTPMailSetupConfig: Record "SMTP Mail Setup")
    begin
        // This might be changed.
        SMTPMailSetupConfig."SMTP Server" := GetYahooSmtpServer;
        SMTPMailSetupConfig."SMTP Server Port" := GetYahooSmtpPort;
        ApplyDefaultSmtpConnectionSettings(SMTPMailSetupConfig);
    end;

    procedure IsOffice365Setup(var SMTPMailSetupConfig: Record "SMTP Mail Setup"): Boolean
    begin
        if SMTPMailSetupConfig."SMTP Server" <> GetO365SmtpServer then
            exit(false);

        if SMTPMailSetupConfig."SMTP Server Port" <> GetDefaultSmtpPort then
            exit(false);

        exit(IsSmtpConnectionSetup(SMTPMailSetupConfig));
    end;

    procedure IsOutlookSetup(var SMTPMailSetupConfig: Record "SMTP Mail Setup"): Boolean
    begin
        if SMTPMailSetupConfig."SMTP Server" <> GetOutlookSmtpServer then
            exit(false);

        if SMTPMailSetupConfig."SMTP Server Port" <> GetDefaultSmtpPort then
            exit(false);

        exit(IsSmtpConnectionSetup(SMTPMailSetupConfig));
    end;

    procedure IsGmailSetup(var SMTPMailSetupConfig: Record "SMTP Mail Setup"): Boolean
    begin
        if SMTPMailSetupConfig."SMTP Server" <> GetGmailSmtpServer then
            exit(false);

        if SMTPMailSetupConfig."SMTP Server Port" <> GetDefaultSmtpPort then
            exit(false);

        exit(IsSmtpConnectionSetup(SMTPMailSetupConfig));
    end;

    procedure IsYahooSetup(var SMTPMailSetupConfig: Record "SMTP Mail Setup"): Boolean
    begin
        if SMTPMailSetupConfig."SMTP Server" <> GetYahooSmtpServer then
            exit(false);

        if SMTPMailSetupConfig."SMTP Server Port" <> GetYahooSmtpPort then
            exit(false);

        exit(IsSmtpConnectionSetup(SMTPMailSetupConfig));
    end;

    local procedure IsSmtpConnectionSetup(var SMTPMailSetupConfig: Record "SMTP Mail Setup"): Boolean
    begin
        if SMTPMailSetupConfig.Authentication <> GetDefaultSmtpAuthType then
            exit(false);

        if SMTPMailSetupConfig."Secure Connection" <> true then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsSmtpAuthErrorCode(ErrorCode: Text): Boolean
    begin
        // SMTP error codes as in RFC1893: https://www.ietf.org/rfc/rfc1893.txt
        // Unfortunately, this RFC does not define fine-grained guidelines, and as a consequence different email providers
        // have different policies on the error code to return in different cases.
        // - For wrong credentials, Office 365 returns 5.7.57:
        // | https://answers.microsoft.com/en-us/msoffice/forum/all/smtp-error/df466cf6-57a2-43a0-98a0-ece19f2e543d
        // | and provides a guide for App passwords generation in case of 2fa:
        // | https://support.office.com/en-us/article/Create-an-app-password-for-Office-365-3e7c860f-bda4-4441-a618-b53953ee1183
        // - For wrong credentials, Gmail returns 5.5.1: https://support.google.com/mail/forum/AAAAK7un8RUf6zMEadr69I
        // | and provides a guide for App passwords generation in case of 2fa:
        // | https://support.google.com/accounts/answer/6010255

        exit(ErrorCode in ['5.7.57', '5.5.1', '5.7.3']);
    end;

    [Scope('OnPrem')]
    procedure IsSmtpRecipientErrorCode(ErrorCode: Text): Boolean
    begin
        // SMTP error codes as in RFC1893: https://www.ietf.org/rfc/rfc1893.txt
        // Unfortunately, this RFC does not define fine-grained guidelines, and as a consequence different email providers
        // have different policies on the error code to return in different cases.
        // - In case of wrong recipient email address, Office365 returns 5.1.6:
        // | https://answers.microsoft.com/en-us/msoffice/forum/msoffice_o365admin-mso_dep365/[...]
        // | [...]mailprotectionoutlookcom-501-516-recipient/432ff507-21bc-4812-8cd1-496486b064db

        exit(ErrorCode in ['5.1.6']);
    end;

    [Scope('OnPrem')]
    procedure IsSmtpSendAsErrorCode(ErrorCode: Text): Boolean
    begin
        // SMTP error codes as in RFC1893: https://www.ietf.org/rfc/rfc1893.txt
        // Unfortunately, this RFC does not define fine-grained guidelines, and as a consequence different email providers
        // have different policies on the error code to return in different cases.
        // - In case of failure to send as, Office365 returns 5.2.0:
        exit(ErrorCode in ['5.2.0'])
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSend(var SendResult: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateMessage(var FromName: Text; var FromAddress: Text; var Recipients: List of [Text]; var Subject: Text; var Body: Text)
    begin
    end;
}
