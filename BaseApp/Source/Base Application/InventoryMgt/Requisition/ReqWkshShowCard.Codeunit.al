codeunit 335 "Req. Wksh.-Show Card"
{
    TableNo = "Requisition Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, Item, GLAcc, IsHandled);
        if IsHandled then
            exit;

        case Type of
            Type::"G/L Account":
                begin
                    GLAcc."No." := "No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            Type::Item:
                begin
                    Item."No." := "No.";
                    PAGE.Run(PAGE::"Item Card", Item);
                end;
        end;
    end;

    var
        GLAcc: Record "G/L Account";
        Item: Record Item;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RequisitionLine: Record "Requisition Line"; var Item: Record Item; var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;
}

