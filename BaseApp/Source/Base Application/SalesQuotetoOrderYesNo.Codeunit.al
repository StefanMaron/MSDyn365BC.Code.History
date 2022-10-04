codeunit 83 "Sales-Quote to Order (Yes/No)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        if IsOnRunHandled(Rec) then
            exit;

        TestField("Document Type", "Document Type"::Quote);
        if not ConfirmConvertToOrder(Rec) then
            exit;

        if CheckCustomerCreated(true) then
            Get("Document Type"::Quote, "No.")
        else
            exit;

        SalesQuoteToOrder.Run(Rec);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader2);
        Commit();

        OnAfterSalesQuoteToOrderRun(SalesHeader2, Rec);

        ShowCreatedOrder();
    end;

    var
        SalesHeader2: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";

        ConfirmConvertToOrderQst: Label 'Do you want to convert the quote to an order?';
        OpenNewInvoiceQst: Label 'The quote has been converted to order %1. Do you want to open the new order?', Comment = '%1 = No. of the new sales order document.';

    local procedure IsOnRunHandled(var SalesHeader: Record "Sales Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(SalesHeader, IsHandled);
        exit(IsHandled);
    end;

    local procedure ShowCreatedOrder()
    var
        OfficeMgt: Codeunit "Office Management";
        SalesOrder: Page "Sales Order";
        OpenPage: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCreatedOrder(SalesHeader2, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() then
            if OfficeMgt.AttachAvailable() then
                OpenPage := true
            else
                OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst, SalesHeader2."No."), true);
        if OpenPage then begin
            Clear(SalesOrder);
            CheckNotifications(SalesOrder);
            SalesOrder.SetRecord(SalesHeader2);
            SalesOrder.Run();
        end;
    end;

    local procedure ConfirmConvertToOrder(SalesHeader: Record "Sales Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmConvertToOrder(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GuiAllowed then
            if not Confirm(ConfirmConvertToOrderQst, false) then
                exit(false);

        exit(true);
    end;

    local procedure CheckNotifications(var SalesOrder: Page "Sales Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNotifications(SalesOrder, IsHandled);
        if IsHandled then
            exit;

        SalesOrder.CheckNotificationsOnce();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteToOrderRun(var SalesHeader2: Record "Sales Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCreatedOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNotifications(var SalesOrder: Page "Sales Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmConvertToOrder(SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

