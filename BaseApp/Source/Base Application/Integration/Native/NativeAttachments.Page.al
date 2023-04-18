#if not CLEAN20
page 2820 "Native - Attachments"
{
    Caption = 'nativeInvoicingAttachments', Locked = true;
    DelayedInsert = true;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;
    PageType = List;
    ODataKeyFields = SystemId;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    begin
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Id), TempFieldBuffer);
                    end;
                }
                field(documentId; "Document Id")
                {
                    ApplicationArea = All;
                    Caption = 'documentId', Locked = true;
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
                        if ContentChanged then
                            Error(ContentChangedErr);

                        if AttachmentsLoaded then
                            Modify();
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Content), TempFieldBuffer);

                        ContentChanged := true;
                    end;
                }
                field(base64Content; Base64Content)
                {
                    ApplicationArea = All;
                    Caption = 'base64Content', Locked = true;
                    ToolTip = 'Specifies base64 encoded content.';

                    trigger OnValidate()
                    begin
                        if ContentChanged then
                            Error(ContentChangedErr);

                        ContentFromBase64String();
                        if AttachmentsLoaded then
                            Modify();
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Content), TempFieldBuffer);

                        ContentChanged := true;
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
            FilterView := GetView();
            DocumentIdFilter := GetFilter("Document Id");
            AttachmentIdFilter := GetFilter(Id);
            if (AttachmentIdFilter <> '') and (DocumentIdFilter = '') then begin
                DocumentId := GraphMgtAttachmentBuffer.GetDocumentIdFromAttachmentId(AttachmentIdFilter);
                DocumentIdFilter := Format(DocumentId);
            end;
            GraphMgtAttachmentBuffer.LoadAttachments(Rec, DocumentIdFilter, AttachmentIdFilter);
            SetView(FilterView);
            AttachmentsFound := FindFirst();
            if not AttachmentsFound then
                exit(false);
            AttachmentsLoaded := true;
        end;
        exit(AttachmentsFound);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FileManagement: Codeunit "File Management";
    begin
        if not FileManagement.IsValidFileName("File Name") then
            Validate("File Name", 'filename.txt');

        Validate("Created Date-Time", RoundDateTime(CurrentDateTime, 1000));
        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo("Created Date-Time"), TempFieldBuffer);

        ByteSizeFromContent();

        GraphMgtAttachmentBuffer.PropagateInsertAttachmentSafe(Rec, TempFieldBuffer);

        Base64Content := ''; // Cut out base64Content from the response
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        GraphMgtAttachmentBuffer.PropagateModifyAttachment(Rec, TempFieldBuffer);
        ByteSizeFromContent();
        Base64Content := ''; // Cut out base64Content from the response
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        TempFieldBuffer.Reset();
        TempFieldBuffer.DeleteAll();
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
        AttachmentsLoaded: Boolean;
        AttachmentsFound: Boolean;
        ContentChanged: Boolean;
        Base64Content: Text;
        ContentChangedErr: Label 'Only one either content or base64Content could be specified.';

    [Scope('OnPrem')]
    procedure ContentFromBase64String()
    var
        OutStream: OutStream;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
    begin
        Clear(Content);
        if Base64Content = '' then
            exit;
        MemoryStream := MemoryStream.MemoryStream(Convert.FromBase64String(Base64Content));
        Content.CreateOutStream(OutStream);
        MemoryStream.WriteTo(OutStream);
        MemoryStream.Close();
    end;

    local procedure ByteSizeFromContent()
    var
        TempBlob: Codeunit "Temp Blob";
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
    begin
        TempBlob.FromRecord(Rec, FieldNo(Content));
        "Byte Size" := GraphMgtAttachmentBuffer.GetContentLength(TempBlob);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; var UnlinkedAttachment: Record "Unlinked Attachment")
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(Id), UnlinkedAttachment.Id);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Attachments");
    end;

    [ServiceEnabled]
    procedure Copy(var ActionContext: DotNet WebServiceActionContext)
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
    begin
        GraphMgtAttachmentBuffer.CopyAttachment(Rec, UnlinkedAttachment, true);
        SetActionResponse(ActionContext, UnlinkedAttachment);
    end;
}
#endif
