codeunit 1552 "User Callouts Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetAutoStartTours', '', false, false)]
    local procedure CheckIfUserCalloutsAreEnabled(var IsEnabled: Boolean)
    var
        UserCallouts: Record "User Callouts";
    begin
        IsEnabled := UserCallouts.AreCalloutsEnabled(UserSecurityId());
    end;
}