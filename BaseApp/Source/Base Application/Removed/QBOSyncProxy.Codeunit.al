codeunit 1061 "QBO Sync Proxy"
{

    trigger OnRun()
    begin
    end;

    var
        AuthUrl: Text;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure GetQBOSyncSettings(var Title: Text; var Description: Text; var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure OnGetQBOAuthURL()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure SetQBOSyncEnabled(Enabled: Boolean)
    begin
    end;

    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure GetQBOAuthURL(): Text
    begin
        exit(AuthUrl);
    end;

    [Scope('OnPrem')]
    [Obsolete('Quickbooks integration to Invoicing is discontinued.', '17.0')]
    procedure SetQBOAuthURL(Value: Text)
    begin
        AuthUrl := Value;
    end;
}

