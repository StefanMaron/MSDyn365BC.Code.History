codeunit 136357 "UT T Job WIP Total"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WIP Total] [Job]
        IsInitialized := false;
    end;

    var
        Text001: Label 'Rolling back changes...';
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job WIP Total");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");

        LibraryERMCountryData.UpdateGeneralPostingSetup;

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");
    end;

    [Normal]
    local procedure SetUp()
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        JobWIPTotal.Init();
        JobWIPTotal."Job No." := Job."No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal.Insert();
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobWIPTotal);
        asserterror Error(Text001);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize;
        SetUp;

        // Verify that a Job WIP Total can be deleted and that all Job WIP Warnings are deleted as well.
        JobWIPWarning.Init();
        JobWIPWarning."Job WIP Total Entry No." := JobWIPTotal."Entry No.";
        JobWIPWarning.Insert(true);

        JobWIPWarning.SetRange("Job WIP Total Entry No.", JobWIPTotal."Entry No.");
        Assert.IsTrue(JobWIPWarning.FindFirst, 'No Job WIP Warnings were found.');

        Assert.IsTrue(JobWIPTotal.Delete(true), 'The Job WIP Total could not be deleted.');
        Assert.IsFalse(JobWIPWarning.FindFirst, 'Job WIP Warnings still exist after deletion of Record.');

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPWarnings()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize;
        SetUp;

        // Verify that WIP Warnings is false when no warnings exist.
        Assert.IsFalse(JobWIPTotal."WIP Warnings", 'WIP Warning is true, even if no warnings exist.');

        // Verify that WIP Warnings is true when warnings exist.
        JobWIPWarning.Init();
        JobWIPWarning."Job No." := Job."No.";
        JobWIPWarning."Job Task No." := JobTask."Job Task No.";
        JobWIPWarning."Job WIP Total Entry No." := JobWIPTotal."Entry No.";
        JobWIPWarning.Insert();
        JobWIPTotal.CalcFields("WIP Warnings");
        Assert.IsTrue(JobWIPTotal."WIP Warnings", 'WIP Warning is false, even if warnings exist.');

        TearDown;
    end;
}

