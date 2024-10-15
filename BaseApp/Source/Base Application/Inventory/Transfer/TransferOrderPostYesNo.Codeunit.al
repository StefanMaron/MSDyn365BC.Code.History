namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Setup;

codeunit 5706 "TransferOrder-Post (Yes/No)"
{
    TableNo = "Transfer Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        TransHeader.Copy(Rec);
        Code();
        Rec := TransHeader;
    end;

    var
        TransHeader: Record "Transfer Header";
        PreviewMode: Boolean;
        PostBatch: Boolean;
        TransferOrderPost: enum "Transfer Order Post";
        Text000: Label '&Ship,&Receive';

    local procedure "Code"()
    var
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        PostReceipt, PostShipment, PostTransfer : Boolean;
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled, TransferOrderPostShipment, TransferOrderPostReceipt, PostBatch, TransferOrderPost);
        if IsHandled then
            exit;

        DefaultNumber := GetDefaultNumber();

        IsHandled := false;
        OnCodeOnBeforePostTransferOrder(TransHeader, DefaultNumber, Selection, IsHandled, PostBatch, TransferOrderPost, PreviewMode);
        if not IsHandled then begin
            GetPostingOptions(DefaultNumber, Selection, PostShipment, PostReceipt, PostTransfer);
            PostTransferOrder(PostShipment, PostReceipt, PostTransfer);
        end;

        OnAfterPost(TransHeader, Selection);
    end;

    local procedure GetDefaultNumber() DefaultNumber: Integer
    var
        TransferLine: Record "Transfer Line";
    begin
        if PostBatch or TransHeader."Direct Transfer" then
            exit;

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransHeader."No.");
        if TransferLine.Find('-') then
            repeat
                if (TransferLine."Quantity Shipped" < TransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 1;
                if (TransferLine."Quantity Received" < TransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 2;
            until (TransferLine.Next() = 0) or (DefaultNumber > 0);
    end;

    local procedure GetPostingOptions(var DefaultNumber: Integer; var Selection: Option " ",Shipment,Receipt; var PostShipment: boolean; var PostReceipt: boolean; var PostTransfer: boolean)
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPostingOptions(TransHeader, Selection, PostShipment, PostReceipt, IsHandled, PostTransfer);
        if IsHandled then
            exit;

        InventorySetup.Get();

        case true of
            (TransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Receipt and Shipment"):
                begin
                    PostShipment := true;
                    PostReceipt := true;
                end;
            (TransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Direct Transfer"):
                PostTransfer := true;
            PostBatch:
                begin
                    PostShipment := TransferOrderPost = TransferOrderPost::Ship;
                    PostReceipt := TransferOrderPost = TransferOrderPost::Receive;
                end;
            else begin
                if DefaultNumber = 0 then
                    DefaultNumber := 1;
                Selection := StrMenu(Text000, DefaultNumber);

                IsHandled := false;
                OnGetPostingOptionsOnAfterSelection(TransHeader, DefaultNumber, Selection, PostShipment, PostReceipt, PostTransfer, IsHandled);
                if IsHandled then
                    exit;

                PostShipment := Selection = Selection::Shipment;
                PostReceipt := Selection = Selection::Receipt;
            end;
        end;
    end;

    local procedure PostTransferOrder(PostShipment: boolean; PostReceipt: boolean; PostTransfer: boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        if PostShipment then begin
            TransferOrderPostShipment.SetHideValidationDialog(PostBatch);
            TransferOrderPostShipment.SetPreviewMode(PreviewMode);
            TransferOrderPostShipment.Run(TransHeader);
        end;

        if PostReceipt then begin
            TransferOrderPostReceipt.SetHideValidationDialog(PostBatch);
            TransferOrderPostReceipt.SetPreviewMode(PreviewMode);
            TransferOrderPostReceipt.Run(TransHeader);
        end;

        if PostTransfer then begin
            TransferOrderPostTransfer.SetPreviewMode(PreviewMode);
            TransferOrderPostTransfer.Run(TransHeader);
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    internal procedure SetParameters(SetPostBatch: Boolean; SetTransferOrderPost: enum "Transfer Order Post")
    begin
        PostBatch := SetPostBatch;
        TransferOrderPost := SetTransferOrderPost;
    end;

    procedure Preview(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(TransferOrderPostYesNo);
        GenJnlPostPreview.Preview(TransferOrderPostYesNo, TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        TransferHeader: Record "Transfer Header";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
    begin
        TransferHeader.Copy(RecVar);
        TransferOrderPostYesNo.SetPreviewMode(true);
        Result := TransferOrderPostYesNo.Run(TransferHeader);
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt"; var PostBatch: Boolean; var TransferOrderPost: Enum "Transfer Order Post")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostTransferOrder(var TransHeader: Record "Transfer Header"; var DefaultNumber: Integer; var Selection: Option; var IsHandled: Boolean; var PostBatch: Boolean; var TransferOrderPost: Enum "Transfer Order Post"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingOptions(TransferHeader: Record "Transfer Header"; Selection: Option; var PostShipment: Boolean; var PostReceipt: Boolean; var IsHandled: Boolean; var PostTransfer: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPostingOptionsOnAfterSelection(TransferHeader: Record "Transfer Header"; DefaultNumber: Integer; var Selection: Option; var PostShipment: Boolean; var PostReceipt: Boolean; var PostTransfer: Boolean; var IsHandled: Boolean);
    begin
    end;
}
