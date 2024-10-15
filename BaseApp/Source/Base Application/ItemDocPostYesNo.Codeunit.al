codeunit 12456 "Item Doc.-Post (Yes/No)"
{
    TableNo = "Item Document Header";

    trigger OnRun()
    begin
        ItemDocHeader.Copy(Rec);
        Code;
        Rec := ItemDocHeader;
    end;

    var
        ItemDocHeader: Record "Item Document Header";
        Text001: Label 'Do you want to post Item Document?';

    local procedure "Code"()
    var
        ItemDocPostReceipt: Codeunit "Item Doc.-Post Receipt";
        ItemDocPostShipment: Codeunit "Item Doc.-Post Shipment";
    begin
        with ItemDocHeader do begin
            if not Confirm(Text001, false) then
                exit;
            case "Document Type" of
                "Document Type"::Receipt:
                    ItemDocPostReceipt.Run(ItemDocHeader);
                "Document Type"::Shipment:
                    ItemDocPostShipment.Run(ItemDocHeader);
            end;
        end;
    end;
}

