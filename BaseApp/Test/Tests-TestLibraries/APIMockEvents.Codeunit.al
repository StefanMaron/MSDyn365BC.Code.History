codeunit 132476 "API Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        MockIsAPIENabled: Boolean;
        MultipleTestHandlersOnEventErr: Label 'There are multiple subscribers competing for the handled in the tests.';

    [EventSubscriber(ObjectType::Codeunit, 5465, 'OnGetIsAPIEnabled', '', false, false)]
    local procedure HandleOnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        if Handled then
            Error(MultipleTestHandlersOnEventErr);

        Handled := true;
        IsAPIEnabled := MockIsAPIENabled;
    end;

    procedure SetIsAPIEnabled(NewIsAPIEnabled: Boolean)
    begin
        MockIsAPIENabled := NewIsAPIEnabled;
    end;
}

