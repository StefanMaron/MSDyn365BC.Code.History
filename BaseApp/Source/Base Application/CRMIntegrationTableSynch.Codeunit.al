codeunit 5340 "CRM Integration Table Synch."
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        "Field": Record "Field";
        OriginalJobQueueEntry: Record "Job Queue Entry";
        ConnectionName: Text;
        LatestModifiedOn: array[2] of DateTime;
        isHandled: Boolean;
    begin
        OnBeforeRun(Rec, IsHandled);
        If IsHandled then
            exit;

        ConnectionName := InitConnection();
        TestConnection();

        if "Int. Table UID Field Type" = Field.Type::Option then
            SynchOption(Rec)
        else begin
            SetOriginalCRMJobQueueEntryOnHold(Rec, OriginalJobQueueEntry);
            if Direction in [Direction::ToIntegrationTable, Direction::Bidirectional] then
                LatestModifiedOn[2] := PerformScheduledSynchToIntegrationTable(Rec);
            if Direction in [Direction::FromIntegrationTable, Direction::Bidirectional] then
                LatestModifiedOn[1] := PerformScheduledSynchFromIntegrationTable(Rec);
            UpdateTableMappingModifiedOn(Rec, LatestModifiedOn);
            SetOriginalCRMJobQueueEntryReady(Rec, OriginalJobQueueEntry);
        end;

        CloseConnection(ConnectionName);
    end;

    var
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        RecordNotFoundErr: Label 'Cannot find %1 record %2.', Comment = '%1 = Source table caption, %2 = The lookup value when searching for the source record';
        SourceRecordIsNotInMappingErr: Label 'Cannot find the mapping %2 in table %1.', Comment = '%1 Integration Table Mapping caption, %2 Integration Table Mapping Name';
        CannotDetermineSourceOriginErr: Label 'Cannot determine the source origin: %1.', Comment = '%1 the value of the source id';
        SynchronizeEmptySetErr: Label 'Attempted to synchronize an empty set of records.';
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        CRMProductName: Codeunit "CRM Product Name";
        TypeHelper: Codeunit "Type Helper";
        SupportedSourceType: Option ,RecordID,GUID;
        NoMappingErr: Label 'No mapping is set for %1.', Comment = '%1=Table Caption';
        OutOfMapFilter: Boolean;
        ModifiedByFieldMustBeGUIDErr: Label 'The field %1 in the table %2 must be of type GUID.', Comment = '%1 - a field name, %2 - a table name';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        ClearCacheTxt: Label 'Clear cache.', Locked = true;

    internal procedure InitConnection() ConnectionName: Text
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        initConnectionHandled: Boolean;
    begin
        CRMIntegrationManagement.OnInitCDSConnection(ConnectionName, initConnectionHandled);
        if initConnectionHandled then
            exit(ConnectionName);

        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL);

        ConnectionName := Format(CreateGuid);

        if CRMConnectionSetup."Is User Mapping Required" then
            ConnectionName := CRMConnectionSetup.RegisterUserConnection
        else
            CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        ClearCache;
    end;

    local procedure GetIntegrationUserId(): Guid
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationUserId: Guid;
        handled: Boolean;
    begin
        CRMIntegrationManagement.OnGetCDSIntegrationUserId(IntegrationUserId, handled);
        if handled then
            exit(IntegrationUserId);

        exit(CRMConnectionSetup.GetIntegrationUserID());
    end;

    internal procedure TestConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        testConnectionHandled: Boolean;
    begin
        CRMIntegrationManagement.OnTestCDSConnection(testConnectionHandled);
        if not testConnectionHandled then
            if not CRMConnectionSetup.TryReadSystemUsers then
                Error(GetLastErrorText);
    end;

    internal procedure CloseConnection(ConnectionName: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        closeConnectionHandled: Boolean;
    begin
        ClearCache;

        CRMIntegrationManagement.OnCloseCDSConnection(ConnectionName, closeConnectionHandled);
        if closeConnectionHandled then
            exit;

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure ClearCache()
    begin
        Session.LogMessage('0000CM6', ClearCacheTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        CRMIntTableSubscriber.ClearCache;
        Clear(CRMIntTableSubscriber);
    end;

    local procedure FindModifiedCRMRecords(var CRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        ModifyByFieldRef: FieldRef;
        ForceModify: Boolean;
        ModifiedByFilterNeeded: Boolean;
    begin
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        IntegrationTableMapping.SetIntRecordRefFilter(CRMRecordRef);
        // Exclude modifications by background job
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if not ForceModify then
            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
                ModifiedByFilterNeeded := not HasUnidirectionalFieldMappingFromIntegrationTable(IntegrationTableMapping)
            else
                ModifiedByFilterNeeded := true;
        if ModifiedByFilterNeeded then begin
            ModifyByFieldRef := CRMRecordRef.Field(GetModifyByFieldNo(IntegrationTableMapping."Integration Table ID"));
            if ModifyByFieldRef.Type <> FieldType::GUID then
                Error(ModifiedByFieldMustBeGUIDErr, ModifyByFieldRef.Name, CRMRecordRef.Name);
            ModifyByFieldRef.SetFilter('<>%1', GetIntegrationUserId());
        end;
        exit(CRMRecordRef.FindSet());
    end;

    local procedure FindFailedNotSkippedCRMRecords(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary; var CRMIDDictionary: Dictionary of [Guid, Boolean]): Boolean
    var
        CRMRecordRef: RecordRef;
        CRMTableView: Text;
        CRMIDFilter: Text;
        Found: Boolean;
        CRMIDFilterList: List of [Text];
    begin
        CRMTableView := IntegrationTableMapping.GetIntegrationTableFilter();
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        CRMRecordRef.SetView(CRMTableView);
        CRMIDFilter := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").GetFilter();
        CRMRecordRef.Close();
        if CRMIDFilter <> '' then
            exit(false); // Ignore failed not synched records if going to synch records selected by CRMID

        TempCRMIntegrationRecord.SetRange(Skipped, false);
        TempCRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. Result", TempCRMIntegrationRecord."Last Synch. Result"::Failure);
        if TempCRMIntegrationRecord.FindSet() then begin
            repeat
                if not CRMIDDictionary.ContainsKey(TempCRMIntegrationRecord."CRM ID") then
                    CRMIDDictionary.Add(TempCRMIntegrationRecord."CRM ID", true);
            until TempCRMIntegrationRecord.Next() = 0;
            GetIdFilterList(CRMIDDictionary, CRMIDFilterList);
            Found := CacheFilteredCRMRecords(CRMIDFilterList, IntegrationTableMapping, TempCRMRecordRef);
        end;
        TempCRMIntegrationRecord.SetRange(Skipped);
        TempCRMIntegrationRecord.SetRange("Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. Result");
        exit(Found);
    end;

    local procedure CacheFilteredCRMRecords(var CRMIDFilterList: List of [Text]; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMRecordRef: RecordRef): Boolean
    var
        OutlookSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        CRMRecordRef: RecordRef;
        CRMIDFilter: Text;
        Cached: Boolean;
    begin
        foreach CRMIDFilter in CRMIDFilterList do
            if CRMIDFilter <> '' then begin
                CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").SetFilter(CRMIDFilter);
                if CRMRecordRef.FindSet() then
                    repeat
                        OutlookSynchNAVMgt.CopyRecordReference(CRMRecordRef, TempCRMRecordRef, false);
                        Cached := true;
                    until CRMRecordRef.Next() = 0;
                CRMRecordRef.Close();
            end;
        exit(Cached);
    end;

    local procedure GetIdFilterList(var IdDictionary: Dictionary of [Guid, Boolean]; var IdFilterList: List of [Text]): Boolean
    var
        IdFilter: Text;
        I: Integer;
        Id: Guid;
        MaxCount: Integer;
    begin
        MaxCount := GetMaxNumberOfConditions();
        foreach Id in IdDictionary.Keys() do begin
            IdFilter += '|' + Id;
            I += 1;
            if I = MaxCount then begin
                IdFilter := IdFilter.TrimStart('|');
                IdFilterList.Add(IdFilter);
                IdFilter := '';
                I := 0;
            end;
        end;
        if IdFilter <> '' then begin
            IdFilter := IdFilter.TrimStart('|');
            IdFilterList.Add(IdFilter);
        end;
    end;

    local procedure CacheFilteredCRMTable(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        OutlookSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        CRMRecordRef: RecordRef;
        CRMID: Guid;
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
    begin
        TempCRMRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
        FindFailedNotSkippedCRMRecords(TempCRMRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord, FailedNotSkippedIdDictionary);
        if FindModifiedCRMRecords(CRMRecordRef, IntegrationTableMapping) then
            repeat
                CRMID := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
                if not FailedNotSkippedIdDictionary.ContainsKey(CRMID) then
                    OutlookSynchNAVMgt.CopyRecordReference(CRMRecordRef, TempCRMRecordRef, false);
            until CRMRecordRef.Next() = 0;
        CRMRecordRef.Close();
    end;

    local procedure HasUnidirectionalFieldMappingFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange(Direction, IntegrationFieldMapping.Direction::FromIntegrationTable);
        IntegrationFieldMapping.SetFilter("Integration Table Field No.", '>0');
        IntegrationFieldMapping.SetFilter(Status, '<>%1', IntegrationFieldMapping.Status::Disabled);
        exit(not IntegrationFieldMapping.IsEmpty());
    end;

    procedure GetOutOfMapFilter(): Boolean
    begin
        exit(OutOfMapFilter);
    end;

    local procedure GetSourceRecordRef(IntegrationTableMapping: Record "Integration Table Mapping"; SourceID: Variant; var RecordRef: RecordRef): Boolean
    var
        RecordID: RecordID;
        CRMID: Guid;
    begin
        case GetSourceType(SourceID) of
            SupportedSourceType::RecordID:
                begin
                    RecordID := SourceID;
                    if RecordID.TableNo = 0 then
                        Error(CannotDetermineSourceOriginErr, SourceID);
                    if not (RecordID.TableNo = IntegrationTableMapping."Table ID") then
                        Error(SourceRecordIsNotInMappingErr, IntegrationTableMapping.TableCaption, IntegrationTableMapping.Name);
                    if not RecordRef.Get(RecordID) then
                        Error(RecordNotFoundErr, RecordRef.Caption, Format(RecordID, 0, 1));
                    exit(IntegrationTableMapping.FindFilteredRec(RecordRef, OutOfMapFilter));
                end;
            SupportedSourceType::GUID:
                begin
                    CRMID := SourceID;
                    if IsNullGuid(CRMID) then
                        Error(CannotDetermineSourceOriginErr, SourceID);
                    if not IntegrationTableMapping.GetRecordRef(CRMID, RecordRef) then
                        Error(RecordNotFoundErr, IntegrationTableMapping.GetExtendedIntegrationTableCaption, CRMID);
                    exit(IntegrationTableMapping.FindFilteredRec(RecordRef, OutOfMapFilter));
                end;
            else
                Error(CannotDetermineSourceOriginErr, SourceID);
        end;
    end;

    local procedure GetSourceType(Source: Variant): Integer
    begin
        if Source.IsRecordId then
            exit(SupportedSourceType::RecordID);
        if Source.IsGuid then
            exit(SupportedSourceType::GUID);
        exit(0);
    end;

    local procedure FillCodeBufferFromOption(FieldRef: FieldRef; var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        TempNameValueBufferWithValue: Record "Name/Value Buffer" temporary;
    begin
        CollectOptionValues(FieldRef.OptionMembers, TempNameValueBuffer, FieldRef);
        CollectOptionValues(FieldRef.OptionCaption, TempNameValueBufferWithValue, FieldRef);
        MergeBuffers(TempNameValueBuffer, TempNameValueBufferWithValue);
        exit(TempNameValueBuffer.FindSet);
    end;

    local procedure FindModifiedLocalRecords(var RecRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        SystemModifiedAtFieldRef: FieldRef;
    begin
        RecRef.Open(IntegrationTableMapping."Table ID");
        IntegrationTableMapping.SetRecordRefFilter(RecRef);
        if IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." <> 0DT then begin
            SystemModifiedAtFieldRef := RecRef.Field(RecRef.SystemModifiedAtNo());
            SystemModifiedAtFieldRef.SetFilter('>%1', IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.");
        end;

        exit(RecRef.FindSet());
    end;

    local procedure FindFailedNotSkippedLocalRecords(var SystemIdDictionary: Dictionary of [Guid, Boolean]; IntegrationTableMapping: Record "Integration Table Mapping"; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary): Boolean
    var
        LocalRecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        LocalTableView: Text;
        I: Integer;
        NoFilterOnPK: Boolean;
    begin
        LocalTableView := IntegrationTableMapping.GetTableFilter();
        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
        LocalRecordRef.SetView(LocalTableView);

        if LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).GetFilter() <> '' then
            exit(false); // Ignore failed not synched records if going to synch records selected by systemId

        PrimaryKeyRef := LocalRecordRef.KeyIndex(1);
        for I := 1 to PrimaryKeyRef.FieldCount() do
            if LocalRecordRef.Field(PrimaryKeyRef.FieldIndex(I).Number()).GetFilter() = '' then begin
                NoFilterOnPK := true;
                break;
            end;
        if not NoFilterOnPK then
            exit(false); // Ignore failed not synched records if going to synch records selected by primary key

        TempCRMIntegrationRecord.SetRange(Skipped, false);
        TempCRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. CRM Result", TempCRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        if TempCRMIntegrationRecord.FindSet() then
            repeat
                if not SystemIdDictionary.ContainsKey(TempCRMIntegrationRecord."Integration ID") then
                    SystemIdDictionary.Add(TempCRMIntegrationRecord."Integration ID", true);
            until TempCRMIntegrationRecord.Next() = 0;
        TempCRMIntegrationRecord.SetRange(Skipped);
        TempCRMIntegrationRecord.SetRange("Table ID");
        TempCRMIntegrationRecord.SetRange("Last Synch. CRM Result");
        exit(SystemIdDictionary.Count() > 0);
    end;

    local procedure CollectOptionValues(OptionString: Text; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; FieldRef: FieldRef)
    var
        CommaPos: Integer;
        OptionValue: Text;
        OptionValueInt: Integer;
    begin
        OptionValueInt := 1;
        TempNameValueBuffer.DeleteAll();
        while StrLen(OptionString) > 0 do begin
            CommaPos := StrPos(OptionString, ',');
            if CommaPos = 0 then begin
                OptionValue := OptionString;
                OptionString := '';
            end else begin
                OptionValue := CopyStr(OptionString, 1, CommaPos - 1);
                OptionString := CopyStr(OptionString, CommaPos + 1);
            end;
            if DelChr(OptionValue, '=', ' ') <> '' then begin
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID := FieldRef.GetEnumValueOrdinal(OptionValueInt);
                TempNameValueBuffer.Name := CopyStr(OptionValue, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Insert
            end;
            OptionValueInt += 1;
        end;
    end;

    local procedure MergeBuffers(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var TempNameValueBufferWithValue: Record "Name/Value Buffer" temporary)
    begin
        with TempNameValueBuffer do begin
            if FindSet then
                repeat
                    if TempNameValueBufferWithValue.Get(ID) then begin
                        Value := TempNameValueBufferWithValue.Name;
                        Modify
                    end;
                until Next = 0;
            TempNameValueBufferWithValue.DeleteAll();
        end;
    end;

    procedure SynchOption(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        "Field": Record "Field";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
        NewPK: Text;
    begin
        if TypeHelper.GetField(
             IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", Field)
        then
            if Field.Type = Field.Type::Option then begin
                RecordRef.Open(Field.TableNo);
                FieldRef := RecordRef.Field(Field."No.");
                RecordRef.Close;
                if FillCodeBufferFromOption(FieldRef, TempNameValueBuffer) then begin
                    CRMOptionMapping.SetRange("Table ID", IntegrationTableMapping."Table ID");
                    CRMOptionMapping.DeleteAll();

                    RecordRef.Open(IntegrationTableMapping."Table ID");
                    KeyRef := RecordRef.KeyIndex(1);
                    FieldRef := KeyRef.FieldIndex(1);
                    repeat
                        NewPK := CopyStr(TempNameValueBuffer.Name, 1, FieldRef.Length);
                        FieldRef.SetRange(NewPK);
                        if not RecordRef.FindFirst then begin
                            RecordRef.Init();
                            FieldRef.Value := NewPK;
                            RecordRef.Insert(true);
                        end;

                        CRMOptionMapping.Init();
                        CRMOptionMapping."Record ID" := RecordRef.RecordId;
                        CRMOptionMapping."Option Value" := TempNameValueBuffer.ID;
                        CRMOptionMapping."Option Value Caption" := TempNameValueBuffer.Value;
                        CRMOptionMapping."Table ID" := IntegrationTableMapping."Table ID";
                        CRMOptionMapping."Integration Table ID" := IntegrationTableMapping."Integration Table ID";
                        CRMOptionMapping."Integration Field ID" := IntegrationTableMapping."Integration Table UID Fld. No.";
                        CRMOptionMapping.Insert();
                    until TempNameValueBuffer.Next = 0;
                    RecordRef.Close;
                end;
            end;
    end;

    procedure SynchRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceID: Variant; ForceModify: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean) JobID: Guid
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        FromRecordRef: RecordRef;
        ToRecordRef: RecordRef;
    begin
        if GetSourceRecordRef(IntegrationTableMapping, SourceID, FromRecordRef) then begin // sets the global OutOfMapFilter
            JobID := IntegrationTableSynch.BeginIntegrationSynchJob(TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, FromRecordRef.Number);
            if not IsNullGuid(JobID) then begin
                IntegrationTableSynch.Synchronize(FromRecordRef, ToRecordRef, ForceModify, IgnoreSynchOnlyCoupledRecords);
                IntegrationTableSynch.EndIntegrationSynchJob;
            end;
        end;
    end;

    procedure SynchRecordsToIntegrationTable(RecordsToSynchRecordRef: RecordRef; IgnoreChanges: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean) JobID: Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        IntegrationRecordRef: RecordRef;
    begin
        if not IntegrationTableMapping.FindMappingForTable(RecordsToSynchRecordRef.Number) then
            Error(NoMappingErr, RecordsToSynchRecordRef.Name);

        if not RecordsToSynchRecordRef.FindLast then
            Error(SynchronizeEmptySetErr);

        JobID :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, RecordsToSynchRecordRef.Number);
        if not IsNullGuid(JobID) then begin
            repeat
                IntegrationTableSynch.Synchronize(RecordsToSynchRecordRef, IntegrationRecordRef, IgnoreChanges, IgnoreSynchOnlyCoupledRecords)
            until RecordsToSynchRecordRef.Next(-1) = 0;
            IntegrationTableSynch.EndIntegrationSynchJob;
        end;
    end;

    local procedure SynchNAVTableToCRM(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestModifiedOn: DateTime
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        SourceRecordRef: RecordRef;
        RecordSystemId: Guid;
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
    begin
        LatestModifiedOn := 0DT;
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);

        SourceRecordRef.Open(IntegrationTableMapping."Table ID");
        if FindFailedNotSkippedLocalRecords(FailedNotSkippedIdDictionary, IntegrationTableMapping, TempCRMIntegrationRecord) then
            foreach RecordSystemId in FailedNotSkippedIdDictionary.Keys() do
                if SourceRecordRef.GetBySystemId(RecordSystemId) then
                    SynchNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestModifiedOn);
        SourceRecordRef.Close();

        if FindModifiedLocalRecords(SourceRecordRef, IntegrationTableMapping) then
            repeat
                RecordSystemId := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
                if not FailedNotSkippedIdDictionary.ContainsKey(RecordSystemId) then
                    SynchNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestModifiedOn);
            until SourceRecordRef.Next() = 0;

        if LatestModifiedOn = 0DT then
            LatestModifiedOn := IntegrationTableSynch.GetStartDateTime();
    end;

    local procedure SynchNAVRecordToCRM(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary; var LatestModifiedOn: DateTime)
    var
        DestinationRecordRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
        ModifiedOn: DateTime;
    begin
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        IgnoreRecord := false;
        OnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
        if not IgnoreRecord then begin
            SystemIdFieldRef := SourceRecordRef.Field(SourceRecordRef.SystemIdNo);
            if not TempCRMIntegrationRecord.IsIntegrationIdCoupled(SystemIdFieldRef.Value()) then
                IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
            if not IgnoreRecord then
                if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, ForceModify, false) then begin
                    ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
                    if ModifiedOn > LatestModifiedOn then
                        LatestModifiedOn := ModifiedOn;
                end;
        end;
    end;

    local procedure SynchCRMTableToNAV(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var SourceRecordRef: RecordRef) LatestModifiedOn: DateTime
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        OutlookSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
        DestinationRecordRef: RecordRef;
        CloneSourceRecordRef: RecordRef;
        ModifiedOn: DateTime;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
    begin
        LatestModifiedOn := 0DT;
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
        CacheFilteredCRMTable(SourceRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord);
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if SourceRecordRef.FindSet then
            repeat
                CloneSourceRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
                OutlookSynchNAVMgt.CopyRecordReference(SourceRecordRef, CloneSourceRecordRef, false);
                IgnoreRecord := false;
                OnQueryPostFilterIgnoreRecord(CloneSourceRecordRef, IgnoreRecord);
                if not IgnoreRecord then begin
                    if TempCRMIntegrationRecord.IsCRMRecordRefCoupled(CloneSourceRecordRef) then
                        TempCRMIntegrationRecord.Delete
                    else
                        IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
                    if not IgnoreRecord then
                        if IntegrationTableSynch.Synchronize(CloneSourceRecordRef, DestinationRecordRef, ForceModify, false) then begin
                            ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, CloneSourceRecordRef);
                            if ModifiedOn > LatestModifiedOn then
                                LatestModifiedOn := ModifiedOn;
                        end;
                end;
                CloneSourceRecordRef.Close();
            until SourceRecordRef.Next = 0;
        if LatestModifiedOn = 0DT then
            LatestModifiedOn := IntegrationTableSynch.GetStartDateTime;
    end;

    local procedure GetModifyByFieldNo(CRMTableID: Integer): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, CRMTableID);
        Field.SetRange(FieldName, 'ModifiedBy'); // All CRM tables should have "ModifiedBy" field
        Field.FindFirst;
        exit(Field."No.");
    end;

    local procedure PerformScheduledSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
    begin
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::ToIntegrationTable);
            LatestModifiedOn := SynchNAVTableToCRM(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
    end;

    local procedure PerformScheduledSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        JobId: Guid;
    begin
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::FromIntegrationTable);
            LatestModifiedOn := SynchCRMTableToNAV(IntegrationTableMapping, IntegrationTableSynch, SourceRecordRef);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    internal procedure SetOriginalCRMJobQueueEntryOnHold(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry")
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IntegrationTableMapping."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(IntegrationTableMapping."Parent Name");
            JobQueueEntry.SetRange("Record ID to Process", OriginalIntegrationTableMapping.RecordId);
            if JobQueueEntry.FindFirst then
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
        end;
    end;

    local procedure SetOriginalCRMJobQueueEntryReady(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry")
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IntegrationTableMapping."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(IntegrationTableMapping."Parent Name");
            OriginalIntegrationTableMapping.CopyModifiedOnFilters(IntegrationTableMapping);
            if JobQueueEntry.FindFirst then
                JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        end;
    end;

    local procedure UpdateTableMappingModifiedOn(var IntegrationTableMapping: Record "Integration Table Mapping"; ModifiedOn: array[2] of DateTime)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTableMappingModifiedOn(IntegrationTableMapping, ModifiedOn, IsHandled);
        if IsHandled then
            exit;

        with IntegrationTableMapping do begin
            if ModifiedOn[1] > "Synch. Modified On Filter" then
                "Synch. Modified On Filter" := ModifiedOn[1];
            if ModifiedOn[2] > "Synch. Int. Tbl. Mod. On Fltr." then
                "Synch. Int. Tbl. Mod. On Fltr." := ModifiedOn[2];
            Modify(true);
        end;
    end;

    internal procedure CreateCRMIntegrationRecordClone(ForTable: Integer; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        TempCRMIntegrationRecord.Reset();
        TempCRMIntegrationRecord.DeleteAll();

        CRMIntegrationManagement.RepairBrokenCouplings();
        CRMIntegrationRecord.SetRange("Table ID", ForTable);
        if not CRMIntegrationRecord.FindSet then
            exit;

        repeat
            TempCRMIntegrationRecord.Copy(CRMIntegrationRecord, false);
            TempCRMIntegrationRecord.Insert();
        until CRMIntegrationRecord.Next = 0;
    end;

    local procedure GetMaxNumberOfConditions(): Integer
    begin
        // CRM SDK allows max 499 conditions. A twice smaller limit is used to be on the safe side.
        exit(499 DIV 2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTableMappingModifiedOn(var IntegrationTableMapping: Record "Integration Table Mapping"; ModifiedOn: array[2] of DateTime; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    local procedure IgnoreCompanyContactOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        Contact: Record Contact;
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number = DATABASE::Contact then begin
            SourceRecordRef.SetTable(Contact);
            if Contact.Type = Contact.Type::Company then
                IgnoreRecord := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyJobQueueEntry(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.OnBeforeModifyJobQueueEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job", 'OnCanBeRemoved', '', false, false)]
    local procedure OnSynchJobEntryCanBeRemoved(IntegrationSynchJob: Record "Integration Synch. Job"; var AllowRemoval: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if AllowRemoval then
            exit;

        with CRMIntegrationRecord do begin
            SetRange(Skipped, true);
            SetRange("Last Synch. Job ID", IntegrationSynchJob.ID);
            if IsEmpty then begin
                SetRange("Last Synch. Job ID");
                SetRange("Last Synch. CRM Job ID", IntegrationSynchJob.ID);
                if IsEmpty() then
                    AllowRemoval := true;
            end;
        end;
    end;
}

