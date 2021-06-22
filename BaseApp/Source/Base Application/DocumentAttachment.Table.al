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

                if DocumentAttachmentMgmt.IsDuplicateFile("Table ID", "No.", "Document Type", "Line No.", "File Name", "File Extension") = true then
                    Error(DuplicateErr);
            end;
        }
        field(6; "File Type"; Option)
        {
            Caption = 'File Type';
            OptionCaption = ' ,Image,PDF,Word,Excel,PowerPoint,Email,XML,Other';
            OptionMembers = " ",Image,PDF,Word,Excel,PowerPoint,Email,XML,Other;
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
            CalcFormula = Lookup (User."User Name" WHERE("User Security ID" = FIELD("Attached By"),
                                                         "License Type" = CONST("Full User")));
            Caption = 'User';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Document Flow Purchase"; Boolean)
        {
            Caption = 'Flow to Purch. Trx';

            trigger OnValidate()
            begin
                if not "Document Reference ID".HasValue then
                    Error(NoDocumentAttachedErr);
            end;
        }
        field(12; "Document Flow Sales"; Boolean)
        {
            Caption = 'Flow to Sales Trx';

            trigger OnValidate()
            begin
                if not "Document Reference ID".HasValue then
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
    begin
        if IncomingFileName <> '' then begin
            Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
            Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));
        end;

        if not "Document Reference ID".HasValue then
            Error(NoDocumentAttachedErr);

        Validate("Attached Date", CurrentDateTime);
        if IsNullGuid("Attached By") then
            "Attached By" := UserSecurityId;
    end;

    var
        NoDocumentAttachedErr: Label 'Please attach a document first.';
        EmptyFileNameErr: Label 'Please choose a file to attach.';
        NoContentErr: Label 'The selected file has no content. Please choose another file.';
        FileManagement: Codeunit "File Management";
        IncomingFileName: Text;
        DuplicateErr: Label 'This file is already attached to the document. Please choose another file.';

    [Scope('OnPrem')]
    procedure Export(ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DocumentStream: OutStream;
        FullFileName: Text;
    begin
        if ID = 0 then
            exit;
        // Ensure document has value in DB
        if not "Document Reference ID".HasValue then
            exit;

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

    [Scope('OnPrem')]
    procedure SaveAttachment(RecRef: RecordRef; FileName: Text; TempBlob: Codeunit "Temp Blob")
    var
        DocStream: InStream;
    begin
        OnBeforeSaveAttachment(Rec, RecRef, FileName, TempBlob);

        if FileName = '' then
            Error(EmptyFileNameErr);
        // Validate file/media is not empty
        if not TempBlob.HasValue then
            Error(NoContentErr);

        TempBlob.CreateInStream(DocStream);
        InsertAttachment(DocStream, RecRef, FileName);
    end;

    procedure SaveAttachmentFromStream(DocStream: InStream; RecRef: RecordRef; FileName: Text)
    begin
        OnBeforeSaveAttachmentFromStream(Rec, RecRef, FileName, DocStream);

        if FileName = '' then
            Error(EmptyFileNameErr);

        InsertAttachment(DocStream, RecRef, FileName);
    end;

    local procedure InsertAttachment(DocStream: InStream; RecRef: RecordRef; FileName: Text)
    begin
        IncomingFileName := FileName;

        Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
        Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));

        // IMPORTSTREAM(stream,description, mime-type,filename)
        // description and mime-type are set empty and will be automatically set by platform code from the stream
        "Document Reference ID".ImportStream(DocStream, '');
        if not "Document Reference ID".HasValue then
            Error(NoDocumentAttachedErr);

        InitFieldsFromRecRef(RecRef);

        OnBeforeInsertAttachment(Rec, RecRef);
        Insert(true);
    end;

    procedure InitFieldsFromRecRef(RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
    begin
        Validate("Table ID", RecRef.Number);

        case RecRef.Number of
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item,
            DATABASE::Employee,
            DATABASE::"Fixed Asset",
            DATABASE::Resource,
            DATABASE::Job:
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Header",
            DATABASE::"Purchase Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(1);
                    DocType := FieldRef.Value;
                    Validate("Document Type", DocType);

                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value;
                    Validate("Line No.", LineNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number of
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value;
                    Validate("No.", RecNo);

                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value;
                    Validate("Line No.", LineNo);
                end;
        end;
    end;

    procedure FindUniqueFileName(FileName: Text; FileExtension: Text): Text[250]
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FileIndex: Integer;
        SourceFileName: Text[250];
    begin
        SourceFileName := CopyStr(FileName, 1, MaxStrLen(SourceFileName));
        while DocumentAttachmentMgmt.IsDuplicateFile("Table ID", "No.", "Document Type", "Line No.", FileName, FileExtension) DO BEGIN
            FileIndex += 1;
            FileName := GetNextFileName(SourceFileName, FileIndex);
        end;
        exit(CopyStr(StrSubstNo('%1.%2', FileName, FileExtension), 1, MaxStrLen(SourceFileName)));
    end;

    local procedure GetNextFileName(FileName: Text[250]; FileIndex: Integer): Text[250]
    begin
        exit(StrSubstNo('%1 (%2)', FileName, FileIndex));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; FileName: Text; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAttachmentFromStream(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; FileName: Text; var DocStream: InStream)
    begin
    end;

}

