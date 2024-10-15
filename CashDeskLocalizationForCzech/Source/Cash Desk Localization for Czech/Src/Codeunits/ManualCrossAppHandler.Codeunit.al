codeunit 31131 "Manual Cross App. Handler CZP"
{
    EventSubscriberInstance = Manual;

    var
        AppliesToIDCode: Code[50];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cross Application Mgt. CZL", 'OnSetAppliesToID', '', false, false)]
    local procedure OnSetAppliesToIDCrossApplication(AppliesToID: Code[50])
    begin
        AppliesToIDCode := AppliesToID;
    end;

    procedure GetAppliesToID(): Code[50]
    begin
        exit(AppliesToIDCode);
    end;
}