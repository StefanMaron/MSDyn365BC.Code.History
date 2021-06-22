codeunit 134605 "Test Report Layout Selection"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('JobQueueEntriesHandler,ReportIsEmptyMsgHandler')]
    [Scope('OnPrem')]
    procedure TestReportInbox()
    var
        ReportInbox: Record "Report Inbox";
        OrderProcessorRoleCenter: TestPage "Order Processor Role Center";
    begin
        // Init
        ReportInbox.DeleteAll;
        ReportInbox."User ID" := UserId;
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := 134600;
        ReportInbox.Description := '134600';
        ReportInbox.Insert(true);

        // Execute
        OrderProcessorRoleCenter.OpenView;
        OrderProcessorRoleCenter.Control21.First;
        // Pre-validation
        Assert.AreEqual('134600', OrderProcessorRoleCenter.Control21.Description.Value, '');
        ReportInbox.Read := true;
        ReportInbox.Modify;

        // Read/Unread
        OrderProcessorRoleCenter.Control21.Unread.Invoke;
        Assert.IsFalse(OrderProcessorRoleCenter.Control21.First, '');
        OrderProcessorRoleCenter.Control21.All.Invoke;
        Assert.IsTrue(OrderProcessorRoleCenter.Control21.First, '');

        OrderProcessorRoleCenter.Control21.ShowQueue.Invoke; // Verify that it opens Job Queue Entries page.

        OrderProcessorRoleCenter.Control21.Show.Invoke;
        OrderProcessorRoleCenter.Control21.Description.DrillDown; // Save as Show

        OrderProcessorRoleCenter.Control21.Delete.Invoke;
        Assert.IsFalse(OrderProcessorRoleCenter.Control21.First, '');
    end;

    [Test]
    [HandlerFunctions('ReportIsEmptyMsgHandler')]
    [Scope('OnPrem')]
    procedure TestReportInboxTestPage()
    var
        ReportInbox: Record "Report Inbox";
        ReportInboxTestPage: TestPage "Report Inbox";
    begin
        // [FEATURE] [Report Inbox] [UI]
        // [SCENARIO 314312] Stan can download report from Report Inbox list page
        ReportInbox.DeleteAll;
        ReportInbox."User ID" := UserId;
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Report ID" := 134600;
        ReportInbox.Insert(true);

        ReportInboxTestPage.OpenView;

        Assert.AreEqual('Test Report - Default=Word', ReportInboxTestPage."Report Name".Value, '');

        ReportInboxTestPage."Report Name".DrillDown; // Save as Show
        ReportInboxTestPage.Close;
    end;

    [Test]
    [HandlerFunctions('Report134600ReportHandler,CustomLayoutHandler')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageOpen()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        ReportLayoutSelectionPage.OpenView;
        ReportLayoutSelectionPage.First;
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger, '');

        ReportLayoutSelection."Report ID" := 134602;
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        asserterror ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        ReportLayoutSelectionPage.Customizations.Invoke;
        ReportLayoutSelectionPage.RunReport.Invoke;

        ReportLayoutSelectionPage.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('CustomLayoutHandlerModal,NewLayoutHandlerModal')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageLineActions()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        ReportLayoutSelectionPage.OpenView;
        ReportLayoutSelectionPage.First;
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger, '');

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        // Execute. Opens modal pages.
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Custom Layout")); // Opens lookup
        Assert.AreEqual('Test', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');

        ReportLayoutSelectionPage.CustomLayoutDescription.Lookup; // lookup from description
        Assert.AreEqual('Test', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');

        ReportLayoutSelectionPage.CustomLayoutDescription.SetValue('built'); // finds closest match
        Assert.AreEqual('Copy of built-in', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');
    end;

    [Test]
    [HandlerFunctions('CustomLayoutHandlerModalCancel')]
    [Scope('OnPrem')]
    procedure TestReportLayoutPageLineActionsNegative()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        ReportLayoutSelectionPage: TestPage "Report Layout Selection";
    begin
        // Combined tests due to expensive initialization (>5 sec.)
        ReportLayoutSelectionPage.OpenView;
        ReportLayoutSelectionPage.First;
        Assert.AreNotEqual(0, ReportLayoutSelectionPage."Report ID".AsInteger, '');

        ReportLayoutSelection."Report ID" := 134600;
        ReportLayoutSelection.SetRange("Report ID", ReportLayoutSelection."Report ID");
        ReportLayoutSelection.DeleteAll;
        CustomReportLayout.SetRange("Report ID", ReportLayoutSelection."Report ID");
        CustomReportLayout.DeleteAll;
        ReportLayoutSelectionPage.GotoRecord(ReportLayoutSelection);

        // Execute. Opens modal pages.
        ReportLayoutSelectionPage.Type.SetValue(Format(ReportLayoutSelection.Type::"Custom Layout")); // Opens lookup
        Assert.AreEqual('', ReportLayoutSelectionPage.CustomLayoutDescription.Value, '');
    end;

    [Test]
    [HandlerFunctions('ServerPrinterPageHandler')]
    [Scope('OnPrem')]
    procedure TestPageServerPrinters()
    var
        ServerPrinters: Page "Server Printers";
    begin
        ServerPrinters.SetSelectedPrinterName('X');
        if ServerPrinters.RunModal = ACTION::OK then
            if ServerPrinters.GetSelectedPrinterName = '' then; // non-predictable in test environment
    end;

    [Test]
    [HandlerFunctions('DateTimeDialogHandler')]
    [Scope('OnPrem')]
    procedure TestDateTimeDialogFromJobQECard()
    var
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // Init
        JobQueueEntryCard.OpenNew;
        JobQueueEntryCard."Earliest Start Date/Time".Value := Format(CreateDateTime(22221212D, 121200T));

        // Execute
        JobQueueEntryCard."Earliest Start Date/Time".Lookup;

        // Validate
        Assert.AreEqual(
          Format(CreateDateTime(20110101D, 010100T)),
          Format(JobQueueEntryCard."Earliest Start Date/Time".AsDateTime),
          'Earlies start date/time');
    end;

    [Test]
    [HandlerFunctions('DateTimeDialogHandler')]
    [Scope('OnPrem')]
    procedure TestDateTimeDialogFromJobQECard2()
    var
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // Init
        JobQueueEntryCard.OpenNew;
        JobQueueEntryCard."Expiration Date/Time".Value := Format(CreateDateTime(22221212D, 121200T));

        // Execute
        JobQueueEntryCard."Expiration Date/Time".Lookup;

        // Validate
        Assert.AreEqual(
          Format(CreateDateTime(20110101D, 010100T)),
          Format(JobQueueEntryCard."Expiration Date/Time".AsDateTime),
          'Expiration date/time');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStartAndExpirationFromJobQE()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        BindSubscription(LibraryJobQueue);

        // Init;
        JobQueueEntry.Init;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20121212D, 121200T));

        // Execute + Validate
        JobQueueEntry.Validate("Earliest Start Date/Time", CreateDateTime(20110101D, 010100T));
        JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20120101D, 000000T));
        asserterror JobQueueEntry.Validate("Earliest Start Date/Time", CreateDateTime(20121212D, 121200T));
        asserterror JobQueueEntry.Validate("Expiration Date/Time", CreateDateTime(20100101D, 000000T));

        UnbindSubscription(LibraryJobQueue);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntriesHandler(var JobQueueEntries: TestPage "Job Queue Entries")
    begin
        JobQueueEntries.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReportIsEmptyMsgHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, 'empty') > 1, '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomLayoutHandler(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomLayoutHandlerModal(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.NewLayout.Invoke;
        CustomReportLayouts.Description.SetValue('Copy of built-in');
        CustomReportLayouts.CopyRec.Invoke;
        CustomReportLayouts.Description.SetValue('Test');
        CustomReportLayouts.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomLayoutHandlerModalCancel(var CustomReportLayouts: TestPage "Custom Report Layouts")
    begin
        CustomReportLayouts.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NewLayoutHandlerModal(var ReportLayoutLookup: TestPage "Report Layout Lookup")
    begin
        ReportLayoutLookup.AddRDLC.SetValue(true);
        ReportLayoutLookup.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure Report134600ReportHandler(var TestReportDefaultWord: Report "Test Report - Default=Word")
    begin
        Clear(TestReportDefaultWord);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServerPrinterPageHandler(var ServerPrinters: TestPage "Server Printers")
    begin
        ServerPrinters.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DateTimeDialogHandler(var DateTimeDialog: TestPage "Date-Time Dialog")
    begin
        // Validate initial values
        Assert.AreEqual(22221212D, DateTimeDialog.Date.AsDate, '');
        Assert.AreEqual(121200T, DateTimeDialog.Time.AsTime, '');

        // Execute new values
        DateTimeDialog.Date.Value := Format(20110101D);
        DateTimeDialog.Time.Value := Format(010100T);

        DateTimeDialog.OK.Invoke;
    end;
}

