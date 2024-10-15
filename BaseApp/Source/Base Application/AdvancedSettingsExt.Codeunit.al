namespace System.Environment.Configuration;

codeunit 9203 "Advanced Settings Ext."
{
    Access = Public;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeOpenCompanySettings(var PageID: Integer; var Handled: Boolean)
    begin
    end;
}