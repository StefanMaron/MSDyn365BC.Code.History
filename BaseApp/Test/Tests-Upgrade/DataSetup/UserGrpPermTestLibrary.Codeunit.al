#if not CLEAN22
#pragma warning disable AS0072
codeunit 132865 "User Grp. Perm. Test Library"
{
    EventSubscriberInstance = Manual;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Grp. Perm. Subscribers", 'OnBeforeGetAppId', '', false, false)]
    local procedure OnBeforeGetAppId(var Skip: Boolean)
    begin
        Skip := true;
    end;
}
#endif