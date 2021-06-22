codeunit 1320 "Lines Instruction Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        LinesMissingQuantityErr: Label 'One or more document lines with a value in the Item No. field do not have a quantity specified.';

    procedure SalesCheckAllLinesHaveQuantityAssigned(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange(Quantity, 0);

        if not SalesLine.IsEmpty then
            Error(LinesMissingQuantityErr);
    end;

    procedure PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetRange(Quantity, 0);

        if not PurchaseLine.IsEmpty then
            Error(LinesMissingQuantityErr);
    end;
}

