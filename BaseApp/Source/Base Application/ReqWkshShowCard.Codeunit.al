codeunit 335 "Req. Wksh.-Show Card"
{
    TableNo = "Requisition Line";

    trigger OnRun()
    begin
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
}

