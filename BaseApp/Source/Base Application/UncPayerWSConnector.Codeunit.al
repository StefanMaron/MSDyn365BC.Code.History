#if not CLEAN17
codeunit 11759 "Unc. Payer WS Connector"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        NamespaceTxt: Label 'http://adis.mfcr.cz/rozhraniCRPDPH/', Locked = true;
        VATRegNoLimitExceededMsg: Label 'The number of VAT Registration No. has been exceeded. The maximum number of VAT Registration No. is 100 and %1 were sent. The service returns a response for only the first top 100 VAT Registration No.', Comment = '%1 = actual number of sending VAT registration numbers';
        ServiceUrl: Text;

    [TryFunction]
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetStatus(var DotNetArrayVATRegNo: Codeunit DotNet_Array; var TempBlobResponse: Codeunit "Temp Blob")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXmlDocument: DotNet XmlDocument;
        RootXmlNode: DotNet XmlNode;
        ChildXmlNode: DotNet XmlNode;
        i: Integer;
    begin
        if DotNetArrayVATRegNo.Length > GetInputRecordLimit then
            if GuiAllowed then
                Message(VATRegNoLimitExceededMsg, DotNetArrayVATRegNo.Length);

        RequestXmlDocument := RequestXmlDocument.XmlDocument;
        XMLDOMMgt.AddRootElementWithPrefix(RequestXmlDocument, 'StatusNespolehlivyPlatceRequest', '', NamespaceTxt, RootXmlNode);
        for i := 0 to DotNetArrayVATRegNo.Length - 1 do
            XMLDOMMgt.AddElement(RootXmlNode, 'dic', FormatVATRegNo(DotNetArrayVATRegNo.GetValueAsText(i)), NamespaceTxt, ChildXmlNode);

        SendHttpRequest(RequestXmlDocument, TempBlobResponse);
    end;

    [TryFunction]
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetStatusExtended(var DotNetArrayVATRegNo: Codeunit DotNet_Array; var TempBlobResponse: Codeunit "Temp Blob")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXmlDocument: DotNet XmlDocument;
        RootXmlNode: DotNet XmlNode;
        ChildXmlNode: DotNet XmlNode;
        i: Integer;
    begin
        if DotNetArrayVATRegNo.Length > GetInputRecordLimit then
            if GuiAllowed then
                Message(VATRegNoLimitExceededMsg, DotNetArrayVATRegNo.Length);

        RequestXmlDocument := RequestXmlDocument.XmlDocument;
        XMLDOMMgt.AddRootElementWithPrefix(RequestXmlDocument, 'StatusNespolehlivyPlatceRozsirenyRequest', '', NamespaceTxt, RootXmlNode);
        for i := 0 to DotNetArrayVATRegNo.Length - 1 do
            XMLDOMMgt.AddElement(RootXmlNode, 'dic', FormatVATRegNo(DotNetArrayVATRegNo.GetValueAsText(i)), NamespaceTxt, ChildXmlNode);

        SendHttpRequest(RequestXmlDocument, TempBlobResponse);
    end;

    [TryFunction]
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetList(var TempBlobResponse: Codeunit "Temp Blob")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXmlDocument: DotNet XmlDocument;
        RootXmlNode: DotNet XmlNode;
    begin
        RequestXmlDocument := RequestXmlDocument.XmlDocument;
        XMLDOMMgt.AddRootElementWithPrefix(RequestXmlDocument, 'SeznamNespolehlivyPlatceRequest', '', NamespaceTxt, RootXmlNode);
        SendHttpRequest(RequestXmlDocument, TempBlobResponse);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure SetServiceUrl(NewServiceUrl: Text)
    begin
        ServiceUrl := NewServiceUrl;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetInputRecordLimit(): Integer
    begin
        exit(100);
    end;

    local procedure SendHttpRequest(RequestXmlDocument: DotNet XmlDocument; var TempBlobResponse: Codeunit "Temp Blob")
    var
        TempBlobRequest: Codeunit "Temp Blob";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        ResponseInStream: InStream;
        ResponseOutStream: OutStream;
        RequestInStream: InStream;
        RequestOutStream: OutStream;
    begin
        Clear(TempBlobResponse);
        Clear(TempBlobRequest);

        TempBlobRequest.CreateInStream(RequestInStream);
        TempBlobRequest.CreateOutStream(RequestOutStream);
        RequestXmlDocument.Save(RequestOutStream);

        SOAPWebServiceRequestMgt.SetGlobals(RequestInStream, ServiceUrl, '', '');
        SOAPWebServiceRequestMgt.DisableHttpsCheck;
        SOAPWebServiceRequestMgt.SetTimeout(10000);

        if SOAPWebServiceRequestMgt.SendRequestToWebService then begin
            SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);
            TempBlobResponse.CreateOutStream(ResponseOutStream);
            CopyStream(ResponseOutStream, ResponseInStream);
        end else
            SOAPWebServiceRequestMgt.ProcessFaultResponse('');
    end;

    local procedure FormatVATRegNo(VATRegNo: Text): Text
    var
        DotNetRegex: Codeunit DotNet_Regex;
    begin
        DotNetRegex.Regex('[A-Z]');
        exit(DotNetRegex.Replace(UpperCase(VATRegNo), ''));
    end;
}


#endif