table 5339 "Integration Synch. Job Errors"
{
    Caption = 'Integration Synch. Job Errors';

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Synch. Job ID"; Guid)
        {
            Caption = 'Integration Synch. Job ID';
            TableRelation = "Integration Synch. Job".ID;
        }
        field(3; "Source Record ID"; RecordID)
        {
            Caption = 'Source Record ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Destination Record ID"; RecordID)
        {
            Caption = 'Destination Record ID';
            DataClassification = SystemMetadata;
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(6; "Date/Time"; DateTime)
        {
            Caption = 'Date/Time';
        }
        field(7; "Exception Detail"; BLOB)
        {
            Caption = 'Exception Detail';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Integration Synch. Job ID", "Date/Time")
        {
        }
        key(Key3; "Date/Time", "Integration Synch. Job ID")
        {
        }
        key(Key4; "Integration Synch. Job ID")
        {
        }
        key(Key5; "Destination Record ID")
        {
        }
        key(Key6; "Source Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DeleteEntriesQst: Label 'Are you sure that you want to delete the %1 entries?', Comment = '%1 = Integration Synch. Job Errors caption';

    procedure DeleteEntries(DaysOld: Integer)
    begin
        if not Confirm(StrSubstNo(DeleteEntriesQst, TableCaption)) then
            exit;

        SetFilter("Date/Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
        DeleteAll();
        SetRange("Date/Time");
    end;

    procedure LogSynchError(IntegrationSynchJobId: Guid; SourceRecordId: RecordID; DestinationRecordId: RecordID; ErrorMessage: Text)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        StackTraceOutStream: OutStream;
    begin
        with IntegrationSynchJobErrors do begin
            Init;
            "Integration Synch. Job ID" := IntegrationSynchJobId;
            "Source Record ID" := SourceRecordId;
            "Destination Record ID" := DestinationRecordId;
            "Date/Time" := CurrentDateTime;
            Message := CopyStr(ErrorMessage, 1, MaxStrLen(Message));
            "Exception Detail".CreateOutStream(StackTraceOutStream);
            StackTraceOutStream.Write(GetLastErrorCallstack);
            Insert(true);
        end;
        OnAfterLogSynchError(Rec);
    end;

    procedure SetDataIntegrationUIElementsVisible(var DataIntegrationCuesVisible: Boolean)
    begin
        OnIsDataIntegrationEnabled(DataIntegrationCuesVisible);
    end;

    procedure ForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    begin
        OnForceSynchronizeDataIntegration(LocalRecordID, SynchronizeHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDataIntegrationEnabled(var IsIntegrationEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogSynchError(IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    begin
    end;
}

