codeunit 10527 HMRCSubmissionHelpers
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure CreateIRMark(XMLDocument: DotNet XmlDocument; GovTalkNameSpace: Text; TaxNameSpace: Text): Text
    var
        XMLNSMgr: DotNet XmlNamespaceManager;
        XMLDummyNode: DotNet XmlNode;
        XmlC14NTransform: DotNet XmlDsigC14NTransform;
        HashingAlgorithm: DotNet SHA1;
        Convert: DotNet Convert;
        TempXMLDocument: DotNet XmlDocument;
        CRCharacter: Char;
    begin
        XMLDocument.PreserveWhitespace := true;
        XMLNSMgr := XMLNSMgr.XmlNamespaceManager(XMLDocument.NameTable);
        XMLNSMgr.AddNamespace('GovTalk', GovTalkNameSpace);
        XMLNSMgr.AddNamespace('Tax', TaxNameSpace);

        CRCharacter := 13;
        TempXMLDocument := TempXMLDocument.XmlDocument();
        TempXMLDocument.PreserveWhitespace := true;
        TempXMLDocument.LoadXml(XMLDocument.OuterXml);
        TempXMLDocument.PreserveWhitespace := true;
        TempXMLDocument.InnerXml := DelChr(TempXMLDocument.InnerXml, '=', Format(CRCharacter));

        XMLDummyNode := TempXMLDocument.SelectSingleNode('//GovTalk:Body', XMLNSMgr);
        TempXMLDocument.LoadXml(XMLDummyNode.OuterXml);

        XMLDummyNode := TempXMLDocument.SelectSingleNode('//Tax:IRmark', XMLNSMgr);
        XMLDummyNode.ParentNode.RemoveChild(XMLDummyNode);

        XmlC14NTransform := XmlC14NTransform.XmlDsigC14NTransform();
        XmlC14NTransform.LoadInput(TempXMLDocument);

        HashingAlgorithm := HashingAlgorithm.Create();
        exit(Convert.ToBase64String(XmlC14NTransform.GetDigestedOutput(HashingAlgorithm)));
    end;

    [Scope('OnPrem')]
    procedure HashPassword(Password: Text): Text
    var
        Encoder: DotNet Encoding;
        HashingAlgorithm: DotNet MD5;
        Convert: DotNet Convert;
    begin
        Password := LowerCase(Password);
        Password := Encoder.UTF8.GetString(Encoder.Default.GetBytes(Password));
        HashingAlgorithm := HashingAlgorithm.Create();
        exit(Convert.ToBase64String(HashingAlgorithm.ComputeHash(Encoder.Default.GetBytes(Password))));
    end;
}

