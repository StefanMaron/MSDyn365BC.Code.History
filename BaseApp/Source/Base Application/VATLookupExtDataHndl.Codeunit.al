codeunit 248 "VAT Lookup Ext. Data Hndl"
{
    Permissions = TableData "VAT Registration Log" = rimd;
    TableNo = "VAT Registration Log";

    trigger OnRun()
    begin
        VATRegistrationLog := Rec;

        LookupVatRegistrationFromWebService(true);

        Rec := VATRegistrationLog;
    end;

    var
        NamespaceTxt: Label 'urn:ec.europa.eu:taxud:vies:services:checkVat:types', Locked = true;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        VatRegNrValidationWebServiceURLTxt: Label 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService', Locked = true;
        VATRegistrationURL: Text;

    local procedure LookupVatRegistrationFromWebService(ShowErrors: Boolean)
    var
        TempBlobRequestBody: Codeunit "Temp Blob";
    begin
        SendRequestToVatRegistrationService(TempBlobRequestBody, ShowErrors);

        InsertLogEntry(TempBlobRequestBody);

        Commit();
    end;

    local procedure SendRequestToVatRegistrationService(var TempBlobBody: Codeunit "Temp Blob"; ShowErrors: Boolean)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        SOAPWebServiceRequestMgt: Codeunit "SOAP Web Service Request Mgt.";
        ResponseInStream: InStream;
        InStream: InStream;
        ResponseOutStream: OutStream;
    begin
        PrepareSOAPRequestBody(TempBlobBody);

        TempBlobBody.CreateInStream(InStream);
        VATRegistrationURL := VATRegNoSrvConfig.GetVATRegNoURL;
        SOAPWebServiceRequestMgt.SetGlobals(InStream, VATRegistrationURL, '', '');
        SOAPWebServiceRequestMgt.DisableHttpsCheck;
        SOAPWebServiceRequestMgt.SetTimeout(60000);

        if SOAPWebServiceRequestMgt.SendRequestToWebService then begin
            SOAPWebServiceRequestMgt.GetResponseContent(ResponseInStream);

            TempBlobBody.CreateOutStream(ResponseOutStream);
            CopyStream(ResponseOutStream, ResponseInStream);
        end else
            if ShowErrors then
                SOAPWebServiceRequestMgt.ProcessFaultResponse('');
    end;

    local procedure PrepareSOAPRequestBody(var TempBlob: Codeunit "Temp Blob")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        BodyContentInputStream: InStream;
        BodyContentOutputStream: OutStream;
        BodyContentXmlDoc: DotNet XmlDocument;
        EnvelopeXmlNode: DotNet XmlNode;
        CreatedXmlNode: DotNet XmlNode;
    begin
        TempBlob.CreateInStream(BodyContentInputStream);
        BodyContentXmlDoc := BodyContentXmlDoc.XmlDocument;

        XMLDOMMgt.AddRootElementWithPrefix(BodyContentXmlDoc, 'checkVatApprox', '', NamespaceTxt, EnvelopeXmlNode);
        XMLDOMMgt.AddElement(EnvelopeXmlNode, 'countryCode', VATRegistrationLog.GetCountryCode, NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(EnvelopeXmlNode, 'vatNumber', VATRegistrationLog.GetVATRegNo, NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(
          EnvelopeXmlNode, 'requesterCountryCode', VATRegistrationLog.GetCountryCode, NamespaceTxt, CreatedXmlNode);
        XMLDOMMgt.AddElement(
          EnvelopeXmlNode, 'requesterVatNumber', VATRegistrationLog.GetVATRegNo, NamespaceTxt, CreatedXmlNode);

        Clear(TempBlob);
        TempBlob.CreateOutStream(BodyContentOutputStream);
        BodyContentXmlDoc.Save(BodyContentOutputStream);
    end;

    local procedure InsertLogEntry(TempBlobRequestBody: Codeunit "Temp Blob")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocOut: DotNet XmlDocument;
        InStream: InStream;
    begin
        TempBlobRequestBody.CreateInStream(InStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, XMLDocOut);

        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, XMLDocOut, NamespaceTxt);
    end;

    procedure GetVATRegNrValidationWebServiceURL(): Text[250]
    begin
        exit(VatRegNrValidationWebServiceURLTxt);
    end;
}

