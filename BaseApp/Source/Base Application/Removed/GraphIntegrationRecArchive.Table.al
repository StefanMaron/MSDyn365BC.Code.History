table 5452 "Graph Integration Rec. Archive"
{
    ObsoleteState = Removed;
    ReplicateData = false;
    ObsoleteReason = 'This functionality will be removed. The API that it was integrating to was discontinued.';
    ObsoleteTag = '20.0';
    Caption = 'Graph Integration Rec. Archive';
    DataClassification = CustomerContent;

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
            CalcFormula = lookup("Integration Record"."Table ID" where("Integration ID" = field("Integration ID")));
            Caption = 'Table ID';
            FieldClass = FlowField;
        }
        field(7; ChangeKey; Text[250])
        {
            Caption = 'ChangeKey';
        }
        field(194; "Webhook Notification"; BLOB)
        {
            Caption = 'Webhook Notification';
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

    procedure FindRecordIDFromID(SourceGraphID: Text[250]; DestinationTableID: Integer; var DestinationRecordId: RecordID): Boolean
    var
        GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive";
        IntegrationRecordArchive: Record "Integration Record Archive";
    begin
        if FindRowFromGraphID(SourceGraphID, DestinationTableID, GraphIntegrationRecArchive) then
            if IntegrationRecordArchive.FindByIntegrationId(GraphIntegrationRecArchive."Integration ID") then begin
                DestinationRecordId := IntegrationRecordArchive."Record ID";
                exit(true);
            end;

        exit(false);
    end;

    procedure FindIDFromRecordID(SourceRecordID: RecordID; var DestinationGraphID: Text[250]): Boolean
    var
        GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive";
    begin
        if not FindRowFromRecordID(SourceRecordID, GraphIntegrationRecArchive) then
            exit(false);

        DestinationGraphID := GraphIntegrationRecArchive."Graph ID";
        exit(true);
    end;

    local procedure FindRowFromRecordID(SourceRecordID: RecordID; var GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive"): Boolean
    var
        IntegrationRecordArchive: Record "Integration Record Archive";
    begin
        if not IntegrationRecordArchive.FindByRecordId(SourceRecordID) then
            exit(false);
        exit(FindRowFromIntegrationID(IntegrationRecordArchive."Integration ID", GraphIntegrationRecArchive));
    end;

    local procedure FindRowFromGraphID(GraphID: Text[250]; DestinationTableID: Integer; var GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive"): Boolean
    begin
        GraphIntegrationRecArchive.SetRange("Graph ID", GraphID);
        GraphIntegrationRecArchive.SetFilter("Table ID", Format(DestinationTableID));
        exit(GraphIntegrationRecArchive.FindFirst());
    end;

    local procedure FindRowFromIntegrationID(IntegrationID: Guid; var GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive"): Boolean
    begin
        GraphIntegrationRecArchive.SetCurrentKey("Integration ID");
        GraphIntegrationRecArchive.SetFilter("Integration ID", IntegrationID);
        exit(GraphIntegrationRecArchive.FindFirst());
    end;
}
