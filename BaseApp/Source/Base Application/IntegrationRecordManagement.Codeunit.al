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
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            TABLECONNECTIONTYPE::MicrosoftGraph:
                exit(GraphIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure FindIntegrationTableUIdByRecordId(IntegrationTableConnectionType: TableConnectionType; SourceRecordId: RecordID; var IntegrationTableUid: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            TABLECONNECTIONTYPE::MicrosoftGraph:
                exit(GraphIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure MarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchResultFailed(SourceRecRef, DirectionToIntTable, JobID);
            TABLECONNECTIONTYPE::MicrosoftGraph,
          TABLECONNECTIONTYPE::ExternalSQL:
                ;
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.CoupleCRMIDToRecordID(IntegrationTableUid, RecordId);
            TABLECONNECTIONTYPE::MicrosoftGraph:
                GraphIntegrationRecord.CoupleGraphIDToRecordID(IntegrationTableUid, RecordId);
            TABLECONNECTIONTYPE::ExternalSQL:
                ExtTxtIDIntegrationRecord.CoupleExternalIDToRecordID(IntegrationTableUid, RecordId);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableTimestamp(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; IntegrationTableModfiedOn: DateTime; TableID: Integer; ModifiedOn: DateTime; JobID: Guid; Direction: Option)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchModifiedOns(
                  IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn, JobID, Direction);
            TABLECONNECTIONTYPE::MicrosoftGraph:
                GraphIntegrationRecord.SetLastSynchModifiedOns(IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn);
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
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(IntegrationTableUid, DestinationTableId, LastModifiedOn));
            TABLECONNECTIONTYPE::MicrosoftGraph:
                exit(
                  GraphIntegrationRecord.IsModifiedAfterLastSynchonizedGraphRecord(IntegrationTableUid, DestinationTableId, LastModifiedOn));
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
        GraphIntegrationRecord: Record "Graph Integration Record";
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            TABLECONNECTIONTYPE::MicrosoftGraph:
                exit(GraphIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            TABLECONNECTIONTYPE::ExternalSQL:
                exit(ExtTxtIDIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;
}

