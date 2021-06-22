codeunit 1062 "QBD Sync Proxy"
{

    trigger OnRun()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure GetQBDSyncSettings(var Title: Text; var Description: Text; var Enabled: Boolean; var SendToEmail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure SetQBDSyncEnabled(Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure SetQBDSyncSendToEmail(SendToEmail: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure SendEmailInBackground(var Handled: Boolean)
    begin
    end;
}

