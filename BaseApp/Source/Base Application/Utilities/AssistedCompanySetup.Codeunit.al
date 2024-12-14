// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System.Environment.Configuration;
using System.IO;
using System.Threading;
using System.Environment;
using System.Media;
using System.Globalization;

codeunit 1800 "Assisted Company Setup"
{
    Permissions = tabledata "Assisted Company Setup Status" = r,
                  tabledata "G/L Entry" = r;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnRun()
    begin
    end;

    var
        EnableWizardErr: Label 'You cannot enable the assisted company setup for an already active company.';
        NoConfigPackageFileMsg: Label 'There are no configuration package files defined in your system. Assisted company setup will not be fully functional. Please contact your system administrator.';
        CompanyIsBeingSetUpMsg: Label 'The Company is being set up. Please wait...';
        StandardTxt: Label 'Standard', Locked = true;
        EvaluationTxt: Label 'Evaluation', Locked = true;
        ExtendedTxt: Label 'Extended', Locked = true;
        CreatingCompanyMsg: Label 'Creating company...';
        NoPermissionsErr: Label 'You do not have permissions to create a new company. Contact your system administrator.';
        InitialCompanySetupTxt: Label 'Enter company details';
        InitialCompanySetupShortTitleTxt: Label 'Company details';
        InitialCompanySetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115383', Locked = true;
        InitialCompanySetupDescTxt: Label 'Provide your company''s name, address, logo, and other basic information.';
        CompanyEvaluationCategoryTok: Label 'Company Evaluation', Locked = true;
        CompanyEvaluationTxt: Label 'Company Evaluation:%1', Comment = '%1 = Company Evaluation', Locked = true;

    local procedure EnableAssistedCompanySetup(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    var
        GLEntry: Record "G/L Entry";
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        if AssistedSetupEnabled then begin
            GLEntry.ChangeCompany(SetupCompanyName);
            if not GLEntry.IsEmpty() then
                Error(EnableWizardErr);
            if ConfigurationPackageFile.IsEmpty() then
                Message(NoConfigPackageFileMsg);
        end;
    end;

    local procedure RunAssistedCompanySetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if not GuiAllowed then
            exit;

        if CompanyActive() then
            exit;

        if not AssistedSetupEnabled() then
            exit;

        if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard") then
            exit;

        Commit(); // Make sure all data is committed before we run the wizard

        GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, PAGE::"Assisted Company Setup Wizard");
    end;

    procedure ApplyUserInput(var TempConfigSetup: Record "Config. Setup" temporary; var BankAccount: Record "Bank Account"; AccountingPeriodStartDate: Date; SkipSetupCompanyInfo: Boolean)
    begin
        if not SkipSetupCompanyInfo then
            TempConfigSetup.CopyCompInfo();
        CreateAccountingPeriod(AccountingPeriodStartDate);
        SetupCompanyBankAccount(BankAccount);
    end;

#pragma warning disable AS0072
    [Scope('OnPrem')]
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure GetConfigurationPackageFile(ConfigurationPackageFile: Record "Configuration Package File") ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        TempFile: File;
        OutStream: OutStream;
        InStream: InStream;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('rapidstart');
        TempFile.Create(ServerTempFileName);
        TempFile.CreateOutStream(OutStream);
        ConfigurationPackageFile.CalcFields(Package);
        ConfigurationPackageFile.Package.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        TempFile.Close();
    end;
#pragma warning restore AS0072

    procedure CreateAccountingPeriod(StartDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        CreateFiscalYear: Report "Create Fiscal Year";
        DateFormulaVariable: DateFormula;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAccountingPeriod(StartDate, IsHandled);
        if IsHandled then
            exit;

        // The wizard should only setup accounting periods, if non exist.
        if (not AccountingPeriod.IsEmpty) or (StartDate = 0D) then
            exit;

        Evaluate(DateFormulaVariable, '<1M>');
        CreateFiscalYear.InitializeRequest(12, DateFormulaVariable, StartDate);
        CreateFiscalYear.UseRequestPage(false);
        CreateFiscalYear.HideConfirmationDialog(true);
        CreateFiscalYear.RunModal();
    end;

    local procedure SetupCompanyBankAccount(var BankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        CompanyInformation.Get();
        CompanyInformationMgt.UpdateCompanyBankAccount(CompanyInformation, '', BankAccount);
    end;

    local procedure AssistedSetupEnabled(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        exit(AssistedCompanySetupStatus.Get(CompanyName) and AssistedCompanySetupStatus.Enabled);
    end;

    local procedure CompanyActive(): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        if not GLEntry.ReadPermission then
            exit(true);

        exit(not GLEntry.IsEmpty);
    end;

    local procedure FindJobQueueLogEntries(Name: Text[30]; var JobQueueLogEntry: Record "Job Queue Log Entry"): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if not AssistedCompanySetupStatus.Get(Name) then
            exit(false);
        if IsNullGuid(AssistedCompanySetupStatus."Task ID") then
            exit(false);
        JobQueueLogEntry.SetRange(ID, AssistedCompanySetupStatus."Task ID");
        exit(JobQueueLogEntry.FindLast());
    end;

    local procedure GetCompanySetupStatus(Name: Text[30]): Enum "Company Setup Status"
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if AssistedCompanySetupStatus.Get(Name) then
            if IsNullGuid(AssistedCompanySetupStatus."Task ID") then
                exit(Enum::"Company Setup Status"::Completed);

        if not JobQueueLogEntry.ChangeCompany(Name) then
            exit(Enum::"Company Setup Status"::"Missing Permission");

        if not JobQueueLogEntry.ReadPermission then
            exit(Enum::"Company Setup Status"::"Missing Permission");

        if IsCompanySetupInProgress(Name) then
            exit(Enum::"Company Setup Status"::"In Progress");

        if FindJobQueueLogEntries(Name, JobQueueLogEntry) then
            exit(Enum::"Company Setup Status".FromInteger(JobQueueLogEntry.Status + 1));

        exit(Enum::"Company Setup Status"::" ");
    end;

    procedure IsCompanySetupInProgress(NewCompanyName: Text): Boolean
    var
        ActiveSession: Record "Active Session";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if AssistedCompanySetupStatus.Get(NewCompanyName) then
            if AssistedCompanySetupStatus."Company Setup Session ID" <> 0 then
                exit(ActiveSession.Get(AssistedCompanySetupStatus."Server Instance ID", AssistedCompanySetupStatus."Company Setup Session ID"));
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure WaitForPackageImportToComplete()
    var
        Window: Dialog;
    begin
        if IsCompanySetupInProgress(CompanyName) then begin
            Window.Open(CompanyIsBeingSetUpMsg);
            while IsCompanySetupInProgress(CompanyName) do
                Sleep(1000);
            Window.Close();
        end;
    end;

    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure FillCompanyData(NewCompanyName: Text[30]; NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data")
    var
        Company: Record Company;
        ConfigurationPackageFile: Record "Configuration Package File";
        UserPersonalization: Record "User Personalization";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        if NewCompanyData in [NewCompanyData::"Evaluation Data", NewCompanyData::"Extended Data"] then begin
            Company.Get(NewCompanyName);
            Company."Evaluation Company" := true;
            Company.Modify();
            Commit();
            DataClassificationEvalData.CreateEvaluationData();
            Session.LogMessage('0000HUJ', StrSubstNo(CompanyEvaluationTxt, Company."Evaluation Company"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CompanyEvaluationCategoryTok);
        end;

        UserPersonalization.Get(UserSecurityId());
        if FindConfigurationPackageFile(ConfigurationPackageFile, NewCompanyData) then
            ScheduleConfigPackageImport(ConfigurationPackageFile, NewCompanyName);
    end;
#pragma warning restore AS0072

    local procedure FilterConfigurationPackageFile(var ConfigurationPackageFile: Record "Configuration Package File"; CompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data"): Boolean
    begin
        case CompanyData of
            CompanyData::"Evaluation Data":
                ConfigurationPackageFile.SetFilter(Code, '*' + EvaluationTxt + '*');
            CompanyData::"Standard Data":
                ConfigurationPackageFile.SetFilter(Code, '*' + StandardTxt + '*');
            CompanyData::"Extended Data":
                ConfigurationPackageFile.SetFilter(Code, '*' + ExtendedTxt + '*');
            else
                exit(false);
        end;
        ConfigurationPackageFile.SetRange("Setup Type", ConfigurationPackageFile."Setup Type"::Company);
        ConfigurationPackageFile.SetRange("Language ID", GlobalLanguage);
        if ConfigurationPackageFile.IsEmpty() then
            ConfigurationPackageFile.SetRange("Language ID");
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure ExistsConfigurationPackageFile(CompanyData: Option): Boolean
    var
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        if FilterConfigurationPackageFile(ConfigurationPackageFile, CompanyData) then
            exit(not ConfigurationPackageFile.IsEmpty);
        exit(false);
    end;

    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure FindConfigurationPackageFile(var ConfigurationPackageFile: Record "Configuration Package File"; CompanyData: Option): Boolean
    begin
        if FilterConfigurationPackageFile(ConfigurationPackageFile, CompanyData) then
            exit(ConfigurationPackageFile.FindFirst());
        exit(false);
    end;

    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure ScheduleConfigPackageImport(ConfigurationPackageFile: Record "Configuration Package File"; Name: Text)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        DoNotScheduleTask: Boolean;
        TaskID: Guid;
        ImportSessionID: Integer;
    begin
        AssistedCompanySetupStatus.LockTable();
        AssistedCompanySetupStatus.Get(Name);
        OnBeforeScheduleTask(DoNotScheduleTask, TaskID, ImportSessionID);
        if DoNotScheduleTask then
            AssistedCompanySetupStatus."Task ID" := TaskID
        else begin
            Commit();
            AssistedCompanySetupStatus."Task ID" := CreateGuid();
            ImportSessionID := 0;
            StartSession(ImportSessionID, CODEUNIT::"Import Config. Package File", AssistedCompanySetupStatus."Company Name", ConfigurationPackageFile);
        end;
        AssistedCompanySetupStatus."Company Setup Session ID" := ImportSessionID;
        if AssistedCompanySetupStatus."Company Setup Session ID" = 0 then
            Clear(AssistedCompanySetupStatus."Task ID");
        AssistedCompanySetupStatus.Modify();
        Commit();
    end;
#pragma warning restore AS0072

    local procedure SetApplicationArea(NewCompanyName: Text[30])
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ExperienceTierSetup."Company Name" := NewCompanyName;
        ExperienceTierSetup.Essential := true;
        ExperienceTierSetup.Insert();

        ApplicationAreaMgmt.SetExperienceTierOtherCompany(ExperienceTierSetup, NewCompanyName);
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure SetUpNewCompany(NewCompanyName: Text[30]; NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data")
    begin
        SetUpNewCompany(NewCompanyName, NewCompanyData, false);
    end;

    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    procedure SetUpNewCompany(NewCompanyName: Text[30]; NewCompanyData: Option "Evaluation Data","Standard Data","None","Extended Data","Full No Data"; InstallAdditionalDemoData: Boolean)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Enabled: Boolean;
    begin
        SetApplicationArea(NewCompanyName);

        if not (NewCompanyData in [NewCompanyData::"Evaluation Data", NewCompanyData::"Standard Data", NewCompanyData::None, NewCompanyData::"Extended Data", NewCompanyData::"Full No Data"]) then
            Enabled := true;

        AssistedCompanySetupStatus.SetEnabled(NewCompanyName, Enabled, false);

        OnAfterAssistedCompanySetupStatusEnabled(NewCompanyName, InstallAdditionalDemoData);

        if not (NewCompanyData in [NewCompanyData::None, NewCompanyData::"Full No Data"]) then
            FillCompanyData(NewCompanyName, NewCompanyData)
    end;
#pragma warning restore AS0072

    procedure CreateNewCompany(NewCompanyName: Text[30])
    var
        Company: Record Company;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Window: Dialog;
    begin
        Window.Open(CreatingCompanyMsg);

        Company.Init();
        Company.Name := NewCompanyName;
        Company."Display Name" := NewCompanyName;
        Company.Insert();

        if not GeneralLedgerSetup.ChangeCompany(NewCompanyName) then
            Error(NoPermissionsErr);
        if not GeneralLedgerSetup.WritePermission then
            Error(NoPermissionsErr);

        Commit();

        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure GetAllowedCompaniesForCurrentUser(var TempCompany: Record Company temporary)
    var
        Company: Record Company;
        UserAccountHelper: DotNet NavUserAccountHelper;
        CompanyName: Text[30];
    begin
        TempCompany.DeleteAll();
        foreach CompanyName in UserAccountHelper.GetAllowedCompanies() do
            if Company.Get(CompanyName) then begin
                TempCompany := Company;
                TempCompany.Insert();
            end;
    end;

    [Scope('OnPrem')]
    procedure IsAllowedCompanyForCurrentUser(CompanyName: Text[30]): Boolean
    var
        UserAccountHelper: DotNet NavUserAccountHelper;
        AllowedCompanyName: Text;
    begin
        foreach AllowedCompanyName in UserAccountHelper.GetAllowedCompanies() do
            if CompanyName = AllowedCompanyName then
                exit(true);
        exit(false);
    end;

    procedure AddAssistedCompanySetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        CurrentGlobalLanguage := GLOBALLANGUAGE;
        NavApp.GetCurrentModuleInfo(Info);
        GuidedExperience.InsertAssistedSetup(InitialCompanySetupTxt, InitialCompanySetupShortTitleTxt, InitialCompanySetupDescTxt, 3,
            ObjectType::Page, Page::"Assisted Company Setup Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, InitialCompanySetupHelpTxt);

        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Assisted Company Setup Wizard", Language.GetDefaultApplicationLanguageId(), InitialCompanySetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    local procedure AssistedCompanySetupIsVisible(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if AssistedCompanySetupStatus.Get(CompanyName) then
            exit(AssistedCompanySetupStatus.Enabled);
        exit(false);
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    [IntegrationEvent(false, false)]   
    local procedure OnBeforeScheduleTask(var DoNotScheduleTask: Boolean; var TaskID: Guid; var SessionID: Integer)
    begin
    end;
#pragma warning restore AS0072

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        if AssistedCompanySetupIsVisible() then
            AddAssistedCompanySetup();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnEnabled', '', false, false)]
    local procedure OnEnableAssistedCompanySetup(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    begin
        EnableAssistedCompanySetup(SetupCompanyName, AssistedSetupEnabled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterCompanyOpenRunAssistedCompanySetup()
    begin
        RunAssistedCompanySetup();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Accessible Companies", 'OnBeforeActionEvent', 'Create New Company', false, false)]
    local procedure OnBeforeCreateNewCompanyActionAccessibleCompanies(var Rec: Record Company)
    begin
        PAGE.RunModal(PAGE::"Company Creation Wizard");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Companies", 'OnBeforeActionEvent', 'Create New Company', false, false)]
    local procedure OnBeforeCreateNewCompanyActionOnCompanyPageOpenCompanyCreationWizard(var Rec: Record Company)
    begin
        PAGE.RunModal(PAGE::"Company Creation Wizard");
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnAfterValidateEvent', 'Package Imported', false, false)]
    local procedure OnAfterPackageImportedValidate(var Rec: Record "Assisted Company Setup Status"; var xRec: Record "Assisted Company Setup Status"; CurrFieldNo: Integer)
    begin
        // Send global notification that the new company is ready for use
    end;

    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnAfterValidateEvent', 'Import Failed', false, false)]
    local procedure OnAfterImportFailedValidate(var Rec: Record "Assisted Company Setup Status"; var xRec: Record "Assisted Company Setup Status"; CurrFieldNo: Integer)
    begin
        // Send global notification that the company set up failed
    end;
#pragma warning restore AS0072

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnCompanyChange', '', false, false)]
    local procedure OnCompanyChangeCheckForSetupCompletion(NewCompanyName: Text; var IsSetupInProgress: Boolean)
    begin
        IsSetupInProgress := IsCompanySetupInProgress(NewCompanyName);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnGetCompanySetupStatusValue', '', false, false)]
    local procedure OnGetIsCompanySetupInProgressValue(Name: Text[30]; var SetupStatus: Enum "Company Setup Status")
    begin
        SetupStatus := GetCompanySetupStatus(Name);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnSetupStatusDrillDown', '', false, false)]
    local procedure OnSetupStatusDrillDown(Name: Text[30])
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if not JobQueueLogEntry.ChangeCompany(Name) then
            exit;
        if FindJobQueueLogEntries(Name, JobQueueLogEntry) then
            PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

#pragma warning disable AS0072
    [Obsolete('Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084', '25.2')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistedCompanySetupStatusEnabled(NewCompanyName: Text[30]; InstallAdditionalDemoData: Boolean)
    begin
    end;
#pragma warning restore AS0072

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAccountingPeriod(StartDate: Date; var IsHandled: Boolean)
    begin
    end;
}

