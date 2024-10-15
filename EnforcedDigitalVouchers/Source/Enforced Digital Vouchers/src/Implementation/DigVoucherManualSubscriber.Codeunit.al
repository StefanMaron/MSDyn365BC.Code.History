codeunit 5584 "Dig. Voucher Manual Subscriber"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        DigitalVoucherEntry: Codeunit "Digital Voucher Entry";
        DigitalVoucherImpl: Codeunit "Digital Voucher Impl.";

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSaveDocumentAttachmentFromRecRef', '', true, true)]
    local procedure AttachDigitalVoucherOnBeforeSaveDocumentAttachmentFromRecRe(RecRef: RecordRef; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    var
        DocType: Text;
        DocNo: Code[20];
        PostingDate: Date;
    begin
        if not DigitalVoucherEntry.GetDocNoAndPostingDateFromRecRef(DocType, DocNo, PostingDate, RecRef) then
            exit;
        DigitalVoucherImpl.AttachBlobToIncomingDocument(TempBlob, DocType, PostingDate, DocNo);
        IsHandled := true;
    end;
}
