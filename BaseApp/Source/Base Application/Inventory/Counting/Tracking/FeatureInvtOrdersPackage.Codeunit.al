#if not CLEAN24
namespace System.Environment.Configuration;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Counting.Tracking;

codeunit 5890 "Feature - Invt. Orders Package" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = TableData "Feature Data Update Status" = rm;
    ObsoleteReason = 'Feature OptionMapping will be enabled by default in version 27.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    // The Data upgrade codeunit for Phys. Invt. Orders Package Tracking
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        DescriptionTxt: Label 'If you enable package tracking for physical inventory orders, all orders data for current and expected tracking will be migrated to new tracking tables with package number fields.';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        // Data upgrade is not required if following tables are empty:
        // table 5885 Phys. Invt. Tracking
        // table 5886 "Exp. Phys. Invt. Tracking"
        // table 5887 "Pstd. Exp. Phys. Invt. Track"
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty());
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");  // Data is not per company
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        InvtOrderTracking: Record "Invt. Order Tracking";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        MigrateInvtOrderTracking();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, InvtOrderTracking.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords(): Integer
    var
        PhysInvtTracking: Record "Phys. Invt. Tracking";
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::"Phys. Invt. Tracking", PhysInvtTracking.TableCaption(), PhysInvtTracking.CountApprox());
        InsertDocumentEntry(Database::"Exp. Phys. Invt. Tracking", ExpPhysInvtTracking.TableCaption(), ExpPhysInvtTracking.CountApprox());
        InsertDocumentEntry(Database::"Pstd. Exp. Phys. Invt. Track", PstdExpPhysInvtTrack.TableCaption(), PstdExpPhysInvtTrack.CountApprox());
    end;

    local procedure MigrateInvtOrderTracking()
    var
        PhysInvtTracking: Record "Phys. Invt. Tracking";
        ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
        InvtOrderTracking: Record "Invt. Order Tracking";
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
        InventorySetup: Record "Inventory Setup";
    begin
        if PhysInvtTracking.FindSet() then
            repeat
                InvtOrderTracking.TransferFields(PhysInvtTracking);
                InvtOrderTracking.Insert(true);
            until PhysInvtTracking.Next() = 0;

        if ExpPhysInvtTracking.FindSet() then
            repeat
                ExpInvtOrderTracking.TransferFields(ExpPhysInvtTracking);
                ExpInvtOrderTracking.Insert(true);
            until ExpPhysInvtTracking.Next() = 0;

        if PstdExpPhysInvtTrack.FindSet() then
            repeat
                PstdExpInvtOrderTracking.TransferFields(PstdExpPhysInvtTrack);
                PstdExpInvtOrderTracking.Insert(true);
            until PstdExpPhysInvtTrack.Next() = 0;

        InventorySetup.Get();
        InventorySetup.Validate("Invt. Orders Package Tracking", true);
        InventorySetup.Modify();
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}
#endif