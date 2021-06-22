codeunit 452 "Report Distribution Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        HideDialog: Boolean;
        SalesInvoiceDocTypeTxt: Label 'Sales Invoice';
        SalesCrMemoDocTypeTxt: Label 'Sales Credit Memo';
        SalesQuoteDocTypeTxt: Label 'Sales Quote';
        SalesOrderDocTypeTxt: Label 'Sales Order';
        SalesBlanketOrderDocTypeTxt: Label 'Sales Blanket Order';
        SalesReturnOrderDocTypeTxt: Label 'Sales Return Order';
        SalesShipmentDocTypeTxt: Label 'Sales Shipment';
        SalesReturnRcptDocTypeTxt: Label 'Sales Receipt';
        PurchaseInvoiceDocTypeTxt: Label 'Purchase Invoice';
        PurchaseCrMemoDocTypeTxt: Label 'Purchase Credit Memo';
        PurchaseQuoteDocTypeTxt: Label 'Purchase Quote';
        PurchaseOrderDocTypeTxt: Label 'Purchase Order';
        PurchaseBlanketOrderDocTypeTxt: Label 'Purchase Blanket Order';
        PurchaseReturnOrderDocTypeTxt: Label 'Purchase Return Order';
        ServiceInvoiceDocTypeTxt: Label 'Service Invoice';
        ServiceCrMemoDocTypeTxt: Label 'Service Credit Memo';
        ServiceQuoteDocTypeTxt: Label 'Service Quote';
        ServiceOrderDocTypeTxt: Label 'Service Order';
        JobQuoteDocTypeTxt: Label 'Job Quote';
        IssuedReminderDocTypeTxt: Label 'Issued Reminder';
        IssuedFinChargeMemoDocTypeTxt: Label 'Issued Finance Charge Memo';

    [Scope('OnPrem')]
    procedure VANDocumentReport(HeaderDoc: Variant; TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        RecordExportBuffer: Record "Record Export Buffer";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        RecordRef: RecordRef;
        SpecificRecordRef: RecordRef;
        XMLPath: Text[250];
        ClientFileName: Text[250];
    begin
        RecordRef.GetTable(HeaderDoc);
        if RecordRef.FindSet then
            repeat
                SpecificRecordRef.Get(RecordRef.RecordId);
                SpecificRecordRef.SetRecFilter;
                ElectronicDocumentFormat.SendElectronically(
                  XMLPath, ClientFileName, SpecificRecordRef, TempDocumentSendingProfile."Electronic Format");
                if ElectronicDocumentFormat."Delivery Codeunit ID" = 0 then
                    DocExchServiceMgt.SendDocument(SpecificRecordRef, XMLPath)
                else begin
                    RecordExportBuffer.RecordID := SpecificRecordRef.RecordId;
                    RecordExportBuffer.ClientFileName := ClientFileName;
                    RecordExportBuffer.ServerFilePath := XMLPath;
                    RecordExportBuffer."Electronic Document Format" := TempDocumentSendingProfile."Electronic Format";
                    RecordExportBuffer."Document Sending Profile" := TempDocumentSendingProfile.Code;
                    CODEUNIT.Run(ElectronicDocumentFormat."Delivery Codeunit ID", RecordExportBuffer);
                end;
            until RecordRef.Next = 0;
    end;

    procedure DownloadPdfOnClient(ServerPdfFilePath: Text): Text
    var
        FileManagement: Codeunit "File Management";
        ClientPdfFilePath: Text;
    begin
        ClientPdfFilePath := FileManagement.DownloadTempFile(ServerPdfFilePath);
        Erase(ServerPdfFilePath);
        exit(ClientPdfFilePath);
    end;

    procedure InitializeFrom(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure GetFullDocumentTypeText(DocumentVariant: Variant) DocumentTypeText: Text[50]
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        TranslationHelper: Codeunit "Translation Helper";
        DocumentRecordRef: RecordRef;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        TranslationHelper.SetGlobalLanguageByCode(GetDocumentLanguageCode(DocumentVariant));

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                DocumentTypeText := SalesInvoiceDocTypeTxt;
            DATABASE::"Sales Cr.Memo Header":
                DocumentTypeText := SalesCrMemoDocTypeTxt;
            Database::"Sales Shipment Header":
                DocumentTypeText := SalesShipmentDocTypeTxt;
            DATABASE::"Service Invoice Header":
                DocumentTypeText := ServiceInvoiceDocTypeTxt;
            DATABASE::"Service Cr.Memo Header":
                DocumentTypeText := ServiceCrMemoDocTypeTxt;
            DATABASE::Job:
                DocumentTypeText := JobQuoteDocTypeTxt;
            Database::"Return Receipt Header":
                DocumentTypeText := SalesReturnRcptDocTypeTxt;
            Database::"Issued Reminder Header":
                DocumentTypeText := IssuedReminderDocTypeTxt;
            Database::"Issued Fin. Charge Memo Header":
                DocumentTypeText := IssuedFinChargeMemoDocTypeTxt;
            DATABASE::"Sales Header":
                begin
                    DocumentRecordRef.SetTable(SalesHeader);
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Invoice:
                            DocumentTypeText := SalesInvoiceDocTypeTxt;
                        SalesHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := SalesCrMemoDocTypeTxt;
                        SalesHeader."Document Type"::Quote:
                            DocumentTypeText := SalesQuoteDocTypeTxt;
                        SalesHeader."Document Type"::Order:
                            DocumentTypeText := SalesOrderDocTypeTxt;
                        SalesHeader."Document Type"::"Blanket Order":
                            DocumentTypeText := SalesBlanketOrderDocTypeTxt;
                        SalesHeader."Document Type"::"Return Order":
                            DocumentTypeText := SalesReturnOrderDocTypeTxt;
                    end;
                end;
            DATABASE::"Purchase Header":
                begin
                    DocumentRecordRef.SetTable(PurchaseHeader);
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Invoice:
                            DocumentTypeText := PurchaseInvoiceDocTypeTxt;
                        PurchaseHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := PurchaseCrMemoDocTypeTxt;
                        PurchaseHeader."Document Type"::Quote:
                            DocumentTypeText := PurchaseQuoteDocTypeTxt;
                        PurchaseHeader."Document Type"::Order:
                            DocumentTypeText := PurchaseOrderDocTypeTxt;
                        PurchaseHeader."Document Type"::"Blanket Order":
                            DocumentTypeText := PurchaseBlanketOrderDocTypeTxt;
                        PurchaseHeader."Document Type"::"Return Order":
                            DocumentTypeText := PurchaseReturnOrderDocTypeTxt;
                    end;
                end;
            DATABASE::"Service Header":
                begin
                    DocumentRecordRef.SetTable(ServiceHeader);
                    case ServiceHeader."Document Type" of
                        ServiceHeader."Document Type"::Invoice:
                            DocumentTypeText := ServiceInvoiceDocTypeTxt;
                        ServiceHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := ServiceCrMemoDocTypeTxt;
                        ServiceHeader."Document Type"::Quote:
                            DocumentTypeText := ServiceQuoteDocTypeTxt;
                        ServiceHeader."Document Type"::Order:
                            DocumentTypeText := ServiceOrderDocTypeTxt;
                    end;
                end;
        end;

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure GetDocumentLanguageCode(DocumentVariant: Variant): Code[10]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
        DocumentRecordRef: RecordRef;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    exit(SalesInvoiceHeader."Language Code");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentRecordRef.SetTable(SalesCrMemoHeader);
                    exit(SalesCrMemoHeader."Language Code");
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocumentRecordRef.SetTable(ServiceInvoiceHeader);
                    exit(ServiceInvoiceHeader."Language Code");
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentRecordRef.SetTable(ServiceCrMemoHeader);
                    exit(ServiceCrMemoHeader."Language Code");
                end;
            DATABASE::"Sales Header":
                begin
                    DocumentRecordRef.SetTable(SalesHeader);
                    exit(SalesHeader."Language Code");
                end;
            DATABASE::"Purchase Header":
                begin
                    DocumentRecordRef.SetTable(PurchaseHeader);
                    exit(PurchaseHeader."Language Code");
                end;
            DATABASE::"Service Header":
                begin
                    DocumentRecordRef.SetTable(ServiceHeader);
                    exit(ServiceHeader."Language Code");
                end;
            DATABASE::Job:
                begin
                    DocumentRecordRef.SetTable(Job);
                    exit(Job."Language Code");
                end;
        end;
    end;

    local procedure GetBillToCustomer(var Customer: Record Customer; DocumentVariant: Variant)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
        DocumentRecordRef: RecordRef;
    begin
        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := DocumentVariant;
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := DocumentVariant;
                    Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.");
                end;
            DATABASE::"Service Header":
                begin
                    ServiceHeader := DocumentVariant;
                    Customer.Get(ServiceHeader."Bill-to Customer No.");
                end;
            DATABASE::"Sales Header":
                begin
                    SalesHeader := DocumentVariant;
                    Customer.Get(SalesHeader."Bill-to Customer No.");
                end;
            DATABASE::Job:
                begin
                    Job := DocumentVariant;
                    Customer.Get(Job."Bill-to Customer No.");
                end;
        end;
    end;

    local procedure GetBuyFromVendor(var Vendor: Record Vendor; DocumentVariant: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentRecordRef: RecordRef;
    begin
        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Purchase Header":
                begin
                    PurchaseHeader := DocumentVariant;
                    Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveFileOnClient(ServerFilePath: Text; ClientFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DownloadHandler(
          ServerFilePath,
          '',
          '',
          FileManagement.GetToFilterText('', ClientFileName),
          ClientFileName);
    end;

    local procedure SendAttachment(PostedDocumentNo: Code[20]; SendEmailAddress: Text[250]; AttachmentFilePath: Text[250]; AttachmentFileName: Text[250]; DocumentType: Text[50]; SendTo: Option; ServerEmailBodyFilePath: Text[250]; ReportUsage: Enum "Report Selection Usage")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailing: Codeunit "Document-Mailing";
    begin
        if SendTo = DocumentSendingProfile."Send To"::Disk then begin
            SaveFileOnClient(AttachmentFilePath, AttachmentFileName);
            exit;
        end;

        DocumentMailing.EmailFile(
          AttachmentFilePath, AttachmentFileName, ServerEmailBodyFilePath, PostedDocumentNo,
          SendEmailAddress, DocumentType, HideDialog, ReportUsage.AsInteger());
    end;

    [Scope('OnPrem')]
    procedure SendXmlEmailAttachment(DocumentVariant: Variant; DocumentFormat: Code[20]; ServerEmailBodyFilePath: Text[250]; SendToEmailAddress: Text[250])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        XMLPath: Text[250];
        ClientFileName: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        GetBillToCustomer(Customer, DocumentVariant);

        if SendToEmailAddress = '' then
            SendToEmailAddress := DocumentMailing.GetToAddressFromCustomer(Customer."No.");

        DocumentSendingProfile.Get(Customer."Document Sending Profile");
        if DocumentSendingProfile.Usage = DocumentSendingProfile.Usage::"Job Quote" then
            ReportUsage := ReportSelections.Usage::JQ;

        ElectronicDocumentFormat.SendElectronically(XMLPath, ClientFileName, DocumentVariant, DocumentFormat);
        Commit();
        SendAttachment(
          ElectronicDocumentFormat.GetDocumentNo(DocumentVariant),
          SendToEmailAddress,
          XMLPath,
          ClientFileName,
          GetFullDocumentTypeText(DocumentVariant),
          DocumentSendingProfile."Send To"::"Electronic Document",
          ServerEmailBodyFilePath, ReportUsage);
    end;

    [Scope('OnPrem')]
    procedure SendXmlEmailAttachmentVendor(DocumentVariant: Variant; DocumentFormat: Code[20]; ServerEmailBodyFilePath: Text[250]; SendToEmailAddress: Text[250])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        Vendor: Record Vendor;
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        XMLPath: Text[250];
        ClientFileName: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        GetBuyFromVendor(Vendor, DocumentVariant);

        if SendToEmailAddress = '' then
            SendToEmailAddress := DocumentMailing.GetToAddressFromVendor(Vendor."No.");

        DocumentSendingProfile.Get(Vendor."Document Sending Profile");

        if DocumentSendingProfile.Usage = DocumentSendingProfile.Usage::"Job Quote" then
            ReportUsage := ReportSelections.Usage::JQ;

        ElectronicDocumentFormat.SendElectronically(XMLPath, ClientFileName, DocumentVariant, DocumentFormat);
        Commit();
        SendAttachment(
          ElectronicDocumentFormat.GetDocumentNo(DocumentVariant),
          SendToEmailAddress,
          XMLPath,
          ClientFileName,
          GetFullDocumentTypeText(DocumentVariant),
          DocumentSendingProfile."Send To"::"Electronic Document",
          ServerEmailBodyFilePath, ReportUsage);
    end;

    [Scope('OnPrem')]
    procedure RunDefaultCheckSalesElectronicDocument(SalesHeader: Record "Sales Header")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunDefaultCheckSalesElectronicDocument(SalesHeader, IsHandled);
        if IsHandled then
            exit;
        GetElectronicDocumentFormat(ElectronicDocumentFormat, SalesHeader);

        ElectronicDocumentFormat.ValidateElectronicSalesDocument(SalesHeader, ElectronicDocumentFormat.Code);
    end;

    [Scope('OnPrem')]
    procedure RunDefaultCheckServiceElectronicDocument(ServiceHeader: Record "Service Header")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        GetElectronicDocumentFormat(ElectronicDocumentFormat, ServiceHeader);

        ElectronicDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, ElectronicDocumentFormat.Code);
    end;

    local procedure GetElectronicDocumentFormat(var ElectronicDocumentFormat: Record "Electronic Document Format"; DocumentVariant: Variant)
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        GetBillToCustomer(Customer, DocumentVariant);

        if not DocumentSendingProfile.GET(Customer."Document Sending Profile") then
            exit;

        if DocumentSendingProfile.Disk in
           [DocumentSendingProfile.Disk::"Electronic Document", DocumentSendingProfile.Disk::"PDF & Electronic Document"]
        then
            IF NOT ElectronicDocumentFormat.GET(DocumentSendingProfile."Disk Format") then
                exit;

        IF DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::No then
            IF NOT ElectronicDocumentFormat.GET(DocumentSendingProfile."Electronic Format") then
                exit;
    end;

    [Scope('OnPrem')]
    procedure CreateOrAppendZipFile(var DataCompression: Codeunit "Data Compression"; ServerFilePath: Text[250]; ClientFileName: Text[250]; var ClientZipFileName: Text[250])
    var
        FileManagement: Codeunit "File Management";
        ServerTempBlob: Codeunit "Temp Blob";
        ServerFile: File;
        ServerFileInStream: InStream;
        IsGZip: Boolean;
    begin
        ServerFile.Open(ServerFilePath);
        ServerFile.CreateInStream(ServerFileInStream);
        IsGZip := DataCompression.IsGZip(ServerFileInStream);
        if IsGZip then begin
            DataCompression.OpenZipArchive(ServerFileInStream, true);
            ClientZipFileName := ClientFileName;
        end else begin
            DataCompression.CreateZipArchive;
            FileManagement.BLOBImportFromServerFile(ServerTempBlob, ServerFilePath);
            ServerTempBlob.CreateInStream(ServerFileInStream);
            DataCompression.AddEntry(ServerFileInStream, ClientFileName);
            ClientZipFileName := CopyStr(FileManagement.GetFileNameWithoutExtension(ClientFileName) + '.zip', 1, 250);
        end;
        ServerFile.Close;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunDefaultCheckSalesElectronicDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

