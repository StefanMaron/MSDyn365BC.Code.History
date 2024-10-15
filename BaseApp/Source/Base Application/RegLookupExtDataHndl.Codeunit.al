codeunit 11797 "Reg. Lookup Ext. Data Hndl"
{
    TableNo = "Registration Log";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        RegistrationLog := Rec;

        LookupRegistrationFromService(true);

        Rec := RegistrationLog;
    end;

    var
        RegistrationLog: Record "Registration Log";
        RegistrationLogMgt: Codeunit "Registration Log Mgt.";
        RegNoValidationWebServiceURLTxt: Label 'http://wwwinfo.mfcr.cz/cgi-bin/ares/darv_bas.cgi', Locked = true;
        NamespaceTxt: Label 'http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.3', Locked = true;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure LookupRegistrationFromService(ShowErrors: Boolean)
    var
        ResponseTempBlob: Codeunit "Temp Blob";
    begin
        SendRequest(ResponseTempBlob, ShowErrors);

        InsertLogEntry(ResponseTempBlob);

        Commit();
    end;

    local procedure SendRequest(var ResponseTempBlob: Codeunit "Temp Blob"; ShowErrors: Boolean)
    var
        RegNoSrvConfig: Record "Reg. No. Srv Config";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseInStream: InStream;
        URL: Text;
    begin
        URL := StrSubstNo('%1?ico=%2', RegNoSrvConfig.GetRegNoURL, RegistrationLog."Registration No.");

        HttpWebRequestMgt.Initialize(URL);

        if not GuiAllowed then
            HttpWebRequestMgt.DisableUI;

        ResponseTempBlob.CreateInStream(ResponseInStream);
        if not HttpWebRequestMgt.GetResponseStream(ResponseInStream) then
            if ShowErrors then
                HttpWebRequestMgt.ProcessFaultResponse('');
    end;

    local procedure InsertLogEntry(ResponseTempBlob: Codeunit "Temp Blob")
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDoc: DotNet XmlDocument;
        ResponseInStream: InStream;
    begin
        ResponseTempBlob.CreateInStream(ResponseInStream);
        XMLDOMManagement.LoadXMLDocumentFromInStream(ResponseInStream, XmlDoc);
        RegistrationLogMgt.LogVerification(RegistrationLog, XmlDoc, NamespaceTxt);
    end;

    procedure GetRegistrationNoValidationWebServiceURL(): Text[250]
    begin
        exit(RegNoValidationWebServiceURLTxt);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetRegistrationLog(RegnLog: Record "Registration Log")
    begin
        RegistrationLog := RegnLog;
    end;
}

