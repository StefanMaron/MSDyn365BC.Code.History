codeunit 5068 WordApplicationHandler
{
    EventSubscriberInstance = Manual;

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

    local procedure GetApplication(): Boolean
    var
        ErrorMessage: Text;
    begin
        if not IsNull(WordApplication) then
            if IsAlive then
                exit(true);
        if not CanLoadType(WordApplication) then
            exit(false);
        WordApplication := WordHelper.GetApplication(ErrorMessage);
        if IsNull(WordApplication) then
            Error(ErrorMessage);
        exit(true);
    end;

    local procedure GetWordApplication(var NewWordApplication: DotNet ApplicationClass): Boolean
    begin
        if GetApplication then
            NewWordApplication := WordApplication
        else
            Clear(NewWordApplication);
        exit(not IsNull(NewWordApplication));
    end;

    [TryFunction]
    procedure IsAlive()
    begin
        // returns FALSE if the application has been terminated
        if WordApplication.Name <> '' then;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnFindActiveSubscriber', '', false, false)]
    local procedure OnFindActiveHandler(var IsFound: Boolean)
    begin
        if not IsFound then
            IsFound := Active;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnGetWord', '', false, false)]
    local procedure OnGetWordApplicationHandler(var NewWordApplication: DotNet ApplicationClass; var IsFound: Boolean)
    begin
        if Active then
            IsFound := GetWordApplication(NewWordApplication);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnDeactivate', '', false, false)]
    local procedure OnDeactivateHandler(HandlerID: Integer)
    begin
        if Active and (HandlerID = ID) then
            CloseApplication;
    end;
}

