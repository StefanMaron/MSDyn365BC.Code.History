codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    local procedure UpdatePhysInventoryOrders()
    var
        SourceCodeSetup: Record "Source Code Setup";
        InventorySetup: Record "Inventory Setup";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
        PstdPhysInvtTracking: Record "Pstd. Phys. Invt. Tracking";
        PhysInvtTracking: Record "Phys. Invt. Tracking";
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
        PhysInvtCountBuffer: Record "Phys. Invt. Count Buffer";
        UPGPhysInventoryOrderHeader: Record "Phys. Inventory Order Header";
        UPGPhysInventoryOrderLine: Record "Phys. Inventory Order Line";
        UPGPhysInvtRecordingHeader: Record "Phys. Invt. Recording Header";
        UPGPhysInvtRecordingLine: Record "Phys. Invt. Recording Line";
        UPGPostPhysInvtOrderHeader: Record "Post. Phys. Invt. Order Header";
        UPGPostedPhysInvtOrderLine: Record "Posted Phys. Invt. Order Line";
        UPGPostedPhysInvtRecHeader: Record "Posted Phys. Invt. Rec. Header";
        UPGPostedPhysInvtRecLine: Record "Posted Phys. Invt. Rec. Line";
        UPGPhysInventoryCommentLine: Record "Phys. Inventory Comment Line";
        UPGPostedPhysInvtTrackLine: Record "Posted Phys. Invt. Track. Line";
        UPGPhysInvtTrackingBuffer: Record "Phys. Invt. Tracking Buffer";
        UPGExpectPhysInvTrackLine: Record "Expect. Phys. Inv. Track. Line";
        UPGPostExpPhInTrackLine: Record "Post. Exp. Ph. In. Track. Line";
        UPGPhysInvtDiffListBuffer: Record "Phys. Invt. Diff. List Buffer";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag) THEN
            EXIT;

        IF InventorySetup.GET THEN BEGIN
            InventorySetup."Phys. Invt. Order Nos." := InventorySetup."Phys. Inv. Order Nos.";
            InventorySetup."Posted Phys. Invt. Order Nos." := InventorySetup."Posted Phys. Inv. Order Nos.";
            InventorySetup.MODIFY;
        END;

        IF SourceCodeSetup.GET THEN BEGIN
            SourceCodeSetup."Phys. Invt. Orders" := SourceCodeSetup."Phys. Invt. Order";
            SourceCodeSetup.MODIFY;
        END;

        IF UPGPhysInventoryOrderHeader.FINDSET THEN
            REPEAT
                PhysInvtOrderHeader.INIT;
                PhysInvtOrderHeader.TRANSFERFIELDS(UPGPhysInventoryOrderHeader, TRUE);
                PhysInvtOrderHeader.INSERT;
            UNTIL UPGPhysInventoryOrderHeader.NEXT = 0;

        IF UPGPhysInventoryOrderLine.FINDSET THEN
            REPEAT
                PhysInvtOrderLine.INIT;
                PhysInvtOrderLine.TRANSFERFIELDS(UPGPhysInventoryOrderLine, TRUE);
                PhysInvtOrderLine.INSERT;
            UNTIL UPGPhysInventoryOrderLine.NEXT = 0;

        IF UPGPhysInvtRecordingHeader.FINDSET THEN
            REPEAT
                PhysInvtRecordHeader.INIT;
                PhysInvtRecordHeader.TRANSFERFIELDS(UPGPhysInvtRecordingHeader, TRUE);
                PhysInvtRecordHeader.INSERT;
            UNTIL UPGPhysInvtRecordingHeader.NEXT = 0;

        IF UPGPhysInvtRecordingLine.FINDSET THEN
            REPEAT
                PhysInvtRecordLine.INIT;
                PhysInvtRecordLine.TRANSFERFIELDS(UPGPhysInvtRecordingLine, TRUE);
                PhysInvtRecordLine.INSERT;
            UNTIL UPGPhysInvtRecordingLine.NEXT = 0;

        IF UPGPostPhysInvtOrderHeader.FINDSET THEN
            REPEAT
                PstdPhysInvtOrderHdr.INIT;
                PstdPhysInvtOrderHdr.TRANSFERFIELDS(UPGPostPhysInvtOrderHeader, TRUE);
                PstdPhysInvtOrderHdr.INSERT;
            UNTIL UPGPostPhysInvtOrderHeader.NEXT = 0;

        IF UPGPostedPhysInvtOrderLine.FINDSET THEN
            REPEAT
                PstdPhysInvtOrderLine.INIT;
                PstdPhysInvtOrderLine.TRANSFERFIELDS(UPGPostedPhysInvtOrderLine, TRUE);
                PstdPhysInvtOrderLine.INSERT;
            UNTIL UPGPostedPhysInvtOrderLine.NEXT = 0;

        IF UPGPostedPhysInvtRecHeader.FINDSET THEN
            REPEAT
                PstdPhysInvtRecordHdr.INIT;
                PstdPhysInvtRecordHdr.TRANSFERFIELDS(UPGPostedPhysInvtRecHeader, TRUE);
                PstdPhysInvtRecordHdr.INSERT;
            UNTIL UPGPostedPhysInvtRecHeader.NEXT = 0;

        IF UPGPostedPhysInvtRecLine.FINDSET THEN
            REPEAT
                PstdPhysInvtRecordLine.INIT;
                PstdPhysInvtRecordLine.TRANSFERFIELDS(UPGPostedPhysInvtRecLine, TRUE);
                PstdPhysInvtRecordLine.INSERT;
            UNTIL UPGPostedPhysInvtRecLine.NEXT = 0;

        IF UPGPhysInventoryCommentLine.FINDSET THEN
            REPEAT
                PhysInvtCommentLine.INIT;
                PhysInvtCommentLine.TRANSFERFIELDS(UPGPhysInventoryCommentLine, TRUE);
                PhysInvtCommentLine.INSERT;
            UNTIL UPGPhysInventoryCommentLine.NEXT = 0;

        IF UPGPostedPhysInvtTrackLine.FINDSET THEN
            REPEAT
                PstdPhysInvtTracking.INIT;
                PstdPhysInvtTracking.TRANSFERFIELDS(UPGPostedPhysInvtTrackLine, TRUE);
                PstdPhysInvtTracking.INSERT;
            UNTIL UPGPostedPhysInvtTrackLine.NEXT = 0;

        IF UPGPhysInvtTrackingBuffer.FINDSET THEN
            REPEAT
                PhysInvtTracking.INIT;
                PhysInvtTracking.TRANSFERFIELDS(UPGPhysInvtTrackingBuffer);
                PhysInvtTracking.INSERT;
            UNTIL UPGPhysInvtTrackingBuffer.NEXT = 0;

        IF UPGExpectPhysInvTrackLine.FINDSET THEN
            REPEAT
                ExpPhysInvtTracking.INIT;
                ExpPhysInvtTracking.TRANSFERFIELDS(UPGExpectPhysInvTrackLine);
                ExpPhysInvtTracking.INSERT;
            UNTIL UPGExpectPhysInvTrackLine.NEXT = 0;

        IF UPGPostExpPhInTrackLine.FINDSET THEN
            REPEAT
                PstdExpPhysInvtTrack.INIT;
                PstdExpPhysInvtTrack.TRANSFERFIELDS(UPGPostExpPhInTrackLine);
                PstdExpPhysInvtTrack.INSERT;
            UNTIL UPGPostExpPhInTrackLine.NEXT = 0;

        IF UPGPhysInvtDiffListBuffer.FINDSET THEN
            REPEAT
                PhysInvtCountBuffer.INIT;
                PhysInvtCountBuffer.TRANSFERFIELDS(UPGPhysInvtDiffListBuffer);
                PhysInvtCountBuffer.INSERT;
            UNTIL UPGPhysInvtDiffListBuffer.NEXT = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag);
    end;

    procedure SetReportSelectionForGLVATReconciliation()
    var
        DACHReportSelections: Record "DACH Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag) THEN
            EXIT;

        DACHReportSelections.SETRANGE(Usage, DACHReportSelections.Usage::"Sales VAT Acc. Proof");
        IF DACHReportSelections.FINDFIRST THEN BEGIN
            DACHReportSelections."Report ID" := 11;
            DACHReportSelections.MODIFY;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag);
    end;
}

