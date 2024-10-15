namespace Microsoft.Bank.Deposit;

codeunit 1513 "Open Deposit Test Report"
{
    trigger OnRun()
    begin
        OnOpenDepositTestReport();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositTestReport()
    begin
    end;

}