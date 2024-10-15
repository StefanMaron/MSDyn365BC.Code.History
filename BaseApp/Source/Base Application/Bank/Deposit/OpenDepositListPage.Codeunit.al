namespace Microsoft.Bank.Deposit;

codeunit 1506 "Open Deposit List Page"
{
    trigger OnRun()
    begin
        OnOpenDepositListPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositListPage()
    begin
    end;
}