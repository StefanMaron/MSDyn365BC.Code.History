codeunit 138947 "BC O365 No. Series Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Web] [NumberSeries]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,NumberSeriesModalPageHandler,NoSeriesConfirmationHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangingNextInvoiceNumber()
    var
        BCO365NoSeriesSettings: TestPage "BC O365 No. Series Settings";
        PostedInvoiceNo: Code[20];
        NextInvoiceNumber: Code[20];
        InitialEstimateNumber: Code[20];
    begin
        // [SCENARIO] Verify changing next invoice number updates future series correctly
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user changes number series for invoices
        BCO365NoSeriesSettings.OpenView;
        InitialEstimateNumber := BCO365NoSeriesSettings.NextEstimateNo.Value;
        NextInvoiceNumber := GetCodeWithADigit;
        LibraryVariableStorage.Enqueue(NextInvoiceNumber);
        BCO365NoSeriesSettings.NextInvoiceNo.AssistEdit;

        // [THEN] The new invoice number is reflected in setting
        Assert.AreEqual(BCO365NoSeriesSettings.NextInvoiceNo.Value, NextInvoiceNumber, 'Wrong invoice number displayed in settings');
        BCO365NoSeriesSettings.Close;

        // [WHEN] Invoice is sent
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The new invoice number in setting reflects the next number in invoice
        Assert.AreEqual(PostedInvoiceNo, NextInvoiceNumber, 'Wrong invoice number');

        // [WHEN] Next invoice is sent
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The no series is  incremented by one
        Assert.AreEqual(PostedInvoiceNo, IncStr(NextInvoiceNumber), 'Wrong invoice number');

        // [THEN] Estimate number is not affected
        BCO365NoSeriesSettings.OpenView;
        Assert.AreEqual(InitialEstimateNumber, BCO365NoSeriesSettings.NextEstimateNo.Value, 'Estimate number should be unchanged');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,NumberSeriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangingNextEstimateNumber()
    var
        BCO365NoSeriesSettings: TestPage "BC O365 No. Series Settings";
        EstimateNo: Code[20];
        NextEstimateNumber: Code[20];
        InitialInvoiceNumber: Code[20];
    begin
        // [SCENARIO] Verify changing next estimate number updates future series correctly
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user changes number series for estimates
        BCO365NoSeriesSettings.OpenView;
        InitialInvoiceNumber := BCO365NoSeriesSettings.NextInvoiceNo.Value;
        NextEstimateNumber := GetCodeWithADigit;
        LibraryVariableStorage.Enqueue(NextEstimateNumber);
        BCO365NoSeriesSettings.NextEstimateNo.AssistEdit;

        // [THEN] The new estimate number is reflected in setting
        Assert.AreEqual(BCO365NoSeriesSettings.NextEstimateNo.Value, NextEstimateNumber, 'Wrong estimate number displayed in settings');
        BCO365NoSeriesSettings.Close;

        // [WHEN] Estimate is created
        EstimateNo := LibraryInvoicingApp.CreateEstimate;

        // [THEN] The new estimate number in settings reflects the next number in estimate
        Assert.AreEqual(EstimateNo, NextEstimateNumber, 'Wrong estimate number');

        // [WHEN] Next estimate is sent
        EstimateNo := LibraryInvoicingApp.CreateEstimate;

        // [THEN] The no series is incremented by one
        Assert.AreEqual(EstimateNo, IncStr(NextEstimateNumber), 'Wrong estimate number');

        // [THEN] Invoice number is not affected
        BCO365NoSeriesSettings.OpenView;
        Assert.AreEqual(InitialInvoiceNumber, BCO365NoSeriesSettings.NextInvoiceNo.Value, 'Invoice number should be unchanged');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,NumberSeriesModalPageHandler,NoSeriesConfirmationHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangingInvoiceNumbersTwice()
    var
        BCO365NoSeriesSettings: TestPage "BC O365 No. Series Settings";
        PostedInvoiceNo: Code[20];
        NextInvoiceNumber: Code[20];
    begin
        // [SCENARIO] Verify changing invoice number multiple times is possible
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user changes number series for invoices twice
        BCO365NoSeriesSettings.OpenView;
        LibraryVariableStorage.Enqueue(GetCodeWithADigit);
        BCO365NoSeriesSettings.NextInvoiceNo.AssistEdit;
        NextInvoiceNumber := GetCodeWithADigit;
        LibraryVariableStorage.Enqueue(NextInvoiceNumber);
        BCO365NoSeriesSettings.NextInvoiceNo.AssistEdit;

        // [THEN] A new posted invoice has the latest number
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);
        Assert.AreEqual(PostedInvoiceNo, NextInvoiceNumber, 'Wrong invoice number');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,NumberSeriesModalPageHandler,NumberContainsNoNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidNumberSeries()
    var
        BCO365NoSeriesSettings: TestPage "BC O365 No. Series Settings";
        OriginalInvoiceNumber: Code[20];
        OriginalEstimateNumber: Code[20];
    begin
        // [SCENARIO] Verify the user is prevented from setting an invalid invoice/estimate number series
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [WHEN] The user changes invoice number series to an invalid one (i.e. with no digits)
        BCO365NoSeriesSettings.OpenView;
        OriginalInvoiceNumber := BCO365NoSeriesSettings.NextInvoiceNo.Value;
        OriginalEstimateNumber := BCO365NoSeriesSettings.NextEstimateNo.Value;
        LibraryVariableStorage.Enqueue(GetCodeWithNoDigits);

        // [THEN] A message informs the user that the number is not valid
        BCO365NoSeriesSettings.NextInvoiceNo.AssistEdit;

        // [WHEN] The user changes estimate number series to an invalid one (i.e. with no digits)
        LibraryVariableStorage.Enqueue(GetCodeWithNoDigits);

        // [THEN] A message informs the user that the number is not valid
        BCO365NoSeriesSettings.NextEstimateNo.AssistEdit;
        BCO365NoSeriesSettings.Close;

        // [THEN] The numbers shown in settings are unchanged
        BCO365NoSeriesSettings.OpenView;
        Assert.AreEqual(OriginalInvoiceNumber, BCO365NoSeriesSettings.NextInvoiceNo.Value, 'Invoice number should not have changed');
        Assert.AreEqual(OriginalEstimateNumber, BCO365NoSeriesSettings.NextEstimateNo.Value, 'Estimate number should not have changed');
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        EventSubscriberInvoicingApp.Clear;
        LibraryInvoicingApp.SetupEmail;

        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        WorkDate(Today);
        IsInitialized := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NumberSeriesModalPageHandler(var BCO365NoSeriesCard: TestPage "BC O365 No. Series Card")
    begin
        BCO365NoSeriesCard.NextNo.SetValue(LibraryVariableStorage.DequeueText);
        BCO365NoSeriesCard.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NumberContainsNoNumberMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual('The value in the Next number field must have a number so that we can assign the next number in the series.',
          Message, 'Unexpected message UI.');
        exit;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoSeriesConfirmationHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        exit;
    end;

    local procedure GetCodeWithADigit() ReturnCode: Code[15]
    begin
        ReturnCode := CopyStr(LibraryRandom.RandText(15), 1, MaxStrLen(ReturnCode));

        ReturnCode[LibraryRandom.RandIntInRange(1, 15)] :=
          LibraryRandom.RandIntInRange(48, 57); // ASCII value for characters '0','1',...,'9'
    end;

    local procedure GetCodeWithNoDigits() ReturnCode: Code[15]
    var
        RandomText: Text[50];
    begin
        RandomText := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(RandomText));
        RandomText := DelChr(RandomText, '=', '0123456789');

        ReturnCode := CopyStr(RandomText, 1, MaxStrLen(ReturnCode));
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

