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
        LibrarySales: Codeunit "Library - Sales";
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
    procedure TotalWIPSalesGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
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

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Sales G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-UnitPrice);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPSalesGLAmountIsCalculatedCorrectlyForJobWithPerJobLedgerEntryWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
        Initialize();
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job Ledger Entry'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
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

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Sales G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-UnitPrice);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPCostGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPage: TestPage "Job Card";
        UnitCost: Integer;
        UnitPrice: Integer;
    begin
        Initialize();
        UnitCost := LibraryRandom.RandInt(200);
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Add Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // Add 'Job Planning Line'
        LibraryJob.CreateJobPlanningLine("Job planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice created posted for the 'Job Planning Line'
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Cost G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Cost G/L Amount".AssertEquals(-UnitCost);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPCostGLAmountIsCalculatedCorrectlyForJobWithPerJobLedgerEntryWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPage: TestPage "Job Card";
        UnitCost: Integer;
        UnitPrice: Integer;
    begin
        Initialize();
        UnitCost := LibraryRandom.RandInt(200);
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job Ledger Entry'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // Add Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // Add 'Job Planning Line'
        LibraryJob.CreateJobPlanningLine("Job planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice created posted for the 'Job Planning Line'
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Cost G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Cost G/L Amount".AssertEquals(-UnitCost);
        JobPage.Close();
    end;

    local procedure GetSalesDocument(JobPlanningLine: Record "Job Planning Line"; DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        with JobPlanningLineInvoice do begin
            SetRange("Job No.", JobPlanningLine."Job No.");
            SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
            if DocumentType = SalesHeader."Document Type"::Invoice then
                SetRange("Document Type", "Document Type"::Invoice)
            else
                SetRange("Document Type", "Document Type"::"Credit Memo");
            FindFirst();
            SalesHeader.Get(DocumentType, "Document No.")
        end
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToInvoiceHandler(var RequestPage: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        RequestPage.OK.Invoke
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}