table 4002 "Hybrid Replication Detail"
{
    DataPerCompany = false;
    ReplicateData = false;

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
            OptionMembers = Failed,InProgress,Successful,Warning;
            OptionCaption = 'Failed,In Progress,Successful,Warning';
            DataClassification = SystemMetadata;
        }
        field(10; "Errors"; Blob)
        {
            Description = 'Any errors that occured during the replication.';
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

    procedure GetErrors() Value: Text
    var
        ErrorsInStream: InStream;
    begin
        if Errors.HasValue() then begin
            CalcFields(Errors);
            Errors.CreateInStream(ErrorsInStream, TextEncoding::UTF8);
            ErrorsInStream.ReadText(Value);
        end;
    end;

    procedure SetErrors(Value: Text)
    var
        ErrorsOutStream: OutStream;
    begin
        Errors.CreateOutStream(ErrorsOutStream, TextEncoding::UTF8);
        ErrorsOutStream.WriteText(Value);
    end;

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