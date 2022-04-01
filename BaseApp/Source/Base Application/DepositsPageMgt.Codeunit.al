codeunit 1504 "Deposits Page Mgt."
{
    procedure PromptDepositFeature(): Boolean
    begin
        if not Confirm(MisconfiguredDepositsExtensionErr) then
            exit(false);
        Page.Run(Page::"Feature Management");
        exit(true);
    end;

    local procedure GetDepositsPageSetup(DepositsSetupKey: Enum "Deposits Page Setup Key"; var DepositsPageSetup: Record "Deposits Page Setup"): Boolean
    var
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
    begin
        if DepositsPageSetup.Get(DepositsSetupKey) then
            exit(true);

        if BankDepositFeatureMgt.IsEnabled() then begin
            FeatureKey.Get(BankDepositFeatureMgt.GetFeatureKeyId());
            FeatureManagementFacade.AfterValidateEnabled(FeatureKey);
            DepositsPageSetup.Get(DepositsSetupKey);
            exit(true);
        end;

        BankDepositFeatureMgt.DefaultDepositSetup();
        if DepositsPageSetup.Get(DepositsSetupKey) then
            exit(true);
        PromptDepositFeature();
        exit(false);
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
        MisconfiguredDepositsExtensionErr: Label 'The deposits functionality is not yet switched on. Do you want to switch it on in the Feature Management page now?';

}