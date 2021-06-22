table 61 "Electronic Document Format"
{
    Caption = 'Electronic Document Format';
    LookupPageID = "Electronic Document Format";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Sales Invoice,Sales Credit Memo,Sales Validation,Service Invoice,Service Credit Memo,Service Validation,Job Quote';
            OptionMembers = "Sales Invoice","Sales Credit Memo","Sales Validation","Service Invoice","Service Credit Memo","Service Validation","Job Quote";
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Codeunit ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Codeunit ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit));
        }
        field(6; "Codeunit Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Codeunit),
                                                                           "Object ID" = FIELD("Codeunit ID")));
            Caption = 'Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Delivery Codeunit ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Delivery Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit));
        }
        field(8; "Delivery Codeunit Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Codeunit),
                                                                           "Object ID" = FIELD("Delivery Codeunit ID")));
            Caption = 'Delivery Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code", Usage)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckCodeunitExist;
    end;

    trigger OnModify()
    begin
        CheckCodeunitExist;
    end;

    var
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 = Sales Document Type';
        NonExistingDocumentFormatErr: Label 'The electronic document format %1 does not exist for the document type %2.', Comment = '%1 : document format, %2 document use eq Invoice';
        UnSupportedDocumentTypeErr: Label 'The document type %1 is not supported.', Comment = '%1 : document ytp eq Invocie ';
        ElectronicDocumentNotCreatedErr: Label 'The electronic document has not been created.';
        ElectronicFormatErr: Label 'The electronic format %1 does not exist.', Comment = '%1=Specified Electronic Format';
        DataCompression: Codeunit "Data Compression";

    [Scope('OnPrem')]
    procedure SendElectronically(var ServerFilePath: Text[250]; var ClientFileName: Text[250]; DocumentVariant: Variant; ElectronicFormat: Code[20])
    var
        RecordExportBuffer: Record "Record Export Buffer";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessage: Record "Error Message";
        FileManagement: Codeunit "File Management";
        EntryTempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        ZipFile: File;
        EntryFileInStream: InStream;
        ZipFileOutStream: OutStream;
        DocumentUsage: Option "Sales Invoice","Sales Credit Memo";
        StartID: Integer;
        EndID: Integer;
        IsMissingServerFile: Boolean;
    begin
        GetDocumentUsage(DocumentUsage, DocumentVariant);

        if not Get(ElectronicFormat, DocumentUsage) then begin
            Usage := DocumentUsage;
            Error(NonExistingDocumentFormatErr, ElectronicFormat, Format(Usage));
        end;

        RecRef.GetTable(DocumentVariant);

        RecordExportBuffer.LockTable();
        if RecRef.FindSet then
            repeat
                Clear(RecordExportBuffer);
                RecordExportBuffer.RecordID := RecRef.RecordId;
                RecordExportBuffer.ClientFileName :=
                  GetAttachmentFileName(GetDocumentNo(RecRef), GetDocumentType(RecRef), 'xml');
                RecordExportBuffer.ZipFileName :=
                  GetAttachmentFileName(GetDocumentNo(RecRef), GetDocumentType(RecRef), 'zip');
                RecordExportBuffer.Insert(true);
                if StartID = 0 then
                    StartID := RecordExportBuffer.ID;
                EndID := RecordExportBuffer.ID;
            until RecRef.Next = 0;

        RecordExportBuffer.SetRange(ID, StartID, EndID);
        if RecordExportBuffer.FindSet then
            repeat
                ErrorMessage.SetContext(RecordExportBuffer);
                ErrorMessage.ClearLog;

                CODEUNIT.Run("Codeunit ID", RecordExportBuffer);

                TempErrorMessage.CopyFromContext(RecordExportBuffer);
                ErrorMessage.ClearLog; // Clean up

                if RecordExportBuffer.ServerFilePath = '' then
                    IsMissingServerFile := true;
            until RecordExportBuffer.Next = 0;

        // Display errors in case anything went wrong.
        TempErrorMessage.ShowErrorMessages(true);
        if IsMissingServerFile then
            Error(ElectronicDocumentNotCreatedErr);

        if RecordExportBuffer.Count > 1 then begin
            ServerFilePath := CopyStr(FileManagement.ServerTempFileName('zip'), 1, 250);
            ZipFile.Create(ServerFilePath);
            ZipFile.CreateOutStream(ZipFileOutStream);
            DataCompression.CreateZipArchive;
            ClientFileName := CopyStr(RecordExportBuffer.ZipFileName, 1, 250);
            RecordExportBuffer.FindSet;
            repeat
                FileManagement.BLOBImportFromServerFile(EntryTempBlob, RecordExportBuffer.ServerFilePath);
                EntryTempBlob.CreateInStream(EntryFileInStream);
                DataCompression.AddEntry(EntryFileInStream, RecordExportBuffer.ClientFileName);
            until RecordExportBuffer.Next = 0;
            DataCompression.SaveZipArchive(ZipFileOutStream);
            DataCompression.CloseZipArchive;
            ZipFile.Close;
        end else
            if RecordExportBuffer.FindFirst then begin
                ServerFilePath := RecordExportBuffer.ServerFilePath;
                ClientFileName := RecordExportBuffer.ClientFileName;
            end;

        RecordExportBuffer.DeleteAll();
    end;

    procedure ValidateElectronicServiceDocument(ServiceHeader: Record "Service Header"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Service Validation") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", ServiceHeader);
    end;

    procedure ValidateElectronicSalesDocument(SalesHeader: Record "Sales Header"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Sales Validation") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", SalesHeader);
    end;

    procedure ValidateElectronicJobsDocument(Job: Record Job; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Job Quote") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", Job);
    end;

    procedure GetAttachmentFileName(DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]): Text[250]
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(
          CopyStr(
            StrSubstNo('%1 - %2 %3.%4', FileMgt.StripNotsupportChrInFileName(CompanyName), DocumentType, DocumentNo, Extension), 1, 250));
    end;

    procedure GetDocumentUsage(var DocumentUsage: Option; DocumentVariant: Variant)
    var
        DocumentRecordRef: RecordRef;
    begin
        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                DocumentUsage := Usage::"Sales Invoice";
            DATABASE::"Sales Cr.Memo Header":
                DocumentUsage := Usage::"Sales Credit Memo";
            DATABASE::"Service Invoice Header":
                DocumentUsage := Usage::"Service Invoice";
            DATABASE::"Service Cr.Memo Header":
                DocumentUsage := Usage::"Service Credit Memo";
            DATABASE::"Sales Header":
                GetDocumentUsageForSalesHeader(DocumentUsage, DocumentVariant);
            DATABASE::"Service Header":
                GetDocumentUsageForServiceHeader(DocumentUsage, DocumentVariant);
            DATABASE::Job:
                DocumentUsage := Usage::"Job Quote";
            else
                Error(UnSupportedTableTypeErr, DocumentRecordRef.Caption);
        end;
    end;

    procedure GetDocumentNo(DocumentVariant: Variant): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
        DocumentRecordRef: RecordRef;
        DocumentNo: Code[20];
        IsHandled: Boolean;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    exit(SalesInvoiceHeader."No.");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    exit(SalesCrMemoHeader."No.");
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := DocumentVariant;
                    exit(ServiceInvoiceHeader."No.");
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := DocumentVariant;
                    exit(ServiceCrMemoHeader."No.");
                end;
            DATABASE::"Service Header":
                begin
                    ServiceHeader := DocumentVariant;
                    exit(ServiceHeader."No.");
                end;
            DATABASE::"Sales Header":
                begin
                    SalesHeader := DocumentVariant;
                    exit(SalesHeader."No.");
                end;
            DATABASE::Job:
                begin
                    Job := DocumentVariant;
                    exit(Job."No.");
                end;
            else begin
                    IsHandled := false;
                    OnGetDocumentNoCaseElse(DocumentVariant, DocumentNo, IsHandled);
                    if IsHandled then
                        exit(DocumentNo);

                    Error(UnSupportedTableTypeErr, DocumentRecordRef.Caption);
                end;
        end;
    end;

    local procedure GetDocumentUsageForSalesHeader(var DocumentUsage: Option; SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDocumentUsageForSalesHeader(Rec, SalesHeader, DocumentUsage, IsHandled);
        if IsHandled then
            exit;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                exit;
            SalesHeader."Document Type"::Invoice:
                DocumentUsage := Usage::"Sales Invoice";
            SalesHeader."Document Type"::"Credit Memo":
                DocumentUsage := Usage::"Sales Credit Memo";
            else
                Error(UnSupportedDocumentTypeErr, Format(SalesHeader."Document Type"));
        end;
    end;

    local procedure GetDocumentUsageForServiceHeader(var DocumentUsage: Option; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDocumentUsageForServiceHeader(Rec, ServiceHeader, DocumentUsage, IsHandled);
        if IsHandled then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Invoice:
                DocumentUsage := Usage::"Service Invoice";
            ServiceHeader."Document Type"::"Credit Memo":
                DocumentUsage := Usage::"Service Credit Memo";
            else
                Error(UnSupportedDocumentTypeErr, Format(ServiceHeader."Document Type"));
        end;
    end;

    local procedure CheckCodeunitExist()
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, "Codeunit ID");
    end;

    procedure ValidateElectronicFormat(ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.SetRange(Code, ElectronicFormat);
        if ElectronicDocumentFormat.IsEmpty then
            Error(ElectronicFormatErr, ElectronicFormat);
    end;

    local procedure GetDocumentType(DocumentVariant: Variant) DocumentTypeText: Text[50]
    var
        DummySalesHeader: Record "Sales Header";
        DummyServiceHeader: Record "Service Header";
        DocumentRecordRef: RecordRef;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;
        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                exit(Format(DummySalesHeader."Document Type"::Invoice));
            DATABASE::"Sales Cr.Memo Header":
                exit(Format(DummySalesHeader."Document Type"::"Credit Memo"));
            DATABASE::"Service Invoice Header":
                exit(Format(DummyServiceHeader."Document Type"::Invoice));
            DATABASE::"Service Cr.Memo Header":
                exit(Format(DummyServiceHeader."Document Type"::"Credit Memo"));
            DATABASE::Job:
                exit(Format(DummyServiceHeader."Document Type"::Quote));
            DATABASE::"Service Header":
                begin
                    DummyServiceHeader := DocumentVariant;
                    if DummyServiceHeader."Document Type" = DummyServiceHeader."Document Type"::Quote then
                        exit(Format(DummyServiceHeader."Document Type"::Quote));
                end;
            DATABASE::"Sales Header":
                begin
                    DummySalesHeader := DocumentVariant;
                    if DummySalesHeader."Document Type" = DummySalesHeader."Document Type"::Quote then
                        exit(Format(DummySalesHeader."Document Type"::Quote));
                end;
            else
                OnGetDocumentTypeCaseElse(DocumentVariant, DocumentTypeText);
        end;
    end;

    procedure InsertElectronicFormat(InsertElectronicFormatCode: Code[20]; InsertElectronicFormatDescription: Text[250]; CodeunitID: Integer; DeliveryCodeunitID: Integer; InsertElectronicFormatUsage: Option)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if ElectronicDocumentFormat.Get(InsertElectronicFormatCode, InsertElectronicFormatUsage) then
            exit;

        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := InsertElectronicFormatCode;
        ElectronicDocumentFormat.Description := InsertElectronicFormatDescription;
        ElectronicDocumentFormat."Codeunit ID" := CodeunitID;
        ElectronicDocumentFormat."Delivery Codeunit ID" := DeliveryCodeunitID;
        ElectronicDocumentFormat.Usage := InsertElectronicFormatUsage;
        ElectronicDocumentFormat.Insert();
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnDiscoverElectronicFormat()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentUsageForSalesHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; SalesHeader: Record "Sales Header"; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentUsageForServiceHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; ServiceHeader: Record "Service Header"; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentNoCaseElse(DocumentVariant: Variant; var DocumentNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentTypeCaseElse(DocumentVariant: Variant; var DocumentTypeText: Text[50])
    begin
    end;
}

