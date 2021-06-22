codeunit 2110 "O365 Sales Initial Setup"
{
    Permissions = TableData "Sales Document Icon" = rimd,
                  TableData "Marketing Setup" = rimd;

    trigger OnRun()
    begin
        InitializeO365SalesCompany;
        InitializeAccountingPeriod; // ensure accounting period is always valid
        EnableCompanyInvoicingApplicationArea;
        CreatePaymentRegistrationSetupForCurrentUser; // payment registration setup needs to be initialized per user
        ValidateUserLocale;
    end;

    var
        Company: Record Company;
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        OverrideDefaultsWithSalesSetupQst: Label 'We would like to update some configuration data but have detected some existing invoices. Would you like to update the configuration data anyway?';
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        HideDialogs: Boolean;
        SetupCompleteMsg: Label 'Hello, this is your invoicing overview. The invoice you created has been saved as a draft.';
        ViewInvoiceLbl: Label 'View Draft';
        DeleteInvoiceLbl: Label 'Discard Draft';
        NoInvoiceMsg: Label 'The draft invoice does not exist.';
        ConfirmInvoiceDeleteQst: Label 'Are you sure you want to delete the invoice for %1?', Comment = '%1 = customer name';
        NotAnInvoicingCompanyErr: Label 'You cannot use the company %1 in Microsoft Invoicing because you use it in Microsoft Dynamics 365.', Comment = '%1 = The name of your company';
        DefaultLbl: Label 'Default';
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        TaxableDescriptionTxt: Label 'Taxable';
        DefaultCityTxt: Label 'Default';
        CompanyCodeTok: Label 'COMPANY', Locked = true;
        PersonCodeTok: Label 'PERSON', Locked = true;
        SalesMailTok: Label 'SALESEMAIL', Locked = true;
        OutOfDateCompanyErr: Label 'You have used this company in Dynamics 365 a long time ago. Please go to Dynamics 365 Business Central and recreate the company. If you have forgotten your login details, the site will help you.\For more information, see https://go.microsoft.com/fwlink/?linkid=860971.', Comment = 'No translation needed for url';
        CannotSendTestInvoiceErr: Label 'You cannot send a test invoice.';
        InitialSetupCategoryTxt: Label 'AL InvInitialSetup', Locked = true;
        BadLocaleMsg: Label 'An invalid locale was detected for the current user: %1. Resetting to %2.', Locked = true;
        CompanyRead: Boolean;
        O365SalesInitSetupRead: Boolean;
        InvoicingNotSupportedErr: Label 'Sorry, we are no longer accepting subscriptions for Microsoft Invoicing.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2101368.', Comment = 'No translation needed for url';

    procedure HideConfirmDialog()
    begin
        HideDialogs := true;
    end;

    local procedure InitializeO365SalesCompany()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Overwrite: Boolean;
    begin
        // Override defaults for O365 Sales
        if not GetO365SalesInitialSetup then
            exit;
        if O365SalesInitialSetup."Is initialized" then
            exit;

        if not (IsNewCompany or HideDialogs) then begin
            if not GuiAllowed then
                exit;
            Overwrite := Confirm(OverrideDefaultsWithSalesSetupQst);
        end;

        O365SalesInitialSetup.LockTable();
        O365SalesInitialSetup.Get();

        if IsNewCompany or Overwrite then begin
            InitializeBankAccount;
            InitializeSalesAndReceivablesSetup;
            InitializePaymentRegistrationSetup;
            InitializeReportSelections;
            InitializeNotifications;
            InitializeNoSeries;
            InitializeDefaultBCC;
            InitializeCustomerTemplate;
            InitializeContactToCustomerTemplate;
            InitializePaymentInstructions;
            InitializeItemTemplate;
            ClearPaymentMethodsBalAccount;
        end;

        InitializeVAT;
        InitializeVATRegService;
        InitializeTax;
        SetFinancialsJobQueueEntriesOnHold;

        O365SalesInitialSetup."Is initialized" := true;
        O365SalesInitialSetup.Modify();

        AssistedSetup.Complete(PAGE::"Assisted Company Setup Wizard");
    end;

    local procedure InitializePaymentRegistrationSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(
             O365SalesInitialSetup."Payment Reg. Template Name",
             O365SalesInitialSetup."Payment Reg. Batch Name")
        then
            exit;

        with PaymentRegistrationSetup do begin
            DeleteAll();
            Init;
            Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
            Validate("Journal Batch Name", GenJournalBatch.Name);
            Insert(true);
        end;
    end;

    local procedure CreatePaymentRegistrationSetupForCurrentUser()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if PaymentRegistrationSetup.Get(UserId) then
            exit;
        if PaymentRegistrationSetup.Get then begin
            PaymentRegistrationSetup."User ID" := UserId;
            if PaymentRegistrationSetup.Insert(true) then;
        end;
    end;

    local procedure InitializeSalesAndReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesReceivablesSetup.Get then
            SalesReceivablesSetup.Insert(true);

        SalesReceivablesSetup."Default Item Quantity" := true;
        SalesReceivablesSetup."Create Item from Description" := true;
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup."Calc. Inv. Discount" := true;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure InitializeCustomerTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        ConfigTemplateHeader.SetFilter(Code, '<>%1', O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.DeleteAll(true);

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Payment Method Code"), O365SalesInitialSetup."Default Payment Method Code");
        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Payment Terms Code"), O365SalesInitialSetup."Default Payment Terms Code");

        if CompanyInformation.Get then
            if CountryRegion.Get(CompanyInformation.GetCompanyCountryRegionCode) then
                ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
                  DATABASE::Customer, Customer.FieldNo("Country/Region Code"), CountryRegion.Code);

        ConfigTmplSelectionRules.SetRange("Table ID", DATABASE::Customer);
        if not ConfigTmplSelectionRules.FindFirst then begin
            ConfigTmplSelectionRules.Validate("Table ID", DATABASE::Customer);
            ConfigTmplSelectionRules.Validate("Page ID", PAGE::"Customer Entity");
            ConfigTmplSelectionRules.Validate("Template Code", O365SalesInitialSetup."Default Customer Template");
            ConfigTmplSelectionRules.Insert(true);
            exit;
        end;

        Clear(ConfigTmplSelectionRules."Selection Criteria");
        ConfigTmplSelectionRules.Modify(true);
    end;

    local procedure InitializeContactToCustomerTemplate()
    var
        MarketingSetup: Record "Marketing Setup";
        CompanyCustomerTemplate: Record "Customer Template";
        PersonCustomerTemplate: Record "Customer Template";
        ConfigTemplateLine: Record "Config. Template Line";
        CompanyTemplateFieldRef: FieldRef;
        CompanyTemplateRecordRef: RecordRef;
        PersonTemplateFieldRef: FieldRef;
        PersonTemplateRecordRef: RecordRef;
    begin
        if not MarketingSetup.Get then begin
            MarketingSetup.Init();
            MarketingSetup.Insert(true);
        end;

        if (MarketingSetup."Cust. Template Company Code" = '') or
           (MarketingSetup."Cust. Template Person Code" = '')
        then begin
            MarketingSetup.Validate("Cust. Template Company Code", CompanyCodeTok);
            MarketingSetup.Validate("Cust. Template Person Code", PersonCodeTok);
            MarketingSetup.Modify(true);
        end;

        // Get the fields that we need to copy over to the customer template
        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateLine.SetFilter(
          "Field ID",
          '<>%1&<>%2&<>%3',// there are some fields we should ignore
          CompanyCustomerTemplate.FieldNo("Contact Type"),
          CompanyCustomerTemplate.FieldNo("Allow Line Disc."),
          CompanyCustomerTemplate.FieldNo("Prices Including VAT"));

        if not ConfigTemplateLine.FindSet then
            exit;

        if not CompanyCustomerTemplate.Get(MarketingSetup."Cust. Template Company Code") then begin
            CompanyCustomerTemplate.Validate(Code, CompanyCodeTok);
            CompanyCustomerTemplate.Validate("Contact Type", CompanyCustomerTemplate."Contact Type"::Company);
            CompanyCustomerTemplate.Validate("Allow Line Disc.", true);
            CompanyCustomerTemplate.Insert(true);
        end;

        if not PersonCustomerTemplate.Get(MarketingSetup."Cust. Template Person Code") then begin
            PersonCustomerTemplate.Validate(Code, PersonCodeTok);
            PersonCustomerTemplate.Validate("Contact Type", PersonCustomerTemplate."Contact Type"::Person);
            PersonCustomerTemplate.Validate("Allow Line Disc.", true);
            if O365SalesInitialSetup."Tax Type" = O365SalesInitialSetup."Tax Type"::VAT then
                PersonCustomerTemplate.Validate("Prices Including VAT", true);
            PersonCustomerTemplate.Insert(true);
        end else
            if O365SalesInitialSetup."Tax Type" = O365SalesInitialSetup."Tax Type"::VAT then begin
                PersonCustomerTemplate.Validate("Prices Including VAT", true);
                PersonCustomerTemplate.Modify(true);
            end;

        CompanyTemplateRecordRef.GetTable(CompanyCustomerTemplate);
        PersonTemplateRecordRef.GetTable(PersonCustomerTemplate);

        repeat
            if CompanyTemplateRecordRef.FieldExist(ConfigTemplateLine."Field ID") then begin
                CompanyTemplateFieldRef := CompanyTemplateRecordRef.Field(ConfigTemplateLine."Field ID");
                PersonTemplateFieldRef := PersonTemplateRecordRef.Field(ConfigTemplateLine."Field ID");
                CompanyTemplateFieldRef.Validate(ConfigTemplateLine."Default Value");
                PersonTemplateFieldRef.Validate(ConfigTemplateLine."Default Value");
            end;
        until ConfigTemplateLine.Next = 0;

        CompanyTemplateRecordRef.Modify(true);
        PersonTemplateRecordRef.Modify(true);
    end;

    local procedure InitializeItemTemplate()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
    begin
        ConfigTemplateHeader.SetFilter(Code, '<>%1', O365SalesInitialSetup."Default Item Template");
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateHeader.DeleteAll(true);

        ConfigTmplSelectionRules.SetRange("Table ID", DATABASE::Item);
        if not ConfigTmplSelectionRules.FindFirst then begin
            ConfigTmplSelectionRules.Validate("Table ID", DATABASE::Item);
            ConfigTmplSelectionRules.Validate("Page ID", PAGE::"Item Entity");
            ConfigTmplSelectionRules.Validate("Template Code", O365SalesInitialSetup."Default Item Template");
            ConfigTmplSelectionRules.Insert(true);
            exit;
        end;

        Clear(ConfigTmplSelectionRules."Selection Criteria");
        ConfigTmplSelectionRules.Modify(true);
    end;

    local procedure InitializeReportSelections()
    var
        DummyReportSelections: Record "Report Selections";
    begin
        InitializeReportSelection(
          REPORT::"Standard Sales - Draft Invoice", DummyReportSelections.Usage::"S.Invoice Draft",
          'MS-1303-INVOICING', SalesMailTok, DummyReportSelections."Email Body Layout Type"::"HTML Layout");
        InitializeReportSelection(
          REPORT::"Standard Sales - Quote", DummyReportSelections.Usage::"S.Quote",
          'MS-1304-INVOICING', SalesMailTok, DummyReportSelections."Email Body Layout Type"::"HTML Layout");
        InitializeReportSelection(
          REPORT::"Standard Sales - Invoice", DummyReportSelections.Usage::"S.Invoice",
          'MS-1306-INVOICING', SalesMailTok, DummyReportSelections."Email Body Layout Type"::"HTML Layout");
    end;

    local procedure InitializeReportSelection(ReportID: Integer; ReportUsage: Enum "Report Selection Usage"; LayoutCode: Code[20]; EmailBodyLayoutCode: Code[20]; EmailBodyLayoutType: Option)
    var
        ReportSelections: Record "Report Selections";
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.DeleteAll();

        ReportSelections.Usage := ReportUsage;
        ReportSelections.NewRecord;
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Validate("Use for Email Body", true);
        ReportSelections.Validate("Email Body Layout Type", EmailBodyLayoutType);
        ReportSelections.Validate("Email Body Layout Code", EmailBodyLayoutCode);
        ReportSelections.Insert(true);

        CustomReportLayout.Reset();
        CustomReportLayout.SetRange(Code, LayoutCode);
        CustomReportLayout.SetRange("Report ID", ReportID);
        if not CustomReportLayout.FindFirst then
            exit;

        if ReportLayoutSelection.Get(ReportID, CompanyName) then
            ReportLayoutSelection.Delete();
        ReportLayoutSelection.Init();
        ReportLayoutSelection.Validate("Report ID", ReportID);
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Custom Layout");
        ReportLayoutSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);
        ReportLayoutSelection.Insert(true);
    end;

    local procedure InitializeNotifications()
    var
        MyNotifications: Record "My Notifications";
        MyNotificationsPage: Page "My Notifications";
    begin
        // Disable all notifications
        MyNotificationsPage.InitializeNotificationsWithDefaultState;
        MyNotifications.ModifyAll(Enabled, false, true);
    end;

    local procedure InitializeNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if not IsNewCompany then
            exit; // Do not change no. series if we already have invoices documents

        if not SalesReceivablesSetup.Get then
            exit;

        if O365SalesInitialSetup."Sales Invoice No. Series" <> '' then
            SalesReceivablesSetup.Validate("Invoice Nos.", O365SalesInitialSetup."Sales Invoice No. Series");
        if O365SalesInitialSetup."Posted Sales Inv. No. Series" <> '' then
            SalesReceivablesSetup.Validate("Posted Invoice Nos.", O365SalesInitialSetup."Posted Sales Inv. No. Series");
        if O365SalesInitialSetup."Sales Quote No. Series" <> '' then
            SalesReceivablesSetup.Validate("Quote Nos.", O365SalesInitialSetup."Sales Quote No. Series");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure InitializeTax()
    var
        GLAccount: Record "G/L Account";
        CompanyInformation: Record "Company Information";
        TaxGroup: Record "Tax Group";
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxSetup: Record "Tax Setup";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        Item: Record Item;
        Customer: Record Customer;
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
    begin
        if CompanyInformation.Get and (CompanyInformation.City <> '') then begin
            TaxAreaCode := UpperCase(CopyStr(CompanyInformation.City, 1, MaxStrLen(TaxAreaCode) - 4));
            TaxJurisdictionCode := CopyStr(TaxAreaCode, 1, MaxStrLen(TaxJurisdictionCode));
            if CompanyInformation.County <> '' then // 2 char state
                TaxAreaCode := CopyStr(TaxAreaCode + ', ' + CopyStr(CompanyInformation.County, 1, 2), 1, MaxStrLen(TaxAreaCode));
        end else begin
            TaxAreaCode := DefaultLbl;
            TaxJurisdictionCode := DefaultCityTxt;
        end;

        if not TaxArea.Get(TaxAreaCode) then begin
            TaxArea.Init();
            TaxArea.Validate(Code, TaxAreaCode);
            TaxArea.Validate(Description, TaxAreaCode);
            TaxArea.Insert();
        end;

        if not TaxJurisdiction.Get(TaxJurisdictionCode) then begin
            TaxJurisdiction.Init();
            TaxJurisdiction.Validate(Code, TaxJurisdictionCode);
            TaxJurisdiction.Insert();
        end;

        if not TaxGroup.Get(TaxableCodeTxt) then begin
            TaxGroup.Init();
            TaxGroup.Validate(Code, TaxableCodeTxt);
            TaxGroup.Validate(Description, TaxableDescriptionTxt);
            TaxGroup.Insert();
        end;

        if TaxSetup.Get then;
        TaxJurisdiction.Validate(Description, TaxableDescriptionTxt);
        if GLAccount.Get(TaxSetup."Tax Account (Sales)") then
            TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        if GLAccount.Get(TaxSetup."Tax Account (Purchases)") then
            TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify();

        if not TaxAreaLine.Get(TaxArea.Code, TaxJurisdiction.Code) then begin
            TaxAreaLine.Init();
            TaxAreaLine.Validate("Tax Area", TaxArea.Code);
            TaxAreaLine.Validate("Tax Jurisdiction Code", TaxJurisdiction.Code);
            TaxAreaLine.Insert();
        end;

        if not TaxDetail.Get(TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax", WorkDate) then begin
            TaxDetail.Init();
            TaxDetail.Validate("Tax Jurisdiction Code", TaxJurisdiction.Code);
            TaxDetail.Validate("Tax Group Code", TaxGroup.Code);
            TaxDetail.Validate("Tax Type", TaxDetail."Tax Type"::"Sales Tax");
            TaxDetail.Validate("Effective Date", WorkDate);
            TaxDetail.Insert(true);
        end;

        TaxDetail.Validate("Maximum Amount/Qty.", 0);
        TaxDetail.Validate("Tax Below Maximum", 0);
        TaxDetail.Modify();

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Item, Item.FieldNo("Tax Group Code"), TaxGroup.Code);

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Tax Area Code"), TaxArea.Code);
    end;

    local procedure InitializeVAT()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATBusinessPostingGroup.SetFilter(Code, '<>%1', O365SalesInitialSetup."Default VAT Bus. Posting Group");
        VATBusinessPostingGroup.DeleteAll();

        VATProductPostingGroup.SetFilter(
          Code,
          '<>%1&<>%2&<>%3',
          O365SalesInitialSetup."Normal VAT Prod. Posting Gr.",
          O365SalesInitialSetup."Reduced VAT Prod. Posting Gr.",
          O365SalesInitialSetup."Zero VAT Prod. Posting Gr.");
        VATProductPostingGroup.DeleteAll();

        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', O365SalesInitialSetup."Default VAT Bus. Posting Group");
        VATPostingSetup.DeleteAll();
        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter(
          "VAT Prod. Posting Group",
          '<>%1&<>%2&<>%3',
          O365SalesInitialSetup."Normal VAT Prod. Posting Gr.",
          O365SalesInitialSetup."Reduced VAT Prod. Posting Gr.",
          O365SalesInitialSetup."Zero VAT Prod. Posting Gr.");
        VATPostingSetup.DeleteAll();
    end;

    local procedure InitializeAccountingPeriod()
    var
        Item: Record Item;
        AccountingPeriod: Record "Accounting Period";
        CreateFiscalYear: Report "Create Fiscal Year";
        DateFormulaVariable: DateFormula;
    begin
        if not (GetO365SalesInitialSetup and O365SalesInitialSetup."Is initialized") then
            exit;

        if AccountingPeriod.FindLast then
            if AccountingPeriod."Starting Date" > WorkDate + 366 then
                exit;

        // Auto-create accounting periods will fail with items with average costing.
        Item.SetRange("Costing Method", Item."Costing Method"::Average);
        if not Item.IsEmpty then
            exit;

        AccountingPeriod.LockTable();
        if AccountingPeriod.FindLast then
            if AccountingPeriod."Starting Date" > WorkDate + 366 then
                exit;

        AccountingPeriod.SetRange("New Fiscal Year", true);
        if not AccountingPeriod.FindLast then
            AccountingPeriod."Starting Date" := CalcDate('<-CY>', WorkDate)
        else
            AccountingPeriod."Starting Date" := CalcDate('<1Y>', AccountingPeriod."Starting Date");

        Evaluate(DateFormulaVariable, '<1M>');
        CreateFiscalYear.InitializeRequest(12, DateFormulaVariable, AccountingPeriod."Starting Date");
        CreateFiscalYear.UseRequestPage(false);
        CreateFiscalYear.HideConfirmationDialog(true);
        CreateFiscalYear.RunModal;
    end;

    local procedure InitializeBankAccount()
    var
        CompanyInformation: Record "Company Information";
        BankAccount: Record "Bank Account";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        CompanyInformation.LockTable();
        if not CompanyInformation.Get then
            exit;

        CompanyInformation.Validate("Allow Blank Payment Info.", true);
        CompanyInformation.Modify(true);

        CompanyInformationMgt.UpdateCompanyBankAccount(CompanyInformation, '', BankAccount);
    end;

    local procedure InitializePaymentInstructions()
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        O365PaymentInstrTransl: Record "O365 Payment Instr. Transl.";
    begin
        if GetCompany then;
        O365PaymentInstructions.SetRange(Default, true);
        if O365PaymentInstructions.FindFirst then begin
            O365PaymentInstructions.SetPaymentInstructions(
              StrSubstNo(O365PaymentInstructions.GetPaymentInstructions, Company."Display Name"));
            O365PaymentInstructions.Modify(true);
            O365PaymentInstrTransl.SetRange(Id, O365PaymentInstructions.Id);
            if O365PaymentInstrTransl.FindSet then
                repeat
                    O365PaymentInstrTransl.SetTranslPaymentInstructions(
                      StrSubstNo(O365PaymentInstrTransl.GetTransPaymentInstructions, Company."Display Name"));
                    O365PaymentInstrTransl.Modify(true);
                until O365PaymentInstrTransl.Next = 0;
        end;
    end;

    local procedure InitializeDefaultBCC()
    var
        O365EmailSetup: Record "O365 Email Setup";
        EmailAccount: Record "Email Account";
        EmailFeature: Codeunit "Email Feature";
        EmailScenario: Codeunit "Email Scenario";
        BccEmail: Text[80];
    begin
        if EmailFeature.IsEnabled() then begin
            if EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount) then
                BccEmail := CopyStr(EmailAccount."Email Address", 1, MaxStrLen(BccEmail));
        end else
            BccEmail := TryGetEmailFromSmtpSetup();

        if BccEmail = '' then begin
            BccEmail := TryGetEmailFromCurrentUser();
            if BccEmail = '' then
                exit;
        end;

        O365EmailSetup.SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, BccEmail);
        O365EmailSetup.SetRange(RecipientType, O365EmailSetup.RecipientType::BCC);
        if O365EmailSetup.FindFirst then
            exit;

        // Add the email to BCC on all invoices
        O365EmailSetup.Reset();
        O365EmailSetup.Init();
        O365EmailSetup.Validate(RecipientType, O365EmailSetup.RecipientType::BCC);
        O365EmailSetup.Email := BccEmail;
        O365EmailSetup.Insert(true);
    end;

    local procedure InitializeVATRegService()
    var
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        VATRegistrationLogMgt.EnableService;
    end;

    local procedure SetFinancialsJobQueueEntriesOnHold()
    var
        DummyJobQueueEntry: Record "Job Queue Entry";
    begin
        SetJobQueueEntriesOnHoldForObject(DummyJobQueueEntry."Object Type to Run"::Report, REPORT::"Delegate Approval Requests");
        SetJobQueueEntriesOnHoldForObject(DummyJobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"O365 Sync. Management");
    end;

    local procedure SetJobQueueEntriesOnHoldForObject(ObjectTypeToRun: Option; ObjectIdToRun: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", ObjectTypeToRun);
            SetRange("Object ID to Run", ObjectIdToRun);
            SetFilter(Status, '<>%1', Status::"On Hold");
            if IsEmpty then
                exit;

            ModifyAll(Status, Status::"On Hold", true);
        end;
    end;

    local procedure ValidateUserLocale()
    var
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
        Language: Codeunit Language;
    begin
        if not (UserPersonalization.ReadPermission and UserPersonalization.WritePermission) then
            exit;
        if not WindowsLanguage.ReadPermission then
            exit;
        if not UserPersonalization.Get(UserSecurityId) then
            exit;

        if WindowsLanguage.Get(UserPersonalization."Locale ID") then
            exit; // Valid configuration

        // Locale may be invalid, perform check again with a lock to be sure
        UserPersonalization.LockTable();
        if not UserPersonalization.Get(UserSecurityId) then
            exit;
        if WindowsLanguage.Get(UserPersonalization."Locale ID") then
            exit;

        Session.LogMessage('00001UN', StrSubstNo(BadLocaleMsg, UserPersonalization."Locale ID", Language.GetDefaultApplicationLanguageId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InitialSetupCategoryTxt);

        UserPersonalization.Validate("Locale ID", Language.GetDefaultApplicationLanguageId);
        UserPersonalization.Modify(true);
    end;

    local procedure TryGetEmailFromSmtpSetup(): Text[80]
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        MailManagement: Codeunit "Mail Management";
        BccEmail: Text[80];
    begin
        if not (SMTPMailSetup.GetSetup and MailManagement.IsSMTPEnabled) then
            exit;

        if SMTPMailSetup.Authentication <> SMTPMailSetup.Authentication::Basic then
            exit;

        BccEmail := CopyStr(SMTPMailSetup."User ID", 1, MaxStrLen(BccEmail));

        if not MailManagement.CheckValidEmailAddress(BccEmail) then
            exit('');

        exit(BccEmail);
    end;

    local procedure TryGetEmailFromCurrentUser() BccEmail: Text[80]
    var
        User: Record User;
        MailManagement: Codeunit "Mail Management";
    begin
        if not User.Get(UserSecurityId) then
            exit;

        if User."Authentication Email" = '' then
            exit;

        if not MailManagement.CheckValidEmailAddress(User."Authentication Email") then
            exit;

        BccEmail := CopyStr(User."Authentication Email", 1, MaxStrLen(BccEmail));
    end;

    procedure NotifySetupComplete(SalesInvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SetupCompletedNotification: Notification;
        InvoiceRecordId: RecordID;
    begin
        SetupCompletedNotification.Id := CreateGuid;
        SetupCompletedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SetupCompletedNotification.SetData('SalesInvoiceNo', SalesInvoiceNo);
        SetupCompletedNotification.Message(SetupCompleteMsg);
        SetupCompletedNotification.AddAction(ViewInvoiceLbl, CODEUNIT::"O365 Sales Initial Setup", 'ViewInitialDraftInvoice');
        SetupCompletedNotification.AddAction(DeleteInvoiceLbl, CODEUNIT::"O365 Sales Initial Setup", 'RemoveInitialDraftInvoice');
        InvoiceRecordId := SalesHeader.RecordId;
        if SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceNo) then
            InvoiceRecordId := SalesHeader.RecordId;
        NotificationLifecycleMgt.SendNotification(SetupCompletedNotification, InvoiceRecordId);
    end;

    procedure ViewInitialDraftInvoice(SenderNotification: Notification)
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: Page "O365 Sales Invoice";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Invoice, SenderNotification.GetData('SalesInvoiceNo')) then begin
            Message(NoInvoiceMsg);
            exit;
        end;

        O365SalesInvoice.SetRecord(SalesHeader);
        O365SalesInvoice.SuppressExitPrompt;
        O365SalesInvoice.Run;
    end;

    procedure RemoveInitialDraftInvoice(SenderNotification: Notification)
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Invoice, SenderNotification.GetData('SalesInvoiceNo')) then begin
            Message(NoInvoiceMsg);
            exit;
        end;

        if Confirm(StrSubstNo(ConfirmInvoiceDeleteQst, SalesHeader."Sell-to Customer Name")) then
            SalesHeader.Delete(true);
    end;

    local procedure HasPermission(): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        ApplicationAreaSetup: Record "Application Area Setup";
        BankAccount: Record "Bank Account";
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        CustomReportLayout: Record "Custom Report Layout";
        CustomerTemplate: Record "Customer Template";
        CompanyInformation: Record "Company Information";
        GenJournalBatch: Record "Gen. Journal Batch";
        MarketingSetup: Record "Marketing Setup";
        MyNotifications: Record "My Notifications";
        O365EmailSetup: Record "O365 Email Setup";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentMethod: Record "Payment Method";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportSelections: Record "Report Selections";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxSetup: Record "Tax Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        exit(not (false in [
                            AccountingPeriod.WritePermission,
                            ApplicationAreaSetup.WritePermission,
                            BankAccount.WritePermission,
                            ConfigTemplateHeader.WritePermission,
                            ConfigTemplateLine.WritePermission,
                            CustomReportLayout.WritePermission,
                            CustomerTemplate.WritePermission,
                            CompanyInformation.WritePermission,
                            GenJournalBatch.WritePermission,
                            MarketingSetup.WritePermission,
                            MyNotifications.WritePermission,
                            O365EmailSetup.WritePermission,
                            O365SalesInitialSetup.WritePermission,
                            PaymentMethod.WritePermission,
                            PaymentRegistrationSetup.WritePermission,
                            ReportLayoutSelection.WritePermission,
                            ReportSelections.WritePermission,
                            SalesReceivablesSetup.WritePermission,
                            TaxArea.WritePermission,
                            TaxAreaLine.WritePermission,
                            TaxDetail.WritePermission,
                            TaxGroup.WritePermission,
                            TaxJurisdiction.WritePermission,
                            TaxSetup.WritePermission,
                            VATBusinessPostingGroup.WritePermission,
                            VATPostingSetup.WritePermission
                            ]
                  ));
    end;

    procedure CreateInvoice(Notification: Notification)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);

        PAGE.Run(PAGE::"O365 Sales Invoice", SalesHeader);
    end;

    local procedure IsNewCompany(): Boolean
    var
        GLRegister: Record "G/L Register";
        Customer: Record Customer;
        Item: Record Item;
    begin
        // Simple logic to determine if this is a new company
        if not GLRegister.IsEmpty then
            exit(false);

        if not Customer.IsEmpty then
            exit(false);

        if not Item.IsEmpty then
            exit(false);

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterCompanyOpen', '', false, false)]
    local procedure OnAfterCompanyOpen()
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        FinancialsCompanyName: Text;
    begin
        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Background then
            exit;

        if not EnvInfoProxy.IsInvoicing then
            exit;

        if GetCompany and Company."Evaluation Company" then
            exit;

        if CompanyInformationMgt.IsDemoCompany then
            exit;

        if not HasPermission then
            exit;

        Error(InvoicingNotSupportedErr);

        // Do not setup Invoicing App for financials users.
        if not IsNewCompany then
            if not (GetO365SalesInitialSetup and O365SalesInitialSetup."Is initialized") then begin
                FinancialsCompanyName := CompanyName;
                if GetCompany then
                    FinancialsCompanyName := Company."Display Name";
                Error(NotAnInvoicingCompanyErr, FinancialsCompanyName);
            end;

        if (not GetO365SalesInitialSetup) or
           ((not O365SalesInitialSetup."Is initialized") and (O365SalesInitialSetup."Sales Quote No. Series" = ''))
        then
            Error(OutOfDateCompanyErr); // User signed up for financials a long time ago and is now trying to use MS invoicing

        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");
    end;

    [EventSubscriber(ObjectType::Table, 79, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterCompanyInformationModify(var Rec: Record "Company Information"; var xRec: Record "Company Information"; RunTrigger: Boolean)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        DummyCustomer: Record Customer;
    begin
        if Rec.IsTemporary then
            exit;

        if (Rec."Country/Region Code" <> xRec."Country/Region Code") and (Rec."Country/Region Code" <> '') then
            if ConfigTemplateHeader.Get(O365SalesInitialSetup."Default Customer Template") then begin
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Field ID", DummyCustomer.FieldNo("Country/Region Code"));
                ConfigTemplateLine.DeleteAll();
                ConfigTemplateManagement.InsertConfigTemplateLine(ConfigTemplateHeader.Code,
                  DummyCustomer.FieldNo("Country/Region Code"), Rec."Country/Region Code", ConfigTemplateHeader."Table ID");
            end;
    end;

    local procedure EnableCompanyInvoicingApplicationArea()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CurrentExperienceTier: Text;
    begin
        if not (GetO365SalesInitialSetup and O365SalesInitialSetup."Is initialized") then
            exit;

        if GetCompany and Company."Evaluation Company" then
            exit;

        if ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName) then;
        if ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(CurrentExperienceTier) then;
        if not ApplicationAreaSetup.Invoicing or (CurrentExperienceTier <> ExperienceTierSetup.FieldCaption(Invoicing)) then
            ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Invoicing));
    end;

    local procedure ClearPaymentMethodsBalAccount()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Use for Invoicing", true);
        PaymentMethod.ModifyAll("Bal. Account No.", '');
    end;

    procedure EnsureConfigurationTemplatateSelectionRuleExists(TableId: Integer)
    var
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        ConfigTemplateHeader: Record "Config. Template Header";
        ExpectedCode: Code[10];
    begin
        ConfigTmplSelectionRules.SetRange("Table ID", TableId);
        if ConfigTmplSelectionRules.FindFirst then
            exit;

        if not GetO365SalesInitialSetup then
            exit;

        ConfigTmplSelectionRules.Validate("Table ID", TableId);

        case TableId of
            DATABASE::Item:
                begin
                    ConfigTmplSelectionRules.Validate("Page ID", PAGE::"Item Entity");
                    ExpectedCode := O365SalesInitialSetup."Default Item Template";
                end;
            DATABASE::Customer:
                begin
                    ConfigTmplSelectionRules.Validate("Page ID", PAGE::"Customer Entity");
                    ExpectedCode := O365SalesInitialSetup."Default Customer Template";
                end;
            else
                exit;
        end;

        if ExpectedCode = '' then
            exit;

        ConfigTemplateHeader.SetRange("Table ID", TableId);
        ConfigTemplateHeader.SetRange(Code, ExpectedCode);
        if not ConfigTemplateHeader.FindFirst then
            exit;

        ConfigTmplSelectionRules.Validate("Template Code", ExpectedCode);
        ConfigTmplSelectionRules.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnBeforePostSalesDoc', '', false, false)]
    local procedure BlockSendingTestInvoices(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.IsTest then
            Error(CannotSendTestInvoiceErr);
    end;

    [EventSubscriber(ObjectType::Page, 1518, 'OnAfterInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnAfterInitializingNotificationsDisable()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not GetO365SalesInitialSetup then
            exit;
        if not O365SalesInitialSetup."Is initialized" then
            exit;

        MyNotifications.SetRange("User Id", UserId);
        MyNotifications.ModifyAll(Enabled, false, true);
    end;

    local procedure GetCompany(): Boolean
    begin
        if not CompanyRead then
            CompanyRead := Company.Get(CompanyName);
        exit(CompanyRead);
    end;

    local procedure GetO365SalesInitialSetup(): Boolean
    begin
        if not O365SalesInitSetupRead then
            O365SalesInitSetupRead := O365SalesInitialSetup.Get();
        exit(O365SalesInitSetupRead);
    end;

    [EventSubscriber(ObjectType::Table, 1518, 'OnAfterIsNotificationEnabled', '', false, false)]
    local procedure DisableMyNotifications(NotificationId: Guid; var IsNotificationEnabled: Boolean)
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not EnvInfoProxy.IsInvoicing then
            exit;

        if not O365SalesInitialSetup.Get then
            exit;

        if not O365SalesInitialSetup."Is initialized" then
            exit;

        IsNotificationEnabled := false;
    end;
}

