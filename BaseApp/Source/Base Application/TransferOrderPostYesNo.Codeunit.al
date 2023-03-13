codeunit 5706 "TransferOrder-Post (Yes/No)"
{
    TableNo = "Transfer Header";

    trigger OnRun()
    begin
        TransHeader.Copy(Rec);
        Code();
        Rec := TransHeader;
    end;

    var
        TransHeader: Record "Transfer Header";

        Text000: Label '&Ship,&Receive';

    local procedure "Code"()
    var
        InvtSetup: Record "Inventory Setup";
        TransLine: Record "Transfer Line";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled, TransferPostShipment, TransferPostReceipt);
        if IsHandled then
            exit;

        InvtSetup.Get();

        DefaultNumber := 0;
        TransLine.SetRange("Document No.", TransHeader."No.");
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
            until (TransLine.Next() = 0) or (DefaultNumber > 0);

        IsHandled := false;
        OnCodeOnBeforePostTransferOrder(TransHeader, DefaultNumber, Selection, IsHandled);
        if not IsHandled then
            if TransHeader."Direct Transfer" then
                case InvtSetup."Direct Transfer Posting" of
                    InvtSetup."Direct Transfer Posting"::"Receipt and Shipment":
                        begin
                            TransferPostShipment.Run(TransHeader);
                            TransferPostReceipt.Run(TransHeader);
                        end;
                    InvtSetup."Direct Transfer Posting"::"Direct Transfer":
                        TransferOrderPostTransfer.Run(TransHeader);
                end
            else begin
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

        OnAfterPost(TransHeader, Selection);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostTransferOrder(var TransHeader: Record "Transfer Header"; var DefaultNumber: Integer; var Selection: Option; var IsHandled: Boolean)
    begin
    end;
}

