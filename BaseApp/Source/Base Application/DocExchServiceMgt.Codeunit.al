codeunit 1410 "Doc. Exch. Service Mgt."
{
    Permissions = TableData "Sales Invoice Header" = m,
                  TableData "Sales Cr.Memo Header" = m;

    trigger OnRun()
    begin
    end;

    var
        MissingCredentialsQst: Label 'The %1 is missing the secret keys or tokens. Do you want to open the %1 window?', Comment = '%1=Doc. Exch. Service Setup';
        MissingCredentialsErr: Label 'The tokens and secret keys must be filled in the %1 window.', Comment = '%1 = Doc. Exch. Service Setup';
        TempBlobResponse: Codeunit "Temp Blob";
        TempBlobTrace: Codeunit "Temp Blob";
        Trace: Codeunit Trace;
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ConnectionSuccessMsg: Label 'The connection test was successful. The settings are valid.';
        DocSendSuccessMsg: Label 'The document was successfully sent to the document exchange service for processing.', Comment = '%1 is the actual document no.';
        DocUploadSuccessMsg: Label 'The document was successfully uploaded to the document exchange service for processing.', Comment = '%1 is the actual document no.';
        DocDispatchSuccessMsg: Label 'The document was successfully sent for dispatching.', Comment = '%1 is the actual document no.';
        DocDispatchFailedMsg: Label 'The document was not successfully dispatched. ', Comment = '%1 is the actual document no.';
        DocStatusOKMsg: Label 'The current status of the electronic document is %1.', Comment = '%1 is the returned value.';
        NotEnabledErr: Label 'The document exchange service is not enabled.';
        DocExchLinks: Codeunit "Doc. Exch. Links";
        XMLDOMMgt: Codeunit "XML DOM Management";
        GLBResponseInStream: InStream;
        CheckConnectionTxt: Label 'Check connection.';
        SendDocTxt: Label 'Send document.';
        GLBHttpStatusCode: DotNet HttpStatusCode;
        GLBResponseHeaders: DotNet NameValueCollection;
        GLBLastUsedGUID: Text;
        DispatchDocTxt: Label 'Dispatch document.';
        GetDocStatusTxt: Label 'Check document status.';
        GetDocsTxt: Label 'Get received documents.';
        LoggingConstTxt: Label 'Document exchange service.';
        GetDocErrorTxt: Label 'Check document dispatch errors.';
        MarkBusinessProcessedTxt: Label 'Mark as Business Processed.';
        DocIdImportedTxt: Label 'The document ID %1 is imported into incoming documents.', Comment = '%1 is the actual doc id.';
        FileInvalidTxt: Label 'The document ID %1 is not a valid XML format. ', Comment = '%1 is the actual doc id';
        GLBTraceLogEnabled: Boolean;
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        InvalidHeaderResponseMsg: Label 'The document exchange service did not return a document identifier.';
        CannotResendErr: Label 'You cannot send this electronic document because it is already delivered or in progress.';
        MalformedGuidErr: Label 'The document exchange service did not return a valid document identifier.';
        DocExchServiceDocumentSuccessfullySentTxt: Label 'The user successfully sent a document via the exchange service.', Locked = true;
        DocExchServiceDocumentSuccessfullyReceivedTxt: Label 'The user successfully received a document via the exchange service.', Locked = true;
        TelemetryCategoryTok: Label 'AL Document Exchange Service', Locked = true;

    procedure SetURLsToDefault(var DocExchServiceSetup: Record "Doc. Exch. Service Setup")
    begin
        with DocExchServiceSetup do begin
            "Sign-up URL" := 'https://go.tradeshift.com/register';
            "Service URL" := 'https://api.tradeshift.com/tradeshift/rest/external';
            "Sign-in URL" := 'https://go.tradeshift.com/login';
            "User Agent" := CopyStr(CompanyName + '/v1.0', 1, MaxStrLen("User Agent"));
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        VerifyPrerequisites(true);
        Initialize(GetCheckConnectionURL, 'GET', '');

        DocExchServiceSetup.Get();
        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(DocExchServiceSetup.RecordId, CheckConnectionTxt, '');

        LogActivitySucceeded(DocExchServiceSetup.RecordId, CheckConnectionTxt, ConnectionSuccessMsg);

        Message(ConnectionSuccessMsg);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'checkstatus', TempBlobTrace);
    end;

    [Scope('OnPrem')]
    procedure SendUBLDocument(DocVariant: Variant; FileName: Text): Text
    var
        DocRecRef: RecordRef;
    begin
        CheckServiceEnabled;

        DocRecRef.GetTable(DocVariant);

        CheckDocumentStatus(DocRecRef);

        Initialize(GetPostSalesURL(DocRecRef), 'POST', FileName);

        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        LogActivitySucceeded(DocRecRef.RecordId, SendDocTxt, DocSendSuccessMsg);

        DocExchLinks.UpdateDocumentRecord(DocRecRef, GLBLastUsedGUID, '');

        LogTelemetryDocumentSent;

        if GuiAllowed then
            Message(DocSendSuccessMsg);

        exit(GLBLastUsedGUID);
    end;

    [Scope('OnPrem')]
    procedure SendDocument(DocVariant: Variant; FileName: Text): Text
    var
        DocRecRef: RecordRef;
        DocIdentifier: Text;
    begin
        CheckServiceEnabled;

        DocIdentifier := GetGUID;
        DocRecRef.GetTable(DocVariant);

        CheckDocumentStatus(DocRecRef);

        PutDocument(FileName, DocIdentifier, DocRecRef);
        DispatchDocument(DocIdentifier, DocRecRef);

        LogTelemetryDocumentSent;

        if GuiAllowed then
            Message(DocSendSuccessMsg);

        exit(DocIdentifier);
    end;

    local procedure PutDocument(FileName: Text; DocIdentifier: Text; DocRecRef: RecordRef)
    begin
        Initialize(GetPUTDocURL(DocIdentifier), 'PUT', FileName);

        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        if not GLBHttpStatusCode.Equals(GLBHttpStatusCode.NoContent) then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        LogActivitySucceeded(DocRecRef.RecordId, SendDocTxt, DocUploadSuccessMsg);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'put', TempBlobTrace);
    end;

    local procedure DispatchDocument(DocOrigIdentifier: Text; DocRecRef: RecordRef)
    var
        DocIdentifier: Text;
        PlaceholderGuid: Guid;
    begin
        Initialize(GetDispatchDocURL(DocOrigIdentifier), 'POST', '');

        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, '');

        if not GLBHttpStatusCode.Equals(GLBHttpStatusCode.Created) then begin
            DocExchLinks.UpdateDocumentRecord(DocRecRef, '', DocOrigIdentifier);
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, DocDispatchFailedMsg);
        end;

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'dispatch', TempBlobTrace);

        DocIdentifier := GLBResponseHeaders.Get(GetDocumentIDKey);
        if not Evaluate(PlaceholderGuid, DocIdentifier) then
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, InvalidHeaderResponseMsg);
        DocExchLinks.UpdateDocumentRecord(DocRecRef, DocIdentifier, DocOrigIdentifier);

        LogActivitySucceeded(DocRecRef.RecordId, DispatchDocTxt, DocDispatchSuccessMsg);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentStatus(DocRecordID: RecordID; DocIdentifier: Text[50]; DocOrigIdentifier: Text[50]): Text
    var
        Errors: Text;
    begin
        CheckServiceEnabled;

        // Check for dispatch errors first
        if DocOrigIdentifier <> '' then
            if GetDocDispatchErrors(DocRecordID, DocOrigIdentifier, Errors) then
                if Errors <> '' then
                    exit('FAILED');

        // Check metadata
        if not GetDocumentMetadata(DocRecordID, DocIdentifier, Errors) then
            exit('PENDING');

        // If metadata exist it means doc has been dispatched
        exit(Errors);
    end;

    local procedure GetDocDispatchErrors(DocRecordID: RecordID; DocIdentifier: Text; var Errors: Text): Boolean
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled;

        Initialize(GetDispatchErrorsURL(DocIdentifier), 'GET', '');

        if not ExecuteWebServiceRequest then begin
            LogActivityFailed(DocRecordID, GetDocErrorTxt, '');
            exit(false);
        end;

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then begin
            LogActivityFailed(DocRecordID, GetDocErrorTxt, '');
            exit(false);
        end;

        Errors := XMLDOMMgt.FindNodeTextWithNamespace(XmlDoc.DocumentElement, GetErrorXPath,
            GetPrefix, GetApiNamespace);

        LogActivitySucceeded(DocRecordID, GetDocErrorTxt, Errors);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'dispatcherrors', TempBlobTrace);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentMetadata(DocRecordID: RecordID; DocIdentifier: Text[50]; var NewStatus: Text): Boolean
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled;
        NewStatus := '';

        Initialize(GetDocStatusURL(DocIdentifier), 'GET', '');

        if not ExecuteWebServiceRequest then begin
            LogActivityFailed(DocRecordID, GetDocStatusTxt, '');
            exit(false);
        end;

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then begin
            LogActivityFailed(DocRecordID, GetDocStatusTxt, '');
            exit(false);
        end;

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'checkstatus', TempBlobTrace);

        NewStatus := XMLDOMMgt.FindNodeTextWithNamespace(XmlDoc.DocumentElement, GetStatusXPath, GetPrefix, GetPublicNamespace);
        LogActivitySucceeded(DocRecordID, GetDocStatusTxt, StrSubstNo(DocStatusOKMsg, NewStatus));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ReceiveDocuments(ContextRecordID: RecordID)
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled;

        Initialize(GetRetrieveDocsURL, 'GET', '');

        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');

        ProcessReceivedDocs(ContextRecordID, XmlDoc);
    end;

    local procedure ProcessReceivedDocs(ContextRecordID: RecordID; XmlDocs: DotNet XmlDocument)
    var
        IncomingDocument: Record "Incoming Document";
        XMLRootNode: DotNet XmlNode;
        Node: DotNet XmlNode;
        DummyGuid: Guid;
        DocIdentifier: Text;
        Description: Text;
    begin
        XMLRootNode := XmlDocs.DocumentElement;

        foreach Node in XMLRootNode.ChildNodes do begin
            DocIdentifier := XMLDOMMgt.FindNodeTextWithNamespace(Node, GetDocumentIDXPath,
                GetPrefix, GetPublicNamespace);

            if not Evaluate(DummyGuid, DocIdentifier) then
                LogActivityFailedAndError(ContextRecordID, GetDocsTxt, MalformedGuidErr);
            if TryGetDocumentDescription(Node, Description) then;
            if DelChr(Description, '<>', ' ') = '' then
                Description := DocIdentifier;
            GetOriginalDocument(ContextRecordID, DocIdentifier);
            CreateIncomingDocEntry(IncomingDocument, ContextRecordID, DocIdentifier, Description);

            if not MarkDocBusinessProcessed(DocIdentifier) then begin
                IncomingDocument.Delete();
                LogActivityFailed(ContextRecordID, MarkBusinessProcessedTxt, '');
            end else
                LogActivitySucceeded(ContextRecordID, MarkBusinessProcessedTxt, StrSubstNo(DocIdImportedTxt, DocIdentifier));
            Commit();

            IncomingDocument.Find;
            LogTelemetryDocumentReceived;
            OnAfterIncomingDocReceivedFromDocExch(IncomingDocument);
        end;
    end;

    local procedure GetOriginalDocument(ContextRecordID: RecordID; DocIdentifier: Text)
    begin
        CheckServiceEnabled;

        Initialize(GetRetrieveOriginalDocIDURL(DocIdentifier), 'GET', '');

        // If can't get the original, it means it was not a 2-step. Get the actual TS-UBL
        if not ExecuteWebServiceRequest then
            GetDocument(ContextRecordID, DocIdentifier);
    end;

    local procedure GetDocument(ContextRecordID: RecordID; DocIdentifier: Text)
    begin
        CheckServiceEnabled;

        Initialize(GetRetrieveDocIDURL(DocIdentifier), 'GET', '');

        if not ExecuteWebServiceRequest then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');
    end;

    [TryFunction]
    local procedure MarkDocBusinessProcessed(DocIdentifier: Text)
    begin
        CheckServiceEnabled;

        Initialize(GetSetTagURL(DocIdentifier), 'PUT', '');

        ExecuteWebServiceRequest;
    end;

    local procedure CreateIncomingDocEntry(var IncomingDocument: Record "Incoming Document"; ContextRecordID: RecordID; DocIdentifier: Text; Description: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        XmlDoc: DotNet XmlDocument;
    begin
        // Assert response is XML
        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, StrSubstNo(FileInvalidTxt, DocIdentifier));

        IncomingDocument.CreateIncomingDocument(
          CopyStr(Description, 1, MaxStrLen(IncomingDocument.Description)), GetExternalDocURL(DocIdentifier));

        // set received XML as main attachment and extract additional ones as secondary attachments
        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, DocIdentifier, 'xml', GLBResponseInStream);
        ProcessAttachments(IncomingDocument, XmlDoc);
    end;

    local procedure ProcessAttachments(var IncomingDocument: Record "Incoming Document"; XmlDoc: DotNet XmlDocument)
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
    begin
        XMLDOMMgt.FindNodesWithNamespace(XmlDoc.DocumentElement, GetEmbeddedDocXPath, GetPrefix, GetCBCNamespace,
          NodeList);
        foreach Node in NodeList do
            ExtractAdditionalAttachment(IncomingDocument, Node);
    end;

    local procedure ExtractAdditionalAttachment(var IncomingDocument: Record "Incoming Document"; Node: DotNet XmlNode)
    var
        FileMgt: Codeunit "File Management";
        Convert: DotNet Convert;
        TempFile: DotNet File;
        FilePath: Text;
        FileName: Text;
    begin
        FileName := XMLDOMMgt.GetAttributeValue(Node, 'filename');
        FilePath := FileMgt.ServerTempFileName(FileMgt.GetExtension(FileName));
        FileMgt.IsAllowedPath(FilePath, false);
        TempFile.WriteAllBytes(FilePath, Convert.FromBase64String(Node.InnerText));
        IncomingDocument.AddAttachmentFromServerFile(FileName, FilePath);
    end;

    local procedure Initialize(URL: Text; Method: Text[6]; BodyFilePath: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        OAuthAuthorization: DotNet OAuthAuthorization;
        OAuthConsumer: DotNet Consumer;
        OAuthToken: DotNet Token;
    begin
        CheckCredentials;

        with DocExchServiceSetup do begin
            Get;
            OAuthConsumer := OAuthConsumer.Consumer(GetPassword("Consumer Key"), GetPassword("Consumer Secret"));
            OAuthToken := OAuthToken.Token(GetPassword(Token), GetPassword("Token Secret"));
            OAuthAuthorization := OAuthAuthorization.OAuthAuthorization(OAuthConsumer, OAuthToken);
        end;

        Clear(HttpWebRequestMgt);
        HttpWebRequestMgt.Initialize(URL);
        HttpWebRequestMgt.SetMethod(Method);
        HttpWebRequestMgt.AddHeader('Authorization', OAuthAuthorization.GetAuthorizationHeader(URL, Method));

        SetDefaults(BodyFilePath);
    end;

    local procedure SetDefaults(BodyFilePath: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        HttpWebRequestMgt.SetContentType('text/xml');
        HttpWebRequestMgt.SetReturnType('text/xml');
        HttpWebRequestMgt.SetUserAgent(GetUserAgent);
        HttpWebRequestMgt.AddHeader('X-Tradeshift-TenantId', GetTenantID);
        HttpWebRequestMgt.AddHeader('Accept-Encoding', 'utf-8');
        HttpWebRequestMgt.AddBody(BodyFilePath);

        // Set tracing
        DocExchServiceSetup.Get();
        GLBTraceLogEnabled := DocExchServiceSetup."Log Web Requests";
        HttpWebRequestMgt.SetTraceLogEnabled(DocExchServiceSetup."Log Web Requests");
    end;

    procedure CheckCredentials()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if not VerifyPrerequisites(false) then
            if Confirm(StrSubstNo(MissingCredentialsQst, DocExchServiceSetup.TableCaption), true) then begin
                Commit();
                PAGE.RunModal(PAGE::"Doc. Exch. Service Setup", DocExchServiceSetup);
                if not VerifyPrerequisites(false) then
                    Error(MissingCredentialsErr, DocExchServiceSetup.TableCaption);
            end else
                Error(MissingCredentialsErr, DocExchServiceSetup.TableCaption);
    end;

    [TryFunction]
    local procedure ExecuteWebServiceRequest()
    begin
        Clear(TempBlobResponse);
        TempBlobResponse.CreateInStream(GLBResponseInStream);

        if not GuiAllowed then
            HttpWebRequestMgt.DisableUI;

        if not HttpWebRequestMgt.GetResponse(GLBResponseInStream, GLBHttpStatusCode, GLBResponseHeaders) then
            HttpWebRequestMgt.ProcessFaultXMLResponse('', GetErrorXPath, GetPrefix, GetApiNamespace);
    end;

    procedure CheckServiceEnabled()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        DocExchServiceSetup.Get();
        if not DocExchServiceSetup.Enabled then
            Error(NotEnabledErr);
    end;

    local procedure CheckDocumentStatus(DocRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocRecRef.SetTable(SalesInvoiceHeader);
                    if SalesInvoiceHeader."Document Exchange Status" in
                       [SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
                        SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocRecRef.SetTable(SalesCrMemoHeader);
                    if SalesCrMemoHeader."Document Exchange Status" in
                       [SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        SalesCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
                        SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocRecRef.SetTable(ServiceInvoiceHeader);
                    if ServiceInvoiceHeader."Document Exchange Status" in
                       [ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        ServiceInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
                        ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocRecRef.SetTable(ServiceCrMemoHeader);
                    if ServiceCrMemoHeader."Document Exchange Status" in
                       [ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        ServiceCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
                        ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    local procedure GetTenantID(): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        with DocExchServiceSetup do begin
            Get;
            exit(GetPassword("Doc. Exch. Tenant ID"));
        end;
    end;

    local procedure GetUserAgent(): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        with DocExchServiceSetup do begin
            Get;
            TestField("User Agent");
            exit("User Agent");
        end;
    end;

    local procedure GetFullURL(PartialURL: Text): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        with DocExchServiceSetup do begin
            Get;
            TestField("Service URL");
            exit("Service URL" + PartialURL);
        end;
    end;

    local procedure GetCheckConnectionURL(): Text
    begin
        exit(GetFullURL('/account/info'));
    end;

    local procedure GetPostSalesURL(DocRecRef: RecordRef): Text
    begin
        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header", DATABASE::"Service Invoice Header":
                exit(GetPostSalesInvURL);
            DATABASE::"Sales Cr.Memo Header", DATABASE::"Service Cr.Memo Header":
                exit(GetPostSalesCrMemoURL);
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    local procedure GetPostSalesInvURL(): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/dispatcher?documentId=%1&documentProfileId=tradeshift.invoice.ubl.1.0',
              GetGUID)));
    end;

    local procedure GetPostSalesCrMemoURL(): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/dispatcher?documentId=%1&documentProfileId=tradeshift.creditnote.ubl.1.0',
              GetGUID)));
    end;

    local procedure GetDocStatusURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/metadata', DocIdentifier)));
    end;

    local procedure GetPUTDocURL(FileName: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/file?directory=outbox', FileName)));
    end;

    local procedure GetDispatchDocURL(FileName: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/dispatcher?directory=outbox', FileName)));
    end;

    local procedure GetDispatchErrorsURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/errors', DocIdentifier)));
    end;

    local procedure GetRetrieveDocsURL(): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents?stag=inbox&withouttag=BusinessDelivered&limit=%1', GetChunckSize)));
    end;

    local procedure GetRetrieveDocIDURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1', DocIdentifier)));
    end;

    local procedure GetRetrieveOriginalDocIDURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/original', DocIdentifier)));
    end;

    local procedure GetSetTagURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/tags/BusinessDelivered', DocIdentifier)));
    end;

    local procedure GetGUID(): Text
    begin
        GLBLastUsedGUID := DelChr(DelChr(Format(CreateGuid), '=', '{'), '=', '}');

        exit(GLBLastUsedGUID);
    end;

    local procedure GetChunckSize(): Integer
    begin
        exit(100);
    end;

    local procedure GetApiNamespace(): Text
    begin
        exit('http://tradeshift.com/api/1.0');
    end;

    local procedure GetPublicNamespace(): Text
    begin
        exit('http://tradeshift.com/api/public/1.0');
    end;

    local procedure GetCBCNamespace(): Text
    begin
        exit('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure GetErrorXPath(): Text
    begin
        exit(StrSubstNo('//%1:Message', GetPrefix));
    end;

    local procedure GetStatusXPath(): Text
    begin
        exit(StrSubstNo('//%1:DeliveryState', GetPrefix));
    end;

    local procedure GetDocumentIDXPath(): Text
    begin
        exit(StrSubstNo('.//%1:DocumentId', GetPrefix));
    end;

    local procedure GetDocumentTypeXPath(): Text
    begin
        exit(StrSubstNo('.//%1:DocumentType', GetPrefix));
    end;

    local procedure GetDocumentIDForDescriptionXPath(): Text
    begin
        exit(StrSubstNo('.//%1:ID', GetPrefix));
    end;

    local procedure GetEmbeddedDocXPath(): Text
    begin
        exit(StrSubstNo('//%1:EmbeddedDocumentBinaryObject', GetPrefix));
    end;

    local procedure GetPrefix(): Text
    begin
        exit('newnamespace');
    end;

    local procedure GetDocumentIDKey(): Text
    begin
        exit('X-Tradeshift-DocumentId');
    end;

    [TryFunction]
    local procedure TryGetDocumentDescription(Node: DotNet XmlNode; var Description: Text)
    var
        SrchNode: DotNet XmlNode;
    begin
        Description := '';
        XMLDOMMgt.FindNodeWithNamespace(Node, GetDocumentTypeXPath, GetPrefix,
          GetPublicNamespace, SrchNode);
        Description := MapDocumentType(XMLDOMMgt.GetAttributeValue(SrchNode, 'type'));
        Description += ' ' + XMLDOMMgt.FindNodeTextWithNamespace(Node, GetDocumentIDForDescriptionXPath,
            GetPrefix, GetPublicNamespace);
    end;

    local procedure MapDocumentType(DocType: Text): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case DocType of
            'invoice':
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
            'creditnote':
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
            else
                exit('');
        end;
        exit(Format(PurchaseHeader."Document Type"));
    end;

    local procedure LogActivitySucceeded(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Success, LoggingConstTxt,
          ActivityDescription, ActivityMessage);
    end;

    local procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityMessageVar: Text;
    begin
        ActivityMessageVar := ActivityMessage;
        LogActivityFailedCommon(RelatedRecordID, ActivityDescription, ActivityMessageVar);
    end;

    local procedure LogActivityFailedAndError(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    begin
        LogActivityFailedCommon(RelatedRecordID, ActivityDescription, ActivityMessage);
        if DelChr(ActivityMessage, '<>', ' ') <> '' then
            Error(ActivityMessage);
    end;

    local procedure LogActivityFailedCommon(RelatedRecordID: RecordID; ActivityDescription: Text; var ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityMessage := GetLastErrorText + ' ' + ActivityMessage;
        ClearLastError;

        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Failed, LoggingConstTxt,
          ActivityDescription, ActivityMessage);

        if ActivityMessage = '' then
            ActivityLog.SetDetailedInfoFromStream(GLBResponseInStream);

        Commit();
    end;

    procedure EnableTraceLog(NewTraceLogEnabled: Boolean)
    begin
        GLBTraceLogEnabled := NewTraceLogEnabled;
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleVANRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        RecRef: RecordRef;
    begin
        if not DocExchServiceSetup.Get then begin
            DocExchServiceSetup.Init();
            DocExchServiceSetup.Insert();
        end;

        RecRef.GetTable(DocExchServiceSetup);

        if DocExchServiceSetup.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        with DocExchServiceSetup do
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, TableCaption, "Service URL", PAGE::"Doc. Exch. Service Setup");
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnAfterIncomingDocReceivedFromDocExch(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    procedure GetExternalDocURL(DocID: Text): Text
    var
        URLPart: Text;
    begin
        URLPart := 'www';
        if StrPos(GetFullURL(''), 'sandbox') > 0 then
            URLPart := 'sandbox';

        exit(StrSubstNo('https://%1.tradeshift.com/app/Tradeshift.Migration#::conversation/view/%2::', URLPart, DocID));
    end;

    procedure VerifyPrerequisites(ShowFailure: Boolean): Boolean
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        with DocExchServiceSetup do
            if not (Get and HasPassword("Consumer Key") and HasPassword("Consumer Secret") and
                    HasPassword(Token) and HasPassword("Token Secret") and HasPassword("Doc. Exch. Tenant ID"))
            then
                if ShowFailure then
                    Error(MissingCredentialsErr, TableCaption);
        exit(true)
    end;

    local procedure LogTelemetryDocumentSent()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        DocExchServiceSetup.Get();
        SendTraceTag('000089R', TelemetryCategoryTok, VERBOSITY::Normal,
          DocExchServiceDocumentSuccessfullySentTxt, DATACLASSIFICATION::SystemMetadata);
        SendTraceTag('000089S', TelemetryCategoryTok, VERBOSITY::Normal,
          DocExchServiceSetup."Service URL", DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure LogTelemetryDocumentReceived()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        DocExchServiceSetup.Get();
        SendTraceTag('000089T', TelemetryCategoryTok, VERBOSITY::Normal,
          DocExchServiceDocumentSuccessfullyReceivedTxt, DATACLASSIFICATION::SystemMetadata);
        SendTraceTag('000089U', TelemetryCategoryTok, VERBOSITY::Normal,
          DocExchServiceSetup."Service URL", DATACLASSIFICATION::SystemMetadata);
    end;
}

