table 5377 "Ext Txt ID Integration Record"
{
    Caption = 'Ext Txt ID Integration Record';
    ObsoleteState = Removed;
    ObsoleteReason = 'This functionality will be replaced by the systemID field';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "External ID"; Text[250])
        {
            Caption = 'External ID';
        }
        field(3; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';
            TableRelation = "Integration Record"."Integration ID";
        }
        field(4; "Last Synch. Modified On"; DateTime)
        {
            Caption = 'Last Synch. Modified On';
        }
        field(5; "Last Synch. Ext Modified On"; DateTime)
        {
            Caption = 'Last Synch. Ext Modified On';
        }
        field(6; "Table ID"; Integer)
        {
            CalcFormula = lookup("Integration Record"."Table ID" where("Integration ID" = field("Integration ID")));
            Caption = 'Table ID';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "External ID", "Integration ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IntegrationRecordNotFoundErr: Label 'The integration record for entity %1 was not found.', Comment = '%1 = Record id';
        RecordIdAlreadyMappedErr: Label 'Cannot couple %1 to this external record, because the record is already coupled to key: %2 in external table.', Comment = '%1 ID of the record, %2 ID of the already mapped record';
        CoupledRecordNotFoundErr: Label 'The coupling record for the key ''%1'' and table %2 was not found.', Comment = '%1 = the key of the external record, %2 is the NAV table that this key is linked with.';

    procedure FindRecordIDFromID(SourceExternalID: Text[250]; DestinationTableID: Integer; var DestinationRecordId: RecordID): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        IntegrationRecord: Record "Integration Record";
    begin
        if FindRowFromExternalID(SourceExternalID, DestinationTableID, ExtTxtIDIntegrationRecord) then
            if IntegrationRecord.FindByIntegrationId(ExtTxtIDIntegrationRecord."Integration ID") then begin
                DestinationRecordId := IntegrationRecord."Record ID";
                exit(true);
            end;

        exit(false);
    end;

    local procedure FindRowFromRecordID(SourceRecordID: RecordID; var ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record"): Boolean
    var
        IntegrationRecord: Record "Integration Record";
    begin
        if not IntegrationRecord.FindByRecordId(SourceRecordID) then
            exit(false);
        exit(FindRowFromIntegrationID(IntegrationRecord."Integration ID", ExtTxtIDIntegrationRecord));
    end;

    local procedure FindRowFromExternalID(ExternalID: Text[250]; DestinationTableID: Integer; var ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record"): Boolean
    begin
        ExtTxtIDIntegrationRecord.SetRange("External ID", ExternalID);
        ExtTxtIDIntegrationRecord.SetFilter("Table ID", Format(DestinationTableID));
        exit(ExtTxtIDIntegrationRecord.FindFirst());
    end;

    procedure CoupleExternalIDToRecordID(ExternalID: Text[250]; RecordID: RecordID)
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        IntegrationRecord: Record "Integration Record";
        ExtTxtIDIntegrationRecord2: Record "Ext Txt ID Integration Record";
        ErrExternalID: Text[250];
    begin
        if not IntegrationRecord.FindByRecordId(RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        // Find coupling between External ID and TableNo
        if not FindRowFromExternalID(ExternalID, RecordID.TableNo, ExtTxtIDIntegrationRecord) then
            // Find rogue coupling beteen External ID and table 0
            if not FindRowFromExternalID(ExternalID, 0, ExtTxtIDIntegrationRecord) then begin
                // Find other coupling to the record
                if ExtTxtIDIntegrationRecord2.FindIDFromRecordID(RecordID, ExternalID) then
                    Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1), ExternalID);

                ExtTxtIDIntegrationRecord.Reset();
                ExtTxtIDIntegrationRecord.Init();
                ExtTxtIDIntegrationRecord."External ID" := ExternalID;
                ExtTxtIDIntegrationRecord."Integration ID" := IntegrationRecord."Integration ID";
                ExtTxtIDIntegrationRecord.Insert(true);
                exit;
            end;

        // Update Integration ID
        if ExtTxtIDIntegrationRecord."Integration ID" <> IntegrationRecord."Integration ID" then begin
            if ExtTxtIDIntegrationRecord2.FindIDFromRecordID(RecordID, ErrExternalID) then
                Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));
            ExtTxtIDIntegrationRecord.Rename(ExtTxtIDIntegrationRecord."External ID", IntegrationRecord."Integration ID");
        end;
    end;

    procedure RemoveCouplingToRecord(RecordID: RecordID): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if FindRowFromRecordID(RecordID, ExtTxtIDIntegrationRecord) then begin
            ExtTxtIDIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure RemoveCouplingToExternalID(ExternalID: Text[250]; DestinationTableID: Integer): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if FindRowFromExternalID(ExternalID, DestinationTableID, ExtTxtIDIntegrationRecord) then begin
            ExtTxtIDIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure UpdateCoupledRecordForExternalId(OldExternalId: Text[250]; NewExternalId: Text[250]; TableNo: Integer)
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
        ExtTxtIDIntegrationRecordNew: Record "Ext Txt ID Integration Record";
    begin
        ExtTxtIDIntegrationRecord.SetRange("External ID", OldExternalId);
        ExtTxtIDIntegrationRecord.SetRange("Table ID", TableNo);
        if not ExtTxtIDIntegrationRecord.FindFirst() then
            Error(CoupledRecordNotFoundErr, OldExternalId, TableNo);

        ExtTxtIDIntegrationRecordNew := ExtTxtIDIntegrationRecord;
        ExtTxtIDIntegrationRecordNew."External ID" := NewExternalId;
        ExtTxtIDIntegrationRecord.DeleteAll();
        ExtTxtIDIntegrationRecordNew.Insert();
    end;

    procedure SetLastSynchModifiedOns(SourceExternalID: Text[250]; DestinationTableID: Integer; ExternalLastModifiedOn: DateTime; LastModifiedOn: DateTime)
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if not FindRowFromExternalID(SourceExternalID, DestinationTableID, ExtTxtIDIntegrationRecord) then
            exit;

        ExtTxtIDIntegrationRecord."Last Synch. Ext Modified On" := ExternalLastModifiedOn;
        ExtTxtIDIntegrationRecord."Last Synch. Modified On" := LastModifiedOn;
        ExtTxtIDIntegrationRecord.Modify(true);
    end;

    procedure FindIDFromRecordID(SourceRecordID: RecordID; var DestinationTextID: Text[250]): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if not FindRowFromRecordID(SourceRecordID, ExtTxtIDIntegrationRecord) then
            exit(false);

        DestinationTextID := ExtTxtIDIntegrationRecord."External ID";
        exit(true);
    end;

    local procedure FindRowFromIntegrationID(IntegrationID: Guid; var ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record"): Boolean
    begin
        ExtTxtIDIntegrationRecord.SetCurrentKey("Integration ID");
        ExtTxtIDIntegrationRecord.SetFilter("Integration ID", IntegrationID);
        exit(ExtTxtIDIntegrationRecord.FindFirst());
    end;

    procedure IsModifiedAfterLastSynchonizedExternalRecord(ExternalID: Text[250]; DestinationTableID: Integer; CurrentModifiedOn: DateTime): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if not FindRowFromExternalID(ExternalID, DestinationTableID, ExtTxtIDIntegrationRecord) then
            exit(false);

        exit(RoundDateTime(CurrentModifiedOn) > RoundDateTime(ExtTxtIDIntegrationRecord."Last Synch. Ext Modified On"));
    end;

    procedure IsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime): Boolean
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if not FindRowFromRecordID(RecordID, ExtTxtIDIntegrationRecord) then
            exit(false);

        exit(RoundDateTime(CurrentModifiedOn) > RoundDateTime(ExtTxtIDIntegrationRecord."Last Synch. Modified On"));
    end;

    procedure InsertIntegrationRecordIfNotPresent(RecordRef: RecordRef)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.SetRange("Record ID", RecordRef.RecordId);
        if not IntegrationRecord.FindFirst() then
            InsertIntegrationRecord(RecordRef);
    end;

    procedure InsertIntegrationRecord(RecordRef: RecordRef)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IntegrationRecord.Init();
        IntegrationRecord."Integration ID" := RecordRef.Field(RecordRef.SystemIdNo).Value();

        IntegrationRecord."Record ID" := RecordRef.RecordId;
        IntegrationRecord."Table ID" := RecordRef.Number;
        IntegrationRecord."Modified On" := CurrentDateTime;
        IntegrationRecord.Insert(true);
    end;

    procedure DeleteEmptyExternalIntegrationRecord(DestinationTableId: Integer)
    var
        ExtTxtIDIntegrationRecord: Record "Ext Txt ID Integration Record";
    begin
        if FindRowFromExternalID('', DestinationTableId, ExtTxtIDIntegrationRecord) then
            ExtTxtIDIntegrationRecord.Delete(true);
    end;
}

