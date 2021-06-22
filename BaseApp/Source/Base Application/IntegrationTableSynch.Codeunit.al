codeunit 5335 "Integration Table Synch."
{

    trigger OnRun()
    begin
    end;

    var
        IntegrationTableMappingHasNoMappedFieldsErr: Label 'There are no field mapping rows for the %2 %3 in the %1 table.', Comment = '%1="Integration Field Mapping" table caption, %2="Integration Field Mapping.Integration Table Mapping Name" field caption, %3 Integration Table Mapping value';
        IntegrationNotActivatedErr: Label 'Integration Management must be activated before you can start the synchronization processes.';
        RecordMustBeIntegrationRecordErr: Label 'Table %1 must be registered for integration.', Comment = '%1 = Table caption';
        IntegrationRecordNotFoundErr: Label 'The integration record for %1 was not found.', Comment = '%1 = Internationalized RecordID, such as ''Customer 1234''';
        CurrentIntegrationSynchJob: Record "Integration Synch. Job";
        CurrentIntegrationTableMapping: Record "Integration Table Mapping";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationTableConnectionType: TableConnectionType;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        JobState: Option Ready,Created,"In Progress";
        UnableToDetectSynchDirectionErr: Label 'The synchronization direction cannot be determined.';
        MappingDoesNotAllowDirectionErr: Label 'The %1 %2 is not configured for %3 synchronization.', Comment = '%1 = Integration Table Mapping caption, %2 Integration Table Mapping Name, %3 = the calculated synch. direction (FromIntegrationTable|ToIntegrationTable)';
        InvalidStateErr: Label 'The synchronization process is in a state that is not valid.';
        DirectionChangeIsNotSupportedErr: Label 'You cannot change the synchronization direction after a job has started.';
        TablesDoNotMatchMappingErr: Label 'Source table %1 and destination table %2 do not match integration table mapping %3.', Comment = '%1,%2 - tables Ids; %2 - name of the mapping.';
        JobQueueLogEntryNo: Integer;

    procedure BeginIntegrationSynchJob(ConnectionType: TableConnectionType; var IntegrationTableMapping: Record "Integration Table Mapping"; SourceTableID: Integer) JobID: Guid
    var
        DirectionIsDefined: Boolean;
        ErrorMessage: Text;
    begin
        EnsureState(JobState::Ready);

        Clear(CurrentIntegrationSynchJob);
        Clear(CurrentIntegrationTableMapping);

        IntegrationTableConnectionType := ConnectionType;
        CurrentIntegrationTableMapping := IntegrationTableMapping;
        JobQueueLogEntryNo := IntegrationTableMapping.GetJobLogEntryNo;
        DirectionIsDefined := DetermineSynchDirection(SourceTableID, ErrorMessage);

        JobID := InitIntegrationSynchJob;
        if not IsNullGuid(JobID) then begin
            JobState := JobState::Created;
            if not DirectionIsDefined then
                FinishIntegrationSynchJob(ErrorMessage);
        end;
    end;

    procedure BeginIntegrationSynchJobLoging(ConnectionType: TableConnectionType; CodeunitID: Integer; JobLogEntryNo: Integer; TableID: Integer) JobID: Guid
    begin
        EnsureState(JobState::Ready);

        Clear(CurrentIntegrationSynchJob);
        Clear(CurrentIntegrationTableMapping);

        IntegrationTableConnectionType := ConnectionType;
        JobQueueLogEntryNo := JobLogEntryNo;
        CurrentIntegrationTableMapping."Table ID" := TableID;
        CurrentIntegrationTableMapping.Name := Format(CodeunitID);
        CurrentIntegrationTableMapping.Direction := CurrentIntegrationTableMapping.Direction::ToIntegrationTable;

        JobID := InitIntegrationSynchJob;
        if not IsNullGuid(JobID) then
            JobState := JobState::Created;
    end;

    procedure Synchronize(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ForceModify: Boolean; IgnoreSynchOnlyCoupledRecords: Boolean): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        SynchAction: Option;
        IsHandled: Boolean;

    begin
        OnBeforeSynchronize(SourceRecordRef, DestinationRecordRef, ForceModify, IgnoreSynchOnlyCoupledRecords, IsHandled);
        if IsHandled then
            exit;

        if not DoesSourceMatchMapping(SourceRecordRef.Number) then begin
            FinishIntegrationSynchJob(
              StrSubstNo(
                TablesDoNotMatchMappingErr, SourceRecordRef.Number, DestinationRecordRef.Number, CurrentIntegrationTableMapping.GetName));
            exit(false);
        end;

        EnsureState(JobState::Created);
        // Ready to synch.
        Commit();

        // First synch. fixes direction
        if JobState = JobState::Created then begin
            JobState := JobState::"In Progress";
            CurrentIntegrationSynchJob."Synch. Direction" := CurrentIntegrationTableMapping.Direction;
            CurrentIntegrationSynchJob.Modify(true);

            BuildTempIntegrationFieldMapping(
              CurrentIntegrationTableMapping, CurrentIntegrationTableMapping.Direction, TempIntegrationFieldMapping);
            Commit();
        end else
            if CurrentIntegrationTableMapping.Direction <> CurrentIntegrationSynchJob."Synch. Direction" then
                Error(DirectionChangeIsNotSupportedErr);

        if ForceModify then
            SynchAction := SynchActionType::ForceModify
        else
            SynchAction := SynchActionType::Skip;

        if SourceRecordRef.Count <> 0 then begin
            if IsRecordSkipped(SourceRecordRef) then
                SynchAction := SynchActionType::Skip
            else begin
                IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
                IntegrationRecSynchInvoke.SetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef,
                  IntegrationRecordSynch, SynchAction, IgnoreSynchOnlyCoupledRecords, CurrentIntegrationSynchJob.ID,
                  IntegrationTableConnectionType);
                if not IntegrationRecSynchInvoke.Run then begin
                    LogSynchError(SourceRecordRef, DestinationRecordRef, GetLastErrorText);
                    IntegrationRecSynchInvoke.MarkIntegrationRecordAsFailed(
                      CurrentIntegrationTableMapping, SourceRecordRef, CurrentIntegrationSynchJob.ID, IntegrationTableConnectionType);
                    exit(false);
                end;
                IntegrationRecSynchInvoke.GetContext(
                  CurrentIntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationRecordSynch, SynchAction);
            end;
            IncrementSynchJobCounters(SynchAction);
        end;

        exit(true);
    end;

    procedure Delete(RecRef: RecordRef): Boolean
    var
        IntegrationRecDeleteInvoke: Codeunit "Integration Rec. Delete Invoke";
        SynchDirection: Option;
        SynchAction: Option;
    begin
        EnsureState(JobState::Created);

        JobState := JobState::"In Progress";
        case RecRef.Number of
            CurrentIntegrationTableMapping."Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::FromIntegrationTable;
            CurrentIntegrationTableMapping."Integration Table ID":
                SynchDirection := CurrentIntegrationTableMapping.Direction::ToIntegrationTable;
        end;
        CurrentIntegrationSynchJob.Modify(true);
        Commit();
        SynchAction := SynchActionType::Delete;

        IntegrationRecDeleteInvoke.SetContext(
          CurrentIntegrationTableMapping, RecRef,
          SynchAction, CurrentIntegrationSynchJob.ID);
        if not IntegrationRecDeleteInvoke.Run then begin
            LogSynchError(RecRef, RecRef, GetLastErrorText);
            exit(false);
        end;
        IntegrationRecDeleteInvoke.GetContext(
          CurrentIntegrationTableMapping, RecRef, SynchAction);

        IncrementSynchJobCounters(SynchAction);

        exit(true);
    end;

    procedure EndIntegrationSynchJob(): Guid
    begin
        exit(EndIntegrationSynchJobWithMsg(''));
    end;

    procedure EndIntegrationSynchJobWithMsg(FinalMessage: Text): Guid
    begin
        if CurrentIntegrationSynchJob."Finish Date/Time" = 0DT then
            FinishIntegrationSynchJob(FinalMessage);

        JobState := JobState::Ready;
        exit(CurrentIntegrationSynchJob.ID);
    end;

    procedure GetRowLastModifiedOn(IntegrationTableMapping: Record "Integration Table Mapping"; FromRecordRef: RecordRef): DateTime
    var
        IntegrationRecord: Record "Integration Record";
        ModifiedFieldRef: FieldRef;
    begin
        if FromRecordRef.Number = IntegrationTableMapping."Integration Table ID" then begin
            ModifiedFieldRef := FromRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            exit(ModifiedFieldRef.Value);
        end;

        if IntegrationRecord.FindByRecordId(FromRecordRef.RecordId) then
            exit(IntegrationRecord."Modified On");
        Error(IntegrationRecordNotFoundErr, Format(FromRecordRef.RecordId, 0, 1));
    end;

    procedure GetStartDateTime(): DateTime
    begin
        exit(CurrentIntegrationSynchJob."Start Date/Time");
    end;

    local procedure EnsureState(RequiredState: Option)
    begin
        if (JobState = JobState::"In Progress") and (RequiredState = JobState::Created) then
            exit;

        if RequiredState <> JobState then
            Error(InvalidStateErr);
    end;

    local procedure DetermineSynchDirection(TableID: Integer; var ErrorMessage: Text): Boolean
    var
        DummyIntegrationTableMapping: Record "Integration Table Mapping";
        SynchDirection: Option;
    begin
        with CurrentIntegrationTableMapping do begin
            ErrorMessage := '';
            case TableID of
                "Table ID":
                    SynchDirection := Direction::ToIntegrationTable;
                "Integration Table ID":
                    SynchDirection := Direction::FromIntegrationTable;
                else begin
                        ErrorMessage := UnableToDetectSynchDirectionErr;
                        exit(false);
                    end;
            end;

            if not (Direction in [SynchDirection, Direction::Bidirectional]) then begin
                DummyIntegrationTableMapping.Direction := SynchDirection;
                ErrorMessage :=
                  StrSubstNo(
                    MappingDoesNotAllowDirectionErr, TableCaption, Name,
                    DummyIntegrationTableMapping.Direction);
                exit(false);
            end;

            Direction := SynchDirection;
        end;
        exit(true);
    end;

    local procedure InitIntegrationSynchJob(): Guid
    var
        JobID: Guid;
    begin
        JobID := CreateIntegrationSynchJobEntry;

        if EnsureIntegrationServicesState then begin // Prepare for processing
            Commit();
            exit(JobID);
        end;
    end;

    local procedure FinishIntegrationSynchJob(FinalMessage: Text)
    begin
        with CurrentIntegrationSynchJob do begin
            if FinalMessage <> '' then
                Message := CopyStr(FinalMessage, 1, MaxStrLen(Message));
            "Finish Date/Time" := CurrentDateTime;
            Modify(true);
        end;
        Commit();
    end;

    local procedure CreateIntegrationSynchJobEntry() JobID: Guid
    begin
        with CurrentIntegrationSynchJob do
            if IsEmpty or IsNullGuid(ID) then begin
                Reset;
                Init;
                ID := CreateGuid;
                "Start Date/Time" := CurrentDateTime;
                "Integration Table Mapping Name" := CurrentIntegrationTableMapping.GetName;
                "Synch. Direction" := CurrentIntegrationTableMapping.Direction;
                "Job Queue Log Entry No." := JobQueueLogEntryNo;
                Insert(true);
                Commit();
                JobID := ID;
            end;
    end;

    local procedure EnsureIntegrationServicesState(): Boolean
    var
        IntegrationManagement: Codeunit "Integration Management";
    begin
        if not IntegrationManagement.IsIntegrationActivated then begin
            FinishIntegrationSynchJob(IntegrationNotActivatedErr);
            exit(false);
        end;

        with CurrentIntegrationTableMapping do begin
            if IntegrationManagement.IsIntegrationRecord("Table ID") then
                exit(true);

            if IntegrationManagement.IsIntegrationRecordChild("Table ID") then
                exit(true);

            if "Integration Table ID" = DATABASE::"Graph Contact" then
                exit(true);

            FinishIntegrationSynchJob(StrSubstNo(RecordMustBeIntegrationRecordErr, "Table ID"));
        end;
        exit(false);
    end;

    local procedure BuildTempIntegrationFieldMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; SynchDirection: Option; var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        with IntegrationFieldMapping do begin
            SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            SetFilter(Direction, '%1|%2', SynchDirection, Direction::Bidirectional);
            SetFilter(Status, '<>%1', Status::Disabled);
            if IsEmpty then
                Error(
                  IntegrationTableMappingHasNoMappedFieldsErr, TableCaption,
                  FieldCaption("Integration Table Mapping Name"), IntegrationTableMapping.Name);

            TempIntegrationFieldMapping.DeleteAll();
            FindSet;
            repeat
                TempIntegrationFieldMapping.Init();
                TempIntegrationFieldMapping."No." := "No.";
                TempIntegrationFieldMapping."Integration Table Mapping Name" := "Integration Table Mapping Name";
                TempIntegrationFieldMapping."Constant Value" := "Constant Value";
                TempIntegrationFieldMapping."Not Null" := "Not Null";
                if SynchDirection = IntegrationTableMapping.Direction::ToIntegrationTable then begin
                    TempIntegrationFieldMapping."Source Field No." := "Field No.";
                    TempIntegrationFieldMapping."Destination Field No." := "Integration Table Field No.";
                    TempIntegrationFieldMapping."Validate Destination Field" := "Validate Integration Table Fld";
                end else begin
                    TempIntegrationFieldMapping."Source Field No." := "Integration Table Field No.";
                    TempIntegrationFieldMapping."Destination Field No." := "Field No.";
                    TempIntegrationFieldMapping."Validate Destination Field" := "Validate Field";
                end;
                TempIntegrationFieldMapping.Insert();
            until Next = 0;
        end;
    end;

    procedure LogSynchError(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ErrorMessage: Text): Guid
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SourceRecordID: RecordID;
        DestinationRecordID: RecordID;
    begin
        IncrementSynchJobCounters(SynchActionType::Fail);
        if DestinationRecordRef.Number <> 0 then
            DestinationRecordID := DestinationRecordRef.RecordId;
        if SourceRecordRef.Number <> 0 then
            SourceRecordID := SourceRecordRef.RecordId;

        IntegrationSynchJobErrors.LogSynchError(
          CurrentIntegrationSynchJob.ID, SourceRecordID, DestinationRecordID, ErrorMessage);
        exit(CurrentIntegrationSynchJob.ID);
    end;

    procedure IncrementSynchJobCounters(SynchAction: Option)
    begin
        UpdateSynchJobCounters(SynchAction, 1)
    end;

    procedure UpdateSynchJobCounters(SynchAction: Option; Counter: Integer)
    begin
        if Counter = 0 then
            exit;
        with CurrentIntegrationSynchJob do begin
            case SynchAction of
                SynchActionType::Insert:
                    Inserted += Counter;
                SynchActionType::Modify, SynchActionType::ForceModify:
                    Modified += Counter;
                SynchActionType::IgnoreUnchanged:
                    Unchanged += Counter;
                SynchActionType::Skip:
                    Skipped += Counter;
                SynchActionType::Fail:
                    Failed += Counter;
                SynchActionType::Delete:
                    Deleted += Counter;
                else
                    exit
            end;
            Modify;
            Commit();
        end;
    end;

    local procedure DoesSourceMatchMapping(SourceTableID: Integer): Boolean
    begin
        with CurrentIntegrationTableMapping do
            case Direction of
                Direction::ToIntegrationTable:
                    exit(SourceTableID = "Table ID");
                Direction::FromIntegrationTable:
                    exit(SourceTableID = "Integration Table ID");
            end;
    end;

    local procedure IsRecordSkipped(RecRef: RecordRef): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecRef.RecordId);
        exit(CRMIntegrationRecord.Skipped);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronize(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var ForceModify: Boolean; var IgnoreSynchOnlyCoupledRecords: Boolean; var IsHandled: Boolean)
    begin
    end;
}

