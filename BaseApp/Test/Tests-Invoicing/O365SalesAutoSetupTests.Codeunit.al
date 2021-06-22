codeunit 138906 "O365 Sales Auto. Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Initial Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        OverrideDefaultsWithSalesSetupQst: Label 'We would like to update some configuration data but have detected some existing invoices. Would you like to update the configuration data anyway?';
        DefaultLbl: Label 'Default';
        DefaultCodeTxt: Label 'DEFAULT';
        DraftInvoiceLayoutTxt: Label 'MS-%1-BlueSimple', Comment = '%1 = report id';
        NotificationEnabledErr: Label 'Notification %1 is still enabled.';
        CouldNotFindLineErr: Label 'Could not find line for %1.', Comment = '%1 = property that could not be find';
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        TestMailTxt: Label 'test@mail.com';
        LibraryERM: Codeunit "Library - ERM";
        DefaultCityTxt: Label 'Default';
        InvoicingAppAreaMustBeEnabledErr: Label 'Invoicing application area must be enabled';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLRegister: Record "G/L Register";
        Customer: Record Customer;
        Item: Record Item;
        LibraryO365: Codeunit "Library - O365";
    begin
        // Clean up company
        SalesHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();
        GLRegister.DeleteAll();
        Customer.DeleteAll();
        Item.DeleteAll();

        // Remove setup if it exists
        if O365SalesInitialSetup.Get then
            O365SalesInitialSetup.Delete();

        LibraryO365.PopulateO365Setup;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestNoSetupIfAlreadyComplete()
    var
        O365SalesInitialSetupRec: Record "O365 Sales Initial Setup";
        O365SalesInitialSetup: Codeunit "O365 Sales Initial Setup";
    begin
        // Setup
        Initialize;
        O365SalesInitialSetup.HideConfirmDialog;
        O365SalesInitialSetup.Run;
        Clear(O365SalesInitialSetup);

        O365SalesInitialSetupRec.Get();
        Assert.IsTrue(O365SalesInitialSetupRec."Is initialized", 'Setup has not been initialised already');

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        O365SalesInitialSetupRec.Get();
        Assert.IsTrue(O365SalesInitialSetupRec."Is initialized", 'Setup has not been initialised already');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPromptIfDataAlreadyExists()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInitialSetupRec: Record "O365 Sales Initial Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize;
        LibrarySales.CreateSalesInvoice(SalesHeader);

        LibraryVariableStorage.Enqueue(OverrideDefaultsWithSalesSetupQst);
        LibraryVariableStorage.Enqueue(true);

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        O365SalesInitialSetupRec.Get();
        Assert.IsTrue(O365SalesInitialSetupRec."Is initialized", 'Setup has not been initialised already');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPromptIfDataAlreadyExistsReject()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInitialSetupRec: Record "O365 Sales Initial Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize;
        LibrarySales.CreateSalesInvoice(SalesHeader);

        LibraryVariableStorage.Enqueue(OverrideDefaultsWithSalesSetupQst);
        LibraryVariableStorage.Enqueue(false);

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        O365SalesInitialSetupRec.Get();
        Assert.IsTrue(O365SalesInitialSetupRec."Is initialized", 'Setup has not been initialised already');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSalesAndReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        // Setup
        Initialize;
        if SalesReceivablesSetup.Get then
            SalesReceivablesSetup.Delete();

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        Assert.IsTrue(SalesReceivablesSetup.Get, 'Sales & Receivables setup was not created');
        Assert.IsTrue(SalesReceivablesSetup."Default Item Quantity", 'Default item quantity not set');
        Assert.IsTrue(SalesReceivablesSetup."Create Item from Description", 'Create item from description not enabled');
        Assert.IsFalse(SalesReceivablesSetup."Stockout Warning", 'Stockout warnings have not been disabled');
        Assert.IsTrue(SalesReceivablesSetup."Calc. Inv. Discount", 'Calc. Inv. Discount not set');

        O365SalesInitialSetup.Get();
        Assert.AreEqual(
          O365SalesInitialSetup."Sales Invoice No. Series", SalesReceivablesSetup."Invoice Nos.", 'Invoice number series not set up');
        Assert.AreEqual(
          O365SalesInitialSetup."Posted Sales Inv. No. Series", SalesReceivablesSetup."Posted Invoice Nos.",
          'Posted invoice number series not set up');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestMarketingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 217158] Customer templates for person and company type must be defined in Marketing Setup
        Initialize;

        // [GIVEN] Marketin Setup record does not exist
        if MarketingSetup.Get then
            MarketingSetup.Delete();

        // [WHEN] Codeunit "O365 Sales Initial Setup" is being run
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [THEN] Marketing Setup record created
        MarketingSetup.Get();
        // [THEN] "Cust. Template Company Code" and "Cust. Template Person Code" field are filled in
        MarketingSetup.TestField("Cust. Template Company Code");
        MarketingSetup.TestField("Cust. Template Person Code");
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestPaymentRegistrationSetup()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        LibraryJournals: Codeunit "Library - Journals";
    begin
        // Setup
        Initialize;
        O365SalesInitialSetup.Get();

        if not GenJournalBatch.Get(O365SalesInitialSetup."Payment Reg. Template Name", O365SalesInitialSetup."Payment Reg. Batch Name") then begin
            LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
            O365SalesInitialSetup."Payment Reg. Template Name" := GenJournalBatch."Journal Template Name";
            O365SalesInitialSetup."Payment Reg. Batch Name" := GenJournalBatch.Name;
            O365SalesInitialSetup.Modify();
        end;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        Assert.IsTrue(PaymentRegistrationSetup.Get, 'A default payment registration setup does not exist');
        Assert.AreEqual(
          O365SalesInitialSetup."Payment Reg. Template Name", PaymentRegistrationSetup."Journal Template Name",
          'Template name not set correctly');
        Assert.AreEqual(
          O365SalesInitialSetup."Payment Reg. Batch Name", PaymentRegistrationSetup."Journal Batch Name", 'Batch name not set correctly');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestReportSelectionSetup()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportSelections: Record "Report Selections";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        // Setup
        Initialize;

        if not CustomReportLayout.Get(StrSubstNo(DraftInvoiceLayoutTxt, REPORT::"Standard Sales - Draft Invoice")) then begin
            CustomReportLayout.Init();
            CustomReportLayout."App ID" := CreateGuid;
            CustomReportLayout."Report ID" := REPORT::"Standard Sales - Draft Invoice";
            CustomReportLayout.Code := StrSubstNo(DraftInvoiceLayoutTxt, CustomReportLayout."Report ID");
            CustomReportLayout.Insert();
        end;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice Draft");
        Assert.IsFalse(ReportSelections.IsEmpty, 'No report selections were created');

        Assert.IsTrue(
          ReportLayoutSelection.Get(REPORT::"Standard Sales - Draft Invoice", CompanyName), 'Report layout selection was not created');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestNotificationsDisabled()
    var
        MyNotifications: Record "My Notifications";
    begin
        // Setup
        Initialize;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Assert
        MyNotifications.FindSet;
        repeat
            Assert.IsFalse(MyNotifications.Enabled, StrSubstNo(NotificationEnabledErr, MyNotifications.Name));
        until MyNotifications.Next = 0;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCustomerTemplateSetup()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        InStr: InStream;
        ConfigRule: Text;
    begin
        // Setup
        Initialize;
        O365SalesInitialSetup.Get();

        ConfigTemplateHeader.DeleteAll();
        ConfigTemplateLine.DeleteAll();
        ConfigTemplateHeader.Validate(Code, O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateHeader.Validate("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.Insert(true);

        if CompanyInformation.Get then begin
            LibraryERM.CreateCountryRegion(CountryRegion);
            CompanyInformation."Country/Region Code" := CountryRegion.Code;
            CompanyInformation.City := '';
            CompanyInformation.Modify();
        end;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        Assert.IsTrue(ConfigTemplateHeader.FindSet, 'There are no templates defined for the customer');
        repeat
            ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
            ConfigTemplateLine.SetRange("Field ID", Customer.FieldNo("Payment Method Code"));
            Assert.IsTrue(ConfigTemplateLine.FindFirst, StrSubstNo(CouldNotFindLineErr, Customer.FieldName("Payment Method Code")));
            Assert.AreEqual(O365SalesInitialSetup."Default Payment Method Code", ConfigTemplateLine."Default Value", '');

            ConfigTemplateLine.SetRange("Field ID", Customer.FieldNo("Payment Terms Code"));
            Assert.IsTrue(ConfigTemplateLine.FindFirst, StrSubstNo(CouldNotFindLineErr, Customer.FieldName("Payment Terms Code")));
            Assert.AreEqual(O365SalesInitialSetup."Default Payment Terms Code", ConfigTemplateLine."Default Value", '');

            ConfigTemplateLine.SetRange("Field ID", Customer.FieldNo("Tax Area Code"));
            Assert.IsTrue(ConfigTemplateLine.FindFirst, StrSubstNo(CouldNotFindLineErr, Customer.FieldName("Tax Area Code")));
            Assert.AreEqual(DefaultCodeTxt, ConfigTemplateLine."Default Value", '');

            ConfigTemplateLine.SetRange("Field ID", Customer.FieldNo("Country/Region Code"));
            Assert.IsTrue(ConfigTemplateLine.FindFirst, StrSubstNo(CouldNotFindLineErr, Customer.FieldName("Country/Region Code")));
            Assert.AreEqual(CountryRegion.Code, ConfigTemplateLine."Default Value", '');
        until ConfigTemplateHeader.Next = 0;

        ConfigTmplSelectionRules.SetRange("Table ID", DATABASE::Customer);
        ConfigTmplSelectionRules.FindFirst;

        Assert.AreEqual(1, ConfigTmplSelectionRules.Count, 'There should only be one selection rule for customers');
        ConfigTmplSelectionRules."Selection Criteria".CreateInStream(InStr);
        InStr.ReadText(ConfigRule);
        Assert.AreEqual('', ConfigRule, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCustomerContactTemplateSetup()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CompanyInformation: Record "Company Information";
        CustomerTemplate: Record "Customer Template";
    begin
        // Setup
        Initialize;
        CustomerTemplate.DeleteAll();

        if CompanyInformation.Get then begin
            CompanyInformation.City := '';
            CompanyInformation.Modify();
        end;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        Assert.IsTrue(ConfigTemplateHeader.FindFirst, 'There are no templates defined for the customer');
        Assert.IsFalse(CustomerTemplate.IsEmpty, 'No Customer templates have been created');

        CustomerTemplate.SetRange("Contact Type", CustomerTemplate."Contact Type"::Company);
        CustomerTemplate.FindFirst;
        VerifyCustomerTemplate(CustomerTemplate);

        CustomerTemplate.SetRange("Contact Type", CustomerTemplate."Contact Type"::Person);
        CustomerTemplate.FindFirst;
        VerifyCustomerTemplate(CustomerTemplate);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestItemTemplateSetup()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules";
        InStr: InStream;
        ConfigRule: Text;
    begin
        // Setup
        Initialize;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        Assert.IsTrue(ConfigTemplateHeader.IsEmpty, 'There are templates defined for items');

        ConfigTmplSelectionRules.SetRange("Table ID", DATABASE::Item);
        ConfigTmplSelectionRules.FindFirst;

        Assert.AreEqual(1, ConfigTmplSelectionRules.Count, 'There should only be one selection rule for customers');
        ConfigTmplSelectionRules."Selection Criteria".CreateInStream(InStr);
        InStr.ReadText(ConfigRule);
        Assert.AreEqual('', ConfigRule, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestTaxSetup()
    var
        TaxGroup: Record "Tax Group";
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        CompanyInformation: Record "Company Information";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
    begin
        // Setup
        Initialize;

        // Exercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        if CompanyInformation.Get and (CompanyInformation.City <> '') then begin
            TaxAreaCode := UpperCase(CopyStr(CompanyInformation.City, 1, MaxStrLen(TaxAreaCode) - 4));
            TaxJurisdictionCode := CopyStr(TaxAreaCode, 1, MaxStrLen(TaxJurisdictionCode));
            if CompanyInformation.County <> '' then // 2 char state
                TaxAreaCode := CopyStr(TaxAreaCode + ', ' + CopyStr(CompanyInformation.County, 1, 2), 1, MaxStrLen(TaxAreaCode));
        end else begin
            TaxAreaCode := DefaultLbl;
            TaxJurisdictionCode := DefaultCityTxt;
        end;

        Assert.IsTrue(TaxGroup.Get(TaxableCodeTxt), 'TaxGroup');
        Assert.IsTrue(TaxArea.Get(TaxAreaCode), 'TaxArea');
        Assert.IsTrue(TaxJurisdiction.Get(TaxJurisdictionCode), 'TaxJurisdiction');
        Assert.IsTrue(TaxAreaLine.Get(TaxArea.Code, TaxJurisdiction.Code), 'TaxAreaLine');

        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroup.Code);
        Assert.IsFalse(TaxDetail.IsEmpty, 'TaxDetail');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestIconsCreatedFromDemoData()
    var
        SalesDocumentIcon: Record "Sales Document Icon";
    begin
        // Setup
        Initialize;
        LibraryLowerPermissions.SetO365Setup;

        // Verify
        Assert.IsFalse(SalesDocumentIcon.IsEmpty, 'Sales Document icons were not created from demo data');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupMarkedAsCompleted()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        // Setup
        Initialize;
        O365SalesInitialSetup.Get();
        Assert.IsFalse(O365SalesInitialSetup."Is initialized", '');

        // Excercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        O365SalesInitialSetup.Get();
        Assert.IsTrue(O365SalesInitialSetup."Is initialized", '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestBccSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        O365EmailSetup: Record "O365 Email Setup";
        SMTPMail: Codeunit "SMTP Mail";
    begin
        // Setup
        Initialize;
        if SMTPMailSetup.Get then
            SMTPMailSetup.Delete();

        SMTPMail.ApplyOffice365Smtp(SMTPMailSetup);
        SMTPMailSetup."User ID" := TestMailTxt;
        SMTPMailSetup.Insert();

        // Excercise
        LibraryLowerPermissions.SetO365Setup;
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // Verify
        O365EmailSetup.SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, TestMailTxt);
        O365EmailSetup.SetRange(RecipientType, O365EmailSetup.RecipientType::BCC);
        Assert.IsTrue(O365EmailSetup.FindFirst, 'BCC rule was not created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBCJobQueueEntriesAreOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [GIVEN] A new company
        Initialize;

        // [WHEN] Invoicing initial setup runs on COD2110 for the first time
        CODEUNIT.Run(CODEUNIT::"O365 Sales Initial Setup");

        // [THEN] Any job queue entry that was created before (e.g. in COD2) is now set OnHold, except the ones useful for Invoicing
        if JobQueueEntry.FindSet then
            repeat
                Assert.AreEqual(JobQueueEntry.Status, JobQueueEntry.Status::"On Hold",
                  StrSubstNo('Job queue entry for %1 %2 is not On Hold for Invoicing, but it''s %3.',
                    JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run", JobQueueEntry.Status));
            until JobQueueEntry.Next = 0;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure InvoicingAppAreaEnabledOnInitializeO365Company()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        O365SalesInitialSetup: Codeunit "O365 Sales Initial Setup";
    begin
        // [SCENARIO 197381] Application area #Invoicing is enabled after initialization of O365 company
        Initialize;

        // [WHEN] O365 company is being initialized
        O365SalesInitialSetup.HideConfirmDialog;
        O365SalesInitialSetup.Run;

        // [THEN] #Invoicing is enabled for company's application area setup
        ApplicationAreaSetup.Get(CompanyName, '', '');
        Assert.IsTrue(ApplicationAreaSetup.Invoicing, InvoicingAppAreaMustBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure BlankPaymentMethodsBalAccount()
    var
        PaymentMethod: Record "Payment Method";
        O365SalesInitialSetup: Codeunit "O365 Sales Initial Setup";
    begin
        // [SCENARIO 203201] Bal. Account field should be blank for payment methods with Use for Invoicing after initialization of O365 company
        Initialize;

        // [GIVEN] Create new payment method with Bal. Account
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        PaymentMethod."Use for Invoicing" := true;
        PaymentMethod.Modify();

        // [WHEN] O365 company is being initialized
        O365SalesInitialSetup.HideConfirmDialog;
        O365SalesInitialSetup.Run;

        // [THEN] Bal. Account field is blank for payment methods with Use for Invoicing = Yes
        PaymentMethod.SetRange("Use for Invoicing", true);
        PaymentMethod.SetFilter("Bal. Account No.", '<>%1', '');
        Assert.RecordIsEmpty(PaymentMethod);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;

    local procedure VerifyCustomerTemplate(var CustomerTemplate: Record "Customer Template")
    begin
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("Customer Posting Group"));
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("Payment Terms Code"));
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("Country/Region Code"));
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("Payment Method Code"));
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("Gen. Bus. Posting Group"));
        AssertCustomerTemplateFieldMatchesTemplate(CustomerTemplate, CustomerTemplate.FieldNo("VAT Bus. Posting Group"));
    end;

    local procedure AssertCustomerTemplateFieldMatchesTemplate(var CustomerTemplate: Record "Customer Template"; FieldId: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(CustomerTemplate);
        FieldRef := RecRef.Field(FieldId);

        Assert.AreEqual(
          GetValueFromTemplate(FieldId), Format(FieldRef.Value),
          StrSubstNo('The field %1 does not match across both templates', FieldRef.Name));
    end;

    local procedure GetValueFromTemplate(FieldId: Integer): Text
    var
        ConfigTemplateLine: Record "Config. Template Line";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        O365SalesInitialSetup.Get();
        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateLine.SetRange("Field ID", FieldId);
        if not ConfigTemplateLine.FindFirst then
            exit('');

        exit(ConfigTemplateLine."Default Value");
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

