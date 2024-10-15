codeunit 5356 "CRM Item Availability Job"
{
    trigger OnRun()
    begin
        CheckItemLedgerEntries();
    end;

    var
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        StartingToRefreshItemAvailabilityMsg: Label 'Starting to refresh item availability based on item ledger entry activity.', Locked = true;
        ScheduledItemSyncJobForSelectedRecordsMsg: Label 'Scheduled item sync job for selected records.', Locked = true;
        FinishedRefreshingItemAvailabilityMsg: Label 'Finished refreshing item availability based on item ledger entry activity.', Locked = true;
        TelemetryCategoryTok: Label 'AL CRM Integration';

    local procedure CheckItemLedgerEntries()
    var
        Item: Record Item;
        CRMSynchStatus: Record "CRM Synch Status";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMProductName: Codeunit "CRM Product Name";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIdFilter: Text;
        BCNoFilter: Text;
        i: Integer;
        ItemNumber: Code[20];
        NewItemAvailabilitySynchTime: DateTime;
        ItemNumbers: List of [Code[20]];
        CRMIdFilterList: List of [Text];
        BCIdFilterList: List of [Text];
        IdDictionary: Dictionary of [Guid, Code[20]];
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        if CRMSynchStatus.Get() then begin
            NewItemAvailabilitySynchTime := CurrentDateTime();
            Session.LogMessage('0000E44', StartingToRefreshItemAvailabilityMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            AddItemsWithLedgerEntryActivity(CRMSynchStatus."Item Availability Synch. Time", ItemNumbers);

            foreach ItemNumber in ItemNumbers do
                if Item.Get(ItemNumber) then begin
                    CRMIntegrationRecord.Reset();
                    CRMIntegrationRecord.SetRange("Table ID", Database::Item);
                    CRMIntegrationRecord.SetRange(Skipped, false);
                    CRMIntegrationRecord.SetRange("Integration ID", Item.SystemId);
                    if CRMIntegrationRecord.FindFirst() then
                        if not IdDictionary.ContainsKey(CRMIntegrationRecord."CRM ID") then
                            IdDictionary.Add(CRMIntegrationRecord."CRM ID", Item."No.");
                end;

            GetIdFilterLists(IdDictionary, CRMIdFilterList, BCIdFilterList);
            for i := 1 to CRMIdFilterList.Count() do begin
                CRMIdFilter := CRMIdFilterList.Get(i);
                BCNoFilter := BCIdFilterList.Get(i);
                if (CRMIdFilter <> '') and (BCNoFilter <> '') then begin
                    IntegrationTableMapping.Get('ITEM-PRODUCT');
                    IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForFilter(IntegrationTableMapping."Integration Table ID", CRMIdFilter));
                    IntegrationTableMapping.SetTableFilter(GetTableViewForFilter(IntegrationTableMapping."Table ID", BCNoFilter));
                    CRMIntegrationManagement.AddIntegrationTableMapping(IntegrationTableMapping);
                    Commit();
                    CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping);
                    Session.LogMessage('0000E45', ScheduledItemSyncJobForSelectedRecordsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                end;
            end;

            CRMSynchStatus."Item Availability Synch. Time" := NewItemAvailabilitySynchTime;
            CRMSynchStatus.Modify();
            Session.LogMessage('0000E46', FinishedRefreshingItemAvailabilityMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        end;
    end;

    local procedure AddItemsWithLedgerEntryActivity(StartDateTime: DateTime; var ItemNumbers: List of [Code[20]]);
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if StartDateTime = 0DT then begin
            IntegrationTableMapping.Get('ITEM-PRODUCT');
            StartDateTime := IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.";
        end;

        ItemLedgerEntry.SetFilter(SystemModifiedAt, '>%1', StartDateTime);
        if ItemLedgerEntry.FindSet() then
            repeat
                if not ItemNumbers.Contains(ItemLedgerEntry."Item No.") then
                    ItemNumbers.Add(ItemLedgerEntry."Item No.");
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure GetTableViewForFilter(TableNo: Integer; FilterText: Text) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        RecordRef.Open(TableNo);
        KeyRef := RecordRef.KeyIndex(1); // Primary Key
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetFilter(FilterText);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetIdFilterLists(var IdDictionary: Dictionary of [Guid, Code[20]]; var CRMIdFilterList: List of [Text]; var BCNoFilterList: List of [Text]): Boolean
    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        BCIdFilter: Text;
        CRMIdFilter: Text;
        i: Integer;
        MaxCount: Integer;
        Id: Guid;
    begin
        MaxCount := CRMIntegrationTableSynch.GetMaxNumberOfConditions();
        foreach Id in IdDictionary.Keys() do begin
            CRMIdFilter += '|' + Id;
            BCIdFilter += '|' + IdDictionary.Get(Id);
            i += 1;
            if i = MaxCount then begin
                CRMIdFilter := CRMIdFilter.TrimStart('|');
                BCIdFilter := BCIdFilter.TrimStart('|');
                CRMIdFilterList.Add(CRMIdFilter);
                BCNoFilterList.Add(BCIdFilter);
                CRMIdFilter := '';
                BCIdFilter := '';
                i := 0;
            end;
        end;
        if CRMIdFilter <> '' then begin
            BCIdFilter := BCIdFilter.TrimStart('|');
            CRMIdFilter := CRMIdFilter.TrimStart('|');
            BCNoFilterList.Add(BCIdFilter);
            CRMIdFilterList.Add(CRMIdFilter);
        end;
    end;
}