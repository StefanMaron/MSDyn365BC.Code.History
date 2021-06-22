codeunit 5922 "Serv-Quote to Order (Yes/No)"
{
    TableNo = "Service Header";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        HideMessage: Boolean;
    begin
        Rec.TestField("Document Type", Rec."Document Type"::Quote);
        Rec.TestField("Customer No.");
        Rec.TestField("Bill-to Customer No.");
        if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
            exit;

        ServQuoteToOrder.Run(Rec);

        OnBeforeShowMessage(Rec, ServQuoteToOrder.ReturnOrderNo(), HideMessage);
        if not HideMessage then
            Message(Text001, Rec."No.", ServQuoteToOrder.ReturnOrderNo());
    end;

    var
        Text000: Label 'Do you want to convert the quote to an order?';
        Text001: Label 'Service quote %1 has been converted to service order no. %2.';
        ServQuoteToOrder: Codeunit "Service-Quote to Order";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMessage(var Rec: Record "Service Header"; OrderNo: Code[20]; var HideMessage: Boolean)
    begin
    end;
}

