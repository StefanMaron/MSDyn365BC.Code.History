page 5512 "G/L Entry Attachments Entity"
{
    Caption = 'generalLedgerEntryAttachments', Locked = true;
    DelayedInsert = true;
    EntityName = 'generalLedgerEntryAttachments';
    EntitySetName = 'generalLedgerEntryAttachments';
    ODataKeyFields = "G/L Entry No.", Id;
    PageType = API;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(generalLedgerEntryNumber; "G/L Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'generalLedgerEntryNumber', Locked = true;
                }
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    begin
                        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo(Id), TempFieldBuffer);
                    end;
                }
                field(fileName; "File Name")
                {
                    ApplicationArea = All;
                    Caption = 'fileName', Locked = true;

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
                field(createdDateTime; "Created Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'createdDateTime', Locked = true;
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
        GLEntryNoFilter: Text;
        AttachmentIdFilter: Text;
        FilterView: Text;
    begin
        if not AttachmentsLoaded then begin
            FilterView := GetView;
            GLEntryNoFilter := GetFilter("G/L Entry No.");
            AttachmentIdFilter := GetFilter(Id);
            if GLEntryNoFilter = '' then
                Error(MissingGLEntryNoErr);

            GraphMgtAttachmentBuffer.LoadAttachments(Rec, GLEntryNoFilter, AttachmentIdFilter);
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
        FileManagement: Codeunit "File Management";
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        GLEntryNoFilter: Text;
        FilterView: Text;
    begin
        if "G/L Entry No." = 0 then begin
            FilterView := GetView;
            GLEntryNoFilter := GetFilter("G/L Entry No.");
            if GLEntryNoFilter <> '' then begin
                Value := "G/L Entry No.";
                TypeHelper.Evaluate(Value, GLEntryNoFilter, '', 'en-US');
                "G/L Entry No." := Value;
            end;
            SetView(FilterView);
        end;
        if "G/L Entry No." = 0 then
            Error(MissingGLEntryNoErr);

        if not FileManagement.IsValidFileName("File Name") then
            Validate("File Name", 'filename.txt');

        Validate("Created Date-Time", RoundDateTime(CurrentDateTime, 1000));
        GraphMgtAttachmentBuffer.RegisterFieldSet(FieldNo("Created Date-Time"), TempFieldBuffer);

        ByteSizeFromContent;

        GraphMgtAttachmentBuffer.PropagateInsertAttachment(Rec, TempFieldBuffer);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if xRec.Id <> Id then
            Error(StrSubstNo(CannotModifyKeyFieldErr, 'id'));
        if xRec."G/L Entry No." <> "G/L Entry No." then
            Error(StrSubstNo(CannotModifyKeyFieldErr, 'generalLedgerEntryNumber'));

        GraphMgtAttachmentBuffer.PropagateModifyAttachment(Rec, TempFieldBuffer);
        ByteSizeFromContent;
        exit(false);
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        GraphMgtAttachmentBuffer: Codeunit "Graph Mgt - Attachment Buffer";
        AttachmentsLoaded: Boolean;
        AttachmentsFound: Boolean;
        MissingGLEntryNoErr: Label 'You must specify a generalLedgerEntryNumber in the request body.', Locked = true;
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

