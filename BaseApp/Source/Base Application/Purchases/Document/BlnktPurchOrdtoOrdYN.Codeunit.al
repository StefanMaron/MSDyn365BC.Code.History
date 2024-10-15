namespace Microsoft.Purchases.Document;

using System.Utilities;

codeunit 94 "Blnkt Purch Ord. to Ord. (Y/N)"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        SkipMessage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;

        Rec.TestField("Document Type", Rec."Document Type"::"Blanket Order");
        if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
            exit;

        BlanketPurchOrderToOrder.Run(Rec);
        BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchOrderHeader);

        OnAfterCreatePurchOrder(PurchOrderHeader, SkipMessage);
        if not SkipMessage then
            Message(Text001, PurchOrderHeader."No.", Rec."No.");
    end;

    var
        PurchOrderHeader: Record "Purchase Header";
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";

        Text000: Label 'Do you want to create an order from the blanket order?';
        Text001: Label 'Order %1 has been created from blanket order %2.';

    local procedure IsOnRunHandled(var PurchaseHeader: Record "Purchase Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(PurchaseHeader, IsHandled);
        exit(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; var SkipMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
}

