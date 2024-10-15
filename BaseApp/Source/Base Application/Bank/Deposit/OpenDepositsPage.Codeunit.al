namespace Microsoft.Bank.Deposit;

codeunit 1500 "Open Deposits Page"
{
    trigger OnRun()
    begin
        OnOpenDepositsPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositsPage()
    begin
    end;
}