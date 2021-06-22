codeunit 5509 "Graph Mgt - Inc Doc Attachment"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "G/L Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        AttachmentCategoryLbl: Label 'AL Attachment', Locked = true;
        NoPermissionErr: Label 'No permission to update a related document (table %1).', Comment = '%1=table number that caused the error', Locked = true;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        DummyIncomingDocumentAttachment: Record "Incoming Document Attachment";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Incoming Document Attachment");
        GraphMgtGeneralTools.UpdateIntegrationRecords(RecRef, DummyIncomingDocumentAttachment.FieldNo(Id), OnlyItemsWithoutId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;

    [EventSubscriber(ObjectType::Table, 133, 'OnAfterInsertEvent', '', false, false)]
    local procedure HandleOnAfterInsert(var Rec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 133, 'OnAfterModifyEvent', '', false, false)]
    local procedure HandleOnAfterUpdate(var Rec: Record "Incoming Document Attachment"; var xRec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 133, 'OnAfterRenameEvent', '', false, false)]
    local procedure HandleOnAfterRename(var Rec: Record "Incoming Document Attachment"; var xRec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 133, 'OnAfterDeleteEvent', '', false, false)]
    local procedure HandleOnAfterDelete(var Rec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    local procedure UpdateRelatedDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        IncomingDocument: Record "Incoming Document";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        IntegrationManagement: Codeunit "Integration Management";
        DataTypeManagement: Codeunit "Data Type Management";
        RelatedDocument: Variant;
        RelatedRecRef: RecordRef;
    begin
        if IncomingDocumentAttachment.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
            exit;

        if not IncomingDocument.GetRecord(RelatedDocument) then
            exit;

        if not DataTypeManagement.GetRecordRef(RelatedDocument, RelatedRecRef) then
            exit;

        if not RelatedRecRef.WritePermission then begin
            SendTraceTag('00006WH',
              AttachmentCategoryLbl,
              VERBOSITY::Error,
              StrSubstNo(NoPermissionErr, RelatedRecRef.Number),
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if not IntegrationManagement.IsIntegrationRecord(RelatedRecRef.Number) then
            exit;

        RelatedRecRef.Modify();
    end;
}

