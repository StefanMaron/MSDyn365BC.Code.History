table 5451 "Graph Integration Record"
{
    Caption = 'Graph Integration Record';

    fields
    {
        field(2; "Graph ID"; Text[250])
        {
            Caption = 'Graph ID';
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
        field(5; "Last Synch. Graph Modified On"; DateTime)
        {
            Caption = 'Last Synch. Graph Modified On';
        }
        field(6; "Table ID"; Integer)
        {
            CalcFormula = Lookup ("Integration Record"."Table ID" WHERE("Integration ID" = FIELD("Integration ID")));
            Caption = 'Table ID';
            FieldClass = FlowField;
        }
        field(7; ChangeKey; Text[250])
        {
            Caption = 'ChangeKey';
        }
        field(8; XRMId; Guid)
        {
            Caption = 'XRMId';
        }
    }

    keys
    {
        key(Key1; "Graph ID", "Integration ID")
        {
            Clustered = true;
        }
        key(Key2; "Integration ID")
        {
        }
        key(Key3; "Last Synch. Modified On", "Integration ID")
        {
        }
        key(Key4; "Last Synch. Graph Modified On", "Graph ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        IntegrationRecordNotFoundErr: Label 'The integration record for entity %1 was not found.', Comment = '%1 = record id';
        GraphIdAlreadyMappedErr: Label 'Cannot couple %1 to this Microsoft Graph record, because the Microsoft Graph record is already coupled to %2.', Comment = '%1 ID of the record, %2 ID of the already mapped record';
        RecordIdAlreadyMappedErr: Label 'Cannot couple the Microsoft Graph record to %1, because %1 is already coupled to another Microsoft Graph record.', Comment = '%1 ID from the record, %2 ID of the already mapped record';

    procedure IsRecordCoupled(DestinationRecordID: RecordID): Boolean
    var
        GraphID: Text[250];
    begin
        exit(FindIDFromRecordID(DestinationRecordID, GraphID));
    end;

    procedure FindRecordIDFromID(SourceGraphID: Text[250]; DestinationTableID: Integer; var DestinationRecordId: RecordID): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
    begin
        if FindRowFromGraphID(SourceGraphID, DestinationTableID, GraphIntegrationRecord) then
            if IntegrationRecord.FindByIntegrationId(GraphIntegrationRecord."Integration ID") then begin
                DestinationRecordId := IntegrationRecord."Record ID";
                exit(true);
            end;

        exit(false);
    end;

    procedure FindIDFromRecordID(SourceRecordID: RecordID; var DestinationGraphID: Text[250]): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        if not FindRowFromRecordID(SourceRecordID, GraphIntegrationRecord) then
            exit(false);

        DestinationGraphID := GraphIntegrationRecord."Graph ID";
        exit(true);
    end;

    local procedure FindIntegrationIDFromGraphID(SourceGraphID: Text[250]; DestinationTableID: Integer; var DestinationIntegrationID: Guid): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        if FindRowFromGraphID(SourceGraphID, DestinationTableID, GraphIntegrationRecord) then begin
            DestinationIntegrationID := GraphIntegrationRecord."Integration ID";
            exit(true);
        end;

        exit(false);
    end;

    procedure CoupleGraphIDToRecordID(GraphID: Text[250]; RecordID: RecordID)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
        GraphIntegrationRecord2: Record "Graph Integration Record";
        ErrGraphID: Text[250];
    begin
        if not IntegrationRecord.FindByRecordId(RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        // Find coupling between GraphID and TableNo
        if not FindRowFromGraphID(GraphID, RecordID.TableNo, GraphIntegrationRecord) then
            // Find rogue coupling beteen GraphID and table 0
            if not FindRowFromGraphID(GraphID, 0, GraphIntegrationRecord) then begin
                // Find other coupling to the record
                if GraphIntegrationRecord2.FindIDFromRecordID(RecordID, ErrGraphID) then
                    Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));

                InsertGraphIntegrationRecord(GraphID, IntegrationRecord, RecordID);
                exit;
            end;

        // Update Integration ID
        if GraphIntegrationRecord."Integration ID" <> IntegrationRecord."Integration ID" then begin
            if GraphIntegrationRecord2.FindIDFromRecordID(RecordID, ErrGraphID) then
                Error(RecordIdAlreadyMappedErr, Format(RecordID, 0, 1));
            GraphIntegrationRecord.Rename(GraphIntegrationRecord."Graph ID", IntegrationRecord."Integration ID");
        end;
    end;

    procedure CoupleRecordIdToGraphID(RecordID: RecordID; GraphID: Text[250])
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
    begin
        if not IntegrationRecord.FindByRecordId(RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        if not FindRowFromIntegrationID(IntegrationRecord."Integration ID", GraphIntegrationRecord) then begin
            AssertRecordIDCanBeCoupled(RecordID, GraphID);
            InsertGraphIntegrationRecord(GraphID, IntegrationRecord, RecordID);
        end else
            if GraphIntegrationRecord."Graph ID" <> GraphID then begin
                AssertRecordIDCanBeCoupled(RecordID, GraphID);
                GraphIntegrationRecord.Rename(GraphID, GraphIntegrationRecord."Integration ID");
            end;
    end;

    procedure RemoveCouplingToRecord(RecordID: RecordID): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationRecord: Record "Integration Record";
    begin
        if not IntegrationRecord.FindByRecordId(RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        if FindRowFromIntegrationID(IntegrationRecord."Integration ID", GraphIntegrationRecord) then begin
            GraphIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure RemoveCouplingToGraphID(GraphID: Text[250]; DestinationTableID: Integer): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        if FindRowFromGraphID(GraphID, DestinationTableID, GraphIntegrationRecord) then begin
            GraphIntegrationRecord.Delete(true);
            exit(true);
        end;
    end;

    procedure AssertRecordIDCanBeCoupled(RecordID: RecordID; GraphID: Text[250])
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        ErrRecordID: RecordID;
        ErrIntegrationID: Guid;
    begin
        if FindIntegrationIDFromGraphID(GraphID, RecordID.TableNo, ErrIntegrationID) then
            if not UncoupleGraphIDIfRecordDeleted(ErrIntegrationID) then begin
                GraphIntegrationRecord.FindRecordIDFromID(GraphID, RecordID.TableNo, ErrRecordID);
                Error(GraphIdAlreadyMappedErr, Format(RecordID, 0, 1), ErrRecordID);
            end;
    end;

    procedure SetLastSynchModifiedOns(SourceGraphID: Text[250]; DestinationTableID: Integer; GraphLastModifiedOn: DateTime; LastModifiedOn: DateTime)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        if not FindRowFromGraphID(SourceGraphID, DestinationTableID, GraphIntegrationRecord) then
            exit;

        with GraphIntegrationRecord do begin
            "Last Synch. Graph Modified On" := GraphLastModifiedOn;
            "Last Synch. Modified On" := LastModifiedOn;
            Modify(true);
            Commit();
        end;
    end;

    procedure SetLastSynchGraphModifiedOn(GraphID: Text[250]; DestinationTableID: Integer; GraphLastModifiedOn: DateTime)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        if not FindRowFromGraphID(GraphID, DestinationTableID, GraphIntegrationRecord) then
            exit;

        GraphIntegrationRecord."Last Synch. Graph Modified On" := GraphLastModifiedOn;
        GraphIntegrationRecord.Modify(true);
        Commit();
    end;

    procedure IsModifiedAfterLastSynchonizedGraphRecord(GraphID: Text[250]; DestinationTableID: Integer; CurrentModifiedOn: DateTime): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GraphDataSetup: Codeunit "Graph Data Setup";
        TypeHelper: Codeunit "Type Helper";
        GraphRecordRef: RecordRef;
        GraphChangeKey: Text[250];
    begin
        if not FindRowFromGraphID(GraphID, DestinationTableID, GraphIntegrationRecord) then
            exit(false);

        GraphIntegrationRecord.CalcFields("Table ID");
        IntegrationTableMapping.FindMappingForTable(GraphIntegrationRecord."Table ID");
        if IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No." <> 0 then
            if GraphDataSetup.GetGraphRecord(GraphRecordRef, GraphID, GraphIntegrationRecord."Table ID") then begin
                GraphChangeKey := GraphRecordRef.Field(IntegrationTableMapping."Int. Tbl. ChangeKey Fld. No.").Value;
                exit(GraphChangeKey <> GraphIntegrationRecord.ChangeKey);
            end;

        exit(TypeHelper.CompareDateTime(CurrentModifiedOn, GraphIntegrationRecord."Last Synch. Graph Modified On") > 0);
    end;

    procedure IsModifiedAfterLastSynchronizedRecord(RecordID: RecordID; CurrentModifiedOn: DateTime): Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        TypeHelper: Codeunit "Type Helper";
    begin
        if not FindRowFromRecordID(RecordID, GraphIntegrationRecord) then
            exit(false);

        exit(TypeHelper.CompareDateTime(CurrentModifiedOn, GraphIntegrationRecord."Last Synch. Modified On") > 0);
    end;

    local procedure UncoupleGraphIDIfRecordDeleted(IntegrationID: Guid): Boolean
    var
        IntegrationRecord: Record "Integration Record";
        GraphIntegrationRecord: Record "Graph Integration Record";
    begin
        IntegrationRecord.FindByIntegrationId(IntegrationID);
        if IntegrationRecord."Deleted On" <> 0DT then begin
            if FindRowFromIntegrationID(IntegrationID, GraphIntegrationRecord) then
                GraphIntegrationRecord.Delete();
            exit(true);
        end;

        exit(false);
    end;

    procedure DeleteIfRecordDeleted(GraphID: Text[250]; DestinationTableID: Integer): Boolean
    var
        IntegrationID: Guid;
    begin
        if not FindIntegrationIDFromGraphID(GraphID, DestinationTableID, IntegrationID) then
            exit(false);

        exit(UncoupleGraphIDIfRecordDeleted(IntegrationID));
    end;

    local procedure FindRowFromRecordID(SourceRecordID: RecordID; var GraphIntegrationRecord: Record "Graph Integration Record"): Boolean
    var
        IntegrationRecord: Record "Integration Record";
    begin
        if not IntegrationRecord.FindByRecordId(SourceRecordID) then
            exit(false);
        exit(FindRowFromIntegrationID(IntegrationRecord."Integration ID", GraphIntegrationRecord));
    end;

    local procedure FindRowFromGraphID(GraphID: Text[250]; DestinationTableID: Integer; var GraphIntegrationRecord: Record "Graph Integration Record"): Boolean
    begin
        GraphIntegrationRecord.SetRange("Graph ID", GraphID);
        GraphIntegrationRecord.SetFilter("Table ID", Format(DestinationTableID));
        exit(GraphIntegrationRecord.FindFirst);
    end;

    local procedure FindRowFromIntegrationID(IntegrationID: Guid; var GraphIntegrationRecord: Record "Graph Integration Record"): Boolean
    begin
        GraphIntegrationRecord.SetCurrentKey("Integration ID");
        GraphIntegrationRecord.SetFilter("Integration ID", IntegrationID);
        exit(GraphIntegrationRecord.FindFirst);
    end;

    local procedure InsertGraphIntegrationRecord(GraphID: Text[250]; var IntegrationRecord: Record "Integration Record"; RecordID: RecordID)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphIntContact: Codeunit "Graph Int. - Contact";
    begin
        GraphIntegrationRecord."Graph ID" := GraphID;
        GraphIntegrationRecord."Integration ID" := IntegrationRecord."Integration ID";
        GraphIntegrationRecord."Table ID" := RecordID.TableNo;
        GraphIntContact.SetXRMId(GraphIntegrationRecord);

        GraphIntegrationRecord.Insert(true);
    end;
}

