codeunit 1814 "Assisted Setup Subscribers"
{

    var
        ApprovalWorkflowSetupTxt: Label 'Set up approval workflows';
        ApprovalWorkflowSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115466', Locked = true;
        ApprovalWorkflowSetupDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change certain values on documents, journal lines, or cards, such as an amount above a specified limit.';
        EmailSetupTxt: Label 'Set up outgoing email';
        EmailSetupShortTxt: Label 'Outgoing email';
        SMTPSetupDescriptionTxt: Label 'Choose the email account your business will use to send out invoices and other documents. You can use a Microsoft 365 account or another provider.';
        EmailAccountSetupDescriptionTxt: Label 'Set up the email accounts your business will use to send out invoices and other documents. You can use a Microsoft 365 account or another provider.';
        OfficeAddinSetupTxt: Label 'Set up your Business Inbox in Outlook';
        OfficeAddinSetupDescriptionTxt: Label 'Configure Exchange so that users can complete business tasks without leaving their Outlook inbox.';
        ODataWizardTxt: Label 'Set up reporting data';
        ODataWizardHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115254', Locked = true;
        ODataWizardDescriptionTxt: Label 'Create data sets that you can use for building reports in Excel, Power BI, or any other reporting tool that works with an OData data source.';
        DataMigrationTxt: Label 'Migrate business data';
        DataMigrationShortTxt: Label 'Migrate data';
        DataMigrationDescriptionTxt: Label 'Import existing data to Business Central from your former system.';
        SetupExchangeRatesTxt: Label 'Set up exchange rates';
        SetupExchangeRatesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115182', Locked = true;
        SetupExchangeRatesVideoTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2117931', Locked = true;
        SetupExchangeRatesDescriptionTxt: Label 'Set up exchange rates';
        SetupEmailLoggingTxt: Label 'Set up email logging';
        SetupEmailLoggingHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115467';
        SetupEmailLoggingDescriptionTxt: Label 'Track email exchanges between your sales team and customers and prospects, and then turning them into actionable opportunities.';
        CustomizeDocumentLayoutsTxt: Label 'Customize document layouts';
        CustomizeDocumentLayoutsHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115464', Locked = true;
        CustomizeDocumentLayoutsDescTxt: Label 'Make invoices and other documents look right for your business.';
        CustomerAppWorkflowTxt: Label 'Set up a customer approval workflow';
        CustomerAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change a customer.';
        ItemAppWorkflowTxt: Label 'Set up an item approval workflow';
        ItemAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change an item.';
        PmtJnlAppWorkflowTxt: Label 'Set up a payment approval workflow';
        PmtJnlAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user sends payment journal lines for approval.';
        SalesTaxSetupTxt: Label 'Set up sales tax';
        HelpSetupSalesTaxTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828688', Locked = true;
        VideoUrlSalesTaxSetupTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843242', Locked = true;
        SalesTaxSetupDescriptionTxt: Label 'Set up sales tax information for your company, customers, and vendors.';
        CashFlowForecastTxt: Label 'Set up cash flow forecast';
        CashFlowForecastDescriptionTxt: Label 'Manage your cash flow by automatically analyzing specific general ledger accounts.';
        CRMConnectionSetupTxt: Label 'Set up %1 connection', Comment = '%1 = CRM product name';
        CRMConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115256', Locked = true;
        CRMConnectionSetupDescriptionTxt: Label 'Connect your Dynamics 365 services for better insights.';
        CDSConnectionSetupTxt: Label 'Set up a connection to Microsoft Dataverse';
        CDSConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115257', Locked = true;
        CDSConnectionSetupDescriptionTxt: Label 'Connect to Dataverse for better insights across business applications.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated';
        AzureAdSetupTxt: Label 'Set up Azure Active Directory';
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
        VideoUrlSetupCRMConnectionTxt: Label '', Locked = true;
        VideoUrlSetupApprovalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843246', Locked = true;
        VideoUrlSetupEmailLoggingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843360', Locked = true;
        SetupDimensionsTxt: Label 'Set up dimensions';
        VideoUrlSetupDimensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843362', Locked = true;
        CreateJobTxt: Label 'Create a job';
        VideoUrlCreateJobTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843363', Locked = true;
        InviteExternalAccountantTxt: Label 'Invite external accountant';
        InviteExternalAccountantHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2114063', Locked = true;
        InviteExternalAccountantDescTxt: Label 'Send a link to your external accountant so that they can access your Business Central.';
        SetupPaymentServicesTxt: Label 'Set up payment services';
        SetupPaymentServicesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115183', Locked = true;
        SetupPaymentServicesDescriptionTxt: Label 'Connect to a payment services so that your customers can pay you electronically.';
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
        SetupMexicanCFDITxt: Label 'Enter Mexican CFDI settings';
        CompanyAlreadySetUpQst: Label 'This company is already set up. To change settings for it, go to the Company Information page.\\Go there now?';
        EmailAlreadySetUpQst: Label 'One or more email accounts are already set up. To change settings for email, go to the Email Accounts page.\\Go there now?';
        Info: ModuleInfo;
        UpdateUsersFromOfficeTxt: Label 'Fetch users from Microsoft 365';
        UpdateUsersFromOfficeShortTxt: Label 'Update users';
        UpdateUsersFromOfficeDescriptionTxt: Label 'Get the latest information about users and licenses for Business Central from Microsoft 365.';


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

        GuidedExperience.InsertAssistedSetup(SalesTaxSetupTxt, CopyStr(SalesTaxSetupTxt, 1, 50), SalesTaxSetupDescriptionTxt, 0, ObjectType::Page, PAGE::"Sales Tax Setup Wizard",
            AssistedSetupGroup::GettingStarted, VideoUrlSalesTaxSetupTxt, VideoCategory::GettingStarted, HelpSetupSalesTaxTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Sales Tax Setup Wizard", Language.GetDefaultApplicationLanguageId(), SalesTaxSetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
        UpdateTaxSetupCompleted();

        GuidedExperience.InsertAssistedSetup(UpdateUsersFromOfficeTxt, CopyStr(UpdateUsersFromOfficeShortTxt, 1, 50), UpdateUsersFromOfficeDescriptionTxt, 5, ObjectType::Page,
            Page::"Azure AD User Update Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::Uncategorized, '');
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Azure AD User Update Wizard", Language.GetDefaultApplicationLanguageId(), UpdateUsersFromOfficeTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(DataMigrationTxt, CopyStr(DataMigrationShortTxt, 1, 50), DataMigrationDescriptionTxt, 15, ObjectType::Page,
            Page::"Data Migration Wizard", AssistedSetupGroup::ReadyForBusiness, VideoImportbusinessdataTxt, VideoCategory::ReadyForBusiness, HelpImportbusinessdataTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Data Migration Wizard", Language.GetDefaultApplicationLanguageId(), DataMigrationTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupExchangeRatesTxt, CopyStr(SetupExchangeRatesTxt, 1, 50), SetupExchangeRatesDescriptionTxt, 0, ObjectType::Page,
            Page::"Curr. Exch. Rate Service List", AssistedSetupGroup::GettingStarted, SetupExchangeRatesVideoTxt, VideoCategory::GettingStarted, SetupExchangeRatesHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Curr. Exch. Rate Service List", Language.GetDefaultApplicationLanguageId(), SetupExchangeRatesTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Analysis

        GuidedExperience.InsertAssistedSetup(CashFlowForecastTxt, CopyStr(CashFlowForecastTxt, 1, 50), CashFlowForecastDescriptionTxt, 0, ObjectType::Page,
            Page::"Cash Flow Forecast Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupCashFlowForecastTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Cash Flow Forecast Wizard", Language.GetDefaultApplicationLanguageId(), CashFlowForecastTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Customize for your need
        InitializeCustomize();

        // Setup Group
        GuidedExperience.InsertAssistedSetup(ODataWizardTxt, CopyStr(ODataWizardTxt, 1, 50), ODataWizardDescriptionTxt, 0, ObjectType::Page,
            Page::"OData Setup Wizard", AssistedSetupGroup::FinancialReporting, '', VideoCategory::FinancialReporting, ODataWizardHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"OData Setup Wizard", Language.GetDefaultApplicationLanguageId(), ODataWizardTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(ItemAppWorkflowTxt, CopyStr(ItemAppWorkflowTxt, 1, 50), ItemAppWorkflowDescriptionTxt, 0, ObjectType::Page,
                Page::"Item Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Item Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), ItemAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if NOT EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(AzureAdSetupTxt, CopyStr(AzureAdSetupTxt, 1, 50), '', 0, ObjectType::Page,
                Page::"Azure AD App Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Uncategorized, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Azure AD App Setup Wizard", Language.GetDefaultApplicationLanguageId(), AzureAdSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(PmtJnlAppWorkflowTxt, CopyStr(PmtJnlAppWorkflowTxt, 1, 50), PmtJnlAppWorkflowDescriptionTxt, 0, ObjectType::Page,
                Page::"Pmt. App. Workflow Setup Wzrd.", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Pmt. App. Workflow Setup Wzrd.", Language.GetDefaultApplicationLanguageId(), PmtJnlAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT()),
                CopyStr(STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT()), 1, 50), CRMConnectionSetupDescriptionTxt, 0, ObjectType::Page,
                Page::"CRM Connection Setup Wizard", AssistedSetupGroup::Connect, VideoUrlSetupCRMConnectionTxt, VideoCategory::Connect, CRMConnectionSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"CRM Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT()));
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(CDSConnectionSetupTxt, CopyStr(CDSConnectionSetupTxt, 1, 50), CDSConnectionSetupDescriptionTxt, 0, ObjectType::Page,
                Page::"CDS Connection Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Connect, CDSConnectionSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"CDS Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), CDSConnectionSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(InviteExternalAccountantTxt, CopyStr(InviteExternalAccountantTxt, 1, 50), InviteExternalAccountantDescTxt, 0, ObjectType::Page,
                Page::"Invite External Accountant", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, InviteExternalAccountantHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Invite External Accountant", Language.GetDefaultApplicationLanguageId(), InviteExternalAccountantTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(SetupPaymentServicesTxt, CopyStr(SetupPaymentServicesTxt, 1, 50), SetupPaymentServicesDescriptionTxt, 0, ObjectType::Page,
            Page::"Payment Services", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, SetupPaymentServicesHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Payment Services", Language.GetDefaultApplicationLanguageId(), SetupPaymentServicesTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupConsolidationReportingTxt, CopyStr(SetupConsolidationReportingTxt, 1, 50), '', 0, ObjectType::Page,
            Page::"Company Consolidation Wizard", AssistedSetupGroup::FinancialReporting, '', VideoCategory::Uncategorized, '');
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Company Consolidation Wizard", Language.GetDefaultApplicationLanguageId(), SetupConsolidationReportingTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(SetupMexicanCFDITxt, CopyStr(SetupMexicanCFDITxt, 1, 50), '', 0, ObjectType::Page,
                Page::"Mexican CFDI Wizard", AssistedSetupGroup::Customize, '', VideoCategory::Uncategorized, '');
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Mexican CFDI Wizard", Language.GetDefaultApplicationLanguageId(), SetupMexicanCFDITxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        UpdateStatus;
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
            GuidedExperience.InsertAssistedSetup(ApprovalWorkflowSetupTxt, CopyStr(ApprovalWorkflowSetupTxt, 1, 50), ApprovalWorkflowSetupDescriptionTxt, 0, ObjectType::Page,
                Page::"Approval Workflow Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupApprovalsTxt, VideoCategory::ApprovalWorkflows, ApprovalWorkflowSetupHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Approval Workflow Setup Wizard", Language.GetDefaultApplicationLanguageId(), ApprovalWorkflowSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);

            GuidedExperience.InsertAssistedSetup(CustomerAppWorkflowTxt, CopyStr(CustomerAppWorkflowTxt, 1, 50), CustomerAppWorkflowDescriptionTxt, 0, ObjectType::Page,
                Page::"Cust. Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Cust. Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), CustomerAppWorkflowTxt);
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
            GuidedExperience.InsertAssistedSetup(EmailSetupTxt, CopyStr(EmailSetupTxt, 1, 50), SMTPSetupDescriptionTxt, 5, ObjectType::Page,
                Page::"Email Setup Wizard", AssistedSetupGroup::FirstInvoice, VideoUrlSetupEmailTxt, VideoCategory::FirstInvoice, HelpSetupEmailTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Email Setup Wizard", Language.GetDefaultApplicationLanguageId(), EmailSetupTxt);
            GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Account Wizard");
        end;
        GlobalLanguage(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(SetupEmailLoggingTxt, CopyStr(SetupEmailLoggingTxt, 1, 50), SetupEmailLoggingDescriptionTxt, 0, ObjectType::Page,
                Page::"Setup Email Logging", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupEmailLoggingTxt, VideoCategory::ApprovalWorkflows, SetupEmailLoggingHelpTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Setup Email Logging", Language.GetDefaultApplicationLanguageId(), SetupEmailLoggingTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(CustomizeDocumentLayoutsTxt, CopyStr(CustomizeDocumentLayoutsTxt, 1, 50), CustomizeDocumentLayoutsDescTxt, 0, ObjectType::Page,
            Page::"Custom Report Layouts", AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, CustomizeDocumentLayoutsHelpTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Custom Report Layouts", Language.GetDefaultApplicationLanguageId(), CustomizeDocumentLayoutsTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);


        GuidedExperience.InsertAssistedSetup(OfficeAddinSetupTxt, CopyStr(OfficeAddinSetupTxt, 1, 50), OfficeAddinSetupDescriptionTxt, 0, ObjectType::Page,
            Page::"Exchange Setup Wizard", AssistedSetupGroup::DoMoreWithBC, VideoRunyourbusinesswithOffice365Txt, VideoCategory::DoMoreWithBC, HelpSetuptheOfficeaddinTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            PAGE::"Exchange Setup Wizard", Language.GetDefaultApplicationLanguageId(), OfficeAddinSetupTxt);
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

    local procedure UpdateTaxSetupCompleted()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        CompanyInformation: Record "Company Information";
        TaxSetup: Record "Tax Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if not TaxSetup.Get then
            exit;

        if CompanyInformation.Get then;
        if CompanyInformation."Tax Area Code" = '' then
            exit;

        if TaxJurisdiction.IsEmpty() then
            exit;

        AssistedSetup.Complete(PAGE::"Sales Tax Setup Wizard");
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
