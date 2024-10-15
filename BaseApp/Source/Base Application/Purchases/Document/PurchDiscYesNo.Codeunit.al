namespace Microsoft.Purchases.Document;

using System.Utilities;

codeunit 71 "Purch.-Disc. (Yes/No)"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if ConfirmManagement.GetResponseOrDefault(Text000, true) then
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", Rec);
    end;

    var
        Text000: Label 'Do you want to calculate the invoice discount?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}

