page 2150 "O365 Sales Email Dialog"
{
    Caption = 'Send Email';
    PageType = StandardDialog;
    RefreshOnActivate = true;
    SourceTable = "Email Item";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(SendToText; SendTo)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'To';
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the recipient of the email.';

                trigger OnValidate()
                var
                    MailManagement: Codeunit "Mail Management";
                begin
                    MailManagement.CheckValidEmailAddresses(SendTo);
                    if SendTo <> TempEmailItem."Send to" then
                        GetEmailBody(SendTo);
                    TempEmailItem."Send to" := SendTo;
                end;
            }
            field(CcBccText; CcAndBcc)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'CC/BCC';
                Editable = false;
                Importance = Additional;
                QuickEntry = false;
                ToolTip = 'Specifies one or more additional recipients.';

                trigger OnAssistEdit()
                begin
                    PAGE.RunModal(PAGE::"BC O365 Email Settings");
                    TempEmailItem.AddCcBcc;
                    UpdateCcBccText(TempEmailItem."Send CC", TempEmailItem."Send BCC");
                end;
            }
            field(FromAddressField; FromAddress)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'From';
                Editable = false;
                ExtendedDatatype = EMail;
                QuickEntry = false;
                ToolTip = 'Specifies address for sending emails.';

                trigger OnAssistEdit()
                var
                    O365SetupEmail: Codeunit "O365 Setup Email";
                    MailManagement: Codeunit "Mail Management";
                begin
                    O365SetupEmail.SetupEmail(true);
                    FromAddress := MailManagement.GetSenderEmailAddress;
                end;
            }
            field(Subject; SubjectText)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Subject';
                ToolTip = 'Specifies the text that will display as the subject of the email.';

                trigger OnValidate()
                begin
                    TempEmailItem.Subject := SubjectText;
                end;
            }
            field(Body; BodyText)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Email Body Text';
                MultiLine = true;
                Visible = NOT IsBodyHidden;

                trigger OnValidate()
                begin
                    if BodyText = '' then
                        BodyText := ' '; // an empty body text triggers insertion of the html content.
                    TempEmailItem.SetBodyText(BodyText);
                    GetEmailBody(SendTo);
                end;
            }
            field(ShowEmailContentLbl; ShowEmailContentLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                var
                    FileManagement: Codeunit "File Management";
                    O365EmailPreview: Page "O365 Email Preview";
                    FileName: Text;
                begin
                    BodyText := TempEmailItem.GetBodyText;
                    if TempEmailItem."Body File Path" = '' then
                        FileName := FileManagement.CreateAndWriteToServerFile(BodyText, 'html')
                    else
                        FileName := TempEmailItem."Body File Path";

                    O365EmailPreview.LoadHTMLFile(FileName);
                    O365EmailPreview.RunModal;
                end;
            }
            group(Attachments)
            {
                Caption = 'Attachments';
            }
            field(AttachmentName; InvoiceOrEstimate)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Visible = HasInvoiceAttachment;

                trigger OnDrillDown()
                begin
                    if HasInvoiceAttachment then
                        Download(TempEmailItem."Attachment File Path", '', '', '', TempEmailItem."Attachment File Path");
                end;
            }
            field(NoOfAttachmentsValueTxt; NoOfAttachmentsValueTxt)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                var
                    SalesHeader: Record "Sales Header";
                    RecRef: RecordRef;
                begin
                    if not DocumentHeaderRecordVariant.IsRecord then
                        exit;
                    UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.EditAttachments(DocumentHeaderRecordVariant));
                    if not GetSalesHeader(DocumentHeaderRecordVariant, SalesHeader) then
                        exit;
                    RecRef.GetTable(DocumentHeaderRecordVariant);
                    if RecRef.Number = DATABASE::"Sales Header" then begin
                        SalesHeader := DocumentHeaderRecordVariant;
                        if SalesHeader.Find then
                            DocumentHeaderRecordVariant := SalesHeader;
                    end;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not DocumentHeaderRecordVariant.IsRecord then
            exit;
        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(DocumentHeaderRecordVariant));
    end;

    trigger OnOpenPage()
    var
        TypeHelper: Codeunit "Type Helper";
        MailManagement: Codeunit "Mail Management";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
        BodyInStream: InStream;
    begin
        // Set CC and BCC field
        TempEmailItem.FindFirst;
        UpdateCcBccText(TempEmailItem."Send CC", TempEmailItem."Send BCC");
        SendTo := CopyStr(TempEmailItem."Send to", 1, MaxStrLen(SendTo));
        SubjectText := TempEmailItem.Subject;
        if not MailManagement.TryGetSenderEmailAddress(FromAddress) then;
        TempEmailItem.CalcFields(Body);
        TempEmailItem.Body.CreateInStream(BodyInStream, O365SalesEmailManagement.GetBodyTextEncoding);
        BodyText := TypeHelper.ReadAsTextWithSeparator(BodyInStream, TypeHelper.LFSeparator);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        TempEmailItem.Modify(true);
        Rec := TempEmailItem;
        if CloseAction <> ACTION::OK then
            exit;
        if TempEmailItem."Send to" = '' then
            Error(MustSpecifyToEmailAddressErr);
        if FromAddress = '' then
            Error(MailNotConfiguredErr);
        if DocumentHeaderRecordVariant.IsRecord then
            if O365SalesAttachmentMgt.GetAttachments(DocumentHeaderRecordVariant, IncomingDocumentAttachment) then
                O365SalesAttachmentMgt.AssertIncomingDocumentSizeBelowMax(IncomingDocumentAttachment);
    end;

    var
        TempEmailItem: Record "Email Item" temporary;
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        DocumentHeaderRecordVariant: Variant;
        SendTo: Text[80];
        FromAddress: Text[250];
        CcAndBcc: Text;
        MustSpecifyToEmailAddressErr: Label 'Please enter a recipient email address.';
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.';
        ShowEmailContentLbl: Label 'Preview email';
        NoOfAttachmentsTxt: Label 'Other attachments (%1)', Comment = '%1=an integer number, starting at 0';
        NoOfAttachmentsValueTxt: Text;
        AddAttachmentTxt: Label 'Add attachment';
        SubjectText: Text[250];
        BodyText: Text;
        HasInvoiceAttachment: Boolean;
        IsBodyHidden: Boolean;
        InvoiceOrEstimate: Text[20];
        pdfEstimateTxt: Label 'PDF Estimate';
        pdfInvoiceTxt: Label 'PDF Invoice';

    [Scope('OnPrem')]
    procedure SetValues(NewDocumentHeaderRecordVariant: Variant; var NewTempEmailItem: Record "Email Item" temporary)
    var
        DummyVariant: Variant;
    begin
        TempEmailItem.Copy(NewTempEmailItem, true);
        DocumentHeaderRecordVariant := NewDocumentHeaderRecordVariant;
        HasInvoiceAttachment := Format(DocumentHeaderRecordVariant) <> Format(DummyVariant);
        GetEmailBody('');
    end;

    local procedure GetEmailBody(SendTo: Text[250])
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        ReportUsage: Option;
        CustomerNo: Code[20];
    begin
        if GetSalesInvoiceHeader(DocumentHeaderRecordVariant, SalesInvoiceHeader) then begin
            ReportUsage := ReportSelections.Usage::"S.Invoice";
            CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";
        end else
            if GetSalesHeader(DocumentHeaderRecordVariant, SalesHeader) then begin
                case SalesHeader."Document Type" of
                    SalesHeader."Document Type"::Quote:
                        ReportUsage := ReportSelections.Usage::"S.Quote";
                    SalesHeader."Document Type"::Invoice:
                        ReportUsage := ReportSelections.Usage::"S.Invoice Draft";
                    else
                        ReportUsage := ReportSelections.Usage::"S.Invoice Draft"; // default
                end;
                CustomerNo := SalesHeader."Sell-to Customer No.";
            end else
                exit;

        if ReportSelections.GetEmailBodyCustomText(TempEmailItem."Body File Path", ReportUsage, DocumentHeaderRecordVariant,
             CustomerNo, SendTo, TempEmailItem.GetBodyText)
        then
            TempEmailItem.Modify();
        Commit();
    end;

    local procedure GetSalesHeader(DocVariant: Variant; var SalesHeader: Record "Sales Header"): Boolean
    var
        RecRef: RecordRef;
    begin
        if not DocVariant.IsRecord then
            exit(false);
        RecRef.GetTable(DocVariant);
        if RecRef.Number <> DATABASE::"Sales Header" then
            exit(false);
        SalesHeader := DocVariant;
        exit(true);
    end;

    local procedure GetSalesInvoiceHeader(DocVariant: Variant; var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        RecRef: RecordRef;
    begin
        if not DocVariant.IsRecord then
            exit(false);
        RecRef.GetTable(DocVariant);
        if RecRef.Number <> DATABASE::"Sales Invoice Header" then
            exit(false);
        SalesInvoiceHeader := DocVariant;
        exit(true);
    end;

    local procedure UpdateCcBccText(SendCC: Text; SendBCC: Text)
    begin
        CcAndBcc := SendCC;
        if SendBCC <> '' then begin
            if CcAndBcc <> '' then
                CcAndBcc += '; ';
            CcAndBcc += SendBCC;
        end;
    end;

    local procedure UpdateNoOfAttachmentsLabel(NoOfAttachments: Integer)
    begin
        if NoOfAttachments = 0 then
            NoOfAttachmentsValueTxt := AddAttachmentTxt
        else
            NoOfAttachmentsValueTxt := StrSubstNo(NoOfAttachmentsTxt, NoOfAttachments);
    end;

    procedure HideBody()
    begin
        IsBodyHidden := true;
    end;

    procedure SetNameEstimate()
    begin
        InvoiceOrEstimate := pdfEstimateTxt;
    end;

    procedure SetNameInvoice()
    begin
        InvoiceOrEstimate := pdfInvoiceTxt;
    end;
}

