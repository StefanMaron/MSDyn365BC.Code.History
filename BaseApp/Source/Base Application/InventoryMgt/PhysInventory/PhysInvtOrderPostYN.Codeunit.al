codeunit 5883 "Phys. Invt. Order-Post (Y/N)"
{
    TableNo = "Phys. Invt. Order Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        IsHandled: Boolean;
    begin
        PhysInvtOrderHeader.Copy(Rec);

        IsHandled := false;
        OnPhysInvtOrderPostOnAfterCopyBeforeConfirm(PhysInvtOrderHeader, Rec, IsHandled);
        if IsHandled then
            exit;

        if Confirm(ConfirmPostQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmPostQst: Label 'Do you want to post the order?';

    internal procedure Preview(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    var
        PhysInvtOrderPostYN: Codeunit "Phys. Invt. Order-Post (Y/N)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(PhysInvtOrderPostYN);
        GenJnlPostPreview.Preview(PhysInvtOrderPostYN, PhysInvtOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderPost: Codeunit "Phys. Invt. Order-Post";
    begin
        PhysInvtOrderHeader.Copy(RecVar);
        PhysInvtOrderPost.SetPreviewMode(true);
        Result := PhysInvtOrderPost.Run(PhysInvtOrderHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPhysInvtOrderPostOnAfterCopyBeforeConfirm(var PhysInvtOrderHeaderCopy: Record "Phys. Invt. Order Header"; var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var IsHandled: Boolean)
    begin
    end;
}

