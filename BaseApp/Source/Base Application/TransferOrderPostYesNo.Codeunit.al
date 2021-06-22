codeunit 5706 "TransferOrder-Post (Yes/No)"
{
    TableNo = "Transfer Header";

    trigger OnRun()
    begin
        TransHeader.Copy(Rec);
        Code;
        Rec := TransHeader;
    end;

    var
        Text000: Label '&Ship,&Receive';
        TransHeader: Record "Transfer Header";

    local procedure "Code"()
    var
        TransLine: Record "Transfer Line";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled);
        if IsHandled then
            exit;

        with TransHeader do begin
            TransLine.SetRange("Document No.", "No.");
            if TransLine.Find('-') then
                repeat
                    if (TransLine."Quantity Shipped" < TransLine.Quantity) and
                       (DefaultNumber = 0)
                    then
                        DefaultNumber := 1;
                    if (TransLine."Quantity Received" < TransLine.Quantity) and
                       (DefaultNumber = 0)
                    then
                        DefaultNumber := 2;
                until (TransLine.Next = 0) or (DefaultNumber > 0);
            if "Direct Transfer" then begin
                TransferPostShipment.Run(TransHeader);
                TransferPostReceipt.Run(TransHeader);
            end else begin
                if DefaultNumber = 0 then
                    DefaultNumber := 1;
                Selection := StrMenu(Text000, DefaultNumber);
                case Selection of
                    0:
                        exit;
                    Selection::Shipment:
                        TransferPostShipment.Run(TransHeader);
                    Selection::Receipt:
                        TransferPostReceipt.Run(TransHeader);
                end;
            end;
        end;

        OnAfterPost(TransHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}

