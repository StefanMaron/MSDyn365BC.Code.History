codeunit 9901 "Data Upgrade In Progress"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 9900, 'OnIsUpgradeInProgress', '', false, false)]
    local procedure OnIsUpgradeInProgressHandler(var UpgradeIsInProgress: Boolean)
    begin
        UpgradeIsInProgress := true;
    end;
}

