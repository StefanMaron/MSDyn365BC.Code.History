codeunit 136313 "Job Creation Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Job Creation Wizard] [UI]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        RollingBackChangesErr: Label 'Rolling back changes...';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Creation Wizard Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Creation Wizard Tests");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Creation Wizard Tests");
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        asserterror Error(RollingBackChangesErr);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectNoOnFirstPage()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
        JobCard: TestPage "Job Card";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        with JobCreationWizard do begin
            // [THEN] Make sure default of Yes is checked on the first page.
            Assert.IsTrue(FromExistingJob.AsBoolean(), 'Checkbox should be marked by default.');

            // [WHEN] User marks to note create job from existing job.
            FromExistingJob.SetValue(false);

            JobCard.Trap();
            ActionNext.Invoke();
            // Choosing next here should open up the Job card, with a new Job Number defaulted in.
            Assert.AreEqual(Format(JobCard."No."), Format(Job."No."), 'Job number should have a value when the Job page is opened.');
        end;
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPage()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
    begin
        // [GIVEN] A newly setup company, with a new job created
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        with JobCreationWizard do begin
            FromExistingJob.SetValue(true);
            // [THEN] The checkbox is checked.
            ActionNext.Invoke();

            // [THEN] The new job number was defaulted into the wizard page.
            Assert.AreEqual(Format("No."), Format(Job."No."), 'Default job number does not match created job.');

            // [WHEN] The customer number for the new job is empty.
            "Sell-to Customer No.".SetValue('');

            // [THEN] An error occurs when you click the next button.
            asserterror ActionNext.Invoke();
        end;
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPageThenNextToCopyJob()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
        JobCard: TestPage "Job Card";
        CopyJobTasks: TestPage "Copy Job Tasks";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        with JobCreationWizard do begin
            ActionNext.Invoke();

            // [WHEN] The user has entered a descripton and a customer number for the new job, then clicks next.
            Description.SetValue('Job description.');
            "Sell-to Customer No.".SetValue(Job."Bill-to Customer No.");

            CopyJobTasks.Trap();
            ActionNext.Invoke();
            Assert.AreEqual(Format(CopyJobTasks.TargetJobNo), Format(Job."No."), 'Default job number does not match created job.');
            CopyJobTasks.Close();

            // [WHEN] The user closes the wizard
            JobCard.Trap();
            ActionFinish.Invoke();
            // [THEN] Job card page displays with the new job number.
            Assert.AreEqual(Format(JobCard."No."), Format(Job."No."), 'Job number should have a value when the Job page is opened.');
        end;
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectYesOnFirstPageThenBack()
    var
        LibraryJob: Codeunit "Library - Job";
        JobCreationWizard: TestPage "Job Creation Wizard";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] The user runs the job creation wizard.
        JobCreationWizard.Trap();
        PAGE.Run(PAGE::"Job Creation Wizard", Job);
        with JobCreationWizard do begin
            ActionNext.Invoke();

            // [WHEN] The user clicks back, Yes checkbox should still be checked, and no should be unchecked.
            ActionBack.Invoke();
            // [THEN] The Yes checkbox is checked.
            Assert.IsTrue(FromExistingJob.AsBoolean(), 'Checkbox should be marked true by default.');
        end;
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobCreationSetsNewDefaults()
    var
        JobsSetup: Record "Jobs Setup";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [GIVEN] A newly setup company, with a new job and new customer created (via the CreateJob() method)
        Initialize();
        LibraryJob.CreateJob(Job);

        // [WHEN] Jobs Setup table is accessed
        if JobsSetup.FindFirst() then begin
            // [THEN] Defaults for "Apply Usage Link by Default" and "Allow Sched/Contract Lines Def" are true
            Assert.IsTrue(JobsSetup."Apply Usage Link by Default", '"Apply Usage Link by Default" should be true.');
            Assert.IsTrue(JobsSetup."Allow Sched/Contract Lines Def", '"Allow Sched/Contract Lines Def" should be true.');
        end;

        // [WHEN] Job record is accessed for newly-created job
        // [THEN] Values for "Apply Usage Link by Default" and "Allow Sched/Contract Lines Def" are true
        Assert.IsTrue(Job."Apply Usage Link", '"Apply Usage Link" should be true.');
        Assert.IsTrue(Job."Allow Schedule/Contract Lines", '"Allow Schedule/Contract Lines" should be true.');
    end;
}

