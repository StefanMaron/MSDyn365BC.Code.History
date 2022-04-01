codeunit 5338 "Integration Record Management"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be replaced by the systemID field';
    ObsoleteTag = '15.0';

    trigger OnRun()
    begin
    end;

    var
        UnsupportedTableConnectionTypeErr: Label '%1 is not a supported table connection type.';

    procedure FindRecordIdByIntegrationTableUid(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableId: Integer; var DestinationRecordId: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure FindIntegrationTableUIdByRecordId(IntegrationTableConnectionType: TableConnectionType; SourceRecordId: RecordID; var IntegrationTableUid: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure FindIntegrationTableUIdByRecordRef(IntegrationTableConnectionType: TableConnectionType; SourceRecordRef: RecordRef; var IntegrationTableUid: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindIDFromRecordRef(SourceRecordRef, IntegrationTableUid));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.FindIDFromRecordID(SourceRecordRef.RecordId(), IntegrationTableUid));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure MarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid)
    var
        MarkedAsSkipped: Boolean;
    begin
        MarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecRef, DirectionToIntTable, JobID, MarkedAsSkipped);
    end;

    procedure MarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid; var MarkedAsSkipped: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchResultFailed(SourceRecRef, DirectionToIntTable, JobID, MarkedAsSkipped);
            TABLECONNECTIONTYPE::MicrosoftGraph,
          TABLECONNECTIONTYPE::ExternalSQL:
                ;
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsIntegrationRecordSkipped(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Skipped: Boolean;
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                Skipped := CRMIntegrationRecord.IsSkipped(SourceRecRef, DirectionToIntTable);
            TABLECONNECTIONTYPE::MicrosoftGraph,
            TABLECONNECTIONTYPE::ExternalSQL:
                ;
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
        exit(Skipped);
    end;

    procedure UpdateIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.CoupleCRMIDToRecordID(IntegrationTableUid, RecordId);
            TABLECONNECTIONTYPE::ExternalSQL:
                ExtTxtIDIntegrationRecord.CoupleExternalIDToRecordID(IntegrationTableUid, RecordId);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if RecordRef.Number() = 0 then
            exit;
        if IsNullGuid(RecordRef.Field(RecordRef.SystemIdNo()).Value()) then
            exit;
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.CoupleCRMIDToRecordRef(IntegrationTableUid, RecordRef);
            TABLECONNECTIONTYPE::ExternalSQL:
                ExtTxtIDIntegrationRecord.CoupleExternalIDToRecordID(IntegrationTableUid, RecordRef.RecordId());
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordId: RecordID)
    var
        Removed: Boolean;
    begin
        RemoveIntegrationTableCoupling(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordId, Removed);
    end;

    procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordRef: RecordRef)
    var
        Removed: Boolean;
    begin
        RemoveIntegrationTableCoupling(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordRef, Removed);
    end;

    internal procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordId: RecordID; var Removed: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                if RecordId.TableNo() <> 0 then
                    Removed := CRMIntegrationRecord.RemoveCouplingToRecord(RecordId)
                else
                    Removed := CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationTableUid, DestinationTableID);
            TABLECONNECTIONTYPE::ExternalSQL:
                if RecordId.TableNo() <> 0 then
                    Removed := ExtTxtIDIntegrationRecord.RemoveCouplingToRecord(RecordId)
                else
                    Removed := ExtTxtIDIntegrationRecord.RemoveCouplingToExternalID(IntegrationTableUid, DestinationTableID);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    internal procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordRef: RecordRef; var Removed: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        IsNotNull: Boolean;
    begin
        if RecordRef.Number() <> 0 then
            if not IsNullGuid(RecordRef.Field(RecordRef.SystemIdNo()).Value()) then
                IsNotNull := true;
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                if IsNotNull then
                    Removed := CRMIntegrationRecord.RemoveCouplingToRecord(RecordRef)
                else
                    Removed := CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationTableUid, DestinationTableID);
            TABLECONNECTIONTYPE::ExternalSQL:
                if IsNotNull then
                    Removed := ExtTxtIDIntegrationRecord.RemoveCouplingToRecord(RecordRef.RecordId())
                else
                    Removed := ExtTxtIDIntegrationRecord.RemoveCouplingToExternalID(IntegrationTableUid, DestinationTableID);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableTimestamp(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; IntegrationTableModfiedOn: DateTime; TableID: Integer; ModifiedOn: DateTime; JobID: Guid; Direction: Option)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchModifiedOns(
                  IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn, JobID, Direction);
            TABLECONNECTIONTYPE::ExternalSQL:
                ExtTxtIDIntegrationRecord.SetLastSynchModifiedOns(
                  IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterIntegrationTableRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableId: Integer; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(IntegrationTableUid, DestinationTableId, LastModifiedOn));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.IsModifiedAfterLastSynchonizedExternalRecord(IntegrationTableUid, DestinationTableId,
                    LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; SourceRecordID: RecordID; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; SourceRecordRef: RecordRef; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordRef, LastModifiedOn));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordRef.RecordId(), LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;
}

