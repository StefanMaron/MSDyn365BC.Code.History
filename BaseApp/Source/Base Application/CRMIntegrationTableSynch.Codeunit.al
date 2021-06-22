codeunit 5340 "CRM Integration Table Synch."
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        "Field": Record "Field";
        OriginalJobQueueEntry: Record "Job Queue Entry";
        ConnectionName: Text;
        LatestModifiedOn: array[2] of DateTime;
        testConnectionHandled: Boolean;
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
                LatestModifiedOn[1] :=
                  PerformScheduledSynchFromIntegrationTable(Rec, GetIntegrationUserId());
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

    local procedure InitConnection() ConnectionName: Text
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

    local procedure TestConnection()
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

    local procedure CloseConnection(ConnectionName: Text)
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
        CRMIntTableSubscriber.ClearCache;
        Clear(CRMIntTableSubscriber);
    end;

    local procedure CacheTable(var RecordRef: RecordRef; var TempRecordRef: RecordRef)
    var
        OutlookSynchNAVMgt: Codeunit "Outlook Synch. NAV Mgt";
    begin
        TempRecordRef.Open(RecordRef.Number, true);
        if RecordRef.FindSet then
            repeat
                OutlookSynchNAVMgt.CopyRecordReference(RecordRef, TempRecordRef, false);
            until RecordRef.Next = 0;
        RecordRef.Close;
    end;

    local procedure CacheFilteredCRMTable(TempSourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationUserId: Guid)
    var
        CRMRecordRef: RecordRef;
        ModifyByFieldRef: FieldRef;
    begin
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        IntegrationTableMapping.SetIntRecordRefFilter(CRMRecordRef);
        // Exclude modifications by background job
        if not IntegrationTableMapping."Delete After Synchronization" then begin
            ModifyByFieldRef := CRMRecordRef.Field(GetModifyByFieldNo(IntegrationTableMapping."Integration Table ID"));
            if ModifyByFieldRef.Type <> FieldType::GUID then
                Error(ModifiedByFieldMustBeGUIDErr, ModifyByFieldRef.Name, CRMRecordRef.Name);
            ModifyByFieldRef.SetFilter('<>%1', IntegrationUserId);
        end;
        CacheTable(CRMRecordRef, TempSourceRecordRef);
        CRMRecordRef.Close;
    end;

    local procedure CacheFilteredNAVTable(TempSourceRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(IntegrationTableMapping."Table ID");
        IntegrationTableMapping.SetRecordRefFilter(SourceRecordRef);
        CacheTable(SourceRecordRef, TempSourceRecordRef);
        SourceRecordRef.Close;
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

    local procedure FindModifiedIntegrationRecords(var IntegrationRecord: Record "Integration Record"; IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        IntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
        if IntegrationTableMapping."Synch. Modified On Filter" <> 0DT then
            IntegrationRecord.SetFilter("Modified On", '>%1', IntegrationTableMapping."Synch. Modified On Filter");
        exit(IntegrationRecord.FindSet);
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
        IntegrationRecord: Record "Integration Record";
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
        ModifiedOn: DateTime;
    begin
        LatestModifiedOn := 0DT;
        if FindModifiedIntegrationRecords(IntegrationRecord, IntegrationTableMapping) then begin
            CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
            CacheFilteredNAVTable(SourceRecordRef, IntegrationTableMapping);
            ForceModify := IntegrationTableMapping."Delete After Synchronization";
            repeat
                IgnoreRecord := false;
                if SourceRecordRef.Get(IntegrationRecord."Record ID") then begin
                    OnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
                    if not IgnoreRecord then begin
                        if not TempCRMIntegrationRecord.IsIntegrationIdCoupled(IntegrationRecord."Integration ID") then
                            IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
                        if not IgnoreRecord then
                            if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, ForceModify, false) then begin
                                ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
                                if ModifiedOn > LatestModifiedOn then
                                    LatestModifiedOn := ModifiedOn;
                            end;
                    end;
                end;
            until IntegrationRecord.Next = 0;
        end;
        if LatestModifiedOn = 0DT then
            LatestModifiedOn := IntegrationTableSynch.GetStartDateTime;
    end;

    local procedure SynchCRMTableToNAV(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationUserId: Guid; var IntegrationTableSynch: Codeunit "Integration Table Synch.") LatestModifiedOn: DateTime
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        ModifiedOn: DateTime;
        IgnoreRecord: Boolean;
        ForceModify: Boolean;
    begin
        LatestModifiedOn := 0DT;
        CacheFilteredCRMTable(SourceRecordRef, IntegrationTableMapping, IntegrationUserId);
        CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
        ForceModify := IntegrationTableMapping."Delete After Synchronization";
        if SourceRecordRef.FindSet then
            repeat
                IgnoreRecord := false;
                OnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
                if not IgnoreRecord then begin
                    if TempCRMIntegrationRecord.IsCRMRecordRefCoupled(SourceRecordRef) then
                        TempCRMIntegrationRecord.Delete
                    else
                        IgnoreRecord := IntegrationTableMapping."Synch. Only Coupled Records";
                    if not IgnoreRecord then
                        if IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, ForceModify, false) then begin
                            ModifiedOn := IntegrationTableSynch.GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);
                            if ModifiedOn > LatestModifiedOn then
                                LatestModifiedOn := ModifiedOn;
                        end;
                end;
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

    local procedure MarkAllFailedCRMRecordsAsModified(LatestModifiedOn: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        with CRMIntegrationRecord do begin
            SetRange(Skipped, false);
            SetRange("Last Synch. CRM Result", "Last Synch. CRM Result"::Failure);
            if FindSet then
                repeat
                    SetIntegrationRecordModifiedOn("Integration ID", LatestModifiedOn);
                until Next = 0;
        end;
    end;

    local procedure MarkAllFailedRecordsAsModified(LatestModifiedOn: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        with CRMIntegrationRecord do begin
            SetRange(Skipped, false);
            SetRange("Last Synch. Result", "Last Synch. Result"::Failure);
            if FindSet then
                repeat
                    SetIntegrationRecordModifiedOn("Integration ID", LatestModifiedOn);
                until Next = 0;
        end;
    end;

    local procedure SetIntegrationRecordModifiedOn(IntegrationID: Guid; LatestModifiedOn: DateTime)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        with IntegrationRecord do
            if Get(IntegrationID) then
                if "Modified On" <= LatestModifiedOn then begin
                    "Modified On" := LatestModifiedOn + 999;
                    Modify;
                end;
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
            MarkAllFailedCRMRecordsAsModified(LatestModifiedOn);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
        end;
    end;

    local procedure PerformScheduledSynchFromIntegrationTable(var IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationUserId: Guid) LatestModifiedOn: DateTime
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
    begin
        JobId :=
          IntegrationTableSynch.BeginIntegrationSynchJob(
            TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Integration Table ID");
        if not IsNullGuid(JobId) then begin
            CRMFullSynchReviewLine.FullSynchStarted(IntegrationTableMapping, JobId, IntegrationTableMapping.Direction::FromIntegrationTable);
            LatestModifiedOn := SynchCRMTableToNAV(IntegrationTableMapping, IntegrationUserId, IntegrationTableSynch);
            MarkAllFailedRecordsAsModified(LatestModifiedOn);
            IntegrationTableSynch.EndIntegrationSynchJob;
            CRMFullSynchReviewLine.FullSynchFinished(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
        end;
    end;

    local procedure SetOriginalCRMJobQueueEntryOnHold(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry")
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
    begin
        with IntegrationTableMapping do begin
            if ModifiedOn[1] > "Synch. Modified On Filter" then
                "Synch. Modified On Filter" := ModifiedOn[1];
            if ModifiedOn[2] > "Synch. Int. Tbl. Mod. On Fltr." then
                "Synch. Int. Tbl. Mod. On Fltr." := ModifiedOn[2];
            Modify(true);
        end;
    end;

    local procedure CreateCRMIntegrationRecordClone(ForTable: Integer; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        TempCRMIntegrationRecord.Reset();
        TempCRMIntegrationRecord.DeleteAll();

        CRMIntegrationRecord.SetRange("Table ID", ForTable);
        if not CRMIntegrationRecord.FindSet then
            exit;

        repeat
            TempCRMIntegrationRecord.Copy(CRMIntegrationRecord, false);
            TempCRMIntegrationRecord.Insert();
        until CRMIntegrationRecord.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 5340, 'OnQueryPostFilterIgnoreRecord', '', false, false)]
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

    [EventSubscriber(ObjectType::Table, 472, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyJobQueueEntry(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.OnBeforeModifyJobQueueEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 5338, 'OnCanBeRemoved', '', false, false)]
    local procedure OnSynchJobEntryCanBeRemoved(IntegrationSynchJob: Record "Integration Synch. Job"; var AllowRemoval: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        with CRMIntegrationRecord do begin
            SetRange(Skipped, true);
            SetRange("Last Synch. Job ID", IntegrationSynchJob.ID);
            if not IsEmpty then
                AllowRemoval := false
            else begin
                SetRange("Last Synch. Job ID");
                SetRange("Last Synch. CRM Job ID", IntegrationSynchJob.ID);
                AllowRemoval := IsEmpty;
            end;
        end;
    end;
}

