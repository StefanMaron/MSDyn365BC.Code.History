codeunit 1814 "Assisted Setup Subscribers"
{

    var
        ApprovalWorkflowSetupTxt: Label 'Set up approval workflows';
        SMTPSetupTxt: Label 'Set up email';
        OfficeAddinSetupTxt: Label 'Set up your Business Inbox in Outlook';
        ODataWizardTxt: Label 'Set up reporting data';
        DataMigrationTxt: Label 'Migrate business data';
        SetupEmailLoggingTxt: Label 'Set up email logging';
        CustomerAppWorkflowTxt: Label 'Set up a customer approval workflow';
        ItemAppWorkflowTxt: Label 'Set up an item approval workflow';
        PmtJnlAppWorkflowTxt: Label 'Set up a payment approval workflow';
        VATSetupWizardTxt: Label 'Set up VAT';
        VATSetupWizardLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=850305', Locked = true;
        CashFlowForecastTxt: Label 'Set up cash flow forecast';
        CRMConnectionSetupTxt: Label 'Set up %1 connection', Comment = '%1 = CRM product name';
        AzureAdSetupTxt: Label 'Set up Azure Active Directory';
        HelpIntroductiontoFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828702', Locked = true;
        HelpSetupCashFlowForecastTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828693', Locked = true;
        HelpSetupemailTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828689', Locked = true;
        HelpImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828687', Locked = true;
        VideoWorkwithextensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828686', Locked = true;
        VideoWorkwithExcelTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828685', Locked = true;
        VideoWorkwithPowerBITxt: Label 'https://go.microsoft.com/fwlink/?linkid=828684', Locked = true;
        VideoRunyourbusinesswithOffice365Txt: Label 'https://go.microsoft.com/fwlink/?linkid=828683', Locked = true;
        VideoWorkwithgeneraljournalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828682', Locked = true;
        VideoIntrotoDynamics365forFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828681', Locked = true;
        VideoAzureAIforFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828680', Locked = true;
        VideoImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828660', Locked = true;
        HelpSetuptheOfficeaddinTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828690', Locked = true;
        HelpWorkwithPowerBINameTxt: Label 'Work with PowerBI';
        HelpCreateasalesinvoiceNameTxt: Label 'Create a sales invoice';
        HelpAddacustomerNameTxt: Label 'Add a customer';
        HelpAddanitemNameTxt: Label 'Add an item';
        HelpSetupReportingNameTxt: Label 'Set up reporting';
        VideoWorkwithextensionsNameTxt: Label 'Install extensions to add features and integrations';
        VideoWorkwithExcelNameTxt: Label 'Work with Excel';
        VideoWorkwithgeneraljournalsNameTxt: Label 'Work with general journals';
        VideoIntrotoDynamics365forFinancialsNameTxt: Label 'Learn about Dynamics 365';
        VideoAzureAIforFinancialsNameTxt: Label 'AzureAI with Dynamics 365';
        VideoUrlSetupEmailTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843243', Locked = true;
        VideoUrlSetupCRMConnectionTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843244', Locked = true;
        VideoUrlSetupApprovalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843246', Locked = true;
        VideoUrlSetupEmailLoggingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843360', Locked = true;
        YearEndClosingTxt: Label 'Year-end closing';
        VideoUrlYearEndClosingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843361', Locked = true;
        SetupDimensionsTxt: Label 'Set up dimensions';
        VideoUrlSetupDimensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843362', Locked = true;
        CreateJobTxt: Label 'Create a job';
        VideoUrlCreateJobTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843363', Locked = true;
        InviteExternalAccountantTxt: Label 'Invite External Accountant';
        SetupConsolidationReportingTxt: Label 'Set up consolidation reporting';
        AccessAllFeaturesTxt: Label 'Access all features';
        VideoAccessAllFeaturesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857610', Locked = true;
        AnalyzeDataUsingAccSchedulesTxt: Label 'Analyze data using account schedules';
        VideoAnalyzeDataUsingAccSchedulesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857611', Locked = true;
        WorkWithLocAndTransfOrdTxt: Label 'Work with locations and transfer orders';
        VideoWorkWithLocAndTransfOrdTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857612', Locked = true;
        WorkWithPostingGroupsTxt: Label 'Work with posting groups';
        VideoWorkWithPostingGroupsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857613', Locked = true;
        WorkWithVatTxt: Label 'Work with VAT';
        VideoWorkWithVatTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857614', Locked = true;
        IntroductionTxt: Label 'Introduction';
        VideoUrlIntroductionTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867632', Locked = true;
        GettingStartedTxt: Label 'Getting Started';
        VideoUrlGettingStartedTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867634', Locked = true;
        AdditionalReourcesTxt: Label 'Additional Resources';
        VideoUrlAdditionalReourcesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867635', Locked = true;
        CompanyAlreadySetUpQst: Label 'This company is already set up. To change settings for it, go to the Company Information window.\\Go there now?';
        Info: ModuleInfo;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        CRMProductName: Codeunit "CRM Product Name";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        // Getting Started
        AssistedSetup.Add(GetAppId(), PAGE::"Data Migration Wizard", DataMigrationTxt, AssistedSetupGroup::GettingStarted, VideoImportbusinessdataTxt, HelpImportbusinessdataTxt);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"Data Migration Wizard", 1033, DataMigrationTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if AssistedCompanySetupIsVisible then
            if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then
                AssistedCompanySetup.AddAssistedCompanySetup();

        // Analysis

        AssistedSetup.Add(GetAppId(), PAGE::"Cash Flow Forecast Wizard", CashFlowForecastTxt, AssistedSetupGroup::Analysis, '', HelpSetupCashFlowForecastTxt);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"Cash Flow Forecast Wizard", 1033, CashFlowForecastTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Customize for your need
        InitializeCustomize();

        // Setup Group
        AssistedSetup.Add(GetAppId(), PAGE::"OData Setup Wizard", ODataWizardTxt, AssistedSetupGroup::Extensions);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"OData Setup Wizard", 1033, ODataWizardTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Item Approval WF Setup Wizard", ItemAppWorkflowTxt, AssistedSetupGroup::Extensions);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Item Approval WF Setup Wizard", 1033, ItemAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if NOT EnvironmentInfo.IsSaaS then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Azure AD App Setup Wizard", AzureAdSetupTxt, AssistedSetupGroup::Extensions);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Azure AD App Setup Wizard", 1033, AzureAdSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Pmt. App. Workflow Setup Wzrd.", PmtJnlAppWorkflowTxt, AssistedSetupGroup::Extensions);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Pmt. App. Workflow Setup Wzrd.", 1033, PmtJnlAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"CRM Connection Setup Wizard", STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT),
            AssistedSetupGroup::Extensions, VideoUrlSetupCRMConnectionTxt, '');
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"CRM Connection Setup Wizard", 1033, STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT));
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"VAT Setup Wizard", VATSetupWizardTxt, AssistedSetupGroup::Extensions, '', VATSetupWizardLinkTxt);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"VAT Setup Wizard", 1033, VATSetupWizardTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if EnvironmentInfo.IsSaaS then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Invite External Accountant", InviteExternalAccountantTxt, AssistedSetupGroup::Extensions);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Invite External Accountant", 1033, InviteExternalAccountantTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Company Consolidation Wizard", SetupConsolidationReportingTxt, AssistedSetupGroup::Extensions);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Company Consolidation Wizard", 1033, SetupConsolidationReportingTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        UpdateStatus;
    end;

    local procedure InitializeCustomize()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Approval Workflow Setup Wizard", ApprovalWorkflowSetupTxt, AssistedSetupGroup::Customize, VideoUrlSetupApprovalsTxt, '');
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Approval Workflow Setup Wizard", 1033, ApprovalWorkflowSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);

            AssistedSetup.Add(GetAppId(), PAGE::"Cust. Approval WF Setup Wizard", CustomerAppWorkflowTxt, AssistedSetupGroup::Customize);
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Cust. Approval WF Setup Wizard", 1033, CustomerAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"Email Setup Wizard", SMTPSetupTxt, AssistedSetupGroup::Customize, VideoUrlSetupEmailTxt, HelpSetupemailTxt);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"Email Setup Wizard", 1033, SMTPSetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Setup Email Logging", SetupEmailLoggingTxt, AssistedSetupGroup::Customize, VideoUrlSetupEmailLoggingTxt, '');
            GLOBALLANGUAGE(1033);
            AssistedSetup.AddTranslation(GetAppId(), PAGE::"Setup Email Logging", 1033, SetupEmailLoggingTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"Exchange Setup Wizard", OfficeAddinSetupTxt, AssistedSetupGroup::Customize, VideoRunyourbusinesswithOffice365Txt, HelpSetuptheOfficeaddinTxt);
        GLOBALLANGUAGE(1033);
        AssistedSetup.AddTranslation(GetAppId(), PAGE::"Exchange Setup Wizard", 1033, OfficeAddinSetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnReRunOfCompletedSetup', '', false, false)]
    local procedure OnReRunOfCompletedSetup(ExtensionId: Guid; PageID: Integer; var Handled: Boolean)
    begin
        if ExtensionId <> GetAppId() then
            exit;
        case PageID of
            Page::"Assisted Company Setup Wizard":
                begin
                    if Confirm(CompanyAlreadySetUpQst, true) then
                        Page.Run(PAGE::"Company Information");
                    Handled := true;
                end;
        end;
    end;

    local procedure AssistedCompanySetupIsVisible(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        IF AssistedCompanySetupStatus.GET(COMPANYNAME) THEN
            EXIT(AssistedCompanySetupStatus.Enabled);
        EXIT(FALSE);
    end;

    local procedure GetAppId(): Guid
    var
        EmptyGuid: Guid;
    begin
        if Info.Id() = EmptyGuid then
            NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Video, 'OnRegisterVideo', '', false, false)]
    local procedure OnRegisterVideo(sender: Codeunit Video)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin

        sender.Register(GetAppId(), VideoIntrotoDynamics365forFinancialsNameTxt, VideoIntrotoDynamics365forFinancialsTxt);
        sender.Register(GetAppId(), IntroductionTxt, VideoUrlIntroductionTxt);
        sender.Register(GetAppId(), GettingStartedTxt, VideoUrlGettingStartedTxt);
        sender.Register(GetAppId(), AdditionalReourcesTxt, VideoUrlAdditionalReourcesTxt);
        sender.Register(GetAppId(), AccessAllFeaturesTxt, VideoAccessAllFeaturesTxt);

        if EnvironmentInfo.IsSaaS then
            sender.Register(GetAppId(), CreateJobTxt, VideoUrlCreateJobTxt);

        // Warehouse Management
        sender.Register(GetAppId(), WorkWithLocAndTransfOrdTxt, VideoWorkWithLocAndTransfOrdTxt);

        // Journals
        sender.Register(GetAppId(), VideoWorkwithgeneraljournalsNameTxt, VideoWorkwithgeneraljournalsTxt);
        sender.Register(GetAppId(), YearEndClosingTxt, VideoUrlYearEndClosingTxt);
        sender.Register(GetAppId(), WorkWithPostingGroupsTxt, VideoWorkWithPostingGroupsTxt);
        sender.Register(GetAppId(), WorkWithVatTxt, VideoWorkWithVatTxt);

        sender.Register(GetAppId(), VideoAzureAIforFinancialsNameTxt, VideoAzureAIforFinancialsTxt);
        sender.Register(GetAppId(), VideoWorkwithExcelNameTxt, VideoWorkwithExcelTxt);
        sender.Register(GetAppId(), HelpWorkwithPowerBINameTxt, VideoWorkwithPowerBITxt);
        sender.Register(GetAppId(), AnalyzeDataUsingAccSchedulesTxt, VideoAnalyzeDataUsingAccSchedulesTxt);

        sender.Register(GetAppId(), VideoWorkwithextensionsNameTxt, VideoWorkwithextensionsTxt);
    end;

    local procedure UpdateStatus()
    begin
        UpdateSetUpEmail;
        UpdateSetUpApprovalWorkflow;
    end;

    local procedure UpdateSetUpEmail()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        IF not SMTPMailSetup.GetSetup THEN
            exit;
        AssistedSetup.Complete(GetAppId(), PAGE::"Email Setup Wizard");
    end;

    local procedure UpdateSetUpApprovalWorkflow()
    var
        ApprovalUserSetup: Record "User Setup";
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        ApprovalUserSetup.SETFILTER("Approver ID", '<>%1', '');
        IF ApprovalUserSetup.ISEMPTY THEN
            EXIT;

        AssistedSetup.Complete(GetAppId(), PAGE::"Approval Workflow Setup Wizard");
    end;
}

