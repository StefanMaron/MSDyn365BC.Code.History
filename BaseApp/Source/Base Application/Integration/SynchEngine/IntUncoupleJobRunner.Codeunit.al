codeunit 5358 "Int. Uncouple Job Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get("Record ID to Process");
        RunIntegrationTableUncouple(IntegrationTableMapping, GetLastLogEntryNo());
    end;

    procedure RunIntegrationTableUncouple(IntegrationTableMapping: Record "Integration Table Mapping"; JobLogEntryNo: Integer)
    begin
        IntegrationTableMapping.SetJobLogEntryNo(JobLogEntryNo);
        Codeunit.Run(IntegrationTableMapping."Uncouple Codeunit ID", IntegrationTableMapping);
    end;
}

