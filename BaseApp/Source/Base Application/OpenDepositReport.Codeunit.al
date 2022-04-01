codeunit 1507 "Open Deposit Report"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenDepositReport();
    end;
}