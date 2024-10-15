namespace Microsoft.Bank.Deposit;

codeunit 1505 "Open Deposit Page"
{
    trigger OnRun()
    begin
        OnOpenDepositPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositPage()
    begin
    end;
}