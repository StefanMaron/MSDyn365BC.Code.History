codeunit 1513 "Open Deposit Test Report"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenDepositTestReport();
    end;
}