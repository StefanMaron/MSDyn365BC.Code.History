codeunit 5467 "PDF Document Management"
{

    trigger OnRun()
    begin
    end;

    var
        CannotFindDocumentErr: Label 'The document %1 cannot be found.', Comment = '%1 - Error Message';
        CannotOpenFileErr: Label 'Opening the file failed because of the following error: \%1.', Comment = '%1 - Error Message';
        UnpostedCreditMemoErr: Label 'You must post sales credit memo %1 before generating the PDF document.', Comment = '%1 - sales credit memo id';
        UnpostedPurchaseInvoiceErr: Label 'You must post purchase invoice %1 before generating the PDF document.', Comment = '%1 - sales credit memo id';
        CreditMemoTxt: Label 'Credit Memo';
        PurchaseInvoiceTxt: Label 'Purchase Invoice';

    [Scope('OnPrem')]
    procedure GeneratePdf(DocumentId: Guid; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        NativeReports: Codeunit "Native - Reports";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        File: File;
        InStream: InStream;
        OutStream: OutStream;
        Path: Text[250];
        Name: Text[250];
        ReportId: Integer;
        DocumentFound: Boolean;
    begin
        CompanyInformation.Get();
        SalesHeader.SetRange(Id, DocumentId);
        if SalesHeader.FindFirst then begin
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice:
                    begin
                        ReportId := NativeReports.DraftSalesInvoiceReportId;
                        ReportSelections.GetPdfReport(Path, ReportId, SalesHeader, SalesHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt, ReportId);
                    end;
                SalesHeader."Document Type"::Quote:
                    begin
                        ReportId := NativeReports.SalesQuoteReportId;
                        ReportSelections.GetPdfReport(Path, ReportId, SalesHeader, SalesHeader."Sell-to Customer No.");
                        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt, ReportId);
                    end;
                SalesHeader."Document Type"::"Credit Memo":
                    Error(UnpostedCreditMemoErr, DocumentId);
                else
                    Error(CannotFindDocumentErr, DocumentId);
            end;
            DocumentFound := true;
        end;

        if not DocumentFound then begin
            if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentId, SalesInvoiceHeader) then begin
                ReportId := NativeReports.PostedSalesInvoiceReportId;
                ReportSelections.GetPdfReport(Path, ReportId, SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
                DocumentMailing.GetAttachmentFileName(Name, SalesInvoiceHeader."No.", SalesInvoiceHeader.GetDocTypeTxt, ReportId);
                DocumentFound := true;
            end;
        end;

        if not DocumentFound then begin
            if GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderFromId(DocumentId, SalesCrMemoHeader) then begin
                ReportId := NativeReports.SalesCreditMemoReportId;
                ReportSelections.GetPdfReport(Path, ReportId, SalesCrMemoHeader, SalesCrMemoHeader."Sell-to Customer No.");
                DocumentMailing.GetAttachmentFileName(Name, SalesCrMemoHeader."No.", CreditMemoTxt, ReportId);
                DocumentFound := true;
            end;
        end;

        if not DocumentFound then begin
            PurchaseHeader.SetRange(Id, DocumentId);
            if PurchaseHeader.FindFirst and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice) then
                Error(UnpostedPurchaseInvoiceErr, DocumentId);
        end;

        if not DocumentFound then begin
            if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentId, PurchInvHeader) then begin
                ReportId := NativeReports.PurchaseInvoiceReportId;
                ReportSelections.GetPdfReport(Path, ReportId, PurchInvHeader, PurchInvHeader."Buy-from Vendor No.");
                DocumentMailing.GetAttachmentFileName(Name, PurchInvHeader."No.", PurchaseInvoiceTxt, ReportId);
                DocumentFound := true;
            end;
        end;

        if not DocumentFound then
            Error(CannotFindDocumentErr, DocumentId);

        if not File.Open(Path) then
            Error(CannotOpenFileErr, GetLastErrorText);

        TempAttachmentEntityBuffer.Init();
        TempAttachmentEntityBuffer.Id := DocumentId;
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := Name;
        TempAttachmentEntityBuffer.Type := TempAttachmentEntityBuffer.Type::PDF;
        TempAttachmentEntityBuffer.Content.CreateOutStream(OutStream);
        File.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        File.Close;
        if Erase(Path) then;
        TempAttachmentEntityBuffer.Insert(true);

        exit(true);
    end;
}

