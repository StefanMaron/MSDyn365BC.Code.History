codeunit 1876 "Business Setup Subscribers"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyNameTxt: Label 'Company';
        CompanyDescriptionTxt: Label 'Make general company settings.';
        CompanyKeywordsTxt: Label 'Company';
        CountriesRegionsNameTxt: Label 'Countries/Regions';
        CountriesRegionsDescriptionTxt: Label 'Define which countries/regions you trade in.';
        CountriesRegionsKeywordsTxt: Label 'Reference data, Country, Region, System';
        CurrenciesNameTxt: Label 'Currencies';
        CurrenciesDescriptionTxt: Label 'Define how you trade in foreign currencies.';
        CurrenciesKeywordsTxt: Label 'Finance, Currency, Money';
        GeneralLedgerSetupNameTxt: Label 'General Ledger Setup';
        GeneralLedgerSetupDescriptionTxt: Label 'Define how to manage your company finances.';
        GeneralLedgerSetupKeywordsTxt: Label 'Ledger, Finance';
        JobsSetupNameTxt: Label 'Jobs Setup';
        JobsSetupDescriptionTxt: Label 'Set up policies for project management (jobs).';
        JobsSetupKeywordsTxt: Label 'Jobs, Project Management';
        FixedAssetSetupNameTxt: Label 'Fixed Assets Setup';
        FixedAssetSetupDescriptionTxt: Label 'Set up accounting policies for fixed assets.';
        FixedAssetSetupKeywordsTxt: Label 'Fixed Assets';
        HumanResourcesSetupNameTxt: Label 'Human Resources Setup';
        HumanResourcesSetupDescriptionTxt: Label 'Define how you manage employee data.';
        HumanResourcesSetupKeywordsTxt: Label 'Human Resources, HR';
        InventorySetupNameTxt: Label 'Inventory Setup';
        InventorySetupDescriptionTxt: Label 'Set up policies for inventory items.';
        InventorySetupKeywordsTxt: Label 'Inventory, Number Series, Product';
        LocationsNameTxt: Label 'Locations';
        LocationsDescriptionTxt: Label 'Set up locations';
        LocationsKeywordsTxt: Label 'Inventory, Location';
        TransferRoutesNameTxt: Label 'Transfer Routes';
        TransferRoutesDescriptionTxt: Label 'Set up transfer routes';
        TransferRoutesKeywordsTxt: Label 'Inventory, Location, Transfer';
        ItemChargesNameTxt: Label 'Item Charges';
        ItemChargesDescriptionTxt: Label 'Set up Item Charges';
        ItemChargesKeywordsTxt: Label 'Inventory, Item Charges';
        NoSeriesNameTxt: Label 'Number Series';
        NoSeriesDescriptionTxt: Label 'Manage number series for master data, documents, and transaction records.';
        NoSeriesKeywordsTxt: Label 'Finance, Number Series';
        PostCodesNameTxt: Label 'Post Codes';
        PostCodesDescriptionTxt: Label 'Set up or update post codes.';
        PostCodesKeywordsTxt: Label 'Mail, System, Code';
        ReasonCodesNameTxt: Label 'Reason Codes';
        ReasonCodesDescriptionTxt: Label 'Set up reasons to assign to transactions, such as returns.';
        ReasonCodesKeywordsTxt: Label 'Reference data, Reason, Code';
        SourceCodesNameTxt: Label 'Source Codes';
        SourceCodesDescriptionTxt: Label 'Set up sources to assign to transactions for identification.';
        SourceCodesKeywordsTxt: Label 'Reference data, Source, Code';
        PurchasePayablesSetupNameTxt: Label 'Purchase & Payables Setup';
        PurchasePayablesSetupDescriptionTxt: Label 'Define how you process purchases and outgoing payments.';
        PurchasePayablesSetupKeywordsTxt: Label 'Purchase, Payables, Finance, Payment';
        SalesReceivablesSetupNameTxt: Label 'Sales & Receivables Setup';
        SalesReceivablesSetupDescriptionTxt: Label 'Define how you process sales and incoming payments.';
        SalesReceivablesSetupKeywordsTxt: Label 'Sales, Receivables, Finance, Payment';
        PermissionSetsNameTxt: Label 'Permission Sets';
        PermissionSetsDescriptionTxt: Label 'Define which database permissions can be granted to users.';
        PermissionSetsKeywordsTxt: Label 'User, Permission, System';
        ReportLayoutsNameTxt: Label 'Report Layout Selection';
        ReportLayoutsDescriptionTxt: Label 'Define the appearance for PDF or printed documents and reports.';
        ReportLayoutsKeywordsTxt: Label 'Report, Layout, Design';
        SMTPMailSetupNameTxt: Label 'SMTP Mail Setup';
        SMTPMailSetupDescriptionTxt: Label 'Set up your email server.';
        SMTPMailSetupKeywordsTxt: Label 'System, SMTP, Mail';
        EmailAccountMailSetupNameTxt: Label 'Email Account Setup';
        EmailAccountSetupDescriptionTxt: Label 'Set up your email accounts.';
        EmailAccountSetupKeywordsTxt: Label 'System, SMTP, Mail, Outlook';
        UsersNameTxt: Label 'Give permissions to users';
        UsersShortNameTxt: Label 'User permissions';
        UsersDescriptionTxt: Label 'Manage who has access to what based on permissions.';
        UsersKeywordsTxt: Label 'System, User, Permission, Authentication, Password';
        ResponsibilityCentersNameTxt: Label 'Responsibility Centers';
        ResponsibilityCentersDescriptionTxt: Label 'Set up additional company locations, such as sales offices or warehouses.';
        ResponsibilityCentersKeywordsTxt: Label 'Location, Distributed, Office';
        OnlineMapSetupNameTxt: Label 'Online Map Setup';
        OnlineMapSetupDescriptionTxt: Label 'Define which online map service to use.';
        OnlineMapSetupKeywordsTxt: Label 'Map, Geo, Reference data';
        AccountingPeriodsNameTxt: Label 'Accounting Periods';
        AccountingPeriodsDescriptionTxt: Label 'Set up the number of accounting periods, such as 12 monthly periods, within the fiscal year and specify which period is the start of the new fiscal year.';
        AccountingPeriodsKeywordsTxt: Label 'Accounting, Periods';
        DimensionsNameTxt: Label 'Dimensions';
        DimensionsDescriptionTxt: Label 'Set up dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
        DimensionsKeywordsTxt: Label 'Dimensions';
        CashFlowSetupNameTxt: Label 'Cash Flow Setup';
        CashFlowSetupDescriptionTxt: Label 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
        CashFlowSetupKeywordsTxt: Label 'Cash Flow';
        BankExportImportSetupNameTxt: Label 'Bank Export/Import Setup';
        BankExportImportSetupDescriptionTxt: Label 'Set up file formats for exporting vendor payments and for importing bank statements.';
        BankExportImportSetupKeywordsTxt: Label 'Bank, Statement, Export, Import';
        GeneralPostingSetupNameTxt: Label 'General Posting Setup';
        GeneralPostingSetupDescriptionTxt: Label 'Set up combinations of general business and general product posting groups by specifying account numbers for posting of sales and purchase transactions.';
        GeneralPostingSetupKeywordsTxt: Label 'Posting, General';
        GenBusinessPostingGroupsNameTxt: Label 'Gen. Business Posting Groups';
        GenBusinessPostingGroupsDescriptionTxt: Label 'Set up the trade-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
        GenBusinessPostingGroupsKeywordsTxt: Label 'Posting, General';
        GenProductPostingGroupsNameTxt: Label 'Gen. Product Posting Groups';
        GenProductPostingGroupsDescriptionTxt: Label 'Set up the item-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
        GenProductPostingGroupsKeywordsTxt: Label 'Posting, Product';
        VATPostingSetupNameTxt: Label 'VAT Posting Setup';
        VATPostingSetupDescriptionTxt: Label 'Define how tax is posted to the general ledger.';
        VATPostingSetupKeywordsTxt: Label 'VAT, Posting';
        VATBusinessPostingGroupsNameTxt: Label 'VAT Business Posting Groups';
        VATBusinessPostingGroupsDescriptionTxt: Label 'Set up the trade-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
        VATBusinessPostingGroupsKeywordsTxt: Label 'VAT, Posting, Business';
        VATProductPostingGroupsNameTxt: Label 'VAT Product Posting Groups';
        VATProductPostingGroupsDescriptionTxt: Label 'Set up the item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
        VATProductPostingGroupsKeywordsTxt: Label 'VAT, Posting';
        VATReportSetupNameTxt: Label 'VAT Report Setup';
        VATReportSetupDescriptionTxt: Label 'Set up number series and options for the report that you periodically send to the authorities to declare your VAT.';
        VATReportSetupKeywordsTxt: Label 'VAT, Report';
        BankAccountPostingGroupsNameTxt: Label 'Bank Account Posting Groups';
        BankAccountPostingGroupsDescriptionTxt: Label 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
        BankAccountPostingGroupsKeywordsTxt: Label 'Bank Account, Posting';
        GeneralJournalTemplatesNameTxt: Label 'General Journal Templates';
        GeneralJournalTemplatesDescriptionTxt: Label 'Set up templates for the journals that you use for bookkeeping tasks. Templates allow you to work in a journal window that is designed for a specific purpose.';
        GeneralJournalTemplatesKeywordsTxt: Label 'Journal, Templates';
        VATStatementTemplatesNameTxt: Label 'VAT Statement Templates';
        VATStatementTemplatesDescriptionTxt: Label 'Set up the reports that you use to settle VAT and report to the customs and tax authorities.';
        VATStatementTemplatesKeywordsTxt: Label 'VAT, Statement, Templates';
        IntrastatTemplatesNameTxt: Label 'Intrastat Templates';
        IntrastatTemplatesDescriptionTxt: Label 'Define how you want to set up and keep track of journals to report Intrastat.';
        IntrastatTemplatesKeywordsTxt: Label 'Intrastat';
        BusinessRelationsNameTxt: Label 'Business Relations';
        BusinessRelationsDescriptionTxt: Label 'Set up or update Business Relations.';
        BusinessRelationsKeywordsTxt: Label 'Business Relations.';
        IndustryGroupsNameTxt: Label 'Industry Groups';
        IndustryGroupsDescriptionTxt: Label 'Set up or update Industry Groups.';
        IndustryGroupsKeywordsTxt: Label 'Industry Groups.';
        WebSourcesNameTxt: Label 'Web Sources';
        WebSourcesDescriptionTxt: Label 'Set up or update Web Sources.';
        WebSourcesKeywordsTxt: Label 'Web Sources.';
        JobResponsibilitiesNameTxt: Label 'Job Responsibilities';
        JobResponsibilitiesDescriptionTxt: Label 'Set up or update Job Responsibilities.';
        JobResponsibilitiesKeywordsTxt: Label 'Job Responsibilities.';
        OrganizationalLevelsNameTxt: Label 'Organizational Levels';
        OrganizationalLevelsDescriptionTxt: Label 'Set up or update Organizational Levels.';
        OrganizationalLevelsKeywordsTxt: Label 'Organizational Levels.';
        InteractionGroupsNameTxt: Label 'Interaction Groups';
        InteractionGroupsDescriptionTxt: Label 'Set up or update Interaction Groups.';
        InteractionGroupsKeywordsTxt: Label 'Interaction Groups.';
        InteractionTemplatesNameTxt: Label 'Interaction Templates';
        InteractionTemplatesDescriptionTxt: Label 'Set up or update Interaction Templates.';
        InteractionTemplatesKeywordsTxt: Label 'Interaction Templates.';
        SalutationsNameTxt: Label 'Salutations';
        SalutationsDescriptionTxt: Label 'Set up or update Salutations.';
        SalutationsKeywordsTxt: Label 'Salutations.';
        MailingGroupsNameTxt: Label 'Mailing Groups';
        MailingGroupsDescriptionTxt: Label 'Set up or update Mailing Groups.';
        MailingGroupsKeywordsTxt: Label 'Mailing Groups.';
        SalesCyclesNameTxt: Label 'Sales Cycles';
        SalesCyclesDescriptionTxt: Label 'Set up or update Sales Cycles.';
        SalesCyclesKeywordsTxt: Label 'Sales Cycles.';
        CloseOpportunityCodesNameTxt: Label 'Close Opportunity Codes';
        CloseOpportunityCodesDescriptionTxt: Label 'Set up or update Close Opportunity Codes.';
        CloseOpportunityCodesKeywordsTxt: Label 'Close Opportunity Codes.';
        QuestionnaireSetupNameTxt: Label 'Questionnaire Setup';
        QuestionnaireSetupDescriptionTxt: Label 'Set up or update Questionnaire Setup.';
        QuestionnaireSetupKeywordsTxt: Label 'Questionnaire Setup.';
        ActivitiesNameTxt: Label 'Activities';
        ActivitiesDescriptionTxt: Label 'Set up or update Activities.';
        ActivitiesKeywordsTxt: Label 'Activities.';
        MarketingSetupNameTxt: Label 'Marketing Setup';
        MarketingSetupDescriptionTxt: Label 'Set up or update Marketing Setup.';
        MarketingSetupKeywordsTxt: Label 'Marketing Setup.';
        InteractionTemplateSetupNameTxt: Label 'Interaction Template Setup';
        InteractionTemplateSetupDescriptionTxt: Label 'Set up or update Interaction Template Setup.';
        InteractionTemplateSetupKeywordsTxt: Label 'Interaction Template Setup.';
        VATClausesNameTxt: Label 'VAT Clauses';
        VATClausesDescriptionTxt: Label 'Set up descriptions (VAT Act references) that will be printed on invoices when non standard VAT rate is used on invoice.';
        VATClausesKeywordsTxt: Label 'VAT, Invoice, Clause';
        AnalysisViewsTxt: Label 'Analysis by Dimensions';
        AnalysisViewsDescriptionTxt: Label 'Set up which dimension values and filters are used when you use analysis views to analyze amounts in your general ledger by dimensions.';
        AnalysisViewsKeywordsTxt: Label 'Dimensions,Reporting,Analysis Views';
        VATReportConfigTxt: Label 'VAT Report Configuration';
        VATReportConfigDescriptionTxt: Label 'Set up configuration for VAT reports.';
        VATReportConfigKeywordsTxt: Label 'VAT Report, Return, EC Sales List';
        VATReportTxt: Label 'VAT Report Setup';
        VATReportDescriptionTxt: Label 'Set up VAT reports.';
        VATReportKeywordsTxt: Label 'VAT Report, Suggest, Validate, Submission,VAT Return, EC Sales List';
        EnvironmentTxt: Label 'Environments';
        EnvironmentDescriptionTxt: Label 'Set up sandbox environment.';
        EnvironmentKeywordsTxt: Label 'System, Environment, Sandbox';
        ICSetupTxt: Label 'Intercompany Setup';
        ICSetupDescriptionTxt: Label 'View or edit the intercompany setup for the current company.';
        ICSetupKeywordsTxt: Label 'Intercompany';
        ICPartnersTxt: Label 'Intercompany Partners';
        ICPartnersDescriptionTxt: Label 'Set up intercompany partners.';
        ICPartnersKeywordsTxt: Label 'Intercompany, Partners';
        ICChartOfAccountsTxt: Label 'Intercompany Chart of Accounts';
        ICChartOfAccountsDescriptionTxt: Label 'Set up how you want your company''s chart of accounts to correspond to the charts of accounts of your partners.';
        ICChartOfAccountsKeywordsTxt: Label 'Intercompany, Ledger, Finance';
        ICDimensionsTxt: Label 'Intercompany Dimensions';
        ICDimensionsDescriptionTxt: Label 'Set up how your company''s dimension codes correspond to the dimension codes of your intercompany partners.';
        ICDimensionsKeywordsTxt: Label 'Intercompany, Dimensions';
        CostAccountingSetupNameTxt: Label 'Cost Accounting Setup';
        CostAccountingSetupDescriptionTxt: Label 'Set up general ledger transfers to cost accounting, dimension links to cost centers and objects, and how to handle allocation document numbers and IDs.';
        CostAccountingSetupKeywordsTxt: Label 'Cost, Accounting';
        LanguagesNameTxt: Label 'Languages';
        LanguagesDescriptionTxt: Label 'Install and update languages that appear in the user interface.';
        LanguagesKeywordsTxt: Label 'System, User Interface, Text, Language';
        SmartListDesignerTxt: Label 'SmartList Designer Setup';
        SmartListDesignerDescriptionTxt: Label 'Define SmartList Designer App ID';
        SmartListDesignerKeywordsTxt: Label 'SmartList Designer, SmartList, PowerApp App ID';
        WarehouseSetupTxt: Label 'Warehouse Setup';
        WarehouseSetupDescriptionTxt: Label 'Set up number series for warehouse documents, error policies for posting receipts and shipments, and activity requirements for warehouse functionality.';
        WarehouseSetupKeywordsTxt: Label 'Inventory, Location, Number series';
        UserSettingsTxt: Label 'Manage user settings';
        UserSettingsShortTxt: Label 'User settings';
        UserSettingsDescriptionTxt: Label 'Manage role, language, and regional settings for users.';
        UserSettingsKeywordsTxt: Label 'Role, Language, Regional Settings';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertSetupOnRegisterManualSetup(var Sender: Codeunit "Guided Experience")
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EnvironmentInfo: Codeunit "Environment Information";
        EmailFeature: Codeunit "Email Feature";
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);

        // General
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(CompanyNameTxt, CompanyNameTxt, CompanyDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Company Information", ManualSetupCategory::General, CompanyKeywordsTxt);
            Sender.InsertManualSetup(CountriesRegionsNameTxt, CountriesRegionsNameTxt, CountriesRegionsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Countries/Regions", ManualSetupCategory::General, CountriesRegionsKeywordsTxt);
            Sender.InsertManualSetup(NoSeriesNameTxt, NoSeriesNameTxt, NoSeriesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"No. Series", ManualSetupCategory::General, NoSeriesKeywordsTxt);
            Sender.InsertManualSetup(PostCodesNameTxt, PostCodesNameTxt, PostCodesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Post Codes", ManualSetupCategory::General, PostCodesKeywordsTxt);
            Sender.InsertManualSetup(ReasonCodesNameTxt, ReasonCodesNameTxt, ReasonCodesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Reason Codes", ManualSetupCategory::General, ReasonCodesKeywordsTxt);
            Sender.InsertManualSetup(SourceCodesNameTxt, SourceCodesNameTxt, SourceCodesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Source Codes", ManualSetupCategory::General, SourceCodesKeywordsTxt);
            Sender.InsertManualSetup(UserSettingsTxt, UserSettingsShortTxt, UserSettingsDescriptionTxt, 5, ObjectType::Page,
              PAGE::"User Personalization List", ManualSetupCategory::General, UserSettingsKeywordsTxt);
        end;

        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(CurrenciesNameTxt, CurrenciesNameTxt, CurrenciesDescriptionTxt, 0, ObjectType::Page,
              PAGE::Currencies, ManualSetupCategory::General, CurrenciesKeywordsTxt);
            Sender.InsertManualSetup(LanguagesNameTxt, LanguagesNameTxt, LanguagesDescriptionTxt, 0, ObjectType::Page,
              PAGE::Languages, ManualSetupCategory::General, LanguagesKeywordsTxt);
        end;

        // Finance
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(GeneralLedgerSetupNameTxt, GeneralLedgerSetupNameTxt, GeneralLedgerSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"General Ledger Setup", ManualSetupCategory::Finance, GeneralLedgerSetupKeywordsTxt);
            Sender.InsertManualSetup(AccountingPeriodsNameTxt, AccountingPeriodsNameTxt, AccountingPeriodsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Accounting Periods", ManualSetupCategory::Finance, AccountingPeriodsKeywordsTxt);
            Sender.InsertManualSetup(BankExportImportSetupNameTxt, BankExportImportSetupNameTxt, BankExportImportSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Bank Export/Import Setup", ManualSetupCategory::Finance, BankExportImportSetupKeywordsTxt);
            Sender.InsertManualSetup(GeneralPostingSetupNameTxt, GeneralPostingSetupNameTxt, GeneralPostingSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"General Posting Setup", ManualSetupCategory::Finance, GeneralPostingSetupKeywordsTxt);
            Sender.InsertManualSetup(GenBusinessPostingGroupsNameTxt, GenBusinessPostingGroupsNameTxt, GenBusinessPostingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Gen. Business Posting Groups", ManualSetupCategory::Finance, GenBusinessPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(GenProductPostingGroupsNameTxt, GenProductPostingGroupsNameTxt, GenProductPostingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Gen. Product Posting Groups", ManualSetupCategory::Finance, GenProductPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATPostingSetupNameTxt, VATPostingSetupNameTxt, VATPostingSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Posting Setup", ManualSetupCategory::Finance, VATPostingSetupKeywordsTxt);
            Sender.InsertManualSetup(VATBusinessPostingGroupsNameTxt, VATBusinessPostingGroupsNameTxt, VATBusinessPostingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Business Posting Groups", ManualSetupCategory::Finance, VATBusinessPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATProductPostingGroupsNameTxt, VATProductPostingGroupsNameTxt, VATProductPostingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Product Posting Groups", ManualSetupCategory::Finance, VATProductPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATReportSetupNameTxt, VATReportSetupNameTxt, VATReportSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Report Setup", ManualSetupCategory::Finance, VATReportSetupKeywordsTxt);
            Sender.InsertManualSetup(BankAccountPostingGroupsNameTxt, BankAccountPostingGroupsNameTxt, BankAccountPostingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Bank Account Posting Groups", ManualSetupCategory::Finance, BankAccountPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(GeneralJournalTemplatesNameTxt, GeneralJournalTemplatesNameTxt, GeneralJournalTemplatesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"General Journal Templates", ManualSetupCategory::Finance, GeneralJournalTemplatesKeywordsTxt);
            Sender.InsertManualSetup(VATStatementTemplatesNameTxt, VATStatementTemplatesNameTxt, VATStatementTemplatesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Statement Templates", ManualSetupCategory::Finance, VATStatementTemplatesKeywordsTxt);
            Sender.InsertManualSetup(VATClausesNameTxt, VATClausesNameTxt, VATClausesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Clauses", ManualSetupCategory::Finance, VATClausesKeywordsTxt);
            Sender.InsertManualSetup(VATReportConfigTxt, VATReportConfigTxt, VATReportConfigDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Reports Configuration", ManualSetupCategory::Finance, VATReportConfigKeywordsTxt);
            Sender.InsertManualSetup(VATReportTxt, VATReportTxt, VATReportDescriptionTxt, 0, ObjectType::Page,
              PAGE::"VAT Report Setup", ManualSetupCategory::Finance, VATReportKeywordsTxt);
            Sender.InsertManualSetup(CashFlowSetupNameTxt, CashFlowSetupNameTxt, CashFlowSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Cash Flow Setup", ManualSetupCategory::Finance, CashFlowSetupKeywordsTxt);
        end;

        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(DimensionsNameTxt, DimensionsNameTxt, DimensionsDescriptionTxt, 0, ObjectType::Page,
              PAGE::Dimensions, ManualSetupCategory::Finance, DimensionsKeywordsTxt);
            Sender.InsertManualSetup(AnalysisViewsTxt, AnalysisViewsTxt, AnalysisViewsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Analysis View List", ManualSetupCategory::Finance, AnalysisViewsKeywordsTxt);
            Sender.InsertManualSetup(CostAccountingSetupNameTxt, CostAccountingSetupNameTxt, CostAccountingSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Cost Accounting Setup", ManualSetupCategory::Finance, CostAccountingSetupKeywordsTxt);
        end;

        IF ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(ResponsibilityCentersNameTxt, ResponsibilityCentersNameTxt, ResponsibilityCentersDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Responsibility Center List", ManualSetupCategory::Finance, ResponsibilityCentersKeywordsTxt);
            Sender.InsertManualSetup(IntrastatTemplatesNameTxt, IntrastatTemplatesNameTxt, IntrastatTemplatesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Intrastat Journal Templates", ManualSetupCategory::Finance, IntrastatTemplatesKeywordsTxt);
        end;

        // System
        IF ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(PermissionSetsNameTxt, PermissionSetsNameTxt, PermissionSetsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Permission Sets", ManualSetupCategory::System, PermissionSetsKeywordsTxt);

        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(ReportLayoutsNameTxt, ReportLayoutsNameTxt, ReportLayoutsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Report Layout Selection", ManualSetupCategory::System, ReportLayoutsKeywordsTxt);
            if EmailFeature.IsEnabled() then
                Sender.InsertManualSetup(EmailAccountMailSetupNameTxt, EmailAccountMailSetupNameTxt, EmailAccountSetupDescriptionTxt, 0, ObjectType::Page,
                  Page::"Email Accounts", ManualSetupCategory::System, EmailAccountSetupKeywordsTxt)
            else
                Sender.InsertManualSetup(SMTPMailSetupNameTxt, SMTPMailSetupNameTxt, SMTPMailSetupDescriptionTxt, 0, ObjectType::Page,
                  PAGE::"SMTP Mail Setup", ManualSetupCategory::System, SMTPMailSetupKeywordsTxt);

            Sender.InsertManualSetup(UsersNameTxt, UsersShortNameTxt, UsersDescriptionTxt, 5, ObjectType::Page,
              PAGE::Users, ManualSetupCategory::System, UsersKeywordsTxt);
            IF EnvironmentInfo.IsSaaS then
                Sender.InsertManualSetup(
                  EnvironmentTxt, EnvironmentTxt, EnvironmentDescriptionTxt, 0, ObjectType::Page,
                  PAGE::"Sandbox Environment", ManualSetupCategory::System, EnvironmentKeywordsTxt);
        end;

        // Jobs
        IF ApplicationAreaMgmtFacade.IsJobsEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(JobsSetupNameTxt, JobsSetupNameTxt, JobsSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Jobs Setup", ManualSetupCategory::Jobs, JobsSetupKeywordsTxt);

        // Fixed Assets
        IF ApplicationAreaMgmtFacade.IsFixedAssetEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(FixedAssetSetupNameTxt, FixedAssetSetupNameTxt, FixedAssetSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Fixed Asset Setup", ManualSetupCategory::"Fixed Assets", FixedAssetSetupKeywordsTxt);

        // HR
        IF ApplicationAreaMgmtFacade.IsBasicHREnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(HumanResourcesSetupNameTxt, HumanResourcesSetupNameTxt, HumanResourcesSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Human Resources Setup", ManualSetupCategory::HR, HumanResourcesSetupKeywordsTxt);

        // Inventory
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(InventorySetupNameTxt, InventorySetupNameTxt, InventorySetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Inventory Setup", ManualSetupCategory::Inventory, InventorySetupKeywordsTxt);

        if ApplicationAreaMgmtFacade.IsSuiteEnabled() OR ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(WarehouseSetupTxt, WarehouseSetupTxt, WarehouseSetupDescriptionTxt, 0, ObjectType::Page,
                  PAGE::"Warehouse Setup", ManualSetupCategory::Inventory, WarehouseSetupKeywordsTxt);

        // Location
        IF ApplicationAreaMgmtFacade.IsLocationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(LocationsNameTxt, LocationsNameTxt, LocationsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Location List", ManualSetupCategory::Inventory, LocationsKeywordsTxt);

            Sender.InsertManualSetup(TransferRoutesNameTxt, TransferRoutesNameTxt, TransferRoutesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Transfer Routes", ManualSetupCategory::Inventory, TransferRoutesKeywordsTxt);
        end;

        // Item Charges
        IF ApplicationAreaMgmtFacade.IsItemChargesEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(ItemChargesNameTxt, ItemChargesNameTxt, ItemChargesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Item Charges", ManualSetupCategory::Inventory, ItemChargesKeywordsTxt);

        // Relationship Management
        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(BusinessRelationsNameTxt, BusinessRelationsNameTxt, BusinessRelationsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Business Relations", ManualSetupCategory::"Relationship Mgt", BusinessRelationsKeywordsTxt);

            Sender.InsertManualSetup(IndustryGroupsNameTxt, IndustryGroupsNameTxt, IndustryGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Industry Groups", ManualSetupCategory::"Relationship Mgt", IndustryGroupsKeywordsTxt);

            Sender.InsertManualSetup(WebSourcesNameTxt, WebSourcesNameTxt, WebSourcesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Web Sources", ManualSetupCategory::"Relationship Mgt", WebSourcesKeywordsTxt);

            Sender.InsertManualSetup(JobResponsibilitiesNameTxt, JobResponsibilitiesNameTxt, JobResponsibilitiesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Job Responsibilities", ManualSetupCategory::"Relationship Mgt", JobResponsibilitiesKeywordsTxt);

            Sender.InsertManualSetup(OrganizationalLevelsNameTxt, OrganizationalLevelsNameTxt, OrganizationalLevelsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Organizational Levels", ManualSetupCategory::"Relationship Mgt", OrganizationalLevelsKeywordsTxt);

            Sender.InsertManualSetup(InteractionGroupsNameTxt, InteractionGroupsNameTxt, InteractionGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Interaction Groups", ManualSetupCategory::"Relationship Mgt", InteractionGroupsKeywordsTxt);

            Sender.InsertManualSetup(InteractionTemplatesNameTxt, InteractionTemplatesNameTxt, InteractionTemplatesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Interaction Templates", ManualSetupCategory::"Relationship Mgt", InteractionTemplatesKeywordsTxt);

            Sender.InsertManualSetup(SalutationsNameTxt, SalutationsNameTxt, SalutationsDescriptionTxt, 0, ObjectType::Page,
              PAGE::Salutations, ManualSetupCategory::"Relationship Mgt", SalutationsKeywordsTxt);

            Sender.InsertManualSetup(MailingGroupsNameTxt, MailingGroupsNameTxt, MailingGroupsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Mailing Groups", ManualSetupCategory::"Relationship Mgt", MailingGroupsKeywordsTxt);

            Sender.InsertManualSetup(SalesCyclesNameTxt, SalesCyclesNameTxt, SalesCyclesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Sales Cycles", ManualSetupCategory::"Relationship Mgt", SalesCyclesKeywordsTxt);

            Sender.InsertManualSetup(CloseOpportunityCodesNameTxt, CloseOpportunityCodesNameTxt, CloseOpportunityCodesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Close Opportunity Codes", ManualSetupCategory::"Relationship Mgt", CloseOpportunityCodesKeywordsTxt);

            Sender.InsertManualSetup(QuestionnaireSetupNameTxt, QuestionnaireSetupNameTxt, QuestionnaireSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Profile Questionnaires", ManualSetupCategory::"Relationship Mgt", QuestionnaireSetupKeywordsTxt);

            Sender.InsertManualSetup(ActivitiesNameTxt, ActivitiesNameTxt, ActivitiesDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Activity List", ManualSetupCategory::"Relationship Mgt", ActivitiesKeywordsTxt);

            Sender.InsertManualSetup(MarketingSetupNameTxt, MarketingSetupNameTxt, MarketingSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Marketing Setup", ManualSetupCategory::"Relationship Mgt", MarketingSetupKeywordsTxt);

            Sender.InsertManualSetup(InteractionTemplateSetupNameTxt, InteractionTemplateSetupNameTxt, InteractionTemplateSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Interaction Template Setup", ManualSetupCategory::"Relationship Mgt", InteractionTemplateSetupKeywordsTxt);
        end;

        // Service
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(OnlineMapSetupNameTxt, OnlineMapSetupNameTxt, OnlineMapSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Online Map Setup", ManualSetupCategory::Service, OnlineMapSetupKeywordsTxt);

        // Sales
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(SalesReceivablesSetupNameTxt, SalesReceivablesSetupNameTxt, SalesReceivablesSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Sales & Receivables Setup", ManualSetupCategory::Sales, SalesReceivablesSetupKeywordsTxt);

        // Purchasing
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.InsertManualSetup(PurchasePayablesSetupNameTxt, PurchasePayablesSetupNameTxt, PurchasePayablesSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"Purchases & Payables Setup", ManualSetupCategory::Purchasing, PurchasePayablesSetupKeywordsTxt);

        // Intercompany
        IF ApplicationAreaMgmtFacade.IsIntercompanyEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.InsertManualSetup(ICSetupTxt, ICSetupTxt, ICSetupDescriptionTxt, 0, ObjectType::Page,
              PAGE::"IC Setup", ManualSetupCategory::Intercompany, ICSetupKeywordsTxt);

            Sender.InsertManualSetup(ICPartnersTxt, ICPartnersTxt, ICPartnersDescriptionTxt, 0, ObjectType::Page,
              PAGE::"IC Partner List", ManualSetupCategory::Intercompany, ICPartnersKeywordsTxt);

            Sender.InsertManualSetup(ICChartOfAccountsTxt, ICChartOfAccountsTxt, ICChartOfAccountsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"IC Chart of Accounts", ManualSetupCategory::Intercompany, ICChartOfAccountsKeywordsTxt);

            Sender.InsertManualSetup(ICDimensionsTxt, ICDimensionsTxt, ICDimensionsDescriptionTxt, 0, ObjectType::Page,
              PAGE::"IC Dimension List", ManualSetupCategory::Intercompany, ICDimensionsKeywordsTxt);
        end;

        // SmartList Designer
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled() OR ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(SmartListDesignerTxt, SmartListDesignerTxt, SmartListDesignerDescriptionTxt, 0, ObjectType::Page,
              PAGE::"SmartList Designer Setup", ManualSetupCategory::System, SmartListDesignerKeywordsTxt);
    end;
}

