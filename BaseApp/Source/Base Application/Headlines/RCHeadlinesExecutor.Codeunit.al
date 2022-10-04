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
        Tomorrow: Date;
    begin
        JQE.SetRange("Object Type to Run", JQE."Object Type to Run"::Codeunit);
        JQE.SetRange("Object ID to Run", Codeunit::"RC Headlines Executor");
        JQE.SetRange("Parameter String", Format(RoleCenterPageID));
        JQE.SetFilter(Status, '%1|%2', JQE.Status::"In Process", JQE.Status::Ready);
        if not JQE.IsEmpty() then
            exit;

        JQE.SetFilter(Status, '%1|%2', JQE.Status::Error, JQE.Status::"On Hold");
        if JQE.FindFirst() then begin
            // restart the job tomorrow
            Tomorrow := CalcDate('<+1d>');
            JQE."Earliest Start Date/Time" := CreateDateTime(Tomorrow, Time());
        end else begin
            // create a new job
            JQE.Init();
            JQE."Object Type to Run" := JQE."Object Type to Run"::Codeunit;
            JQE."Object ID to Run" := Codeunit::"RC Headlines Executor";
            JQE."Parameter String" := Format(RoleCenterPageID);
        end;

        if TaskScheduler.CanCreateTask() and JQE.WritePermission then
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JQE)
        else
            OnTaskSchedulerUnavailable(JQE);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnComputeHeadlines(RoleCenterPageID: Integer)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnTaskSchedulerUnavailable(JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

