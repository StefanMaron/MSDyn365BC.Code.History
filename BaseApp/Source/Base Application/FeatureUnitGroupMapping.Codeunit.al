#if not CLEAN21
codeunit 5401 "Feature - Unit Group Mapping" implements "Feature Data Update"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature UnitGroupMapping will be deprecated and instead will be an option on the connection setup.';
    ObsoleteTag = '21.0';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        UnitGroup: Record "Unit Group";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        StartDateTime: DateTime;
    begin
        CRMIntegrationManagement.AdjustUnitGroupCRMConnectionSetup();

        StartDateTime := CurrentDateTime;
        CRMIntegrationManagement.UpdateItemUnitGroup();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, UnitGroup.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CRMIntegrationManagement.UpdateResourceUnitGroup();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, UnitGroup.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        LastEntryNo: Integer;
        DescriptionTxt: Label 'If you enable Unit Group Mapping, data will be generated in Unit Group table.';

    local procedure CountRecords()
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::Item, Item.TableCaption(), Item.CountApprox);
        InsertDocumentEntry(Database::Resource, Resource.TableCaption(), Resource.CountApprox);
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        LastEntryNo += 1;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := LastEntryNo;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}
#endif