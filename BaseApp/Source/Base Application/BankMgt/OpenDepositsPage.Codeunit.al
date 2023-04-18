codeunit 1500 "Open Deposits Page"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenDepositsPage();
    end;

}