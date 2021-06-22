codeunit 2112 "O365 Sales Attachment Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        EmailSizeAboveMaxTxt: Label 'The total size of the attachments exceeds the maximum limit (%1). Remove some to be able to send your document.', Comment = '%1=the total size allowed for all the attachments, e.g. "25 MB"';
        NotSupportedMsg: Label 'Cannot view this file type.';
        PhotoLbl: Label 'Photo %1', Comment = '%1 = a number, e.g. 1, 2, 3,...';
        MovieLbl: Label 'Movie %1', Comment = '%1 = a number, e.g. 1, 2, 3,...';
        MegaBytesLbl: Label '%1 MB', Comment = '%1=the number of megabytes';
        AttachmentNameToBeTruncatedMsg: Label 'Names of attachments can contain up to %1 characters. We will shorten longer names to that length.', Comment = '%1=the allowed size of the file name';
        AttachmentNameSizeNotificationGuidTok: Label '9784860c-a89d-439e-b845-424206790b9e', Locked = true;

    procedure GetNoOfAttachments(RecordVariant: Variant): Integer
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not GetAttachments(RecordVariant, IncomingDocumentAttachment) then
            exit(0);

        exit(IncomingDocumentAttachment.Count);
    end;

    [Scope('OnPrem')]
    procedure GetSizeOfAttachments(var IncomingDocumentAttachment: Record "Incoming Document Attachment") TotalSize: Integer
    begin
        TotalSize := 0;

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        if IncomingDocumentAttachment.FindSet then
            repeat
                if IncomingDocumentAttachment.Content.HasValue then
                    TotalSize += IncomingDocumentAttachment.Content.Length;
            until IncomingDocumentAttachment.Next = 0;
    end;

    procedure GetAttachments(RecordVariant: Variant; var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecordVariant);
        if RecordRef.Number = DATABASE::"Sales Header" then begin
            SalesHeader := RecordVariant;
            if SalesHeader."Incoming Document Entry No." = 0 then
                exit(false);

            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", SalesHeader."Incoming Document Entry No.");
            exit(not IncomingDocumentAttachment.IsEmpty);
        end;

        if RecordRef.Number = DATABASE::"Sales Invoice Header" then begin
            SalesInvoiceHeader := RecordVariant;
            IncomingDocumentAttachment.SetRange("Document No.", SalesInvoiceHeader."No.");
            IncomingDocumentAttachment.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
            exit(not IncomingDocumentAttachment.IsEmpty);
        end;

        exit(false);
    end;

    procedure EditAttachments(RecordVariant: Variant) NoOfAttachments: Integer
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecordVariant);
        if not RecordRef.Find then
            exit;
        RecordVariant := RecordRef;
        if RecordRef.Number = DATABASE::"Sales Header" then begin
            SalesHeader := RecordVariant;
            if SalesHeader."Incoming Document Entry No." = 0 then begin
                SalesHeader."Incoming Document Entry No." := IncomingDocument.CreateIncomingDocument(SalesHeader."Sell-to Customer Name", '');
                SalesHeader.Modify();
                Commit();
                RecordVariant := SalesHeader;
            end;
            SalesHeader.SetRecFilter;
            PAGE.Run(PAGE::"O365 Sales Doc. Attachments", SalesHeader);
        end;
        if RecordRef.Number = DATABASE::"Sales Invoice Header" then begin
            SalesInvoiceHeader := RecordVariant;
            SalesInvoiceHeader.SetRecFilter;
            PAGE.Run(PAGE::"O365 Posted Sales Inv. Att.", SalesInvoiceHeader);
        end;
        NoOfAttachments := GetNoOfAttachments(RecordVariant);
    end;

    procedure ImportAttachmentFromFileSystem(var IncomingDocumentAttachmentOrig: Record "Incoming Document Attachment")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.CopyFilters(IncomingDocumentAttachmentOrig);
        IncomingDocumentAttachment.NewAttachment;
        case IncomingDocumentAttachment.Type of
            IncomingDocumentAttachment.Type::Image:
                IncomingDocumentAttachment.Name :=
                  CopyStr(
                    StrSubstNo(PhotoLbl, IncomingDocumentAttachment."Line No." div 10000), 1, MaxStrLen(IncomingDocumentAttachment.Name));
            IncomingDocumentAttachment.Type::Other:
                if UpperCase(IncomingDocumentAttachment."File Extension") = 'MOV' then
                    IncomingDocumentAttachment.Name :=
                      CopyStr(
                        StrSubstNo(MovieLbl, IncomingDocumentAttachment."Line No." div 10000), 1, MaxStrLen(IncomingDocumentAttachment.Name));
        end;
        IncomingDocumentAttachment.Modify();
    end;

    [Scope('OnPrem')]
    procedure OpenAttachmentPreviewIfSupported(IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        with IncomingDocumentAttachment do begin
            CalcFields(Content);
            if not Content.HasValue then
                exit;

            case Type of
                Type::Image:
                    PAGE.RunModal(PAGE::"O365 Incoming Doc. Att. Pict.", IncomingDocumentAttachment);
                Type::PDF:
                    Export(Name + '.' + "File Extension", true)
                else
                    Message(NotSupportedMsg);
            end;
        end
    end;

    [Scope('OnPrem')]
    procedure WarnIfIncomingDocumentSizeAboveMax(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        if GetSizeOfAttachments(IncomingDocumentAttachment) > GetMaxEmailAttachmentsSize then
            Message(StrSubstNo(EmailSizeAboveMaxTxt, GetMaxEmailAttachmentsSizeAsText));
    end;

    [Scope('OnPrem')]
    procedure NotifyIfFileNameIsTruncated(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        AttachmentNameSizeNotification: Notification;
        AttachmentNameSize: Integer;
        AllowedAttachmentNameSize: Integer;
    begin
        AttachmentNameSize := StrLen(StrSubstNo('%1.%2', IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension"));
        AllowedAttachmentNameSize := GetMaxAllowedFileNameSize;
        if AttachmentNameSize > AllowedAttachmentNameSize then begin
            AttachmentNameSizeNotification.Id := AttachmentNameSizeNotificationGuidTok;
            AttachmentNameSizeNotification.Message(StrSubstNo(AttachmentNameToBeTruncatedMsg, AllowedAttachmentNameSize));
            AttachmentNameSizeNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            AttachmentNameSizeNotification.Send;
        end;
    end;

    [Scope('OnPrem')]
    procedure AssertIncomingDocumentSizeBelowMax(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        if GetSizeOfAttachments(IncomingDocumentAttachment) > GetMaxEmailAttachmentsSize then
            Error(EmailSizeAboveMaxTxt, GetMaxEmailAttachmentsSizeAsText);
    end;

    local procedure GetMaxEmailAttachmentsSize() MaxEmailAttachmentSize: Integer
    var
        CompanyInformation: Record "Company Information";
        GraphMail: Codeunit "Graph Mail";
        MaxEmailSize: Integer;
    begin
        if GraphMail.IsEnabled then
            MaxEmailSize := 4 * 1024 * 1024 // REST request size limit is 4MB, including body and emailed documents
        else
            MaxEmailSize := 25 * 1024 * 1024; // 25MB limit for SMTP emails, including body and emailed documents

        CompanyInformation.CalcFields(Picture);

        MaxEmailAttachmentSize := MaxEmailSize - CompanyInformation.Picture.Length - 512 * 1024;// Subtract company logo and 500 KB for rest

        if MaxEmailAttachmentSize < 0 then
            exit(0);
    end;

    local procedure GetMaxEmailAttachmentsSizeAsText(): Text[10]
    var
        Bytes: Integer;
        MegaBytes: Integer;
    begin
        Bytes := GetMaxEmailAttachmentsSize;
        MegaBytes := Bytes div (1024 * 1024);
        exit(StrSubstNo(MegaBytesLbl, MegaBytes));
    end;

    [Scope('OnPrem')]
    procedure GetMaxAllowedFileNameSize(): Integer
    var
        EmailItem: Record "Email Item";
    begin
        exit(MaxStrLen(EmailItem."Attachment Name 2"));
    end;
}

