codeunit 83 "Sales-Quote to Order (Yes/No)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        OfficeMgt: Codeunit "Office Management";
        SalesOrder: Page "Sales Order";
        OpenPage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;

        TestField("Document Type", "Document Type"::Quote);
        if GuiAllowed then
            if not Confirm(ConfirmConvertToOrderQst, false) then
                exit;

        if CheckCustomerCreated(true) then
            Get("Document Type"::Quote, "No.")
        else
            exit;

        SalesQuoteToOrder.Run(Rec);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader2);
        Commit();

        OnAfterSalesQuoteToOrderRun(SalesHeader2);

        if GuiAllowed then
            if OfficeMgt.AttachAvailable then
                OpenPage := true
            else
                OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst, SalesHeader2."No."), true);
        if OpenPage then begin
            Clear(SalesOrder);
            SalesOrder.CheckNotificationsOnce;
            SalesOrder.SetRecord(SalesHeader2);
            SalesOrder.Run;
        end;
    end;

    var
        ConfirmConvertToOrderQst: Label 'Do you want to convert the quote to an order?';
        OpenNewInvoiceQst: Label 'The quote has been converted to order %1. Do you want to open the new order?', Comment = '%1 = No. of the new sales order document.';
        SalesHeader2: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";

    local procedure IsOnRunHandled(var SalesHeader: Record "Sales Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(SalesHeader, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteToOrderRun(var SalesHeader2: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

