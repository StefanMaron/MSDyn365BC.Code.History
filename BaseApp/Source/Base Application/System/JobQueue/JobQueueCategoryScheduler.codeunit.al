namespace System.Threading;

codeunit 451 "Job Queue Category Scheduler"
{
    TableNo = "Job Queue Category";
    InherentPermissions = X;
    Permissions = TableData "Job Queue Category" = rm,
                    TableData "Job Queue Entry" = rm;

    trigger OnRun()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ActivateNextJobInCategory(Rec);

        Clear(Rec."Recovery Task Id");  // current task has been executed
        Clear(Rec."Recovery Task Start Time");

        if JobQueueEntry.AnyReadyJobInCategory(Rec) then
            JobQueueEntry.RefreshRecoveryTask(Rec)
        else
            Rec.Modify();
    end;
}