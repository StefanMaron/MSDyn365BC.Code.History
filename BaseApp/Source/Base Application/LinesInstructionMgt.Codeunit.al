codeunit 1320 "Lines Instruction Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        LinesMissingQuantityErr: Label 'One or more document lines with a value in the No. field do not have a quantity specified.';
        LinesMissingQuantityConfirmQst: Label 'One or more document lines with a value in the No. field do not have a quantity specified. \Do you want to continue?';

    procedure SalesCheckAllLinesHaveQuantityAssigned(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange(Quantity, 0);
        OnAfterSetSalesLineFilters(SalesLine, SalesHeader);

        if not SalesLine.IsEmpty then
            if (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") then
                if Confirm(LinesMissingQuantityConfirmQst, false) then
                    exit
                else
                    Error(LinesMissingQuantityErr)
            else
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
        OnAfterSetPurchaseLineFilters(PurchaseLine, PurchaseHeader);

        if not PurchaseLine.IsEmpty then
            Error(LinesMissingQuantityErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

