codeunit 10521 "HMRC GovTalk Message Scheduler"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        VATReportHeader: Record "VAT Report Header";
        RecRef: RecordRef;
    begin
        if RecRef.Get("Record ID to Process") then begin
            RecRef.SetTable(VATReportHeader);
            SendPollMessage(VATReportHeader, "Parameter String");
        end;
    end;

    var
        GovTalkMessageManagement: Codeunit GovTalkMessageManagement;
        GovTalkNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/envelope', Locked = true;
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLPartMissingErr: Label 'A section of the XML document is missing.';

    local procedure SendPollMessage(var VATReportHeader: Record "VAT Report Header"; XMLPartID: Text)
    var
        GovTalkMessage: Record GovTalkMessage;
        GovTalkMessageParts: Record "GovTalk Message Parts";
        GovTalkMessageXMLNode: DotNet XmlNode;
        CorrelationXMLNode: DotNet XmlNode;
        PartIDGuid: Guid;
    begin
        GovTalkMessageManagement.CreateGovTalkPollMessage(GovTalkMessageXMLNode, VATReportHeader);
        if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::"EC Sales List" then begin
            if not GovTalkMessageParts.Get(XMLPartID) then
                Error('');
            if XMLDOMManagement.FindNodeWithNamespace(GovTalkMessageXMLNode, '//x:CorrelationID', 'x', GovTalkNameSpaceTxt, CorrelationXMLNode) then
                CorrelationXMLNode.InnerText := GovTalkMessageParts."Correlation Id"
            else
                Error(XMLPartMissingErr);
        end;

        Evaluate(PartIDGuid, XMLPartID);
        if GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.") then
            if not GovTalkMessageManagement.ProcessGovTalkSubmission(
                 VATReportHeader, GovTalkMessage.ResponseEndPoint, GovTalkMessageXMLNode, true, true, PartIDGuid)
            then
                GovTalkMessageManagement.RegisterGovTalkPolling(VATReportHeader, XMLPartID);
    end;
}

