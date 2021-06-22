codeunit 5503 "Graph Mgt - Attachment Buffer"
{
    Permissions = TableData "Incoming Document Attachment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        DocumentIDNotSpecifiedForAttachmentsErr: Label 'You must specify a document id to get the attachments.', Locked = true;
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.', Locked = true;
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.', Locked = true;
        CannotInsertAnAttachmentThatAlreadyExistsErr: Label 'You cannot insert an attachment because an attachment already exists.', Locked = true;
        CannotModifyAnAttachmentThatDoesntExistErr: Label 'You cannot modify an attachment that does not exist.', Locked = true;
        CannotDeleteAnAttachmentThatDoesntExistErr: Label 'You cannot delete an attachment that does not exist.', Locked = true;
        EmptyGuid: Guid;
        AttachmentLinkedToAnotherDocumentErr: Label 'The attachment is linked to another document than you specified.', Locked = true;
        DocumentTypeErr: Label 'Only Sales Invoices and Sales Quotes can have attachments.', Locked = true;
        CannotFindRelatedDocumentErr: Label 'Cannot find a document which the attachment is linked to.', Locked = true;

    [Scope('Cloud')]
    procedure LoadAttachments(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentIdFilter: Text; AttachmentIdFilter: Text)
    var
        IncomingDocument: Record "Incoming Document";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        GLEntryNo: Integer;
    begin
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.DeleteAll();

        if not IsLinkedAttachment(DocumentIdFilter) then begin
            LoadUnlinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, AttachmentIdFilter);
            exit;
        end;

        FindParentDocument(DocumentIdFilter, DocumentRecordRef);
        if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit;

        if IsGLEntry(DocumentRecordRef) then
            GLEntryNo := GetGLEntryNo(DocumentRecordRef)
        else
            DocumentId := GetDocumentId(DocumentRecordRef);

        LoadLinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, IncomingDocument, AttachmentIdFilter);
        if TempAttachmentEntityBuffer.FindSet then
            repeat
                if GLEntryNo <> 0 then
                    TempAttachmentEntityBuffer."G/L Entry No." := GLEntryNo
                else
                    TempAttachmentEntityBuffer."Document Id" := DocumentId;
                TempAttachmentEntityBuffer.Modify(true);
            until TempAttachmentEntityBuffer.Next = 0;
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
        ThrowErrorIfAny(ErrorMsg);
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachmentSafe(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
        // Ignore an error from above if any, because we don't want to ask the user
        // to upload the same attachment twice because of a small error like wrong documentId, etc.
        // The client can then handle this and link the attachment and the document afterwards.
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    local procedure PropagateInsertUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary): Boolean
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        AttachmentRecordRef: RecordRef;
        AttachmentId: Guid;
    begin
        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then
            if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then
                Error(CannotInsertAnAttachmentThatAlreadyExistsErr);
        Clear(UnlinkedAttachment);
        TransferToUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment, TempFieldBuffer, true);
        UnlinkedAttachment.Insert(true);
        UnlinkedAttachment.Find;

        if FindLinkedAttachment(TempAttachmentEntityBuffer.Id, IncomingDocumentAttachment) then begin
            AttachmentId := IncomingDocumentAttachment.Id;
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
            DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
            AttachmentRecordRef.GetTable(UnlinkedAttachment);
            TransferIntegrationRecordID(AttachmentId, AttachmentRecordRef);
        end;

        Clear(TempAttachmentEntityBuffer."Document Id");
        TempAttachmentEntityBuffer.Id := UnlinkedAttachment.Id;
        exit(true);
    end;

    local procedure PropagateInsertLinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary; var ErrorMsg: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LastUsedIncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        AttachmentRecordRef: RecordRef;
        LineNo: Integer;
        Name: Text[250];
        Extension: Text[30];
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
        DocumentId: Guid;
        AttachmentId: Guid;
    begin
        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
        if not (IsLinkedAttachment(DocumentIdFilter) or IsLinkedAttachment(GLEntryNoFilter)) then
            exit(false);

        if GLEntryNoFilter <> '' then
            FindParentDocumentSafe(GLEntryNoFilter, DocumentRecordRef, ErrorMsg)
        else
            FindParentDocumentSafe(DocumentIdFilter, DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        VerifyCRUDIsPossibleSafe(DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument);

        LastUsedIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not LastUsedIncomingDocumentAttachment.FindLast then
            LineNo := 10000
        else
            LineNo := LastUsedIncomingDocumentAttachment."Line No." + 10000;

        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then begin
            IncomingDocumentAttachment.SetRange(Id, TempAttachmentEntityBuffer.Id);
            if IncomingDocumentAttachment.FindFirst then begin
                ErrorMsg := CannotInsertAnAttachmentThatAlreadyExistsErr;
                exit(false);
            end;
        end;

        DocumentId := GetDocumentId(DocumentRecordRef);
        TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, true);
        FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Id := TempAttachmentEntityBuffer.Id;
        IncomingDocumentAttachment.Name := Name;
        IncomingDocumentAttachment."File Extension" := Extension;
        if IncomingDocument.Posted then begin
            IncomingDocumentAttachment."Document No." := IncomingDocument."Document No.";
            IncomingDocumentAttachment."Posting Date" := IncomingDocument."Posting Date";
        end;
        IncomingDocumentAttachment.Insert(true);

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            AttachmentId := UnlinkedAttachment.Id;
            UnlinkedAttachment.Delete(true);
            AttachmentRecordRef.GetTable(IncomingDocumentAttachment);
            TransferIntegrationRecordID(AttachmentId, AttachmentRecordRef);
        end;

        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.Id;

        exit(true);
    end;

    [Scope('Cloud')]
    procedure PropagateModifyAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentRecord: Variant;
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
        IsUnlinked: Boolean;
        IsLinked: Boolean;
        ShouldBeLinked: Boolean;
        ShouldBeUnlinked: Boolean;
    begin
        IsUnlinked := FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment);
        if IsUnlinked then begin
            TransferToUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment, TempFieldBuffer, false);
            UnlinkedAttachment.Modify(true);
            ShouldBeLinked := not IsNullGuid(TempAttachmentEntityBuffer."Document Id");
            if ShouldBeLinked then
                LinkAttachmentToDocument(
                  TempAttachmentEntityBuffer.Id, TempAttachmentEntityBuffer."Document Id", TempAttachmentEntityBuffer."File Name");
            exit;
        end;

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        IncomingDocumentAttachment.SetRange(Id, TempAttachmentEntityBuffer.Id);
        IsLinked := IncomingDocumentAttachment.FindFirst;
        if IsLinked then begin
            ShouldBeUnlinked := IsNullGuid(TempAttachmentEntityBuffer."Document Id") and (TempAttachmentEntityBuffer."G/L Entry No." = 0);
            if ShouldBeUnlinked then begin
                IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
                IncomingDocument.GetRecord(DocumentRecord);
                DocumentRecordRef := DocumentRecord;
                VerifyCRUDIsPossible(DocumentRecordRef);
                TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
                UnlinkAttachmentFromDocument(IncomingDocumentAttachment);
                exit;
            end;
            DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
            GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
            if GLEntryNoFilter <> '' then
                FindParentDocument(GLEntryNoFilter, DocumentRecordRef)
            else
                FindParentDocument(DocumentIdFilter, DocumentRecordRef);
            if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
                Error(AttachmentLinkedToAnotherDocumentErr);
            VerifyCRUDIsPossible(DocumentRecordRef);
            TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
            IncomingDocumentAttachment.Modify(true);
            exit;
        end;

        Error(CannotModifyAnAttachmentThatDoesntExistErr);
    end;

    procedure PropagateDeleteAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
    begin
        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            UnlinkedAttachment.Delete(true);
            exit;
        end;

        IncomingDocumentAttachment.SetRange(Id, TempAttachmentEntityBuffer.Id);
        if not IncomingDocumentAttachment.FindFirst then
            Error(CannotDeleteAnAttachmentThatDoesntExistErr);

        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
        if GLEntryNoFilter <> '' then
            FindParentDocument(GLEntryNoFilter, DocumentRecordRef)
        else
            FindParentDocument(DocumentIdFilter, DocumentRecordRef);
        if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            Error(AttachmentLinkedToAnotherDocumentErr);

        VerifyCRUDIsPossible(DocumentRecordRef);
        DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
    end;

    procedure DeleteLinkedAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document")
    var
        AdditionalIncomingDocumentAttachment: Record "Incoming Document Attachment";
        DummyRecordID: RecordID;
        LineNo: Integer;
        IsDefault: Boolean;
        IsMain: Boolean;
    begin
        LineNo := IncomingDocumentAttachment."Line No.";
        IsDefault := IncomingDocumentAttachment.Default;
        IsMain := IncomingDocumentAttachment."Main Attachment";
        if (not IsDefault) and (not IsMain) then
            IncomingDocumentAttachment.Delete(true)
        else begin
            IncomingDocumentAttachment.Default := false;
            IncomingDocumentAttachment."Main Attachment" := false;
            IncomingDocumentAttachment.Modify();
            IncomingDocumentAttachment.Delete(true);
            AdditionalIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            AdditionalIncomingDocumentAttachment.SetFilter("Line No.", '<>%1', LineNo);
            if AdditionalIncomingDocumentAttachment.FindFirst then begin
                AdditionalIncomingDocumentAttachment.Validate(Default, IsDefault);
                AdditionalIncomingDocumentAttachment.Validate("Main Attachment", IsMain);
                AdditionalIncomingDocumentAttachment.Modify(true);
            end;
        end;

        IncomingDocumentAttachment.Reset();
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if IncomingDocumentAttachment.FindFirst then
            exit;

        if IncomingDocument.Posted then begin
            IncomingDocument."Related Record ID" := DummyRecordID;
            IncomingDocument."Posted Date-Time" := 0DT;
            IncomingDocument.Posted := false;
            IncomingDocument.Processed := false;
            IncomingDocument.Status := IncomingDocument.Status::Released;
            IncomingDocument."Document No." := '';
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::" ";
            IncomingDocument."Posting Date" := 0D;
            IncomingDocument.Modify(true);
        end;

        IncomingDocument.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateAttachments(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentId: Guid)
    begin
        DeleteUnusedAttachments(TempOldAttachmentEntityBuffer, TempNewAttachmentEntityBuffer);
        LinkNewAttachmentsToDocument(TempOldAttachmentEntityBuffer, TempNewAttachmentEntityBuffer, DocumentId);
    end;

    local procedure DeleteUnusedAttachments(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    begin
        if TempOldAttachmentEntityBuffer.FindSet then
            repeat
                if not TempNewAttachmentEntityBuffer.Get(TempOldAttachmentEntityBuffer.Id) then
                    PropagateDeleteAttachment(TempOldAttachmentEntityBuffer);
            until TempOldAttachmentEntityBuffer.Next = 0;
    end;

    local procedure LinkNewAttachmentsToDocument(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentId: Guid)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        AttachmentId: Guid;
        FileName: Text[250];
    begin
        if TempNewAttachmentEntityBuffer.FindSet then
            repeat
                AttachmentId := TempNewAttachmentEntityBuffer.Id;
                FileName := TempNewAttachmentEntityBuffer."File Name";
                if not TempOldAttachmentEntityBuffer.Get(AttachmentId) then
                    case true of
                        FindUnlinkedAttachment(AttachmentId, UnlinkedAttachment):
                            begin
                                if FileName = '' then
                                    FileName := UnlinkedAttachment."File Name";
                                LinkAttachmentToDocument(UnlinkedAttachment.Id, DocumentId, FileName);
                            end;
                        FindLinkedAttachment(AttachmentId, IncomingDocumentAttachment):
                            begin
                                IncomingDocumentAttachment.CalcFields(Content);
                                TempNewAttachmentEntityBuffer.Content := IncomingDocumentAttachment.Content;
                                TempNewAttachmentEntityBuffer.Modify(true);
                                CopyAttachment(TempNewAttachmentEntityBuffer, UnlinkedAttachment, true);
                                if FileName = '' then
                                    FileName := NameAndExtensionToFileName(
                                        IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
                                LinkAttachmentToDocument(UnlinkedAttachment.Id, DocumentId, FileName);
                            end;
                        else begin
                                CopyAttachment(TempNewAttachmentEntityBuffer, UnlinkedAttachment, false);
                                if FileName = '' then
                                    FileName := UnlinkedAttachment."File Name";
                                LinkAttachmentToDocument(UnlinkedAttachment.Id, DocumentId, FileName);
                            end;
                    end
                else
                    if TempNewAttachmentEntityBuffer."File Name" <> TempOldAttachmentEntityBuffer."File Name" then
                        if FindLinkedAttachment(AttachmentId, IncomingDocumentAttachment) then begin
                            FileNameToNameAndExtension(FileName, IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
                            IncomingDocumentAttachment.Modify(true);
                        end;
            until TempNewAttachmentEntityBuffer.Next = 0;
    end;

    local procedure LinkAttachmentToDocument(AttachmentId: Guid; DocumentId: Guid; FileName: Text[250])
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        UnlinkedAttachment: Record "Unlinked Attachment";
        ErrorMsg: Text;
    begin
        UnlinkedAttachment.SetAutoCalcFields(Content);
        UnlinkedAttachment.Get(AttachmentId);
        TransferFromUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment);
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := FileName;
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("Created Date-Time"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo(Content), TempFieldBuffer);
        PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg);
    end;

    local procedure UnlinkAttachmentFromDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
    begin
        TransferFromIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, EmptyGuid);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("Created Date-Time"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo(Content), TempFieldBuffer);
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    procedure CopyAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment"; GenerateNewId: Boolean)
    begin
        UnlinkedAttachment.TransferFields(TempAttachmentEntityBuffer);
        if GenerateNewId then
            Clear(UnlinkedAttachment.Id);
        UnlinkedAttachment.Insert(true);
    end;

    procedure RegisterFieldSet(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Attachment Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure GetDocumentIdFilter(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"): Text
    var
        DocumentIdFilter: Text;
    begin
        if IsNullGuid(AttachmentEntityBuffer."Document Id") then begin
            DocumentIdFilter := AttachmentEntityBuffer.GetFilter("Document Id");
            if DocumentIdFilter = '' then
                DocumentIdFilter := Format(EmptyGuid);
        end else
            DocumentIdFilter := Format(AttachmentEntityBuffer."Document Id");
        exit(DocumentIdFilter);
    end;

    local procedure GetGLEntryNoFilter(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"): Text
    var
        GLEntryNoFilter: Text;
    begin
        if AttachmentEntityBuffer."G/L Entry No." = 0 then
            GLEntryNoFilter := AttachmentEntityBuffer.GetFilter("G/L Entry No.")
        else
            GLEntryNoFilter := Format(AttachmentEntityBuffer."G/L Entry No.");
        exit(GLEntryNoFilter);
    end;

    local procedure IsLinkedAttachment(DocumentIdFilter: Text): Boolean
    begin
        exit((DocumentIdFilter <> '') and (DocumentIdFilter <> Format(EmptyGuid)));
    end;

    local procedure IsPostedDocument(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(
          (DocumentRecordRef.Number = DATABASE::"Sales Invoice Header") or (DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header"));
    end;

    local procedure IsGeneralJournalLine(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"Gen. Journal Line");
    end;

    local procedure IsGLEntry(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"G/L Entry");
    end;

    local procedure IsSalesInvoice(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry";
    begin
        if DocumentRecordRef.Number = DATABASE::"Sales Invoice Header" then
            exit(true);
        if DocumentRecordRef.Number = DATABASE::"Sales Header" then begin
            GetDocumentType(DocumentRecordRef, DocumentType);
            exit(DocumentType = DocumentType::Invoice);
        end;
        exit(false);
    end;

    local procedure IsPurchaseInvoice(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry";
    begin
        if DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header" then
            exit(true);
        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            GetDocumentType(DocumentRecordRef, DocumentType);
            exit(DocumentType = DocumentType::Invoice);
        end;
        exit(false);
    end;

    local procedure IsSalesQuote(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::Quote);
    end;

    local procedure GetDocumentType(var DocumentRecordRef: RecordRef; var DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry")
    var
        SalesHeader: Record "Sales Header";
    begin
        if DocumentRecordRef.Number = DATABASE::"Gen. Journal Line" then begin
            DocumentType := DocumentType::"Journal Line";
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"G/L Entry" then begin
            DocumentType := DocumentType::"G/L Entry";
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Sales Invoice Header" then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header" then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        DocumentRecordRef.SetTable(SalesHeader);

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then begin
            DocumentType := DocumentType::Quote;
            exit;
        end;

        Error(DocumentTypeErr);
    end;

    local procedure GetDocumentId(var DocumentRecordRef: RecordRef): Guid
    var
        DummySalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        DataTypeManagement: Codeunit "Data Type Management";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        IdFieldRef: FieldRef;
        Id: Guid;
    begin
        case DocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    exit(SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
                end;
            Database::"Purch. Inv. Header":
                begin
                    DocumentRecordRef.SetTable(PurchInvHeader);
                    exit(PurchInvAggregator.GetPurchaseInvoiceHeaderId(PurchInvHeader));
                end;
            Database::"Gen. Journal Line":
                begin
                    Evaluate(Id, Format(DocumentRecordRef.Field(DocumentRecordRef.SystemIdNo()).Value()));
                    exit(Id);
                end;
        end;

        if DataTypeManagement.FindFieldByName(DocumentRecordRef, IdFieldRef, DummySalesHeader.FieldName(Id)) then
            Evaluate(Id, Format(IdFieldRef.Value));
        exit(Id);
    end;

    local procedure GetGLEntryNo(var DocumentRecordRef: RecordRef): Integer
    var
        DummyGLEntry: Record "G/L Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        EntryNoFieldRef: FieldRef;
        EntryNo: Integer;
    begin
        if DataTypeManagement.FindFieldByName(DocumentRecordRef, EntryNoFieldRef, DummyGLEntry.FieldName("Entry No.")) then
            Evaluate(EntryNo, Format(EntryNoFieldRef.Value));
        exit(EntryNo);
    end;

    procedure GetDocumentIdFromAttachmentId(AttachmentId: Guid): Guid
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        DocumentVariant: Variant;
        DocumentRecordRef: RecordRef;
    begin
        IncomingDocumentAttachment.SetFilter(Id, AttachmentId);
        if not IncomingDocumentAttachment.FindFirst then
            exit(EmptyGuid);

        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");

        if not IncomingDocument.GetRecord(DocumentVariant) then
            Error(CannotFindRelatedDocumentErr);

        DocumentRecordRef.GetTable(DocumentVariant);

        exit(GetDocumentId(DocumentRecordRef));
    end;

    local procedure VerifyCRUDIsPossibleSafe(var DocumentRecordRef: RecordRef; var ErrorMsg: Text)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SearchSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SearchPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SearchSalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentId: Guid;
    begin
        DocumentId := GetDocumentId(DocumentRecordRef);

        if IsGeneralJournalLine(DocumentRecordRef) then begin
            GenJournalLine.SetRange(SystemId, DocumentId);
            if not GenJournalLine.FindFirst then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            exit;
        end;

        if IsGLEntry(DocumentRecordRef) then
            exit;

        if IsSalesInvoice(DocumentRecordRef) then begin
            SalesInvoiceEntityAggregate.SetRange(Id, DocumentId);
            if not SalesInvoiceEntityAggregate.FindFirst then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesInvoiceEntityAggregate.Copy(SalesInvoiceEntityAggregate);
            if SearchSalesInvoiceEntityAggregate.Next <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsPurchaseInvoice(DocumentRecordRef) then begin
            PurchInvEntityAggregate.SetRange(Id, DocumentId);
            if not PurchInvEntityAggregate.FindFirst then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchPurchInvEntityAggregate.Copy(PurchInvEntityAggregate);
            if SearchPurchInvEntityAggregate.Next <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsSalesQuote(DocumentRecordRef) then begin
            SalesQuoteEntityBuffer.SetRange(Id, DocumentId);
            if not SalesQuoteEntityBuffer.FindFirst then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesQuoteEntityBuffer.Copy(SalesQuoteEntityBuffer);
            if SearchSalesQuoteEntityBuffer.Next <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        ErrorMsg := DocumentDoesNotExistErr;
    end;

    local procedure VerifyCRUDIsPossible(var DocumentRecordRef: RecordRef)
    var
        ErrorMsg: Text;
    begin
        VerifyCRUDIsPossibleSafe(DocumentRecordRef, ErrorMsg);
        ThrowErrorIfAny(ErrorMsg);
    end;

    local procedure FindLinkedAttachment(AttachmentId: Guid; var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    begin
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        exit(IncomingDocumentAttachment.FindFirst);
    end;

    local procedure FindUnlinkedAttachment(AttachmentId: Guid; var UnlinkedAttachment: Record "Unlinked Attachment"): Boolean
    begin
        exit(UnlinkedAttachment.Get(AttachmentId));
    end;

    local procedure FindParentDocumentSafe(DocumentIdFilter: Text; var DocumentRecordRef: RecordRef; var ErrorMsg: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        DummyGLEntryNo: Integer;
    begin
        if DocumentIdFilter = '' then begin
            ErrorMsg := DocumentIDNotSpecifiedForAttachmentsErr;
            exit;
        end;

        Value := DummyGLEntryNo;
        if TypeHelper.Evaluate(Value, DocumentIdFilter, '', 'en-US') then begin
            GLEntry.SetFilter("Entry No.", DocumentIdFilter);
            if GLEntry.FindFirst then begin
                DocumentRecordRef.GetTable(GLEntry);
                exit;
            end;
        end;

        GenJournalLine.SetFilter(SystemId, DocumentIdFilter);
        if GenJournalLine.FindFirst then begin
            DocumentRecordRef.GetTable(GenJournalLine);
            exit;
        end;

        SalesHeader.SetFilter(Id, DocumentIdFilter);
        if SalesHeader.FindFirst then begin
            DocumentRecordRef.GetTable(SalesHeader);
            exit;
        end;

        if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentIdFilter, SalesInvoiceHeader) then begin
            DocumentRecordRef.GetTable(SalesInvoiceHeader);
            exit;
        end;

        PurchaseHeader.SetFilter(Id, DocumentIdFilter);
        if PurchaseHeader.FindFirst then begin
            DocumentRecordRef.GetTable(PurchaseHeader);
            exit;
        end;

        if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentIdFilter, PurchInvHeader) then begin
            DocumentRecordRef.GetTable(PurchInvHeader);
            exit;
        end;

        ErrorMsg := DocumentDoesNotExistErr;
    end;

    local procedure FindParentDocument(DocumentIdFilter: Text; var DocumentRecordRef: RecordRef)
    var
        ErrorMsg: Text;
    begin
        FindParentDocumentSafe(DocumentIdFilter, DocumentRecordRef, ErrorMsg);
        ThrowErrorIfAny(ErrorMsg);
    end;

    local procedure FindIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        if IsPostedDocument(DocumentRecordRef) or IsGLEntry(DocumentRecordRef) then
            exit(IncomingDocument.FindByDocumentNoAndPostingDate(DocumentRecordRef, IncomingDocument));
        exit(IncomingDocument.FindFromIncomingDocumentEntryNo(DocumentRecordRef, IncomingDocument));
    end;

    local procedure FindOrCreateIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit;

        IncomingDocument.Init();
        IncomingDocument."Related Record ID" := DocumentRecordRef.RecordId;

        if IsSalesInvoice(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(SalesInvoiceHeader);
            IncomingDocument.Description := CopyStr(SalesInvoiceHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesInvoiceHeader."No.";
            IncomingDocument."Posting Date" := SalesInvoiceHeader."Posting Date";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if IsGeneralJournalLine(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GenJournalLine);
            IncomingDocument.Description := CopyStr(GenJournalLine.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
            IncomingDocument.Insert(true);
            GenJournalLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
            GenJournalLine.Modify();
            DocumentRecordRef.GetTable(GenJournalLine);
            exit;
        end;

        if IsGLEntry(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GLEntry);
            IncomingDocument.Description := CopyStr(GLEntry.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document No." := GLEntry."Document No.";
            IncomingDocument."Posting Date" := GLEntry."Posting Date";
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Sales Header" then begin
            DocumentRecordRef.SetTable(SalesHeader);
            IncomingDocument.Description := CopyStr(SalesHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesHeader."No.";
            IncomingDocument.Insert(true);
            SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            SalesHeader.Modify();
            exit;
        end;

        if IsPurchaseInvoice(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(PurchInvHeader);
            IncomingDocument.Description := CopyStr(PurchInvHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Posting Date" := PurchInvHeader."Posting Date";
            IncomingDocument."Document No." := PurchInvHeader."No.";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            DocumentRecordRef.SetTable(PurchaseHeader);
            IncomingDocument.Description := CopyStr(PurchaseHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Document No." := PurchaseHeader."No.";
            IncomingDocument.Insert(true);
            PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            PurchaseHeader.Modify();
            exit;
        end;
    end;

    local procedure LoadLinkedAttachmentsToBuffer(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocument: Record "Incoming Document"; AttachmentIdFilter: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        LoadContent: Boolean;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        LoadContent := AttachmentIdFilter <> '';
        if LoadContent then
            IncomingDocumentAttachment.SetFilter(Id, AttachmentIdFilter);

        if not IncomingDocumentAttachment.FindSet then
            exit;

        repeat
            if LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for transferring
            TransferFromIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment);
            if not LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for getting content length
            TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
            TempAttachmentEntityBuffer.Modify(true);
        until IncomingDocumentAttachment.Next = 0;
    end;

    local procedure LoadUnlinkedAttachmentsToBuffer(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; AttachmentIdFilter: Text)
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
        TempBlob: Codeunit "Temp Blob";
        LoadContent: Boolean;
    begin
        LoadContent := AttachmentIdFilter <> '';
        if LoadContent then
            UnlinkedAttachment.SetFilter(Id, AttachmentIdFilter);

        if not UnlinkedAttachment.FindSet then
            exit;

        repeat
            Clear(TempAttachmentEntityBuffer);
            if LoadContent then
                UnlinkedAttachment.CalcFields(Content); // Needed for transferring
            TransferFromUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment);
            if not LoadContent then
                UnlinkedAttachment.CalcFields(Content); // Needed for getting content length
            TempBlob.FromRecord(UnlinkedAttachment, UnlinkedAttachment.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
            TempAttachmentEntityBuffer.Modify(true);
        until UnlinkedAttachment.Next = 0;
    end;

    local procedure TransferToIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var TempFieldBuffer: Record "Field Buffer" temporary; IsNewAttachment: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        AttachmentRecordRef: RecordRef;
        UpdateFileName: Boolean;
        Name: Text[250];
        Extension: Text[30];
    begin
        if not IsNewAttachment then begin
            TempBlob.FromRecord(TempAttachmentEntityBuffer, TempAttachmentEntityBuffer.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
        end;
        TempFieldBuffer.SetRange("Field ID", TempAttachmentEntityBuffer.FieldNo("File Name"));
        UpdateFileName := TempFieldBuffer.FindFirst;
        if UpdateFileName then
            FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        AttachmentRecordRef.GetTable(IncomingDocumentAttachment);
        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, TempAttachmentEntityBuffer, AttachmentRecordRef);
        AttachmentRecordRef.SetTable(IncomingDocumentAttachment);
        if UpdateFileName then begin
            IncomingDocumentAttachment.Validate(Name, Name);
            IncomingDocumentAttachment.Validate("File Extension", Extension);
        end;
    end;

    local procedure TransferToUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment"; var TempFieldBuffer: Record "Field Buffer" temporary; IsNewAttachment: Boolean)
    var
        TypeHelper: Codeunit "Type Helper";
        AttachmentRecordRef: RecordRef;
    begin
        if not IsNewAttachment then
            TempAttachmentEntityBuffer.CalcFields(Content);
        AttachmentRecordRef.GetTable(UnlinkedAttachment);
        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, TempAttachmentEntityBuffer, AttachmentRecordRef);
        AttachmentRecordRef.SetTable(UnlinkedAttachment);
    end;

    procedure TransferFromIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(IncomingDocumentAttachment, true);
        TempAttachmentEntityBuffer."File Name" := NameAndExtensionToFileName(
            IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        TempAttachmentEntityBuffer.Insert(true);
    end;

    local procedure TransferFromIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; DocumentId: Guid)
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(IncomingDocumentAttachment, true);
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := NameAndExtensionToFileName(
            IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        TempAttachmentEntityBuffer.Insert(true);
    end;

    procedure TransferFromUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment")
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(UnlinkedAttachment, true);
        TempAttachmentEntityBuffer.Insert(true);
    end;

    local procedure TransferIntegrationRecordID(AttachmentId: Guid; var RecordRef: RecordRef)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        NewIntegrationRecord: Record "Integration Record";
        OldIntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
    begin
        if IsNullGuid(AttachmentId) then
            exit;

        case RecordRef.Number of
            DATABASE::"Incoming Document Attachment":
                begin
                    RecordRef.SetTable(IncomingDocumentAttachment);
                    if IncomingDocumentAttachment.Id = AttachmentId then
                        exit;

                    if OldIntegrationRecord.Get(AttachmentId) then
                        OldIntegrationRecord.Delete();

                    if NewIntegrationRecord.Get(IncomingDocumentAttachment.Id) then
                        NewIntegrationRecord.Delete();

                    IncomingDocumentAttachment.Id := AttachmentId;
                    IncomingDocumentAttachment.Modify(true);
                end;
            DATABASE::"Unlinked Attachment":
                begin
                    RecordRef.SetTable(UnlinkedAttachment);
                    if UnlinkedAttachment.Id = AttachmentId then
                        exit;

                    if OldIntegrationRecord.Get(AttachmentId) then
                        OldIntegrationRecord.Delete();

                    if NewIntegrationRecord.Get(UnlinkedAttachment.Id) then
                        NewIntegrationRecord.Delete();

                    UnlinkedAttachment.Rename(AttachmentId);
                end;
        end;

        IntegrationManagement.InsertUpdateIntegrationRecord(RecordRef, CurrentDateTime);
    end;

    [Scope('Cloud')]
    procedure GetContentLength(var TempBlob: Codeunit "Temp Blob"): Integer
    var
        InStream: InStream;
        MemoryStream: DotNet MemoryStream;
        ContentLength: Integer;
    begin
        if not TempBlob.HasValue then
            exit(0);
        TempBlob.CreateInStream(InStream);
        MemoryStream := MemoryStream.MemoryStream;
        CopyStream(MemoryStream, InStream);
        ContentLength := MemoryStream.Length;
        MemoryStream.Close;
        exit(ContentLength);
    end;

    local procedure ThrowErrorIfAny(ErrorMsg: Text)
    begin
        if ErrorMsg <> '' then
            Error(ErrorMsg);
    end;

    local procedure FileNameToNameAndExtension(FileName: Text; var Name: Text[250]; var Extension: Text[30])
    var
        FileManagement: Codeunit "File Management";
    begin
        Extension := CopyStr(FileManagement.GetExtension(FileName), 1, MaxStrLen(Extension));
        Name := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(Name));
    end;

    local procedure NameAndExtensionToFileName(Name: Text[250]; Extension: Text[30]): Text[250]
    begin
        if Extension <> '' then
            exit(StrSubstNo('%1.%2', Name, Extension));
        exit(Name);
    end;
}

