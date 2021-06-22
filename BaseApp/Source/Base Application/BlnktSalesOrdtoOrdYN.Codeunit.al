codeunit 84 "Blnkt Sales Ord. to Ord. (Y/N)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SkipMessage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;

        TestField("Document Type", "Document Type"::"Blanket Order");
        if GuiAllowed then
            if not Confirm(CreateConfirmQst, false) then
                exit;

        BlanketSalesOrderToOrder.Run(Rec);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);

        OnAfterCreateSalesOrder(SalesOrderHeader, SkipMessage);
        if not SkipMessage then
            Message(OrderCreatedMsg, SalesOrderHeader."No.", "No.");
    end;

    var
        CreateConfirmQst: Label 'Do you want to create an order from the blanket order?';
        OrderCreatedMsg: Label 'Order %1 has been created from blanket order %2.', Comment = '%1 = Order No., %2 = Blanket Order No.';
        SalesOrderHeader: Record "Sales Header";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";

    local procedure IsOnRunHandled(var SalesHeader: Record "Sales Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(SalesHeader, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesOrder(var SalesHeader: Record "Sales Header"; var SkipMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

