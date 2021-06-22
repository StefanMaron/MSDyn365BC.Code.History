page 5511 "Attachments Entity"
{
    Caption = 'attachments', Locked = true;
    DelayedInsert = true;
    EntityName = 'attachments';
    EntitySetName = 'attachments';
    ODataKeyFields = "Document Id", Id;
    PageType = API;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    begin
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Id), TempFieldBuffer);
                    end;
                }
                field(parentId; "Document Id")
                {
                    ApplicationArea = All;
                    Caption = 'parentId', Locked = true;
                }
                field(fileName; "File Name")
                {
                    ApplicationArea = All;
                    Caption = 'fileName', Locked = true;
                    ToolTip = 'Specifies the Description for the Item.';

                    trigger OnValidate()
                    begin
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo("File Name"), TempFieldBuffer);
                    end;
                }
                field(byteSize; "Byte Size")
                {
                    ApplicationArea = All;
                    Caption = 'byteSize', Locked = true;

                    trigger OnValidate()
                    begin
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo("Byte Size"), TempFieldBuffer);
                    end;
                }
                field(content; Content)
                {
                    ApplicationArea = All;
                    Caption = 'content', Locked = true;

                    trigger OnValidate()
                    begin
                        if AttachmentsLoaded then
                            Modify;
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Content), TempFieldBuffer);
                    end;
                }
                field(lastModifiedDateTime; "Created Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        GraphMgtAttachmentBuffer.PropagateDeleteAttachment(Rec);
        exit(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        DocumentIdFilter: Text;
        AttachmentIdFilter: Text;
        FilterView: Text;
        DocumentId: Guid;
    begin
        if not AttachmentsLoaded then begin
            FilterView := GetView;
            DocumentIdFilter := GetFilter("Document Id");
            AttachmentIdFilter := GetFilter(Id);
            if (AttachmentIdFilter <> '') and (DocumentIdFilter = '') then begin
                DocumentId := GraphMgtAttachmentBuffer.GetDocumentIdFromAttachmentId(AttachmentIdFilter);
                DocumentIdFilter := Format(DocumentId);
            end;
            if DocumentIdFilter = '' then
                Error(MissingParentIdErr);

            GraphMgtAttachmentBuffer.LoadAttachments(Rec, DocumentIdFilter, AttachmentIdFilter);
            SetView(FilterView);
            AttachmentsFound := FindFirst;
            if not AttachmentsFound then
                exit(false);
            AttachmentsLoaded := true;
        end;
        exit(AttachmentsFound);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        FileManagement: Codeunit "File Management";
        DocumentIdFilter: Text;
        FilterView: Text;
    begin
        if IsNullGuid("Document Id") then begin
            FilterView := GetView;
            DocumentIdFilter := GetFilter("Document Id");
            if DocumentIdFilter <> '' then
                Validate("Document Id", TypeHelper.GetGuidAsString(DocumentIdFilter));
            SetView(FilterView);
        end;
        if IsNullGuid("Document Id") then
            Error(MissingParentIdErr);

        if not FileManagement.IsValidFileName("File Name") then
            Validate("File Name", 'filename.txt');

        Validate("Created Date-Time", RoundDateTime(CurrentDateTime, 1000));
        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo("Created Date-Time"), TempFieldBuffer);

        ByteSizeFromContent;

        GraphMgtAttachmentBuffer.PropagateInsertAttachmentSafe(Rec, TempFieldBuffer);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if xRec.Id <> Id then
            Error(StrSubstNo(CannotModifyKeyFieldErr, 'id'));
        if xRec."Document Id" <> "Document Id" then
            Error(StrSubstNo(CannotModifyKeyFieldErr, 'parentId'));

        GraphMgtAttachmentBuffer.PropagateModifyAttachment(Rec, TempFieldBuffer);
        ByteSizeFromContent;
        exit(false);
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
        AttachmentsLoaded: Boolean;
        AttachmentsFound: Boolean;
        MissingParentIdErr: Label 'You must specify a parentId in the request body.', Locked = true;
        CannotModifyKeyFieldErr: Label 'You cannot change the value of the key field %1.', Locked = true;

    local procedure ByteSizeFromContent()
    var
        TempBlob: Codeunit "Temp Blob";
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
    begin
        TempBlob.FromRecord(Rec, FieldNo(Content));
        "Byte Size" := GraphMgtAttachmentBuffer.GetContentLength(TempBlob);
    end;
}

