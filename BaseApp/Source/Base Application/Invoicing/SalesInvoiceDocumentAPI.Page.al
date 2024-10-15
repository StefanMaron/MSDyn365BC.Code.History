#if not CLEAN21
page 2200 "Sales Invoice Document API"
{
    Caption = 'Sales Invoice Document API';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "O365 Sales Invoice Document";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(InvoiceId; Rec.InvoiceId)
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field(Base64; Rec.Base64)
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field(Binary; Rec.Binary)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
        if not Evaluate(Rec.InvoiceId, Rec.GetFilter(InvoiceId)) then
            exit(false);

        if IsNullGuid(Rec.InvoiceId) then
            exit(false);

        if SalesInvoiceHeader.GetBySystemId(Rec.InvoiceId) then begin
            GetDocumentFromPostedInvoice(SalesInvoiceHeader);
            exit(true);
        end;

        if SalesHeader.GetBySystemId(Rec.InvoiceId) then begin
            GetDocumentFromDraftInvoice(SalesHeader);
            exit(true);
        end;

        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SelectLatestVersion();
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
        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.GetPdfReportForCust(
          DocumentPath, ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");

        Rec.Base64.CreateOutStream(OutStr);
        FileManagement.IsAllowedPath(DocumentPath, false);
        OutStr.WriteText(Convert.ToBase64String(FileObj.ReadAllBytes(DocumentPath)));

        Rec.Binary.Import(DocumentPath);

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
        SalesHeader.SetRecFilter();
        ReportSelections.GetPdfReportForCust(
          DocumentPath, ReportSelections.Usage::"S.Invoice Draft", SalesHeader, SalesHeader."Sell-to Customer No.");

        Rec.Base64.CreateOutStream(OutStr);
        FileManagement.IsAllowedPath(DocumentPath, false);
        OutStr.WriteText(Convert.ToBase64String(FileObj.ReadAllBytes(DocumentPath)));

        Rec.Binary.Import(DocumentPath);

        if FILE.Erase(DocumentPath) then;
    end;
}
#endif

