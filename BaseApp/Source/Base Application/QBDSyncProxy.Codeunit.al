codeunit 1062 "QBD Sync Proxy"
{

    trigger OnRun()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetQBDSyncSettings(var Title: Text; var Description: Text; var Enabled: Boolean; var SendToEmail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetQBDSyncEnabled(Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetQBDSyncSendToEmail(SendToEmail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SendEmailInBackground(var Handled: Boolean)
    begin
    end;
}

