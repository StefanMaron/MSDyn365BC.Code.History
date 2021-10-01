codeunit 1814 "Assisted Setup Subscribers"
{

    var
        ApprovalWorkflowSetupTitleTxt: Label 'Set up approval workflows';
        ApprovalWorkflowSetupShortTitleTxt: Label 'Set up approval workflows', MaxLength = 50;
        ApprovalWorkflowSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115466', Locked = true;
        ApprovalWorkflowSetupDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change certain values, such as an amount above a specified limit.';
        EmailSetupTxt: Label 'Set up outgoing email';
        EmailSetupShortTxt: Label 'Outgoing email';
        SMTPSetupDescriptionTxt: Label 'Choose the email account your business will use to send out invoices and other documents. You can use a Microsoft 365 account or another provider.';
        EmailAccountSetupDescriptionTxt: Label 'Set up the email accounts your business will use to send out invoices and other documents. You can use a Microsoft 365 account or another provider.';
        OutlookAddinCentralizedSetupTitleTxt: Label 'Outlook Add-in Centralized Deployment';
        OutlookAddinCentralizedSetupShortTitleTxt: Label 'Outlook Add-in Centralized Deployment', MaxLength = 50;
        OutlookAddinCentralizedSetupDescriptionTxt: Label 'Deploy Outlook add-in for specific users, groups, or the entire organization.';
        TeamsAppCentralizedDeploymentTitleTxt: Label 'Teams App Centralized Deployment';
        TeamsAppCentralizedDeploymentShortTitleTxt: Label 'Teams App Centralized Deployment', MaxLength = 50;
        TeamsAppCentralizedDeploymentDescriptionTxt: Label 'Deploy the Business Central app for Teams for specific users, groups, or the entire organization.';
        ExcelAddinCentralizedDeploymentTitleTxt: Label 'Excel Add-in Centralized Deployment';
        ExcelAddinCentralizedDeploymentShortTitleTxt: Label 'Excel Add-in Centralized Deployment', MaxLength = 50;
        ExcelAddinCentralizedDeploymentDescriptionTxt: Label 'Deploy the Excel add-in for specific users, groups, or the entire organization.';
        DataMigrationTitleTxt: Label 'Migrate business data';
        DataMigrationShortTitleTxt: Label 'Migrate data', MaxLength = 50;
        DataMigrationDescriptionTxt: Label 'Import existing data to Business Central from your former system.';
        SetupExchangeRatesTitleTxt: Label 'Set up exchange rates service';
        SetupExchangeRatesShortTitleTxt: Label 'Set up exchange rates', MaxLength = 50;
        SetupExchangeRatesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115182', Locked = true;
        SetupExchangeRatesVideoTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2117931', Locked = true;
        SetupExchangeRatesDescriptionTxt: Label 'View or update currencies and exchange rates if you buy or sell in currencies other than your local currency or record G/L transactions in different currencies.';
        SetupEmailLoggingTitleTxt: Label 'Set up email logging';
        SetupEmailLoggingShortTitleTxt: Label 'Set up email logging', MaxLength = 50;
        SetupEmailLoggingHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115467';
        SetupEmailLoggingDescriptionTxt: Label 'Track email exchanges between your sales team and your customers and prospects, and then turn the emails into actionable opportunities.';
        CustomizeDocumentLayoutsTitleTxt: Label 'Customize document layouts';
        CustomizeDocumentLayoutsShortTitleTxt: Label 'Customize document layouts', MaxLength = 50;
        CustomizeDocumentLayoutsHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115464', Locked = true;
        CustomizeDocumentLayoutsDescTxt: Label 'Make invoices and other documents look right for your business.';
        CustomerAppWorkflowTitleTxt: Label 'Set up a customer approval workflow';
        CustomerAppWorkflowShortTitleTxt: Label 'Set up customer approval workflow', MaxLength = 50;
        CustomerAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change a customer.';
        ItemAppWorkflowTitleTxt: Label 'Set up an approval workflow to manage inventory items';
        ItemAppWorkflowShortTitleTxt: Label 'Set up an item approval workflow', MaxLength = 50;
        ItemAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change an item.';
        PmtJnlAppWorkflowTitleTxt: Label 'Set up an approval workflow to manage payments';
        PmtJnlAppWorkflowShortTitleTxt: Label 'Set up a payment approval workflow', MaxLength = 50;
        PmtJnlAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user sends payment journal lines for approval.';
        VATSetupWizardShortTitleTxt: Label 'Set up VAT', MaxLength = 50;
        VATSetupWizardTitleTxt: Label 'Set up Value-Added Tax (VAT)';
        VATSetupWizardDescriptionTxt: Label 'Set up VAT to specify the rates to use to calculate tax amounts based on who you sell to, who you buy from, what you sell, and what you buy.';
        VATSetupWizardLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=850305', Locked = true;
        CashFlowForecastTitleTxt: Label 'Configure the Cash Flow Forecast chart';
        CashFlowForecastShortTitleTxt: Label 'Set up cash flow forecasting', MaxLength = 50;
        CashFlowForecastDescriptionTxt: Label 'Specify the accounts to use for the Cash Flow Forecast chart. The guide also helps you specify information about when you pay taxes, and whether to turn on Azure AI.';
        CRMConnectionSetupTitleTxt: Label 'Set up a connection to %1', Comment = '%1 = CRM product name';
        CRMConnectionSetupShortTitleTxt: Label 'Connect to %1', Comment = '%1 = CRM product name', MaxLength = 32;
        CRMConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115256', Locked = true;
        CRMConnectionSetupDescriptionTxt: Label 'Connect your Dynamics 365 services for better insights. Data is exchanged between the apps for better productivity.';
        CDSConnectionSetupTitleTxt: Label 'Set up a connection to Dataverse';
        CDSConnectionSetupShortTitleTxt: Label 'Connect to Dataverse', MaxLength = 50;
        CDSConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115257', Locked = true;
        CDSConnectionSetupDescriptionTxt: Label 'Connect to Dataverse for better insights across business applications. Data will flow between the apps for better productivity.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated';
        AzureAdSetupTitleTxt: Label 'Set up your Azure Active Directory accounts';
        AzureAdSetupShortTitleTxt: Label 'Set up Azure Active Directory', MaxLength = 50;
        AzureAdSetupDescriptionTxt: Label 'Register an Azure Active Directory app so that you can use Power BI, Power Automate, Exchange, and other Azure services from on-premises.';
        HelpIntroductiontoFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828702', Locked = true;
        HelpSetupCashFlowForecastTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828693', Locked = true;
        HelpSetupEmailTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828689', Locked = true;
        HelpImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828687', Locked = true;
        VideoWorkwithextensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828686', Locked = true;
        VideoWorkwithExcelTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828685', Locked = true;
        VideoWorkwithPowerBITxt: Label 'https://go.microsoft.com/fwlink/?linkid=828684', Locked = true;
        VideoRunyourbusinesswithOffice365Txt: Label 'https://go.microsoft.com/fwlink/?linkid=828683', Locked = true;
        VideoWorkwithgeneraljournalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828682', Locked = true;
        VideoIntrotoDynamics365forFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828681', Locked = true;
        VideoAzureAIforFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828680', Locked = true;
        VideoImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828660', Locked = true;
        HelpSetupOutlookCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170959', Locked = true;
        HelpSetupTeamsCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170851', Locked = true;
        HelpSetupExcelCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2163968', Locked = true;
        HelpWorkwithPowerBINameTxt: Label 'Work with Power BI';
        HelpCreateasalesinvoiceNameTxt: Label 'Create a sales invoice';
        HelpAddacustomerNameTxt: Label 'Add a customer';
        HelpAddanitemNameTxt: Label 'Add an item';
        HelpSetupReportingNameTxt: Label 'Set up reporting';
        VideoWorkwithextensionsNameTxt: Label 'Install extensions to add features and integrations';
        VideoWorkwithExcelNameTxt: Label 'Work with Excel';
        VideoWorkwithgeneraljournalsNameTxt: Label 'Work with general journals';
        VideoIntrotoDynamics365forFinancialsNameTxt: Label 'Learn about Dynamics 365';
        VideoAzureAIforFinancialsNameTxt: Label 'Azure AI with Dynamics 365';
        VideoUrlSetupEmailTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843243', Locked = true;
        VideoUrlSetupCRMConnectionTxt: Label '', Locked = true;
        VideoUrlSetupApprovalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843246', Locked = true;
        VideoUrlSetupEmailLoggingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843360', Locked = true;
        SetupDimensionsTxt: Label 'Set up dimensions';
        VideoUrlSetupDimensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843362', Locked = true;
        CreateJobTxt: Label 'Create a job';
        VideoUrlCreateJobTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843363', Locked = true;
        InviteExternalAccountantTitleTxt: Label 'Invite your external accountant to the company';
        InviteExternalAccountantShortTitleTxt: Label 'Invite your external accountant', MaxLength = 50;
        InviteExternalAccountantHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2114063', Locked = true;
        InviteExternalAccountantDescTxt: Label 'Send a link to your external accountant so that they can access your Business Central and manage your books from a dedicated home page.';
        SetupPaymentServicesTitleTxt: Label 'Connect to a payment service';
        SetupPaymentServicesShortTitleTxt: Label 'Set up payment services', MaxLength = 50;
        SetupPaymentServicesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115183', Locked = true;
        SetupPaymentServicesDescriptionTxt: Label 'Connect to a payment service so that your customers can pay you electronically.';
        SetupConsolidationReportingTitleTxt: Label 'Process Consolidations';
        SetupConsolidationReportingShortTitleTxt: Label 'Consolidate companies', MaxLength = 50;
        SetupConsolidationReportingDescriptionTxt: Label 'Consolidate the general ledger entries of two or more separate companies (subsidiaries) into a consolidated company.';
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
        CompanyAlreadySetUpQst: Label 'This company is already set up. To change settings for it, go to the Company Information page.\\Go there now?';
        EmailAlreadySetUpQst: Label 'One or more email accounts are already set up. To change settings for email, go to the Email Accounts page.\\Go there now?';
        Info: ModuleInfo;
        UpdateUsersFromOfficeTitleTxt: Label 'Fetch users from Microsoft 365';
        UpdateUsersFromOfficeShortTitleTxt: Label 'Update users', MaxLength = 50;
        UpdateUsersFromOfficeDescriptionTxt: Label 'Get the latest information about users and licenses for Business Central from Microsoft 365.';
        SetupTimeSheetsTitleTxt: Label 'Set Up Time Sheets';
        SetupTimeSheetsShortTitleTxt: Label 'Set up Time Sheets', MaxLength = 50;
        SetupTimeSheetsHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2166666';
        SetupTimeSheetsDescriptionTxt: Label 'Track the time used on jobs, register absences, or create simple time registrations for team members on any device.';


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        CRMProductName: Codeunit "CRM Product Name";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        // Getting Started
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then
            AssistedCompanySetup.AddAssistedCompanySetup();

        GuidedExperience.InsertAssistedSetup(VATSetupWizardTitleTxt, VATSetupWizardShortTitleTxt, VATSetupWizardDescriptionTxt, 15,
            ObjectType::Page, Page::"VAT Setup Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, VATSetupWizardLinkTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"VAT Setup Wizard", Language.GetDefaultApplicationLanguageId(), VATSetupWizardTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(UpdateUsersFromOfficeTitleTxt, UpdateUsersFromOfficeShortTitleTxt, UpdateUsersFromOfficeDescriptionTxt, 5, ObjectType::Page,
            Page::"Azure AD User Update Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::Uncategorized, '');
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Azure AD User Update Wizard", Language.GetDefaultApplicationLanguageId(), UpdateUsersFromOfficeTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(DataMigrationTitleTxt, DataMigrationShortTitleTxt, DataMigrationDescriptionTxt, 15, ObjectType::Page,
            Page::"Data Migration Wizard", AssistedSetupGroup::ReadyForBusiness, VideoImportbusinessdataTxt, VideoCategory::ReadyForBusiness, HelpImportbusinessdataTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Data Migration Wizard", Language.GetDefaultApplicationLanguageId(), DataMigrationTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupExchangeRatesTitleTxt, SetupExchangeRatesShortTitleTxt, SetupExchangeRatesDescriptionTxt, 10, ObjectType::Page,
            Page::"Curr. Exch. Rate Service List", AssistedSetupGroup::GettingStarted, SetupExchangeRatesVideoTxt, VideoCategory::GettingStarted, SetupExchangeRatesHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Curr. Exch. Rate Service List", Language.GetDefaultApplicationLanguageId(), SetupExchangeRatesTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Outlook Individual Deployment");
#if not CLEAN19
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Exchange Setup Wizard");
#endif

        GuidedExperience.InsertAssistedSetup(OutlookAddinCentralizedSetupTitleTxt, OutlookAddinCentralizedSetupShortTitleTxt, OutlookAddinCentralizedSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"Outlook Centralized Deployment", AssistedSetupGroup::DoMoreWithBC, VideoRunyourbusinesswithOffice365Txt, VideoCategory::DoMoreWithBC, HelpSetupOutlookCentralizedDeploymentTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Outlook Centralized Deployment", Language.GetDefaultApplicationLanguageId(), OutlookAddinCentralizedSetupTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(TeamsAppCentralizedDeploymentTitleTxt, TeamsAppCentralizedDeploymentShortTitleTxt, TeamsAppCentralizedDeploymentDescriptionTxt, 5, ObjectType::Page,
                Page::"Teams Centralized Deployment", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupTeamsCentralizedDeploymentTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Teams Centralized Deployment", Language.GetDefaultApplicationLanguageId(), TeamsAppCentralizedDeploymentTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment");

        GuidedExperience.InsertAssistedSetup(ExcelAddinCentralizedDeploymentTitleTxt, ExcelAddinCentralizedDeploymentShortTitleTxt, ExcelAddinCentralizedDeploymentDescriptionTxt, 5, ObjectType::Page,
            Page::"Excel Centralized Depl. Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupExcelCentralizedDeploymentTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Excel Centralized Depl. Wizard", Language.GetDefaultApplicationLanguageId(), ExcelAddinCentralizedDeploymentTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Analysis
        GuidedExperience.InsertAssistedSetup(CashFlowForecastTitleTxt, CashFlowForecastShortTitleTxt, CashFlowForecastDescriptionTxt, 5, ObjectType::Page,
            Page::"Cash Flow Forecast Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupCashFlowForecastTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Cash Flow Forecast Wizard", Language.GetDefaultApplicationLanguageId(), CashFlowForecastTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Customize for your need
        InitializeCustomize();

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(ItemAppWorkflowTitleTxt, ItemAppWorkflowShortTitleTxt, ItemAppWorkflowDescriptionTxt, 3, ObjectType::Page,
                Page::"Item Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Item Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), ItemAppWorkflowTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if NOT EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(AzureAdSetupTitleTxt, AzureAdSetupShortTitleTxt, AzureAdSetupDescriptionTxt, 5, ObjectType::Page,
                Page::"Azure AD App Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Uncategorized, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Azure AD App Setup Wizard", Language.GetDefaultApplicationLanguageId(), AzureAdSetupTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(PmtJnlAppWorkflowTitleTxt, PmtJnlAppWorkflowShortTitleTxt, PmtJnlAppWorkflowDescriptionTxt, 3, ObjectType::Page,
                Page::"Pmt. App. Workflow Setup Wzrd.", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Pmt. App. Workflow Setup Wzrd.", Language.GetDefaultApplicationLanguageId(), PmtJnlAppWorkflowTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(STRSUBSTNO(CRMConnectionSetupTitleTxt, CRMProductName.SHORT()),
                STRSUBSTNO(CRMConnectionSetupShortTitleTxt, CRMProductName.SHORT()), CRMConnectionSetupDescriptionTxt, 10, ObjectType::Page,
                Page::"CRM Connection Setup Wizard", AssistedSetupGroup::Connect, VideoUrlSetupCRMConnectionTxt, VideoCategory::Connect, CRMConnectionSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"CRM Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), STRSUBSTNO(CRMConnectionSetupTitleTxt, CRMProductName.SHORT()));
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(CDSConnectionSetupTitleTxt, CDSConnectionSetupShortTitleTxt, CDSConnectionSetupDescriptionTxt, 10, ObjectType::Page,
                Page::"CDS Connection Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Connect, CDSConnectionSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"CDS Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), CDSConnectionSetupTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(InviteExternalAccountantTitleTxt, InviteExternalAccountantShortTitleTxt, InviteExternalAccountantDescTxt, 5, ObjectType::Page,
                Page::"Invite External Accountant", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, InviteExternalAccountantHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Invite External Accountant", Language.GetDefaultApplicationLanguageId(), InviteExternalAccountantTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(SetupPaymentServicesTitleTxt, SetupPaymentServicesShortTitleTxt, SetupPaymentServicesDescriptionTxt, 5, ObjectType::Page,
            Page::"Payment Services", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, SetupPaymentServicesHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Payment Services", Language.GetDefaultApplicationLanguageId(), SetupPaymentServicesTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupConsolidationReportingTitleTxt, SetupConsolidationReportingShortTitleTxt, SetupConsolidationReportingDescriptionTxt, 5, ObjectType::Page,
            Page::"Company Consolidation Wizard", AssistedSetupGroup::FinancialReporting, '', VideoCategory::Uncategorized, '');
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Company Consolidation Wizard", Language.GetDefaultApplicationLanguageId(), SetupConsolidationReportingTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        UpdateStatus();
    end;

    local procedure InitializeCustomize()
    var
        EmailFeature: Codeunit "Email Feature";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(ApprovalWorkflowSetupTitleTxt, ApprovalWorkflowSetupShortTitleTxt, ApprovalWorkflowSetupDescriptionTxt, 3, ObjectType::Page,
                Page::"Approval Workflow Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupApprovalsTxt, VideoCategory::ApprovalWorkflows, ApprovalWorkflowSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Approval Workflow Setup Wizard", Language.GetDefaultApplicationLanguageId(), ApprovalWorkflowSetupTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);

            GuidedExperience.InsertAssistedSetup(CustomerAppWorkflowTitleTxt, CustomerAppWorkflowShortTitleTxt, CustomerAppWorkflowDescriptionTxt, 5, ObjectType::Page,
                Page::"Cust. Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Cust. Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), CustomerAppWorkflowTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if EmailFeature.IsEnabled() then begin
            GuidedExperience.InsertAssistedSetup(EmailSetupTxt, CopyStr(EmailSetupShortTxt, 1, 50), EmailAccountSetupDescriptionTxt, 5, ObjectType::Page,
                Page::"Email Account Wizard", AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, HelpSetupEmailTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Email Account Wizard", Language.GetDefaultApplicationLanguageId(), EmailSetupTxt);
            GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Setup Wizard");
        end else begin
            GuidedExperience.InsertAssistedSetup(EmailSetupTxt, CopyStr(EmailSetupTxt, 1, 50), SMTPSetupDescriptionTxt, 7, ObjectType::Page,
                Page::"Email Setup Wizard", AssistedSetupGroup::FirstInvoice, VideoUrlSetupEmailTxt, VideoCategory::FirstInvoice, HelpSetupEmailTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Email Setup Wizard", Language.GetDefaultApplicationLanguageId(), EmailSetupTxt);
            GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Account Wizard");
        end;
        GlobalLanguage(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(SetupEmailLoggingTitleTxt, SetupEmailLoggingShortTitleTxt, SetupEmailLoggingDescriptionTxt, 10, ObjectType::Page,
                Page::"Setup Email Logging", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupEmailLoggingTxt, VideoCategory::ApprovalWorkflows, SetupEmailLoggingHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Setup Email Logging", Language.GetDefaultApplicationLanguageId(), SetupEmailLoggingTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(SetupTimeSheetsTitleTxt, SetupTimeSheetsShortTitleTxt, SetupTimeSheetsDescriptionTxt, 10, ObjectType::Page,
            Page::"Time Sheet Setup Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, SetupTimeSheetsHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Time Sheet Setup Wizard", Language.GetDefaultApplicationLanguageId(), SetupTimeSheetsTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(CustomizeDocumentLayoutsTitleTxt, CustomizeDocumentLayoutsShortTitleTxt, CustomizeDocumentLayoutsDescTxt, 10, ObjectType::Page,
            Page::"Custom Report Layouts", AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, CustomizeDocumentLayoutsHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Custom Report Layouts", Language.GetDefaultApplicationLanguageId(), CustomizeDocumentLayoutsTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnReRunOfCompletedAssistedSetup', '', false, false)]
    local procedure OnReRunOfCompletedSetup(ExtensionId: Guid; ObjectType: ObjectType; ObjectID: Integer; var Handled: Boolean)
    begin
        if ExtensionId <> GetAppId() then
            exit;
        case ObjectID of
            Page::"Assisted Company Setup Wizard":
                begin
                    if Confirm(CompanyAlreadySetUpQst, true) then
                        Page.Run(PAGE::"Company Information");

                    Handled := true;
                end;
            Page::"Email Account Wizard":
                begin
                    if not EmailAccountIsSetup() then
                        exit;

                    if Confirm(EmailAlreadySetUpQst, true) then
                        Page.Run(Page::"Email Accounts");

                    Handled := true;
                end;
        end;
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
        VideoCategory: Enum "Video Category";
    begin

        sender.Register(GetAppId(), VideoIntrotoDynamics365forFinancialsNameTxt, VideoIntrotoDynamics365forFinancialsTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), IntroductionTxt, VideoUrlIntroductionTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), GettingStartedTxt, VideoUrlGettingStartedTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), AdditionalReourcesTxt, VideoUrlAdditionalReourcesTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), AccessAllFeaturesTxt, VideoAccessAllFeaturesTxt, VideoCategory::GettingStarted);

        if EnvironmentInfo.IsSaaS then
            sender.Register(GetAppId(), CreateJobTxt, VideoUrlCreateJobTxt, VideoCategory::GettingStarted);

        // Warehouse Management
        sender.Register(GetAppId(), WorkWithLocAndTransfOrdTxt, VideoWorkWithLocAndTransfOrdTxt, VideoCategory::Warehouse);

        // Journals
        sender.Register(GetAppId(), VideoWorkwithgeneraljournalsNameTxt, VideoWorkwithgeneraljournalsTxt, VideoCategory::Journals);
        sender.Register(GetAppId(), WorkWithPostingGroupsTxt, VideoWorkWithPostingGroupsTxt, VideoCategory::Journals);
        sender.Register(GetAppId(), WorkWithVatTxt, VideoWorkWithVatTxt, VideoCategory::Journals);

        sender.Register(GetAppId(), VideoAzureAIforFinancialsNameTxt, VideoAzureAIforFinancialsTxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), VideoWorkwithExcelNameTxt, VideoWorkwithExcelTxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), HelpWorkwithPowerBINameTxt, VideoWorkwithPowerBITxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), AnalyzeDataUsingAccSchedulesTxt, VideoAnalyzeDataUsingAccSchedulesTxt, VideoCategory::Analysis);

        sender.Register(GetAppId(), VideoWorkwithextensionsNameTxt, VideoWorkwithextensionsTxt, VideoCategory::Extensions);
    end;

    local procedure UpdateStatus()
    begin
        UpdateSetUpEmail;
        UpdateSetUpApprovalWorkflow;
    end;

    local procedure UpdateSetUpEmail()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        EmailAccount: Codeunit "Email Account";
        EmailFeature: Codeunit "Email Feature";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if EmailFeature.IsEnabled() then begin
            if not EmailAccount.IsAnyAccountRegistered() then
                exit;
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Email Account Wizard");
            exit;
        end;

        if not SMTPMailSetup.GetSetup then
            exit;
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Email Setup Wizard");
    end;

    local procedure UpdateSetUpApprovalWorkflow()
    var
        ApprovalUserSetup: Record "User Setup";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        ApprovalUserSetup.SETFILTER("Approver ID", '<>%1', '');
        IF ApprovalUserSetup.ISEMPTY THEN
            EXIT;

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Approval Workflow Setup Wizard");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnAfterRunAssistedSetup', '', false, false)]
    local procedure CompleteEmailAssistedSetup(ExtensionID: Guid; ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if ObjectID <> Page::"Email Account Wizard" then
            exit;

        if not EmailAccountIsSetup() then
            exit;

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Email Account Wizard");
    end;

    local procedure EmailAccountIsSetup(): Boolean
    var
        EmailFeature: Codeunit "Email Feature";
        EmailAccount: Codeunit "Email Account";
    begin
        exit(EmailFeature.IsEnabled() and EmailAccount.IsAnyAccountRegistered());
    end;
}
