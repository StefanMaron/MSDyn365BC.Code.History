#if not CLEAN22
codeunit 132865 "User Grp. Perm. Test Library"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Grp. Perm. Subscribers", 'OnBeforeGetAppId', '', false, false)]
    local procedure OnBeforeGetAppId(var Skip: Boolean)
    begin
        Skip := true;
    end;
}
#endif