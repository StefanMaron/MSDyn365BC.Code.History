namespace Microsoft.Bank.Deposit;

codeunit 1515 "Open P. Bank Deposits L. Page"
{
    trigger OnRun()
    begin
        OnOpenPostedBankDepositsListPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPostedBankDepositsListPage()
    begin
    end;
}