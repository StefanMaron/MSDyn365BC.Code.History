codeunit 2822 "Native - Reports"
{

    trigger OnRun()
    begin
    end;

    procedure PostedSalesInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Invoice");
    end;

    procedure DraftSalesInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Invoice Draft");
    end;

    procedure SalesQuoteReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Quote");
    end;

    procedure SalesCreditMemoReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Cr.Memo");
    end;

    procedure PurchaseInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"P.Invoice");
    end;
}

