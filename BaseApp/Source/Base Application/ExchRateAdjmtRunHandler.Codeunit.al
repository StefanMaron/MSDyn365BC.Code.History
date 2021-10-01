codeunit 599 "Exch. Rate Adjmt. Run Handler"
{

    trigger OnRun()
    begin
        RunExchangeRateAdjustment();
    end;

    local procedure RunExchangeRateAdjustment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunExchangeRateAdjustment(IsHandled);
        if IsHandled then
            exit;

        Report.Run(Report::"Adjust Exchange Rates");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunExchangeRateAdjustment(var IsHandled: Boolean)
    begin
    end;
}