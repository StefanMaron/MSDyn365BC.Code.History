codeunit 5401 "Feature - Unit Group Mapping" implements "Feature Data Update"
{
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
        Item: Record Item;
        Resource: Record Resource;
        UnitGroup: Record "Unit Group";
        StartDateTime: DateTime;
    begin
        AdjustCRMConnectionSetup();

        StartDateTime := CurrentDateTime;
        Item.FindSet();
        repeat
            if not UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId) then begin
                UnitGroup.Init();
                UnitGroup."Source Id" := Item.SystemId;
                UnitGroup."Source No." := Item."No.";
                UnitGroup."Code" := ItemUnitGroupPrefixLbl + ' ' + Item."No." + ' ' + 'UOM GR';
                UnitGroup."Source Name" := Item.Description;
                UnitGroup."Source Type" := UnitGroup."Source Type"::Item;
                UnitGroup.Insert();
            end;
        until Item.Next() = 0;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, UnitGroup.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        Resource.FindSet();
        repeat
            if not UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId) then begin
                UnitGroup.Init();
                UnitGroup."Source Id" := Resource.SystemId;
                UnitGroup."Source No." := Resource."No.";
                UnitGroup."Code" := ResourceUnitGroupPrefixLbl + ' ' + Resource."No." + ' ' + 'UOM GR';
                UnitGroup."Source Name" := Resource.Name;
                UnitGroup."Source Type" := UnitGroup."Source Type"::Resource;
                UnitGroup.Insert();
            end;
        until Resource.Next() = 0;
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
        ItemUnitGroupPrefixLbl: Label 'ITEM', Locked = true;
        ResourceUnitGroupPrefixLbl: Label 'RESOURCE', Locked = true;
        DescriptionTxt: Label 'If you enable Unit Group Mapping, data will be generated in Unit Group table.';

    local procedure CountRecords()
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::Item, Item.TableCaption, Item.CountApprox);
        InsertDocumentEntry(Database::Resource, Resource.TableCaption, Resource.CountApprox);
    end;

    local procedure AdjustCRMConnectionSetup()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMFullSyncReviewLine: Record "CRM Full Synch. Review Line";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationRecord.SetFilter("Table ID", '%1', Database::"Unit of Measure");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();
        if CRMIntegrationManagement.IsCRMIntegrationEnabled() then begin
            if CRMFullSyncReviewLine.Get('UNIT OF MEASURE') then
                CRMFullSyncReviewLine.Delete();
            if RemoveIntegrationTableMapping(Database::"Unit of Measure", Database::"CRM Uomschedule") then
                CRMSetupDefaults.ResetUnitGroupMappingConfiguration();
        end;
    end;

    local procedure RemoveIntegrationTableMapping(TableId: Integer; IntTableId: Integer) JobExisted: Boolean;
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableId);
        IntegrationTableMapping.SetRange("Integration Table ID", IntTableId);
        if IntegrationTableMapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                if not JobQueueEntry.IsEmpty() then begin
                    JobExisted := true;
                    JobQueueEntry.DeleteAll(true);
                end;
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;
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