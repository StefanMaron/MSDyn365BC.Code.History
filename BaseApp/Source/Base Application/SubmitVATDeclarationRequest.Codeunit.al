codeunit 10522 "Submit VAT Declaration Request"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        GovTalkMessage: Record GovTalkMessage;
        BodyXMLNode: DotNet XmlNode;
        GovTalkRequestXMLNode: DotNet XmlNode;
        IRMarkXMLNode: DotNet XmlNode;
    begin
        GovTalkMessage.Get("VAT Report Config. Code", "No.");
        if GovTalkMessageManagement.CreateBlankGovTalkXmlMessage(GovTalkMessageXMLNode, BodyXMLNode, Rec, 'request', 'submit', true) then begin
            InsertVATDeclarationRequestIRHeader(GovTalkMessage, BodyXMLNode, GovTalkRequestXMLNode, IRMarkXMLNode);
            InsertVATDeclarationRequestDetails(GovTalkMessage, GovTalkRequestXMLNode, IRMarkXMLNode);
            if not GovTalkMessageManagement.SubmitGovTalkRequest(Rec, GovTalkMessageXMLNode) then
                Error(SubmissionFailedErr);
        end;
    end;

    var
        GovTalkMessageManagement: Codeunit GovTalkMessageManagement;
        VATDeclarationNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/vatdeclaration/2', Locked = true;
        XMLDOMManagement: Codeunit "XML DOM Management";
        GovTalkMessageXMLNode: DotNet XmlNode;
        GovTalkNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/envelope', Locked = true;
        SubmissionFailedErr: Label 'Could not submit the report to the GovTalk service. This might be because the URL to the service is incorrect, or the service is unavailable right now.';

    local procedure InsertVATDeclarationRequestIRHeader(GovTalkMessage: Record GovTalkMessage; var BodyXMLNode: DotNet XmlNode; var GovTalkRequestXMLNode: DotNet XmlNode; var IRmarkXMLNode: DotNet XmlNode)
    var
        CompanyInformation: Record "Company Information";
        IREnvelopeXMLNode: DotNet XmlNode;
        IRHeaderXMLNode: DotNet XmlNode;
        KeysXMLNode: DotNet XmlNode;
        VATRegNoXMLNode: DotNet XmlNode;
        DummyXMLNode: DotNet XmlNode;
    begin
        CompanyInformation.FindFirst;
        with XMLDOMManagement do begin
            AddElementWithPrefix(BodyXMLNode, 'IRenvelope', '', 'vat', VATDeclarationNameSpaceTxt, IREnvelopeXMLNode);
            AddElementWithPrefix(IREnvelopeXMLNode, 'IRheader', '', 'vat', VATDeclarationNameSpaceTxt, IRHeaderXMLNode);
            AddElementWithPrefix(IRHeaderXMLNode, 'Keys', '', 'vat', VATDeclarationNameSpaceTxt, KeysXMLNode);
            AddElementWithPrefix(KeysXMLNode, 'Key',
              GovTalkMessageManagement.FormatVATRegNo(CompanyInformation."Country/Region Code", CompanyInformation."VAT Registration No."),
              'vat', VATDeclarationNameSpaceTxt, VATRegNoXMLNode);
            AddAttribute(VATRegNoXMLNode, 'Type', 'VATRegNo');
            AddElementWithPrefix(IRHeaderXMLNode, 'PeriodID', GovTalkMessage.PeriodID, 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
            AddElementWithPrefix(IRHeaderXMLNode, 'PeriodStart',
              Format(GovTalkMessage.PeriodStart, 0, 9), 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
            AddElementWithPrefix(IRHeaderXMLNode, 'PeriodEnd',
              Format(GovTalkMessage.PeriodEnd, 0, 9), 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
            AddElementWithPrefix(IRHeaderXMLNode, 'IRmark', '', 'vat', VATDeclarationNameSpaceTxt, IRmarkXMLNode);
            AddAttribute(IRmarkXMLNode, 'Type', 'generic');
            AddElementWithPrefix(IRHeaderXMLNode, 'Sender', 'Individual', 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
            AddElementWithPrefix(IREnvelopeXMLNode, 'VATDeclarationRequest', '', 'vat', VATDeclarationNameSpaceTxt, GovTalkRequestXMLNode);
        end;
    end;

    local procedure InsertVATDeclarationRequestDetails(GovTalkMessage: Record GovTalkMessage; var GovTalkRequestXMLNode: DotNet XmlNode; var IRmarkXMLNode: DotNet XmlNode)
    var
        ChildXMLBuffer: Record "XML Buffer";
        HMRCSubmissionHelpers: Codeunit HMRCSubmissionHelpers;
        DummyXMLNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
    begin
        with XMLDOMManagement do begin
            ChildXMLBuffer.SetRange("Parent Entry No.", GovTalkMessage.RootXMLBuffer);
            if ChildXMLBuffer.FindSet then
                repeat
                    AddElementWithPrefix(GovTalkRequestXMLNode,
                      ChildXMLBuffer.Name, ChildXMLBuffer.Value, 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
                until ChildXMLBuffer.Next() = 0;
        end;
        XmlDoc := GovTalkMessageXMLNode.ParentNode;
        XmlDoc.PreserveWhitespace := true;
        IRmarkXMLNode.InnerText := HMRCSubmissionHelpers.CreateIRMark(XmlDoc, GovTalkNameSpaceTxt, VATDeclarationNameSpaceTxt);
    end;
}

