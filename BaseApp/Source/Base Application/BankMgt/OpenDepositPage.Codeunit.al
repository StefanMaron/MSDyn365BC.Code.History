codeunit 1505 "Open Deposit Page"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenDepositPage();
    end;
}