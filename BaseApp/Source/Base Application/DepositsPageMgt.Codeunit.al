codeunit 1504 "Deposits Page Mgt."
{
#if not CLEAN21
    [Obsolete('Bank Deposits feature will be enabled by default', '21.0')]
    procedure PromptDepositFeature(): Boolean
    var
        FeatureKey: Record "Feature Key";
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
        FeatureManagement: Page "Feature Management";
    begin
        if not Confirm(MisconfiguredDepositsExtensionErr) then
            exit(false);
        OpenFeatureMgt();
        exit(true);
    end;
#endif

#if not CLEAN22
    [Obsolete('Bank Deposits feature will be enabled by default', '22.0')]
    procedure OpenFeatureMgtFromNotification(Notification: Notification)
    begin
#if not CLEAN21
        OpenFeatureMgt();
#endif
    end;
#endif

#if not CLEAN21
    local procedure OpenFeatureMgt()
    var
        FeatureKey: Record "Feature Key";
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
        FeatureManagement: Page "Feature Management";
    begin
        if FeatureKey.Get(BankDepositFeatureMgt.GetFeatureKeyId()) then
            FeatureManagement.SetRecord(FeatureKey);
        FeatureManagement.Run();
    end;
#endif

    internal procedure GetDepositsPageSetup(DepositsSetupKey: Enum "Deposits Page Setup Key"; var DepositsPageSetup: Record "Deposits Page Setup"): Boolean
    var
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#if not CLEAN21
        BankDepositFeatureMgt: Codeunit "Bank Deposit Feature Mgt.";
#endif
    begin
        if DepositsPageSetup.Get(DepositsSetupKey) then
            exit(true);

#if not CLEAN21
        if BankDepositFeatureMgt.IsEnabled() then begin
#endif
            FeatureKey.Get(FeatureKeyIdTok);
            FeatureManagementFacade.AfterValidateEnabled(FeatureKey);
            if DepositsPageSetup.Get(DepositsSetupKey) then
                exit(true);
#if not CLEAN21
        end;

        BankDepositFeatureMgt.DefaultDepositSetup();
        if DepositsPageSetup.Get(DepositsSetupKey) then
            exit(true);
        PromptDepositFeature();
#endif
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

#if not CLEAN21
    [Obsolete('Bank Deposits feature will be enabled by default in Business Central Wave 1 2023', '21.0')]
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
#endif

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
#if not CLEAN21
        MisconfiguredDepositsExtensionErr: Label 'The deposits functionality is not yet switched on. Do you want to switch it on in the Feature Management page now?';
#endif
        FeatureKeyIdTok: Label 'StandardizedBankReconciliationAndDeposits', Locked = true;
}