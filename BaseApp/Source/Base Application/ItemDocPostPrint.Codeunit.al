codeunit 12457 "Item Doc.-Post + Print"
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
        ItemRcptHeader: Record "Item Receipt Header";
        Text001: Label 'Do you want to post the %1?';
        ItemShptHeader: Record "Item Shipment Header";

    local procedure "Code"()
    var
        ItemDocPostReceipt: Codeunit "Item Doc.-Post Receipt";
        ItemDocPostShipment: Codeunit "Item Doc.-Post Shipment";
    begin
        with ItemDocHeader do begin
            if not Confirm(Text001, false, "Document Type") then
                exit;

            case "Document Type" of
                "Document Type"::Receipt:
                    begin
                        ItemDocPostReceipt.Run(ItemDocHeader);
                        ItemRcptHeader."No." := "Posting No.";
                        ItemRcptHeader.SetRecFilter;
                        ItemRcptHeader.PrintRecords(false);
                    end;
                "Document Type"::Shipment:
                    begin
                        ItemDocPostShipment.Run(ItemDocHeader);
                        ItemShptHeader."No." := "Posting No.";
                        ItemShptHeader.SetRecFilter;
                        ItemShptHeader.PrintRecords(false);
                    end;
            end;
        end;
    end;
}

