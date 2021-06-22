codeunit 1061 "QBO Sync Proxy"
{

    trigger OnRun()
    begin
    end;

    var
        AuthUrl: Text;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetQBOSyncSettings(var Title: Text; var Description: Text; var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnGetQBOAuthURL()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetQBOSyncEnabled(Enabled: Boolean)
    begin
    end;

    [Scope('OnPrem')]
    procedure GetQBOAuthURL(): Text
    begin
        exit(AuthUrl);
    end;

    [Scope('OnPrem')]
    procedure SetQBOAuthURL(Value: Text)
    begin
        AuthUrl := Value;
    end;
}

