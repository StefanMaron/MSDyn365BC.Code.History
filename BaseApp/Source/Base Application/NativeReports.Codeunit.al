#if not CLEAN20
codeunit 2822 "Native - Reports"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    procedure PostedSalesInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Invoice".AsInteger());
    end;

    procedure DraftSalesInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Invoice Draft".AsInteger());
    end;

    procedure SalesQuoteReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Quote".AsInteger());
    end;

    procedure SalesCreditMemoReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"S.Cr.Memo".AsInteger());
    end;

    procedure PurchaseInvoiceReportId(): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        exit(TempReportSelections.Usage::"P.Invoice".AsInteger());
    end;
}
#endif
