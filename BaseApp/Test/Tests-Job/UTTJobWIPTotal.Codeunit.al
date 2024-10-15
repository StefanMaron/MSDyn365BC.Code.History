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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryJob: Codeunit "Library - Job";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job WIP Total");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateJobPostingGroups();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");
    end;

    local procedure UpdateJobPostingGroups()
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        with JobPostingGroup do
            if FindSet() then
                repeat
                    LibraryJob.UpdateJobPostingGroup(JobPostingGroup);
                until Next = 0;
    end;

    [Normal]
    local procedure SetUp()
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
        Initialize();
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
        Initialize();
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

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure RecogProfitGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobWIPCockpit: TestPage "Job WIP Cockpit";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
        // [SCENARIO 474478] The field “Recog Profit G/L Amount” on Job WIP page does not show the same amount as on the Job Card.
        Initialize();
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Post usage on the Job Task
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", UnitPrice);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [VERIFY] Verify: "Recog. Profit G/L Amount" and "Recog. Profit Amount Difference" are calculated correctly when Calculate WIP
        JobWIPCockpit.OpenView();
        JobWIPCockpit.GoToRecord(Job);
        JobWIPCockpit."Recog. Profit Amount".AssertEquals(Job.CalcRecognizedProfitAmount());
        JobWIPCockpit."Recog. Profit Amount Difference".AssertEquals(
            Job.CalcRecognizedProfitAmount() - Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit.Close();

        // [WHEN] 'Post WIP to G/L' is called
        RunJobPostWIPToGL(Job);

        // [VERIFY] Verify: "Recog. Profit G/L Amount" and "Recog. Profit Amount Difference" are calculated correctly after Post WIP to G/L
        JobWIPCockpit.OpenView();
        JobWIPCockpit.GoToRecord(Job);
        JobWIPCockpit."Recog. Profit G/L Amount".AssertEquals(Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit."Recog. Profit Amount Difference".AssertEquals(
            Job.CalcRecognizedProfitAmount() - Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit.Close();
    end;

    local procedure RunJobCalculateWIP(Job: Record Job)
    var
        JobCalculateWIP: Report "Job Calculate WIP";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobCalculateWIP);
        JobCalculateWIP.SetTableView(Job);

        // Use Document No. as Job No. because value is not important.
        JobCalculateWIP.InitializeRequest;
        JobCalculateWIP.UseRequestPage(false);
        JobCalculateWIP.Run();
    end;

    local procedure RunJobPostWIPToGL(Job: Record Job)
    var
        JobPostWIPToGL: Report "Job Post WIP to G/L";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobPostWIPToGL);
        JobPostWIPToGL.SetTableView(Job);
        JobPostWIPToGL.UseRequestPage(false);
        JobPostWIPToGL.Run();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

