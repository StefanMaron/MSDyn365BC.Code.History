codeunit 132497 MockOnFindTaskSchedulerAllowed
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1543, 'OnFindTaskSchedulerAllowed', '', false, false)]
    local procedure FindTaskSchedulerAllowed(var IsTaskSchedulingAllowed: Boolean)
    begin
        IsTaskSchedulingAllowed := false;
    end;

    [EventSubscriber(ObjectType::Table, 469, 'OnFindTaskSchedulerAllowed', '', false, false)]
    local procedure FindTaskSchedulerAllowedForWFWHSubscription(var IsTaskSchedulingAllowed: Boolean)
    begin
        IsTaskSchedulingAllowed := false;
    end;
}

