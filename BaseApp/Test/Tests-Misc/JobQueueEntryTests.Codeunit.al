codeunit 139018 "Job Queue Entry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Job Queue Entry]
    end;

    var
        Assert: Codeunit Assert;
        WrongEndingDateErr: Label 'Wrong ending date and time calculated.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        NoErrorMessageMsg: Label 'There is no error message.';
        OnlyActiveCanBeMarkedErr: Label 'Only entries with the status In Progress can be marked as errors.';

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEntryCanBeRecurrent()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Job Queue Entry]
        with JobQueueEntry do begin
            Init();
            ID := CreateGuid();
            "Run in User Session" := false;
            "Object Type to Run" := "Object Type to Run"::Report;
            Validate("Run on Mondays", true);
            Insert();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryGetsRecurrentIfNextRunDateFormulaSet()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
        NextRunDateTime: DateTime;
    begin
        // [FEATURE] [Date Formula]
        Assert.IsTrue(Evaluate(DateFormula, '<CM>'), '<CM> is not evaluated as DateFormula');
        NextRunDateTime := CreateDateTime(CalcDate(DateFormula, Today), 0T);
        with JobQueueEntry do begin
            Init();
            Validate("Next Run Date Formula", DateFormula);

            TestField("Recurring Job");
            // [THEN] "Earliest Start Date/Time" is calculated as end of month
            TestField("Earliest Start Date/Time", NextRunDateTime);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryGetsNotRecurrentIfNextRunDateFormulaBlank()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
    begin
        // [FEATURE] [Date Formula]
        Clear(DateFormula);
        with JobQueueEntry do begin
            Init();
            "Recurring Job" := true;
            Validate("Next Run Date Formula", DateFormula);

            TestField("Recurring Job", false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryLostsDailyRecurringIfNextRunDateFormulaSet()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
    begin
        // [FEATURE] [Date Formula]
        Assert.IsTrue(Evaluate(DateFormula, '<CM>'), '<CM> is not evaluated as DateFormula');
        with JobQueueEntry do begin
            Init();
            Validate("Run on Mondays", true);
            Validate("Run on Tuesdays", true);
            Validate("Run on Wednesdays", true);
            Validate("Run on Thursdays", true);
            Validate("Run on Fridays", true);
            Validate("Run on Saturdays", true);
            Validate("Run on Sundays", true);

            Validate("Next Run Date Formula", DateFormula);

            TestField("Recurring Job");
            TestField("Run on Mondays", false);
            TestField("Run on Tuesdays", false);
            TestField("Run on Wednesdays", false);
            TestField("Run on Thursdays", false);
            TestField("Run on Fridays", false);
            TestField("Run on Saturdays", false);
            TestField("Run on Sundays", false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryLostsNextRunDateFormulaIfDailyRecurringSet()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
    begin
        // [FEATURE] [Date Formula]
        Assert.IsTrue(Evaluate(DateFormula, '<CM>'), '<CM> is not evaluated as DateFormula');
        with JobQueueEntry do begin
            Init();
            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Mondays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Mondays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Tuesdays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Tuesdays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Wednesdays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Wednesdays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Thursdays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Thursdays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Fridays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Fridays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Saturdays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Saturdays');

            Validate("Next Run Date Formula", DateFormula);
            Validate("Run on Sundays", true);
            TestField("Recurring Job");
            Assert.AreEqual('', Format("Next Run Date Formula"), 'Sundays');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EntryKeepsEarliestStartOnNextRunDateFormulaValidate()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
        ActualDateTime: DateTime;
    begin
        // [FEATURE] [Date Formula]
        Assert.IsTrue(Evaluate(DateFormula, '<CM>'), '<CM> is not evaluated as DateFormula');
        ActualDateTime := CurrentDateTime;
        with JobQueueEntry do begin
            Init();
            "Earliest Start Date/Time" := ActualDateTime;
            Validate("Next Run Date Formula", DateFormula);
            // [THEN] "Earliest Start Date/Time" is not changed
            TestField("Earliest Start Date/Time", ActualDateTime);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateTimeUT()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 159943] If "Ending Time" specified for Job Queue Entry is earlier than "Starting Time", then calculated ending date should be the day after starting date
        with JobQueueEntry do begin
            Init();
            ID := CreateGuid();
            "Recurring Job" := true;
            "Starting Time" := 180000T; // 18:00:00
            "Ending Time" := 001500T; // 00:15:00
        end;
        Assert.AreEqual(
          CreateDateTime(WorkDate() + 1, JobQueueEntry."Ending Time"),
          JobQueueEntry.GetEndingDateTime(CreateDateTime(WorkDate(), 0T)),
          WrongEndingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryCardShowsNoNotificationWhenStatusIsOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [GIVEN] An "On-Hold" Job Queue Entry
        with JobQueueEntry do begin
            ID := CreateGuid();
            "Starting Time" := DT2Time(CurrentDateTime - 1000 * 60 * 60);
            "Earliest Start Date/Time" := CurrentDateTime + 1000 * 60 * 10;
            Status := Status::"On Hold";
            "No. of Minutes between Runs" := 10;
        end;
        JobQueueEntry.Insert(false);

        // [WHEN] Opening the Job Queue Entry Card
        JobQueueEntryCard.Trap();
        PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);

        // [THEN] Card is opened on the correct record and no notification is triggered
        JobQueueEntryCard."No. of Minutes between Runs".AssertEquals(10);
        JobQueueEntryCard.Status.AssertEquals(JobQueueEntry.Status::"On Hold");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,JobQueueEntryCardPageHandler')]
    [Scope('OnPrem')]
    procedure JobQueueEntryCardShowsNotificationWhenStatusIsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryId: Guid;
    begin
        // [GIVEN] A "Ready" Job Queue Entry
        JobQueueEntryId := CreateGuid();
        with JobQueueEntry do begin
            ID := JobQueueEntryId;
            "Starting Time" := DT2Time(CurrentDateTime - 1000 * 60 * 60);
            "Earliest Start Date/Time" := CurrentDateTime + 1000 * 60 * 2;
            Status := Status::Ready;
            "No. of Minutes between Runs" := 2;
        end;
        JobQueueEntry.Insert(false);

        // [WHEN] Opening the Job Queue Entry Card
        LibraryVariableStorage.Enqueue(JobQueueEntryId);
        PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);

        // [THEN] A notification is triggered and handled in SendNotificatioNHandler
        // [THEN] The action on the notification sets the Status to "On Hold"
        JobQueueEntry.Get(JobQueueEntry.ID);
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorHandlerInsertsErrorLogEntryIfNoActiveLogs()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [Job Queue Error Handler]
        // [GIVEN] An Error "Err" happens
        BindSubscription(LibraryJobQueue);
        ExpectedErrorMessage := LibraryUtility.GenerateGUID();
        asserterror Error(ExpectedErrorMessage);

        // [GIVEN] Job Queue Entry "A", where Status "In Process"
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Insert(true);
        // [GIVEN] The Log Entry for "A", where Status is "Error"
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := JobQueueEntry.ID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry.Insert(true);

        // [WHEN] Run "Job Queue Error Handler"
        CODEUNIT.Run(CODEUNIT::"Job Queue Error Handler", JobQueueEntry);

        // [THEN] Job Queue Entry "A" got Status "Error", "Error Message" is "Err"
        // [THEN] A new Log entry added, where Status "Error", "Error Message" is "Err"
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.FindLast();
        VerifyErrorInJobQueueEntryAndLog(JobQueueEntry, JobQueueLogEntry, ExpectedErrorMessage);
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorHandlerMarksActiveLogEntryAsError()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [Job Queue Error Handler]
        // [GIVEN] An Error "Err" happens
        BindSubscription(LibraryJobQueue);
        ExpectedErrorMessage := LibraryUtility.GenerateGUID();
        asserterror Error(ExpectedErrorMessage);
        // [GIVEN] Job Queue Entry "A", where Status "In Process"
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Insert(true);
        // [GIVEN] Log Entry for "A", where Status "Error"
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := JobQueueEntry.ID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry.Insert(true);
        // [GIVEN] Log Entry "X" for "A", where Status "In Process"
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry.Insert(true);

        // [WHEN] Run "Job Queue Error Handler"
        CODEUNIT.Run(CODEUNIT::"Job Queue Error Handler", JobQueueEntry);

        // [THEN] Job Queue Entry "A" and Log entry "X" got Status "Error", "Error Message" is "Err"
        JobQueueLogEntry.Find();
        VerifyErrorInJobQueueEntryAndLog(JobQueueEntry, JobQueueLogEntry, ExpectedErrorMessage);
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarkActiveLogEntryAsError()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMessage: Text;
        ExpectedMarkerMessage: Text;
    begin
        // [FEATURE] [Job Queue Log Entry]
        // [GIVEN] The last error was "Err"
        ExpectedErrorMessage := LibraryUtility.GenerateGUID();
        asserterror Error(ExpectedErrorMessage);
        // [GIVEN] Job Queue Entry "A", where Status "In Process"
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Insert(true);
        // [GIVEN] Log Entry "X" for "A", where Status "In Process"
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := JobQueueEntry.ID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry.Insert(true);

        // [WHEN] Mark the Log entry as Error
        JobQueueLogEntry.MarkAsError();

        // [THEN] Job Queue Entry "A" and Log entry "X" got Status "Error", "Error Message" is 'Marked as Error by UserID.'
        JobQueueLogEntry.Find();
        ExpectedMarkerMessage := StrSubstNo('Marked as an error by %1.', UserId);
        VerifyErrorInJobQueueEntryAndLog(JobQueueEntry, JobQueueLogEntry, ExpectedMarkerMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarkActiveLogEntryAsErrorIfNoSourceEntry()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedMarkerMessage: Text;
    begin
        // [FEATURE] [Job Queue Log Entry]
        // [GIVEN] Log Entry, where Status "In Process", ID refers to not existing parent entry
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := CreateGuid();
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry.Insert(true);

        // [WHEN] Mark the Log entry as Error
        JobQueueLogEntry.MarkAsError();

        // [THEN] Log entry "X" got Status "Error", "Error Message" is 'Marked as Error by UserID.'
        JobQueueLogEntry.Find();
        ExpectedMarkerMessage := StrSubstNo('Marked as an error by %1.', UserId);
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Error);
        JobQueueLogEntry.TestField("Error Message", ExpectedMarkerMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarkInactiveLogEntryAsErrorShowsError()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // [FEATURE] [Job Queue Log Entry]
        // [GIVEN] Log Entry, where Status "Error"
        JobQueueLogEntry.Init();
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry.Insert(true);
        // [WHEN] Mark the Log entry as Error
        asserterror JobQueueLogEntry.MarkAsError();
        // [THEN] Error message: 'Only active entries can be marked as error.'
        Assert.ExpectedError(OnlyActiveCanBeMarkedErr);

        // [GIVEN] Log Entry, where Status "Success"
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Success;
        JobQueueLogEntry.Insert(true);
        // [WHEN] Mark the Log entry as Error
        asserterror JobQueueLogEntry.MarkAsError();
        // [THEN] Error message: 'Only active entries can be marked as error.'
        Assert.ExpectedError(OnlyActiveCanBeMarkedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DurationOnLogEntry()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedDuration: Duration;
        Duration100: Duration;
        ZeroDuration: Duration;
    begin
        // [FEATURE] [Job Queue Log Entry]
        Clear(ZeroDuration);
        Assert.AreEqual(ZeroDuration, JobQueueLogEntry.Duration(), 'should be zero if nothing is defined');

        JobQueueLogEntry."Start Date/Time" := CurrentDateTime;
        Assert.AreEqual(ZeroDuration, JobQueueLogEntry.Duration(), 'should be zero if end is not defined');

        JobQueueLogEntry."Start Date/Time" := 0DT;
        JobQueueLogEntry."End Date/Time" := CurrentDateTime;
        Assert.AreEqual(ZeroDuration, JobQueueLogEntry.Duration(), 'should be zero if start is not defined');

        Duration100 := 100;
        ExpectedDuration := 50;
        JobQueueLogEntry."Start Date/Time" := JobQueueLogEntry."End Date/Time" - ExpectedDuration;
        Assert.AreEqual(Duration100, JobQueueLogEntry.Duration(), 'should be rounded up from 50 to 100');

        ExpectedDuration := 49;
        JobQueueLogEntry."Start Date/Time" := JobQueueLogEntry."End Date/Time" - ExpectedDuration;
        Assert.AreEqual(ZeroDuration, JobQueueLogEntry.Duration(), 'should be rounded down from 49 to 0');
    end;

    [Test]
    [HandlerFunctions('LogErrorMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowNoErrorMessageIfNoErrorInLog()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // [FEATURE] [Job Queue Log Entry]
        JobQueueLogEntry."Error Message" := '';
        LibraryVariableStorage.Enqueue(NoErrorMessageMsg);
        JobQueueLogEntry.ShowErrorMessage();
        // Handled by LogErrorMessageHandler
    end;

    [Test]
    [HandlerFunctions('LogErrorMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowErrorMessageInLog()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [Job Queue Log Entry]
        ExpectedErrorMessage := LibraryUtility.GenerateGUID();
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry."Error Message" := CopyStr(ExpectedErrorMessage, 1, 2048);
        LibraryVariableStorage.Enqueue(ExpectedErrorMessage);
        JobQueueLogEntry.ShowErrorMessage();
        // Handled by LogErrorMessageHandler
    end;

    [Test]
    [HandlerFunctions('LogErrorMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowErrorCallStackInLog()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ExpectedErrorMessage: Text;
    begin
        // [FEATURE] [Job Queue Log Entry]
        ExpectedErrorMessage := LibraryUtility.GenerateGUID();
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
        JobQueueLogEntry.SetErrorCallStack(ExpectedErrorMessage);
        JobQueueLogEntry.Insert();
        LibraryVariableStorage.Enqueue(ExpectedErrorMessage);
        JobQueueLogEntry.ShowErrorCallStack();
        // Handled by LogErrorMessageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestartClearsNoOfAttempts()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 222577] TAB472.Restart - cleans up "No. of Attempts to Run"
        BindSubscription(LibraryJobQueue);
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry.Status::Error);

        JobQueueEntry.Restart();

        JobQueueEntry.Find();
        JobQueueEntry.TestField("No. of Attempts to Run", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetStatusFromErrorToReadyClearsNoOfAttempts()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 222577] TAB472.SetStatus(Status::Ready) - cleans up "No. of Attempts to Run" when old "Status" = "Status::Error"
        BindSubscription(LibraryJobQueue);
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry.Status::Error);

        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        JobQueueEntry.Find();
        JobQueueEntry.TestField("No. of Attempts to Run", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetStatusFromOnHoldToReadyClearsNoOfAttempts()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 222577] TAB472.SetStatus(Status::Ready) - cleans up "No. of Attempts to Run" when old "Status" = "Status::On Hold"
        BindSubscription(LibraryJobQueue);
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry.Status::"On Hold");

        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        JobQueueEntry.Find();
        JobQueueEntry.TestField("No. of Attempts to Run", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetStatusFromReadyToReadyDoesClearNoOfAttempts()
    var
        JobQueueEntry: Record "Job Queue Entry";
        OldNoOfAttempts: Integer;
    begin
        // [SCENARIO 222577] TAB472.SetStatus(Status::Ready) - keeps unchanged "No. of Attempts to Run" when old "Status" = "Status::Ready"
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry.Status::Ready);

        OldNoOfAttempts := JobQueueEntry."No. of Attempts to Run";
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        JobQueueEntry.Find();
        JobQueueEntry.TestField("No. of Attempts to Run", OldNoOfAttempts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSetStatusToOnHoldIfInstanceInactiveFor()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UserLoginTestLibrary: Codeunit "User Login Test Library";
        JobQueueManagement: Codeunit "Job Queue Management";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        // [SCENARIO] Check if the job queue entry status can be set to Hold in case last user login was too long ago

        // [GIVEN] Create active job queue entry
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry.Status::Ready);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := 1234;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify(true);

        // [GIVEN] This user has logged in 10 days ago
        UserLoginTestLibrary.UpdateUserLogin(UserSecurityId(), 0D, CreateDateTime(CalcDate('<-10D>'), 0T), 0DT);

        // [WHEN] Call the method to set job queue on hold if last login was 11 days ago
        JobQueueManagement.SetStatusToOnHoldIfInstanceInactiveFor(PeriodType::Day, 11,
          JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run");

        // [THEN] Job queue entry status is unchanged
        JobQueueEntry.Get(JobQueueEntry.ID);
        Assert.AreEqual(JobQueueEntry.Status::Ready, JobQueueEntry.Status, 'Job Queue entry status should have been "Ready" since the user logged in recently.');

        // [WHEN] Call the method to set job queue on hold if last login was 9 days ago
        JobQueueManagement.SetStatusToOnHoldIfInstanceInactiveFor(PeriodType::Day, 9,
          JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run");

        // [THEN] Job queue entry status is set to "On Hold"
        JobQueueEntry.Get(JobQueueEntry.ID);
        Assert.AreEqual(JobQueueEntry.Status::"On Hold", JobQueueEntry.Status, 'Job Queue entry status should have been "On Hold" since the user did not login recently.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryUserIsChangedOnScheduleTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        CustomUserId: Text[20];
    begin
        // [FEATURE] [User]
        // [SCENARIO 294844] User ID is changed on running ScheduleTask for JobQueueEntry

        // [GIVEN] User ID "U" not equal to the ID of User running the application
        CustomUserId := CopyStr(LibraryUtility.GenerateRandomXMLText(20), 1, 20);

        // [GIVEN] Job Queue Entry with User ID = "U"
        MockJobQueueEntryWithUserID(JobQueueEntry, CustomUserId);

        // [WHEN] Running SheduleTask on this Job Queue Entry
        BindSubscription(LibraryJobQueue);
        JobQueueEntry.ScheduleTask();

        // [THEN] Job Queue Entry User ID is changed
        JobQueueEntry.Find();
        JobQueueEntry.TestField("User ID", UserId);
    end;


    [Test]
    [HandlerFunctions('ConfirmationHandlerYes,NeutralMessageHandler')]
    [Scope('OnPrem')]
    procedure RunOnceInForeground()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntries: TestPage "Job queue entries";
    begin
        // [SCENARIO] The delegated admin wants to try out a job queue entry before handing it over to the end-user to activate it

        // [GIVEN] An existing job queue entry
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Customer - Top 10 List";
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := copystr(format(CreateGuid()), 1, MaxStrLen(JobQueueEntry.Description)); // so we can find the correct log entry afterwards
        JobQueueEntry.Insert(true);

        // [WHEN] The delegated admin clicks Run in foreground
        JobQueueEntries.OpenView();
        JobQueueEntries.GoToRecord(JobQueueEntry);
        JobQueueEntries.RunInForeground.Invoke(); // Displays a confirmation dialog (Y/N)
        JobQueueEntries.Close();

        // [THEN] The task has been copied and executed and a log entry exists. The original task is untouched.
        JobQueueEntry.Find(); // to make sure it still exists
        JobQueueLogEntry.SetRange(Description, JobQueueEntry.Description);
        JobQueueLogEntry.FindFirst();
        Assert.AreEqual(JobQueueEntry.Status::"On Hold", JobQueueEntry.Status, 'Status has changed.');
        Assert.AreEqual(JobQueueEntry."Object Type to Run", JobQueueLogEntry."Object Type to Run", 'Wrong object type to run');
        Assert.AreEqual(JobQueueEntry."Object ID to Run", JobQueueLogEntry."Object ID to Run", 'Wrong object type to run');
    end;

    [Test]
    procedure RunAsDelegatedAdminWithoutSettingUpWorkflow()
    var
        JobQueueEntry: Record "Job Queue Entry";
        AzureADUserTestLibrary: Codeunit "Azure AD User Test Library";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [SCENARIO] The delegated admin wants to set a job queue to ready without setting up the workflow

        // [GIVEN] Is Delegated admin
        BindSubscription(AzureADUserTestLibrary);
        AzureADUserTestLibrary.SetIsUserDelegatedAdmin(true);

        // [GIVEN] An existing job queue entry
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Customer - Top 10 List";
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := copystr(format(CreateGuid()), 1, MaxStrLen(JobQueueEntry.Description)); // so we can find the correct log entry afterwards
        JobQueueEntry.Insert(true);

        // [WHEN] The delegated admin clicks Run in foreground
        // [THEN] Error that the workflow has not been setup
        JobQueueEntryCard.OpenView();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);
        asserterror JobQueueEntryCard."Set Status to Ready".Invoke();
        Assert.ExpectedError('The Job Queue approval workflow has not been setup.');

        UnbindSubscription(AzureADUserTestLibrary);
    end;

    [Test]
    [HandlerFunctions('ApprovalRequestSentHandler')]
    procedure RunAsDelegatedAdmin()
    var
        AzureADUserTestLibrary: Codeunit "Azure AD User Test Library";
    begin
        // [SCENARIO] The delegated admin wants to set a job queue to ready without setting up the workflow

        // [GIVEN] Is Delegated admin
        BindSubscription(AzureADUserTestLibrary);
        AzureADUserTestLibrary.SetIsUserDelegatedAdmin(true);

        TestDelegatedJQ();

        UnbindSubscription(AzureADUserTestLibrary);
    end;

    [Test]
    [HandlerFunctions('ApprovalRequestSentHandler')]
    procedure RunAsDelegatedHelpdesk()
    var
        AzureADUserTestLibrary: Codeunit "Azure AD User Test Library";
    begin
        // [SCENARIO] The delegated helpdesk wants to set a job queue to ready without setting up the workflow

        // [GIVEN] Is Delegated admin
        BindSubscription(AzureADUserTestLibrary);
        AzureADUserTestLibrary.SetIsUserDelegatedHelpdesk(true);

        TestDelegatedJQ();

        UnbindSubscription(AzureADUserTestLibrary);
    end;

    local procedure TestDelegatedJQ()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        Workflow: Record Workflow;
        EmailAccount: Record "Email Account";
        ConnectorMock: Codeunit "Connector Mock";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        WorkflowSetup: Codeunit "Workflow Setup";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [GIVEN] An existing job queue entry
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Customer - Top 10 List";
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := copystr(format(CreateGuid()), 1, MaxStrLen(JobQueueEntry.Description)); // so we can find the correct log entry afterwards
        JobQueueEntry."User ID" := 'DA';
        JobQueueEntry.Insert(true);

        // [GIVEN] Setup JQ workflow
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.JobQueueEntryWorkflowCode());
        Workflow.Enabled := true;
        Workflow.Modify();

        // [GIVEN] Approval users setup
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(EmailAccount);

        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        UserSetup."E-Mail" := EmailAccount."Email Address";
        UserSetup.Modify();
        ApprovalEntry.DeleteAll();

        // [WHEN] The delegated admin clicks Run in foreground
        // [THEN] Error that the workflow has not been setup
        JobQueueEntryCard.OpenView();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);
        JobQueueEntryCard."Set Status to Ready".Invoke();
        JobQueueEntryCard.Close();

        // [THEN] Approval Entry is created with correct details
        Assert.RecordCount(ApprovalEntry, 1);
        ApprovalEntry.FindFirst();
        Assert.AreEqual(JobQueueEntry.RecordId(), ApprovalEntry."Record ID to Approve", 'Approval Entry created for wrong JQ');
        Assert.AreEqual(UserSetup."Approver ID", ApprovalEntry."Approver ID", 'Wrong Approver ID assigned to Approval Entry');
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; InitialStatus: Option)
    begin
        JobQueueEntry.Init();
        JobQueueEntry."No. of Attempts to Run" := 3;
        JobQueueEntry.Status := InitialStatus;
        JobQueueEntry.Insert(true);
    end;

    local procedure MockJobQueueEntryWithUserID(var JobQueueEntry: Record "Job Queue Entry"; NewUserID: Text[65])
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."User ID" := NewUserID;
        JobQueueEntry.Insert();
    end;

    local procedure VerifyErrorInJobQueueEntryAndLog(JobQueueEntry: Record "Job Queue Entry"; JobQueueLogEntry: Record "Job Queue Log Entry"; ExpectedErrorMessage: Text)
    begin
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Error);
        JobQueueLogEntry.TestField("Error Message", ExpectedErrorMessage);
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Error);
        JobQueueEntry.TestField("Error Message", ExpectedErrorMessage);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntryCardPageHandler(var JobQueueEntryCard: TestPage "Job Queue Entry Card")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure LogErrorMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NeutralMessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandlerYes(Question: Text[1024]; var Answer: Boolean);
    begin
        Answer := true;
    end;


    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueSendNotification: Codeunit "Job Queue - Send Notification";
        JobQueueEntryCard: Page "Job Queue Entry Card";
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Notification.GetData(JobQueueEntry.FieldName(ID)),
          'Notification contained wrong job queue entry ID');
        Assert.AreEqual(JobQueueEntryCard.GetChooseSetOnHoldMsg(), Notification.Message, 'Notification contained wrong message');
        JobQueueSendNotification.SetJobQueueEntryStatusToOnHold(Notification);
    end;

    [MessageHandler]
    procedure ApprovalRequestSentHandler(Message: Text[1024])
    begin
        Assert.IsSubstring('An approval request has been sent.', Message);
    end;
}

