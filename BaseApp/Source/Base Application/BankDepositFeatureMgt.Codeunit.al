#if not CLEAN21
codeunit 1514 "Bank Deposit Feature Mgt."
{
    Permissions = TableData "Feature Key" = rm;
    ObsoleteState = Pending;
    ObsoleteReason = 'Bank Deposits feature will be enabled by default';
    ObsoleteTag = '21.0';

    procedure LaunchDeprecationNotification()
    var
        DeprecationNotification: Notification;
    begin
        DeprecationNotification.Message := DeprecationNotificationMsg;
        DeprecationNotification.Scope := NotificationScope::LocalScope;
        DeprecationNotification.AddAction(OpenFeatureMgtMsg, Codeunit::"Deposits Page Mgt.", 'OpenFeatureMgtFromNotification');
        DeprecationNotification.Send();
    end;

    procedure OnBeforeUpgradeToBankDeposits(var DepositsTableId: Integer; var BankRecHeaderTableId: Integer; var BankRecLineTableId: Integer)
    begin
        DepositsTableId := Database::"Deposit Header";
        BankRecHeaderTableId := Database::"Bank Rec. Header";
        BankRecLineTableId := Database::"Bank Rec. Line"
    end;

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
    begin
        SetBankReconwithAutoMatchInAllCompanies(true);
    end;

    procedure DisableDepositActions()
    begin
        SetBankReconwithAutoMatchInAllCompanies(false);
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

    local procedure SetBankReconwithAutoMatchInAllCompanies(NewValue: Boolean)
    var
        Company: Record Company;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if Company.FindSet() then
            repeat
                GeneralLedgerSetup.ChangeCompany(Company.Name);
                if not GeneralLedgerSetup.Get() then begin
                    GeneralLedgerSetup.Init();
                    GeneralLedgerSetup.Insert();
                end;
                GeneralLedgerSetup.Validate("Bank Recon. with Auto. Match", NewValue);
                // Since the OnValidate trigger doesn't work correctly with ChangeCompany, we need to run this code from "Bank Recon. with Auto. Match" OnValidate manually
                SelectReportLayoutsForRecon(Company.Name, NewValue);
                GeneralLedgerSetup.Modify();
            until Company.Next() = 0;
    end;

    local procedure SelectReportLayoutsForRecon(CompanyName: Text[30]; BankReconwithAutoMatch: Boolean)
    begin
        if BankReconwithAutoMatch then
            CheckSelectedReports(Report::"Bank Account Statement", Report::"Bank Acc. Recon. - Test", CompanyName)
        else
            CheckSelectedReports(Report::"Bank Reconciliation", Report::"Bank Rec. Test Report", CompanyName);
    end;

    local procedure CheckSelectedReports(PrintingReportID: Integer; TestingReportID: Integer; CompanyName: Text[30])
    var
        ReportSelections: Record "Report Selections";
    begin
        SelectReport(ReportSelections.Usage::"B.Stmt", PrintingReportID, CompanyName);
        SelectReport(ReportSelections.Usage::"B.Recon.Test", TestingReportID, CompanyName);
    end;

    local procedure SelectReport(UsageValue: Enum "Report Selection Usage"; ReportID: Integer; CompanyName: Text[30])
    var
        ReportSelections: Record "Report Selections";
    begin
        if CompanyName <> '' then
            ReportSelections.ChangeCompany(CompanyName);
        ReportSelections.SetRange(Usage, UsageValue);

        case true of
            ReportSelections.IsEmpty():
                begin
                    ReportSelections.Reset();
                    ReportSelections.InsertRecord(UsageValue, '1', ReportID);
                end;
            ReportSelections.Count() = 1:
                begin
                    ReportSelections.FindFirst();
                    if ReportSelections."Report ID" <> ReportID then begin
                        ReportSelections.Validate("Report ID", ReportID);
                        ReportSelections.Modify();
                    end;
                end;
        end;
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

    var
        DepositsPageMgt: Codeunit "Deposits Page Mgt.";
        FeatureKeyIdTok: Label 'StandardizedBankReconciliationAndDeposits', Locked = true;
        DeprecationNotificationMsg: Label 'This page will be removed in upcoming releases. To continue using this functionality enable the feature: Standardized bank reconciliation and deposits';
        OpenFeatureMgtMsg: Label 'Open the feature management page.';
}
#endif
