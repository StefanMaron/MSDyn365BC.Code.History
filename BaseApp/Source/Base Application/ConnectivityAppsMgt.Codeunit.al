codeunit 7777 "Connectivity Apps Mgt."
{
    procedure IsBankingAppAvailable(): Boolean
    var
        Result: Boolean;
    begin
        OnIsBankingAppAvailable(Result);
        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsBankingAppAvailable(var Result: Boolean)
    begin
    end;
}