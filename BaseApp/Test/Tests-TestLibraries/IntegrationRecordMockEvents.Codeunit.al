codeunit 132478 "Integration Record Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        IsIntegrationEnabled: Boolean;

    [Scope('OnPrem')]
    procedure SetIsIntegrationEnabled(NewIsIntegrationEnabled: Boolean)
    begin
        IsIntegrationEnabled := NewIsIntegrationEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnGetIntegrationActivated', '', false, false)]
    [Scope('OnPrem')]
    procedure OnGetIntegrationActivated(var IsSyncEnabled: Boolean)
    begin
        IsSyncEnabled := IsIntegrationEnabled;
    end;
}

