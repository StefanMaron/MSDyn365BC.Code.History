codeunit 139026 "Test Job Queue"
{
    // 
    // NOTE: Test Execution
    //   In NAV7, TestIsolation does not support Background Sessions. These tests therefore
    //   fail fast when TestIsolation is enabled. Note that TestIsolation is enabled in SNAP so these
    //   tests cannot be run in SNAP.
    //   How to run these tests in the lab: use the Gate tool.
    //   How to run these tests in your development box:
    //     1. Set the TestIsolation property to Disabled for the Test Runner COD130020, recompile it and use it
    //     through the Test Tool PAG130021.
    //     2. Alternatively, run codeunit directly from CSIDE or run command ALTest runtests /runner:130202 139026.
    // NOTE: Database Rollback
    //   Our Database rollback mechanisms do not support transactions coming from Background Sessions. Running these
    //   tests therefore leaves the database in an unknown state where some tables will be out of sync with others.
    //   This easily impacts other tests and creates failures which are difficult to debug. The C# wrappers which
    //   are used to run these tests have therefore been placed in a separate C# project in file "BackgroundSessionTests.cs"
    //   so that they are isolated and run with a clean database without impacting other tests.
    // NOTE: Checking in changes to this codeunit
    //   This codeunit has been tagged with the "UNSAFE" keyword in the VersionList: the command ALTest CSWRAP
    //   ignores test codeunits with this keyword and does not generate C# wrappers in GeneratedTests.cs. When you
    //   add\remove\update test functions in this codeunit, you need to manually created\update the C# wrappers
    //   in BackgroundSessionTests.cs.
    // NOTE: Execution Parallelization
    //   The assumption is that Tests in this Codeunit are NOT run in parallel on the same Service Instance
    //   and are NOT distributed across multiple Service Instances. This may have unpredictable results due to the
    //   nature of the Job Queue.
    // NOTE: Background Session Cleanup
    //   Tests are intentionally structured in such a way that they attempt to clean up Background Sessions
    //   before performing validation. This is important to ensure reliability and repeatability of tests.

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue]
    end;

    var
        TimeoutErr: Label 'Timeout exceeded. %1.', Comment = '%1 is the reason why the timeout was exceeded, or any additional data needed to debug a timeout issue.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueUserSessionTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        Initialize();

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue CAL Error Sample";
        JobQueueEntry."Job Queue Category Code" := 'TEST';

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;

        WaitForJobEntryStatus(JobQueueEntryID);

        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueSameCategory()
    var
        JobQueueEntry: Record "Job Queue Entry";
        i: Integer;
        NoOfRemainingJobs: Integer;
    begin
        Initialize();

        for i := 1 to 3 do begin
            JobQueueEntry.Init();
            Clear(JobQueueEntry.ID);
            Clear(JobQueueEntry."System Task ID");
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Sleeping Sample"; // sleeps 10s
            JobQueueEntry."Job Queue Category Code" := 'TEST';
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
            Commit();
            Sleep(1000); // allow a small interval between jobs
        end;
        Commit();
        i := 0;
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Job Queue Sleeping Sample");
        repeat
            Sleep(2000);
            NoOfRemainingJobs := JobQueueEntry.Count();
            JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
            Assert.IsTrue(JobQueueEntry.Count <= 1, 'More than one task runs at the same time');
            JobQueueEntry.SetRange(Status);
            i += 1;
        until (NoOfRemainingJobs = 0) or (i > 100);
        Assert.AreEqual(0, NoOfRemainingJobs, 'Not all jobs finished');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryShowRelatedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Customer: Record Customer;
        CustomerLookup: TestPage "Customer Lookup";
        RecRef: RecordRef;
    begin
        Initialize();

        JobQueueEntry.LookupRecordToProcess(); // Does nothing, just returns.
        JobQueueEntry.ID := CreateGuid();
        asserterror JobQueueEntry.LookupRecordToProcess();
        Customer.Init();
        Customer.Insert(true);
        RecRef.GetTable(Customer);
        JobQueueEntry."Record ID to Process" := RecRef.RecordId;
        CustomerLookup.Trap();
        JobQueueEntry.LookupRecordToProcess();
        CustomerLookup.Close();
        Customer.Delete();
        asserterror JobQueueEntry.LookupRecordToProcess();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateEmptyJobQueueCategoryTest()
    var
        JobQueueCategoryList: TestPage "Job Queue Category List";
    begin
        JobQueueCategoryList.OpenNew();
        asserterror JobQueueCategoryList.Code.Value := '';
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GracefullDotNetErrorHandlingTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();

        CreateJobQueueEntry(
          JobQueueEntry,
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Job Queue Exception Sample",
          JobQueueEntry.Status::Ready);
        JobQueueEntryID := JobQueueEntry.ID;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        WaitForJobEntryStatus(JobQueueEntryID);

        with JobQueueLogEntry do begin
            SetRange(ID, JobQueueEntryID);

            Assert.IsTrue(FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
            Assert.AreEqual(Status::Error, Status, 'Unexpected status in the log');
            ErrorMsg := "Error Message";
            Assert.IsTrue(StrPos(ErrorMsg, 'System.Xml.XmlTextReader.Create') > 0, CopyStr('Unexpected error message:' + ErrorMsg, 1, 1024));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryOutdatedStart()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryLogFound: Boolean;
        Baseline: DateTime;
        StartingTime: Time;
        EndingTime: Time;
        Duration: Integer;
        EarliestStartingDateTime: DateTime;
        NextDay: Boolean;
    begin
        Initialize();

        Duration := 1;
        Baseline := RoundDateTime(CurrentDateTime, 1000, '>'); // Rounds to nearest second avoiding milisecond comparison failures.
        EarliestStartingDateTime := Baseline;
        StartingTime := DT2Time(Baseline) + 3 * 60 * 60 * 1000; // Sets to 3h from now.
        EndingTime := StartingTime + 1 * 60 * 60 * 1000;
        // We can meet case when StartingTime set to next day's (Baseline between 21-00 and 24-00). In this case next start date must be next day.
        NextDay := (DT2Time(Baseline) >= 210000T);

        // Test that when the Job Queue Entry is marked as Ready, the Earliest Start DateTime is automatically
        // adjusted to the next possible DateTime based on the Start\End Time boundaries.
        CreateTimeBasedRecurringJobQueueEntry(
          JobQueueEntry,
          StartingTime,
          EndingTime,
          Duration,
          EarliestStartingDateTime,
          JobQueueEntry.Status::Ready);
        Assert.AreEqual(
          StartingTime,
          DT2Time(JobQueueEntry."Earliest Start Date/Time"),
          StrSubstNo(
            'Earliest Start time should be set to that of StartingTime for baseline: %1',
            Baseline));
        if NextDay then
            Assert.AreEqual(DT2Date(Baseline) + 1, DT2Date(JobQueueEntry."Earliest Start Date/Time"),
              StrSubstNo(
                'Earliest Start date should be tomorrow for baseline: %1',
                Baseline))
        else
            Assert.AreEqual(DT2Date(Baseline), DT2Date(JobQueueEntry."Earliest Start Date/Time"),
              StrSubstNo(
                'Earliest Start date should be today for baseline: %1',
                Baseline));

        Assert.AreEqual(false, JobQueueEntryLogFound, 'Job Queue Entry should not be run');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesDaily()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Daily in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Daily);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", true, 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesWeekly()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Weekly in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Weekly);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", true, 7 * 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesNever()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue when reset Prepmt. Auto Update Frequency to Never in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Daily);
        SalesReceivablesSetup.Modify(true);
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Never);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesDaily()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Daily in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Daily);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", true, 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesWeekly()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Weekly in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Weekly);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", true, 7 * 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesNever()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue when reset Prepmt. Auto Update Frequency to Never in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Daily);
        PurchasesPayablesSetup.Modify(true);
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Never);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryRunConfirm()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UT] [Confirm Dialog] [GUIALLOWED]
        // [SCENARIO 273067] Schedule Job Queue running codeunit with CONFIRM dialog which is not wrapped with GUIALLOWED
        Initialize();

        // [GIVEN] Job Queue Entry running codeunit with CONFIRM dialog
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Confirm";
        JobQueueEntry."Job Queue Category Code" := 'TEST';
        // [WHEN] Job Queue Entry run
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;
        WaitForJobEntryStatus(JobQueueEntryID);
        // [THEN] Job Queue failed, Status = Error
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryRunConfirmWithGuiallowed()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UT] [Confirm Dialog] [GUIALLOWED]
        // [SCENARIO 273067] Schedule Job Queue running codeunit with CONFIRM dialog which is wrapped with GUIALLOWED
        Initialize();

        // [GIVEN] Job Queue Entry running codeunit with CONFIRM dialog wrapped with GUIALLOWED
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Confirm Guiallowed";
        JobQueueEntry."Job Queue Category Code" := 'TEST';
        // [WHEN] Job Queue Entry run
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;
        WaitForJobEntryStatus(JobQueueEntryID);
        // [THEN] Job Queue successful, Status = Success
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Success, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMinutesValidationResetsRecurringProperly()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 400333] When user validates "No. of Minutes between Runs" after setting "Next Run Date Formula" the Recurring Job is False
        Initialize();

        // [GIVEN] A Job Queue Entry
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"Job Queue Exception Sample", JobQueueEntry.Status::"On Hold");

        // [GIVEN] Next Run Date Formula was set
        Evaluate(JobQueueEntry."Next Run Date Formula", '1D');
        JobQueueEntry.Validate("Next Run Date Formula");

        // [WHEN] Set "No. of Minutes between Runs" to 60
        JobQueueEntry.Validate("No. of Minutes between Runs", LibraryRandom.RandIntInRange(50, 200));

        // [THEN] "Recurring Job" is false
        JobQueueEntry.TestField("Recurring Job", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntriesPageStaleJob()
    var
        JobQueueEntries: TestPage "Job Queue Entries";
        JobQueueEntry: Record "Job Queue Entry";
        FirstJQId: Guid;
        SecondJQId: Guid;
    begin
        // [Scenario] Given stale (in process) jobs, when the page opens, it should update the stale jobs to error state

        // [Given] Stale job queues
        CreateJobQueueEntry(JobQueueEntry, 0, 0, JobQueueEntry.Status::"In Process");
        FirstJQId := JobQueueEntry.ID;

        CreateJobQueueEntry(JobQueueEntry, 0, 0, JobQueueEntry.Status::"In Process");
        SecondJQId := JobQueueEntry.ID;

        // [When] Open JQE list page
        JobQueueEntries.OpenView();

        // [Then] Job queues should be in error state
        JobQueueEntries.GoToKey(FirstJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntries.Status, 'The first job queue is not in error state.');
        JobQueueEntries.GoToKey(SecondJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntries.Status, 'The second job queue is not in error state.');
        JobQueueEntries.Close();

        JobQueueEntry.Get(FirstJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'The first job queue is not in error state.');
        JobQueueEntry.Get(SecondJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'The second job queue is not in error state.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueLogEntriesPageStaleJob()
    var
        JobQueueLogEntries: TestPage "Job Queue Log Entries";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        FirstJQId: Integer;
        SecondJQId: Integer;
    begin
        // [Scenario] Given stale (in process) jobs, when the page opens, it should update the stale jobs to error state

        // [Given] Stale job queues log entries
        CreateJobQueueLogEntry(JobQueueLogEntry, 0, 0, JobQueueLogEntry.Status::"In Process");
        FirstJQId := JobQueueLogEntry."Entry No.";

        CreateJobQueueLogEntry(JobQueueLogEntry, 0, 0, JobQueueLogEntry.Status::"In Process");
        SecondJQId := JobQueueLogEntry."Entry No.";

        // [When] Open JQLE list page
        JobQueueLogEntries.OpenView();

        // [Then] Job queue log entries should be in error state
        JobQueueLogEntries.GoToKey(FirstJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntries.Status, 'The first job queue log entry is not in error state.');
        JobQueueLogEntries.GoToKey(SecondJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntries.Status, 'The second job queue log entry is not in error state.');
        JobQueueLogEntries.Close();

        JobQueueLogEntry.Get(FirstJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'The first job queue log entry is not in error state.');
        JobQueueLogEntry.Get(SecondJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'The second job queue log entry is not in error state.');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        DeleteAllJobQueueEntries();
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; ObjectType: Integer; ObjectID: Integer; JQEntryStatus: Option)
    begin
        JobQueueEntry.Init();
        Clear(JobQueueEntry."ID");
        JobQueueEntry.Validate("Object Type to Run", ObjectType);
        JobQueueEntry.Validate("Object ID to Run", ObjectID);
        JobQueueEntry.Status := JQEntryStatus;
        JobQueueEntry.Insert(true);
    end;

    local procedure CreateJobQueueLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry"; ObjectType: Integer; ObjectID: Integer; JQLogEntryStatus: Option)
    begin
        JobQueueLogEntry.Init();
        Clear(JobQueueLogEntry."Entry No.");
        JobQueueLogEntry.Validate("Object Type to Run", ObjectType);
        JobQueueLogEntry.Validate("Object ID to Run", ObjectID);
        JobQueueLogEntry.Status := JQLogEntryStatus;
        JobQueueLogEntry.Insert(true);
    end;

    local procedure CreateRecurringJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; Duration: Integer; JQEntryStatus: Option)
    begin
        CreateJobQueueEntry(
          JobQueueEntry,
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Job Queue Sleeping Sample",
          JobQueueEntry.Status::"On Hold");

        with JobQueueEntry do begin
            "Recurring Job" := true;
            "Run on Mondays" := true;
            "Run on Tuesdays" := true;
            "Run on Wednesdays" := true;
            "Run on Thursdays" := true;
            "Run on Fridays" := true;
            "Run on Saturdays" := true;
            "Run on Sundays" := true;
            "No. of Minutes between Runs" := Duration;
            Modify(true);
            SetStatus(JQEntryStatus);
        end;
    end;

    local procedure CreateTimeBasedRecurringJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; StartingTime: Time; EndingTime: Time; Duration: Integer; EarliestStartingDatetTime: DateTime; JQEntryStatus: Option)
    begin
        CreateRecurringJobQueueEntry(JobQueueEntry, Duration, JobQueueEntry.Status::"On Hold");

        with JobQueueEntry do begin
            "Starting Time" := StartingTime;
            "Ending Time" := EndingTime;
            "Earliest Start Date/Time" := EarliestStartingDatetTime;
            Modify(true);
            SetStatus(JQEntryStatus);
        end;
    end;

    local procedure WaitForJobEntryStatus(JobEntryId: Guid)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        i: Integer;
    begin
        Commit();
        repeat
            i += 1;
            Sleep(1000);

            JobQueueLogEntry.SetRange(ID, JobEntryId);
            if JobQueueLogEntry.FindLast() then;
        until (i > 300) or ((JobQueueLogEntry."Entry No." <> 0) and (JobQueueLogEntry.Status <> JobQueueLogEntry.Status::"In Process"));

        if i > 300 then
            Error(TimeoutErr, 'JobQueueEntry status remained In Progress');
    end;

    local procedure DeleteAllJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // We won't be able to delete entries with Status = In Process.
        Commit();
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        if JobQueueEntry.FindSet() then begin
            repeat
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            until JobQueueEntry.Next() = 0;
        end;
        JobQueueEntry.SetRange(Status);

        JobQueueEntry.DeleteAll(true);
        JobQueueLogEntry.DeleteAll(true);
        Commit();
    end;

    local procedure VerifyJobQueueEntry(ExpectedRecID: RecordID)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        with JobQueueEntry do begin
            SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
            SetRange("Object ID to Run", CODEUNIT::"Document-Mailing");
            FindFirst();
            TestField("Record ID to Process", ExpectedRecID);
        end;
    end;

    local procedure VerifyJobQueueEntryWithTearDown(CodeunitID: Integer; Recurring: Boolean; NoOfMinutes: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Recurring Job", Recurring);
        JobQueueEntry.TestField("No. of Minutes between Runs", NoOfMinutes);

        JobQueueEntry.Delete();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyRequest(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) > 0, 'Unexpected confirmation request');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

