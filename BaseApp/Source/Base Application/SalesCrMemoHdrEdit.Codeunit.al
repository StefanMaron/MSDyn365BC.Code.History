codeunit 12189 "Sales Cr. Memo Hdr. - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader := Rec;
        SalesCrMemoHeader.LockTable();
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader."Fattura Document Type" := "Fattura Document Type";
        OnBeforeSalesCrMemoHeaderModify(SalesCrMemoHeader, Rec);
        SalesCrMemoHeader.TestField("No.", "No.");
        SalesCrMemoHeader.Modify();
        Rec := SalesCrMemoHeader;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoHeaderModify(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}

