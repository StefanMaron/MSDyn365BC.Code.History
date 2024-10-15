codeunit 130625 "Graph Force Sync Subscriber"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Connection Setup", 'OnCheckForceSync', '', false, false)]
    local procedure ForceSyncForTestSubscribers(var Force: Boolean)
    begin
        Force := true;
    end;
}

