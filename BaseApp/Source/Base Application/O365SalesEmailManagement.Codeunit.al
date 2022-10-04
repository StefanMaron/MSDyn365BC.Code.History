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
#if not CLEAN20        
        CannotOpenFileErr: Label 'Opening the file failed because of the following error: \%1.', Comment = '%1 - Error Message';
        CannotFindDocumentErr: Label 'The Document %1 cannot be found.', Comment = '%1 - Error Message';
        MetaViewportStartTxt: Label '<meta name="viewport"', Locked = true;
        MetaViewportFullTxt: Label '<meta name="viewport" content="initial-scale=1.0" />', Locked = true;
        HtmlTagTxt: Label 'html', Locked = true;
        HeadTagTxt: Label 'head', Locked = true;
        StartTagTxt: Label '<', Locked = true;
        EndTagTxt: Label '>', Locked = true;
#endif
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

#if not CLEAN20
    [Obsolete('These objects will be removed', '20.0')]
    [Scope('OnPrem')]
    procedure NativeAPISaveEmailBodyText(DocumentId: Guid)
    var
        EmailParameter: Record "Email Parameter";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        EmailAddress: Text[250];
        EmailSubject: Text[250];
        EmailBody: Text;
        ReportUsage: Integer;
        BodyText: Text;
    begin
        NativeAPIGetEmailParametersFromId(
            DocumentId, DocumentNo, CustomerNo, EmailAddress, EmailSubject, EmailBody, ReportUsage, BodyText);
        EmailParameter.SaveParameterValueWithReportUsage(
            DocumentNo, ReportUsage, EmailParameter."Parameter Type"::Body.AsInteger(), BodyText);
    end;

    [Obsolete('These objects will be removed', '20.0')]
    [Scope('OnPrem')]
    procedure NativeAPIGetEmailParametersFromId(DocumentId: Guid; var DocumentNo: Code[20]; var CustomerNo: Code[20]; var EmailAddress: Text[250]; var EmailSubject: Text[250]; var EmailBody: Text; var ReportUsage: Integer; var BodyText: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        NativeReports: Codeunit "Native - Reports";
        O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
        RecordVariant: Variant;
        FilePath: Text[250];
        DocumentName: Text[250];
        Cancelled: Boolean;
    begin
        if SalesHeader.GetBySystemId(DocumentId) then
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice:
                    begin
                        RecordVariant := SalesHeader;
                        DocumentName := SalesHeader.GetDocTypeTxt();
                        DocumentNo := SalesHeader."No.";
                        CustomerNo := SalesHeader."Sell-to Customer No.";
                        ReportUsage := NativeReports.DraftSalesInvoiceReportId();
                    end;
                SalesHeader."Document Type"::Quote:
                    begin
                        RecordVariant := SalesHeader;
                        DocumentName := SalesHeader.GetDocTypeTxt();
                        DocumentNo := SalesHeader."No.";
                        CustomerNo := SalesHeader."Sell-to Customer No.";
                        ReportUsage := NativeReports.SalesQuoteReportId();
                    end;
                else
                    Error(CannotFindDocumentErr, DocumentId);
            end
        else begin
            SalesInvoiceHeader.GetBySystemId(DocumentId);
            if not SalesInvoiceHeader.FindFirst() then
                Error(CannotFindDocumentErr, DocumentId);
            Cancelled := IsSalesInvoiceHeaderCancelled(SalesInvoiceHeader);
            if not Cancelled then begin
                DocumentName := SalesInvoiceHeader.GetDefaultEmailDocumentName();
                RecordVariant := SalesInvoiceHeader;
                DocumentNo := SalesInvoiceHeader."No.";
                CustomerNo := SalesInvoiceHeader."Sell-to Customer No.";
                ReportUsage := NativeReports.PostedSalesInvoiceReportId();
            end;
        end;

        BodyText := DocumentMailing.GetEmailBody(DocumentNo, ReportUsage, CustomerNo);

        if not Cancelled then begin
            if ReportSelections.GetEmailBodyTextForCust(
                FilePath, "Report Selection Usage".FromInteger(ReportUsage), RecordVariant, CustomerNo, EmailAddress, BodyText)
            then
                EmailBody := NativeAPIGetEmailBody(FilePath);

            EmailSubject := DocumentMailing.GetEmailSubject(DocumentNo, DocumentName, ReportUsage);
        end else begin
            EmailAddress := O365SalesCancelInvoice.GetEmailAddress(SalesInvoiceHeader);
            EmailSubject := O365SalesCancelInvoice.GetEmailSubject(SalesInvoiceHeader);
        end;
    end;

    local procedure IsSalesInvoiceHeaderCancelled(var SalesInvoiceHeader: Record "Sales Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeIsSalesInvoiceHeaderCancelled(SalesInvoiceHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SalesInvoiceHeader.CalcFields(Cancelled);
        Result := SalesInvoiceHeader.Cancelled;
    end;

    local procedure NativeAPIGetEmailBody(FilePath: Text[250]): Text
    var
        File: File;
        InStream: InStream;
        EmailBody: Text;
        Buffer: Text;
    begin
        if not File.Open(FilePath, GetBodyTextEncoding()) then
            Error(CannotOpenFileErr, GetLastErrorText);
        File.CreateInStream(InStream);
        while not InStream.EOS() do begin
            InStream.Read(Buffer);
            EmailBody += Buffer;
        end;
        File.Close();
        if Erase(FilePath) then;

        NativeAPIInjectMetaViewport(EmailBody);

        exit(EmailBody);
    end;

    local procedure NativeAPIInjectMetaViewport(var EmailBody: Text)
    var
        BodyStart: Text[1000];
        PosHtml: Integer;
        PosHead: Integer;
        PosMeta: Integer;
        PosTagBeforeMeta: Integer;
        BodyStartLength: Integer;
        MaxBodyStartLength: Integer;
    begin
        // Used for Native App HTML preview
        BodyStartLength := StrLen(EmailBody);
        MaxBodyStartLength := MaxStrLen(BodyStart);
        if BodyStartLength > MaxBodyStartLength then
            BodyStartLength := MaxBodyStartLength;
        BodyStart := LowerCase(CopyStr(EmailBody, 1, BodyStartLength));
        if StrPos(BodyStart, MetaViewportStartTxt) > 0 then
            exit;

        PosHtml := StrPos(BodyStart, StartTagTxt + HtmlTagTxt);
        if PosHtml = 0 then
            exit;

        PosHead := StrPos(BodyStart, StartTagTxt + HeadTagTxt);
        if PosHead > 0 then
            PosTagBeforeMeta := PosHead
        else
            PosTagBeforeMeta := PosHtml;

        PosMeta := PosTagBeforeMeta + StrPos(CopyStr(BodyStart, PosTagBeforeMeta + 1), EndTagTxt);
        if PosMeta > 0 then
            EmailBody := CopyStr(EmailBody, PosHtml, PosMeta - PosHtml + 1) + MetaViewportFullTxt + CopyStr(EmailBody, PosMeta + 1);
    end;
#endif

    procedure GetBodyTextEncoding(): TextEncoding
    begin
        exit(TEXTENCODING::UTF8);
    end;

#if not CLEAN20
    [Obsolete('These objects will be removed', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSalesInvoiceHeaderCancelled(var SalesInvoiceHeader: Record "Sales Invoice Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif
}
#endif

