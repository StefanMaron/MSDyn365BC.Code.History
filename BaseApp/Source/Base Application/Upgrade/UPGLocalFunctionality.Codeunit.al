codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdatePhysInventoryOrders();
        CleanupPhysOrders();
        UpdateVendorRegistrationNo();
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
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag()) THEN
            EXIT;

        IF InventorySetup.Get() then BEGIN
            InventorySetup."Phys. Invt. Order Nos." := InventorySetup."Phys. Inv. Order Nos.";
            InventorySetup."Posted Phys. Invt. Order Nos." := InventorySetup."Posted Phys. Inv. Order Nos.";
            InventorySetup.Modify();
        END;

        IF SourceCodeSetup.Get() then BEGIN
            SourceCodeSetup."Phys. Invt. Orders" := SourceCodeSetup."Phys. Invt. Order";
            SourceCodeSetup.Modify();
        END;

        IF UPGPhysInventoryOrderHeader.FindSet() then
            REPEAT
                PhysInvtOrderHeader.Init();
                PhysInvtOrderHeader.TRANSFERFIELDS(UPGPhysInventoryOrderHeader, TRUE);
                PhysInvtOrderHeader.Insert();
            UNTIL UPGPhysInventoryOrderHeader.Next() = 0;

        IF UPGPhysInventoryOrderLine.FindSet() then
            REPEAT
                PhysInvtOrderLine.Init();
                PhysInvtOrderLine.TRANSFERFIELDS(UPGPhysInventoryOrderLine, TRUE);
                PhysInvtOrderLine.Insert();
            UNTIL UPGPhysInventoryOrderLine.Next() = 0;

        IF UPGPhysInvtRecordingHeader.FindSet() then
            REPEAT
                PhysInvtRecordHeader.Init();
                PhysInvtRecordHeader.TRANSFERFIELDS(UPGPhysInvtRecordingHeader, TRUE);
                PhysInvtRecordHeader.Insert();
            UNTIL UPGPhysInvtRecordingHeader.Next() = 0;

        IF UPGPhysInvtRecordingLine.FindSet() then
            REPEAT
                PhysInvtRecordLine.Init();
                PhysInvtRecordLine.TRANSFERFIELDS(UPGPhysInvtRecordingLine, TRUE);
                PhysInvtRecordLine.Insert();
            UNTIL UPGPhysInvtRecordingLine.Next() = 0;

        IF UPGPostPhysInvtOrderHeader.FindSet() then
            REPEAT
                PstdPhysInvtOrderHdr.Init();
                PstdPhysInvtOrderHdr.TRANSFERFIELDS(UPGPostPhysInvtOrderHeader, TRUE);
                PstdPhysInvtOrderHdr.Insert();
            UNTIL UPGPostPhysInvtOrderHeader.Next() = 0;

        IF UPGPostedPhysInvtOrderLine.FindSet() then
            REPEAT
                PstdPhysInvtOrderLine.Init();
                PstdPhysInvtOrderLine.TRANSFERFIELDS(UPGPostedPhysInvtOrderLine, TRUE);
                PstdPhysInvtOrderLine.Insert();
            UNTIL UPGPostedPhysInvtOrderLine.Next() = 0;

        IF UPGPostedPhysInvtRecHeader.FindSet() then
            REPEAT
                PstdPhysInvtRecordHdr.Init();
                PstdPhysInvtRecordHdr.TRANSFERFIELDS(UPGPostedPhysInvtRecHeader, TRUE);
                PstdPhysInvtRecordHdr.Insert();
            UNTIL UPGPostedPhysInvtRecHeader.Next() = 0;

        IF UPGPostedPhysInvtRecLine.FindSet() then
            REPEAT
                PstdPhysInvtRecordLine.Init();
                PstdPhysInvtRecordLine.TRANSFERFIELDS(UPGPostedPhysInvtRecLine, TRUE);
                PstdPhysInvtRecordLine.Insert();
            UNTIL UPGPostedPhysInvtRecLine.Next() = 0;

        IF UPGPhysInventoryCommentLine.FindSet() then
            REPEAT
                PhysInvtCommentLine.Init();
                PhysInvtCommentLine.TRANSFERFIELDS(UPGPhysInventoryCommentLine, TRUE);
                PhysInvtCommentLine.Insert();
            UNTIL UPGPhysInventoryCommentLine.Next() = 0;

        IF UPGPostedPhysInvtTrackLine.FindSet() then
            REPEAT
                PstdPhysInvtTracking.Init();
                PstdPhysInvtTracking.TRANSFERFIELDS(UPGPostedPhysInvtTrackLine, TRUE);
                PstdPhysInvtTracking.Insert();
            UNTIL UPGPostedPhysInvtTrackLine.Next() = 0;

        IF UPGPhysInvtTrackingBuffer.FindSet() then
            REPEAT
                PhysInvtTracking.Init();
                PhysInvtTracking.TRANSFERFIELDS(UPGPhysInvtTrackingBuffer);
                PhysInvtTracking.Insert();
            UNTIL UPGPhysInvtTrackingBuffer.Next() = 0;

        IF UPGExpectPhysInvTrackLine.FindSet() then
            REPEAT
                ExpPhysInvtTracking.Init();
                ExpPhysInvtTracking.TRANSFERFIELDS(UPGExpectPhysInvTrackLine);
                ExpPhysInvtTracking.Insert();
            UNTIL UPGExpectPhysInvTrackLine.Next() = 0;

        IF UPGPostExpPhInTrackLine.FindSet() then
            REPEAT
                PstdExpPhysInvtTrack.Init();
                PstdExpPhysInvtTrack.TRANSFERFIELDS(UPGPostExpPhInTrackLine);
                PstdExpPhysInvtTrack.Insert();
            UNTIL UPGPostExpPhInTrackLine.Next() = 0;

        IF UPGPhysInvtDiffListBuffer.FindSet() then
            REPEAT
                PhysInvtCountBuffer.Init();
                PhysInvtCountBuffer.TRANSFERFIELDS(UPGPhysInvtDiffListBuffer);
                PhysInvtCountBuffer.Insert();
            UNTIL UPGPhysInvtDiffListBuffer.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag());
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
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag()) THEN
            EXIT;

        DACHReportSelections.SETRANGE(Usage, DACHReportSelections.Usage::"Sales VAT Acc. Proof");
        IF DACHReportSelections.FindFirst() then BEGIN
            DACHReportSelections."Report ID" := 11;
            DACHReportSelections.Modify();
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag());
    end;

    procedure UpdateVendorRegistrationNo()
    var
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        VendorDataTransfer: DataTransfer;
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag()) THEN
            EXIT;

        VendorDataTransfer.SetTables(Database::Vendor, Database::Vendor);
        VendorDataTransfer.AddFieldValue(Vendor.FieldNo("Registration No."), Vendor.FieldNo("Registration Number"));
        VendorDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag());
    end;
}

