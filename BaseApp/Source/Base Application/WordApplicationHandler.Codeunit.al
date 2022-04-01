#if not CLEAN19
codeunit 5068 WordApplicationHandler
{
    EventSubscriberInstance = Manual;
    ObsoleteState = Pending;
    ObsoleteReason = 'Word DotNet libraries do not work in any of the supported clients.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordHelper: DotNet WordHelper;
        Active: Boolean;
        ID: Integer;

    procedure Activate(var WordApplicationHandler: Codeunit WordApplicationHandler; HandlerID: Integer)
    begin
        Active := BindSubscription(WordApplicationHandler);
        ID := HandlerID;
    end;

    local procedure CloseApplication()
    begin
        if IsAlive then
            WordHelper.CallQuit(WordApplication, false);
        Clear(WordApplication);
        Active := false;
        ID := 0;
    end;

    [TryFunction]
    procedure IsAlive()
    begin
        // returns FALSE if the application has been terminated
        if WordApplication.Name <> '' then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WordManagement", 'OnFindActiveSubscriber', '', false, false)]
    local procedure OnFindActiveHandler(var IsFound: Boolean)
    begin
        if not IsFound then
            IsFound := Active;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WordManagement", 'OnDeactivate', '', false, false)]
    local procedure OnDeactivateHandler(HandlerID: Integer)
    begin
        if Active and (HandlerID = ID) then
            CloseApplication();
    end;
}

#endif