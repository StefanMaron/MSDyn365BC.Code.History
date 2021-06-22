codeunit 132475 "Assisted Setup Mock Events"
{
    EventSubscriberInstance = Manual;
    Subtype = Normal;

    var
        FirstTestPageNameTxt: Label 'FIRST TEST Page';
        SecondTestPageNameTxt: Label 'SECOND TEST Page';
        BaseAppID: Codeunit "BaseApp ID";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    [Normal]
    procedure HandleOnRegisterFirstExtensionAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        AssistedSetup.Add(BaseAppID.Get(), PAGE::"Item List", FirstTestPageNameTxt, AssistedSetupGroup::Uncategorized);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    [Normal]
    procedure HandleOnRegisterSecondExtensionAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        AssistedSetup.Add(BaseAppID.Get(), PAGE::"Customer List", SecondTestPageNameTxt, AssistedSetupGroup::Uncategorized);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnAfterRun', '', false, false)]
    [Normal]
    procedure HandleOnUpdateAssistedSetupStatus(ExtensionId: Guid; PageID: Integer)
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
    begin
        if ExtensionId <> BaseAppID.Get() then
            exit;
        if PageID <> PAGE::"Item List" then
            exit;
        AssistedSetup.Complete(ExtensionId, PageID);
    end;    
}

