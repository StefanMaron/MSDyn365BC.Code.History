codeunit 139502 "MS - PayPal Standard Inv Tests"
{
    Permissions = TableData 2000000199 = rimd;
    EventSubscriberInstance = Manual;
    Subtype = Test;

    var
        Assert: Codeunit 130000;
        LibrarySales: Codeunit 130509;
        LibraryUtility: Codeunit 131000;
        LibraryVariableStorage: Codeunit 131004;
        LibraryRandom: Codeunit 130440;
        LibraryInvoicingApp: Codeunit 132220;
        LibraryLowerPermissions: Codeunit 132217;
        MSPayPalStandardInvTests: Codeunit "MS - PayPal Standard Inv Tests";
        TypeHelper: Codeunit 10;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        DatasetFileName: Text;
        PayPalStandardNameTxt: Label 'PayPal Payments Standard';
        PayPalStandardDescriptionTxt: Label 'PayPal Payments Standard - Fee % of Amount';
        InvoiceSentMsg: Label 'Your invoice is being sent.';
        IsInitialized: Boolean;
        InvoiceTok: Label 'INV', Locked = true;
        PayPalCreatedByTok: Label 'PAYPAL.COM', Locked = true;
        PayPalSandboxCreatedByTok: Label 'SANDBOX.PAYPAL.COM', Locked = true;
        PayPalSandboxPrefixTok: Label 'sandbox.';
        CancelPostedInvoiceMsg: Label 'The invoice has been canceled and an email has been sent to the customer.';

    local procedure Initialize();
    var
        MSPayPalStandardAccount: Record 1070;
        SMTPMailSetup: Record 409;
        O365C2GraphEventSettings: Record 2162;
        WebhookSubscription: Record 2000000199;
        LibraryAzureKVMockMgmt: Codeunit 131021;
    begin
        LibraryVariableStorage.AssertEmpty();
        MSPayPalStandardAccount.DELETEALL(TRUE);
        WebhookSubscription.DELETEALL(TRUE);
        SMTPMailSetup.DELETEALL();
        APPLICATIONAREA('#Invoicing');
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');


        IF IsInitialized THEN
            EXIT;

        EnvironmentInfoTestLibrary.SetAppId(InvoiceTok);
        BindSubscription(EnvironmentInfoTestLibrary);
        BindSubscription(MSPayPalStandardInvTests);

        IF NOT O365C2GraphEventSettings.GET() THEN
            O365C2GraphEventSettings.INSERT(TRUE);

        O365C2GraphEventSettings.SetEventsEnabled(FALSE);
        O365C2GraphEventSettings.MODIFY();

        IsInitialized := TRUE;
    end;

    // [Test]
    procedure TestEnableDisablePaymentServiceE2E();
    begin
        // [GIVEN] A clean application
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        // [THEN] PayPal is not set up
        VerifyNoPaymentServiceExists();

        // [WHEN] The PayPal settings page is opened but no email is added
        SetupPayPalForInvoiceApp('');

        // [THEN] PayPal is disabled
        VerifyPaymentService(FALSE, FALSE);

        // [WHEN] An email is entered into the PayPal settings page
        SetupPayPalForInvoiceApp('test@microsoft.com');

        // [THEN] PayPal is enabled
        VerifyPaymentService(TRUE, TRUE);

        // [WHEN] The PayPal settings page is opened and the email is set back to nothing
        SetupPayPalForInvoiceApp('');

        // [THEN] PayPal is disabled
        VerifyPaymentService(FALSE, FALSE);

        // [WHEN] An email is again entered into the PayPal settings page
        SetupPayPalForInvoiceApp('test@microsoft.com');

        // [THEN] PayPal is enabled
        VerifyPaymentService(TRUE, TRUE);

        // [WHEN] The email in the PayPal settings page is changed once again
        SetupPayPalForInvoiceApp('anotherEmail@test.com');

        // [THEN] PayPal is enabled
        VerifyPaymentService(TRUE, TRUE);
    end;

    // [Test]
    procedure TestEnableWhenEnteringEmail();
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        // Execute
        SetupPayPalForInvoiceApp('test@microsoft.com');

        // Verify
        VerifyPaymentService(TRUE, TRUE);
    end;

    // [Test]
    [HandlerFunctions('SalesInvoiceReportRequestPageHandler,EmailDialogModalPageHandler,MessageHandler')]
    procedure TestSalesInvoiceReportSingleInvoice();
    var
        TempPaymentReportingArgument: Record 1062 temporary;
        PostedInvoiceNo: Code[20];
    begin
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();
        LibraryInvoicingApp.SetupEmail();

        // [GIVEN] PayPal has been set up
        SetupPayPalForInvoiceApp('test@microsoft.com');

        // [GIVEN] An invoice is being sent
        PostedInvoiceNo := CreateAndSendInvoice();
        MSPayPalStandardInvTests.VerifyBodyText(PostedInvoiceNo);

        // [WHEN] The posted invoice is being saved to XML
        SaveInvoiceToXML(TempPaymentReportingArgument, PostedInvoiceNo);

        // [THEN] The posted invoice contains a link to PayPal
        VerifyPaymentServiceIsInReportDataset(TempPaymentReportingArgument);
        VerifyPayPalURL(TempPaymentReportingArgument, PostedInvoiceNo);
    end;

    // [Test]
    [HandlerFunctions('MessageHandler,EmailDialogModalPageHandler,CancelInvoiceConfirmDialogHandler')]
    procedure TestCoverLetterPaymentLink();
    var
        SalesInvoiceHeader: Record 112;
        O365SalesCancelInvoice: Codeunit 2103;
        PostedInvoiceNo: Code[20];
    begin
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();
        LibraryInvoicingApp.SetupEmail();

        // [GIVEN] PayPal has been set up
        SetupPayPalForInvoiceApp('test@microsoft.com');

        // [WHEN] An invoice is being sent
        PostedInvoiceNo := CreateAndSendInvoice();

        // [THEN] The sent invoice email contains a link to PayPal
        MSPayPalStandardInvTests.VerifyBodyText(PostedInvoiceNo);

        // [WHEN] The invoice is canceled
        SalesInvoiceHeader.GET(PostedInvoiceNo);
        LibraryVariableStorage.Enqueue(CancelPostedInvoiceMsg);
        O365SalesCancelInvoice.CancelInvoice(SalesInvoiceHeader);

        // [THEN] The canceled invoice email does not contain a link to PayPal
        MSPayPalStandardInvTests.VerifyBodyTextDoesNotContainPayPal(PostedInvoiceNo);
    end;

    [Test]
    procedure TestTermsOfService();
    var
        MSPayPalStandardTemplate: Record 1071;
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();


        // Verify
        MSPayPalStandardTemplate.FINDFIRST();
        Assert.AreNotEqual('', MSPayPalStandardTemplate."Terms of Service", 'Terms of service are not set on the template');
    end;

    [Test]
    procedure TestWebhookIsCreatedWhenSettingupAccount();
    var
        WebhookSubscription: Record 2000000199;
        PayPalAccountID: Text[80];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        PayPalAccountID := 'test@microsoft.com';
        // Execute
        SetupPayPalForInvoiceApp(PayPalAccountID);

        WebhookSubscription.SETRANGE("Subscription ID", PayPalAccountID);
        WebhookSubscription.SETFILTER("Created By", STRSUBSTNO('*%1*', PayPalCreatedByTok));

        Assert.IsTrue(WebhookSubscription.FINDFIRST(), STRSUBSTNO('Error Expecting Webhook to be created for Account %1', PayPalAccountID));
    end;

    [Test]
    procedure TestWebhookIsCreatedAfterModifyingAccount();
    var
        WebhookSubscription: Record 2000000199;
        FirstPayPalAccountID: Text[80];
        SecondPayPalAccountID: Text[80];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        FirstPayPalAccountID := 'test@microsoft.com';
        SecondPayPalAccountID := 'test1@microsoft.com';

        // Execute
        SetupPayPalForInvoiceApp(FirstPayPalAccountID);
        SetupPayPalForInvoiceApp(SecondPayPalAccountID);

        WebhookSubscription.SETRANGE("Subscription ID", SecondPayPalAccountID);
        WebhookSubscription.SETFILTER("Created By", STRSUBSTNO('*%1*', PayPalCreatedByTok));

        Assert.IsTrue(
          WebhookSubscription.FINDFIRST(), STRSUBSTNO('Error Expecting Webhook to be created for Account %1', SecondPayPalAccountID));
    end;

    [Test]
    [HandlerFunctions('SandboxConfirmDialogHandler')]
    procedure TestWebhookSandboxPrefixAndEnableSandboxSetup();
    var
        WebhookSubscription: Record 2000000199;
        PayPalAccountID: Text[80];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        PayPalAccountID := PayPalSandboxPrefixTok + 'test@microsoft.com';
        LibraryVariableStorage.Enqueue(TRUE);

        // Execute
        SetupPayPalForInvoiceApp(PayPalAccountID);

        WebhookSubscription.SETRANGE("Subscription ID", PayPalAccountID);
        WebhookSubscription.SETFILTER("Created By", STRSUBSTNO('*%1*', PayPalSandboxCreatedByTok));

        Assert.IsTrue(
          WebhookSubscription.FINDFIRST(),
          STRSUBSTNO('Error Expecting Webhook with sandbox url to be created for Account %1', PayPalAccountID));
    end;

    [Test]
    [HandlerFunctions('SandboxConfirmDialogHandler')]
    procedure TestWebhookSandboxPrefixAndEnableNormalSetup();
    var
        WebhookSubscription: Record 2000000199;
        PayPalAccountID: Text[80];
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp();
        Initialize();

        PayPalAccountID := PayPalSandboxPrefixTok + 'test@microsoft.com';

        LibraryVariableStorage.Enqueue(FALSE);
        // Execute
        SetupPayPalForInvoiceApp(PayPalAccountID);

        WebhookSubscription.SETRANGE("Subscription ID", PayPalAccountID);
        WebhookSubscription.SETFILTER("Created By", STRSUBSTNO('*%1*', PayPalCreatedByTok));

        Assert.IsTrue(
          WebhookSubscription.FINDFIRST(), STRSUBSTNO('Error Expecting Webhook with normal url to be created for Account %1', PayPalAccountID));
    end;

    local procedure VerifyPaymentServiceIsInReportDataset(var PaymentReportingArgument: Record 1062);
    var
        XMLBuffer: Record 1235;
        ValueFound: Boolean;
    begin
        XMLBuffer.Load(DatasetFileName);
        XMLBuffer.SETRANGE(Name, 'PaymentServiceURL');
        XMLBuffer.FIND('-');

        ValueFound := FALSE;
        REPEAT
            ValueFound := COPYSTR(PaymentReportingArgument.GetTargetURL(), 1, 250) = XMLBuffer.Value
        UNTIL (XMLBuffer.NEXT() = 0) OR ValueFound;
        Assert.IsTrue(ValueFound, 'Cound not find target URL');
        XMLBuffer.SETRANGE(Name, 'PaymentServiceURLText');
        XMLBuffer.SETRANGE("Parent Entry No.", XMLBuffer."Parent Entry No.");
        XMLBuffer.FIND('-');
        Assert.AreEqual(PaymentReportingArgument."URL Caption", XMLBuffer.Value, '');
    end;

    local procedure VerifyPayPalURL(var PaymentReportingArgument: Record 1062; PostedInvoiceNo: Code[20]);
    var
        GeneralLedgerSetup: Record 98;
        MSPayPalStandardAccount: Record 1070;
        SalesInvoiceHeader: Record 112;
        TargetURL: Text;
        BaseURL: Text;
        AccountID: Text;
    begin
        SalesInvoiceHeader.GET(PostedInvoiceNo);
        TargetURL := PaymentReportingArgument.GetTargetURL();
        Assert.RecordCount(MSPayPalStandardAccount, 1);
        MSPayPalStandardAccount.FINDFIRST();
        BaseURL := MSPayPalStandardAccount.GetTargetURL();

        SalesInvoiceHeader.CALCFIELDS("Amount Including VAT");
        Assert.IsTrue(STRPOS(TargetURL, BaseURL) > 0, 'Base url was not set correctly');
        Assert.IsTrue(STRPOS(TargetURL, SalesInvoiceHeader."No.") > 0, 'Document No. was not set correctly');
        AccountID := MSPayPalStandardAccount."Account ID";
        Assert.IsTrue(STRPOS(TargetURL, TypeHelper.UrlEncode(AccountID)) > 0,
          'Account ID was not set correctly');
        Assert.IsTrue(STRPOS(TargetURL, FORMAT(SalesInvoiceHeader."Amount Including VAT", 0, 9)) > 0, 'Total amount was not set correctly');

        GeneralLedgerSetup.GET();
        Assert.IsTrue(
          STRPOS(TargetURL, GeneralLedgerSetup.GetCurrencyCode(SalesInvoiceHeader."Currency Code")) > 0,
          'Currency Code was not set correctly');
    end;

    procedure VerifyBodyText(PostedInvoiceNo: Code[20]);
    var
        SalesInvoiceHeader: Record 112;
        GeneralLedgerSetup: Record 98;
        MSPayPalStandardAccount: Record 1070;
        BodyHTMLText: Text;
        BaseURL: Text;
    begin
        SalesInvoiceHeader.GET(PostedInvoiceNo);
        Assert.RecordCount(MSPayPalStandardAccount, 1);
        MSPayPalStandardAccount.FINDFIRST();
        SalesInvoiceHeader.CALCFIELDS("Amount Including VAT");
        BodyHTMLText := LibraryVariableStorage.DequeueText();
        BaseURL := MSPayPalStandardAccount.GetTargetURL();
        TypeHelper.HtmlEncode(BaseURL);

        Assert.IsTrue(STRPOS(BodyHTMLText, BaseURL) > 0, 'Base url was not set correctly');
        Assert.IsTrue(STRPOS(BodyHTMLText, SalesInvoiceHeader."No.") > 0, 'Document No. was not set correctly');
        Assert.IsTrue(STRPOS(BodyHTMLText, MSPayPalStandardAccount."Account ID") > 0, 'Account ID was not set correctly');
        Assert.IsTrue(
          STRPOS(BodyHTMLText, FORMAT(SalesInvoiceHeader."Amount Including VAT", 0, 9)) > 0, 'Total amount was not set correctly');

        GeneralLedgerSetup.GET();
        Assert.IsTrue(
          STRPOS(BodyHTMLText, GeneralLedgerSetup.GetCurrencyCode(SalesInvoiceHeader."Currency Code")) > 0,
          'Currency Code was not set correctly');
    end;

    procedure VerifyBodyTextDoesNotContainPayPal(PostedInvoiceNo: Code[20]);
    var
        MSPayPalStandardAccount: Record 1070;
        BodyHTMLText: Text;
        BaseURL: Text;
    begin
        Assert.RecordCount(MSPayPalStandardAccount, 1);
        MSPayPalStandardAccount.FINDFIRST();
        BodyHTMLText := LibraryVariableStorage.DequeueText();
        BaseURL := MSPayPalStandardAccount.GetTargetURL();
        TypeHelper.HtmlEncode(BaseURL);

        Assert.IsTrue(STRPOS(BodyHTMLText, BaseURL) = 0, 'Base url was set');
    end;

    [RequestPageHandler]
    procedure SalesInvoiceReportRequestPageHandler(var SalesInvoice: TestRequestPage 206);
    var
        LibraryReportDataset: Codeunit 131007;
    begin
        DatasetFileName := LibraryReportDataset.GetFileName();
        SalesInvoice.SAVEASXML(LibraryReportDataset.GetParametersFileName(), DatasetFileName);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024]);
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    local procedure CreateAndSendInvoice() PostedInvoiceNo: Code[20];
    var
        SalesInvoiceHeader: Record 112;
        SalesHeader: Record 36;
        SalesLine: Record 37;
        O365SalesInvoice: TestPage 2110;
        O365SalesInvoiceLineCard: TestPage 2157;
        InvoiceNo: Code[20];
    begin
        O365SalesInvoice.OPENNEW();
        O365SalesInvoice."Sell-to Customer Name".VALUE(CreateCustomer('test@microsoft.com'));
        SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FINDLAST();

        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.VALIDATE(Type, SalesLine.Type::Item);
        SalesLine.MODIFY();

        O365SalesInvoiceLineCard.OPENEDIT();
        O365SalesInvoiceLineCard.GOTORECORD(SalesLine);
        O365SalesInvoiceLineCard.Description.VALUE(CreateItem());
        O365SalesInvoiceLineCard."Unit Price".SETVALUE(LibraryRandom.RandDec(100, 2));
        O365SalesInvoiceLineCard.CLOSE();

        InvoiceNo := SalesHeader."No.";

        LibraryVariableStorage.Enqueue(InvoiceSentMsg);
        O365SalesInvoice.Post.INVOKE();

        SalesInvoiceHeader.SETRANGE("Pre-Assigned No.", InvoiceNo);
        SalesInvoiceHeader.FINDLAST();
        PostedInvoiceNo := SalesInvoiceHeader."No.";
    end;

    local procedure CreateCustomer(Email: Text[80]) CustomerName: Text[50];
    var
        O365SalesCustomerCard: TestPage 2107;
    begin
        O365SalesCustomerCard.OPENNEW();
        CustomerName := LibraryUtility.GenerateGUID();
        O365SalesCustomerCard.Name.VALUE(CustomerName);
        O365SalesCustomerCard."E-Mail".VALUE(Email);
        O365SalesCustomerCard.CLOSE();
    end;

    local procedure CreateItem() ItemDescription: Text[50];
    var
        O365ItemCard: TestPage 2106;
    begin
        O365ItemCard.OPENNEW();
        ItemDescription := LibraryUtility.GenerateGUID();
        O365ItemCard.Description.VALUE(ItemDescription);
        O365ItemCard.CLOSE();
    end;

    local procedure SaveInvoiceToXML(var TempPaymentReportingArgument: Record 1062 temporary; PostedInvoiceNo: Code[20]);
    var
        TempPaymentServiceSetup: Record 1060 temporary;
        SalesInvoiceHeader: Record 112;
    begin
        SalesInvoiceHeader.GET(PostedInvoiceNo);
        TempPaymentServiceSetup.CreateReportingArgs(TempPaymentReportingArgument, SalesInvoiceHeader);
        SalesInvoiceHeader.SETRECFILTER();
        COMMIT();
        REPORT.RUNMODAL(REPORT::"Sales - Invoice", TRUE, FALSE, SalesInvoiceHeader);
    end;

    local procedure SetupPayPalForInvoiceApp(Email: Text[80]);
    var
        MSPayPalStandardSettings: TestPage 1074;
    begin
        MSPayPalStandardSettings.OPENEDIT();
        MSPayPalStandardSettings.AccountID.VALUE(Email);
        MSPayPalStandardSettings.CLOSE();
    end;

    local procedure VerifyPaymentService(IsEnabled: Boolean; AlwaysIncludeOnDocuments: Boolean);
    var
        ActualPaymentServiceSetup: Record 1060;
    begin
        ActualPaymentServiceSetup.DELETEALL();
        ActualPaymentServiceSetup.OnRegisterPaymentServices(ActualPaymentServiceSetup);
        Assert.RecordCount(ActualPaymentServiceSetup, 1);
        ActualPaymentServiceSetup.FINDFIRST();
        Assert.AreEqual(PayPalStandardNameTxt, ActualPaymentServiceSetup.Name, 'Wrong value set for Name');
        Assert.AreEqual(PayPalStandardDescriptionTxt, ActualPaymentServiceSetup.Description, 'Wrong value set for Description');
        Assert.AreEqual(IsEnabled, ActualPaymentServiceSetup.Enabled, 'Wrong value set for Enabled');
        Assert.AreEqual(
          AlwaysIncludeOnDocuments,
          ActualPaymentServiceSetup."Always Include on Documents",
          'Wrong value set for Always Include on Documents');
    end;

    local procedure VerifyNoPaymentServiceExists();
    var
        PaymentServiceSetup: Record 1060;
    begin
        PaymentServiceSetup.DELETEALL();
        PaymentServiceSetup.OnRegisterPaymentServices(PaymentServiceSetup);
        Assert.RecordIsEmpty(PaymentServiceSetup);
    end;

    [ModalPageHandler]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage 2150);
    begin
        O365SalesEmailDialog.OK().INVOKE();
    end;

    [EventSubscriber(ObjectType::Codeunit, 9520, 'OnBeforeDoSending', '', false, false)]
    procedure BlockEmailSendingEventSubscriber(var CancelSending: Boolean);
    begin
        CancelSending := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    procedure ManuallyRunJobQueueTask(var JobQueueEntry: Record 472; var DoNotScheduleTask: Boolean);
    begin
        IF DT2DATE(JobQueueEntry."Earliest Start Date/Time") = TODAY() THEN BEGIN
            JobQueueEntry.VALIDATE(Status, JobQueueEntry.Status::Ready);
            JobQueueEntry.MODIFY();
            CODEUNIT.RUN(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);
        END;

        DoNotScheduleTask := TRUE;
    end;

    [EventSubscriber(ObjectType::Codeunit, 260, 'OnBeforeSendEmail', '', false, false)]
    procedure SaveEmailContentBeforeSending(var TempEmailItem: Record "Email Item" temporary; IsFromPostedDoc: Boolean; PostedDocNo: Code[20]; HideDialog: Boolean; ReportUsage: Integer);
    begin
        LibraryVariableStorage.Enqueue(TempEmailItem.GetBodyText());
    end;

    [ConfirmHandler]
    procedure SandboxConfirmDialogHandler(Message: Text[1024]; var Reply: Boolean);
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    procedure CancelInvoiceConfirmDialogHandler(Message: Text[1024]; var Reply: Boolean);
    begin
        Reply := TRUE;
    end;
}

