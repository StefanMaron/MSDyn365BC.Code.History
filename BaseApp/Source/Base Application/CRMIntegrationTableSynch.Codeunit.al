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
        PrevStatus: Option;
    begin
        OnBeforeRun(Rec, IsHandled);
        If IsHandled then
            exit;

        ConnectionName := InitConnection();
        TestConnection();

        if "Int. Table UID Field Type" = Field.Type::Option then
            SynchOption(Rec)
        else begin
            SetOriginalCRMJobQueueEntryOnHold(Rec, OriginalJobQueueEntry, PrevStatus);
            if Direction in [Direction::ToIntegrationTable, Direction::Bidirectional] then
                LatestModifiedOn[DateType::Local] := PerformScheduledSynchToIntegrationTable(Rec);
            if Direction in [Direction::FromIntegrationTable, Direction::Bidirectional] then
                LatestModifiedOn[DateType::Integration] := PerformScheduledSynchFromIntegrationTable(Rec);
            UpdateTableMappingModifiedOn(Rec, LatestModifiedOn);
            SetOriginalCRMJobQueueEntryStatus(Rec, OriginalJobQueueEntry, PrevStatus);
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
        DateType: Option ,Integration,Local;
        NoMappingErr: Label 'No mapping is set for %1.', Comment = '%1=Table Caption';
        OutOfMapFilter: Boolean;
        ModifiedByFieldMustBeGUIDErr: Label 'The field %1 in the table %2 must be of type GUID.', Comment = '%1 - a field name, %2 - a table name';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        ClearCacheTxt: Label 'Clear cache.', Locked = true;
        CopyRecordRefFailedTxt: Label 'Copy record reference failed. Dataverse ID: %1', Locked = true, Comment = '%1 - Dataverse record id';

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

    internal procedure SplitLocalTableFilter(var IntegrationTableMapping: Record "Integration Table Mapping"; var TableFilterList: List of [Text]): Boolean
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(IntegrationTableMapping."Table ID", true);
        exit(SplitTableFilter(IntegrationTableMapping."Table ID", RecordRef.SystemIdNo(), IntegrationTableMapping.GetTableFilter(), TableFilterList));
    end;

    internal procedure SplitIntegrationTableFilter(var IntegrationTableMapping: Record "Integration Table Mapping"; var TableFilterList: List of [Text]): Boolean
    begin
        exit(SplitTableFilter(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", IntegrationTableMapping.GetIntegrationTableFilter(), TableFilterList));
    end;

    internal procedure SplitTableFilter(TableId: Integer; FieldNo: Integer; TableFilter: Text; var TableFilterList: List of [Text]): Boolean
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldFilter: Text;
        FieldFilterList: List of [Text];
    begin
        RecordRef.Open(TableId, true);
        RecordRef.SetView(TableFilter);
        FieldRef := RecordRef.Field(FieldNo);
        FieldFilter := FieldRef.GetFilter();
        if not SplitFieldFilter(FieldFilter, FieldFilterList) then begin
            TableFilterList.Add(TableFilter);
            exit(false);
        end;
        foreach FieldFilter in FieldFilterList do begin
            FieldRef.SetFilter(FieldFilter);
            TableFilter := RecordRef.GetView();
            TableFilterList.Add(TableFilter);
        end;
        exit(true);
    end;

    local procedure SplitFieldFilter(FieldFilter: Text; var FilterList: List of [Text]): Boolean
    var
        ConditionList: List of [Text];
        Condition: Text;
        PartFilter: Text;
        Length: Integer;
        Id: Guid;
        MaxCount: Integer;
        I: Integer;
        CannotSplit: Boolean;
    begin
        MaxCount := GetMaxNumberOfConditions();
        ConditionList := FieldFilter.Split('|');
        if ConditionList.Count() > MaxCount then begin
            foreach Condition in ConditionList do begin
                I += 1;
                if I = 1 then
                    Length := StrLen(Condition)
                else
                    if Length <> StrLen(Condition) then begin
                        CannotSplit := true;
                        break;
                    end;
                if not Evaluate(Id, Condition) then begin
                    CannotSplit := true;
                    break;
                end;
                if PartFilter <> '' then
                    PartFilter += '|' + Condition
                else
                    PartFilter := Condition;
                if I = MaxCount then begin
                    FilterList.Add(PartFilter);
                    PartFilter := '';
                    I := 0;
                end;
            end;
            if PartFilter <> '' then
                FilterList.Add(PartFilter);
        end else
            FilterList.Add(FieldFilter);

        if not CannotSplit then
            exit(true);

        Clear(FilterList);
        FilterList.Add(FieldFilter);
        exit(false);
    end;

    local procedure IsModifiedByFilterNeeded(IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        if IntegrationTableMapping."Delete After Synchronization" then
            exit(false);
        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
            exit(not HasUnidirectionalFieldMappingFromIntegrationTable(IntegrationTableMapping));
        exit(true);
    end;

    local procedure FindModifiedCRMRecords(var TempCRMRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean])
    var
        CRMRecordRef: RecordRef;
        CRMID: Guid;
        ModifiedByFilterNeeded: Boolean;
        TableFilter: Text;
        FilterList: List of [Text];
    begin
        ModifiedByFilterNeeded := IsModifiedByFilterNeeded(IntegrationTableMapping);
        SplitIntegrationTableFilter(IntegrationTableMapping, FilterList);
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        foreach TableFilter in FilterList do begin
            SetIntRecordRefFilter(CRMRecordRef, TableFilter, ModifiedByFilterNeeded, IntegrationTableMapping);
            if CRMRecordRef.FindSet() then
                repeat
                    CRMID := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
                    if not FailedNotSkippedIdDictionary.ContainsKey(CRMID) then
                        if not TryCopyRecordReference(CRMRecordRef, TempCRMRecordRef, false) then
                            Session.LogMessage('0000ECC', StrSubstNo(CopyRecordRefFailedTxt, CRMID), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                until CRMRecordRef.Next() = 0;
        end;
        CRMRecordRef.Close();
    end;

    [TryFunction]
    local procedure TryCopyRecordReference(FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    begin
        CopyRecordReference(FromRec, ToRec, ValidateOnInsert);
    end;

    local procedure CopyRecordReference(FromRec: RecordRef; var ToRec: RecordRef; ValidateOnInsert: Boolean)
    var
        FromField: FieldRef;
        ToField: FieldRef;
        Counter: Integer;
    begin
        if FromRec.Number <> ToRec.Number then
            exit;

        ToRec.Init();
        for Counter := 1 to FromRec.FieldCount do begin
            FromField := FromRec.FieldIndex(Counter);
            if not (FromField.Type in [FieldType::BLOB, FieldType::TableFilter]) then begin
                ToField := ToRec.Field(FromField.Number);
                ToField.Value := FromField.Value;
            end;
        end;
        ToRec.Insert(ValidateOnInsert);
    end;

    local procedure SetIntRecordRefFilter(var IntRecordRef: RecordRef; TableFilter: Text; ModifiedByFilterNeeded: Boolean; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        ModifiedOnFieldRef: FieldRef;
        ModifyByFieldRef: FieldRef;
        ModifyByFieldNo: Integer;
    begin
        if TableFilter <> '' then
            IntRecordRef.SetView(TableFilter);

        if IntegrationTableMapping."Synch. Modified On Filter" <> 0DT then begin
            ModifiedOnFieldRef := IntRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            ModifiedOnFieldRef.SetFilter('>%1', IntegrationTableMapping."Synch. Modified On Filter" - 999);
        end;

        if ModifiedByFilterNeeded then begin
            ModifyByFieldNo := GetModifyByFieldNo(IntegrationTableMapping."Integration Table ID");
            ModifyByFieldRef := IntRecordRef.Field(ModifyByFieldNo);
            if ModifyByFieldRef.Type <> FieldType::GUID then
                Error(ModifiedByFieldMustBeGUIDErr, ModifyByFieldRef.Name, IntRecordRef.Name);
            ModifyByFieldRef.SetFilter('<>%1', GetIntegrationUserId())
        end;
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
                        CopyRecordReference(CRMRecordRef, TempCRMRecordRef, false);
                        Cached := true;
                    until CRMRecordRef.Next() = 0;
                CRMRecordRef.Close();
            end;
        exit(Cached);
    end;

    local procedure GetIdFilterList(var IdDictionary: Dictionary of [Guid, Boolean]; var IdFilterList: List of [Text])
    var
        IdList: List of [Guid];
    begin
        IdList := IdDictionary.Keys();
        GetIdFilterList(IdList, IdFilterList);
    end;

    internal procedure GetIdFilterList(var IdList: List of [Guid]; var IdFilterList: List of [Text])
    var
        IdFilter: Text;
        I: Integer;
        Id: Guid;
        MaxCount: Integer;
    begin
        MaxCount := GetMaxNumberOfConditions();
        foreach Id in IdList do begin
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
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
    begin
        TempCRMRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
        FindFailedNotSkippedCRMRecords(TempCRMRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord, FailedNotSkippedIdDictionary);
        FindModifiedCRMRecords(TempCRMRecordRef, IntegrationTableMapping, FailedNotSkippedIdDictionary);
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
        CollectEnumValues(FieldRef, TempNameValueBuffer);
        exit(TempNameValueBuffer.FindSet);
    end;

    local procedure CollectEnumValues(FieldRef: FieldRef; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        OptionValue: Text;
        OptionValueInt: Integer;
    begin
        TempNameValueBuffer.DeleteAll();
        for OptionValueInt := 1 to FieldRef.EnumValueCount() do begin
            OptionValue := FieldRef.GetEnumValueName(OptionValueInt);
            if DelChr(OptionValue, '=', ' ') <> '' then begin
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID := FieldRef.GetEnumValueOrdinal(OptionValueInt);
                TempNameValueBuffer.Name := CopyStr(OptionValue, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Value := CopyStr(FieldRef.GetEnumValueCaption(OptionValueInt), 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Insert();
            end;
        end;
    end;

    local procedure FindModifiedLocalRecords(var RecRef: RecordRef; TableFilter: Text; IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        SystemModifiedAtFieldRef: FieldRef;
    begin
        if TableFilter <> '' then
            RecRef.SetView(TableFilter);
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
                    until TempNameValueBuffer.Next() = 0;
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

    local procedure SynchNAVTableToCRM(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestLocalModifiedOn: DateTime
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        SourceRecordRef: RecordRef;
        RecordSystemId: Guid;
        FailedNotSkippedIdDictionary: Dictionary of [Guid, Boolean];
        FilterList: List of [Text];
        TableFilter: Text;
    begin
        LatestLocalModifiedOn := 0DT;
        SplitLocalTableFilter(IntegrationTableMapping, FilterList);
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);

        SourceRecordRef.Open(IntegrationTableMapping."Table ID");
        if FindFailedNotSkippedLocalRecords(FailedNotSkippedIdDictionary, IntegrationTableMapping, TempCRMIntegrationRecord) then
            foreach RecordSystemId in FailedNotSkippedIdDictionary.Keys() do
                if SourceRecordRef.GetBySystemId(RecordSystemId) then
                    SyncNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestLocalModifiedOn);

        foreach TableFilter in FilterList do
            if FindModifiedLocalRecords(SourceRecordRef, TableFilter, IntegrationTableMapping) then
                repeat
                    RecordSystemId := SourceRecordRef.Field(SourceRecordRef.SystemIdNo()).Value();
                    if not FailedNotSkippedIdDictionary.ContainsKey(RecordSystemId) then
                        SyncNAVRecordToCRM(SourceRecordRef, IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord, LatestLocalModifiedOn);
                until SourceRecordRef.Next() = 0;

        OnSynchNAVTableToCRMOnBeforeCheckLatestModifiedOn(SourceRecordRef, IntegrationTableMapping);
        SourceRecordRef.Close();
    end;

    procedure SyncNAVRecordToCRM(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary; var LatestLocalModifiedOn: DateTime)
    var
        DestinationRecordRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
        LocalModifiedOn: DateTime;
    begin
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        IgnoreRecord := false;
        OnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
        if not IgnoreRecord then begin
            SystemIdFieldRef := SourceRecordRef.Field(SourceRecordRef.SystemIdNo);
            if not TempCRMIntegrationRecord.IsIntegrationIdCoupled(SystemIdFieldRef.Value()) then
                IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
            if not IgnoreRecord then
                IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, ForceModify, false);
        end;
        // collect latest modified time across all local records including not synched
        LocalModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
        if LocalModifiedOn > LatestLocalModifiedOn then
            LatestLocalModifiedOn := LocalModifiedOn;
    end;

    local procedure SynchCRMTableToNAV(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var SourceRecordRef: RecordRef) LatestIntegrationModifiedOn: DateTime
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        DestinationRecordRef: RecordRef;
        CloneSourceRecordRef: RecordRef;
        IntegrationModifiedOn: DateTime;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
    begin
        LatestIntegrationModifiedOn := 0DT;
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
        CacheFilteredCRMTable(SourceRecordRef, IntegrationTableMapping, TempCRMIntegrationRecord);
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if SourceRecordRef.FindSet() then
            repeat
                CloneSourceRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
                CopyRecordReference(SourceRecordRef, CloneSourceRecordRef, false);
                IgnoreRecord := false;
                OnQueryPostFilterIgnoreRecord(CloneSourceRecordRef, IgnoreRecord);
                if not IgnoreRecord then begin
                    if TempCRMIntegrationRecord.IsCRMRecordRefCoupled(CloneSourceRecordRef) then
                        TempCRMIntegrationRecord.Delete
                    else
                        IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
                    if not IgnoreRecord then
                        IntegrationTableSynch.Synchronize(CloneSourceRecordRef, DestinationRecordRef, ForceModify, false);
                end;
                // collect latest modified time across all integration records including not synched
                IntegrationModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, CloneSourceRecordRef);
                if IntegrationModifiedOn > LatestIntegrationModifiedOn then
                    LatestIntegrationModifiedOn := IntegrationModifiedOn;
                CloneSourceRecordRef.Close();
            until SourceRecordRef.Next() = 0;
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

    local procedure PerformScheduledSynchToIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestLocalModifiedOn: DateTime
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
            LatestLocalModifiedOn := SynchNAVTableToCRM(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
    end;

    local procedure PerformScheduledSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping") LatestIntegrationModifiedOn: DateTime
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
            LatestIntegrationModifiedOn := SynchCRMTableToNAV(IntegrationTableMapping, IntegrationTableSynch, SourceRecordRef);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    local procedure SetOriginalCRMJobQueueEntryOnHold(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry"; var PrevStatus: Option)
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IntegrationTableMapping."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(IntegrationTableMapping."Parent Name");
            JobQueueEntry.SetRange("Record ID to Process", OriginalIntegrationTableMapping.RecordId);
            if JobQueueEntry.FindFirst() then begin
                PrevStatus := JobQueueEntry.Status;
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            end;
        end;
    end;

    local procedure SetOriginalCRMJobQueueEntryStatus(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry"; Status: Option)
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IntegrationTableMapping."Full Sync is Running" then begin
            OriginalIntegrationTableMapping.Get(IntegrationTableMapping."Parent Name");
            OriginalIntegrationTableMapping.CopyModifiedOnFilters(IntegrationTableMapping);
            if JobQueueEntry.FindFirst() then
                JobQueueEntry.SetStatus(Status);
        end;
    end;

    local procedure UpdateTableMappingModifiedOn(var IntegrationTableMapping: Record "Integration Table Mapping"; LatestModifiedOn: array[2] of DateTime)
    var
        IsHandled: Boolean;
        IsChanged: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTableMappingModifiedOn(IntegrationTableMapping, LatestModifiedOn, IsHandled);
        if IsHandled then
            exit;

        if LatestModifiedOn[DateType::Integration] > IntegrationTableMapping."Synch. Modified On Filter" then begin
            IntegrationTableMapping."Synch. Modified On Filter" := LatestModifiedOn[DateType::Integration];
            IsChanged := true;
        end;
        if LatestModifiedOn[DateType::Local] > IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." then begin
            IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := LatestModifiedOn[DateType::Local];
            IsChanged := true;
        end;
        if IsChanged then
            IntegrationTableMapping.Modify(true);
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
        until CRMIntegrationRecord.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetMaxNumberOfConditions(): Integer
    var
        Handled: Boolean;
        MaxNumberOfConditions: Integer;
    begin
        OnGetMaxNumberOfConditions(Handled, MaxNumberOfConditions);
        if Handled then
            exit(MaxNumberOfConditions);

        // CRM SDK allows max 499 conditions. A smaller limit is used to be on the safe side.
        exit(400);
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

    [IntegrationEvent(false, false)]
    local procedure OnSynchNAVTableToCRMOnBeforeCheckLatestModifiedOn(var SourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMaxNumberOfConditions(var Handled: Boolean; var Value: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    local procedure IgnoreCompanyContactOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        Contact: Record Contact;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number = DATABASE::Contact then begin
            if CRMSynchHelper.IsContactTypeCheckIgnored() then
                exit;
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
        if Rec.IsTemporary() then
            exit;

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
            if IsEmpty() then begin
                SetRange("Last Synch. Job ID");
                SetRange("Last Synch. CRM Job ID", IntegrationSynchJob.ID);
                if IsEmpty() then
                    AllowRemoval := true;
            end;
        end;
    end;
}

