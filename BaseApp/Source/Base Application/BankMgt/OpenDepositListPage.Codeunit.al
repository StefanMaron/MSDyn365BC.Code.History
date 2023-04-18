codeunit 1506 "Open Deposit List Page"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenDepositListPage();
    end;
}