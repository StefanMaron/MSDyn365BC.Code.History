codeunit 1441 "RC Headlines Executor"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        RCHeadlinesUserData: Record "RC Headlines User Data";
        RoleCenterPageID: Integer;
    begin
        Evaluate(RoleCenterPageID, "Parameter String");
        RCHeadlinesUserData.Get(UserSecurityId(), RoleCenterPageID);
        WorkDate := RCHeadlinesUserData."User workdate";
        OnComputeHeadlines(RoleCenterPageID);
    end;


    procedure ScheduleTask(RoleCenterPageID: Integer)
    var
        JQE: Record "Job Queue Entry";
    begin
        JQE.SetRange("Object Type to Run", JQE."Object Type to Run"::Codeunit);
        JQE.SetRange("Object ID to Run", Codeunit::"RC Headlines Executor");
        JQE.SetFilter(Status, '<>%1&<>%2', JQE.Status::"In Process", JQE.Status::Ready);
        JQE.SetRange("Parameter String", Format(RoleCenterPageID));
        if not JQE.IsEmpty() then
            exit;

        JQE.Init();
        JQE."Object Type to Run" := JQE."Object Type to Run"::Codeunit;
        JQE."Object ID to Run" := Codeunit::"RC Headlines Executor";
        JQE."Parameter String" := Format(RoleCenterPageID);

        if not TaskScheduler.CanCreateTask or not JQE.WritePermission then
            Codeunit.Run(Codeunit::"RC Headlines Executor", JQE) // e. g. in tests
        else
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JQE);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnComputeHeadlines(RoleCenterPageID: Integer)
    begin
    end;
}

