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

#if not CLEAN24
        UpdatePhysInventoryOrders();
        CleanupPhysOrders();
#endif
        UpdateVendorRegistrationNo();
    end;

#if not CLEAN24
    local procedure UpdatePhysInventoryOrders()
    var
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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetPhysInvntOrdersUpgradeTag()) then
            exit;

        if InventorySetup.Get() then begin
            InventorySetup."Phys. Invt. Order Nos." := InventorySetup."Phys. Inv. Order Nos.";
            InventorySetup."Posted Phys. Invt. Order Nos." := InventorySetup."Posted Phys. Inv. Order Nos.";
            InventorySetup.Modify();
        end;

        if UPGPhysInventoryOrderHeader.FindSet() then
            repeat
                PhysInvtOrderHeader.Init();
                PhysInvtOrderHeader.TRANSFERFIELDS(UPGPhysInventoryOrderHeader, true);
                PhysInvtOrderHeader.Insert();
            until UPGPhysInventoryOrderHeader.Next() = 0;

        if UPGPhysInventoryOrderLine.FindSet() then
            repeat
                PhysInvtOrderLine.Init();
                PhysInvtOrderLine.TRANSFERFIELDS(UPGPhysInventoryOrderLine, true);
                PhysInvtOrderLine.Insert();
            until UPGPhysInventoryOrderLine.Next() = 0;

        if UPGPhysInvtRecordingHeader.FindSet() then
            repeat
                PhysInvtRecordHeader.Init();
                PhysInvtRecordHeader.TRANSFERFIELDS(UPGPhysInvtRecordingHeader, true);
                PhysInvtRecordHeader.Insert();
            until UPGPhysInvtRecordingHeader.Next() = 0;

        if UPGPhysInvtRecordingLine.FindSet() then
            repeat
                PhysInvtRecordLine.Init();
                PhysInvtRecordLine.TRANSFERFIELDS(UPGPhysInvtRecordingLine, true);
                PhysInvtRecordLine.Insert();
            until UPGPhysInvtRecordingLine.Next() = 0;

        if UPGPostPhysInvtOrderHeader.FindSet() then
            repeat
                PstdPhysInvtOrderHdr.Init();
                PstdPhysInvtOrderHdr.TRANSFERFIELDS(UPGPostPhysInvtOrderHeader, true);
                PstdPhysInvtOrderHdr.Insert();
            until UPGPostPhysInvtOrderHeader.Next() = 0;

        if UPGPostedPhysInvtOrderLine.FindSet() then
            repeat
                PstdPhysInvtOrderLine.Init();
                PstdPhysInvtOrderLine.TRANSFERFIELDS(UPGPostedPhysInvtOrderLine, true);
                PstdPhysInvtOrderLine.Insert();
            until UPGPostedPhysInvtOrderLine.Next() = 0;

        if UPGPostedPhysInvtRecHeader.FindSet() then
            repeat
                PstdPhysInvtRecordHdr.Init();
                PstdPhysInvtRecordHdr.TRANSFERFIELDS(UPGPostedPhysInvtRecHeader, true);
                PstdPhysInvtRecordHdr.Insert();
            until UPGPostedPhysInvtRecHeader.Next() = 0;

        if UPGPostedPhysInvtRecLine.FindSet() then
            repeat
                PstdPhysInvtRecordLine.Init();
                PstdPhysInvtRecordLine.TRANSFERFIELDS(UPGPostedPhysInvtRecLine, true);
                PstdPhysInvtRecordLine.Insert();
            until UPGPostedPhysInvtRecLine.Next() = 0;

        if UPGPhysInventoryCommentLine.FindSet() then
            repeat
                PhysInvtCommentLine.Init();
                PhysInvtCommentLine.TRANSFERFIELDS(UPGPhysInventoryCommentLine, true);
                PhysInvtCommentLine.Insert();
            until UPGPhysInventoryCommentLine.Next() = 0;

        if UPGPostedPhysInvtTrackLine.FindSet() then
            repeat
                PstdPhysInvtTracking.Init();
                PstdPhysInvtTracking.TRANSFERFIELDS(UPGPostedPhysInvtTrackLine, true);
                PstdPhysInvtTracking.Insert();
            until UPGPostedPhysInvtTrackLine.Next() = 0;

        if UPGPhysInvtTrackingBuffer.FindSet() then
            repeat
                PhysInvtTracking.Init();
                PhysInvtTracking.TRANSFERFIELDS(UPGPhysInvtTrackingBuffer);
                PhysInvtTracking.Insert();
            until UPGPhysInvtTrackingBuffer.Next() = 0;

        if UPGExpectPhysInvTrackLine.FindSet() then
            repeat
                ExpPhysInvtTracking.Init();
                ExpPhysInvtTracking.TRANSFERFIELDS(UPGExpectPhysInvTrackLine);
                ExpPhysInvtTracking.Insert();
            until UPGExpectPhysInvTrackLine.Next() = 0;
        if UPGPostExpPhInTrackLine.FindSet() then
            repeat
                PstdExpPhysInvtTrack.Init();
                PstdExpPhysInvtTrack.TRANSFERFIELDS(UPGPostExpPhInTrackLine);
                PstdExpPhysInvtTrack.Insert();
            until UPGPostExpPhInTrackLine.Next() = 0;

        if UPGPhysInvtDiffListBuffer.FindSet() then
            repeat
                PhysInvtCountBuffer.Init();
                PhysInvtCountBuffer.TRANSFERFIELDS(UPGPhysInvtDiffListBuffer);
                PhysInvtCountBuffer.Insert();
            until UPGPhysInvtDiffListBuffer.Next() = 0;

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
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCleanupPhysOrders()) then
            exit;

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
#endif

#if not CLEAN25
    [Obsolete('Replaced by ReportSelections table setup', '25.0')]
    procedure SetReportSelectionForGLVATReconciliation()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag()) then
            exit;

        DACHReportSelections.SETRANGE(Usage, DACHReportSelections.Usage::"Sales VAT Acc. Proof");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := 11;

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"Sales VAT Acc. Proof";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := DACHReportSelections."Report ID";
        if not ReportSelections.Insert() then
            ReportSelections.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag());
    end;
#endif

    procedure UpdateVendorRegistrationNo()
    var
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        VendorDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag()) then
            exit;

        VendorDataTransfer.SetTables(Database::Vendor, Database::Vendor);
        VendorDataTransfer.AddFieldValue(Vendor.FieldNo("Registration No."), Vendor.FieldNo("Registration Number"));
        VendorDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag());
    end;
}

