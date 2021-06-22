codeunit 139032 "Job Queue - Inactivity Detect"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Inactivity Detection]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure T104_NotRecurringJobGetsDeletedEvenIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Not recurring job that didn't result in modified/inserted records do not get 'On Hold' status
        Initialize;

        // [GIVEN] Active not recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Modify();

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);  // returns flag of no changes by sync
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job should be deleted
        Assert.IsFalse(JobQueueEntry.Find, 'Job should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105A_ActiveJobBecomesOnHoldWithInactivityTimeoutNonZeroPeriodIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive for a period of time if the run didn't change anything and Inactivity Timeout Period > 0
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;
        // [GIVEN] Active recurring job 'X' is executed, Inactivity Timeout Period = 10
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);
        CurrDT := CurrentDateTime;
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity period"
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        VerifyDateTimeDifference(CurrDT, JobQueueEntry."Earliest Start Date/Time", JobQueueEntry."Inactivity Timeout Period" * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105B_ActiveJobBecomesOnHoldWithInactivityTimeoutZeroPeriodIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive with "On Hold with Inactivity Timeout" state if the run didn't change anything and Inactivity Timeout Period = 0
        Initialize;

        // [GIVEN] Active recurring job 'X' is executed with Inactivity Timeout Period = 0
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry.Validate("Inactivity Timeout Period", 0);
        JobQueueEntry.Modify();

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity Timeout"
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_ActiveJobsStaysActiveIfRecordIsChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job stays active if the run resulted in some activity.
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] Job is done and changes were done
        MockSynchJobRunner.SetJobWasActive;
        BindSubscription(MockSynchJobRunner);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job stays active, Status = Ready
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T111_InactiveJobsBecomesActiveIfRecIsChangedManually()
    var
        Item: Record Item;
        JobQueueEntry: array[3] of Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Inactive job becomes active on manual record modification.
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM1', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[1], DATABASE::Item, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout");
        JobQueueEntry[1]."Last Ready State" := CurrentDateTime; // last run very recently
        JobQueueEntry[1].Modify();
        // [GIVEN] Integration Table Mapping 'CUSTOMER', where "Table ID" = 'Customer'
        // [GIVEN] Job 'CUSTOMER', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[2], DATABASE::Customer, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
        // last run at a time in the past which makes it ready for another run, had the job queue been active.
        JobQueueEntry[2]."Last Ready State" := CurrentDateTime - 60000 * JobQueueEntry[3]."No. of Minutes between Runs";
        JobQueueEntry[2].Modify();
        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM2', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[3], DATABASE::Item, JobQueueEntry[3].Status::"On Hold with Inactivity Timeout");
        // last run at a time in the past which makes it ready for another run, had the job queue been active.
        JobQueueEntry[3]."Last Ready State" := CurrentDateTime - 60000 * JobQueueEntry[3]."No. of Minutes between Runs";
        JobQueueEntry[3].Modify();

        // [WHEN] Item 'X' has been inserted
        Item."No." := LibraryUtility.GenerateGUID;
        Item.Insert(); // calls COD1.OnDatabaseInsert -> COD5150.InsertUpdateIntegrationRecord

        // [THEN] Job 'ITEM1' does not get status "Ready", as it has only recently executed.
        JobQueueEntry[1].Find;
        JobQueueEntry[1].TestField(Status, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout");
        // [THEN] Job 'CUSTOMER' is not changed, the state of the job is "On Hold with Inactivity period"
        JobQueueEntry[2].Find;
        JobQueueEntry[2].TestField(Status, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
        // [THEN] Job 'ITEM2' gets status "Ready"
        JobQueueEntry[3].Find;
        JobQueueEntry[3].TestField(Status, JobQueueEntry[3].Status::Ready);
        // [THEN] new "Earliest Start Date/Time" is about 1 second from now
        VerifyDateTimeDifference(CurrentDateTime, JobQueueEntry[3]."Earliest Start Date/Time", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T112_InactiveJobsStaysInactiveDuringUpgrade()
    var
        Item: Record Item;
        JobQueueEntry: Record "Job Queue Entry";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
    begin
        // [FEATURE] [UT] [Upgrade]
        // [SCENARIO] Inactive job stays inactive on manual record modification during upgrade.
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        JobQueueEntry."Last Ready State" := CurrentDateTime;
        JobQueueEntry.Modify();

        // [GIVEN] Upgrade is in progress
        DataUpgradeMgt.SetUpgradeInProgress;

        // [WHEN] Item 'X' has been inserted
        Item."No." := LibraryUtility.GenerateGUID;
        Item.Insert(); // calls COD1.OnDatabaseInsert -> COD5150.InsertUpdateIntegrationRecord

        // [THEN] Job 'ITEM', where status "On Hold with Inactivity period"
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T113_InactiveJobsAreActivatedOnCompanyOpenIfSourceModified()
    var
        JobQueueEntry: array[6] of Record "Job Queue Entry";
        UpdatedJobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
        I: Integer;
    begin
        // [FEATURE] [UT] [Login] [Company]
        // [SCENARIO] "Inactive" jobs are activated on Company opening if source tables are modified
        // [SCENARIO 310997] "Error" jobs are not started on company open
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Jobs 'A' and 'B', executed and got Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[1], DATABASE::Item, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout");
        JobQueueEntry[1]."Last Ready State" := CurrentDateTime;
        JobQueueEntry[1].Modify();
        CreateJobQueueEntry(JobQueueEntry[2], DATABASE::Customer, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
        JobQueueEntry[2]."Last Ready State" := CurrentDateTime;
        JobQueueEntry[2].Modify();

        // [GIVEN] Job 'C', where Status "On Hold"
        CreateJobQueueEntry(JobQueueEntry[3], DATABASE::Resource, JobQueueEntry[3].Status::"On Hold");

        // [GIVEN] Job 'D', where Status "Ready"
        CreateJobQueueEntry(JobQueueEntry[4], DATABASE::Currency, JobQueueEntry[4].Status::Ready);

        // [GIVEN] Job 'E', where Status "Error", "User ID" = USERID
        CreateJobQueueEntry(JobQueueEntry[5], DATABASE::Vendor, JobQueueEntry[5].Status::Error);
        JobQueueEntry[5]."User ID" := UserId;
        JobQueueEntry[5].Modify();

        // [GIVEN] Job 'F', where Status "Error", and "User ID" is set for User that does not exist
        CreateJobQueueEntryWithDeletedUserID(JobQueueEntry[6], DATABASE::Vendor, JobQueueEntry[6].Status::Error);

        // [GIVEN] Mock a change that should trigger Job 'A' reactivation
        MockSynchJobRunner.SetDescriptionOfJobToBeRun(JobQueueEntry[1].Description);
        BindSubscription(MockSynchJobRunner);

        // [WHEN] Run Codeunit "Job Queue User Handler" (mocking OnCompanyOpen)
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        for I := 1 to ArrayLen(JobQueueEntry) do
            JobQueueEntry[I].Find;

        // [THEN] Job 'A' is activated, the state is "Ready"
        Assert.AreEqual(JobQueueEntry[1].Status::Ready, JobQueueEntry[1].Status, 'Job A Status');

        // [THEN] new "Earliest Start Date/Time" is about 1 second from now
        VerifyDateTimeDifference(CurrentDateTime, JobQueueEntry[1]."Earliest Start Date/Time", 1);

        // [THEN] Jobs 'B', 'C' are not changed
        UpdatedJobQueueEntry.SetRange(Status, UpdatedJobQueueEntry.Status::"On Hold with Inactivity Timeout");
        Assert.RecordCount(UpdatedJobQueueEntry, 1);
        VerifyJobQueueEntryUnchanged(JobQueueEntry[2]);
        VerifyJobQueueEntryUnchanged(JobQueueEntry[3]);

        // [THEN] Jobs 'D' is rescheduled
        Assert.AreEqual(JobQueueEntry[4].Status::Ready, JobQueueEntry[4].Status, 'Job D Status');

        // [THEN] Jobs 'E' and 'F' are not changed (TfsId 264925)
        Assert.AreEqual(JobQueueEntry[5].Status::Error, JobQueueEntry[5].Status,'Job E Status');
        Assert.AreEqual(JobQueueEntry[6].Status::Error, JobQueueEntry[6].Status,'Job F Status');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T114_SetStatusOnHoldwithInactivityPeriodInactivityPeriodPositive()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] SetStatus "On Hold with Inactivity period" with Inactivity Timeout Period > 0
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Active recurring job 'X' is executed, "Inactivity Timeout Period" = 10
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] SetStatus("On Hold with Inactivity Timeout")
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        CurrDT := CurrentDateTime;

        // [THEN] Job gets status "On Hold with Inactivity period"
        // [THEN] "Earliest Start Date/Time" is set according to "Inactivity Timeout Period"
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        VerifyDateTimeDifference(CurrDT, JobQueueEntry."Earliest Start Date/Time", JobQueueEntry."Inactivity Timeout Period" * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T115_SetStatusOnHoldwithInactivityPeriodInactivityPeriodZero()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] SetStatus "On Hold with Inactivity period" with Inactivity Timeout Period = 0
        Initialize;
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask;

        // [GIVEN] Active recurring job 'X' is executed, Inactivity Timeout Period = 0s
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry."Inactivity Timeout Period" := 0;
        JobQueueEntry.Modify();

        // [WHEN] SetStatus("On Hold with Inactivity Timeout")
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold with Inactivity Timeout");

        // [THEN] Job gets status "On Hold"
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer; JobStatus: Option)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID;
        IntegrationTableMapping."Table ID" := TableNo;
        IntegrationTableMapping.Insert();

        with JobQueueEntry do begin
            ID := CreateGuid;
            Description := Format(TableNo);
            Status := JobStatus;
            "Object Type to Run" := "Object Type to Run"::Codeunit;
            "Object ID to Run" := CODEUNIT::"Mock Synch. Job Runner";
            "Recurring Job" := true;
            "No. of Minutes between Runs" := 5;
            "Record ID to Process" := IntegrationTableMapping.RecordId;
            "Run on Mondays" := true;
            "Run on Tuesdays" := true;
            "Run on Wednesdays" := true;
            "Run on Thursdays" := true;
            "Run on Fridays" := true;
            "Run on Saturdays" := true;
            "Run on Sundays" := true;
            "Inactivity Timeout Period" := 10;
            "System Task ID" := CreateGuid;
            Insert;
        end;
    end;

    local procedure CreateJobQueueEntryWithDeletedUserID(var JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer; JobStatus: Option)
    begin
        CreateJobQueueEntry(JobQueueEntry, TableNo, JobStatus);
        JobQueueEntry."User ID" := LibraryPermissions.GetNonExistingUserID;
        JobQueueEntry.Modify();
    end;

    local procedure VerifyJobQueueEntryUnchanged(ExpectedJobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry := ExpectedJobQueueEntry;
        JobQueueEntry.Find;
        JobQueueEntry.TestField(Status, ExpectedJobQueueEntry.Status);
    end;

    local procedure VerifyDateTimeDifference(DateTime1: DateTime; DateTime2: DateTime; ExpectedDiffInSeconds: Integer)
    var
        DiffInMilliseconds: Integer;
    begin
        DiffInMilliseconds := DateTime2 - DateTime1;
        Assert.AreEqual(ExpectedDiffInSeconds, Round(DiffInMilliseconds / 1000, 1), 'Expected shift in time.');
    end;
}

