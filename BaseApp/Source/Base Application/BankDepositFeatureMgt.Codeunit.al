codeunit 1514 "Bank Deposit Feature Mgt."
{
    procedure IsEnabled(): Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeIsEnabled(Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(FeatureManagementFacade.IsEnabled(FeatureKeyIdTok));
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    procedure EnableDepositActions()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Init();
            GeneralLedgerSetup.Insert();
        end;
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", true);
        GeneralLedgerSetup.Modify();
    end;

    procedure DisableDepositActions()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Init();
            GeneralLedgerSetup.Insert();
        end;
        GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", false);
        GeneralLedgerSetup.Modify();
#if not CLEAN20
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositsPage, Page::"Deposits");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositPage, Page::"Deposit");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositListPage, Page::"Deposit List");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositReport, Report::"Deposit");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositTestReport, Report::"Deposit Test Report");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::PostedBankDepositListPage, Page::"Posted Deposit List");
#endif
    end;

    procedure DefaultDepositSetup()
    begin
        DisableDepositActions();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEnabled(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN20
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnInitializeFeatureDataUpdateStatus', '', false, false)]
    local procedure HandleOnInitializeFeatureDataUpdateStatus(var FeatureDataUpdateStatus: Record "Feature Data Update Status"; var InitializeHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if InitializeHandled then
            exit;

        if FeatureDataUpdateStatus."Feature Key" <> GetFeatureKeyId() then
            exit;

        if FeatureDataUpdateStatus."Company Name" <> CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name")) then
            exit;

        if not GeneralLedgerSetup.Get() then
            exit;

        if not GeneralLedgerSetup."Bank Recon. with Auto. Match" then begin
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
            InitializeHandled := true;
        end;
    end;
#endif

    var
#if not CLEAN20
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
#endif
        FeatureKeyIdTok: Label 'StandardizedBankReconciliationAndDeposits', Locked = true;
}