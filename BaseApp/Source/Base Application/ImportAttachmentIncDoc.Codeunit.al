codeunit 134 "Import Attachment - Inc. Doc."
{
    TableNo = "Incoming Document Attachment";

    trigger OnRun()
    var
        FileName: Text;
    begin
        UploadFile(Rec, FileName);
        ImportAttachment(Rec, FileName);
    end;

    var
        ReplaceContentQst: Label 'Do you want to replace the file content?';
        ImportTxt: Label 'Insert File';
        FileDialogTxt: Label 'Attachments (%1)|%1', Comment = '%1=file types, such as *.txt or *.docx';
        FilterTxt: Label '*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.tiff;*.tif;*.pdf;*.docx;*.doc;*.xlsx;*.xls;*.pptx;*.ppt;*.msg;*.xml;*.*', Locked = true;
        NotSupportedDocTableErr: Label 'Table no. %1 is not supported.', Comment = '%1 is a number (integer).';
        PhotoLbl: Label 'Photo %1', Comment = '%1 = a number, e.g. 1, 2, 3,...';
        EmptyFileMsg: Label 'You have created an incoming document based on an empty file. Try again with a file that contains data that you want to import.';
        IsTestMode: Boolean;

    [Scope('OnPrem')]
    procedure UploadFile(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        IncomingDocumentAttachment.CalcFields(Content);
        if IncomingDocumentAttachment.Content.HasValue then
            if not Confirm(ReplaceContentQst, false) then
                Error('');

        FileName := FileManagement.BLOBImportWithFilter(
            TempBlob, ImportTxt, FileName, StrSubstNo(FileDialogTxt, FilterTxt), FilterTxt);
        IncomingDocumentAttachment.SetContentFromBlob(TempBlob);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; FileName: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        if FileName = '' then
            Error('');

        with IncomingDocumentAttachment do begin
            FindOrCreateIncomingDocument(IncomingDocumentAttachment, IncomingDocument);
            if IncomingDocument.Status in [IncomingDocument.Status::"Pending Approval", IncomingDocument.Status::Failed] then
                IncomingDocument.TestField(Status, IncomingDocument.Status::New);
            "Incoming Document Entry No." := IncomingDocument."Entry No.";
            "Line No." := GetIncomingDocumentNextLineNo(IncomingDocument);

            if not Content.HasValue then begin
                if FileManagement.ServerFileExists(FileName) then
                    FileManagement.BLOBImportFromServerFile(TempBlob, FileName)
                else
                    FileManagement.BLOBImportFromServerFile(TempBlob, FileManagement.UploadFileToServer(FileName));
                RecordRef.GetTable(IncomingDocumentAttachment);
                TempBlob.ToRecordRef(RecordRef, FieldNo(Content));
                RecordRef.SetTable(IncomingDocumentAttachment);
            end;

            if not Content.HasValue then begin
                Message(EmptyFileMsg);
                if not IsTestMode then
                    Delete;
                exit(false);
            end;

            Validate("File Extension", LowerCase(CopyStr(FileManagement.GetExtension(FileName), 1, MaxStrLen("File Extension"))));
            if Name = '' then
                Name := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(Name));

            "Document No." := IncomingDocument."Document No.";
            "Posting Date" := IncomingDocument."Posting Date";
            if IncomingDocument.Description = '' then begin
                IncomingDocument.Description := CopyStr(Name, 1, MaxStrLen(IncomingDocument.Description));
                IncomingDocument.Modify();
            end;

            Insert(true);

            if Type in [Type::Image, Type::PDF] then
                OnAttachBinaryFile;
        end;
        exit(true);
    end;

    procedure CreateNewAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.Init();

        FindOrCreateIncomingDocument(IncomingDocumentAttachment, IncomingDocument);

        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Document No." := IncomingDocument."Document No.";
        IncomingDocumentAttachment."Posting Date" := IncomingDocument."Posting Date";

        IncomingDocumentAttachment."Line No." := GetIncomingDocumentNextLineNo(IncomingDocument);
    end;

    local procedure FindOrCreateIncomingDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document")
    var
        DocNo: Code[20];
        PostingDate: Date;
    begin
        if FindUsingIncomingDocNoFilter(IncomingDocumentAttachment, IncomingDocument) then
            exit;
        if FindUsingDocNoFilter(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo) then
            exit;
        CreateIncomingDocument(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo);
    end;

    local procedure FindInIncomingDocAttachmentUsingIncomingDocNoFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        IncomingDocNo: Integer;
    begin
        if IncomingDocumentAttachment.GetFilter("Incoming Document Entry No.") <> '' then begin
            IncomingDocNo := IncomingDocumentAttachment.GetRangeMin("Incoming Document Entry No.");
            if IncomingDocNo <> 0 then
                exit(IncomingDocument.Get(IncomingDocNo));
        end;
        exit(false);
    end;

    local procedure FindInGenJournalLineUsingIncomingDocNoFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        IncomingDocNo: Integer;
    begin
        if IncomingDocumentAttachment.GetFilter("Journal Batch Name Filter") <> '' then begin
            IncomingDocNo := CreateNewJournalLineIncomingDoc(IncomingDocumentAttachment);
            if IncomingDocNo <> 0 then
                exit(IncomingDocument.Get(IncomingDocNo));
        end;
        exit(false);
    end;

    local procedure FindInSalesPurchUsingIncomingDocNoFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        IncomingDocNo: Integer;
    begin
        if IncomingDocumentAttachment.GetFilter("Document Table No. Filter") <> '' then begin
            IncomingDocNo := CreateNewSalesPurchIncomingDoc(IncomingDocumentAttachment);
            if IncomingDocNo <> 0 then
                exit(IncomingDocument.Get(IncomingDocNo));
        end;
        exit(false);
    end;

    local procedure FindUsingIncomingDocNoFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        FilterGroupID: Integer;
        Found: Boolean;
    begin
        for FilterGroupID := 0 to 2 do begin
            IncomingDocumentAttachment.FilterGroup(FilterGroupID * 2);
            case true of
                FindInIncomingDocAttachmentUsingIncomingDocNoFilter(IncomingDocumentAttachment, IncomingDocument):
                    Found := true;
                FindInGenJournalLineUsingIncomingDocNoFilter(IncomingDocumentAttachment, IncomingDocument):
                    Found := true;
                FindInSalesPurchUsingIncomingDocNoFilter(IncomingDocumentAttachment, IncomingDocument):
                    Found := true;
            end;
            if Found then
                break;
        end;
        IncomingDocumentAttachment.FilterGroup(0);
        exit(Found);
    end;

    local procedure FindUsingDocNoFilter(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; var PostingDate: Date; var DocNo: Code[20]): Boolean
    var
        FilterGroupID: Integer;
    begin
        for FilterGroupID := 0 to 2 do begin
            IncomingDocumentAttachment.FilterGroup(FilterGroupID * 2);
            if (IncomingDocumentAttachment.GetFilter("Document No.") <> '') and
               (IncomingDocumentAttachment.GetFilter("Posting Date") <> '')
            then begin
                DocNo := IncomingDocumentAttachment.GetRangeMin("Document No.");
                PostingDate := IncomingDocumentAttachment.GetRangeMin("Posting Date");
                if DocNo <> '' then
                    break;
            end;
        end;
        IncomingDocumentAttachment.FilterGroup(0);

        if (DocNo = '') or (PostingDate = 0D) then
            exit(false);

        IncomingDocument.SetRange("Document No.", DocNo);
        IncomingDocument.SetRange("Posting Date", PostingDate);
        exit(IncomingDocument.FindFirst);
    end;

    local procedure CreateNewSalesPurchIncomingDoc(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Integer
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DocTableNo: Integer;
        DocType: Option;
        DocNo: Code[20];
    begin
        with IncomingDocumentAttachment do begin
            if GetFilter("Document Table No. Filter") <> '' then
                DocTableNo := GetRangeMin("Document Table No. Filter");
            if GetFilter("Document Type Filter") <> '' then
                DocType := GetRangeMin("Document Type Filter");
            if GetFilter("Document No. Filter") <> '' then
                DocNo := GetRangeMin("Document No. Filter");

            case DocTableNo of
                DATABASE::"Sales Header":
                    begin
                        SalesHeader.Get(DocType, DocNo);
                        CreateIncomingDocumentExtended(IncomingDocumentAttachment, IncomingDocument, 0D, '', SalesHeader.RecordId);
                        SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
                        SalesHeader.Modify();
                    end;
                DATABASE::"Purchase Header":
                    begin
                        PurchaseHeader.Get(DocType, DocNo);
                        CreateIncomingDocumentExtended(IncomingDocumentAttachment, IncomingDocument, 0D, '', PurchaseHeader.RecordId);
                        PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
                        PurchaseHeader.Modify();
                    end;
                else
                    Error(NotSupportedDocTableErr, DocTableNo);
            end;

            exit(IncomingDocument."Entry No.");
        end;
    end;

    local procedure CreateNewJournalLineIncomingDoc(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Integer
    var
        IncomingDocument: Record "Incoming Document";
        GenJournalLine: Record "Gen. Journal Line";
        JnlTemplateName: Code[20];
        JnlBatchName: Code[20];
        JnlLineNo: Integer;
    begin
        with IncomingDocumentAttachment do begin
            if GetFilter("Journal Template Name Filter") <> '' then
                JnlTemplateName := GetRangeMin("Journal Template Name Filter");
            if GetFilter("Journal Batch Name Filter") <> '' then
                JnlBatchName := GetRangeMin("Journal Batch Name Filter");
            if GetFilter("Journal Line No. Filter") <> '' then
                JnlLineNo := GetRangeMin("Journal Line No. Filter");

            GenJournalLine.Get(JnlTemplateName, JnlBatchName, JnlLineNo);
            CreateIncomingDocumentExtended(IncomingDocumentAttachment, IncomingDocument, 0D, '', GenJournalLine.RecordId);
            GenJournalLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
            GenJournalLine.Modify();

            exit(IncomingDocument."Entry No.");
        end;
    end;

    local procedure CreateIncomingDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; PostingDate: Date; DocNo: Code[20])
    var
        DummyRecordID: RecordID;
    begin
        CreateIncomingDocumentExtended(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo, DummyRecordID);
    end;

    local procedure CreateIncomingDocumentExtended(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; PostingDate: Date; DocNo: Code[20]; RelatedRecordID: RecordID)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RelatedRecordRef: RecordRef;
        RelatedRecord: Variant;
    begin
        IncomingDocument.CreateIncomingDocument('', '');
        IncomingDocument."Document Type" :=
          GetDocType(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo, IncomingDocument.Posted);
        if RelatedRecordID.TableNo = 0 then
            if IncomingDocument.GetRecord(RelatedRecord) then
                if DataTypeManagement.GetRecordRef(RelatedRecord, RelatedRecordRef) then
                    RelatedRecordID := RelatedRecordRef.RecordId;
        IncomingDocument."Related Record ID" := RelatedRecordID;
        if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::" " then begin
            if IncomingDocument.Posted then
                IncomingDocument.Status := IncomingDocument.Status::Posted
            else
                IncomingDocument.Status := IncomingDocument.Status::Created;
            IncomingDocument.Released := true;
            IncomingDocument."Released Date-Time" := CurrentDateTime;
            IncomingDocument."Released By User ID" := UserSecurityId;
        end;
        IncomingDocument.Modify();
    end;

    local procedure GetDocType(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; PostingDate: Date; DocNo: Code[20]; var Posted: Boolean): Integer
    begin
        if (PostingDate <> 0D) and (DocNo <> '') then begin
            IncomingDocument.SetPostedDocFields(PostingDate, DocNo);
            exit(IncomingDocument.GetPostedDocType(PostingDate, DocNo, Posted));
        end;
        Posted := false;
        exit(GetUnpostedDocType(IncomingDocumentAttachment, IncomingDocument));
    end;

    local procedure GetUnpostedDocType(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Integer
    begin
        if IsJournalRelated(IncomingDocumentAttachment) then
            exit(IncomingDocument."Document Type"::Journal);

        if IsSalesPurhaseRelated(IncomingDocumentAttachment) then
            exit(GetUnpostedSalesPurchaseDocType(IncomingDocumentAttachment, IncomingDocument));

        exit(IncomingDocument."Document Type"::" ");
    end;

    local procedure GetUnpostedSalesPurchaseDocType(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"): Integer
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter") of
            DATABASE::"Sales Header":
                begin
                    if IncomingDocumentAttachment.GetRangeMin("Document Type Filter") = SalesHeader."Document Type"::"Credit Memo" then
                        exit(IncomingDocument."Document Type"::"Sales Credit Memo");
                    exit(IncomingDocument."Document Type"::"Sales Invoice");
                end;
            DATABASE::"Purchase Header":
                begin
                    if IncomingDocumentAttachment.GetRangeMin("Document Type Filter") = PurchaseHeader."Document Type"::"Credit Memo" then
                        exit(IncomingDocument."Document Type"::"Purchase Credit Memo");
                    exit(IncomingDocument."Document Type"::"Purchase Invoice");
                end;
        end;
    end;

    local procedure IsJournalRelated(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    var
        Result: Boolean;
    begin
        Result :=
          (IncomingDocumentAttachment.GetFilter("Journal Template Name Filter") <> '') and
          (IncomingDocumentAttachment.GetFilter("Journal Batch Name Filter") <> '') and
          (IncomingDocumentAttachment.GetFilter("Journal Line No. Filter") <> '');
        exit(Result);
    end;

    local procedure IsSalesPurhaseRelated(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    var
        Result: Boolean;
    begin
        Result :=
          (IncomingDocumentAttachment.GetFilter("Document Table No. Filter") <> '') and
          (IncomingDocumentAttachment.GetFilter("Document Type Filter") <> '');
        exit(Result);
    end;

    local procedure GetIncomingDocumentNextLineNo(IncomingDocument: Record "Incoming Document"): Integer
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        with IncomingDocumentAttachment do begin
            SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            if FindLast then;
            exit("Line No." + LineIncrement);
        end;
    end;

    local procedure LineIncrement(): Integer
    begin
        exit(10000);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced with the version accepting a stream.','15.3')]
    procedure ProcessAndUploadPicture(PictureFilePath: Text; var IncomingDocumentAttachmentOriginal: Record "Incoming Document Attachment")
    var
        File: File;
        InStr: InStream;
    begin
        File.Open(PictureFilePath);
        File.CreateInStream(InStr);
        ProcessAndUploadPicture(InStr, IncomingDocumentAttachmentOriginal);
        File.Close;
        if Erase(PictureFilePath) then;
    end;

    procedure ProcessAndUploadPicture(PictureStream: InStream; var IncomingDocumentAttachmentOriginal: Record "Incoming Document Attachment")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OutStr: OutStream;
    begin
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.CopyFilters(IncomingDocumentAttachmentOriginal);

        CreateNewAttachment(IncomingDocumentAttachment);
        IncomingDocumentAttachment.Name :=
          CopyStr(StrSubstNo(PhotoLbl, IncomingDocumentAttachment."Line No." div 10000), 1, MaxStrLen(IncomingDocumentAttachment.Name));
        IncomingDocumentAttachment.Validate("File Extension", 'jpg');

        IncomingDocumentAttachment.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, PictureStream);

        IncomingDocumentAttachment.Insert(true);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure SetTestMode()
    begin
        IsTestMode := true;
    end;
}

