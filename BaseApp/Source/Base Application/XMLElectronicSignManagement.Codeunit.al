codeunit 31132 "XML Electronic Sign Management"
{

    trigger OnRun()
    begin
    end;

    var
        SignedXml: DotNet SignedXml;
        References: DotNet GenericList1;
        GlobalKeyInfo: DotNet KeyInfo;
        GlobalSignedXmlDoc: DotNet XmlDocument;
        GlobalSignedXmlElement: DotNet XmlElement;
        GlobalCanonicalizationMethodUrl: Text;
        GlobalInclusiveNamespacesPrefixList: Text;
        GlobalSignatureMethod: Text;
        SecurityExtensionNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;
        SignatureMethodRSASHA256Txt: Label 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256', Locked = true;
        KeyNotDefinedErr: Label 'Key is not defined.';
        XmlDocumentNotDefinedErr: Label 'Xml document is not defined.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetSignature(XmlDocument: DotNet XmlDocument; "Key": DotNet RSA; var Signature: DotNet XmlElement)
    var
        RSACryptoServiceProvider: DotNet RSACryptoServiceProvider;
        Reference: DotNet Reference;
    begin
        if IsNull(XmlDocument) then
            Error(XmlDocumentNotDefinedErr);

        if IsNull(Key) then
            Error(KeyNotDefinedErr);

        InitializeAlgorithms;

        RSACryptoServiceProvider := RSACryptoServiceProvider.RSACryptoServiceProvider;
        RSACryptoServiceProvider.ImportParameters(Key.ExportParameters(true));

        SignedXml := SignedXml.SignedXml(XmlDocument);
        SignedXml.SigningKey := RSACryptoServiceProvider;

        if GlobalCanonicalizationMethodUrl <> '' then
            SignedXml.SignedInfo.CanonicalizationMethod := GlobalCanonicalizationMethodUrl;

        SetInclusiveNamespacesPrefixListToTransform(
          SignedXml.SignedInfo.CanonicalizationMethodObject, GlobalInclusiveNamespacesPrefixList);

        if GlobalSignatureMethod <> '' then
            SignedXml.SignedInfo.SignatureMethod := GlobalSignatureMethod;

        if not IsNull(GlobalKeyInfo) then
            SignedXml.KeyInfo := GlobalKeyInfo;

        if not IsNull(References) then
            foreach Reference in References do
                SignedXml.AddReference(Reference);

        SignedXml.ComputeSignature;
        Signature := SignedXml.GetXml;
    end;

    [Scope('OnPrem')]
    procedure CheckSignature(Signature: DotNet XmlElement; X509Certificate2: DotNet X509Certificate2): Boolean
    begin
        InitializeAlgorithms;

        if not IsNull(GlobalSignedXmlDoc) then
            SignedXml := SignedXml.SignedXml(GlobalSignedXmlDoc);

        if not IsNull(GlobalSignedXmlElement) then
            SignedXml := SignedXml.SignedXml(GlobalSignedXmlElement);

        if IsNull(SignedXml) then
            SignedXml := SignedXml.SignedXml;

        SignedXml.LoadXml(Signature);
        exit(SignedXml.CheckSignature(X509Certificate2, true));
    end;

    [Scope('OnPrem')]
    procedure AddReference(URI: Text; DigestMethod: Text) ReferenceIndex: Integer
    var
        Reference: DotNet Reference;
    begin
        Reference := Reference.Reference;
        Reference.Uri := '';

        if URI <> '' then
            Reference.Uri := FormatURI(URI);

        if DigestMethod <> '' then
            Reference.DigestMethod := DigestMethod;

        ReferenceIndex := AddReferenceObject(Reference);
    end;

    [Scope('OnPrem')]
    procedure AddReferenceObject(Reference: DotNet Reference) ReferenceIndex: Integer
    begin
        if IsNull(Reference) then
            exit;

        if IsNull(References) then
            References := References.List;

        References.Add(Reference);
        ReferenceIndex := References.Count - 1;
    end;

    [Scope('OnPrem')]
    procedure AddReferenceTransformWithInclusiveNamespacesPrefixList(ReferenceIndex: Integer; Transform: Text; InclusiveNamespacesPrefixList: Text)
    var
        TransformObject: DotNet Transform;
    begin
        if Transform = '' then
            exit;

        if not GetTransformObject(Transform, TransformObject) then
            exit;

        SetInclusiveNamespacesPrefixListToTransform(TransformObject, InclusiveNamespacesPrefixList);

        AddReferenceTransformObject(ReferenceIndex, TransformObject);
    end;

    [Scope('OnPrem')]
    procedure AddReferenceTransformObject(ReferenceIndex: Integer; Transform: DotNet Transform)
    var
        Reference: DotNet Reference;
    begin
        if IsNull(References) or IsNull(Transform) then
            exit;

        Reference := References.Item(ReferenceIndex);
        Reference.AddTransform(Transform);
    end;

    [Scope('OnPrem')]
    procedure AddKeyInfoClauseObject(KeyInfoClause: DotNet KeyInfoClause)
    var
        KeyInfo: DotNet KeyInfo;
    begin
        if IsNull(GlobalKeyInfo) then begin
            KeyInfo := KeyInfo.KeyInfo;
            SetKeyInfoObject(KeyInfo);
        end;

        GlobalKeyInfo.AddClause(KeyInfoClause);
    end;

    [Scope('OnPrem')]
    procedure AddSecurityTokenReference(URI: Text; ValueType: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        KeyInfoNode: DotNet KeyInfoNode;
        SecurityTokenReferenceXmlElement: DotNet XmlElement;
        SecurityTokenReferenceXmlNode: DotNet XmlNode;
        ReferenceXmlNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
    begin
        XmlDoc := XmlDoc.XmlDocument;
        with XMLDOMMgt do begin
            AddRootElementWithPrefix(
              XmlDoc, 'SecurityTokenReference', 'wsse', SecurityExtensionNamespaceTxt, SecurityTokenReferenceXmlNode);
            AddElementWithPrefix(SecurityTokenReferenceXmlNode, 'Reference', '', 'wsse', SecurityExtensionNamespaceTxt, ReferenceXmlNode);
            AddAttribute(ReferenceXmlNode, 'URI', FormatURI(URI));
            AddAttribute(ReferenceXmlNode, 'ValueType', ValueType);
        end;

        SecurityTokenReferenceXmlElement := SecurityTokenReferenceXmlNode;
        AddKeyInfoClauseObject(KeyInfoNode.KeyInfoNode(SecurityTokenReferenceXmlElement));
    end;

    [Scope('OnPrem')]
    procedure SetCanonicalizationMethod(CanonicalizationMethod: Text)
    begin
        // expected input is the name of text constant of the class System.Security.SignedXml
        SetCanonicalizationMethodUrl(GetCanonicalizationMethodUrl(CanonicalizationMethod));
    end;

    [Scope('OnPrem')]
    procedure SetCanonicalizationMethodUrl(CanonicalizationMethodUrl: Text)
    begin
        GlobalCanonicalizationMethodUrl := CanonicalizationMethodUrl;
    end;

    [Scope('OnPrem')]
    procedure SetInclusiveNamespacesPrefixList(InclusiveNamespacesPrefixList: Text)
    begin
        GlobalInclusiveNamespacesPrefixList := InclusiveNamespacesPrefixList;
    end;

    local procedure SetInclusiveNamespacesPrefixListToTransform(Transform: DotNet Transform; InclusiveNamespacesPrefixList: Text)
    var
        Type: DotNet Type;
        PropertyInfo: DotNet PropertyInfo;
    begin
        if IsNull(Transform) then
            exit;

        Type := Transform.GetType;
        PropertyInfo := Type.GetProperty('InclusiveNamespacesPrefixList');
        if not IsNull(PropertyInfo) then
            PropertyInfo.SetValue(Transform, InclusiveNamespacesPrefixList);
    end;

    [Scope('OnPrem')]
    procedure SetSignatureMethod(SignatureMethod: Text)
    begin
        GlobalSignatureMethod := SignatureMethod;
    end;

    [Scope('OnPrem')]
    procedure SetKeyInfoObject(KeyInfo: DotNet KeyInfo)
    begin
        GlobalKeyInfo := KeyInfo;
    end;

    [Scope('OnPrem')]
    procedure SetSignedXmlDocument(SignedXmlDoc: DotNet XmlDocument)
    begin
        GlobalSignedXmlDoc := SignedXmlDoc;
    end;

    [Scope('OnPrem')]
    procedure SetSignedXmlElement(SignedXmlElement: DotNet XmlElement)
    begin
        GlobalSignedXmlElement := SignedXmlElement;
    end;

    local procedure GetTransformObject(Transform: Text; var TransformObject: DotNet Transform): Boolean
    var
        XmlDecryptionTransform: DotNet XmlDecryptionTransform;
        XmlDsigBase64Transform: DotNet XmlDsigBase64Transform;
        XmlDsigC14NTransform: DotNet XmlDsigC14NTransform;
        XmlDsigEnvelopedSignatureTransform: DotNet XmlDsigEnvelopedSignatureTransform;
        XmlDsigExcC14NTransform: DotNet XmlDsigExcC14NTransform;
        XmlDsigXPathTransform: DotNet XmlDsigXPathTransform;
        XmlDsigXsltTransform: DotNet XmlDsigXsltTransform;
        XmlLicenseTransform: DotNet XmlLicenseTransform;
    begin
        case Transform of
            'XmlDecryptionTransform':
                TransformObject := XmlDecryptionTransform.XmlDecryptionTransform;
            'XmlDsigBase64Transform':
                TransformObject := XmlDsigBase64Transform.XmlDsigBase64Transform;
            'XmlDsigC14NTransform':
                TransformObject := XmlDsigC14NTransform.XmlDsigC14NTransform;
            'XmlDsigEnvelopedSignatureTransform':
                TransformObject := XmlDsigEnvelopedSignatureTransform.XmlDsigEnvelopedSignatureTransform;
            'XmlDsigExcC14NTransform':
                TransformObject := XmlDsigExcC14NTransform.XmlDsigExcC14NTransform;
            'XmlDsigXPathTransform':
                TransformObject := XmlDsigXPathTransform.XmlDsigXPathTransform;
            'XmlDsigXsltTransform':
                TransformObject := XmlDsigXsltTransform.XmlDsigXsltTransform;
            'XmlLicenseTransform':
                TransformObject := XmlLicenseTransform.XmlLicenseTransform;
            else
                exit(false);
        end;

        exit(true);
    end;

    local procedure GetCanonicalizationMethodUrl(CanonicalizationMethod: Text): Text
    var
        Type: DotNet Type;
        FieldInfo: DotNet FieldInfo;
        SignedXml: DotNet SignedXml;
    begin
        Type := GetDotNetType(SignedXml);
        FieldInfo := Type.GetField(CanonicalizationMethod);
        exit(FieldInfo.GetValue(GetDotNetType(SignedXml)));
    end;

    local procedure InitializeAlgorithms()
    var
        CryptoConfig: DotNet CryptoConfig;
        RSAPKCS1SHA256SignatureDescription: DotNet RSAPKCS1SHA256SignatureDescription;
        Names: DotNet Array;
        String: DotNet String;
    begin
        Names := Names.CreateInstance(GetDotNetType(String), 1);
        Names.SetValue(SignatureMethodRSASHA256Txt, 0);
        CryptoConfig.AddAlgorithm(GetDotNetType(RSAPKCS1SHA256SignatureDescription), Names);
    end;

    local procedure FormatURI(URI: Text): Text
    begin
        if StrPos(URI, '#') = 0 then
            exit(StrSubstNo('#%1', URI));
        exit(URI);
    end;
}

