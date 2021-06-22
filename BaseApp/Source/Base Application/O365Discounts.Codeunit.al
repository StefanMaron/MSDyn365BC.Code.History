codeunit 2155 "O365 Discounts"
{

    trigger OnRun()
    begin
    end;

    procedure ApplyInvoiceDiscountPercentage(var SalesHeader: Record "Sales Header"; InvoiceDiscountPercentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        SalesHeader."Invoice Discount Calculation" := SalesHeader."Invoice Discount Calculation"::"%";
        SalesHeader."Invoice Discount Value" := InvoiceDiscountPercentage;

        if not CustInvoiceDisc.Get(SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", 0) then begin
            SalesHeader."Invoice Disc. Code" := SalesHeader."No.";
            if not CustInvoiceDisc.Get(SalesHeader."Invoice Disc. Code", SalesHeader."Currency Code", 0) then begin
                CustInvoiceDisc.Code := SalesHeader."No.";
                CustInvoiceDisc."Currency Code" := SalesHeader."Currency Code";
                CustInvoiceDisc.Insert(true);
            end;
        end;
        CustInvoiceDisc."Discount %" := InvoiceDiscountPercentage;
        CustInvoiceDisc.Modify(true);
        SalesHeader.Modify(true);
        SalesHeader.CalcInvDiscForHeader;
    end;
}

