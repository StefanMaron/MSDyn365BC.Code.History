codeunit 28074 "Sales Tax Cr.Memo-Printed"
{
    Permissions = TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Sales Tax Cr.Memo Header" = rimd;
    TableNo = "Sales Tax Cr.Memo Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;

        SalesTaxCrMemoLine.SetRange("Document No.", "No.");
        if SalesTaxCrMemoLine.FindFirst then begin
            SalesCrMemoHeader.SetRange("No.", SalesTaxCrMemoLine."External Document No.");
            if SalesCrMemoHeader.FindFirst then begin
                SalesCrMemoHeader."Printed Tax Document" := true;
                SalesCrMemoHeader.Modify();
            end;
        end;

        Commit();
    end;

    var
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
}

