codeunit 5853 "Invt. Doc.-Post (Yes/No)"
{
    TableNo = "Invt. Document Header";

    trigger OnRun()
    begin
        InvtDocHeader.Copy(Rec);
        Code();
        Rec := InvtDocHeader;
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        ConfirmPostQst: Label 'Do you want to post Inventory Document?';

    local procedure "Code"()
    var
        InvtDocPostReceipt: Codeunit "Invt. Doc.-Post Receipt";
        InvtDocPostShipment: Codeunit "Invt. Doc.-Post Shipment";
    begin
        if not Confirm(ConfirmPostQst, false) then
            exit;
        case InvtDocHeader."Document Type" of
            InvtDocHeader."Document Type"::Receipt:
                InvtDocPostReceipt.Run(InvtDocHeader);
            InvtDocHeader."Document Type"::Shipment:
                InvtDocPostShipment.Run(InvtDocHeader);
        end;
    end;
}

