codeunit 5885 "Phys. Invt. Order-Post + Print"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        PhysInvtOrderHeader.Copy(Rec);

        if not Confirm(ConfirmPostQst, false) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        OnAfterPostPhysInvtOrder(PhysInvtOrderHeader);

        PstdPhysInvtOrderHdr.Init();
        PstdPhysInvtOrderHdr."No." := PhysInvtOrderHeader."Last Posting No.";
        PstdPhysInvtOrderHdr.SetRecFilter;
        DocPrint.PrintPostedInvtOrder(PstdPhysInvtOrderHdr, false);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmPostQst: Label 'Do you want to post and print the order?';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        DocPrint: Codeunit "Document-Print";

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPhysInvtOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;
}

