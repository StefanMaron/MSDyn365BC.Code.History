codeunit 28072 "Sales Tax Inv.-Printed"
{
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Tax Invoice Header" = rimd;
    TableNo = "Sales Tax Invoice Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;

        SalesTaxInvLine.SetRange("Document No.", "No.");
        if SalesTaxInvLine.FindFirst then begin
            SalesInvHeader.SetRange("No.", SalesTaxInvLine."External Document No.");
            if SalesInvHeader.FindFirst then begin
                SalesInvHeader."Printed Tax Document" := true;
                SalesInvHeader.Modify();
            end;
        end;

        Commit();
    end;

    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesTaxInvLine: Record "Sales Tax Invoice Line";
}

