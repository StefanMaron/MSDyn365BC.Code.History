#if not CLEAN21
codeunit 1514 "Bank Deposit Feature Mgt."
{
    Permissions = TableData "Feature Key" = rm;
    ObsoleteState = Pending;
    ObsoleteReason = 'Bank Deposits feature will be enabled by default';
    ObsoleteTag = '21.0';

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
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositsPage, Page::"Deposits");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositPage, Page::"Deposit");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositListPage, Page::"Deposit List");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositReport, Report::"Deposit");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::DepositTestReport, Report::"Deposit Test Report");
        DepositsPageMgt.SetSetupKey(Enum::"Deposits Page Setup Key"::PostedBankDepositListPage, Page::"Posted Deposit List");
    end;

    procedure DefaultDepositSetup()
    begin
        DisableDepositActions();
    end;

    internal procedure PreviousNADepositStateDetected()
    begin
        OnPreviousNADepositStateDetected();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreviousNADepositStateDetected()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEnabled(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnInitializeFeatureDataUpdateStatus', '', false, false)]
    local procedure HandleOnInitializeFeatureDataUpdateStatus(var FeatureDataUpdateStatus: Record "Feature Data Update Status"; var InitializeHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FeatureKey: Record "Feature Key";
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
            if FeatureKey.WritePermission() then begin
                FeatureKey.Get(FeatureDataUpdateStatus."Feature Key");
                FeatureKey.Enabled := FeatureKey.Enabled::None;
                FeatureKey.Modify();
            end;
            InitializeHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
    var
        BankRecHeader: Record "Bank Rec. Header";
        DepositHeader: Record "Deposit Header";
        Company: Record Company;
    begin
        if FeatureKey.ID <> GetFeatureKeyId() then
            exit;

        if Company.FindSet() then
        repeat
            BankRecHeader.ChangeCompany(Company.Name);
            BankRecHeader.Reset();
            DepositHeader.ChangeCompany(Company.Name);
            DepositHeader.Reset();
            if (not DepositHeader.IsEmpty()) or (not BankRecHeader.IsEmpty()) then
                Error(EnableFeatureErr, Company.Name);
        until Company.Next() = 0;
    end;

    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
        EnableFeatureErr: Label 'You must either post or delete all deposits and bank reconciliation worksheets for company %1 and every company on this environment before enabling Bank Deposits feature.', Comment = '%1 - The name of the company';
        FeatureKeyIdTok: Label 'StandardizedBankReconciliationAndDeposits', Locked = true;
}
#endif