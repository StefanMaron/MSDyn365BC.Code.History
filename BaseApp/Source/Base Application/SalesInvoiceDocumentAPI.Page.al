page 2200 "Sales Invoice Document API"
{
    Caption = 'Sales Invoice Document API';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "O365 Sales Invoice Document";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(InvoiceId; InvoiceId)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field(Base64; Base64)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field(Binary; Binary)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not Evaluate(InvoiceId, GetFilter(InvoiceId)) then
            exit(false);

        if IsNullGuid(InvoiceId) then
            exit(false);

        SalesInvoiceHeader.SetRange(Id, InvoiceId);
        if SalesInvoiceHeader.FindFirst then begin
            GetDocumentFromPostedInvoice(SalesInvoiceHeader);
            exit(true);
        end;

        SalesHeader.SetRange(Id, InvoiceId);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        if SalesHeader.FindFirst then begin
            GetDocumentFromDraftInvoice(SalesHeader);
            exit(true);
        end;

        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SelectLatestVersion;
    end;

    local procedure GetDocumentFromPostedInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ReportSelections: Record "Report Selections";
        FileManagement: Codeunit "File Management";
        Convert: DotNet Convert;
        FileObj: DotNet File;
        OutStr: OutStream;
        DocumentPath: Text[250];
    begin
        SalesInvoiceHeader.SetRecFilter;
        ReportSelections.GetPdfReport(
          DocumentPath, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");

        Base64.CreateOutStream(OutStr);
        FileManagement.IsAllowedPath(DocumentPath, false);
        OutStr.WriteText(Convert.ToBase64String(FileObj.ReadAllBytes(DocumentPath)));

        Binary.Import(DocumentPath);

        if FILE.Erase(DocumentPath) then;
    end;

    local procedure GetDocumentFromDraftInvoice(SalesHeader: Record "Sales Header")
    var
        ReportSelections: Record "Report Selections";
        FileManagement: Codeunit "File Management";
        Convert: DotNet Convert;
        FileObj: DotNet File;
        OutStr: OutStream;
        DocumentPath: Text[250];
    begin
        SalesHeader.SetRecFilter;
        ReportSelections.GetPdfReport(
          DocumentPath, ReportSelections.Usage::"S.Invoice Draft", SalesHeader, SalesHeader."Sell-to Customer No.");

        Base64.CreateOutStream(OutStr);
        FileManagement.IsAllowedPath(DocumentPath, false);
        OutStr.WriteText(Convert.ToBase64String(FileObj.ReadAllBytes(DocumentPath)));

        Binary.Import(DocumentPath);

        if FILE.Erase(DocumentPath) then;
    end;
}

