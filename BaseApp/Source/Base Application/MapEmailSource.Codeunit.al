codeunit 8898 "Map Email Source"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnShowSource', '', false, false)]
    local procedure OnGetPageForSourceRecord(SourceTableId: Integer; SourceSystemId: Guid; var IsHandled: Boolean)
    var
        PageManagement: Codeunit "Page Management";
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.GetBySystemId(SourceSystemId) then
            exit;

        if PageManagement.PageRun(SourceRecordRef) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnFindRelatedAttachments', '', false, false)]
    local procedure FindRelatedAttachments(SourceTableId: Integer; SourceSystemID: Guid; var EmailRelatedAttachments: Record "Email Related Attachment")
    var
        DocAttachment: Record "Document Attachment";
        SourceRecordRef: RecordRef;
        FieldNo: Integer;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.GetBySystemId(SourceSystemID) then
            exit;

        FieldNo := GetNoFieldFieldNumber(SourceTableId);
        DocAttachment.SetRange("No.", SourceRecordRef.Field(FieldNo).Value());
        if (FieldNo > 0) and DocAttachment.FindSet() then
            repeat
                EmailRelatedAttachments."Attachment Name" :=
                    CopyStr(StrSubstNo(FileFormatTxt, DocAttachment."File Name", DocAttachment."File Extension"),
                        1,
                        MaxStrLen(EmailRelatedAttachments."Attachment Name")
                    );
                EmailRelatedAttachments."Attachment Table ID" := Database::"Document Attachment";
                EmailRelatedAttachments."Attachment System ID" := DocAttachment.SystemId;
                EmailRelatedAttachments.Insert();
            until DocAttachment.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnGetAttachment', '', false, false)]
    local procedure InsertAttachment(AttachmentTableID: Integer; AttachmentSystemID: Guid; MessageID: Guid)
    var
        TenantMedia: Record "Tenant Media";
        DocAttachment: Record "Document Attachment";
        EmailMessage: Codeunit "Email Message";
        AttachmentInStream: InStream;
        AttachmentGuid: Guid;
        FileName: Text;
    begin
        if (AttachmentTableID <> Database::"Document Attachment") then
            exit;

        if not DocAttachment.GetBySystemId(AttachmentSystemID) then
            exit;

        EmailMessage.Get(MessageID);

        AttachmentGuid := DocAttachment."Document Reference ID".MediaId();
        TenantMedia.Get(AttachmentGuid);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(AttachmentInStream);
        FileName := StrSubstNo(FileFormatTxt, DocAttachment."File Name", DocAttachment."File Extension");

        EmailMessage.AddAttachment(CopyStr(FileName, 1, 250), TenantMedia."Mime Type", AttachmentInStream);
    end;

    local procedure GetNoFieldFieldNumber(TableID: Integer): Integer
    begin
        case TableID of
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item,
            DATABASE::Employee,
            DATABASE::"Fixed Asset",
            DATABASE::Resource,
            DATABASE::Job:
                exit(1);
            DATABASE::"Sales Header",
            DATABASE::"Purchase Header",
            DATABASE::"Sales Line",
            DATABASE::"Purchase Line",
            DATABASE::"Sales Invoice Header",
            DATABASE::"Sales Cr.Memo Header",
            DATABASE::"Purch. Inv. Header",
            DATABASE::"Purch. Cr. Memo Hdr.",
            DATABASE::"Sales Invoice Line",
            DATABASE::"Sales Cr.Memo Line",
            DATABASE::"Purch. Inv. Line",
            DATABASE::"Purch. Cr. Memo Line":
                exit(3);
        end;
    end;

    var
        FileFormatTxt: Label '%1.%2', Comment='%1=File Name, %2=File Extension', Locked = true;
}