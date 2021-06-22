codeunit 131106 "Library - File Mgt Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        BeforeDownloadHandlerActivated: Boolean;
        DisableSending: Boolean;

    [Scope('OnPrem')]
    procedure SetDownloadSubscriberActivated(NewBeforeDownloadHandlerActivated: Boolean)
    begin
        BeforeDownloadHandlerActivated := NewBeforeDownloadHandlerActivated;
    end;

    [EventSubscriber(ObjectType::Codeunit, 419, 'OnBeforeDownloadHandler', '', false, false)]
    local procedure HandleOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        if not BeforeDownloadHandlerActivated then
            exit;

        IsHandled := true;
    end;

}

