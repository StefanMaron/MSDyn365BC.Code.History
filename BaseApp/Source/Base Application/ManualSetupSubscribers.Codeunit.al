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
        UsersNameTxt: Label 'Users';
        UsersDescriptionTxt: Label 'Set up users and assign permissions sets.';
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

    [EventSubscriber(ObjectType::Codeunit, 1875, 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertSetupOnRegisterManualSetup(var Sender: Codeunit "Manual Setup")
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EnvironmentInfo: Codeunit "Environment Information";
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);

        // General
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(CompanyNameTxt, CompanyDescriptionTxt,
              CompanyKeywordsTxt, PAGE::"Company Information", Info.Id(), ManualSetupCategory::General);
            Sender.Insert(CountriesRegionsNameTxt, CountriesRegionsDescriptionTxt,
              CountriesRegionsKeywordsTxt, PAGE::"Countries/Regions", Info.Id(), ManualSetupCategory::General);
            Sender.Insert(NoSeriesNameTxt, NoSeriesDescriptionTxt,
              NoSeriesKeywordsTxt, PAGE::"No. Series", Info.Id(), ManualSetupCategory::General);
            Sender.Insert(PostCodesNameTxt, PostCodesDescriptionTxt,
              PostCodesKeywordsTxt, PAGE::"Post Codes", Info.Id(), ManualSetupCategory::General);
            Sender.Insert(ReasonCodesNameTxt, ReasonCodesDescriptionTxt,
              ReasonCodesKeywordsTxt, PAGE::"Reason Codes", Info.Id(), ManualSetupCategory::General);
            Sender.Insert(SourceCodesNameTxt, SourceCodesDescriptionTxt,
              SourceCodesKeywordsTxt, PAGE::"Source Codes", Info.Id(), ManualSetupCategory::General);
        end;

        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(CurrenciesNameTxt, CurrenciesDescriptionTxt,
              CurrenciesKeywordsTxt, PAGE::Currencies, Info.Id(), ManualSetupCategory::General);
            Sender.Insert(LanguagesNameTxt, LanguagesDescriptionTxt,
              LanguagesKeywordsTxt, PAGE::Languages, Info.Id(), ManualSetupCategory::General);
        end;

        // Finance
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(GeneralLedgerSetupNameTxt, GeneralLedgerSetupDescriptionTxt,
              GeneralLedgerSetupKeywordsTxt, PAGE::"General Ledger Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(AccountingPeriodsNameTxt, AccountingPeriodsDescriptionTxt,
              AccountingPeriodsKeywordsTxt, PAGE::"Accounting Periods",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(BankExportImportSetupNameTxt, BankExportImportSetupDescriptionTxt,
              BankExportImportSetupKeywordsTxt, PAGE::"Bank Export/Import Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(GeneralPostingSetupNameTxt, GeneralPostingSetupDescriptionTxt,
              GeneralPostingSetupKeywordsTxt, PAGE::"General Posting Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(GenBusinessPostingGroupsNameTxt, GenBusinessPostingGroupsDescriptionTxt,
              GenBusinessPostingGroupsKeywordsTxt, PAGE::"Gen. Business Posting Groups",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(GenProductPostingGroupsNameTxt, GenProductPostingGroupsDescriptionTxt,
              GenProductPostingGroupsKeywordsTxt, PAGE::"Gen. Product Posting Groups",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATPostingSetupNameTxt, VATPostingSetupDescriptionTxt,
              VATPostingSetupKeywordsTxt, PAGE::"VAT Posting Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATBusinessPostingGroupsNameTxt, VATBusinessPostingGroupsDescriptionTxt,
              VATBusinessPostingGroupsKeywordsTxt, PAGE::"VAT Business Posting Groups",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATProductPostingGroupsNameTxt, VATProductPostingGroupsDescriptionTxt,
              VATProductPostingGroupsKeywordsTxt, PAGE::"VAT Product Posting Groups",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATReportSetupNameTxt, VATReportSetupDescriptionTxt,
              VATReportSetupKeywordsTxt, PAGE::"VAT Report Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(BankAccountPostingGroupsNameTxt, BankAccountPostingGroupsDescriptionTxt,
              BankAccountPostingGroupsKeywordsTxt, PAGE::"Bank Account Posting Groups",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(GeneralJournalTemplatesNameTxt, GeneralJournalTemplatesDescriptionTxt,
              GeneralJournalTemplatesKeywordsTxt, PAGE::"General Journal Templates",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATStatementTemplatesNameTxt, VATStatementTemplatesDescriptionTxt,
              VATStatementTemplatesKeywordsTxt, PAGE::"VAT Statement Templates",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATClausesNameTxt, VATClausesDescriptionTxt,
              VATClausesKeywordsTxt, PAGE::"VAT Clauses",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATReportConfigTxt, VATReportConfigDescriptionTxt,
              VATReportConfigKeywordsTxt, PAGE::"VAT Reports Configuration",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(VATReportTxt, VATReportDescriptionTxt,
              VATReportKeywordsTxt, PAGE::"VAT Report Setup",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(CashFlowSetupNameTxt, CashFlowSetupDescriptionTxt,
              CashFlowSetupKeywordsTxt, PAGE::"Cash Flow Setup",
              Info.Id(), ManualSetupCategory::Finance);
        end;

        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(DimensionsNameTxt, DimensionsDescriptionTxt,
              DimensionsKeywordsTxt, PAGE::Dimensions,
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(AnalysisViewsTxt, AnalysisViewsDescriptionTxt,
              AnalysisViewsKeywordsTxt, PAGE::"Analysis View List",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(CostAccountingSetupNameTxt, CostAccountingSetupDescriptionTxt,
              CostAccountingSetupKeywordsTxt, PAGE::"Cost Accounting Setup",
              Info.Id(), ManualSetupCategory::Finance);
        end;

        IF ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(ResponsibilityCentersNameTxt, ResponsibilityCentersDescriptionTxt,
              ResponsibilityCentersKeywordsTxt, PAGE::"Responsibility Center List",
              Info.Id(), ManualSetupCategory::Finance);
            Sender.Insert(IntrastatTemplatesNameTxt, IntrastatTemplatesDescriptionTxt,
              IntrastatTemplatesKeywordsTxt, PAGE::"Intrastat Journal Templates",
              Info.Id(), ManualSetupCategory::Finance);
        end;

        // System
        IF ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(PermissionSetsNameTxt, PermissionSetsDescriptionTxt,
              PermissionSetsKeywordsTxt, PAGE::"Permission Sets", Info.Id(), ManualSetupCategory::System);

        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(ReportLayoutsNameTxt, ReportLayoutsDescriptionTxt,
              ReportLayoutsKeywordsTxt, PAGE::"Report Layout Selection", Info.Id(), ManualSetupCategory::System);
            Sender.Insert(SMTPMailSetupNameTxt, SMTPMailSetupDescriptionTxt,
              SMTPMailSetupKeywordsTxt, PAGE::"SMTP Mail Setup", Info.Id(), ManualSetupCategory::System);
            Sender.Insert(UsersNameTxt, UsersDescriptionTxt,
              UsersKeywordsTxt, PAGE::Users, Info.Id(), ManualSetupCategory::System);
            IF EnvironmentInfo.IsSaaS then
                Sender.Insert(
                  EnvironmentTxt, EnvironmentDescriptionTxt, EnvironmentKeywordsTxt,
                  PAGE::"Sandbox Environment", Info.Id(), ManualSetupCategory::System);
        end;

        // Jobs
        IF ApplicationAreaMgmtFacade.IsJobsEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(JobsSetupNameTxt, JobsSetupDescriptionTxt,
              JobsSetupKeywordsTxt, PAGE::"Jobs Setup", Info.Id(), ManualSetupCategory::Jobs);

        // Fixed Assets
        IF ApplicationAreaMgmtFacade.IsFixedAssetEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(FixedAssetSetupNameTxt, FixedAssetSetupDescriptionTxt,
              FixedAssetSetupKeywordsTxt, PAGE::"Fixed Asset Setup", Info.Id(), ManualSetupCategory::"Fixed Assets");

        // HR
        IF ApplicationAreaMgmtFacade.IsBasicHREnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(HumanResourcesSetupNameTxt, HumanResourcesSetupDescriptionTxt,
              HumanResourcesSetupKeywordsTxt, PAGE::"Human Resources Setup",
              Info.Id(), ManualSetupCategory::HR);

        // Inventory
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(InventorySetupNameTxt, InventorySetupDescriptionTxt,
              InventorySetupKeywordsTxt, PAGE::"Inventory Setup", Info.Id(), ManualSetupCategory::Inventory);

        // Location
        IF ApplicationAreaMgmtFacade.IsLocationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(LocationsNameTxt, LocationsDescriptionTxt,
              LocationsKeywordsTxt, PAGE::"Location List", Info.Id(), ManualSetupCategory::Inventory);

            Sender.Insert(TransferRoutesNameTxt, TransferRoutesDescriptionTxt,
              TransferRoutesKeywordsTxt, PAGE::"Transfer Routes", Info.Id(), ManualSetupCategory::Inventory);
        end;

        // Item Charges
        IF ApplicationAreaMgmtFacade.IsItemChargesEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(ItemChargesNameTxt, ItemChargesDescriptionTxt,
              ItemChargesKeywordsTxt, PAGE::"Item Charges", Info.Id(), ManualSetupCategory::Inventory);

        // Relationship Management
        IF ApplicationAreaMgmtFacade.IsSuiteEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(BusinessRelationsNameTxt, BusinessRelationsDescriptionTxt,
              BusinessRelationsKeywordsTxt, PAGE::"Business Relations", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(IndustryGroupsNameTxt, IndustryGroupsDescriptionTxt,
              IndustryGroupsKeywordsTxt, PAGE::"Industry Groups", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(WebSourcesNameTxt, WebSourcesDescriptionTxt,
              WebSourcesKeywordsTxt, PAGE::"Web Sources", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(JobResponsibilitiesNameTxt, JobResponsibilitiesDescriptionTxt,
              JobResponsibilitiesKeywordsTxt, PAGE::"Job Responsibilities",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(OrganizationalLevelsNameTxt, OrganizationalLevelsDescriptionTxt,
              OrganizationalLevelsKeywordsTxt, PAGE::"Organizational Levels",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(InteractionGroupsNameTxt, InteractionGroupsDescriptionTxt,
              InteractionGroupsKeywordsTxt, PAGE::"Interaction Groups", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(InteractionTemplatesNameTxt, InteractionTemplatesDescriptionTxt,
              InteractionTemplatesKeywordsTxt, PAGE::"Interaction Templates",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(SalutationsNameTxt, SalutationsDescriptionTxt,
              SalutationsKeywordsTxt, PAGE::Salutations, Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(MailingGroupsNameTxt, MailingGroupsDescriptionTxt,
              MailingGroupsKeywordsTxt, PAGE::"Mailing Groups", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(SalesCyclesNameTxt, SalesCyclesDescriptionTxt,
              SalesCyclesKeywordsTxt, PAGE::"Sales Cycles", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(CloseOpportunityCodesNameTxt, CloseOpportunityCodesDescriptionTxt,
              CloseOpportunityCodesKeywordsTxt, PAGE::"Close Opportunity Codes",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(QuestionnaireSetupNameTxt, QuestionnaireSetupDescriptionTxt,
              QuestionnaireSetupKeywordsTxt, PAGE::"Profile Questionnaires",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(ActivitiesNameTxt, ActivitiesDescriptionTxt,
              ActivitiesKeywordsTxt, PAGE::"Activity List", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(MarketingSetupNameTxt, MarketingSetupDescriptionTxt,
              MarketingSetupKeywordsTxt, PAGE::"Marketing Setup", Info.Id(), ManualSetupCategory::"Relationship Mgt");

            Sender.Insert(InteractionTemplateSetupNameTxt, InteractionTemplateSetupDescriptionTxt,
              InteractionTemplateSetupKeywordsTxt, PAGE::"Interaction Template Setup",
              Info.Id(), ManualSetupCategory::"Relationship Mgt");
        end;

        // Service
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(OnlineMapSetupNameTxt, OnlineMapSetupDescriptionTxt,
              OnlineMapSetupKeywordsTxt, PAGE::"Online Map Setup", Info.Id(), ManualSetupCategory::Service);

        // Sales
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(SalesReceivablesSetupNameTxt, SalesReceivablesSetupDescriptionTxt,
              SalesReceivablesSetupKeywordsTxt, PAGE::"Sales & Receivables Setup",
              Info.Id(), ManualSetupCategory::Sales);

        // Purchasing
        IF ApplicationAreaMgmtFacade.IsFoundationEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then
            Sender.Insert(PurchasePayablesSetupNameTxt, PurchasePayablesSetupDescriptionTxt,
              PurchasePayablesSetupKeywordsTxt, PAGE::"Purchases & Payables Setup",
              Info.Id(), ManualSetupCategory::Purchasing);

        // Intercompany
        IF ApplicationAreaMgmtFacade.IsIntercompanyEnabled OR ApplicationAreaMgmtFacade.IsAllDisabled then begin
            Sender.Insert(ICSetupTxt, ICSetupDescriptionTxt,
              ICSetupKeywordsTxt, PAGE::"IC Setup", Info.Id(), ManualSetupCategory::Intercompany);

            Sender.Insert(ICPartnersTxt, ICPartnersDescriptionTxt,
              ICPartnersKeywordsTxt, PAGE::"IC Partner List", Info.Id(), ManualSetupCategory::Intercompany);

            Sender.Insert(ICChartOfAccountsTxt, ICChartOfAccountsDescriptionTxt,
              ICChartOfAccountsKeywordsTxt, PAGE::"IC Chart of Accounts", Info.Id(), ManualSetupCategory::Intercompany);

            Sender.Insert(ICDimensionsTxt, ICDimensionsDescriptionTxt,
              ICDimensionsKeywordsTxt, PAGE::"IC Dimension List", Info.Id(), ManualSetupCategory::Intercompany);
        end;
    end;
}

