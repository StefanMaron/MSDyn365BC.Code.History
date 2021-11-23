codeunit 131106 "Library - File Mgt Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        ServerTempFileName: Text;
        BeforeDownloadHandlerActivated: Boolean;
        SaveFileActivated: Boolean;
        DisableSending: Boolean;

    [Scope('OnPrem')]
    procedure SetDownloadSubscriberActivated(NewBeforeDownloadHandlerActivated: Boolean)
    begin
        BeforeDownloadHandlerActivated := NewBeforeDownloadHandlerActivated;
    end;

    procedure SetSaveFileActivated(NewSaveFileActivated: Boolean)
    begin
        SaveFileActivated := NewSaveFileActivated;
    end;

    procedure GetServerTempFileName(): Text
    begin
        exit(ServerTempFileName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure HandleOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        if not BeforeDownloadHandlerActivated then
            exit;

        if SaveFileActivated then begin
            ServerTempFileName := FileMgt.ServerTempFileName(FileMgt.GetExtension(FromFileName));
            FileMgt.CopyServerFile(FromFileName, ServerTempFileName, false);
        end;

        IsHandled := true;
    end;

}

