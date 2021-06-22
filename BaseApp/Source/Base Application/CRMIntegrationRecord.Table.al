table 5331 "CRM Integration Record"
{
    Caption = 'CRM Integration Record';

    fields
    {
        field(2; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            Description = 'An ID of a record in Microsoft Dynamics CRM';

            trigger OnValidate()
            begin
                Clear("Last Synch. CRM Job ID");
                "Last Synch. CRM Modified On" := 0DT;
                "Last Synch. CRM Result" := 0;
                Skipped := false;
            end;
        }
        field(3; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';

            trigger OnValidate()
            begin
                Clear("Last Synch. Job ID");
                "Last Synch. Modified On" := 0DT;
                "Last Synch. Result" := 0;
                Skipped := false;
            end;
        }
        field(4; "Last Synch. Modified On"; DateTime)
        {
            Caption = 'Last Synch. Modified On';
        }
        field(5; "Last Synch. CRM Modified On"; DateTime)
        {
            Caption = 'Last Synch. CRM Modified On';
        }
        field(6; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
            FieldClass = Normal;
        }
        field(7; "Last Synch. Result"; Option)
        {
            Caption = 'Last Synch. Result';
            OptionCaption = ',Success,Failure';
            OptionMembers = ,Success,Failure;
        }
        field(8; "Last Synch. CRM Result"; Option)
        {
            Caption = 'Last Synch. CRM Result';
            OptionCaption = ',Success,Failure';
            OptionMembers = ,Success,Failure;
        }
        field(9; "Last Synch. Job ID"; Guid)
        {
            Caption = 'Last Synch. Job ID';
        }
        field(10; "Last Synch. CRM Job ID"; Guid)
        {
            Caption = 'Last Synch. CRM Job ID';
        }
        field(11; Skipped; Boolean)
        {
            Caption = 'Skipped';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "CRM ID", "Integration ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration ID")
        {
        }
        key(Key3; "Last Synch. Modified On", "Integration ID")
        {
        }
        key(Key4; "Last Synch. CRM Modified On", "CRM ID")
        {
        }
        key(Key5; Skipped, "Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        IntegrationRecordNotFoundErr: Label 'The integration record for entity %1 was not found.';
        CRMIdAlreadyMappedErr: Label 'Cannot couple %1 to this %3 record, because the %3 record is already coupled to %2.', Comment = '%1 ID of the record, %2 ID of the already mapped record, %3 = CRM product name';
        RecordIdAlreadyMappedErr: Label 'Cannot couple the %2 record to %1, because %1 is already coupled to another %2 record.', Comment = '%1 ID from the record, %2 ID of the already mapped record';
        CRMProductName: Codeunit "CRM Product Name";

    local procedure GetCRMIdFromRecRef(CRMRecordRef: RecordRef): Guid
    var
        CRMIdFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := CRMRecordRef.KeyIndex(1);
        CRMIdFieldRef := PrimaryKeyRef.FieldIndex(1);
        exit(CRMIdFieldRef.Value);
    end;

    procedure GetCRMRecordID(IntegrationTableID: Integer; var CRMRecID: RecordID) Found: Boolean
    var
        RecRef: RecordRef;
    begin
        Found := GetCRMRecordRef(IntegrationTableID, RecRef);
        CRMRecID := RecRef.RecordId;
        RecRef.Close;
    end;

    procedure GetCRMRecordRef(IntegrationTableID: Integer; var RecRef: RecordRef): Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        if IntegrationTableID = 0 then
            exit(false);

        RecRef.Open(IntegrationTableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange("CRM ID");
        exit(RecRef.FindFirst);
    end;

    procedure GetLatestJobIDFilter(): Text
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if IsNullGuid("Last Synch. Job ID") and IsNullGuid("Last Synch. CRM Job ID") then
            exit('');
        IntegrationSynchJob.SetFilter(ID, '%1|%2', "Last Synch. Job ID", "Last Synch. CRM Job ID");
        exit(IntegrationSynchJob.GetFilter(ID));
    end;

    procedure GetLatestError(var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    begin
        if not IsNullGuid("Last Synch. CRM Job ID") then
            exit(GetErrorForJobID("Last Synch. CRM Job ID", IntegrationSynchJobErrors));
        if not IsNullGuid("Last Synch. Job ID") then
            exit(GetErrorForJobID("Last Synch. Job ID", IntegrationSynchJobErrors))
    end;

    local procedure GetErrorForJobID(JobID: Guid; var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMRecId: RecordID;
        RecId: RecordId;
    begin
        if IntegrationSynchJob.Get(JobID) then
            case IntegrationSynchJob."Synch. Direction" of
                IntegrationSynchJob."Synch. Direction"::ToIntegrationTable:
                    if FindRecordId(RecId) then
                        exit(IntegrationSynchJob.GetErrorForRecordID(RecId, IntegrationSynchJobErrors));
                IntegrationSynchJob."Synch. Direction"::FromIntegrationTable:
                    if IntegrationTableMapping.Get(IntegrationSynchJob."Integration Table Mapping Name") then
                        if GetCRMRecordID(IntegrationTableMapping."Integration Table ID", CRMRecId) then
                            exit(IntegrationSynchJob.GetErrorForRecordID(CRMRecId, IntegrationSynchJobErrors));
            end;
    end;

    procedure InsertRecord(CRMID: Guid; IntegrationRecord: Record "Integration Record")
    begin
        Reset();
        Init();
        "CRM ID" := CRMID;
        "Integration ID" := IntegrationRecord."Integration ID";
        "Table ID" := IntegrationRecord."Table ID";
        Insert(true);
    end;

    procedure InsertRecord(CRMID: Guid; SysId: Guid; TableId: Integer)
    begin
        Reset;
        Init;
        "CRM ID" := CRMID;
        "Integration ID" := SysId;
        "Table ID" := TableId;
        Insert(true);
    end;

    procedure IsCRMRecordRefCoupled(CRMRecordRef: RecordRef): Boolean
    begin
        exit(FindByCRMID(GetCRMIdFromRecRef(CRMRecordRef)));
    end;

    procedure IsIntegrationIdCoupled(IntegrationID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(FindRowFromIntegrationID(IntegrationID, CRMIntegrationRecord));
    end;

    procedure IsRecordCoupled(DestinationRecordID: RecordID): Boolean
    var
        CRMId: Guid;
    begin
        exit(FindIDFromRecordID(DestinationRecordID, CRMId));
    end;

    procedure FindByCRMID(CRMID: Guid): Boolean
    begin
        Reset;
        SetRange("CRM ID", CRMID);
        exit(FindFirst);
    end;

    procedure FindValidByCRMID(CRMID: Guid) Found: Boolean
    var
        RecRef: RecordRef;
        RecId: RecordId;
    begin
        Clear("CRM ID");
        Reset;
        SetRange("CRM ID", CRMID);
        if FindFirst then
            if FindRecordId(RecId) then
                Found := RecRef.Get(RecId);
    end;

    procedure FindRecordId(var RecId: RecordId): Boolean
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        EmptyRecId: RecordId;
        FoundRecId: RecordId;
    begin
        RecRef.Open("Table ID");
        FldRef := RecRef.FIELD(RecRef.SystemIdNo());
        FldRef.SetRange("Integration ID");
        If RecRef.FindFirst() then
            FoundRecId := RecRef.RecordId();

        if FoundRecId <> EmptyRecId then
            RecId := FoundRecId;

        exit(FoundRecId <> EmptyRecId);
    end;

    procedure FindSystemIdByRecordId(var SysId: Guid; RecId: RecordId): Boolean
    var
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
    begin
        if not RecRef.Get(RecId) then
            exit(false);

        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        Evaluate(SysId, Format(SystemIdFieldRef.Value()));

        exit(not IsNullGuid(SysId));
    end;

    procedure FindByRecordID(RecID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromRecordID(RecID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            exit(true);
        end;
    end;

    procedure FindValidByRecordID(RecID: RecordID; IntegrationTableID: Integer) Found: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMRecId: RecordID;
    begin
        Clear("CRM ID");
        if FindRowFromRecordID(RecID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            Found := GetCRMRecordID(IntegrationTableID, CRMRecId);
        end;
    end;

    procedure FindRecordIDFromID(SourceCRMID: Guid; DestinationTableID: Integer; var DestinationRecordId: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecId: RecordId;
    begin
        if FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then
            if CRMIntegrationRecord.FindRecordId(RecId) then begin
                DestinationRecordId := RecId;
                exit(true);
            end;
    end;

    procedure FindIDFromRecordID(SourceRecordID: RecordID; var DestinationCRMID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromRecordID(SourceRecordID, CRMIntegrationRecord) then begin
            DestinationCRMID := CRMIntegrationRecord."CRM ID";
            exit(true);
        end;
    end;

    local procedure FindIntegrationIDFromCRMID(SourceCRMID: Guid; DestinationTableID: Integer; var DestinationIntegrationID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then begin
            DestinationIntegrationID := CRMIntegrationRecord."Integration ID";
            exit(true);
        end;
    end;

    procedure CoupleCRMIDToRecordID(CRMID: Guid; RecordID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationRecord2: Record "CRM Integration Record";
        ErrCRMID: Guid;
        SysId: Guid;
    begin
        if not FindSystemIdByRecordId(SysId, RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        // Find coupling between CRMID and TableNo
        if not FindRowFromCRMID(CRMID, RecordID.TableNo, CRMIntegrationRecord) then
            // Find rogue coupling beteen CRMID and table 0
            if not FindRowFromCRMID(CRMID, 0, CRMIntegrationRecord) then begin
                // Find other coupling to the record
                if CRMIntegrationRecord2.FindIDFromRecordID(RecordID, ErrCRMID) then
                    Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));

                CRMIntegrationRecord.InsertRecord(CRMID, SysId, RecordID.TableNo);
                exit;
            end;

        // Update Integration ID
        if CRMIntegrationRecord."Integration ID" <> SysId then begin
            if CRMIntegrationRecord2.FindIDFromRecordID(RecordID, ErrCRMID) then
                Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));
            CRMIntegrationRecord.SetNewIntegrationId(SysId);
        end;
    end;

    procedure CoupleRecordIdToCRMID(RecordID: RecordID; CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        RecRef: RecordRef;
        IntegrationID: Guid;
    begin
        // we shouldn't remove this code until we abandon Integration Record in CRM completely. That can happen only after we get $lastModifiedOn feature on all records.
        if not IntegrationRecord.FindByRecordId(RecordID) then begin
            RecRef.Get(RecordID);
            IntegrationID := IntegrationManagement.InsertUpdateIntegrationRecord(RecRef, CurrentDateTime);
            if IsNullGuid(IntegrationID) then
                exit;
            IntegrationRecord.Get(IntegrationID);
        end;
        if not FindRowFromIntegrationID(IntegrationRecord."Integration ID", CRMIntegrationRecord) then begin
            AssertRecordIDCanBeCoupled(RecordID, CRMID);
            CRMIntegrationRecord.InsertRecord(CRMID, IntegrationRecord."Integration ID", IntegrationRecord."Table ID");
        end else
            if CRMIntegrationRecord."CRM ID" <> CRMID then begin
                AssertRecordIDCanBeCoupled(RecordID, CRMID);
                CRMIntegrationRecord.SetNewCRMId(CRMID);
            end;
    end;

    procedure RemoveCouplingToRecord(RecordID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SysId: Guid;
    begin
        if not FindSystemIdByRecordId(SysId, RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        if FindRowFromIntegrationID(SysId, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            CRMIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure RemoveCouplingToCRMID(CRMID: Guid; DestinationTableID: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then begin
            Copy(CRMIntegrationRecord);
            CRMIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure SetNewCRMId(CRMId: Guid)
    begin
        Delete;
        Validate("CRM ID", CRMId);
        Insert;
    end;

    procedure SetNewIntegrationId(IntegrationId: Guid)
    begin
        Delete;
        Validate("Integration ID", IntegrationId);
        Insert;
    end;

    procedure AssertRecordIDCanBeCoupled(RecordID: RecordID; CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ErrRecordID: RecordID;
        ErrIntegrationID: Guid;
    begin
        if FindIntegrationIDFromCRMID(CRMID, RecordID.TableNo, ErrIntegrationID) then
            if not UncoupleCRMIDIfRecordDeleted(RecordID.TableNo, ErrIntegrationID) then begin
                CRMIntegrationRecord.FindRecordIDFromID(CRMID, RecordID.TableNo, ErrRecordID);
                Error(CRMIdAlreadyMappedErr, Format(RecordID, 0, 1), ErrRecordID, CRMProductName.SHORT);
            end;
    end;

    procedure SetLastSynchResultFailed(SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobId: Guid)
    var
        Found: Boolean;
    begin
        if DirectionToIntTable then
            Found := FindByRecordID(SourceRecRef.RecordId)
        else
            Found := FindByCRMID(GetCRMIdFromRecRef(SourceRecRef));
        if Found then begin
            if DirectionToIntTable then begin
                if (not Skipped) and ("Last Synch. CRM Result" = "Last Synch. CRM Result"::Failure) then
                    Skipped := IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. CRM Job ID", JobId);
                "Last Synch. CRM Job ID" := JobId;
                "Last Synch. CRM Result" := "Last Synch. CRM Result"::Failure
            end else begin
                if (not Skipped) and ("Last Synch. Result" = "Last Synch. Result"::Failure) then
                    Skipped := IsSameFailureRepeatedTwice(SourceRecRef, "Last Synch. Job ID", JobId);
                "Last Synch. Job ID" := JobId;
                "Last Synch. Result" := "Last Synch. Result"::Failure;
            end;
            Modify(true);
        end;
    end;

    procedure SetLastSynchModifiedOns(SourceCRMID: Guid; DestinationTableID: Integer; CRMLastModifiedOn: DateTime; LastModifiedOn: DateTime; JobId: Guid; Direction: Option)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if FindRowFromCRMID(SourceCRMID, DestinationTableID, CRMIntegrationRecord) then
            with CRMIntegrationRecord do begin
                case Direction of
                    IntegrationTableMapping.Direction::FromIntegrationTable:
                        begin
                            "Last Synch. Job ID" := JobId;
                            "Last Synch. Result" := "Last Synch. Result"::Success;
                        end;
                    IntegrationTableMapping.Direction::ToIntegrationTable:
                        begin
                            "Last Synch. CRM Job ID" := JobId;
                            "Last Synch. CRM Result" := "Last Synch. CRM Result"::Success;
                        end;
                end;
                "Last Synch. Modified On" := LastModifiedOn;
                "Last Synch. CRM Modified On" := CRMLastModifiedOn;
                Modify(true);
            end;
    end;

    procedure SetLastSynchCRMModifiedOn(CRMID: Guid; DestinationTableID: Integer; CRMLastModifiedOn: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then begin
            CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMLastModifiedOn;
            CRMIntegrationRecord.Modify(true);
        end;
    end;

    local procedure IsSameFailureRepeatedTwice(RecRef: RecordRef; LastJobID: Guid; NewJobID: Guid): Boolean
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        LastError: Text;
        NewError: Text;
    begin
        if IsNullGuid(LastJobID) or IsNullGuid(NewJobID) then
            exit(false);
        if IntegrationSynchJob.Get(LastJobID) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRef.RecordId, IntegrationSynchJobErrors) then
                LastError := IntegrationSynchJobErrors.Message;
        if IntegrationSynchJob.Get(NewJobID) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRef.RecordId, IntegrationSynchJobErrors) then
                NewError := IntegrationSynchJobErrors.Message;
        exit((LastError = NewError) and (NewError <> ''));
    end;

    procedure IsModifiedAfterLastSynchonizedCRMRecord(CRMID: Guid; DestinationTableID: Integer; CurrentModifiedOn: DateTime) IsModified: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TypeHelper: Codeunit "Type Helper";
        Handled: Boolean;
    begin
        OnBeforeIsModifiedAfterLastSynchronizedCRMRecord(CRMID, DestinationTableID, CurrentModifiedOn, IsModified, Handled);
        if Handled then
            exit(IsModified);

        if FindRowFromCRMID(CRMID, DestinationTableID, CRMIntegrationRecord) then
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMIntegrationRecord."Last Synch. CRM Modified On") > 0);
    end;

    procedure IsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime) IsModified: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TypeHelper: Codeunit "Type Helper";
        Handled: Boolean;
    begin
        OnBeforeIsModifiedAfterLastSynchronizedRecord(RecordID, CurrentModifiedOn, IsModified, Handled);
        if Handled then
            exit(IsModified);

        if FindRowFromRecordID(RecordID, CRMIntegrationRecord) then
            exit(TypeHelper.CompareDateTime(CurrentModifiedOn, CRMIntegrationRecord."Last Synch. Modified On") > 0);
    end;

    local procedure UncoupleCRMIDIfRecordDeleted(TableId: Integer; IntegrationId: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecId: RecordId;
    begin
        CRMIntegrationRecord."Table ID" := TableId;
        CRMIntegrationRecord."Integration ID" := IntegrationId;
        if not CRMIntegrationRecord.FindRecordId(RecId) then begin
            if FindRowFromIntegrationID(IntegrationId, CRMIntegrationRecord) then
                CRMIntegrationRecord.Delete();
            exit(true);
        end;
    end;

    procedure DeleteIfRecordDeleted(CRMID: Guid; DestinationTableID: Integer): Boolean
    var
        IntegrationID: Guid;
    begin
        if FindIntegrationIDFromCRMID(CRMID, DestinationTableID, IntegrationID) then
            exit(UncoupleCRMIDIfRecordDeleted(DestinationTableID, IntegrationID));
    end;

    local procedure FindRowFromRecordID(SourceRecordID: RecordID; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    var
        SysId: Guid;
    begin
        if FindSystemIdByRecordId(SysId, SourceRecordID) then
            exit(FindRowFromIntegrationID(SysId, CRMIntegrationRecord));
    end;

    local procedure FindRowFromCRMID(CRMID: Guid; DestinationTableID: Integer; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    begin
        CRMIntegrationRecord.SetRange("CRM ID", CRMID);
        CRMIntegrationRecord.SetFilter("Table ID", Format(DestinationTableID));
        exit(CRMIntegrationRecord.FindFirst);
    end;

    local procedure FindRowFromIntegrationID(IntegrationID: Guid; var CRMIntegrationRecord: Record "CRM Integration Record"): Boolean
    begin
        CRMIntegrationRecord.SetCurrentKey("Integration ID");
        CRMIntegrationRecord.SetFilter("Integration ID", IntegrationID);
        exit(CRMIntegrationRecord.FindFirst);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsModifiedAfterLastSynchronizedCRMRecord(CRMID: Guid; DestinationTableID: Integer; CurrentModifiedOn: DateTime; var IsModified: Boolean; var Handled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime; var IsModified: Boolean; var Handled: Boolean);
    begin
    end;
}

