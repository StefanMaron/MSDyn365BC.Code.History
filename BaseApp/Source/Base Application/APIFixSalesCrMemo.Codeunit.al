codeunit 5519 "API Fix Sales Cr. Memo"
{
    trigger OnRun()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeSalesCreditMemoReasonCode();
    end;
}