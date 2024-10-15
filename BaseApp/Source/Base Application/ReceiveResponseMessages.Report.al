report 11408 "Receive Response Messages"
{
    Caption = 'Receive Response Messages';
    Permissions = TableData "Elec. Tax Decl. Response Msg." = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Elec. Tax Declaration Header"; "Elec. Tax Declaration Header")
        {

            trigger OnAfterGetRecord()
            var
                ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
                ErrorLog: Record "Elec. Tax Decl. Error Log";
                EnvironmentInfo: Codeunit "Environment Information";
                StatusService: DotNet DigipoortServices;
                Request: DotNet getStatussenProcesRequest;
                StatusResultatQueue: DotNet Queue;
                StatusResultat: DotNet StatusResultaat;
                MessageBLOB: OutStream;
                ClientCertificateInStream: InStream;
                ServiceCertificateInStream: InStream;
                NextNo: Integer;
                FoundXmlContent: Boolean;
                StatusDetails: Text;
                StatusErrorDescription: Text;
            begin
                if "Message ID" = '' then
                    CurrReport.Skip;

                Window.Update(1, WindowStatusDeletingMsg);
                ElecTaxDeclResponseMsg.SetRange("Declaration Type", "Declaration Type");
                ElecTaxDeclResponseMsg.SetRange("Declaration No.", "No.");
                ElecTaxDeclResponseMsg.DeleteAll;
                ElecTaxDeclResponseMsg.Reset;

                ErrorLog.SetRange("Declaration Type", "Declaration Type");
                ErrorLog.SetRange("Declaration No.", "No.");
                ErrorLog.DeleteAll;

                Window.Update(1, WindowStatusRequestingMsg);
                Request := Request.getStatussenProcesRequest;
                with Request do begin
                    kenmerk := "Elec. Tax Declaration Header"."Message ID";
                    autorisatieAdres := 'http://geenausp.nl'
                end;

                if EnvironmentInfo.IsSaaS then begin
                    ClientCertificateTempBlob.CreateInStream(ClientCertificateInStream, TEXTENCODING::Windows);
                    ServiceCertificateTempBlob.CreateInStream(ServiceCertificateInStream, TEXTENCODING::Windows);
                    StatusResultatQueue := StatusService.GetStatus(Request,
                        ElecTaxDeclarationSetup."Digipoort Status URL",
                        ClientCertificateInStream,
                        ClientCertificatePassword,
                        ServiceCertificateInStream,
                        30);
                end else
                    StatusResultatQueue := StatusService.GetStatus(Request,
                        ElecTaxDeclarationSetup."Digipoort Status URL",
                        ElecTaxDeclarationSetup."Digipoort Client Cert. Name",
                        ElecTaxDeclarationSetup."Digipoort Service Cert. Name",
                        30);

                Window.Update(1, WindowStatusProcessingMsg);
                ElecTaxDeclResponseMsg.Reset;
                if not ElecTaxDeclResponseMsg.FindLast then
                    ElecTaxDeclResponseMsg."No." := 0;
                NextNo := ElecTaxDeclResponseMsg."No." + 1;

                while StatusResultatQueue.Count > 0 do begin
                    StatusResultat := StatusResultatQueue.Dequeue;
                    if StatusResultat.statuscode <> '-1' then begin
                        with ElecTaxDeclResponseMsg do begin
                            Init;
                            "No." := NextNo;
                            NextNo += 1;
                            "Declaration Type" := "Elec. Tax Declaration Header"."Declaration Type";
                            "Declaration No." := "Elec. Tax Declaration Header"."No.";
                            Subject := CopyStr(StatusResultat.statusomschrijving, 1, MaxStrLen(Subject));
                            "Status Code" := CopyStr(StatusResultat.statuscode, 1, MaxStrLen("Status Code"));

                            FoundXmlContent := false;
                            Message.CreateOutStream(MessageBLOB);

                            StatusErrorDescription := StatusResultat.statusFoutcode.foutbeschrijving;
                            if StatusErrorDescription <> '' then
                                if StatusErrorDescription[1] = '<' then begin
                                    MessageBLOB.WriteText(StatusErrorDescription);
                                    FoundXmlContent := true;
                                end;

                            StatusDetails := StatusResultat.statusdetails;
                            if StatusDetails <> '' then
                                if StatusDetails[1] = '<' then begin
                                    MessageBLOB.WriteText(StatusDetails);
                                    FoundXmlContent := true;
                                end;

                            if FoundXmlContent then
                                "Status Description" := CopyStr(BlobContentStatusMsg, 1, MaxStrLen("Status Description"))
                            else begin
                                if StatusErrorDescription <> '' then
                                    "Status Description" := CopyStr(StatusErrorDescription, 1, MaxStrLen("Status Description"))
                                else
                                    "Status Description" := CopyStr(StatusDetails, 1, MaxStrLen("Status Description"));
                            end;

                            "Date Sent" := Format(StatusResultat.tijdstempelStatus);
                            Status := Status::Received;
                            Insert(true);
                        end;
                    end else
                        Error(StatusResultat.statusFoutcode.foutbeschrijving);
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field("Client Certificate"; ClientCertificateFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Certificate';
                    ToolTip = 'Specifies Client Certificate.';

                    trigger OnAssistEdit()
                    begin
                        ClientCertificateFileName :=
                          FileManagement.BLOBImportWithFilter(ClientCertificateTempBlob, ImportFileTxt, '', 'P12 Files (*.p12)|*.p12', '.p12');
                    end;
                }
                field("Client Certificate Password"; ClientCertificatePassword)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Certificate Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies a password for accessing the Client Certificate file.';
                }
                field("Service Certificate"; ServiceCertificateFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Certificate';
                    ToolTip = 'Specifies Service Certificate.';

                    trigger OnAssistEdit()
                    begin
                        ServiceCertificateFileName :=
                          FileManagement.BLOBImportWithFilter(
                            ServiceCertificateTempBlob, ImportFileTxt, '', 'CER Files (*.cer)|*.cer|CRT Files (*.crt)|*.crt', '.crt,.cer');
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Window.Close;
    end;

    trigger OnPreReport()
    begin
        Window.Open(DialogTxt);

        ElecTaxDeclarationSetup.Get;
        ElecTaxDeclarationSetup.CheckDigipoortSetup;
    end;

    var
        DialogTxt: Label 'Receiving Electronic Tax Declaration Responses...\\Status          #1##################';
        WindowStatusRequestingMsg: Label 'Requesting status information';
        WindowStatusProcessingMsg: Label 'Processing data';
        WindowStatusDeletingMsg: Label 'Removing old status data';
        BlobContentStatusMsg: Label 'Extended content';
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        ClientCertificateTempBlob: Codeunit "Temp Blob";
        ServiceCertificateTempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        Window: Dialog;
        ClientCertificateFileName: Text;
        ServiceCertificateFileName: Text;
        ClientCertificatePassword: Text;
        ImportFileTxt: Label 'Select a file to import.';
}

