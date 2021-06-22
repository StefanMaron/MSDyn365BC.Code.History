codeunit 5345 "Integration Rec. Synch. Invoke"
{

    trigger OnRun()
    begin
        CheckContext();
        SynchRecord(
          IntegrationTableMappingContext, SourceRecordRefContext, DestinationRecordRefContext,
          IntegrationRecordSynchContext, SynchActionContext, IgnoreSynchOnlyCoupledRecordsContext,
          JobIdContext, IntegrationTableConnectionTypeContext);
    end;

    var
        IntegrationTableMappingContext: Record "Integration Table Mapping";
        IntegrationRecordSynchContext: Codeunit "Integration Record Synch.";
        SourceRecordRefContext: RecordRef;
        DestinationRecordRefContext: RecordRef;
        IntegrationTableConnectionTypeContext: TableConnectionType;
        JobIdContext: Guid;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip;
        BothDestinationAndSourceIsNewerErr: Label 'Cannot update the %2 record because both the %1 record and the %2 record have been changed.', Comment = '%1 = Source record table caption, %2 destination table caption';
        ModifyFailedErr: Label 'Modifying %1 failed because of the following error: %2.', Comment = '%1 = Table Caption, %2 = Error from modify process.';
        ConfigurationTemplateNotFoundErr: Label 'The %1 %2 was not found.', Comment = '%1 = Configuration Template table caption, %2 = Configuration Template Name';
        CoupledRecordIsDeletedErr: Label 'The %1 record cannot be updated because it is coupled to a deleted record.', Comment = '1% = Source Table Caption';
        CopyDataErr: Label 'The data could not be updated because of the following error: %1.', Comment = '%1 = Error message from transferdata process.';
        IntegrationRecordNotFoundErr: Label 'The integration record for %1 was not found.', Comment = '%1 = Internationalized RecordID, such as ''Customer 1234''';
        SynchActionContext: Option;
        IgnoreSynchOnlyCoupledRecordsContext: Boolean;
        IsContextInitialized: Boolean;
        ContextErr: Label 'The integration record synchronization context has not been initialized.';

    procedure SetContext(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationRecordSynch: Codeunit "Integration Record Synch."; SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    begin
        IntegrationTableMappingContext := IntegrationTableMapping;
        IntegrationRecordSynchContext := IntegrationRecordSynch;
        SourceRecordRefContext := SourceRecordRef;
        DestinationRecordRefContext := DestinationRecordRef;
        SynchActionContext := SynchAction;
        IgnoreSynchOnlyCoupledRecordsContext := IgnoreSynchOnlyCoupledRecords;
        IntegrationTableConnectionTypeContext := IntegrationTableConnectionType;
        JobIdContext := JobId;
        IsContextInitialized := true;
    end;

    procedure GetContext(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IntegrationRecordSynch: Codeunit "Integration Record Synch."; var SynchAction: Option)
    begin
        CheckContext();
        IntegrationTableMapping := IntegrationTableMappingContext;
        IntegrationRecordSynch := IntegrationRecordSynchContext;
        SourceRecordRef := SourceRecordRefContext;
        DestinationRecordRef := DestinationRecordRefContext;
        SynchAction := SynchActionContext;
    end;

    procedure WasModifiedAfterLastSynch(IntegrationTableMapping: Record "Integration Table Mapping"; RecordRef: RecordRef): Boolean
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        LastModifiedOn: DateTime;
    begin
        LastModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, RecordRef);
        if IntegrationTableMapping."Integration Table ID" = RecordRef.Number() then
            exit(
              IntegrationRecordManagement.IsModifiedAfterIntegrationTableRecordLastSynch(
                IntegrationTableConnectionTypeContext, RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value(),
                IntegrationTableMapping."Table ID", LastModifiedOn));

        exit(
          IntegrationRecordManagement.IsModifiedAfterRecordLastSynch(
            IntegrationTableConnectionTypeContext, RecordRef.RecordId(), LastModifiedOn));
    end;

    procedure GetRowLastModifiedOn(IntegrationTableMapping: Record "Integration Table Mapping"; FromRecordRef: RecordRef): DateTime
    var
        IntegrationRecord: Record "Integration Record";
        ModifiedFieldRef: FieldRef;
    begin
        if FromRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then begin
            ModifiedFieldRef := FromRecordRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
            exit(ModifiedFieldRef.Value());
        end;

        if IntegrationRecord.FindByRecordId(FromRecordRef.RecordId()) then
            exit(IntegrationRecord."Modified On");
        Error(IntegrationRecordNotFoundErr, Format(FromRecordRef.RecordId(), 0, 1));
    end;

    local procedure CheckContext()
    begin
        if not IsContextInitialized then
            Error(ContextErr);
    end;

    local procedure SynchRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IntegrationRecordSynch: Codeunit "Integration Record Synch."; var SynchAction: Option; IgnoreSynchOnlyCoupledRecords: Boolean; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        AdditionalFieldsModified: Boolean;
        SourceWasChanged: Boolean;
        WasModified: Boolean;
        ConflictText: Text;
        RecordState: Option NotFound,Coupled,Decoupled;
    begin
        // Find the coupled record or prepare a new one
        RecordState :=
          GetCoupledRecord(
            IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, IntegrationTableConnectionType);
        if RecordState = RecordState::NotFound then begin
            if SynchAction = SynchActionType::Fail then
                exit;
            if IntegrationTableMapping."Synch. Only Coupled Records" and not IgnoreSynchOnlyCoupledRecords then begin
                SynchAction := SynchActionType::Skip;
                exit;
            end;
            PrepareNewDestination(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            SynchAction := SynchActionType::Insert;
        end;

        if SynchAction = SynchActionType::Insert then
            SourceWasChanged := true
        else begin
            SourceWasChanged := WasModifiedAfterLastSynch(IntegrationTableMapping, SourceRecordRef);
            if SynchAction <> SynchActionType::ForceModify then
                if SourceWasChanged then
                    ConflictText :=
                      ChangedDestinationConflictsWithSource(IntegrationTableMapping, DestinationRecordRef)
                else
                    SynchAction := SynchActionType::IgnoreUnchanged;
        end;

        if not (SynchAction in [SynchActionType::Insert, SynchActionType::Modify, SynchActionType::ForceModify]) then
            exit;

        if SourceWasChanged or (ConflictText <> '') or (SynchAction = SynchActionType::ForceModify) then
            TransferFields(
              IntegrationRecordSynch, SourceRecordRef, DestinationRecordRef, SynchAction, AdditionalFieldsModified, JobId, ConflictText <> '');

        WasModified := IntegrationRecordSynch.GetWasModified() or AdditionalFieldsModified;
        if WasModified then
            if ConflictText <> '' then begin
                SynchAction := SynchActionType::Fail;
                LogSynchError(
                  SourceRecordRef, DestinationRecordRef,
                  StrSubstNo(ConflictText, SourceRecordRef.Caption(), DestinationRecordRef.Caption()), JobId);
                MarkIntegrationRecordAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, IntegrationTableConnectionType);
                exit;
            end;
        if (SynchAction = SynchActionType::Modify) and (not WasModified) then
            SynchAction := SynchActionType::IgnoreUnchanged;

        case SynchAction of
            SynchActionType::Insert:
                InsertRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, IntegrationTableConnectionType);
            SynchActionType::Modify,
          SynchActionType::ForceModify:
                ModifyRecord(
                  IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, SynchAction, JobId, IntegrationTableConnectionType);
            SynchActionType::IgnoreUnchanged:
                begin
                    UpdateIntegrationRecordCoupling(
                      IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
                    OnAfterUnchangedRecordHandled(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
                    UpdateIntegrationRecordTimestamp(
                      IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId);
                end;
        end;
    end;

    local procedure InsertRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    begin
        OnBeforeInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
        DestinationRecordRef.Insert(true);
        ApplyConfigTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, JobId, SynchAction);
        if SynchAction <> SynchActionType::Fail then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            OnAfterInsertRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId);
        end;
        Commit();
    end;

    local procedure ModifyRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    begin
        OnBeforeModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);

        if DestinationRecordRef.Modify(true) then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            OnAfterModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobId);
        end else begin
            OnErrorWhenModifyingRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            SynchAction := SynchActionType::Fail;
            LogSynchError(
              SourceRecordRef, DestinationRecordRef,
              StrSubstNo(ModifyFailedErr, DestinationRecordRef.Caption(), RemoveTrailingDots(GetLastErrorText())), JobId);
            MarkIntegrationRecordAsFailed(IntegrationTableMapping, SourceRecordRef, JobId, IntegrationTableConnectionType);
        end;
        Commit();
    end;

    local procedure ApplyConfigTemplate(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; JobId: Guid; var SynchAction: Option)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        ConfigTemplateCode: Code[10];
    begin
        if DestinationRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then
            ConfigTemplateCode := IntegrationTableMapping."Int. Tbl. Config Template Code"
        else
            ConfigTemplateCode := IntegrationTableMapping."Table Config Template Code";
        if ConfigTemplateCode <> '' then begin
            OnBeforeApplyRecordTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, ConfigTemplateCode);

            if ConfigTemplateHeader.Get(ConfigTemplateCode) then begin
                ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, DestinationRecordRef);
                if DestinationRecordRef.Number() <> IntegrationTableMapping."Integration Table ID" then
                    InsertDimensionsFromTemplate(ConfigTemplateHeader, DestinationRecordRef);
                OnAfterApplyRecordTemplate(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
            end else begin
                SynchAction := SynchActionType::Fail;
                LogSynchError(
                  SourceRecordRef, DestinationRecordRef,
                  StrSubstNo(ConfigurationTemplateNotFoundErr, ConfigTemplateHeader.TableCaption(), ConfigTemplateCode), JobId);
            end;
        end;
    end;

    local procedure InsertDimensionsFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; var DestinationRecordRef: RecordRef)
    var
        DimensionsTemplate: Record "Dimensions Template";
        PrimaryKeyRef: KeyRef;
        PrimaryKeyFieldRef: FieldRef;
    begin
        PrimaryKeyRef := DestinationRecordRef.KeyIndex(1);
        if PrimaryKeyRef.FieldCount() <> 1 then
            exit;

        PrimaryKeyFieldRef := PrimaryKeyRef.FieldIndex(1);
        if PrimaryKeyFieldRef.Type() <> FieldType::Code then
            exit;

        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, CopyStr(Format(PrimaryKeyFieldRef.Value()), 1, 20), DestinationRecordRef.Number);
        DestinationRecordRef.Get(DestinationRecordRef.RecordId());
    end;

    local procedure ChangedDestinationConflictsWithSource(IntegrationTableMapping: Record "Integration Table Mapping"; DestinationRecordRef: RecordRef) ConflictText: Text
    begin
        if IntegrationTableMapping.GetDirection = IntegrationTableMapping.Direction::Bidirectional then
            if WasModifiedAfterLastSynch(IntegrationTableMapping, DestinationRecordRef) then
                ConflictText := BothDestinationAndSourceIsNewerErr
    end;

    local procedure GetCoupledRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef; var CoupledRecordRef: RecordRef; var SynchAction: Option; JobId: Guid; IntegrationTableConnectionType: TableConnectionType): Integer
    var
        IsDestinationMarkedAsDeleted: Boolean;
        RecordState: Option NotFound,Coupled,Decoupled;
    begin
        IsDestinationMarkedAsDeleted := false;
        RecordState :=
          FindRecord(
            IntegrationTableMapping, RecordRef, CoupledRecordRef, IsDestinationMarkedAsDeleted, IntegrationTableConnectionType);

        if RecordState <> RecordState::NotFound then
            if IsDestinationMarkedAsDeleted then begin
                RecordState := RecordState::NotFound;
                SynchAction := SynchActionType::Fail;
                LogSynchError(RecordRef, CoupledRecordRef, StrSubstNo(CoupledRecordIsDeletedErr, RecordRef.Caption), JobId);
                MarkIntegrationRecordAsFailed(IntegrationTableMapping, RecordRef, JobId, IntegrationTableConnectionType);
            end else begin
                if RecordState = RecordState::Decoupled then
                    SynchAction := SynchActionType::ForceModify;
                if SynchAction <> SynchActionType::ForceModify then
                    SynchAction := SynchActionType::Modify;
            end;
        exit(RecordState);
    end;

    local procedure FindRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsDestinationDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType): Integer
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IDFieldRef: FieldRef;
        RecordIDValue: RecordID;
        RecordState: Option NotFound,Coupled,Decoupled;
        RecordFound: Boolean;
    begin
        if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then // NAV -> Integration Table synch
            RecordFound :=
              FindIntegrationTableRecord(
                IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsDestinationDeleted, IntegrationTableConnectionType)
        else begin  // Integration Table -> NAV synch
            IDFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            RecordFound :=
              IntegrationRecordManagement.FindRecordIdByIntegrationTableUid(
                IntegrationTableConnectionType, IDFieldRef.Value, IntegrationTableMapping."Table ID", RecordIDValue);
            if RecordFound then
                IsDestinationDeleted := not DestinationRecordRef.Get(RecordIDValue);
        end;
        if RecordFound then
            exit(RecordState::Coupled);

        // If no explicit coupling is found, attempt to find a match based on user data
        if FindAndCoupleDestinationRecord(
             IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IsDestinationDeleted, IntegrationTableConnectionType)
        then
            exit(RecordState::Decoupled);
        exit(RecordState::NotFound);
    end;

    local procedure FindAndCoupleDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType) DestinationFound: Boolean
    begin
        OnFindUncoupledDestinationRecord(
          IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, DestinationIsDeleted, DestinationFound);
        if DestinationFound then begin
            UpdateIntegrationRecordCoupling(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType);
            UpdateIntegrationRecordTimestamp(
              IntegrationTableMapping, SourceRecordRef, DestinationRecordRef, IntegrationTableConnectionType, JobIdContext);
        end;
    end;

    local procedure FindIntegrationTableRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var IsDestinationDeleted: Boolean; IntegrationTableConnectionType: TableConnectionType) FoundDestination: Boolean
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IDValue: Variant;
    begin
        FoundDestination :=
          IntegrationRecordManagement.FindIntegrationTableUIdByRecordId(IntegrationTableConnectionType, SourceRecordRef.RecordId, IDValue);

        if FoundDestination then
            IsDestinationDeleted := not IntegrationTableMapping.GetRecordRef(IDValue, DestinationRecordRef);
    end;

    local procedure PrepareNewDestination(var IntegrationTableMapping: Record "Integration Table Mapping"; var RecordRef: RecordRef; var CoupledRecordRef: RecordRef)
    begin
        CoupledRecordRef.Close;

        if RecordRef.Number = IntegrationTableMapping."Table ID" then
            CoupledRecordRef.Open(IntegrationTableMapping."Integration Table ID")
        else
            CoupledRecordRef.Open(IntegrationTableMapping."Table ID");

        CoupledRecordRef.Init();
    end;

    local procedure LogSynchError(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; ErrorMessage: Text; JobId: Guid)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EmptyRecordID: RecordID;
    begin
        if DestinationRecordRef.Number = 0 then begin
            EmptyRecordID := SourceRecordRef.RecordId;
            Clear(EmptyRecordID);
            IntegrationSynchJobErrors.LogSynchError(JobId, SourceRecordRef.RecordId, EmptyRecordID, ErrorMessage)
        end else begin
            IntegrationSynchJobErrors.LogSynchError(JobId, SourceRecordRef.RecordId, DestinationRecordRef.RecordId, ErrorMessage);

            // Close destination - it is in error state and can no longer be used.
            DestinationRecordRef.Close;
        end;
    end;

    local procedure TransferFields(var IntegrationRecordSynch: Codeunit "Integration Record Synch."; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var SynchAction: Option; var AdditionalFieldsModified: Boolean; JobId: Guid; ConflictFound: Boolean)
    var
        CDSTransformationRuleMgt: Codeunit "CDS Transformation Rule Mgt.";
    begin
        OnBeforeTransferRecordFields(SourceRecordRef, DestinationRecordRef);

        CDSTransformationRuleMgt.ApplyTransformations(SourceRecordRef, DestinationRecordRef);
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, SynchAction <> SynchActionType::Insert);
        if IntegrationRecordSynch.Run then begin
            if ConflictFound and IntegrationRecordSynch.GetWasModified then
                exit;
            OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef,
              AdditionalFieldsModified, SynchAction <> SynchActionType::Insert);
            AdditionalFieldsModified := AdditionalFieldsModified or IntegrationRecordSynch.GetWasModified;
        end else begin
            SynchAction := SynchActionType::Fail;
            LogSynchError(
              SourceRecordRef, DestinationRecordRef,
              StrSubstNo(CopyDataErr, RemoveTrailingDots(GetLastErrorText)), JobId);
            MarkIntegrationRecordAsFailed(IntegrationTableMappingContext, SourceRecordRef, JobId, IntegrationTableConnectionTypeContext);
            Commit();
        end;
    end;

    procedure MarkIntegrationRecordAsFailed(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; JobId: Guid; IntegrationTableConnectionType: TableConnectionType)
    var
        IntegrationManagement: Codeunit "Integration Management";
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        DirectionToIntTable: Boolean;
    begin
        if IntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
            exit;
        DirectionToIntTable := IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationRecordManagement.MarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecordRef, DirectionToIntTable, JobId);
    end;

    local procedure UpdateIntegrationRecordCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType)
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IntegrationManagement: Codeunit "Integration Management";
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
    begin
        if IntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
            exit;

        ArrangeRecordRefs(SourceRecordRef, DestinationRecordRef, IntegrationTableMapping."Table ID");
        IntegrationTableUidFieldRef := DestinationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value;

        IntegrationRecordManagement.UpdateIntegrationTableCoupling(
          IntegrationTableConnectionType, IntegrationTableUid, SourceRecordRef.RecordId);
    end;

    local procedure UpdateIntegrationRecordTimestamp(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; IntegrationTableConnectionType: TableConnectionType; JobID: Guid)
    var
        IntegrationRecordManagement: Codeunit "Integration Record Management";
        IntegrationManagement: Codeunit "Integration Management";
        IntegrationTableUidFieldRef: FieldRef;
        IntegrationTableUid: Variant;
        IntegrationTableModifiedOn: DateTime;
        ModifiedOn: DateTime;
    begin
        if IntegrationManagement.IsIntegrationRecordChild(IntegrationTableMapping."Table ID") then
            exit;

        ArrangeRecordRefs(SourceRecordRef, DestinationRecordRef, IntegrationTableMapping."Table ID");
        IntegrationTableUidFieldRef := DestinationRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        IntegrationTableUid := IntegrationTableUidFieldRef.Value;
        IntegrationTableModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, DestinationRecordRef);
        ModifiedOn := GetRowLastModifiedOn(IntegrationTableMapping, SourceRecordRef);

        IntegrationRecordManagement.UpdateIntegrationTableTimestamp(
          IntegrationTableConnectionType, IntegrationTableUid, IntegrationTableModifiedOn,
          SourceRecordRef.Number, ModifiedOn, JobID, IntegrationTableMapping.Direction);
        Commit();
    end;

    local procedure ArrangeRecordRefs(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; TableID: Integer)
    var
        RecordRef: RecordRef;
    begin
        if SourceRecordRef.Number <> TableID then begin
            RecordRef := SourceRecordRef;
            SourceRecordRef := DestinationRecordRef;
            DestinationRecordRef := RecordRef;
        end;
    end;

    local procedure RemoveTrailingDots(Message: Text): Text
    begin
        exit(DelChr(Message, '>', '.'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRecordFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorWhenModifyingRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyRecordTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var TemplateCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyRecordTemplate(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUncoupledDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    begin
    end;
}

