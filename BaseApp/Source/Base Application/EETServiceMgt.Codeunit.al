codeunit 31120 "EET Service Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        WebServiceURLTxt: Label 'https://prod.eet.cz/eet/services/EETServiceSOAP/v3', Locked = true;
        WebServicePGURLTxt: Label 'https://pg.eet.cz/eet/services/EETServiceSOAP/v3', Locked = true;
        EETNamespaceTxt: Label 'http://fs.mfcr.cz/eet/schema/v3', Locked = true;
        SoapNamespaceTxt: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        SecurityUtilityNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd', Locked = true;
        SecurityExtensionNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;
        SecurityEncodingTypeBase64BinaryTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary', Locked = true;
        SecurityValueTypeX509V3Txt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3', Locked = true;
        SignatureMethodRSASHA256Txt: Label 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256', Locked = true;
        DigestMethodSHA256Txt: Label 'http://www.w3.org/2001/04/xmlenc#sha256', Locked = true;
        CanonicalizationMethodTxt: Label 'XmlDsigExcC14NTransformUrl', Locked = true;
        ReferenceTransformTxt: Label 'XmlDsigExcC14NTransform', Locked = true;
        BodyPathTxt: Label '/soap:Envelope/soap:Body', Locked = true;
        BinarySecurityTokenPathTxt: Label '//wsse:BinarySecurityToken', Locked = true;
        SecurityPathTxt: Label '//wsse:Security', Locked = true;
        TempErrorMessage: Record "Error Message" temporary;
        FIKControlCode: Text;
        ErrorPathTxt: Label '//eet:Chyba', Locked = true;
        WarningPathTxt: Label '//eet:Varovani', Locked = true;
        ConfirmationPathTxt: Label '//eet:Potvrzeni', Locked = true;
        HeaderPathTxt: Label '//eet:Hlavicka', Locked = true;
        PKPCipherTxt: Label 'RSA2048', Locked = true;
        PKPDigestTxt: Label 'SHA256', Locked = true;
        PKPEncodingTxt: Label 'base64', Locked = true;
        BKPDigestTxt: Label 'SHA1', Locked = true;
        BKPEncodingTxt: Label 'base16', Locked = true;
        ResponseContentError: Text;
        ResponseContentErrorCode: Text;
        VerificationMode: Boolean;
        EETNamespacePrefixTxt: Label 'eet', Locked = true;
        ErrorCodeTxt: Label 'Error Code: %1', Comment = '%1 = error code';
        WarningCodeTxt: Label 'Warning Code: %1', Comment = '%1 = warning code';
        SignatureNotValidErr: Label 'Signature of received data message is not valid.';
        CertificateNotExistErr: Label 'There is not valid certificate %1.', Comment = '%1 = certificate code';
        XMLFormatErr: Label 'XML Format of response is not supported.';
        MessageUUIDNotMatchErr: Label 'Message UUID received in response doesn''t match to Message UUID in EET Entry.';
        BKPControlCodeNotMatchErr: Label 'BKP control code received in response doesn''t match to BKP control code in EET Entry.';
        EETCertificateNotValidErr: Label 'Certificate of EET service is not valid.';
        VATRegistrationErr: Label 'VAT Registration No. %1 doesn''t match to VAT Registration No. %2 in certificate.', Comment = '%1=VAT Registration Number of company, %2=VAT Registration Number of certificate';
        EmptyBusinessPremisesIdErr: Label 'Business Premises Id must not be empty.';
        EmptyCashRegisterNoErr: Label 'Cash Register No. must not be empty.';
        EmptyReceiptSerialNoErr: Label 'Receipt Serial No. must not be empty.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure SendRegisteredSalesDataMessage(EETEntry: Record "EET Entry")
    var
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        XmlDoc: DotNet XmlDocument;
        RequestContentXmlDoc: DotNet XmlDocument;
        ResponseContentXmlDoc: DotNet XmlDocument;
        ResponseXmlDoc: DotNet XmlDocument;
    begin
        Initialize;

        LoadValidCertificate(EETEntry.GetCertificateCode, DotNetX509Certificate2);
        if not CheckEETEntry(EETEntry, DotNetX509Certificate2) then
            Error('');

        CreateXmlDocument(EETEntry, XmlDoc);
        CreateSoapRequest(XmlDoc, DotNetX509Certificate2, RequestContentXmlDoc);
        SendSoapRequest(RequestContentXmlDoc, ResponseXmlDoc, ResponseContentXmlDoc);

        if HasResponseContentError(ResponseContentXmlDoc) then
            ProcessResponseContentError(ResponseContentXmlDoc);

        if HasResponseContentWarnings(ResponseContentXmlDoc) then
            ProcessResponseContentWarnings(ResponseContentXmlDoc);

        CheckResponseSecurity(ResponseXmlDoc);
        CheckResponseContentHeader(ResponseContentXmlDoc, EETEntry);
        ProcessResponseContent(ResponseContentXmlDoc);

        if HasErrors then
            Error('');
    end;

    local procedure CheckEETEntry(EETEntry: Record "EET Entry"; DotNetX509Certificate2: Codeunit DotNet_X509Certificate2): Boolean
    var
        CompanyInformation: Record "Company Information";
        CertificateManagement: Codeunit "Certificate Management";
        CommonName: Text;
    begin
        CompanyInformation.Get();
        CommonName := CertificateManagement.GetCertificateCommonName(DotNetX509Certificate2);
        if CompanyInformation."VAT Registration No." <> CommonName then
            LogMessage(TempErrorMessage."Message Type"::Error, '',
              StrSubstNo(VATRegistrationErr, CompanyInformation."VAT Registration No.", CommonName));
        if EETEntry.GetBusinessPremisesId = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyBusinessPremisesIdErr);
        if EETEntry.GetCashRegisterNo = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyCashRegisterNoErr);
        if EETEntry."Receipt Serial No." = '' then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EmptyReceiptSerialNoErr);
        exit(not HasErrors);
    end;

    local procedure LoadValidCertificate("Code": Code[10]; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateCZCode: Record "Certificate CZ Code";
    begin
        CertificateCZCode.Get(Code);
        if not CertificateCZCode.LoadValidCertificate(IsolatedCertificate) then
            Error(CertificateNotExistErr, Code);
        IsolatedCertificate.GetDotNetX509Certificate2(DotNetX509Certificate2);
        OnAfterLoadValidCertificate(IsolatedCertificate);
    end;

    local procedure CreateXmlDocument(EETEntry: Record "EET Entry"; var XmlDoc: DotNet XmlDocument)
    var
        CompanyInformation: Record "Company Information";
        EETServiceSetup: Record "EET Service Setup";
        XMLDOMMgt: Codeunit "XML DOM Management";
        SalesXmlNode: DotNet XmlNode;
        HeaderXmlNode: DotNet XmlNode;
        DataXmlNode: DotNet XmlNode;
        ControlCodesXmlNode: DotNet XmlNode;
        PKPControlCodeXmlNode: DotNet XmlNode;
        BKPControlCodeXmlNode: DotNet XmlNode;
    begin
        XmlDoc := XmlDoc.XmlDocument;
        with XMLDOMMgt do begin
            AddRootElementWithPrefix(XmlDoc, 'Trzba', EETNamespacePrefixTxt, EETNamespaceTxt, SalesXmlNode);
            AddElementWithPrefix(SalesXmlNode, 'Hlavicka', '', EETNamespacePrefixTxt, EETNamespaceTxt, HeaderXmlNode);
            AddElementWithPrefix(SalesXmlNode, 'Data', '', EETNamespacePrefixTxt, EETNamespaceTxt, DataXmlNode);
            AddElementWithPrefix(SalesXmlNode, 'KontrolniKody', '', EETNamespacePrefixTxt, EETNamespaceTxt, ControlCodesXmlNode);
            AddElementWithPrefix(ControlCodesXmlNode, 'pkp',
              EETEntry.GetSignatureCode, EETNamespacePrefixTxt, EETNamespaceTxt, PKPControlCodeXmlNode);
            AddElementWithPrefix(ControlCodesXmlNode, 'bkp',
              EETEntry."Security Code (BKP)", EETNamespacePrefixTxt, EETNamespaceTxt, BKPControlCodeXmlNode);
        end;

        CompanyInformation.Get();
        EETServiceSetup.Get();
        with EETEntry do begin
            AddAttribute(HeaderXmlNode, 'uuid_zpravy', "Message UUID");
            AddAttribute(HeaderXmlNode, 'dat_odesl', FormatedCurrentDateTime);
            AddAttribute(HeaderXmlNode, 'prvni_zaslani', FormatBoolean(IsFirstSending));
            AddAttribute(HeaderXmlNode, 'overeni', FormatBoolean(VerificationMode));

            AddAttribute(DataXmlNode, 'dic_popl', CompanyInformation."VAT Registration No.");
            AddAttribute(DataXmlNode, 'dic_poverujiciho', EETServiceSetup."Appointing VAT Reg. No.");
            AddAttribute(DataXmlNode, 'id_provoz', GetBusinessPremisesId);
            AddAttribute(DataXmlNode, 'id_pokl', GetCashRegisterNo);
            AddAttribute(DataXmlNode, 'porad_cis', "Receipt Serial No.");
            AddAttribute(DataXmlNode, 'dat_trzby', FormatDateTime("Creation Datetime"));
            AddAttribute(DataXmlNode, 'celk_trzba', FormatDecimal("Total Sales Amount"));
            AddAttribute(DataXmlNode, 'zakl_nepodl_dph', FormatDecimal("Amount Exempted From VAT"));
            AddAttribute(DataXmlNode, 'zakl_dan1', FormatDecimal("VAT Base (Basic)"));
            AddAttribute(DataXmlNode, 'dan1', FormatDecimal("VAT Amount (Basic)"));
            AddAttribute(DataXmlNode, 'zakl_dan2', FormatDecimal("VAT Base (Reduced)"));
            AddAttribute(DataXmlNode, 'dan2', FormatDecimal("VAT Amount (Reduced)"));
            AddAttribute(DataXmlNode, 'zakl_dan3', FormatDecimal("VAT Base (Reduced 2)"));
            AddAttribute(DataXmlNode, 'dan3', FormatDecimal("VAT Amount (Reduced 2)"));
            AddAttribute(DataXmlNode, 'cest_sluz', FormatDecimal("Amount - Art.89"));
            AddAttribute(DataXmlNode, 'pouzit_zboz1', FormatDecimal("Amount (Basic) - Art.90"));
            AddAttribute(DataXmlNode, 'pouzit_zboz2', FormatDecimal("Amount (Reduced) - Art.90"));
            AddAttribute(DataXmlNode, 'pouzit_zboz3', FormatDecimal("Amount (Reduced 2) - Art.90"));
            AddAttribute(DataXmlNode, 'urceno_cerp_zuct', FormatDecimal("Amt. For Subseq. Draw/Settle"));
            AddAttribute(DataXmlNode, 'cerp_zuct', FormatDecimal("Amt. Subseq. Drawn/Settled"));
            AddAttribute(DataXmlNode, 'rezim', FormatOption(EETServiceSetup."Sales Regime"));

            AddAttribute(PKPControlCodeXmlNode, 'cipher', PKPCipherTxt);
            AddAttribute(PKPControlCodeXmlNode, 'digest', PKPDigestTxt);
            AddAttribute(PKPControlCodeXmlNode, 'encoding', PKPEncodingTxt);

            AddAttribute(BKPControlCodeXmlNode, 'digest', BKPDigestTxt);
            AddAttribute(BKPControlCodeXmlNode, 'encoding', BKPEncodingTxt);
        end;

        OnAfterCreateXmlDocument(XmlDoc);
    end;

    local procedure AddAttribute(var XMLNode: DotNet XmlNode; Name: Text; NodeValue: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
    begin
        if (NodeValue = '') or (NodeValue = FormatDecimal(0)) then
            exit;

        XMLDOMMgt.AddAttribute(XMLNode, Name, NodeValue);
    end;

    local procedure CreateSoapRequest(SoapBodyContentXmlDoc: DotNet XmlDocument; DotNetX509Certificate2: Codeunit DotNet_X509Certificate2; var RequestContentXmlDoc: DotNet XmlDocument)
    var
        SoapEnvelopeXmlDoc: DotNet XmlDocument;
        SoapBodyXmlNode: DotNet XmlNode;
    begin
        CreateSoapEnvelope(SoapEnvelopeXmlDoc, SoapBodyXmlNode, DotNetX509Certificate2);
        AddBodyToEnvelope(SoapBodyXmlNode, SoapBodyContentXmlDoc);
        SignXmlDocument(SoapEnvelopeXmlDoc, DotNetX509Certificate2, RequestContentXmlDoc);
        OnAfterCreateSoapRequest(RequestContentXmlDoc);
    end;

    local procedure CreateSoapEnvelope(var SoapEnvelopeXmlDoc: DotNet XmlDocument; var SoapBodyXmlNode: DotNet XmlNode; DotNetX509Certificate2: Codeunit DotNet_X509Certificate2)
    var
        CertificateManagement: Codeunit "Certificate Management";
        XMLDOMMgt: Codeunit "XML DOM Management";
        EnvelopeXmlNode: DotNet XmlNode;
        HeaderXmlNode: DotNet XmlNode;
        SecurityXmlNode: DotNet XmlNode;
        BinarySecurityTokenXmlNode: DotNet XmlNode;
    begin
        SoapEnvelopeXmlDoc := SoapEnvelopeXmlDoc.XmlDocument;
        with XMLDOMMgt do begin
            AddRootElementWithPrefix(SoapEnvelopeXmlDoc, 'Envelope', 'soap', SoapNamespaceTxt, EnvelopeXmlNode);
            AddElementWithPrefix(EnvelopeXmlNode, 'Header', '', 'soap', SoapNamespaceTxt, HeaderXmlNode);

            if not DotNetX509Certificate2.IsDotNetNull() then begin
                AddElementWithPrefix(HeaderXmlNode, 'Security', '', 'wsse', SecurityExtensionNamespaceTxt, SecurityXmlNode);
                AddAttributeWithPrefix(SecurityXmlNode, 'mustUnderstand', 'soap', SoapNamespaceTxt, '1');
                AddAttribute(SecurityXmlNode, 'xmlns:wsu', SecurityUtilityNamespaceTxt);

                AddElementWithPrefix(
                  SecurityXmlNode, 'BinarySecurityToken', CertificateManagement.ConvertDotNetX509Certificate2ToBase64String(DotNetX509Certificate2, '', false),
                  'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode);
                AddAttributeWithPrefix(BinarySecurityTokenXmlNode, 'Id', 'wsu', SecurityUtilityNamespaceTxt, CreateXmlElementID);
                AddAttribute(BinarySecurityTokenXmlNode, 'EncodingType', SecurityEncodingTypeBase64BinaryTxt);
                AddAttribute(BinarySecurityTokenXmlNode, 'ValueType', SecurityValueTypeX509V3Txt);
            end;

            AddElementWithPrefix(EnvelopeXmlNode, 'Body', '', 'soap', SoapNamespaceTxt, SoapBodyXmlNode);
            AddAttribute(SoapBodyXmlNode, 'Id', CreateXmlElementID);
        end;
    end;

    local procedure AddBodyToEnvelope(var SoapBodyXmlNode: DotNet XmlNode; SoapBodyContentXmlDoc: DotNet XmlDocument)
    begin
        SoapBodyXmlNode.AppendChild(SoapBodyXmlNode.OwnerDocument.ImportNode(SoapBodyContentXmlDoc.DocumentElement, true));
    end;

    local procedure SignXmlDocument(XmlDoc: DotNet XmlDocument; DotNetX509Certificate2: Codeunit DotNet_X509Certificate2; var SignedXmlDoc: DotNet XmlDocument)
    var
        DotNetAsymmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm;
        TempBlob: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLElectronicSignMgt: Codeunit "XML Electronic Sign Management";
        Signature: DotNet XmlElement;
        SecurityXmlNode: DotNet XmlNode;
        BinarySecurityTokenXmlNode: DotNet XmlNode;
        SoapBodyXmlNode: DotNet XmlNode;
        BinarySecurityTokenId: Text;
        SoapBodyId: Text;
        ReferenceIndex: Integer;
        KeyStream: InStream;
        OutputStream: OutStream;
    begin
        XMLDOMMgt.FindNodeWithNamespace(
          XmlDoc.DocumentElement, BinarySecurityTokenPathTxt, 'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode);
        BinarySecurityTokenId := XMLDOMMgt.GetAttributeValue(BinarySecurityTokenXmlNode, 'wsu:Id');

        XMLDOMMgt.FindNodeWithNamespace(
          XmlDoc.DocumentElement, BodyPathTxt, 'soap', SoapNamespaceTxt, SoapBodyXmlNode);
        SoapBodyId := XMLDOMMgt.GetAttributeValue(SoapBodyXmlNode, 'Id');

        with XMLElectronicSignMgt do begin
            ReferenceIndex := AddReference(SoapBodyId, DigestMethodSHA256Txt);
            AddReferenceTransformWithInclusiveNamespacesPrefixList(ReferenceIndex, ReferenceTransformTxt, '');
            SetCanonicalizationMethod(CanonicalizationMethodTxt);
            SetInclusiveNamespacesPrefixList('soap');
            SetSignatureMethod(SignatureMethodRSASHA256Txt);
            AddSecurityTokenReference(BinarySecurityTokenId, SecurityValueTypeX509V3Txt);
            DotNetX509Certificate2.PrivateKey(DotNetAsymmetricAlgorithm);
            TempBlob.CreateOutStream(OutputStream);
            TempBlob.CreateInStream(KeyStream);
            OutputStream.Write(DotNetAsymmetricAlgorithm.ToXmlString(true));
            GetSignature(XmlDoc, KeyStream, Signature);
        end;

        SignedXmlDoc := XmlDoc;

        XMLDOMMgt.FindNodeWithNamespace(
          SignedXmlDoc.DocumentElement, SecurityPathTxt, 'wsse', SecurityExtensionNamespaceTxt, SecurityXmlNode);
        SecurityXmlNode.AppendChild(Signature);
    end;

    local procedure SendSoapRequest(RequestContentXmlDoc: DotNet XmlDocument; var ResponseXmlDoc: DotNet XmlDocument; var ResponseContentXmlDoc: DotNet XmlDocument)
    var
        EETServiceSetup: Record "EET Service Setup";
        RequestContentTempBlob: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RequestContentOutStream: OutStream;
        RequestContentInStream: InStream;
        ResponseContentInStream: InStream;
        ResponseInStream: InStream;
    begin
        RequestContentTempBlob.CreateOutStream(RequestContentOutStream);
        RequestContentTempBlob.CreateInStream(RequestContentInStream);

        RequestContentXmlDoc.PreserveWhitespace := true;
        RequestContentXmlDoc.Save(RequestContentOutStream);

        InitializeSecurityProtocol;

        EETServiceSetup.Get();
        with SOAPWebServiceRequestMgt do begin
            SetGlobals(RequestContentInStream, EETServiceSetup."Service URL", '', '');
            SetTimeout(EETServiceSetup."Limit Response Time");
            if SendRequestToWebService then begin
                GetResponse(ResponseInStream);
                XMLDOMManagement.LoadXMLDocumentFromInStream(ResponseInStream, ResponseXmlDoc);

                GetResponseContent(ResponseContentInStream);
                XMLDOMManagement.LoadXMLDocumentFromInStream(ResponseContentInStream, ResponseContentXmlDoc);
            end else
                ProcessFaultResponse('');
        end;
    end;

    local procedure ProcessResponseContent(ResponseContentXmlDoc: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ConfirmationXmlNode: DotNet XmlNode;
    begin
        if VerificationMode or (ResponseContentErrorCode <> '') then
            exit;

        if not XMLDOMMgt.FindNodeWithNamespace(
             ResponseContentXmlDoc.DocumentElement, ConfirmationPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, ConfirmationXmlNode)
        then
            LogMessage(TempErrorMessage."Message Type"::Error, '', XMLFormatErr);

        FIKControlCode := XMLDOMMgt.GetAttributeValue(ConfirmationXmlNode, 'fik');
    end;

    local procedure ProcessResponseContentError(ResponseContentXmlDoc: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ErrorXmlNode: DotNet XmlNode;
    begin
        XMLDOMMgt.FindNodeWithNamespace(
          ResponseContentXmlDoc.DocumentElement, ErrorPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, ErrorXmlNode);

        ResponseContentError := ErrorXmlNode.InnerXml;
        ResponseContentErrorCode := XMLDOMMgt.GetAttributeValue(ErrorXmlNode, 'kod');

        if VerificationMode and (ResponseContentErrorCode = '0') then
            exit;

        LogMessage(TempErrorMessage."Message Type"::Error, ResponseContentErrorCode, ResponseContentError);
    end;

    local procedure ProcessResponseContentWarnings(ResponseContentXmlDoc: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        WarningXmlNodeList: DotNet XmlNodeList;
        WarningXmlNode: DotNet XmlNode;
        ResponseContentWarning: Text;
        ResponseContentWarningCode: Text;
    begin
        XMLDOMMgt.FindNodesWithNamespace(
          ResponseContentXmlDoc.DocumentElement, WarningPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, WarningXmlNodeList);

        foreach WarningXmlNode in WarningXmlNodeList do begin
            ResponseContentWarning := WarningXmlNode.InnerXml;
            ResponseContentWarningCode := XMLDOMMgt.GetAttributeValue(WarningXmlNode, 'kod_varov');

            LogMessage(TempErrorMessage."Message Type"::Warning, ResponseContentWarningCode, ResponseContentWarning);
        end;
    end;

    local procedure HasResponseContentError(ResponseContentXmlDoc: DotNet XmlDocument): Boolean
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ErrorXmlNode: DotNet XmlNode;
    begin
        exit(
          XMLDOMMgt.FindNodeWithNamespace(
            ResponseContentXmlDoc.DocumentElement, ErrorPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, ErrorXmlNode));
    end;

    local procedure HasResponseContentWarnings(ResponseContentXmlDoc: DotNet XmlDocument): Boolean
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        WarningXmlNode: DotNet XmlNode;
    begin
        exit(
          XMLDOMMgt.FindNodeWithNamespace(
            ResponseContentXmlDoc.DocumentElement, WarningPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, WarningXmlNode));
    end;

    local procedure CheckResponseContentHeader(ResponseContentXmlDoc: DotNet XmlDocument; EETEntry: Record "EET Entry")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        HeaderXmlNode: DotNet XmlNode;
        MessageUUID: Text;
        BKPControlCode: Text;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(
             ResponseContentXmlDoc.DocumentElement, HeaderPathTxt, EETNamespacePrefixTxt, EETNamespaceTxt, HeaderXmlNode)
        then
            exit;

        MessageUUID := XMLDOMMgt.GetAttributeValue(HeaderXmlNode, 'uuid_zpravy');
        BKPControlCode := XMLDOMMgt.GetAttributeValue(HeaderXmlNode, 'bkp');

        if ResponseContentErrorCode = '' then begin
            if MessageUUID <> EETEntry."Message UUID" then
                LogMessage(TempErrorMessage."Message Type"::Error, '', MessageUUIDNotMatchErr);
            if BKPControlCode <> EETEntry."Security Code (BKP)" then
                LogMessage(TempErrorMessage."Message Type"::Error, '', BKPControlCodeNotMatchErr);
        end else begin
            if (MessageUUID <> EETEntry."Message UUID") and (MessageUUID <> '') then
                LogMessage(TempErrorMessage."Message Type"::Error, '', MessageUUIDNotMatchErr);
            if (BKPControlCode <> EETEntry."Security Code (BKP)") and (BKPControlCode <> '') then
                LogMessage(TempErrorMessage."Message Type"::Error, '', BKPControlCodeNotMatchErr);
        end;
    end;

    local procedure CheckResponseSecurity(ResponseXmlDoc: DotNet XmlDocument)
    var
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
        X509Certificate2: DotNet X509Certificate2;
        X509Chain: DotNet X509Chain;
        X509RevocationMode: DotNet X509RevocationMode;
    begin
        if VerificationMode then
            exit;

        if not GetResponseCertificate(ResponseXmlDoc, DotNetX509Certificate2) then
            exit;

        DotNetX509Certificate2.GetX509Certificate2(X509Certificate2);
        X509Chain := X509Chain.X509Chain;
        X509Chain.ChainPolicy.RevocationMode := X509RevocationMode.NoCheck;
        if not X509Chain.Build(X509Certificate2) then
            LogMessage(TempErrorMessage."Message Type"::Error, '', EETCertificateNotValidErr);

        if not CheckResponseSignature(ResponseXmlDoc, DotNetX509Certificate2) then
            LogMessage(TempErrorMessage."Message Type"::Error, '', SignatureNotValidErr);
    end;

    local procedure CheckResponseSignature(SignedXmlDoc: DotNet XmlDocument; DotNetX509Certificate2: Codeunit DotNet_X509Certificate2): Boolean
    begin
        exit((SignedXmlDoc.OuterXml <> '') and (not DotNetX509Certificate2.IsDotNetNull()));
    end;

    local procedure GetResponseCertificate(ResponseXmlDoc: DotNet XmlDocument; var DotNetX509Certificate2: Codeunit DotNet_X509Certificate2): Boolean
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        CertificateManagement: Codeunit "Certificate Management";
        BinarySecurityTokenXmlNode: DotNet XmlNode;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(
             ResponseXmlDoc.DocumentElement, BinarySecurityTokenPathTxt, 'wsse', SecurityExtensionNamespaceTxt, BinarySecurityTokenXmlNode)
        then
            exit(false);

        CertificateManagement.ConvertBase64StringToDotNetX509Certificate2(BinarySecurityTokenXmlNode.InnerText, '', DotNetX509Certificate2);
        exit(not DotNetX509Certificate2.IsDotNetNull());
    end;

    local procedure InitializeSecurityProtocol()
    var
        ServicePointManager: DotNet ServicePointManager;
        SecurityProtocolType: DotNet SecurityProtocolType;
    begin
        ServicePointManager.SecurityProtocol := SecurityProtocolType.Tls12;
    end;

    local procedure Initialize()
    begin
        FIKControlCode := '';
        ResponseContentError := '';
        ResponseContentErrorCode := '';

        TempErrorMessage.ClearLog;
        ClearLastError;
    end;

    local procedure CreateXmlElementID(): Text
    begin
        exit('uuid-' + CreateUUID);
    end;

    local procedure CreateUUID(): Text[36]
    begin
        exit(DelChr(LowerCase(Format(CreateGuid)), '=', '{}'));
    end;

    local procedure FormatOption(Option: Option): Text
    var
        EETEntryMgt: Codeunit "EET Entry Management";
    begin
        exit(EETEntryMgt.FormatOption(Option));
    end;

    local procedure FormatDecimal(Decimal: Decimal): Text
    var
        EETEntryMgt: Codeunit "EET Entry Management";
    begin
        exit(EETEntryMgt.FormatDecimal(Decimal));
    end;

    local procedure FormatBoolean(Boolean: Boolean): Text
    var
        EETEntryMgt: Codeunit "EET Entry Management";
    begin
        exit(EETEntryMgt.FormatBoolean(Boolean));
    end;

    local procedure FormatDateTime(DateTime: DateTime): Text
    var
        EETEntryMgt: Codeunit "EET Entry Management";
    begin
        exit(EETEntryMgt.FormatDateTime(DateTime));
    end;

    local procedure FormatedCurrentDateTime(): Text
    begin
        exit(FormatDateTime(CurrentDateTime));
    end;

    local procedure IsVerificationModeOK(): Boolean
    begin
        exit(VerificationMode and (ResponseContentErrorCode = '0'));
    end;

    local procedure LogMessage(MessageType: Option; MessageCode: Text; MessageText: Text)
    begin
        TempErrorMessage.LogSimpleMessage(MessageType, MessageText);

        if MessageType = TempErrorMessage."Message Type"::Warning then
            TempErrorMessage.Validate("Additional Information", StrSubstNo(WarningCodeTxt, MessageCode))
        else
            TempErrorMessage.Validate("Additional Information", StrSubstNo(ErrorCodeTxt, MessageCode));

        TempErrorMessage.Modify();
    end;

    [Scope('OnPrem')]
    procedure HasErrors(): Boolean
    begin
        exit(TempErrorMessage.HasErrors(false));
    end;

    [Scope('OnPrem')]
    procedure HasWarnings(): Boolean
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Warning);
        exit(not TempErrorMessage.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetWebServiceURLTxt(): Text[250]
    begin
        exit(WebServiceURLTxt);
    end;

    [Scope('OnPrem')]
    procedure GetWebServicePlayGroundURLTxt(): Text[250]
    begin
        exit(WebServicePGURLTxt);
    end;

    [Scope('OnPrem')]
    procedure GetFIKControlCode(): Text[39]
    begin
        exit(CopyStr(FIKControlCode, 1, 39));
    end;

    [Scope('OnPrem')]
    procedure GetResponseText(): Text
    begin
        if IsVerificationModeOK then
            exit(ResponseContentError);

        if GetLastErrorText <> '' then
            exit(GetLastErrorText);

        TempErrorMessage.Reset();
        TempErrorMessage.FindFirst;
        exit(TempErrorMessage.Description);
    end;

    [Scope('OnPrem')]
    procedure SetVerificationMode(NewVerificationMode: Boolean)
    begin
        VerificationMode := NewVerificationMode;
    end;

    [Scope('OnPrem')]
    procedure SetURLToDefault(var EETServiceSetup: Record "EET Service Setup")
    begin
        EETServiceSetup."Service URL" := GetWebServicePlayGroundURLTxt;
    end;

    [Scope('OnPrem')]
    procedure CopyErrorMessageToTemp(var TempErrorMessage2: Record "Error Message" temporary)
    begin
        if (GetLastErrorText <> ResponseContentError) and (GetLastErrorText <> '') then
            LogMessage(TempErrorMessage."Message Type"::Error, GetLastErrorCode, GetLastErrorText);

        TempErrorMessage.Reset();
        TempErrorMessage.CopyToTemp(TempErrorMessage2);
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleEETRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        EETServiceSetup: Record "EET Service Setup";
        RecRef: RecordRef;
    begin
        if not EETServiceSetup.Get then begin
            EETServiceSetup.Init();
            EETServiceSetup.Insert(true);
        end;
        RecRef.GetTable(EETServiceSetup);

        if EETServiceSetup.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        with EETServiceSetup do
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, TableName, "Service URL", PAGE::"EET Service Setup");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadValidCertificate(var IsolatedCertificate: Record "Isolated Certificate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateXmlDocument(var XmlDoc: DotNet XmlDocument)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSoapRequest(var RequestContentXmlDoc: DotNet XmlDocument)
    begin
    end;
}

