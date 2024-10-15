#if not CLEAN21
codeunit 2151 "O365 Sales Email Management"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        TestInvoiceTxt: Label 'Test Invoice';

    [Scope('OnPrem')]
    procedure ShowEmailDialog(DocumentNo: Code[20]): Boolean
    var
        EmailParameter: Record "Email Parameter";
        TempEmailItem: Record "Email Item" temporary;
        ReportSelections: Record "Report Selections";
        TempReportSelections: Record "Report Selections" temporary;
        DocumentMailing: Codeunit "Document-Mailing";
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        MailManagement: Codeunit "Mail Management";
        Attachment: Codeunit "Temp Blob";
        O365SalesEmailDialog: Page "O365 Sales Email Dialog";
        AttachmentName: Text[250];
        InStream: InStream;
        DocumentRecordVariant: Variant;
        CustomerNo: Code[20];
        EmailAddress: Text[250];
        EmailSubject: Text[250];
        EmailBody: Text;
        ReportUsage: Enum "Report Selection Usage";
        HasBeenSent: Boolean;
        IsTestInvoice: Boolean;
        DocumentType: Enum "Sales Document Type";
        DocumentName: Text[250];
        BodyText: Text;
    begin
        if not InitializeDocumentSpecificVariables(DocumentRecordVariant, ReportUsage, CustomerNo, DocumentType, DocumentNo, IsTestInvoice) then
            exit;

        DocumentName := GetDocumentName(IsTestInvoice);

        if IsTestInvoice then begin
            EmailSubject := DocumentMailing.GetTestInvoiceEmailSubject();
            EmailBody := DocumentMailing.GetTestInvoiceEmailBody(CustomerNo);

            if not ReportSelections.GetEmailBodyTextForCust(
                 TempEmailItem."Body File Path", ReportUsage, DocumentRecordVariant, CustomerNo, EmailAddress, EmailBody)
            then
                ;
            EmailAddress := MailManagement.GetSenderEmailAddress(Enum::"Email Scenario"::Default);
            EmailParameter.SaveParameterValueWithReportUsage(
              DocumentNo, ReportUsage.AsInteger(), EmailParameter."Parameter Type"::Address.AsInteger(), EmailAddress);
        end else begin
            EmailSubject := DocumentMailing.GetEmailSubject(DocumentNo, DocumentName, ReportUsage.AsInteger());
            EmailBody := DocumentMailing.GetEmailBody(DocumentNo, ReportUsage.AsInteger(), CustomerNo);
            if not ReportSelections.GetEmailBodyForCust(TempEmailItem."Body File Path", ReportUsage, DocumentRecordVariant, CustomerNo, EmailAddress) then;
        end;

        if ReportSelections.FindEmailAttachmentUsageForCust(ReportUsage, CustomerNo, TempReportSelections) then begin
            // Create attachment
            TempReportSelections.GetPdfReportForCust(
              Attachment, ReportUsage,
              DocumentRecordVariant, CustomerNo);

            DocumentMailing.GetAttachmentFileName(
              AttachmentName, DocumentNo, DocumentName, ReportUsage.AsInteger());
            Attachment.CreateInStream(InStream);
            TempEmailItem.AddAttachment(InStream, AttachmentName);
        end;

        TempEmailItem.Subject := EmailSubject;
        TempEmailItem.SetBodyText(EmailBody);
        TempEmailItem."Send to" := EmailAddress;
        TempEmailItem.AddCcBcc();
        TempEmailItem.AttachIncomingDocuments(DocumentNo);
        TempEmailItem.Insert(true);
        Commit();

        O365SalesEmailDialog.SetValues(DocumentRecordVariant, TempEmailItem);
        if DocumentType = DocumentType::Quote then
            O365SalesEmailDialog.SetNameEstimate()
        else
            O365SalesEmailDialog.SetNameInvoice();
        HasBeenSent := O365SalesEmailDialog.RunModal() = ACTION::OK;

        O365SalesEmailDialog.GetRecord(TempEmailItem);
        if EmailAddress <> TempEmailItem."Send to" then
            O365HTMLTemplMgt.ReplaceBodyFileSendTo(
              TempEmailItem."Body File Path", EmailAddress, TempEmailItem."Send to");
        SaveEmailParametersIfChanged(
          DocumentNo, ReportUsage.AsInteger(), EmailAddress, TempEmailItem."Send to", TempEmailItem.Subject);

        BodyText := TempEmailItem.GetBodyText();
        if not HasBeenSent then
            BodyText := DocumentMailing.ReplaceCustomerNameWithPlaceholder(CustomerNo, BodyText);

        EmailParameter.SaveParameterValueWithReportUsage(
            DocumentNo, ReportUsage.AsInteger(), EmailParameter."Parameter Type"::Body.AsInteger(), BodyText);

        exit(HasBeenSent);
    end;

    local procedure InitializeDocumentSpecificVariables(var DocumentRecordVariant: Variant; var ReportUsage: Enum "Report Selection Usage"; var CustomerNo: Code[20]; var DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; var IsTestInvoice: Boolean): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
    begin
        IsTestInvoice := false;

        if SalesInvoiceHeader.Get(DocumentNo) then begin
            SalesInvoiceHeader.SetRecFilter();
            DocumentRecordVariant := SalesInvoiceHeader;
            CustomerNo := SalesInvoiceHeader."Bill-to Customer No.";
            ReportUsage := ReportSelections.Usage::"S.Invoice";
            DocumentType := DocumentType::Invoice;
            exit(true);
        end;

        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", DocumentNo);
        if SalesHeader.FindFirst() then begin
            SalesHeader.SetRecFilter();
            DocumentRecordVariant := SalesHeader;
            CustomerNo := SalesHeader."Bill-to Customer No.";

            if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
                ReportUsage := ReportSelections.Usage::"S.Invoice Draft";
                DocumentType := DocumentType::Invoice;
            end else begin
                ReportUsage := ReportSelections.Usage::"S.Quote";
                DocumentType := DocumentType::Quote;
            end;

            if SalesHeader.IsTest then
                IsTestInvoice := true;

            exit(true);
        end;

        exit(false);
    end;

    procedure SaveEmailParametersIfChanged(DocumentNo: Code[20]; ReportUsage: Integer; OldEmailAddress: Text[250]; NewEmailAddress: Text[250]; NewEmailSubject: Text[250])
    var
        EmailParameter: Record "Email Parameter";
    begin
        if OldEmailAddress <> NewEmailAddress then
            EmailParameter.SaveParameterValueWithReportUsage(
              DocumentNo, ReportUsage, EmailParameter."Parameter Type"::Address.AsInteger(), NewEmailAddress);
        EmailParameter.SaveParameterValueWithReportUsage(
          DocumentNo, ReportUsage, EmailParameter."Parameter Type"::Subject.AsInteger(), NewEmailSubject);
    end;

    local procedure GetDocumentName(IsTestInvoice: Boolean): Text[250]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsTestInvoice then
            exit(TestInvoiceTxt);
        exit(SalesInvoiceHeader.GetDefaultEmailDocumentName());
    end;

    procedure GetBodyTextEncoding(): TextEncoding
    begin
        exit(TEXTENCODING::UTF8);
    end;
}
#endif

