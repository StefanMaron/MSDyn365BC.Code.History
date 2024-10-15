codeunit 11754 "Reg. Lookup Ext. Data CZL"
{
    TableNo = "Registration Log CZL";

    trigger OnRun()
    begin
        RegistrationLogCZL := Rec;
        LookupRegistrationFromService();
        Rec := RegistrationLogCZL;
    end;

    var
        RegistrationLogCZL: Record "Registration Log CZL";
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";

    procedure LookupRegistrationFromService()
    begin
        InsertLogEntry(SendRequest());
        Commit();
    end;

    local procedure SendRequest() HttpResponseMessage: HttpResponseMessage
    var
        RegNoServiceConfigCZL: Record "Reg. No. Service Config CZL";
        HttpClient: HttpClient;
        RequestURL: Text;
        RegNoTok: Label '%1/%2', Locked = true, Comment = '%1 = Registration No. service URL, %2 = Registraton No.';
        ServiceCallErr: Label 'Web service call failed.';
    begin
        RequestURL := StrSubstNo(RegNoTok, RegNoServiceConfigCZL.GetRegNoURL(), RegistrationLogCZL."Registration No.");
        if not HttpClient.Get(RequestURL, HttpResponseMessage) then
            Error(ServiceCallErr);
    end;

    local procedure InsertLogEntry(HttpResponseMessage: HttpResponseMessage)
    var
        ResponseObject: JsonObject;
        HttpResponseText: Text;
    begin
        HttpResponseMessage.Content().ReadAs(HttpResponseText);
        ResponseObject.ReadFrom(HttpResponseText);
        if HttpResponseMessage.IsSuccessStatusCode() then
            RegistrationLogMgtCZL.LogVerification(RegistrationLogCZL, ResponseObject)
        else
            RegistrationLogMgtCZL.LogError(RegistrationLogCZL, ResponseObject);
    end;

    procedure GetRegistrationNoValidationWebServiceURL(): Text[250]
    var
        RegNoValidationWebServiceURLTok: Label 'https://ares.gov.cz/ekonomicke-subjekty-v-be/rest/ekonomicke-subjekty', Locked = true;
    begin
        exit(RegNoValidationWebServiceURLTok);
    end;

    procedure SetRegistrationLog(RegistrationLogCZL: Record "Registration Log CZL")
    begin
        RegistrationLogCZL := RegistrationLogCZL;
    end;
}
