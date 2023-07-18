table 1173 "Document Attachment"
{
    Caption = 'Document Attachment';

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            Editable = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(4; "Attached Date"; DateTime)
        {
            Caption = 'Attached Date';
        }
        field(5; "File Name"; Text[250])
        {
            Caption = 'Attachment';
            NotBlank = true;

            trigger OnValidate()
            var
                DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
            begin
                if "File Name" = '' then
                    Error(EmptyFileNameErr);

                if DocumentAttachmentMgmt.IsDuplicateFile(
                    "Table ID", "No.", "Document Type".AsInteger(), "Line No.", "File Name", "File Extension")
                then
                    Error(DuplicateErr);
            end;
        }
        field(6; "File Type"; Enum "Document Attachment File Type")
        {
            Caption = 'File Type';
        }
        field(7; "File Extension"; Text[30])
        {
            Caption = 'File Extension';

            trigger OnValidate()
            begin
                case LowerCase("File Extension") of
                    'jpg', 'jpeg', 'bmp', 'png', 'tiff', 'tif', 'gif':
                        "File Type" := "File Type"::Image;
                    'pdf':
                        "File Type" := "File Type"::PDF;
                    'docx', 'doc':
                        "File Type" := "File Type"::Word;
                    'xlsx', 'xls':
                        "File Type" := "File Type"::Excel;
                    'pptx', 'ppt':
                        "File Type" := "File Type"::PowerPoint;
                    'msg':
                        "File Type" := "File Type"::Email;
                    'xml':
                        "File Type" := "File Type"::XML;
                    else
                        "File Type" := "File Type"::Other;
                end;
            end;
        }
        field(8; "Document Reference ID"; Media)
        {
            Caption = 'Document Reference ID';
        }
        field(9; "Attached By"; Guid)
        {
            Caption = 'Attached By';
            Editable = false;
            TableRelation = User."User Security ID" WHERE("License Type" = CONST("Full User"));
        }
        field(10; User; Code[50])
        {
            CalcFormula = Lookup(User."User Name" WHERE("User Security ID" = FIELD("Attached By"),
                                                         "License Type" = CONST("Full User")));
            Caption = 'User';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Document Flow Purchase"; Boolean)
        {
            Caption = 'Flow to Purch. Trx';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentFlowPurchase(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not "Document Reference ID".HasValue() then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(12; "Document Flow Sales"; Boolean)
        {
            Caption = 'Flow to Sales Trx';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentFlowSales(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not "Document Reference ID".HasValue() then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(13; "Document Type"; Enum "Attachment Document Type")
        {
            Caption = 'Document Type';
        }
        field(14; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(15; "VAT Report Config. Code"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Config. Code';
            TableRelation = "VAT Reports Configuration"."VAT Report Type";
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Document Type", "Line No.", ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", "File Name", "File Extension", "File Type")
        {
        }
    }

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        if IncomingFileName <> '' then begin
            Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
            Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));
        end;

        IsHandled := false;
        OnInsertOnBeforeCheckDocRefID(Rec, IsHandled);
        if not IsHandled then
            if not "Document Reference ID".HasValue() then
                Error(NoDocumentAttachedErr);

        Validate("Attached Date", CurrentDateTime);
        if IsNullGuid("Attached By") then
            "Attached By" := UserSecurityId();
    end;

    var
        FileManagement: Codeunit "File Management";
        IncomingFileName: Text;
        NoDocumentAttachedErr: Label 'Please attach a document first.';
        EmptyFileNameErr: Label 'Please choose a file to attach.';
        NoContentErr: Label 'The selected file has no content. Please choose another file.';
        DuplicateErr: Label 'This file is already attached to the document. Please choose another file.';

    procedure ImportAttachment(DocumentInStream: InStream; FileName: Text)
    begin
        Rec."Document Reference ID".ImportStream(DocumentInStream, '', '', FileName);
        if not Rec."Document Reference ID".HasValue() then
            Error(NoDocumentAttachedErr);

        Rec.Validate("Attached Date", CurrentDateTime);
        if IsNullGuid(Rec."Attached By") then
            Rec."Attached By" := UserSecurityId();

        Rec.Modify();
    end;

    procedure Export(ShowFileDialog: Boolean) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DocumentStream: OutStream;
        FullFileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExport(Rec, IsHandled, ShowFileDialog);
        if IsHandled then
            exit;

        if ID = 0 then
            exit;
        // Ensure document has value in DB
        if not "Document Reference ID".HasValue() then
            exit;

        OnBeforeExportAttachment(Rec);
        FullFileName := "File Name" + '.' + "File Extension";
        TempBlob.CreateOutStream(DocumentStream);
        "Document Reference ID".ExportStream(DocumentStream);
        exit(FileManagement.BLOBExport(TempBlob, FullFileName, ShowFileDialog));
    end;

    procedure HasPostedDocumentAttachment("Record": Variant): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        RecRef.GetTable(Record);
        SetRange("Table ID", RecRef.Number);
        case RecRef.Number of
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    SetRange("No.", RecNo);
                    exit(not IsEmpty);
                end;
        end;

        exit(false);
    end;

    procedure SaveAttachment(RecRef: RecordRef; FileName: Text; TempBlob: Codeunit "Temp Blob")
    begin
        SaveAttachment(RecRef, FileName, TempBlob, true);
    end;

    procedure SaveAttachment(RecRef: RecordRef; FileName: Text; TempBlob: Codeunit "Temp Blob"; AllowDuplicateFileName: Boolean)
    var
        DocStream: InStream;
    begin
        OnBeforeSaveAttachment(Rec, RecRef, FileName, TempBlob);

        if FileName = '' then
            Error(EmptyFileNameErr);
        // Validate file/media is not empty
        if not TempBlob.HasValue() then
            Error(NoContentErr);

        TempBlob.CreateInStream(DocStream);
        InsertAttachment(DocStream, RecRef, FileName, AllowDuplicateFileName);
    end;

    procedure SaveAttachmentFromStream(DocStream: InStream; RecRef: RecordRef; FileName: Text)
    begin
        SaveAttachmentFromStream(DocStream, RecRef, FileName, true);
    end;

    procedure SaveAttachmentFromStream(DocStream: InStream; RecRef: RecordRef; FileName: Text; AllowDuplicateFileName: Boolean)
    begin
        OnBeforeSaveAttachmentFromStream(Rec, RecRef, FileName, DocStream);

        if FileName = '' then
            Error(EmptyFileNameErr);

        InsertAttachment(DocStream, RecRef, FileName, AllowDuplicateFileName);
    end;

    local procedure InsertAttachment(DocStream: InStream; RecRef: RecordRef; FileName: Text; AllowDuplicateFileName: Boolean)
    var
        IsHandled: Boolean;
    begin
        InitFieldsFromRecRef(RecRef);

        // If duplicate filename is allowed, use increment versions (specifically needed for phone Take/Use Photo functionality)
        if AllowDuplicateFileName then
            IncomingFileName := FindUniqueFileName(FileManagement.GetFileNameWithoutExtension(FileName), FileManagement.GetExtension(FileName))
        else
            IncomingFileName := FileName;

        Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
        Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));

        OnInsertAttachmentOnBeforeImportStream(Rec, DocStream, FileName, IsHandled);
        if not IsHandled then begin
            // IMPORTSTREAM(stream,description, mime-type,filename)
            // description and mime-type are set empty and will be automatically set by platform code from the filename
            "Document Reference ID".ImportStream(DocStream, '', '', FileName);
            if not "Document Reference ID".HasValue() then
                Error(NoDocumentAttachedErr);
        end;

        OnBeforeInsertAttachment(Rec, RecRef);
        Insert(true);
    end;

    procedure InitFieldsFromRecRef(RecRef: RecordRef)
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FieldRef: FieldRef;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        FieldNo: Integer;
        LineNo: Integer;
    begin
        Validate("Table ID", RecRef.Number);

        if DocumentAttachmentMgmt.TableHasNumberFieldPrimayKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            RecNo := FieldRef.Value();
            Validate("No.", RecNo);
        end;

        if DocumentAttachmentMgmt.TableHasDocTypePrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            DocType := FieldRef.Value();
            Validate("Document Type", DocType);
        end;

        if DocumentAttachmentMgmt.TableHasLineNumberPrimaryKey(RecRef.Number(), FieldNo) then begin
            FieldRef := RecRef.Field(FieldNo);
            LineNo := FieldRef.Value();
            Validate("Line No.", LineNo);
        end;

        OnAfterInitFieldsFromRecRef(Rec, RecRef);
    end;

    procedure FindUniqueFileName(FileName: Text; FileExtension: Text): Text[250]
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FileIndex: Integer;
        SourceFileName: Text[250];
    begin
        SourceFileName := CopyStr(FileName, 1, MaxStrLen(SourceFileName));
        while DocumentAttachmentMgmt.IsDuplicateFile("Table ID", "No.", "Document Type".AsInteger(), "Line No.", FileName, FileExtension) do begin
            FileIndex += 1;
            FileName := GetNextFileName(SourceFileName, FileIndex);
        end;
        exit(CopyStr(StrSubstNo('%1.%2', FileName, FileExtension), 1, MaxStrLen(SourceFileName)));
    end;

    procedure VATReturnSubmissionAttachmentsExist(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        DocType: Enum "Attachment Document Type";
    begin
        exit(VATReturnAttachmentsExist(VATReportHeader, DocType::"VAT Return Submission"));
    end;

    procedure VATReturnResponseAttachmentsExist(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        DocType: Enum "Attachment Document Type";
    begin
        exit(VATReturnAttachmentsExist(VATReportHeader, DocType::"VAT Return Response"));
    end;

    local procedure VATReturnAttachmentsExist(VATReportHeader: Record "VAT Report Header"; DocType: Enum "Attachment Document Type"): Boolean
    begin
        SetRange("Table ID", Database::"VAT Report Header");
        SetRange("No.", VATReportHeader."No.");
        SetRange("Document Type", DocType);
        exit(not IsEmpty());
    end;

    procedure DownloadZipFileWithVATReturnSubmissionAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]): Boolean
    begin
        exit(DownloadZipFileWithVATReturnAttachments(VATRepConfigCode, VATReportNo, "Document Type"::"VAT Return Submission"));
    end;

    procedure DownloadZipFileWithVATReturnResponseAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]): Boolean
    begin
        exit(DownloadZipFileWithVATReturnAttachments(VATRepConfigCode, VATReportNo, "Document Type"::"VAT Return Response"));
    end;

    local procedure DownloadZipFileWithVATReturnAttachments(VATRepConfigCode: Enum "VAT Report Configuration"; VATReportNo: Code[20]; DocType: Enum "Attachment Document Type"): Boolean
    var
        VATReportHeader: Record "VAT Report Header";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
        ZipInStream: InStream;
        DocumentStream: OutStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        if not VATReportHeader.Get(VATRepConfigCode, VATReportNo) then
            exit(false);

        SetRange("Table ID", Database::"VAT Report Header");
        SetRange("No.", VATReportHeader."No.");
        SetRange("Document Type", DocType);
        if not FindSet() then
            exit(false);

        ToFile := VATReportHeader."No.";
        case "Document Type" of
            "Document Type"::"VAT Return Submission":
                ToFile += '_Submission.zip';
            "Document Type"::"VAT Return Response":
                ToFile += 'Response.zip';
        end;

        DataCompression.CreateZipArchive();
        repeat
            if "Document Reference ID".HasValue() then begin
                clear(TempBlob);
                TempBlob.CreateOutStream(DocumentStream);
                "Document Reference ID".ExportStream(DocumentStream);
                TempBlob.CreateInStream(ServerFileInStream);
                DataCompression.AddEntry(ServerFileInStream, "File Name" + '.' + "File Extension");
            end;
        until Next() = 0;
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        DownloadFromStream(ZipInStream, '', '', '', ToFile);
        exit(true);
    end;

    local procedure GetNextFileName(FileName: Text[250]; FileIndex: Integer): Text[250]
    begin
        exit(StrSubstNo('%1 (%2)', FileName, FileIndex));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean; ShowFileDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachment(var DocumentAttachment: Record "Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FileName: Text; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachmentFromStream(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FileName: Text; var DocStream: InStream)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentFlowPurchase(var DocumentAttachment: Record "Document Attachment"; xDocumentAttachment: Record "Document Attachment"; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentFlowSales(var DocumentAttachment: Record "Document Attachment"; xDocumentAttachment: Record "Document Attachment"; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeCheckDocRefID(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAttachmentOnBeforeImportStream(var DocumentAttachment: Record "Document Attachment"; DocInStream: InStream; FileName: Text; var IsHandled: Boolean)
    begin
    end;
}

