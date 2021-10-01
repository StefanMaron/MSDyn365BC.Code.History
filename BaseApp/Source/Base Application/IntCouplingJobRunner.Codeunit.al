codeunit 5359 "Int. Coupling Job Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get("Record ID to Process");
        RunIntegrationTableCouple(IntegrationTableMapping, GetLastLogEntryNo());
    end;

    procedure RunIntegrationTableCouple(IntegrationTableMapping: Record "Integration Table Mapping"; JobLogEntryNo: Integer)
    begin
        IntegrationTableMapping.SetJobLogEntryNo(JobLogEntryNo);
        Codeunit.Run(IntegrationTableMapping."Coupling Codeunit ID", IntegrationTableMapping);
    end;
}
