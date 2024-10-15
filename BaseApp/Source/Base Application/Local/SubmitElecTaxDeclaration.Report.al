report 11405 "Submit Elec. Tax Declaration"
{
    Caption = 'Submit Elec. Tax Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Elec. Tax Declaration Header"; "Elec. Tax Declaration Header")
        {
            DataItemTableView = SORTING("Declaration Type", "No.");
            MaxIteration = 1;
            dataitem("Elec. Tax Declaration Line"; "Elec. Tax Declaration Line")
            {
                DataItemLink = "Declaration Type" = FIELD("Declaration Type"), "Declaration No." = FIELD("No.");
                DataItemTableView = SORTING("Declaration Type", "Declaration No.", "Indentation Level") WHERE("Indentation Level" = CONST(0));

                trigger OnAfterGetRecord()
                begin
                    TestField("Line Type", "Line Type"::Element);

                    AddDeclarationLine(XMLDoc, "Elec. Tax Declaration Line");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // Note: MaxIteration = 1 for this data item!
                AppendProcessingInstruction(XMLDoc, 'xml', 'version="1.0" encoding="UTF-8" standalone="yes"');

                OnPreExport();
                TestField(Status, Status::Created);
            end;

            trigger OnPostDataItem()
            var
                EnvironmentInfo: Codeunit "Environment Information";
                ElecTaxDeclarationMgt: Codeunit "Elec. Tax Declaration Mgt.";
                XMLDOMMgt: Codeunit "XML DOM Management";
                DotNet_SecureString: Codeunit DotNet_SecureString;
                DeliveryService: DotNet DigipoortServices;
                Request: DotNet aanleverRequest;
                Response: DotNet aanleverResponse;
                Identity: DotNet identiteitType;
                Content: DotNet berichtInhoudType;
                Fault: DotNet foutType;
                UTF8Encoding: DotNet UTF8Encoding;
                DotNetSecureString: DotNet SecureString;
                ClientCertificateBase64: Text;
                ServiceCertificateBase64: Text;
                ClientCertificateInStream: InStream;
                ServiceCertificateInStream: InStream;
                PreviewFileStream: OutStream;
                BlobOutStream: OutStream;
                PreviewFile: File;
                UseVATRegNo: Text[20];
            begin
                "Submission Message BLOB".CreateOutStream(BlobOutStream, TEXTENCODING::UTF8);
                BlobOutStream.WriteText(XMLDOMMgt.XMLTextIndent(XMLDoc.InnerXml));
                if SaveToFile <> '' then begin
                    PreviewFile.Create(SaveToFile);
                    PreviewFile.CreateOutStream(PreviewFileStream);
                    PreviewFileStream.Write(XMLDoc.InnerXml);
                    PreviewFile.Close();
                    exit;
                end;
                if GenerateSubmissionMessageOnly then begin
                    Modify();
                    exit;
                end;

                Session.LogMessage('0000CEK', SubmitDeclarationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);

                Window.Update(1, WindowStatusBuildingMsg);
                Request := Request.aanleverRequest();
                Response := Response.aanleverResponse();
                Identity := Identity.identiteitType();
                Content := Content.berichtInhoudType();
                Fault := Fault.foutType();

                UTF8Encoding := UTF8Encoding.UTF8Encoding();

                UseVATRegNo := CompanyInfo.GetVATIdentificationNo(ElecTaxDeclarationSetup."Part of Fiscal Entity");

                with Identity do begin
                    nummer := UseVATRegNo;
                    type := 'Fi';
                end;

                with Content do begin
                    mimeType := 'application/xml';
                    bestandsnaam := StrSubstNo('%1.xbrl', "Elec. Tax Declaration Header".GetDocType());
                    inhoud := UTF8Encoding.GetBytes(XMLDoc.InnerXml);
                end;

                with Request do begin
                    berichtsoort := "Elec. Tax Declaration Header".GetDocType();
                    aanleverkenmerk := "Our Reference";
                    identiteitBelanghebbende := Identity;
                    rolBelanghebbende := 'Bedrijf';
                    berichtInhoud := Content;
                    autorisatieAdres := 'http://geenausp.nl'
                end;

                Window.Update(1, WindowStatusSendMsg);

                if ElecTaxDeclarationSetup."Use Certificate Setup" then begin
                    ElecTaxDeclarationMgt.InitCertificatesWithPassword(ClientCertificateBase64, DotNet_SecureString, ServiceCertificateBase64);
                    DotNet_SecureString.GetSecureString(DotNetSecureString);
                    Response := DeliveryService.Deliver(Request,
                        ElecTaxDeclarationSetup."Digipoort Delivery URL",
                        ClientCertificateBase64,
                        DotNetSecureString,
                        ServiceCertificateBase64,
                        30);
                end else
                    if EnvironmentInfo.IsSaaS() then begin
                        ClientCertificateTempBlob.CreateInStream(ClientCertificateInStream, TEXTENCODING::Windows);
                        ServiceCertificateTempBlob.CreateInStream(ServiceCertificateInStream, TEXTENCODING::Windows);
                        Response := DeliveryService.Deliver(Request,
                            ElecTaxDeclarationSetup."Digipoort Delivery URL",
                            ClientCertificateInStream,
                            ClientCertificatePassword,
                            ServiceCertificateInStream,
                            30);
                    end else
                        Response := DeliveryService.Deliver(Request,
                            ElecTaxDeclarationSetup."Digipoort Delivery URL",
                            ElecTaxDeclarationSetup."Digipoort Client Cert. Name",
                            ElecTaxDeclarationSetup."Digipoort Service Cert. Name",
                            30);

                Fault := Response.statusFoutcode;
                if Fault.foutcode <> '' then begin
                    Session.LogMessage('0000CEL', StrSubstNo(SubmitDeclarationErrMsg, Fault.foutcode), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                    Error(SubmitErr, "No.", Fault.foutcode, Fault.foutbeschrijving);
                end;

                Window.Update(1, WindowStatusSaveMsg);
                "Message ID" := Response.kenmerk;
                Status := Status::Submitted;
                "Date Submitted" := Today;
                "Time Submitted" := Time;
                "Submitted By" := UserId;
                Modify();
                Commit();

                Window.Close();
                Session.LogMessage('0000CEM', SubmitDeclarationSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DigipoortTok);
                Message(StrSubstNo(SubmitSuccessMsg, "No."));
            end;

            trigger OnPreDataItem()
            begin
                XMLDoc := XMLDoc.XmlDocument();
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
                            ServiceCertificateTempBlob, ImportFileTxt, '',
                            'DER Files (*.der)|*.der|CER Files (*.cer)|*.cer|CRT Files (*.crt)|*.crt|PEM Files (*.pem)|*.pem', '.crt,.cer,.der,.pem');
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

    trigger OnInitReport()
    begin
        SaveToFile := '';

        CompanyInfo.Get();
        CompanyInfo.TestField("VAT Registration No.");

        ElecTaxDeclarationSetup.Get();
        ElecTaxDeclarationSetup.CheckDigipoortSetup();

        Window.Open(WindowStatusMsg);
    end;

    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        CompanyInfo: Record "Company Information";
        ClientCertificateTempBlob: Codeunit "Temp Blob";
        ServiceCertificateTempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XMLDoc: DotNet XmlDocument;
        Window: Dialog;
        SubmitSuccessMsg: Label 'Declaration %1 was submitted successfully.';
        SubmitErr: Label 'Submission of declaration %1 failed with error code %2 and the following message: \\%3.', Comment = '%1 = Fault.foutcode, %2 = Fault.foutbeschrijving';
        WindowStatusMsg: Label 'Submitting Electronic Tax Declaration...\\Status          #1##################';
        WindowStatusBuildingMsg: Label 'Building document';
        WindowStatusSendMsg: Label 'Transmitting document';
        WindowStatusSaveMsg: Label 'Saving document ID';
        GenerateSubmissionMessageOnly: Boolean;
        SaveToFile: Text;
        ImportFileTxt: Label 'Select a file to import.';
        ClientCertificateFileName: Text;
        ServiceCertificateFileName: Text;
        ClientCertificatePassword: Text;
        // fault model labels
        DigipoortTok: Label 'DigipoortTelemetryCategoryTok', Locked = true;
        SubmitDeclarationMsg: Label 'Submitting tax declaration', Locked = true;
        SubmitDeclarationSuccessMsg: Label 'Tax declaration successfully submitted', Locked = true;
        SubmitDeclarationErrMsg: Label 'Tax declaration submission failed with StatusCode: %1', Locked = true;

    local procedure AddDeclarationLine(Parent: DotNet XmlNode; ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line")
    var
        NewNode: DotNet XmlNode;
    begin
        case ElecTaxDeclarationLine."Line Type" of
            ElecTaxDeclarationLine."Line Type"::Element:
                begin
                    AppendElement(Parent, ElecTaxDeclarationLine, NewNode);

                    // Append child lines recursively
                    ElecTaxDeclarationLine.Reset();
                    ElecTaxDeclarationLine.SetCurrentKey("Declaration Type", "Declaration No.", "Parent Line No.");
                    ElecTaxDeclarationLine.SetRange("Declaration Type", ElecTaxDeclarationLine."Declaration Type");
                    ElecTaxDeclarationLine.SetRange("Declaration No.", ElecTaxDeclarationLine."Declaration No.");
                    ElecTaxDeclarationLine.SetRange("Parent Line No.", ElecTaxDeclarationLine."Line No.");

                    if ElecTaxDeclarationLine.Find('-') then
                        repeat
                            AddDeclarationLine(NewNode, ElecTaxDeclarationLine);
                        until ElecTaxDeclarationLine.Next() = 0;
                end;
            ElecTaxDeclarationLine."Line Type"::Attribute:
                AppendAttribute(Parent, ElecTaxDeclarationLine.Name, ElecTaxDeclarationLine.Data, ElecTaxDeclarationLine);
        end;
    end;

    local procedure AppendProcessingInstruction(Parent: DotNet XmlNode; Target: Text[80]; Data: Text[250])
    var
        ProcessingInstruction: DotNet XmlProcessingInstruction;
    begin
        ProcessingInstruction := XMLDoc.CreateProcessingInstruction(Target, Data);
        Parent.AppendChild(ProcessingInstruction);
    end;

    local procedure AppendElement(Parent: DotNet XmlNode; var ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line"; var Element: DotNet XmlElement)
    var
        LocName: Text;
        Namespace: Text;
        NamespaceUri: Text;
    begin
        if StrPos(ElecTaxDeclarationLine.Name, ':') = 0 then
            Element := XMLDoc.CreateElement(ElecTaxDeclarationLine.Name)
        else begin
            LocName := CopyStr(ElecTaxDeclarationLine.Name, 1, StrPos(ElecTaxDeclarationLine.Name, ':') - 1);
            Namespace :=
              CopyStr(
                ElecTaxDeclarationLine.Name, StrPos(ElecTaxDeclarationLine.Name, ':') + 1,
                StrLen(ElecTaxDeclarationLine.Name) - StrPos(ElecTaxDeclarationLine.Name, ':'));

            NamespaceUri := GetUri(LocName, ElecTaxDeclarationLine);
            if NamespaceUri <> '' then
                Element := XMLDoc.CreateElement(LocName, Namespace, NamespaceUri)
            else
                Element := XMLDoc.CreateElement(LocName, Namespace);
        end;
        if ElecTaxDeclarationLine.Data <> '' then
            Element.InnerText := ElecTaxDeclarationLine.Data;
        Parent.AppendChild(Element);
    end;

    local procedure AppendAttribute(Parent: DotNet XmlElement; Name: Text[80]; Data: Text[250]; ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line")
    var
        LocName: Text;
        Namespace: Text;
        NamespaceUri: Text;
    begin
        if StrPos(Name, ':') = 0 then
            Parent.SetAttribute(Name, Data)
        else begin
            LocName := CopyStr(Name, 1, StrPos(Name, ':') - 1);
            Namespace := CopyStr(Name, StrPos(Name, ':') + 1, StrLen(Name) - StrPos(Name, ':'));

            NamespaceUri := GetUri(LocName, ElecTaxDeclarationLine);
            if NamespaceUri <> '' then
                Parent.SetAttribute(Namespace, NamespaceUri, Data)
            else
                Parent.SetAttribute(Name, Data);
        end;
    end;

    local procedure GetUri(TargetNamespace: Text; TargetElecTaxDeclarationLine: Record "Elec. Tax Declaration Line"): Text
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        with ElecTaxDeclarationLine do begin
            SetRange("Declaration Type", TargetElecTaxDeclarationLine."Declaration Type");
            SetRange("Declaration No.", TargetElecTaxDeclarationLine."Declaration No.");
            if FindSet() then
                repeat
                    if StrPos(Name, ':') <> 0 then begin
                        if TargetNamespace = CopyStr(Name, StrPos(Name, ':') + 1, StrLen(Name) - StrPos(Name, ':'))
                        then
                            exit(Data);
                    end;
                until (Next() = 0) or (TargetElecTaxDeclarationLine."Line No." = "Line No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure PreviewOnly(Filename: Text)
    begin
        SaveToFile := Filename;
    end;

    procedure SetGenerateSubmissionMessageOnly()
    begin
        GenerateSubmissionMessageOnly := true;
    end;
}

