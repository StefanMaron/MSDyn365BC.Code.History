codeunit 138959 "O365 Sales Pulse Tests"
{
    Permissions = TableData "Calendar Event" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Calendar Event]
    end;

    var
        Assert: Codeunit Assert;
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        EstimateSentMsg: Label 'Estimate %1 is being sent.', Comment = '%1=The estimate number';
        EstimateAcceptedMsg: Label 'Estimate %1 was accepted.', Comment = '%1=The estimate number';
        EstimateExpiringMsg: Label 'There are expiring estimates.';
        EstimateExpiryTxt: Label 'Estimate Expiry';
        InvoiceEmailFailedMsg: Label 'Invoice %1 could not be sent.', Comment = '%1=The invoice number';
        EstimateEmailFailedMsg: Label 'Estimate %1 could not be sent.', Comment = '%1=The estimate number';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimateSentEvent_Immediate()
    var
        SalesHeader: Record "Sales Header";
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);

        // Execute
        SalesHeader.EmailRecords(false);

        // Assert event is created
        CalendarEvent.SetRange(Description, StrSubstNo(EstimateSentMsg, SalesHeader."No."));
        Assert.IsTrue(CalendarEvent.FindLast, '');
        Assert.AreEqual(Today, CalendarEvent."Scheduled Date", '');

        // Execute event
        CODEUNIT.Run(CODEUNIT::"Calendar Event Execution");

        // Assert event is completed
        CalendarEvent.FindLast;
        Assert.AreEqual(CalendarEvent.State::Completed, CalendarEvent.State, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimateAccepted_Immediate()
    var
        SalesHeader: Record "Sales Header";
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);

        // Execute
        SalesHeader.Validate("Quote Accepted", true);
        SalesHeader.Modify(true);

        // Assert event is created
        CalendarEvent.SetRange(Description, StrSubstNo(EstimateAcceptedMsg, SalesHeader."No."));
        Assert.IsTrue(CalendarEvent.FindLast, '');
        Assert.AreEqual(Today, CalendarEvent."Scheduled Date", '');

        // Execute event
        CODEUNIT.Run(CODEUNIT::"Calendar Event Execution");

        // Assert event is completed
        CalendarEvent.FindLast;
        Assert.AreEqual(CalendarEvent.State::Completed, CalendarEvent.State, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimateExpired_AfterCreation()
    var
        SalesHeader: Record "Sales Header";
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);
        SalesHeader."Quote Valid Until Date" := CalcDate('<1W>', Today);

        // Execute
        SalesHeader.Modify(true);

        // Assert
        CalendarEvent.SetRange(Description, EstimateExpiringMsg);
        Assert.IsTrue(CalendarEvent.FindLast, '');
        Assert.AreEqual(CalcDate('<WD1>', Today), CalendarEvent."Scheduled Date", '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimateExpired_AfterModify()
    var
        SalesHeader: Record "Sales Header";
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);

        // Execute
        SalesHeader."Quote Valid Until Date" := CalcDate('<1W>', Today);
        SalesHeader.Modify(true);
        SalesHeader."Quote Valid Until Date" := Today;
        SalesHeader.Modify(true);

        // Assert
        CalendarEvent.SetRange(Description, EstimateExpiringMsg);
        Assert.IsFalse(CalendarEvent.FindLast, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimateExpired_AfterDelete()
    var
        SalesHeader: Record "Sales Header";
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);
        SalesHeader."Quote Valid Until Date" := CalcDate('<1W>', Today);

        // Execute
        SalesHeader.Modify(true);
        SalesHeader.Delete(true);

        // Assert
        CalendarEvent.SetRange(Description, EstimateExpiringMsg);
        Assert.IsFalse(CalendarEvent.FindLast, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEstimatedExpired_Forced()
    var
        SalesHeader: Record "Sales Header";
        ActivityLog: Record "Activity Log";
        O365SalesWebService: Codeunit "O365 Sales Web Service";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Setup
        Initialize(false);
        LibraryLowerPermissions.SetInvoiceApp;

        CreateQuote(SalesHeader);
        SalesHeader."Quote Valid Until Date" := CalcDate('<2D>', Today);
        SalesHeader.Modify();

        // Execute
        O365SalesWebService.SendEstimateExpiryEvent;

        // Assert
        ActivityLog.SetRange(Context, EstimateExpiryTxt);
        Assert.IsTrue(ActivityLog.FindFirst, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,EmailConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateFailedToSendEvent()
    var
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        EstimateCode: Code[20];
    begin
        // Setup
        Initialize(true);
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        EstimateCode := LibraryInvoicingApp.CreateEstimate;
        LibraryInvoicingApp.SendEstimate(EstimateCode);

        // Assert event is created
        CalendarEvent.SetRange(Description, StrSubstNo(EstimateEmailFailedMsg, EstimateCode));
        Assert.AreEqual(CalendarEvent.Count, 1, 'Wrong number of calendar events.');
        CalendarEvent.FindFirst;
        Assert.AreEqual(Today, CalendarEvent."Scheduled Date", '');

        // Execute event
        CODEUNIT.Run(CODEUNIT::"Calendar Event Execution");

        // Assert event is completed
        CalendarEvent.FindLast;
        Assert.AreEqual(CalendarEvent.State::Completed, CalendarEvent.State, '');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceFailedToSendEvent()
    var
        CalendarEvent: Record "Calendar Event";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InvoiceCode: Code[20];
    begin
        // Setup
        Initialize(true);
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        InvoiceCode := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // Assert event is created
        CalendarEvent.SetRange(Description, StrSubstNo(InvoiceEmailFailedMsg, InvoiceCode));
        Assert.AreEqual(CalendarEvent.Count, 1, 'Wrong number of calendar events.');
        CalendarEvent.FindFirst;
        Assert.AreEqual(Today, CalendarEvent."Scheduled Date", '');

        // Execute event
        CODEUNIT.Run(CODEUNIT::"Calendar Event Execution");

        // Assert event is completed
        CalendarEvent.FindLast;
        Assert.AreEqual(CalendarEvent.State::Completed, CalendarEvent.State, '');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure CreateQuote(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."E-Mail" := 'test@microsoft.com';
        Customer.Modify();

        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");
    end;

    local procedure Initialize(AllowEmailFailing: Boolean)
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        O365SalesEvent: Record "O365 Sales Event";
        CalendarEvent: Record "Calendar Event";
        ActivityLog: Record "Activity Log";
        SalesHeader: Record "Sales Header";
    begin
        CalendarEvent.DeleteAll();
        ActivityLog.DeleteAll();
        O365SalesEvent.DeleteAll();
        SalesHeader.DeleteAll(true);

        if AllowEmailFailing then begin
            // For some tests we need to fail the email sending,
            // but running all the job queue entries causes problems for pulse events
            EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);
            EventSubscriberInvoicingApp.SetAlwaysRunCodeunitNo(CODEUNIT::"Document-Mailing");
            EventSubscriberInvoicingApp.OverrideJobQueueResult(false);
        end else
            EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(true);
        O365C2GraphEventSettings.Modify(true);

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);
        IsInitialized := true;

        if not O365SalesInitialSetup.Get then
            O365SalesInitialSetup.Insert();

        O365SalesInitialSetup."C2Graph Endpoint" := '127.0.0.1:8081/c2graph/status200/;{USER}=test;{PASSWORD}=test';
        O365SalesInitialSetup.Modify();

        SetupSMTP;
    end;

    local procedure SetupSMTP()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        SMTPMailSetup.DeleteAll();
        SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := '127.0.0.1';
        SMTPMailSetup."SMTP Server Port" := 8081;
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'TestUser';
        SMTPMailSetup.SetPassword('TestPassword');
        SMTPMailSetup.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure EmailConfirmMessageHandler(Text: Text[1024])
    begin
        Assert.AreNotEqual(
          0,
          StrPos(Text, 'Your invoice is being sent.') + StrPos(Text, 'Your estimate is being sent.'),
          'Unexpected message'
          );
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

