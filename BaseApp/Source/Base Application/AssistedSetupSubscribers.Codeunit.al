codeunit 1814 "Assisted Setup Subscribers"
{

    var
        ApprovalWorkflowSetupTxt: Label 'Set up approval workflows';
        ApprovalWorkflowSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115466', Locked = true;
        ApprovalWorkflowSetupDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change certain values on documents, journal lines, or cards, such as an amount above a specified limit.';
        SMTPSetupTxt: Label 'Set up email';
        SMTPSetupDescriptionTxt: Label 'Set up the email account that you use to send business documents to customers and vendors.';
        OfficeAddinSetupTxt: Label 'Set up your Business Inbox in Outlook';
        OfficeAddinSetupDescriptionTxt: Label 'Configure Exchange so that users can complete business tasks without leaving their Outlook inbox.';
        ODataWizardTxt: Label 'Set up reporting data';
        ODataWizardHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115254', Locked = true;
        ODataWizardDescriptionTxt: Label 'Create data sets that you can use for building reports in Excel, Power BI, or any other reporting tool that works with an OData data source.';
        DataMigrationTxt: Label 'Migrate business data';
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
        VATSetupWizardTxt: Label 'Set up VAT';
        VATSetupWizardLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=850305', Locked = true;
        CashFlowForecastTxt: Label 'Set up cash flow forecast';
        CashFlowForecastDescriptionTxt: Label 'Manage your cash flow by automatically analyzing specific general ledger accounts.';
        CRMConnectionSetupTxt: Label 'Set up %1 connection', Comment = '%1 = CRM product name';
        CRMConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115256', Locked = true;
        CRMConnectionSetupDescriptionTxt: Label 'Connect your Dynamics 365 services for better insights.';
        CDSConnectionSetupTxt: Label 'Set up the Common Data Service connection';
        CDSConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115257', Locked = true;
        CDSConnectionSetupDescriptionTxt: Label 'Connect to Common Data Service for better insights across business applications.', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated';
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
        CompanyAlreadySetUpQst: Label 'This company is already set up. To change settings for it, go to the Company Information page.\\Go there now?';
        Info: ModuleInfo;
        UpdateUsersFromOfficeTxt: Label 'Update users from Office';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        CRMProductName: Codeunit "CRM Product Name";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        AssistedSetup: Codeunit "Assisted Setup";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        // Getting Started
        if AssistedCompanySetupIsVisible then
            if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then
                AssistedCompanySetup.AddAssistedCompanySetup();

        AssistedSetup.Add(GetAppId(), PAGE::"VAT Setup Wizard", VATSetupWizardTxt, AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, VATSetupWizardLinkTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"VAT Setup Wizard", Language.GetDefaultApplicationLanguageId(), VATSetupWizardTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        AssistedSetup.Add(GetAppId(), Page::"Azure AD User Update Wizard", UpdateUsersFromOfficeTxt, AssistedSetupGroup::GettingStarted);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(Page::"Azure AD User Update Wizard", Language.GetDefaultApplicationLanguageId(), UpdateUsersFromOfficeTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        AssistedSetup.Add(GetAppId(), PAGE::"Data Migration Wizard", DataMigrationTxt, AssistedSetupGroup::ReadyForBusiness, VideoImportbusinessdataTxt, VideoCategory::ReadyForBusiness, HelpImportbusinessdataTxt, DataMigrationDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Data Migration Wizard", Language.GetDefaultApplicationLanguageId(), DataMigrationTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        AssistedSetup.Add(GetAppId(), PAGE::"Curr. Exch. Rate Service List", SetupExchangeRatesTxt, AssistedSetupGroup::GettingStarted, SetupExchangeRatesVideoTxt, VideoCategory::GettingStarted, SetupExchangeRatesHelpTxt, SetupExchangeRatesDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Curr. Exch. Rate Service List", Language.GetDefaultApplicationLanguageId(), SetupExchangeRatesTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Analysis

        AssistedSetup.Add(GetAppId(), PAGE::"Cash Flow Forecast Wizard", CashFlowForecastTxt, AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupCashFlowForecastTxt, CashFlowForecastDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Cash Flow Forecast Wizard", Language.GetDefaultApplicationLanguageId(), CashFlowForecastTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        // Customize for your need
        InitializeCustomize();

        // Setup Group
        AssistedSetup.Add(GetAppId(), PAGE::"OData Setup Wizard", ODataWizardTxt, AssistedSetupGroup::FinancialReporting, '', VideoCategory::FinancialReporting, ODataWizardHelpTxt, ODataWizardDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"OData Setup Wizard", Language.GetDefaultApplicationLanguageId(), ODataWizardTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Item Approval WF Setup Wizard", ItemAppWorkflowTxt, AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '', ItemAppWorkflowDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Item Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), ItemAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if NOT EnvironmentInfo.IsSaaS then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Azure AD App Setup Wizard", AzureAdSetupTxt, AssistedSetupGroup::Connect);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Azure AD App Setup Wizard", Language.GetDefaultApplicationLanguageId(), AzureAdSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Pmt. App. Workflow Setup Wzrd.", PmtJnlAppWorkflowTxt, AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '', PmtJnlAppWorkflowDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Pmt. App. Workflow Setup Wzrd.", Language.GetDefaultApplicationLanguageId(), PmtJnlAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"CRM Connection Setup Wizard", STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT),
            AssistedSetupGroup::Connect, VideoUrlSetupCRMConnectionTxt, VideoCategory::Connect, CRMConnectionSetupHelpTxt, CRMConnectionSetupDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"CRM Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), STRSUBSTNO(CRMConnectionSetupTxt, CRMProductName.SHORT));
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"CDS Connection Setup Wizard", CDSConnectionSetupTxt, AssistedSetupGroup::Connect, '', VideoCategory::Connect, CDSConnectionSetupHelpTxt, CDSConnectionSetupDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"CDS Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), CDSConnectionSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        if EnvironmentInfo.IsSaaS then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Invite External Accountant", InviteExternalAccountantTxt, AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, InviteExternalAccountantHelpTxt, InviteExternalAccountantDescTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Invite External Accountant", Language.GetDefaultApplicationLanguageId(), InviteExternalAccountantTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"Payment Services", SetupPaymentServicesTxt, AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, SetupPaymentServicesHelpTxt, SetupPaymentServicesDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Payment Services", Language.GetDefaultApplicationLanguageId(), SetupPaymentServicesTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Company Consolidation Wizard", SetupConsolidationReportingTxt, AssistedSetupGroup::FinancialReporting);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Company Consolidation Wizard", Language.GetDefaultApplicationLanguageId(), SetupConsolidationReportingTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        UpdateStatus;
    end;

    local procedure InitializeCustomize()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedSetup: Codeunit "Assisted Setup";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GLOBALLANGUAGE;
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Approval Workflow Setup Wizard", ApprovalWorkflowSetupTxt, AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupApprovalsTxt, VideoCategory::ApprovalWorkflows, ApprovalWorkflowSetupHelpTxt, ApprovalWorkflowSetupDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Approval Workflow Setup Wizard", Language.GetDefaultApplicationLanguageId(), ApprovalWorkflowSetupTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);

            AssistedSetup.Add(GetAppId(), PAGE::"Cust. Approval WF Setup Wizard", CustomerAppWorkflowTxt, AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '', CustomerAppWorkflowDescriptionTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Cust. Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), CustomerAppWorkflowTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"Email Setup Wizard", SMTPSetupTxt, AssistedSetupGroup::FirstInvoice, VideoUrlSetupEmailTxt, VideoCategory::FirstInvoice, HelpSetupemailTxt, SMTPSetupDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Email Setup Wizard", Language.GetDefaultApplicationLanguageId(), SMTPSetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            AssistedSetup.Add(GetAppId(), PAGE::"Setup Email Logging", SetupEmailLoggingTxt, AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupEmailLoggingTxt, VideoCategory::ApprovalWorkflows, SetupEmailLoggingHelpTxt, SetupEmailLoggingDescriptionTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            AssistedSetup.AddTranslation(PAGE::"Setup Email Logging", Language.GetDefaultApplicationLanguageId(), SetupEmailLoggingTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;

        AssistedSetup.Add(GetAppId(), PAGE::"Custom Report Layouts", CustomizeDocumentLayoutsTxt, AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, CustomizeDocumentLayoutsHelpTxt, CustomizeDocumentLayoutsDescTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Custom Report Layouts", Language.GetDefaultApplicationLanguageId(), CustomizeDocumentLayoutsTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);


        AssistedSetup.Add(GetAppId(), PAGE::"Exchange Setup Wizard", OfficeAddinSetupTxt, AssistedSetupGroup::DoMoreWithBC, VideoRunyourbusinesswithOffice365Txt, VideoCategory::DoMoreWithBC, HelpSetuptheOfficeaddinTxt, OfficeAddinSetupDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(PAGE::"Exchange Setup Wizard", Language.GetDefaultApplicationLanguageId(), OfficeAddinSetupTxt);
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
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        IF not SMTPMailSetup.GetSetup THEN
            exit;
        AssistedSetup.Complete(PAGE::"Email Setup Wizard");
    end;

    local procedure UpdateSetUpApprovalWorkflow()
    var
        ApprovalUserSetup: Record "User Setup";
        AssistedSetup: Codeunit "Assisted Setup";
    begin
        ApprovalUserSetup.SETFILTER("Approver ID", '<>%1', '');
        IF ApprovalUserSetup.ISEMPTY THEN
            EXIT;

        AssistedSetup.Complete(PAGE::"Approval Workflow Setup Wizard");
    end;
}

