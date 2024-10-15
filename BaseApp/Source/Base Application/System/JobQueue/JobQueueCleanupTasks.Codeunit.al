namespace System.Threading;

codeunit 461 "Job Queue Cleanup Tasks"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
    end;

    internal procedure CleanupJQTasks()
    var
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.CheckAndRefreshCategoryRecoveryTasks();
        JobQueueManagement.FindStaleJobsAndSetError();
    end;

}