namespace Microsoft.Utilities;

codeunit 1332 "Template Feature Mgt."
{
    trigger OnRun()
    begin
    end;

    procedure IsEnabled() Result: Boolean
    begin
        Result := true;
        OnAfterIsEnabled(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;
}