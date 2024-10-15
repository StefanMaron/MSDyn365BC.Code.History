codeunit 11100 "SEPA CT APC-Export File"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
    begin
        LockTable;
        BankAccount.Get("Bal. Account No.");
        if Export(Rec, BankAccount.GetPaymentExportXMLPortID) then
            ModifyAll("Exported to Payment File", true);
    end;

    local procedure Export(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer): Boolean
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, GenJnlLine);
        PostProcessXMLDocument(TempBlob);
        CreditTransferRegister.FindLast;
        exit(FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', CreditTransferRegister.Identifier), true) <> '');
    end;

    [Scope('OnPrem')]
    procedure PostProcessXMLDocument(var TempBlob: Codeunit "Temp Blob")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDoc: DotNet XmlDocument;
        XMLNsMgr: DotNet XmlNamespaceManager;
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateInStream(InStr);

        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        XMLNsMgr := XMLNsMgr.XmlNamespaceManager(XMLDoc.NameTable);
        XMLNsMgr.AddNamespace('ns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');

        ApplyApcRequirements(XMLDoc, XMLNsMgr);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLDoc.Save(OutStr);
    end;

    local procedure ApplyApcRequirements(var XMLDoc: DotNet XmlDocument; XMLNsMgr: DotNet XmlNamespaceManager)
    var
        NodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        // Remove all PstlAdr nodes
        NodeList := XMLDoc.DocumentElement.SelectNodes('//ns:PstlAdr', XMLNsMgr);
        for i := 1 to NodeList.Count do
            NodeList.Item(i - 1).ParentNode.RemoveChild(NodeList.Item(i - 1));

        // Remove Nm from InitgPty
        XMLNode := XMLDoc.DocumentElement.SelectSingleNode('//ns:InitgPty/ns:Nm', XMLNsMgr);
        if not IsNull(XMLNode) then
            XMLNode.ParentNode.RemoveChild(XMLNode);
    end;
}

