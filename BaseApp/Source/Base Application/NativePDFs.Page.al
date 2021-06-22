page 2821 "Native - PDFs"
{
    Caption = 'nativeInvoicingPDFs', Locked = true;
    Editable = false;
    ODataKeyFields = "Document Id";
    PageType = List;
    SourceTable = "Attachment Entity Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(documentId; "Document Id")
                {
                    ApplicationArea = All;
                    Caption = 'documentId', Locked = true;
                }
                field(fileName; "File Name")
                {
                    ApplicationArea = All;
                    Caption = 'fileName', Locked = true;
                }
                field(content; Content)
                {
                    ApplicationArea = All;
                    Caption = 'content', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        PDFDocumentManagement: Codeunit "PDF Document Management";
        DocumentId: Guid;
        DocumentIdFilter: Text;
        FilterView: Text;
    begin
        if not PdfGenerated then begin
            FilterView := GetView;
            DocumentIdFilter := GetFilter("Document Id");
            if DocumentIdFilter = '' then
                DocumentIdFilter := GetFilter(Id);
            SetView(FilterView);
            DocumentId := GetDocumentId(DocumentIdFilter);
            if IsNullGuid(DocumentId) then
                exit(false);
            PdfGenerated := PDFDocumentManagement.GeneratePdf(DocumentId, Rec);
        end;
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
    end;

    var
        DocumentIDNotSpecifiedForAttachmentsErr: Label 'You must specify a document ID to get the PDF.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        PdfGenerated: Boolean;

    local procedure GetDocumentId(DocumentIdFilter: Text): Guid
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecordRef: RecordRef;
        DocumentIdFieldRef: FieldRef;
        DocumentId: Guid;
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedForAttachmentsErr);

        SalesHeader.SetFilter(Id, DocumentIdFilter);
        if SalesHeader.FindFirst then
            DocumentRecordRef.GetTable(SalesHeader)
        else begin
            SalesInvoiceHeader.SetFilter(Id, DocumentIdFilter);
            if SalesInvoiceHeader.FindFirst then
                DocumentRecordRef.GetTable(SalesInvoiceHeader)
            else
                Error(DocumentDoesNotExistErr);
        end;

        DataTypeManagement.FindFieldByName(DocumentRecordRef, DocumentIdFieldRef, SalesHeader.FieldName(Id));
        Evaluate(DocumentId, Format(DocumentIdFieldRef.Value));

        exit(DocumentId);
    end;
}

