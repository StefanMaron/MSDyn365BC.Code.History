codeunit 10766 "Sales Cr.Memo Header - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader := Rec;
        SalesCrMemoHeader.LockTable;
        SalesCrMemoHeader.Find;
        SalesCrMemoHeader."Special Scheme Code" := "Special Scheme Code";
        SalesCrMemoHeader."Cr. Memo Type" := "Cr. Memo Type";
        SalesCrMemoHeader."Correction Type" := "Correction Type";
        SalesCrMemoHeader.TestField("No.", "No.");
        SalesCrMemoHeader.Modify;
        Rec := SalesCrMemoHeader;
    end;
}

