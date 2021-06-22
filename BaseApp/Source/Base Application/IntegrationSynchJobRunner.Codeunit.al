codeunit 5339 "Integration Synch. Job Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get("Record ID to Process");
        RunIntegrationTableSynch(IntegrationTableMapping, GetLastLogEntryNo);
    end;

    procedure RunIntegrationTableSynch(IntegrationTableMapping: Record "Integration Table Mapping"; JobLogEntryNo: Integer)
    begin
        IntegrationTableMapping.SetJobLogEntryNo(JobLogEntryNo);
        CODEUNIT.Run(IntegrationTableMapping."Synch. Codeunit ID", IntegrationTableMapping);
    end;
}

