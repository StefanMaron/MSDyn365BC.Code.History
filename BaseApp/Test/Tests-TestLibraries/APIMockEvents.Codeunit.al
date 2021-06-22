codeunit 132476 "API Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        MockIsAPIEnabled: Boolean;
        MockIntegrationManagementEnabled: Boolean;
        MultipleTestHandlersOnEventErr: Label 'There are multiple subscribers competing for the handled in the tests.';

    [EventSubscriber(ObjectType::Codeunit, 5465, 'OnGetIsAPIEnabled', '', false, false)]
    local procedure HandleOnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        if Handled then
            Error(MultipleTestHandlersOnEventErr);

        Handled := true;
        IsAPIEnabled := MockIsAPIEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnGetIntegrationEnabledOnSystem', '', false, false)]
    local procedure HandleIsIntegrationManagemntEnabled(var IsEnabled: Boolean)
    begin
        if IsEnabled then
            Error(MultipleTestHandlersOnEventErr);

        IsEnabled := MockIntegrationManagementEnabled;
    end;

    procedure SetIsAPIEnabled(NewIsAPIEnabled: Boolean)
    begin
        MockIsAPIEnabled := NewIsAPIEnabled;
    end;

    procedure SetIsIntegrationManagementEnabled(NewIsIntegrationManagementEnabled: Boolean)
    begin
        MockIntegrationManagementEnabled := NewIsIntegrationManagementEnabled;
    end;
}

