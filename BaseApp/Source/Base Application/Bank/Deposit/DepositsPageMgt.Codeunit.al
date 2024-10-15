#if not CLEAN24
namespace Microsoft.Bank.Deposit;

codeunit 1504 "Deposits Page Mgt."
{
    ObsoleteReason = 'Pages used are the ones from the Bank Deposits extension. No other pages are provided, this codeunit was needed when NA had it''s own pages. Open directly the required pages or run the required reports in the Bank Deposits extension.';
    ObsoleteTag = '24.0';
    ObsoleteState = Pending;

    procedure SetSetupKey(DepositsSetupKey: Enum "Deposits Page Setup Key"; KeyValue: Integer)
    var
        DepositsPageSetup: Record "Deposits Page Setup";
    begin
        if not DepositsPageSetup.Get(DepositsSetupKey) then begin
            DepositsPageSetup.Id := DepositsSetupKey;
            DepositsPageSetup.Insert();
        end;
        DepositsPageSetup.ObjectId := KeyValue;
        DepositsPageSetup.Modify();
    end;

    internal procedure GetDepositsPageSetup(DepositsSetupKey: Enum "Deposits Page Setup Key"; var DepositsPageSetup: Record "Deposits Page Setup"): Boolean
    begin
        exit(DepositsPageSetup.Get(DepositsSetupKey));
    end;

    local procedure OpenPage(DepositsSetupKey: Enum "Deposits Page Setup Key")
    var
        DepositsPageSetup: Record "Deposits Page Setup";
    begin
        if not GetDepositsPageSetup(DepositsSetupKey, DepositsPageSetup) then
            exit;
        Page.Run(DepositsPageSetup.ObjectId);
    end;

    local procedure OpenReport(DepositsSetupKey: Enum "Deposits Page Setup Key")
    var
        DepositsPageSetup: Record "Deposits Page Setup";
    begin
        if not GetDepositsPageSetup(DepositsSetupKey, DepositsPageSetup) then
            exit;
        Report.Run(DepositsPageSetup.ObjectId);
    end;

    procedure OpenDepositsPage()
    begin
        OpenPage(DepositsPageSetupKey::DepositsPage);
    end;

    procedure OpenDepositPage()
    begin
        OpenPage(DepositsPageSetupKey::DepositPage);
    end;

    procedure OpenDepositListPage()
    begin
        OpenPage(DepositsPageSetupKey::DepositListPage);
    end;

    procedure OpenDepositReport()
    begin
        OpenReport(DepositsPageSetupKey::DepositReport);
    end;

    procedure OpenDepositTestReport()
    begin
        OpenReport(DepositsPageSetupKey::DepositTestReport);
    end;

    procedure OpenPostedBankDepositListPage()
    begin
        OpenPage(DepositsPageSetupKey::PostedBankDepositListPage);
    end;


    var
        DepositsPageSetupKey: Enum "Deposits Page Setup Key";
}
#endif