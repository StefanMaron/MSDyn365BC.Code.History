table 4002 "Hybrid Replication Detail"
{
    DataPerCompany = false;
    ReplicateData = false;

    // This table is populated during the replication process and as such can not be extended.
    Extensible = false;

    fields
    {
        field(1; "Run ID"; Text[50])
        {
            Description = 'The ID of the replication run.';
            TableRelation = "Hybrid Replication Summary"."Run ID";
            DataClassification = SystemMetadata;
        }
        field(2; "Table Name"; Text[250])
        {
            Description = 'The name of the table that was replicated.';
            DataClassification = SystemMetadata;
        }
        field(3; "Company Name"; Text[250])
        {
            Description = 'The name of the company for which the table data was replicated.';
            DataClassification = SystemMetadata;
        }
        field(4; "Start Time"; DateTime)
        {
            Description = 'The start date time of the table replication.';
            DataClassification = SystemMetadata;
        }
        field(5; "End Time"; DateTime)
        {
            Description = 'The end date time of the table replication.';
            DataClassification = SystemMetadata;
        }
        field(8; "Status"; Option)
        {
            Description = 'The status of the table replication.';
            OptionMembers = Failed,InProgress,Successful,Warning,NotStarted;
            OptionCaption = 'Failed,In Progress,Successful,Warning,Not Started';
            DataClassification = SystemMetadata;
        }
        field(10; "Errors"; Blob)
        {
            Description = 'Any errors that occured during the replication.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to the "Error Message" text field.';
            ObsoleteState = Pending;
            ObsoleteTag = 'Pending in 16.0';
        }
        field(11; "Error Code"; Text[10])
        {
            Description = 'The error code for any errors that occured during the replication.';
            DataClassification = SystemMetadata;
        }
        field(12; "Error Message"; Text[2048])
        {
            Description = 'Any errors that occured during the replication.';
            DataClassification = SystemMetadata;
        }
        field(14; "Records Copied"; Integer)
        {
            Description = 'The number of records that were copied for this table.';
            DataClassification = SystemMetadata;
        }
        field(15; "Total Records"; Integer)
        {
            Description = 'The total number of records in the source table.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Run ID", "Table Name", "Company Name")
        {
            Clustered = true;
        }

        key(TableKey; "Table Name", "Company Name")
        {
        }
    }

    [Obsolete('No longer needed with the text field.', 'Obsolete in 16.0')]
    procedure GetErrors() Value: Text
    var
        ErrorInStream: InStream;
    begin
        Value := "Error Message";
        if Value = '' then begin
            Errors.CreateInStream(ErrorInStream, TextEncoding::UTF8);
            ErrorInStream.ReadText(Value);
        end;
    end;

    [Obsolete('No longer needed with the text field.', 'Obsolete in 16.0')]
    procedure SetErrors(Value: Text)
    var
        ErrorsOutStream: OutStream;
    begin
        Errors.CreateOutStream(ErrorsOutStream, TextEncoding::UTF8);
        ErrorsOutStream.WriteText(Value);
        "Error Message" := CopyStr(Value, 1, 2048);
    end;

    [Obsolete('No longer necessary.', 'Obsolete in 16.0')]
    procedure SetFailureStatus(RunId: Text[50]; TableName: Text[250]; CompanyName: Text[250]; FailureMessage: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
    begin
        if not HybridReplicationDetail.Get(RunId, TableName, CompanyName) then begin
            HybridReplicationDetail.Init();
            HybridReplicationDetail."Table Name" := TableName;
            HybridReplicationDetail."Run ID" := RunId;
            HybridReplicationDetail."Company Name" := CompanyName;
            HybridReplicationDetail.Status := HybridReplicationDetail.Status::Failed;
            HybridReplicationDetail.SetErrors(FailureMessage);
            HybridReplicationDetail.Insert();
        end else
            if HybridReplicationDetail.Status = HybridReplicationDetail.Status::Successful then begin
                HybridReplicationDetail.Status := HybridReplicationDetail.Status::Failed;
                HybridReplicationDetail.SetErrors(FailureMessage);
                HybridReplicationDetail.Modify();
            end;
    end;
}