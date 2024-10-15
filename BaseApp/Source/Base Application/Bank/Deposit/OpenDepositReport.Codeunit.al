namespace Microsoft.Bank.Deposit;

codeunit 1507 "Open Deposit Report"
{
    trigger OnRun()
    begin
        OnOpenDepositReport();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositReport()
    begin
    end;

}