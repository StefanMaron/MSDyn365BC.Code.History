codeunit 11409 "Elec. Tax Declaration Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        SchemaVersionTxt: Label '2019v13.0', Locked = true;
        BDDataEndpointTxt: Label 'http://www.nltaxonomie.nl/nt14/bd/20191211/dictionary/bd-data', Locked = true;
        BDTuplesEndpointTxt: Label 'http://www.nltaxonomie.nl/nt14/bd/20191211/dictionary/bd-tuples', Locked = true;
        VATDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt14/bd/20191211/entrypoints/bd-rpt-ob-aangifte-2020.xsd', Locked = true;
        ICPDeclarationSchemaEndpointTxt: Label 'http://www.nltaxonomie.nl/nt14/bd/20191211/entrypoints/bd-rpt-icp-opgaaf-2020.xsd', Locked = true;
        CannotDeleteCertificateErr: Label 'You cannot delete certificate since it is used in table %1, field %2.', Comment = '%1 - table caption;%2 - field caption.';
        SubmitErr: Label 'Submission of declaration %1 failed with error code %2 and the following message: \\%3.', Comment = '%1 = Fault.foutcode, %2 = Fault.foutbeschrijving, %3 = message text.';
        WindowStatusMsg: Label 'Submitting Electronic Tax Declaration...\\Status          #1##################', Comment = '%1 - any text that represents the status';
        WindowStatusBuildingMsg: Label 'Building document';
        WindowStatusSendMsg: Label 'Transmitting document';
        DialogTxt: Label 'Receiving Electronic Tax Declaration Responses...\\Status          #1##################', Comment = '%1 = status text.';
        WindowStatusRequestingMsg: Label 'Requesting status information';
        WindowStatusProcessingMsg: Label 'Processing data';
        WindowStatusDeletingMsg: Label 'Removing old status data';
        BlobContentStatusMsg: Label 'Extended content';
        // fault model labels
        DigipoortTok: Label 'DigipoortTelemetryCategoryTok', Locked = true;
        SubmitDeclarationMsg: Label 'Submitting tax declaration', Locked = true;
        SubmitDeclarationSuccessMsg: Label 'Tax declaration successfully submitted', Locked = true;
        SubmitDeclarationErrMsg: Label 'Tax declaration submission failed with StatusCode: %1', Locked = true;
        ReceiveResponseMsg: Label 'Receiving response', Locked = true;
        ReceiveResponseSuccessMsg: Label 'Response successfully received', Locked = true;
        ReceiveResponseErrMsg: Label 'The response contains a error', Locked = true;
        UnknownStatusCodeErr: Label 'Unknown response status code', Locked = true;

    [NonDebuggable]
    procedure SubmitDeclaration(VATReportHeader: Record "VAT Report Header"; VATReportArchive: Record "VAT Report Archive"; ClientCertificateBase64: Text; DotNet_SecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text): Text
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInformation: Record "Company Information";
        DotNet_StreamReader: Codeunit DotNet_StreamReader;
        Window: Dialog;
        DotNetSecureString: DotNet SecureString;
        DeliveryService: DotNet DigipoortServices;
        Request: DotNet aanleverRequest;
        Response: DotNet aanleverResponse;
        Identity: DotNet identiteitType;
        Content: DotNet berichtInhoudType;
        Fault: DotNet foutType;
        UTF8Encoding: DotNet UTF8Encoding;
        RequestInStream: InStream;
        RequestText: Text;
    begin
        SendTraceTag('0000CJ9', DigipoortTok, VERBOSITY::Normal, SubmitDeclarationMsg, DATACLASSIFICATION::SystemMetadata);

        Window.Open(WindowStatusMsg);
        Window.Update(1, WindowStatusBuildingMsg);
        Request := Request.aanleverRequest();
        Response := Response.aanleverResponse();
        Identity := Identity.identiteitType();
        Content := Content.berichtInhoudType();
        Fault := Fault.foutType();

        UTF8Encoding := UTF8Encoding.UTF8Encoding();

        ElecTaxDeclarationSetup.Get();
        CompanyInformation.Get();
        with Identity do begin
            nummer := CompanyInformation.GetVATIdentificationNo(ElecTaxDeclarationSetup."Part of Fiscal Entity");
            type := 'Fi';
        end;

        with Content do begin
            mimeType := 'application/xml';
            bestandsnaam := StrSubstNo('%1.xbrl', GetSubmissionDocType());
            VATReportArchive."Submission Message BLOB".CreateInStream(RequestInStream);
            DotNet_StreamReader.StreamReader(RequestInStream, false);
            RequestText := DotNet_StreamReader.ReadToEnd();
            inhoud := UTF8Encoding.GetBytes(RequestText);
        end;

        with Request do begin
            berichtsoort := GetSubmissionDocType();
            aanleverkenmerk := VATReportHeader."Additional Information";
            identiteitBelanghebbende := Identity;
            rolBelanghebbende := 'Bedrijf';
            berichtInhoud := Content;
            autorisatieAdres := 'http://geenausp.nl'
        end;

        Window.Update(1, WindowStatusSendMsg);

        DotNet_SecureString.GetSecureString(DotNetSecureString);
        Response := DeliveryService.Deliver(Request,
            ElecTaxDeclarationSetup."Digipoort Delivery URL",
            ClientCertificateBase64,
            DotNetSecureString,
            ServiceCertificateBase64,
            30);

        Fault := Response.statusFoutcode();
        if Fault.foutcode() <> '' then begin
            SendTraceTag('0000CJA', DigipoortTok, VERBOSITY::Error, StrSubstNo(SubmitDeclarationErrMsg, Fault.foutcode), DATACLASSIFICATION::SystemMetadata);
            Error(SubmitErr, VATReportHeader."No.", Fault.foutcode(), Fault.foutbeschrijving());
        end;
        Window.Close();
        SendTraceTag('0000CJB', DigipoortTok, VERBOSITY::Normal, SubmitDeclarationSuccessMsg, DATACLASSIFICATION::SystemMetadata);
        exit(Response.kenmerk());
    end;

    [NonDebuggable]
    procedure ReceiveResponse(VATReportHeader: Record "VAT Report Header"; ClientCertificateBase64: Text; DotNet_SecureString: Codeunit DotNet_SecureString; ServiceCertificateBase64: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
        ErrorLog: Record "Elec. Tax Decl. Error Log";
        Window: Dialog;
        StatusService: DotNet DigipoortServices;
        Request: DotNet getStatussenProcesRequest;
        StatusResultatQueue: DotNet Queue;
        StatusResultat: DotNet StatusResultaat;
        DotNetSecureString: DotNet SecureString;
        MessageBLOB: OutStream;
        NextNo: Integer;
        FoundXmlContent: Boolean;
        StatusDetails: Text;
        StatusErrorDescription: Text;
    begin
        with VATReportHeader do begin
            if "Message Id" = '' then
                exit;

            SendTraceTag('0000CJC', DigipoortTok, VERBOSITY::Normal, ReceiveResponseMsg, DATACLASSIFICATION::SystemMetadata);

            Window.Open(DialogTxt);
            Window.Update(1, WindowStatusDeletingMsg);
            ElecTaxDeclResponseMsg.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
            ElecTaxDeclResponseMsg.SetRange("VAT Report No.", "No.");
            ElecTaxDeclResponseMsg.DeleteAll();
            ElecTaxDeclResponseMsg.Reset();

            ErrorLog.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
            ErrorLog.SetRange("VAT Report No.", "No.");
            ErrorLog.DeleteAll();

            Window.Update(1, WindowStatusRequestingMsg);
            Request := Request.getStatussenProcesRequest();
            Request.kenmerk := "Message Id";
            Request.autorisatieAdres := 'http://geenausp.nl';

            DotNet_SecureString.GetSecureString(DotNetSecureString);
            ElecTaxDeclarationSetup.Get();
            StatusResultatQueue := StatusService.GetStatus(Request,
                ElecTaxDeclarationSetup."Digipoort Status URL",
                ClientCertificateBase64,
                DotNetSecureString,
                ServiceCertificateBase64,
                30);

            Window.Update(1, WindowStatusProcessingMsg);
            ElecTaxDeclResponseMsg.Reset();
            if not ElecTaxDeclResponseMsg.FindLast() then
                ElecTaxDeclResponseMsg."No." := 0;
            NextNo := ElecTaxDeclResponseMsg."No." + 1;

            while StatusResultatQueue.Count() > 0 do begin
                StatusResultat := StatusResultatQueue.Dequeue();
                if StatusResultat.statuscode() <> '-1' then begin
                    ElecTaxDeclResponseMsg.Init();
                    ElecTaxDeclResponseMsg."No." := NextNo;
                    NextNo += 1;
                    ElecTaxDeclResponseMsg."VAT Report Config. Code" := "VAT Report Config. Code";
                    ElecTaxDeclResponseMsg."VAT Report No." := "No.";
                    ElecTaxDeclResponseMsg.Subject := CopyStr(StatusResultat.statusomschrijving(), 1, MaxStrLen(ElecTaxDeclResponseMsg.Subject));
                    ElecTaxDeclResponseMsg."Status Code" :=
                    CopyStr(StatusResultat.statuscode(), 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Code"));

                    FoundXmlContent := false;
                    ElecTaxDeclResponseMsg.Message.CreateOutStream(MessageBLOB);

                    StatusErrorDescription := StatusResultat.statusFoutcode().foutbeschrijving();
                    if StatusErrorDescription <> '' then
                        if StatusErrorDescription[1] = '<' then begin
                            MessageBLOB.WriteText(StatusErrorDescription);
                            FoundXmlContent := true;
                        end;

                    StatusDetails := StatusResultat.statusdetails();
                    if StatusDetails <> '' then
                        if StatusDetails[1] = '<' then begin
                            MessageBLOB.WriteText(StatusDetails);
                            FoundXmlContent := true;
                        end;

                    if FoundXmlContent then begin
                        ElecTaxDeclResponseMsg."Status Description" := CopyStr(BlobContentStatusMsg, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"));
                        SendTraceTag('0000CJD', DigipoortTok, VERBOSITY::Normal, ReceiveResponseSuccessMsg, DATACLASSIFICATION::SystemMetadata);
                    end else begin
                        SendTraceTag('0000CJE', DigipoortTok, VERBOSITY::Error, ReceiveResponseErrMsg, DATACLASSIFICATION::SystemMetadata);
                        if StatusErrorDescription <> '' then
                            ElecTaxDeclResponseMsg."Status Description" := CopyStr(StatusErrorDescription, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"))
                        else
                            ElecTaxDeclResponseMsg."Status Description" := CopyStr(StatusDetails, 1, MaxStrLen(ElecTaxDeclResponseMsg."Status Description"));
                    end;

                    ElecTaxDeclResponseMsg."Date Sent" := Format(StatusResultat.tijdstempelStatus());
                    ElecTaxDeclResponseMsg.Status := ElecTaxDeclResponseMsg.Status::Received;
                    ElecTaxDeclResponseMsg.Insert(true);
                end else begin
                    SendTraceTag('0000CJF', DigipoortTok, VERBOSITY::Error, UnknownStatusCodeErr, DATACLASSIFICATION::SystemMetadata);
                    Error(StatusResultat.statusFoutcode().foutbeschrijving());
                end;
            end;
            Window.Close();
        end;
    end;

    procedure GetSchemaVersion() SchemaVersion: Text[10]
    var
        Handled: Boolean;
    begin
        OnBeforeGetSchemaVersion(Handled, SchemaVersion);
        if Handled then
            exit(SchemaVersion);
        exit(SchemaVersionTxt);
    end;

    procedure GetBDDataEndpoint() BDDataEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetBDDataEndpoint(Handled, BDDataEndpoint);
        if Handled then
            exit(BDDataEndpoint);
        exit(BDDataEndpointTxt);
    end;

    procedure GetBDTuplesEndpoint() BDTuplesEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetBDTuplesEndpoint(Handled, BDTuplesEndpoint);
        if Handled then
            exit(BDTuplesEndpoint);
        exit(BDTuplesEndpointTxt);
    end;

    procedure GetVATDeclarationSchemaEndpoint() VATDeclarationSchemaEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetVATDeclarationSchemaEndpoint(Handled, VATDeclarationSchemaEndpoint);
        if Handled then
            exit(VATDeclarationSchemaEndpoint);
        exit(VATDeclarationSchemaEndpointTxt);
    end;

    procedure GetICPDeclarationSchemaEndpoint() ICPDeclarationSchemaEndpoint: Text[250]
    var
        Handled: Boolean;
    begin
        OnBeforeGetICPDeclarationSchemaEndpoint(Handled, ICPDeclarationSchemaEndpoint);
        if Handled then
            exit(ICPDeclarationSchemaEndpoint);
        exit(ICPDeclarationSchemaEndpointTxt);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure InitCertificatesWithPassword(var ClientCertificateBase64: Text; var DotNet_SecureString: Codeunit DotNet_SecureString; var ServiceCertificateBase64: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
    begin
        ElecTaxDeclarationSetup.Get();
        IsolatedCertificate.Get(ElecTaxDeclarationSetup."Client Certificate Code");
        CertificateManagement.GetPasswordAsSecureString(DotNet_SecureString, IsolatedCertificate);
        ClientCertificateBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        IsolatedCertificate.Get(ElecTaxDeclarationSetup."Service Certificate Code");
        ServiceCertificateBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
    end;

    local procedure GetSubmissionDocType(): Text
    begin
        exit('Omzetbelasting');
    end;

    [EventSubscriber(ObjectType::Table, 1262, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteIsolatedCertificate(var Rec: Record "Isolated Certificate"; RunTrigger: Boolean)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.Get();
        if ElecTaxDeclarationSetup."Client Certificate Code" <> '' then
            if Rec.Get(ElecTaxDeclarationSetup."Client Certificate Code") then
                Error(
                  CannotDeleteCertificateErr, ElecTaxDeclarationSetup.TableCaption(),
                  ElecTaxDeclarationSetup.FieldCaption("Client Certificate Code"));
        if ElecTaxDeclarationSetup."Service Certificate Code" <> '' then
            if Rec.Get(ElecTaxDeclarationSetup."Service Certificate Code") then
                Error(
                  CannotDeleteCertificateErr, ElecTaxDeclarationSetup.TableCaption(),
                  ElecTaxDeclarationSetup.FieldCaption("Service Certificate Code"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSchemaVersion(var Handled: Boolean; var SchemaVersion: Text[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBDDataEndpoint(var Handled: Boolean; var BDDataEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBDTuplesEndpoint(var Handled: Boolean; var BDTuplesEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVATDeclarationSchemaEndpoint(var Handled: Boolean; var VATDeclarationSchemaEndpoint: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetICPDeclarationSchemaEndpoint(var Handled: Boolean; var ICPDeclarationSchemaEndpoint: Text[250])
    begin
    end;
}

