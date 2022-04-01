codeunit 1515 "Open P. Bank Deposits L. Page"
{
    trigger OnRun()
    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
    begin
        DepositsPageMgt.OpenPostedBankDepositListPage();
    end;
}