table 1797 "Data Migration Error"
{
    Caption = 'Data Migration Error';
    ReplicateData = false;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
        }
        field(2; "Migration Type"; Text[250])
        {
            Caption = 'Migration Type';
        }
        field(3; "Destination Table ID"; Integer)
        {
            Caption = 'Destination Table ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Source Staging Table Record ID"; RecordID)
        {
            Caption = 'Source Staging Table Record ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(6; "Scheduled For Retry"; Boolean)
        {
            Caption = 'Scheduled For Retry';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Destination Table ID", "Migration Type")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateEntryWithMessage(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID; ErrorMessage: Text[250])
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        Init;
        if DataMigrationError.FindLast then
            Id := DataMigrationError.Id + 1
        else
            Id := 1;
        Validate("Migration Type", MigrationType);
        Validate("Destination Table ID", DestinationTableId);
        Validate("Source Staging Table Record ID", SourceStagingTableRecordId);
        Validate("Error Message", ErrorMessage);
        Validate("Scheduled For Retry", false);
        Insert(true);

        OnAfterErrorInserted(MigrationType, ErrorMessage);
    end;

    procedure CreateEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        CreateEntryWithMessage(MigrationType, DestinationTableId, SourceStagingTableRecordId, CopyStr(GetLastErrorText, 1, 250));
    end;

    procedure CreateEntryNoStagingTable(MigrationType: Text[250]; DestinationTableId: Integer)
    var
        DummyRecordId: RecordID;
    begin
        CreateEntry(MigrationType, DestinationTableId, DummyRecordId);
    end;

    procedure CreateEntryNoStagingTableWithMessage(MigrationType: Text[250]; DestinationTableId: Integer; ErrorMessage: Text[250])
    var
        DummyRecordId: RecordID;
    begin
        CreateEntryWithMessage(MigrationType, DestinationTableId, DummyRecordId, ErrorMessage);
    end;

    procedure ClearEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        if FindEntry(MigrationType, DestinationTableId, SourceStagingTableRecordId) then
            Delete(true);
    end;

    procedure ClearEntryNoStagingTable(MigrationType: Text[250]; DestinationTableId: Integer)
    var
        DummyRecordId: RecordID;
    begin
        ClearEntry(MigrationType, DestinationTableId, DummyRecordId);
    end;

    procedure FindEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID): Boolean
    begin
        FilterOnParameters(MigrationType, DestinationTableId, SourceStagingTableRecordId);
        exit(FindFirst);
    end;

    procedure ExistsEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID): Boolean
    begin
        FilterOnParameters(MigrationType, DestinationTableId, SourceStagingTableRecordId);
        exit(not IsEmpty);
    end;

    local procedure FilterOnParameters(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        SetRange("Migration Type", MigrationType);
        SetRange("Destination Table ID", DestinationTableId);
        SetRange("Source Staging Table Record ID", SourceStagingTableRecordId);
    end;

    procedure Ignore()
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        RecordRef: RecordRef;
    begin
        RecordRef.Get("Source Staging Table Record ID");
        RecordRef.Delete(true);
        Delete(true);
        DataMigrationStatusFacade.IgnoreErrors("Migration Type", "Destination Table ID", 1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterErrorInserted(MigrationType: Text; ErrorMessage: Text)
    begin
    end;

    procedure GetErrorMessage(MigrationType: Text[250]; SourceRecordId: RecordID; var ErrorMessage: Text[250])
    begin
        SetRange("Migration Type", MigrationType);
        SetRange("Source Staging Table Record ID", SourceRecordId);
        if FindFirst then
            ErrorMessage := "Error Message"
        else
            ErrorMessage := '';
    end;
}

