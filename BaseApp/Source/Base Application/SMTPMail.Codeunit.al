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
        SmtpConnectTelemetryErrorMsg: Label 'Unable to connect to SMTP server. Smtp server: %1, server port: %2, error code: %3', Comment = '%1=the smtp server, %2=the server port, %3=error code';
        SmtpAuthenticateTelemetryErrorMsg: Label 'Unable to connect to SMTP server. Authentication email from: %1, smtp server: %2, server port: %3, error code: %4', Comment = '%1=the from address, %2=the smtp server, %3=the server port, %4=error code';
        SmtpSendTelemetryErrorMsg: Label 'Unable to send email. Login: %1, send from: %2, send to: %3, send cc: %4, send bcc: %5. send as: %6, %7, error code: %8', Comment = '%1=the login address, %2=the from address, %3=the to address, %4=the cc address, %5=the bcc address, %6=is send as enabled, %7=the send as email, %8=error code';
        SmtpConnectedTelemetryMsg: Label 'Connected to SMTP server. Smtp server: %1, server port: %2', Comment = '%1=the smtp server, %2=the server port';
        SmtpAuthenticateTelemetryMsg: Label 'Authenticated to SMTP server.  Authentication email from: %1, smtp server: %2, server port: %3', Comment = '%1=the from address, %2=the smtp server, %3=the server port';
        SmtpSendTelemetryMsg: Label 'Email sent.';
        FromEmailParseFailureErr: Label 'The From address %1 could not be parsed correctly.', Comment = '%1=The email address';
        EmailParseFailureErr: Label 'The address %1 could not be parsed correctly.', Comment = '%1=The email address';
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
    [TryFunction]
    procedure AddFrom(FromName: Text; FromAddress: Text)
    var
        MailManagement: Codeunit "Mail Management";
        InternetAddress: DotNet InternetAddress;
    begin
        if MailManagement.CheckValidEmailAddress(FromAddress) and InternetAddress.TryParse(FromAddress, InternetAddress) then begin
            InternetAddress.Name(FromName);
            Email.From().Add(InternetAddress);
        end else
            Error(FromEmailParseFailureErr, FromAddress);
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
        MailManagement: Codeunit "Mail Management";
        InternetAddress: DotNet InternetAddress;
        Address: Text;
    begin
        foreach Address in Addresses do begin
            if MailManagement.CheckValidEmailAddress(Address) and InternetAddress.TryParse(Address, InternetAddress) then
                InternetAddressList.Add(InternetAddress)
            else
                Error(EmailParseFailureErr, Address);
        end;
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
    begin
        if not TryParseInternetAddressList(InternetAddressList, Recipients) then begin
            SendTraceTag('0000B5M', SmtpCategoryLbl, Verbosity::Error, StrSubstNo(RecipientErr, FormatListToString(Recipients, ';', true)), DataClassification::EndUserPseudonymousIdentifiers);
            Error(RecipientErr, FormatListToString(Recipients, ';', false));
        end;
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
    [Obsolete('This method is obsolete. A new CreateMessage overload is available, with the following parameters (FromName: Text; FromAddress: Text; Recipients: List of [Text]; Subject: Text; Body: Text).', '15.0')]
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
    /// This overload always uses HTML formatting for the body text.
    /// </summary>
    /// <param name="FromName">The name of the email sender</param>
    /// <param name="FromAddress">The address of the default sender or, when using the Send As or Send on Behalf functionality, the address of the substitute sender</param>
    /// <param name="Recipients">The recipient(s) of the mail</param>
    /// <param name="Subject">The subject of the mail</param>
    /// <param name="Body">The body of the mail</param>
    [TryFunction]
    procedure CreateMessage(FromName: Text; FromAddress: Text; Recipients: List of [Text]; Subject: Text; Body: Text)
    begin
        CreateMessage(FromName, FromAddress, Recipients, Subject, Body, true);
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
        SMTPMailInternals: Codeunit "SMTP Mail Internals";
        MailboxAddress: DotNet MimeMailboxAddress;
    begin
        Initialize();
        OnBeforeCreateMessage(FromName, FromAddress, Recipients, Subject, Body);

        SendResult := '';

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
        SMTPMailInternals.OnAfterCreateMessage(Email, BodyBuilder);
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
        AddressesList: List of [Text];
        FromAddresses: Text;
        ToAddresses: Text;
        CcAddresses: Text;
        BccAddresses: Text;
    begin
        SendResult := '';
        OnBeforeSend(SmtpMailSetup);
        ClearLastError();
        Result := TryConnect();
        if not Result then begin
            SendResult := GetLastErrorText();
            SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
            SendTraceTag('00009UM', SmtpCategoryLbl, Verbosity::Error,
                StrSubstNo(SmtpConnectTelemetryErrorMsg,
                    SmtpMailSetup."SMTP Server",
                    SmtpMailSetup."SMTP Server Port",
                    SMTPErrorCode),
                DataClassification::OrganizationIdentifiableInformation);
        end
        else begin
            SendTraceTag('00009UN', SmtpCategoryLbl, Verbosity::Normal,
                StrSubstNo(SmtpConnectedTelemetryMsg,
                    SmtpMailSetup."SMTP Server",
                    SmtpMailSetup."SMTP Server Port"),
                DataClassification::OrganizationIdentifiableInformation);

            if SmtpMailSetup.Authentication <> SmtpMailSetup.Authentication::Anonymous then begin
                ClearLastError();
                Result := TryAuthenticate();

                if not Result then begin
                    SendResult := GetLastErrorText();
                    SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);
                    SendTraceTag('00009XS', SmtpCategoryLbl, Verbosity::Error,
                        StrSubstNo(SmtpAuthenticateTelemetryErrorMsg,
                            ObsfuscateEmailAddress(SmtpMailSetup."User ID"),
                            SmtpMailSetup."SMTP Server",
                            SmtpMailSetup."SMTP Server Port",
                            SMTPErrorCode),
                        DataClassification::EndUserPseudonymousIdentifiers);
                end
                else begin
                    SendTraceTag('00009XT', SmtpCategoryLbl, Verbosity::Normal,
                        StrSubstNo(SmtpAuthenticateTelemetryMsg,
                            ObsfuscateEmailAddress(SmtpMailSetup."User ID"),
                            SmtpMailSetup."SMTP Server",
                            SmtpMailSetup."SMTP Server Port"),
                        DataClassification::EndUserPseudonymousIdentifiers);
                end;
            end;

            if Result then begin
                Email.Body := BodyBuilder.ToMessageBody();
                ClearLastError();
                Result := TrySend();
                if not Result then begin
                    SendResult := GetLastErrorText();
                    SMTPErrorCode := GetSmtpErrorCodeFromResponse(SendResult);

                    InternetAddressListToList(Email.From(), AddressesList);
                    FromAddresses := FormatListToString(AddressesList, ';', true);
                    AddressesList.RemoveRange(1, AddressesList.Count());
                    InternetAddressListToList(Email."To"(), AddressesList);
                    ToAddresses := FormatListToString(AddressesList, ';', true);
                    AddressesList.RemoveRange(1, AddressesList.Count());
                    InternetAddressListToList(Email."Cc"(), AddressesList);
                    CcAddresses := FormatListToString(AddressesList, ';', true);
                    AddressesList.RemoveRange(1, AddressesList.Count());
                    InternetAddressListToList(Email."Bcc"(), AddressesList);
                    BccAddresses := FormatListToString(AddressesList, ';', true);

                    SendTraceTag('00009UO', SmtpCategoryLbl, Verbosity::Error,
                    StrSubstNo(SmtpSendTelemetryErrorMsg,
                        ObsfuscateEmailAddress(SmtpMailSetup."User ID"),
                        FromAddresses,
                        ToAddresses,
                        CcAddresses,
                        BccAddresses,
                        SmtpMailSetup."Allow Sender Substitution",
                        SmtpMailSetup."Send As",
                        SMTPErrorCode),
                    DataClassification::EndUserPseudonymousIdentifiers);
                end
                else
                    SendTraceTag('00009UP', SmtpCategoryLbl, Verbosity::Normal, SmtpSendTelemetryMsg,
                    DataClassification::SystemMetadata);
            end;
            SmtpClient.Disconnect(true, CancellationToken);
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

        ClearLastError();
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
    [Obsolete('Please call CheckValidEmailAddresses from the Mail Management codeunit directly.', '16.0')]
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
    local procedure FormatListToString(List: List of [Text]; Delimiter: Text; Obfuscate: Boolean) String: Text
    var
        Value: Text;
        Address: Text;
        Counter: Integer;
    begin
        if List.Count() > 0 then begin
            if Obfuscate then
                String += ObsfuscateEmailAddress(List.Get(1))
            else
                String += List.Get(1);

            for Counter := 2 to List.Count() do begin
                Address := List.Get(Counter);
                if Obfuscate then
                    Address := ObsfuscateEmailAddress(Address);
                String += StrSubstNo('%1 %2', Delimiter, Address);
            end;
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

                    ContentId := Format(CreateGuid(), 0, 3);

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
    local procedure TryAddLinkedResources(Filename: Text; Base64Img: Text; ContentType: DotNet MimeContentType;

    var
        MimeEntity: DotNet MimeEntity)
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

    local procedure InternetAddressListToList(IAList: DotNet InternetAddressList;
    var
        Addresses: List of [Text])
    var
        Mailbox: DotNet MimeMailboxAddress;
    begin
        foreach Mailbox in IAList do begin
            Addresses.Add(Mailbox.Address);
        end;
    end;

    local procedure ObsfuscateEmailAddress(Email: Text) ObfuscatedEmail: Text
    var
        Username: Text;
        Domain: Text;
        Position: Integer;
    begin
        Position := StrPos(Email, '@');
        if Position > 0 then begin
            Username := DelStr(Email, Position, StrLen(Email) - Position);
            Domain := DelStr(Email, 1, Position);

            ObfuscatedEmail := StrSubstNo('%1*%2@%3', Username.Substring(1, 1), Username.Substring(Position - 1, 1), Domain);
        end
        else begin
            if StrLen(Email) > 0 then
                ObfuscatedEmail := Email.Substring(1, 1);

            ObfuscatedEmail += '* (Not a valid email)';
        end;
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
