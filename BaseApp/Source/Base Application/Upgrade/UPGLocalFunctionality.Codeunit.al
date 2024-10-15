codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdatePhysInventoryOrders();
        CleanupPhysOrders();
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
            InventorySetup.Modify();
        END;

        IF SourceCodeSetup.GET THEN BEGIN
            SourceCodeSetup."Phys. Invt. Orders" := SourceCodeSetup."Phys. Invt. Order";
            SourceCodeSetup.Modify();
        END;

        IF UPGPhysInventoryOrderHeader.FINDSET THEN
            REPEAT
                PhysInvtOrderHeader.Init();
                PhysInvtOrderHeader.TRANSFERFIELDS(UPGPhysInventoryOrderHeader, TRUE);
                PhysInvtOrderHeader.Insert();
            UNTIL UPGPhysInventoryOrderHeader.Next() = 0;

        IF UPGPhysInventoryOrderLine.FINDSET THEN
            REPEAT
                PhysInvtOrderLine.Init();
                PhysInvtOrderLine.TRANSFERFIELDS(UPGPhysInventoryOrderLine, TRUE);
                PhysInvtOrderLine.Insert();
            UNTIL UPGPhysInventoryOrderLine.Next() = 0;

        IF UPGPhysInvtRecordingHeader.FINDSET THEN
            REPEAT
                PhysInvtRecordHeader.Init();
                PhysInvtRecordHeader.TRANSFERFIELDS(UPGPhysInvtRecordingHeader, TRUE);
                PhysInvtRecordHeader.Insert();
            UNTIL UPGPhysInvtRecordingHeader.Next() = 0;

        IF UPGPhysInvtRecordingLine.FINDSET THEN
            REPEAT
                PhysInvtRecordLine.Init();
                PhysInvtRecordLine.TRANSFERFIELDS(UPGPhysInvtRecordingLine, TRUE);
                PhysInvtRecordLine.Insert();
            UNTIL UPGPhysInvtRecordingLine.Next() = 0;

        IF UPGPostPhysInvtOrderHeader.FINDSET THEN
            REPEAT
                PstdPhysInvtOrderHdr.Init();
                PstdPhysInvtOrderHdr.TRANSFERFIELDS(UPGPostPhysInvtOrderHeader, TRUE);
                PstdPhysInvtOrderHdr.Insert();
            UNTIL UPGPostPhysInvtOrderHeader.Next() = 0;

        IF UPGPostedPhysInvtOrderLine.FINDSET THEN
            REPEAT
                PstdPhysInvtOrderLine.Init();
                PstdPhysInvtOrderLine.TRANSFERFIELDS(UPGPostedPhysInvtOrderLine, TRUE);
                PstdPhysInvtOrderLine.Insert();
            UNTIL UPGPostedPhysInvtOrderLine.Next() = 0;

        IF UPGPostedPhysInvtRecHeader.FINDSET THEN
            REPEAT
                PstdPhysInvtRecordHdr.Init();
                PstdPhysInvtRecordHdr.TRANSFERFIELDS(UPGPostedPhysInvtRecHeader, TRUE);
                PstdPhysInvtRecordHdr.Insert();
            UNTIL UPGPostedPhysInvtRecHeader.Next() = 0;

        IF UPGPostedPhysInvtRecLine.FINDSET THEN
            REPEAT
                PstdPhysInvtRecordLine.Init();
                PstdPhysInvtRecordLine.TRANSFERFIELDS(UPGPostedPhysInvtRecLine, TRUE);
                PstdPhysInvtRecordLine.Insert();
            UNTIL UPGPostedPhysInvtRecLine.Next() = 0;

        IF UPGPhysInventoryCommentLine.FINDSET THEN
            REPEAT
                PhysInvtCommentLine.Init();
                PhysInvtCommentLine.TRANSFERFIELDS(UPGPhysInventoryCommentLine, TRUE);
                PhysInvtCommentLine.Insert();
            UNTIL UPGPhysInventoryCommentLine.Next() = 0;

        IF UPGPostedPhysInvtTrackLine.FINDSET THEN
            REPEAT
                PstdPhysInvtTracking.Init();
                PstdPhysInvtTracking.TRANSFERFIELDS(UPGPostedPhysInvtTrackLine, TRUE);
                PstdPhysInvtTracking.Insert();
            UNTIL UPGPostedPhysInvtTrackLine.Next() = 0;

        IF UPGPhysInvtTrackingBuffer.FINDSET THEN
            REPEAT
                PhysInvtTracking.Init();
                PhysInvtTracking.TRANSFERFIELDS(UPGPhysInvtTrackingBuffer);
                PhysInvtTracking.Insert();
            UNTIL UPGPhysInvtTrackingBuffer.Next() = 0;

        IF UPGExpectPhysInvTrackLine.FINDSET THEN
            REPEAT
                ExpPhysInvtTracking.Init();
                ExpPhysInvtTracking.TRANSFERFIELDS(UPGExpectPhysInvTrackLine);
                ExpPhysInvtTracking.Insert();
            UNTIL UPGExpectPhysInvTrackLine.Next() = 0;

        IF UPGPostExpPhInTrackLine.FINDSET THEN
            REPEAT
                PstdExpPhysInvtTrack.Init();
                PstdExpPhysInvtTrack.TRANSFERFIELDS(UPGPostExpPhInTrackLine);
                PstdExpPhysInvtTrack.Insert();
            UNTIL UPGPostExpPhInTrackLine.Next() = 0;

        IF UPGPhysInvtDiffListBuffer.FINDSET THEN
            REPEAT
                PhysInvtCountBuffer.Init();
                PhysInvtCountBuffer.TRANSFERFIELDS(UPGPhysInvtDiffListBuffer);
                PhysInvtCountBuffer.Insert();
            UNTIL UPGPhysInvtDiffListBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag);
    end;

    local procedure CleanupPhysOrders()
    var
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
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCleanupPhysOrders()) THEN
            EXIT;

        UPGPhysInventoryOrderHeader.DeleteAll();
        UPGPhysInventoryOrderLine.DeleteAll();
        UPGPhysInvtRecordingHeader.DeleteAll();
        UPGPhysInvtRecordingLine.DeleteAll();
        UPGPostPhysInvtOrderHeader.DeleteAll();
        UPGPostedPhysInvtOrderLine.DeleteAll();
        UPGPostedPhysInvtRecHeader.DeleteAll();
        UPGPostedPhysInvtRecLine.DeleteAll();
        UPGPhysInventoryCommentLine.DeleteAll();
        UPGPostedPhysInvtTrackLine.DeleteAll();
        UPGPhysInvtTrackingBuffer.DeleteAll();
        UPGExpectPhysInvTrackLine.DeleteAll();
        UPGPostExpPhInTrackLine.DeleteAll();
        UPGPhysInvtDiffListBuffer.DeleteAll();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCleanupPhysOrders());
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
            DACHReportSelections.Modify();
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag);
    end;

#if not CLEAN19
    procedure UpgradeCheckPartnerVATID()
    var
        CompanyInformation: Record "Company Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCheckPartnerVATIDTag()) then
            exit;

        if CompanyInformation.Get() then begin
            CompanyInformation."Check for Partner VAT ID" := true;
            CompanyInformation."Check for Country of Origin" := true;
            if CompanyInformation.Modify() then;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCheckPartnerVATIDTag());
    end;
#endif
}

