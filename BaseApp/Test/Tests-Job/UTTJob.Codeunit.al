codeunit 136350 "UT T Job"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Job Ledger Entry" = rimd,
                  TableData "Job WIP G/L Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        JobsSetup: Record "Jobs Setup";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NoSeries: Record "No. Series";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RollingBackChangesErr: Label 'Rolling back changes...';
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJob: Codeunit "Library - Job";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        IncorrectSourceIDErr: Label 'Incorrect Source ID.';
        JobTaskDimDoesNotExistErr: Label 'Project Task Dimension does not exist.';
        JobTaskDimExistsErr: Label 'Project Task Dimension exists.';
        TimeSheetLinesErr: Label 'You cannot delete project %1 because it has open or submitted time sheet lines.', Comment = 'You cannot delete project PROJ001 because it has open or submitted time sheet lines.';
        CustomerBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked with type %2', Comment = '%1 - Customer No, %2 - Blocked Type';
        BlockedCustomerExpectedErr: Label 'Blocked Customer error was expected';
        ShipToCityNotMatchedErr: Label '%1 must be equal to %2 in Project table.', Comment = '%1 = Ship-to City field caption, %2 = Expected city value';
        BinCodeNotMatchedErr: Label '%1 must be equal to %2 in Project table.', Comment = '%1 = Bin Code in Job table, %2 = Expected Bin Code value';
        LocationCodeNotMatchedErr: Label '%1 must be equal to %2 in Project table.', Comment = '%1 = Location Code in Job Task table, %2 = Expected Location Code value';
        TasksNotUpdatedMsg: Label 'You have changed %1 on the project, but it has not been changed on the existing project tasks.', Comment = '%1 = a Field Caption like Location Code';
        UpdateTasksManuallyMsg: Label 'You must update the existing project tasks manually.';
        PlanningLinesNotUpdatedMsg: Label 'You have changed %1 on the project task, but it has not been changed on the existing project planning lines.', Comment = '%1 = a Field Caption like Location Code';
        UpdatePlanningLinesManuallyMsg: Label 'You must update the existing project planning lines manually.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitialization()
    var
        JobsSetup: Record "Jobs Setup";
        JobWIPMethod: Record "Job WIP Method";
        LibraryJob: Codeunit "Library - Job";
        Method: Option "Completed Contract","Cost of Sales","Cost Value",POC,"Sales Value";
    begin
        // Verify that Apply Usage Link is initialized correctly.

        // Verify that Apply Usage Link and Allow Schedule/Contract Lines are not set by default, if not set in Jobs Setup.
        Initialize();
        JobsSetup.Get();
        JobsSetup.Validate("Apply Usage Link by Default", false);
        JobsSetup.Validate("Allow Sched/Contract Lines Def", false);
        JobsSetup.Modify();
        LibraryJob.CreateJob(Job);
        Assert.IsFalse(Job."Apply Usage Link", 'Apply Usage link is not FALSE by default.');
        Assert.IsFalse(Job."Allow Schedule/Contract Lines", 'Allow Schedule/Contract Lines is not FALSE by default.');

        TearDown();

        // Verify that Apply Usage Link and Allow Schedule/Contract Lines are set by default, if set in Jobs Setup.
        Initialize();
        JobsSetup.Get();
        JobsSetup.Validate("Apply Usage Link by Default", true);
        JobsSetup.Validate("Allow Sched/Contract Lines Def", true);
        JobsSetup.Modify();
        LibraryJob.CreateJob(Job);
        Assert.IsTrue(Job."Apply Usage Link", 'Apply Usage link is not TRUE by default.');
        Assert.IsTrue(Job."Allow Schedule/Contract Lines", 'Allow Schedule/Contract Lines is not TRUE by default.');

        // Verify that the Default WIP Method is set by default, if set in Jobs Setup.
        JobsSetup.Get();
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Cost Value");
        JobsSetup.Validate("Default WIP Method", JobWIPMethod.Code);
        JobsSetup.Validate("Default WIP Posting Method", JobsSetup."Default WIP Posting Method"::"Per Job Ledger Entry");
        JobsSetup.Modify();
        LibraryJob.CreateJob(Job);
        Assert.AreEqual(Job."WIP Method", JobWIPMethod.Code, 'The WIP Method is not set to the correct default value.');

        // Verify that the Default WIP Posting Method is set by default, if set in Jobs Setup.
        Assert.AreEqual(Job."WIP Posting Method"::"Per Job Ledger Entry", Job."WIP Posting Method",
          'The WIP Posting Method is not set to the correct default value.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldApplyUsageLink()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryJob: Codeunit "Library - Job";
    begin
        Initialize();
        SetUp(true);

        // Verify that Apply Usage Link can be checked, as long as no Usage has been posted.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable",
          JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        Job.Validate("Apply Usage Link", true);
        Assert.IsTrue(Job."Apply Usage Link",
          'Apply Usage link cannot be checked, even if no Job Ledger Entries of type Usage exist.');

        // Verify that all Job Planning Lines of type schedule have Usage Link enabled, after the Job's Apply Usage Link was enabled.
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.SetRange("Usage Link", false);
        Assert.IsFalse(JobPlanningLine.FindFirst(), 'Some Job Planning Lines were not updated with Usage Link.');

        // Verify that Apply Usage Link cannot be checked, once Usage has been posted.
        Job.Validate("Apply Usage Link", false);
        Job.Modify();
        JobLedgerEntry.Init();
        JobLedgerEntry."Job No." := Job."No.";
        JobLedgerEntry.Insert();

        asserterror Job.Validate("Apply Usage Link", true);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPWarnings()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize();
        SetUp(true);

        // Verify that WIP Warnings is false when no warnings exist.
        Assert.IsFalse(Job."WIP Warnings", 'WIP Warning is true, even if no warnings exist.');

        // Verify that WIP Warnings is true when warnings exist.
        JobWIPWarning.Init();
        JobWIPWarning."Job No." := Job."No.";
        JobWIPWarning.Insert();
        Job.CalcFields("WIP Warnings");
        Assert.IsTrue(Job."WIP Warnings", 'WIP Warning is false, even if warnings exist.');

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestFieldWIPMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        SetUp(true);

        // Verify that update of WIP Method is reflected on Job Tasks as well.
        JobWIPMethod.FindFirst();
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindFirst();
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify();
        Job.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.FindFirst();
        Assert.AreEqual(JobWIPMethod.Code, JobTask."WIP Method", 'The WIP Method set on the Job is not propagated to the Job Task Line.');

        with Job do begin
            // Validate that Job WIP Method without "WIP Sales" can't be set when WIP Posting Method is Per Job Ledger Entry.
            CreateJobWIPMethod(JobWIPMethod, false, true);
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");
            asserterror Validate("WIP Method", JobWIPMethod.Code);

            // Validate that Job WIP Method without "WIP Costs" can't be set when WIP Posting Method is Per Job Ledger Entry.
            CreateJobWIPMethod(JobWIPMethod, true, false);
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");
            asserterror Validate("WIP Method", JobWIPMethod.Code);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPPostingMethod()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        SetUp(true);

        with Job do begin
            // Validate that WIP Posting Method can't be changed back to Per Job, once entries have been posted with Per Job Ledger Entry.
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");
            JobLedgerEntry.Init();
            JobLedgerEntry."Job No." := "No.";
            JobLedgerEntry."Amt. Posted to G/L" := LibraryRandom.RandInt(1000);
            JobLedgerEntry.Insert();
            asserterror Validate("WIP Posting Method", "WIP Posting Method"::"Per Job");

            // Validate that WIP Posting Method can't be changed, if Job WIP Entries exist.
            Clear(JobWIPEntry);
            JobWIPEntry.Init();
            if JobWIPEntry.FindLast() then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert();
            asserterror Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");

            // Validate that the Job WIP Method has WIP Sales and WIP Costs enabled, when WIP Posting Method is set to Per Job Ledger Entry.
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job");
            CreateJobWIPMethod(JobWIPMethod, false, true);
            Validate("WIP Method", JobWIPMethod.Code);
            asserterror Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");

            CreateJobWIPMethod(JobWIPMethod, true, false);
            Validate("WIP Method", JobWIPMethod.Code);
            asserterror Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");

            CreateJobWIPMethod(JobWIPMethod, true, true);
            Validate("WIP Method", JobWIPMethod.Code);
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");
            Assert.AreEqual("WIP Posting Method"::"Per Job Ledger Entry", "WIP Posting Method", 'WIP Posting Method could not be set.');
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionsCalcRecognized()
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        Initialize();
        SetUp(true);

        // Verify that CalcAccWIPCostsAmount(), CalcAccWIPSalesAmount, CalcRecognizedProfitAmount, CalcRecognizedProfitPercentage,
        // CalcRecognizedProfitGLAmount and CalcRecognProfitGLPercentage calculate the correct amount.
        with Job do begin
            Clear(JobWIPEntry);
            JobWIPEntry.Init();
            if JobWIPEntry.FindLast() then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry.Type := JobWIPEntry.Type::"Recognized Costs";
            JobWIPEntry.Reverse := false;
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert();

            Clear(JobWIPEntry);
            JobWIPEntry.Init();
            if JobWIPEntry.FindLast() then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry.Type := JobWIPEntry.Type::"Recognized Sales";
            JobWIPEntry.Reverse := false;
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert();

            Clear(JobWIPGLEntry);
            if JobWIPGLEntry.FindLast() then
                JobWIPGLEntry."Entry No." += 1
            else
                JobWIPGLEntry."Entry No." := 1;
            JobWIPGLEntry.Init();
            JobWIPGLEntry."Job No." := "No.";
            JobWIPGLEntry.Type := JobWIPGLEntry.Type::"Recognized Costs";
            JobWIPGLEntry.Reverse := false;
            JobWIPGLEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPGLEntry.Insert();

            Clear(JobWIPGLEntry);
            JobWIPGLEntry.Init();
            if JobWIPGLEntry.FindLast() then
                JobWIPGLEntry."Entry No." += 1
            else
                JobWIPGLEntry."Entry No." := 1;
            JobWIPGLEntry."Job No." := "No.";
            JobWIPGLEntry.Type := JobWIPGLEntry.Type::"Recognized Sales";
            JobWIPGLEntry.Reverse := false;
            JobWIPGLEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPGLEntry.Insert();

            JobTask."Recognized Sales Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Costs Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Sales G/L Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Costs G/L Amount" := LibraryRandom.RandInt(1000);
            JobTask.Modify();

            CalcFields("Calc. Recog. Sales Amount", "Calc. Recog. Costs Amount",
              "Calc. Recog. Sales G/L Amount", "Calc. Recog. Costs G/L Amount",
              "Total WIP Cost Amount", "Total WIP Sales Amount",
              "Applied Costs G/L Amount", "Applied Sales G/L Amount");

            Assert.AreEqual("Total WIP Cost Amount" + "Applied Costs G/L Amount", CalcAccWIPCostsAmount(),
              'CalcAccWIPCostsAmount calculates the wrong amount.');

            Assert.AreEqual("Total WIP Sales Amount" - "Applied Sales G/L Amount", CalcAccWIPSalesAmount(),
              'CalcAccWIPSalesAmount calculates the wrong amount.');

            Assert.AreEqual("Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount", CalcRecognizedProfitAmount(),
              'CalcRecognizedProfitAmount calculates the wrong amount.');

            Assert.AreEqual((("Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount") / "Calc. Recog. Sales Amount") * 100,
              CalcRecognizedProfitPercentage(), 'CalcRecognizedProfitPercentage calculates the wrong amount.');

            Assert.AreEqual("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount", CalcRecognizedProfitGLAmount(),
              'CalcRecognizedProfitGLAmount calculates the wrong amount.');

            Assert.AreEqual((("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount") / "Calc. Recog. Sales G/L Amount") * 100,
              CalcRecognProfitGLPercentage(), 'CalcRecognProfitGLPercentage calculates the wrong amount.');
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCurrencyUpdate()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Initialize();
        SetUp(true);

        // Make sure you can change the currency code on a Job Planning Line through this function.
        Currency.Init();
        Currency.Code := 'TEST';
        Currency.Insert();

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate();
        CurrencyExchangeRate."Exchange Rate Amount" := 1;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 1;
        CurrencyExchangeRate.Insert();

        Job."Currency Code" := Currency.Code;
        Job.CurrencyUpdatePlanningLines();

        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindFirst();

        Assert.AreEqual('TEST', JobPlanningLine."Currency Code",
          'The Currency Code on the Job Planning Line was not set correctly.');

        // Make sure you can't change the currency when the line is transferred to a Sales Invoice.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, 1);
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        asserterror Job.CurrencyUpdatePlanningLines();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReservEntrySourceIDOnJobRename()
    var
        Job: Record Job;
        JobPlanningReservEntry: Record "Reservation Entry";
        JobJnlLineReservEntry: Record "Reservation Entry";
        NewJobNo: Code[20];
    begin
        // [FEATURE] [Reservations]
        // [SCENARIO 361919] Source ID of Reservation Entries is renamed when rename Job No.

        // [GIVEN] Job = "X"
        // [GIVEN] Reservation Entry with Source ID = "X" and Source Type = "Job Planning Line"
        // [GIVEN] Reservation Entry with Source ID = "X" and Source Type = "Job Journal Line"
        Initialize();
        LibraryJob.CreateJob(Job);
        CreateReservEntry(JobPlanningReservEntry, DATABASE::"Job Planning Line", Job."No.");
        CreateReservEntry(JobJnlLineReservEntry, DATABASE::"Job Journal Line", Job."No.");
        NewJobNo := LibraryUtility.GenerateGUID();
        // [WHEN] Job is renamed from "X" to "Y"
        Job.Rename(NewJobNo);
        // [THEN] Source ID of Reservation Entry with Source Type = "Job Planning Line" is "Y"
        JobPlanningReservEntry.Find();
        Assert.AreEqual(NewJobNo, JobPlanningReservEntry."Source ID", IncorrectSourceIDErr);
        // [THEN] Source ID of Reservation Entry with Source Type = "Job Journal Line" is "Y"
        JobJnlLineReservEntry.Find();
        Assert.AreEqual(NewJobNo, JobJnlLineReservEntry."Source ID", IncorrectSourceIDErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobTaskDimensionOnValidateJobGlobalDimension()
    var
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 363274] Job Task Global Dimensions are updated when validate global dimension in Job

        Initialize();
        // [GIVEN] Job and Job Task with empty global dimensions
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Global Dimension Value Codes "X" and "Y"
        LibraryDimension.CreateDimensionValue(DimValue1, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimValue2, LibraryERM.GetGlobalDimensionCode(2));

        // [WHEN] Set Global Dimension Values "X" and "Y" in Job, confirm update for lines
        UpdateJobGlobalDimensionCode(Job, DimValue1.Code, DimValue2.Code);

        // [THEN] Job Task Global Dimensions is equal to Job Global Dimension Values "X" and "Y"
        VerifyJobTaskDimension(JobTask, DimValue1."Dimension Code", DimValue1.Code);
        VerifyJobTaskDimension(JobTask, DimValue2."Dimension Code", DimValue2.Code);
        VerifyJobTaskGlobalDimensions(JobTask, DimValue1.Code, DimValue2.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmFalseHandler')]
    [Scope('OnPrem')]
    procedure JobTaskDimensionOnValidateJobGlobalDimensionCancelConfirm()
    var
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 363274] Job Task Global Dimensions are not updated when validate global dimension in Job and cancel update for lines

        Initialize();
        // [GIVEN] Job and Job Task with empty global dimensions
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Global Dimension Value Codes "X" and "Y"
        LibraryDimension.CreateDimensionValue(DimValue1, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimValue2, LibraryERM.GetGlobalDimensionCode(2));

        // [WHEN] Set Global Dimension Values "X" and "Y" in Job, cancel update for lines
        UpdateJobGlobalDimensionCode(Job, DimValue1.Code, DimValue2.Code);

        // [THEN] No Job Task Dimension
        VerifyJobTaskDimDoesNotExist(JobTask);
        VerifyJobTaskGlobalDimensions(JobTask, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcUpdateOverBudgetValue_UsageWithCostGreaterThanScheduleCost()
    var
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        InputCost: Decimal;
    begin
        // [SCENARIO 302594] "Over Budget" is "Yes" in Job if Total Cost of Job Ledger Entries and input Cost is greater than schedule cost when function UpdateOverBudgetValue is executed

        Initialize();
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(UsageCost, InputCost, ScheduleCost, -1);

        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        InvokeUpdateOverBudgetValueFunctionWithVerification(true, InputCost, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcUpdateOverBudgetValue_UsageWithCostLessThanScheduleCost()
    var
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        InputCost: Decimal;
    begin
        // [SCENARIO 302594] "Over Budget" is "No" in Job if Total Cost of Job Ledger Entries and input Cost is less than schedule cost when function UpdateOverBudgetValue is executed

        Initialize();
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(UsageCost, InputCost, ScheduleCost, 1);

        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        InvokeUpdateOverBudgetValueFunctionWithVerification(true, InputCost, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcUpdateOverBudgetValue_UsageGreaterThanScheduleCostAndInputCost()
    var
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        InputCost: Decimal;
    begin
        // [SCENARIO 302594] "Over Budget" is "Yes" in Job if Total Cost of Job Ledger Entries is greater than schedule cost and input cost when function UpdateOverBudgetValue is executed

        Initialize();
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(InputCost, ScheduleCost, UsageCost, 1);

        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        InvokeUpdateOverBudgetValueFunctionWithVerification(false, InputCost, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcUpdateOverBudgetValue_UsageLessThanScheduleCostAndInputCost()
    var
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        InputCost: Decimal;
    begin
        // [SCENARIO 302594] "Over Budget" is "No" in Job if Total Cost of Job Ledger Entries is less than schedule cost and input cost when function UpdateOverBudgetValue is executed

        Initialize();
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(InputCost, ScheduleCost, UsageCost, -1);

        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        InvokeUpdateOverBudgetValueFunctionWithVerification(false, InputCost, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJobWithOpenTimeSheetLines()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217317] Job cannot be deleted if there are Open Time Sheet Lines for that job.
        Initialize();

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Open.
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Open);

        // [WHEN] Delete the Job.
        asserterror Job.Delete(true);

        // [THEN] The Job is not deleted and error is invoked: 'You cannot delete job Job."No." because it has open or submitted time sheet lines.'
        Assert.ExpectedError(StrSubstNo(TimeSheetLinesErr, Job."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJobWithSubmittedTimeSheetLines()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217317] Job cannot be deleted if there are Submitted Time Sheet Lines for that job.
        Initialize();

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Submitted.
        UpdateTimeSheetLineStatus(TimeSheetLine, TimeSheetLine.Status::Submitted);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Submitted);

        // [WHEN] Delete the Job.
        asserterror Job.Delete(true);

        // [THEN] The Job is not deleted and error is invoked: 'You cannot delete job Job."No." because it has open or submitted time sheet lines.'
        Assert.ExpectedError(StrSubstNo(TimeSheetLinesErr, Job."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJobWithApprovedTimeSheetLines()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217317] Job can be deleted when there are Time Sheet Lines for that Job with Status = Approved.
        Initialize();

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Approved.
        UpdateTimeSheetLineStatus(TimeSheetLine, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);

        // [WHEN] Delete the Job.
        Job.SetRecFilter();
        Job.Delete(true);

        // [THEN] The Job is deleted.
        Assert.RecordIsEmpty(Job);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJobWithRejectedTimeSheetLines()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217317] Job can be deleted when there are Time Sheet Lines for that Job with Status = Rejected.
        Initialize();

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Rejected.
        UpdateTimeSheetLineStatus(TimeSheetLine, TimeSheetLine.Status::Rejected);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Rejected);

        // [WHEN] Delete the Job.
        Job.SetRecFilter();
        Job.Delete(true);

        // [THEN] The Job is deleted.
        Assert.RecordIsEmpty(Job);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyJobAfterModifyJobProjectManager()
    var
        Job: Record Job;
        MyJob: Record "My Job";
        UserA: Code[50];
        UserB: Code[50];
    begin
        // [FEATURE] [User]
        // [SCENARIO 220218] TAB 9154 "My Job" record has been updated when modify Job."Project Manager"
        Initialize();

        // [GIVEN] Users "A", "B", Job "X"
        UserA := MockUser();
        UserB := MockUser();
        LibraryJob.CreateJob(Job);

        // [GIVEN] Validate Job."Project Manager" = "A"
        ValidateJobProjectManagerWithPage(Job, UserA);

        // [GIVEN] MyJob record ("Job No." = "X", "User ID" = "A") has been created
        MyJob.SetRange("Job No.", Job."No.");
        MyJob.SetRange("User ID", UserA);
        Assert.RecordIsNotEmpty(MyJob);

        // [GIVEN] Validate Job."Project Manager" = "B"
        ValidateJobProjectManagerWithPage(Job, UserB);

        // [GIVEN] My Job record ("X", "A") has been removed
        MyJob.SetRange("User ID", UserA);
        Assert.RecordIsEmpty(MyJob);

        // [GIVEN] MyJob record ("X", "B") has been created
        MyJob.SetRange("User ID", UserB);
        Assert.RecordIsNotEmpty(MyJob);

        // [GIVEN] Validate Job."Project Manager" = ""
        ValidateJobProjectManagerWithPage(Job, '');

        // [GIVEN] My Job record ("X", "B") has been removed
        MyJob.SetRange("User ID", UserB);
        Assert.RecordIsEmpty(MyJob);

        // [GIVEN] Validate Job."Project Manager" = "A"
        ValidateJobProjectManagerWithPage(Job, UserA);

        // [WHEN] Delete Job "X"
        Job.Find();
        Job.Delete(true);

        // [THEN] There is no MyJob record with "Job No." = "X"
        MyJob.SetRange("User ID");
        Assert.RecordIsEmpty(MyJob);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DoNotModifyJobRecordIfOverBudgetIsNotChanged()
    var
        DimensionValue: Record "Dimension Value";
        NameValueBuffer: Record "Name/Value Buffer";
        UTTJob: Codeunit "UT T Job";
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        InputCost: Decimal;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 302594] Validation of Job's "Global Dimension 1 Code" and "Global Dimension 1 Code" fields causes single Job's OnModify trigger when job has Job Ledger Entries with total cost.

        Initialize();
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(InputCost, ScheduleCost, UsageCost, 1);

        // [GIVEN] Job "J" with Job Ledger Entries with total cost
        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        // [GIVEN] "Over Budget" is already calculated for the job "J"
        InvokeUpdateOverBudgetValueFunctionWithVerification(false, InputCost, true);

        // [GIVEN] New dimension value code = "D"
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        NameValueBuffer.DeleteAll();
        BindSubscription(UTTJob);

        // [WHEN] Validate "Global Dimension 1 Code" with "D"
        Job.Validate("Global Dimension 1 Code", DimensionValue.Code);

        // [THEN] Trigger Job.OnModify invoked once.
        NameValueBuffer.SetFilter(Name, Job."No.");
        Assert.RecordCount(NameValueBuffer, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyCustomerDimToJobDim()
    var
        Job: Record Job;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 282994] Customer default dimensions copied to job default dimensions
        Initialize();

        // [GIVEN] Customer "CUST" with set of default dimensions "DIMSET"
        CustomerNo := CreateCustomerWithDefDim();

        // [GIVEN] New job "J"
        CreateJob(Job);

        // [WHEN] Job Bill-to Customer No. is being set to "CUST"
        Job.Validate("Bill-to Customer No.", CustomerNo);

        // [THEN] Job "J" has same set of default dimensions "DIMSET"
        VerifyJobDefaultDimensionsFromCustDefaultDimensions(Job."No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeJobCustomerWithDifferentDim()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        CustomerNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 282994] Job and Job Tasks dimensions updated when Bill-to Customer No. is changed by customer with another dimensions
        Initialize();

        // [GIVEN] Customer "CUST1" with set of dimensions "DIMSET1"
        // [GIVEN] Customer "CUST2" with set of dimensions "DIMSET2"
        CustomerNo[1] := CreateCustomerWithDefDim();
        CustomerNo[2] := CreateCustomerWithDefDim();

        // [GIVEN] New job "J" with Bill-to Customer No. = "CUST1"
        CreateJob(Job);
        Job.Validate("Bill-to Customer No.", CustomerNo[1]);
        Job.Validate("Job Posting Group", LibraryJob.FindJobPostingGroup());
        Job.Modify(true);

        // [GIVEN] Job tasks "JT1" - "JT3"
        for i := 1 to 3 do
            LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Job Bill-to Customer No. is being changed to "CUST2"
        Job.Validate("Bill-to Customer No.", CustomerNo[2]);

        // [THEN] Job "J" has dimensionset "DIMSET2"
        VerifyJobDefaultDimensionsFromCustDefaultDimensions(Job."No.", CustomerNo[2]);

        // [THEN] Job tasks "JT1" - "JT3" have dimensionset "DIMSET2"
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindSet();
        repeat
            VerifyJobTaskDimensionsFromCustDefaultDimensions(CustomerNo[2], JobTask);
        until JobTask.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeJobCustomerWithDifferentGlobalDim()
    var
        Customer: array[2] of Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        i: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 282994] Job and Job Tasks dimensions updated when Bill-to Customer No. is changed by customer with another global dimensions
        Initialize();

        // [GIVEN] Customer "CUST1" with global dimension 1 value "GLOBALDIM1"
        // [GIVEN] Customer "CUST2" with global dimension 2 value "GLOBALDIM2"
        Customer[1].Get(CreateCustomerWithDefGlobalDim(1));
        Customer[2].Get(CreateCustomerWithDefGlobalDim(2));

        // [GIVEN] New job "J" with Bill-to Customer No. = "CUST1"
        CreateJob(Job);
        Job.Validate("Bill-to Customer No.", Customer[1]."No.");
        Job.Validate("Job Posting Group", LibraryJob.FindJobPostingGroup());
        Job.Modify(true);

        // [GIVEN] Job tasks "JT1" - "JT3"
        for i := 1 to 3 do
            LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Job Bill-to Customer No. is being changed to "CUST2"
        Job.Validate("Bill-to Customer No.", Customer[2]."No.");

        // [THEN] Job "J" has global dimension 1 value empty
        Job.TestField("Global Dimension 1 Code", '');
        // [THEN] Job "J" has global dimension 2 "GLOBALDIM2"
        Job.TestField("Global Dimension 2 Code", Customer[2]."Global Dimension 2 Code");

        // [THEN] Job tasks "JT1" - "JT3" have global dimension 1 value empty
        // [THEN] Job tasks "JT1" - "JT3" have global dimension 2 "GLOBALDIM2"
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindSet();
        repeat
            JobTask.TestField("Global Dimension 1 Code", '');
            JobTask.TestField("Global Dimension 2 Code", Customer[2]."Global Dimension 2 Code");
        until JobTask.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateJobFromCustomerWithDim()
    var
        Job: Record Job;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 282994] Customer default dimensions copied to job default dimensions when job created from customer card
        Initialize();

        // [GIVEN] Customer "CUST" with set of default dimensions "DIMSET"
        CustomerNo := CreateCustomerWithDefDim();

        // [GIVEN] Mock creating job from customer card
        Job.Init();
        Job.SetFilter("Bill-to Customer No.", CustomerNo);

        // [WHEN] Job is being inserted
        Job.Insert(true);

        // [THEN] Job "J" has same set of default dimensions "DIMSET"
        VerifyJobDefaultDimensionsFromCustDefaultDimensions(Job."No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure KeepBillToInSyncWithSellTo()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        // [SCENARIO] The bill-to fields should be synced with sell-to fields by default.
        Initialize();

        // [GIVEN] A customer and empty job.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        Job.Init();

        // [WHEN] Setting the sell-to customer.
        Job.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Bill-to fields are synced with sell-to.
        Job.TestField("Bill-to Address", Job."Sell-to Address");
        Job.TestField("Bill-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Bill-to City", Job."Sell-to City");
        Job.TestField("Bill-to Contact", Job."Sell-to Contact");
        Job.TestField("Bill-to Contact No.", Job."Sell-to Contact No.");
        Job.TestField("Bill-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Bill-to County", Job."Sell-to County");
        Job.TestField("Bill-to Name", Job."Sell-to Customer Name");
        Job.TestField("Bill-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Bill-to Customer No.", Job."Sell-to Customer No.");
        Job.TestField("Payment Method Code", Customer."Payment Method Code");
        Job.TestField("Payment Terms Code", Customer."Payment Terms Code");

        // [WHEN] Clearing the sell-to customer.
        Job.Validate("Sell-to Customer No.", '');

        // [THEN] Sell-to and Bill-to fields are cleared.
        Job.TestField("Sell-to Address", '');
        Job.TestField("Sell-to Address 2", '');
        Job.TestField("Sell-to City", '');
        Job.TestField("Sell-to Contact", '');
        Job.TestField("Sell-to Contact No.", '');
        Job.TestField("Sell-to Country/Region Code", '');
        Job.TestField("Sell-to County", '');
        Job.TestField("Sell-to Customer Name", '');
        Job.TestField("Sell-to Customer Name 2", '');

        Job.TestField("Bill-to Address", '');
        Job.TestField("Bill-to Address 2", '');
        Job.TestField("Bill-to City", '');
        Job.TestField("Bill-to Contact", '');
        Job.TestField("Bill-to Contact No.", '');
        Job.TestField("Bill-to Country/Region Code", '');
        Job.TestField("Bill-to County", '');
        Job.TestField("Bill-to Name", '');
        Job.TestField("Bill-to Name 2", '');
        Job.TestField("Bill-to Customer No.", '');
        Job.TestField("Payment Method Code", '');
        Job.TestField("Payment Terms Code", '');
    end;

    [Test]
    [HandlerFunctions('ShipToAddressListModalHandler')]
    procedure UpdateShippingAddressForAlternateShippingOption()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
        ShipToAddress: Record "Ship-to Address";
        JobCardPage: TestPage "Job Card";
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO] The ship-to fields should be updated to alternate address.
        Initialize();

        // [GIVEN] A customer with address and ship-to address and a job with customer assigned.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        AddShipToAddressToCustomer(ShipToAddress, Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryJob.CreateJob(Job, Customer."No.");
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);

        // [WHEN] Setting the Ship-To to "Default (Sell-To address)".
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");

        //[THEN] Ship-To Code is empty
        Job.TestField("Ship-to Code", '');

        // [THEN] Ship-to fields are synced with Sell-To.
        Job.TestField("Ship-to Name", Job."Sell-to Customer Name");
        Job.TestField("Ship-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Ship-to Address", Job."Sell-to Address");
        Job.TestField("Ship-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Ship-to City", Job."Sell-to City");
        Job.TestField("Ship-to County", Job."Sell-to County");
        Job.TestField("Ship-to Post Code", Job."Sell-to Post Code");
        Job.TestField("Ship-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Ship-to Contact", Job."Sell-to Contact");

        // [WHEN] Setting the Ship-To to Alternate address.
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ShipToAddress.Code);
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Alternate Shipping Address"); //Needs ShipToAddressListModalHandler;

        //[THEN] Ship-To Code is updated
        Job.Get(Job."No.");
        Job.TestField("Ship-to Code", ShipToAddress.Code);

        // [THEN] Ship-To fields is updated with alternative shipping address.
        Job.TestField("Ship-to Name", ShipToAddress.Name);
        Job.TestField("Ship-to Name 2", ShipToAddress."Name 2");
        Job.TestField("Ship-to Address", ShipToAddress.Address);
        Job.TestField("Ship-to Address 2", ShipToAddress."Address 2");
        Job.TestField("Ship-to City", ShipToAddress.City);
        Job.TestField("Ship-to County", ShipToAddress.County);
        Job.TestField("Ship-to Post Code", ShipToAddress."Post Code");
        Job.TestField("Ship-to Country/Region Code", ShipToAddress."Country/Region Code");
        Job.TestField("Ship-to Contact", ShipToAddress."Contact");
    end;

    [Test]
    [HandlerFunctions('ShipToAddressListModalHandler')]
    procedure UpdateShippingAddressForCustomShippingOption()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
        ShipToAddress: Record "Ship-to Address";
        JobCardPage: TestPage "Job Card";
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO] The ship-to fields should be updated to custom address.
        Initialize();

        // [GIVEN] A customer with address and ship-to address and a job with customer assigned.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        AddShipToAddressToCustomer(ShipToAddress, Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryJob.CreateJob(Job, Customer."No.");
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);

        // [WHEN] Setting the Ship-To to Alternate address.
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(ShipToAddress.Code);
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Alternate Shipping Address"); //Needs ShipToAddressListModalHandler;

        //[THEN] Ship-To Code is updated
        Job.Get(Job."No.");
        Job.TestField("Ship-to Code", ShipToAddress.Code);

        // [THEN] Ship-To fields is updated with alternative shipping address.
        Job.TestField("Ship-to Name", ShipToAddress.Name);
        Job.TestField("Ship-to Name 2", ShipToAddress."Name 2");
        Job.TestField("Ship-to Address", ShipToAddress.Address);
        Job.TestField("Ship-to Address 2", ShipToAddress."Address 2");
        Job.TestField("Ship-to City", ShipToAddress.City);
        Job.TestField("Ship-to County", ShipToAddress.County);
        Job.TestField("Ship-to Post Code", ShipToAddress."Post Code");
        Job.TestField("Ship-to Country/Region Code", ShipToAddress."Country/Region Code");
        Job.TestField("Ship-to Contact", ShipToAddress."Contact");

        // [WHEN] Setting the Ship-To to Custom address.
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Custom Address");
        JobCardPage.OK().Invoke(); //To prevent delayed insert

        //[THEN] Ship-To Code is set to empty
        Job.Get(Job."No.");
        Job.TestField("Ship-to Code", '');

        // [THEN] Ship-To fields are not updated.
        Job.TestField("Ship-to Name", ShipToAddress.Name);
        Job.TestField("Ship-to Name 2", ShipToAddress."Name 2");
        Job.TestField("Ship-to Address", ShipToAddress.Address);
        Job.TestField("Ship-to Address 2", ShipToAddress."Address 2");
        Job.TestField("Ship-to City", ShipToAddress.City);
        Job.TestField("Ship-to County", ShipToAddress.County);
        Job.TestField("Ship-to Post Code", ShipToAddress."Post Code");
        Job.TestField("Ship-to Country/Region Code", ShipToAddress."Country/Region Code");
        Job.TestField("Ship-to Contact", ShipToAddress."Contact");

        // [WHEN] Setting the Ship-To to Default address.
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");
        JobCardPage.OK().Invoke(); //To prevent delayed insert

        //[THEN] Ship-To Code is empty
        Job.Get(Job."No.");
        Job.TestField("Ship-to Code", '');

        // [THEN] Ship-to fields are synced with Sell-To.
        Job.TestField("Ship-to Name", Job."Sell-to Customer Name");
        Job.TestField("Ship-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Ship-to Address", Job."Sell-to Address");
        Job.TestField("Ship-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Ship-to City", Job."Sell-to City");
        Job.TestField("Ship-to County", Job."Sell-to County");
        Job.TestField("Ship-to Post Code", Job."Sell-to Post Code");
        Job.TestField("Ship-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Ship-to Contact", Job."Sell-to Contact");

        // [WHEN] Setting the Ship-To to Custom address.
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Custom Address");
        JobCardPage.OK().Invoke(); //To prevent delayed insert

        //[THEN] Ship-To Code is set to empty
        Job.Get(Job."No.");
        Job.TestField("Ship-to Code", '');

        // [THEN] Ship-To fields are not updated.
        Job.TestField("Ship-to Name", Job."Sell-to Customer Name");
        Job.TestField("Ship-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Ship-to Address", Job."Sell-to Address");
        Job.TestField("Ship-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Ship-to City", Job."Sell-to City");
        Job.TestField("Ship-to County", Job."Sell-to County");
        Job.TestField("Ship-to Post Code", Job."Sell-to Post Code");
        Job.TestField("Ship-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Ship-to Contact", Job."Sell-to Contact");
    end;

    local procedure AddShipToAddressToCustomer(var ShipToAddress: Record "Ship-to Address"; var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate(Address, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ShipToAddress.Address)));
        ShipToAddress.Validate("Address 2", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ShipToAddress."Address 2")));
        LibraryERM.CreatePostCode(PostCode);
        ShipToAddress.Validate("Country/Region Code", PostCode."Country/Region Code");
        ShipToAddress.Validate(City, PostCode.City);
        ShipToAddress.Validate(County, PostCode.County);
        ShipToAddress.Validate("Post Code", PostCode.Code);
        ShipToAddress.Modify(true);
    end;

    [Test]
    procedure WhenSettingBillToSyncSellToWithBillToIfEmpty()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        // [SCENARIO] When setting bill-to, the sell-to fields should be synced with bill-to if 
        //  no sell-to customer has been set.
        Initialize();

        // [GIVEN] A customer and empty job.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        Job.Init();

        // [WHEN] Setting the bill-to customer.
        Job.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Sell-to fields are synced with bill-to.
        Job.TestField("Sell-to Address", Job."Bill-to Address");
        Job.TestField("Sell-to Address 2", Job."Bill-to Address 2");
        Job.TestField("Sell-to City", Job."Bill-to City");
        Job.TestField("Sell-to Contact", Job."Bill-to Contact");
        Job.TestField("Sell-to Contact No.", Job."Bill-to Contact No.");
        Job.TestField("Sell-to Country/Region Code", Job."Bill-to Country/Region Code");
        Job.TestField("Sell-to County", Job."Bill-to County");
        Job.TestField("Sell-to Customer Name", Job."Bill-to Name");
        Job.TestField("Sell-to Customer Name 2", Job."Bill-to Name 2");
        Job.TestField("Sell-to Customer No.", Job."Bill-to Customer No.");
        Job.TestField("Payment Method Code", Customer."Payment Method Code");
        Job.TestField("Payment Terms Code", Customer."Payment Terms Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure BreakBillToSellToSyncWhenChangingBillTo()
    var
        Job: Record Job;
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        // [SCENARIO] We should stop syncing bill-to with sell-to if we change bill-to customer.
        Initialize();

        // [GIVEN] A sell-to/bill-to customer and empty job.
        LibraryMarketing.CreateContactWithCustomer(SellToContact, SellToCustomer);
        LibrarySales.CreateCustomerAddress(SellToCustomer);
        SellToCustomer.Validate("Primary Contact No.", SellToContact."No.");
        SellToCustomer.Modify(true);

        LibraryMarketing.CreateContactWithCustomer(BillToContact, BillToCustomer);
        LibrarySales.CreateCustomerAddress(BillToCustomer);
        BillToCustomer.Validate("Primary Contact No.", BillToContact."No.");

        // [GIVEN] Bill-To customer with different payment terms and method.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        BillToCustomer."Payment Terms Code" := PaymentTerms.Code;
        BillToCustomer."Payment Method Code" := PaymentMethod.Code;
        BillToCustomer.Modify(true);

        Job.Init();

        // [WHEN] Setting the sell-to customer.
        Job.Validate("Sell-to Customer No.", SellToCustomer."No.");

        // [THEN] Bill-to fields are synced with sell-to.
        Job.TestField("Bill-to Address", Job."Sell-to Address");
        Job.TestField("Bill-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Bill-to City", Job."Sell-to City");
        Job.TestField("Bill-to Contact No.", SellToContact."No.");
        Job.TestField("Bill-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Bill-to County", Job."Sell-to County");
        Job.TestField("Bill-to Name", Job."Sell-to Customer Name");
        Job.TestField("Bill-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Bill-to Customer No.", Job."Sell-to Customer No.");
        Job.TestField("Payment Method Code", SellToCustomer."Payment Method Code");
        Job.TestField("Payment Terms Code", SellToCustomer."Payment Terms Code");

        // [WHEN] Changing the bill-to customer.
        Job.Validate("Bill-to Customer No.", BillToCustomer."No.");

        // [THEN] Bill-to fields are no longer synced with sell-to.
        Job.TestField("Sell-to Address", SellToCustomer.Address);
        Job.TestField("Sell-to Address 2", SellToCustomer."Address 2");
        Job.TestField("Sell-to City", SellToCustomer.City);
        Job.TestField("Sell-to Contact No.", SellToContact."No.");
        Job.TestField("Sell-to Country/Region Code", SellToCustomer."Country/Region Code");
        Job.TestField("Sell-to County", SellToCustomer.County);
        Job.TestField("Sell-to Customer Name", SellToCustomer.Name);
        Job.TestField("Sell-to Customer Name 2", SellToCustomer."Name 2");

        Job.TestField("Bill-to Address", BillToCustomer.Address);
        Job.TestField("Bill-to Address 2", BillToCustomer."Address 2");
        Job.TestField("Bill-to City", BillToCustomer.City);
        Job.TestField("Bill-to Contact No.", BillToContact."No.");
        Job.TestField("Bill-to Country/Region Code", BillToCustomer."Country/Region Code");
        Job.TestField("Bill-to County", BillToCustomer.County);
        Job.TestField("Bill-to Name", BillToCustomer.Name);
        Job.TestField("Bill-to Name 2", BillToCustomer."Name 2");

        Job.TestField("Payment Method Code", BillToCustomer."Payment Method Code");
        Job.TestField("Payment Terms Code", BillToCustomer."Payment Terms Code");
    end;

    [Test]
    procedure JobCardLinesEditable()
    var
        Job: Record Job;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 429325] The job task lines subpage is editable when "Bill-to Customer No." is specified
        // Subpage.editable does not work for test page now, so this is UT for function CalcJobTaskLinesEditable
        Initialize();

        // [WHEN] New job "J01" with empty customer number
        CreateJob(Job);
        Job.TestField("Bill-to Customer No.", '');

        // [THEN] CalcJobTaskLinesEditable returns false
        Assert.IsFalse(Job.CalcJobTaskLinesEditable(), 'JobTaskLines must be not editable');

        // [WHEN] "Bill-to Customer No." is specified
        Job.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        // [THEN] CalcJobTaskLinesEditable returns true
        Assert.IsTrue(Job.CalcJobTaskLinesEditable(), 'JobTaskLines must be editable');
    end;

    [Test]
    procedure CheckBlockedCustomerOnJob()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
        ExpectedErr: Text;
    begin
        // [SCENARIO 445521] The bill-to fields should be synced with sell-to fields by default.
        Initialize();

        // [GIVEN] A customer with blocked as All
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify(true);
        Job.Init();

        // [WHEN] Setting the sell-to customer.
        asserterror Job.Validate("Sell-to Customer No.", Customer."No.");
        ExpectedErr := StrSubstNo(CustomerBlockedErr, Customer."No.", Customer.Blocked);

        // [THEN] Error should appear that customer is blocked
        Assert.AreEqual(ExpectedErr, GetLastErrorText(), BlockedCustomerExpectedErr);
    end;

    [Test]
    [HandlerFunctions('CustomerLookupModalHandler,ConfirmHandlerYes')]
    procedure S463319_SwitchSellToCustomerNameToCustomerWithTheSameName()
    var
        Job: Record Job;
        SellToCustomer: array[2] of Record Customer;
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [Job Card] [Customer]
        // [SCENARIO 463319] Switch Customer Name in Job card (by using lookup & select) for a Customer with the same Name but different No.
        Initialize();

        // [GIVEN] Create customer "1" with random Name.
        LibrarySales.CreateCustomer(SellToCustomer[1]);
        SellToCustomer[1].Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(SellToCustomer[1].Name)));
        SellToCustomer[1].Modify(true);

        // [GIVEN] Create customers "2", with the same Name as customer "1" and random Address.
        LibrarySales.CreateCustomer(SellToCustomer[2]);
        SellToCustomer[2].Validate(Name, SellToCustomer[1].Name);
        SellToCustomer[2].Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(SellToCustomer[2].Address)));
        SellToCustomer[2].Modify(true);

        // [GIVEN] Create Job for customer "1".
        LibraryJob.CreateJob(Job, SellToCustomer[1]."No.");
        JobCard.OpenEdit();
        JobCard.GoToRecord(Job);

        // [WHEN] Switch Job to customer "2" via "Sell-to Customer Name".
        LibraryVariableStorage.Enqueue(SellToCustomer[2]."No.");
        JobCard."Sell-to Customer Name".Lookup(); // Uses CustomerLookupModalHandler handler.
        Job.Validate("Sell-to Customer Name", SellToCustomer[2].Name); // Uses ConfirmHandlerYes handler.
        Job.Modify(true);
        JobCard.Close();

        // [THEN] Verify that Job is switched customer "2".
        Job.TestField("Sell-to Customer No.", SellToCustomer[2]."No.");
        Job.TestField("Sell-to Address", SellToCustomer[2].Address);
        Job.TestField("Bill-to Address", SellToCustomer[2].Address);
    end;

    [Test]
    procedure VerifyJobShipToCityUpdatedWhenShipToPostCodeValueChanged()
    var
        Job: Record Job;
        Customer: Record Customer;
        Contact: Record Contact;
        ShipToAddress: Record "Ship-to Address";
        PostCode: Record "Post Code";
        JobCardPage: TestPage "Job Card";
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO 466244] The "Ship-to Post Code" field does not update the State and City fields when updated as the "Bill-to Post Code" does.
        Initialize();

        // [GIVEN] A contact with customer and address.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        LibrarySales.CreateCustomerAddress(Customer);

        // [GIVEN] Add ship-to address and customer primary contact.
        AddShipToAddressToCustomer(ShipToAddress, Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);

        // [GIVEN] Create job with customer assigned.
        LibraryJob.CreateJob(Job, Customer."No.");

        // [THEN] Open Job Card.
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);

        // [WHEN] Setting the Ship-To to "Default (Sell-To address)".
        JobCardPage.ShippingOptions.SetValue(ShipToOptions::"Custom Address");

        // [GIVEN] Create new Post Code.
        LibraryERM.CreatePostCode(PostCode);

        // [THEN] Update Job Ship-To Code with newly create Post Code.
        Job.Validate("Ship-to Post Code", PostCode.Code);

        // [VERIFY] Verify: Job Ship-to City and Post Code city are equal.
        Assert.IsTrue((PostCode.City = Job."Ship-to City"), StrSubstNo(ShipToCityNotMatchedErr, Job.FieldCaption("Ship-to City"), PostCode.City));
    end;

    [Test]
    procedure JobSellToContactNoValidation()
    var
        Job: Record Job;
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [FEATURE] [Job] [Customer] [Contact]
        // [SCENARIO] When setting Sell-to Contact No., Customer and Contact data should be validated
        Initialize();

        // [GIVEN] Create Customer with Company Contact
        LibraryMarketing.CreateContactWithCustomer(CompanyContact, Customer);
        CompanyContact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        CompanyContact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        CompanyContact.Modify(true);

        // Refresh Customer record
        Customer.GetBySystemId(Customer.SystemId);

        // [GIVEN] Create Contact person for Customer
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        PersonContact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        PersonContact.Modify(true);

        // [GIVEN] Create empty Job
        Job.Init();

        // [WHEN] Set Company Contact as Sell-to Contact No.
        Job.Validate("Sell-to Contact No.", CompanyContact."No.");

        // [THEN] Sell-to fields and Bill-to Customer fields are set
        Job.TestField("Sell-to Customer No.", Customer."No.");
        Job.TestField("Sell-to Customer Name", Customer."Name");
        Job.TestField("Sell-to Customer Name 2", Customer."Name 2");
        Job.TestField("Sell-to Address", Customer."Address");
        Job.TestField("Sell-to Address 2", Customer."Address 2");
        Job.TestField("Sell-to City", Customer."City");
        Job.TestField("Sell-to Country/Region Code", Customer."Country/Region Code");
        Job.TestField("Sell-to County", Customer."County");
        Job.TestField("Sell-to Phone No.", CompanyContact."Phone No.");
        Job.TestField("Sell-to E-Mail", CompanyContact."E-Mail");
        Job.TestField("Payment Method Code", Customer."Payment Method Code");
        Job.TestField("Payment Terms Code", Customer."Payment Terms Code");
        Job.TestField("Bill-to Customer No.", Job."Sell-to Customer No.");
        Job.TestField("Bill-to Name", Job."Sell-to Customer Name");
        Job.TestField("Bill-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Bill-to Address", Job."Sell-to Address");
        Job.TestField("Bill-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Bill-to City", Job."Sell-to City");
        Job.TestField("Bill-to Contact", Job."Sell-to Contact");
        Job.TestField("Bill-to Contact No.", Job."Sell-to Contact No.");
        Job.TestField("Bill-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Bill-to County", Job."Sell-to County");

        // [WHEN] Set Person Contact as Sell-to Contact No.
        Job.Validate("Sell-to Contact No.", PersonContact."No.");

        // [THEN] Sell-to fields and Bill-to Customer fields are updated
        Job.TestField("Sell-to Customer No.", Customer."No.");
        Job.TestField("Sell-to Customer Name", Customer."Name");
        Job.TestField("Sell-to Customer Name 2", Customer."Name 2");
        Job.TestField("Sell-to Address", Customer."Address");
        Job.TestField("Sell-to Address 2", Customer."Address 2");
        Job.TestField("Sell-to City", Customer."City");
        Job.TestField("Sell-to Country/Region Code", Customer."Country/Region Code");
        Job.TestField("Sell-to County", Customer."County");
        Job.TestField("Sell-to Phone No.", PersonContact."Phone No.");
        Job.TestField("Sell-to E-Mail", PersonContact."E-Mail");
        Job.TestField("Payment Method Code", Customer."Payment Method Code");
        Job.TestField("Payment Terms Code", Customer."Payment Terms Code");
        Job.TestField("Bill-to Customer No.", Job."Sell-to Customer No.");
        Job.TestField("Bill-to Name", Job."Sell-to Customer Name");
        Job.TestField("Bill-to Name 2", Job."Sell-to Customer Name 2");
        Job.TestField("Bill-to Address", Job."Sell-to Address");
        Job.TestField("Bill-to Address 2", Job."Sell-to Address 2");
        Job.TestField("Bill-to City", Job."Sell-to City");
        Job.TestField("Bill-to Contact", Job."Sell-to Contact");
        Job.TestField("Bill-to Contact No.", Job."Sell-to Contact No.");
        Job.TestField("Bill-to Country/Region Code", Job."Sell-to Country/Region Code");
        Job.TestField("Bill-to County", Job."Sell-to County");
    end;

    [Test]
    procedure BinCodeFromLocationIsPulledOnValidateLocation()
    var
        Job: Record Job;
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [SCENARIO 457693] Verify Bin Code from Location is pulled on validate Location on Job
        Initialize();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create Location with mandatory Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create Bin for Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Set Bin to To-Project Bin Code on Location
        Location.Validate("To-Job Bin Code", Bin.Code);
        Location.Modify(true);

        // [WHEN] Set Location on Job
        Job.Validate("Location Code", Location.Code);

        // [THEN] Verify results
        Assert.AreEqual(Job."Bin Code", Bin.Code, StrSubstNo(BinCodeNotMatchedErr, Job."Bin Code", Bin.Code));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure MessageOccursOnUpdateLocationOnJobIfJobTaskExist()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [SCENARIO 457693] Verify message occurs on update Location on Job if Job Task exist
        Initialize();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);
        LibraryVariableStorage.Enqueue(Database::Job);
        LibraryVariableStorage.Enqueue(Job.FieldCaption("Location Code"));

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Location with mandatory Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create Bin for Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Set Bin to To-Project Bin Code on Location
        Location.Validate("To-Job Bin Code", Bin.Code);
        Location.Modify(true);

        // [WHEN] Set Location on Job
        Job.Validate("Location Code", Location.Code);

        // [THEN] Verify results
    end;

    [Test]
    procedure LocationAndBinCodeOnJobTaskIfLocationAndBinExistOnJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [SCENARIO 457693] Verify Location and Bin Code on Job Task if Location and Bin exist on Job
        Initialize();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create Location with mandatory Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create Bin for Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Set Bin to To-Project Bin Code on Location
        Location.Validate("To-Job Bin Code", Bin.Code);
        Location.Modify(true);

        // [WHEN] Set Location on Job
        Job.Validate("Location Code", Location.Code);
        Job.Modify(true);

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [THEN] Verify results
        Assert.AreEqual(JobTask."Location Code", Location.Code, StrSubstNo(LocationCodeNotMatchedErr, JobTask."Location Code", Location.Code));
        Assert.AreEqual(JobTask."Bin Code", Bin.Code, StrSubstNo(BinCodeNotMatchedErr, JobTask."Bin Code", Bin.Code));
    end;

    [Test]
    procedure LocationAndBinCodeOnJobPlanningLineIfLocationAndBinExistOnJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [SCENARIO 457693] Verify Location and Bin Code on Job Planning Line if Location and Bin exist on Job Task
        Initialize();

        // [GIVEN] Create Job
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Location with mandatory Bin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create Bin for Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');

        // [GIVEN] Set Bin to To-Project Bin Code on Location
        Location.Validate("To-Job Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Set Location on Job
        JobTask.Validate("Location Code", Location.Code);
        JobTask.Modify(true);

        // [WHEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", LibraryInventory.CreateItemNo());
        JobPlanningLine.Modify(true);

        // [THEN] Verify results
        Assert.AreEqual(JobPlanningLine."Location Code", Location.Code, StrSubstNo(LocationCodeNotMatchedErr, JobPlanningLine."Location Code", Location.Code));
        Assert.AreEqual(JobPlanningLine."Bin Code", Bin.Code, StrSubstNo(BinCodeNotMatchedErr, JobPlanningLine."Bin Code", Bin.Code));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        JobBatchJobs: Codeunit "Job Batch Jobs";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        JobBatchJobs.SetJobNoSeries(JobsSetup, NoSeries);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job");
    end;

    local procedure SetUp(ApplyUsageLink: Boolean)
    var
        JobWIPMethod: Record "Job WIP Method";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        JobWIPMethod.FindFirst();
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobPlanningLine);
        asserterror Error(RollingBackChangesErr);
        IsInitialized := false;
    end;

    local procedure CreateCustomerWithDefDim() CustNo: Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        CustNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 3 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustNo, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure CreateCustomerWithDefGlobalDim(DimIndex: Integer) CustNo: Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        CustNo := LibrarySales.CreateCustomerNo();
        GLSetup.Get();
        case DimIndex of
            1:
                begin
                    Dimension.Get(GLSetup."Global Dimension 1 Code");
                    LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
                end;
            2:
                begin
                    Dimension.Get(GLSetup."Global Dimension 2 Code");
                    LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
                end;
        end;

        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateJobWIPMethod(var JobWIPMethod: Record "Job WIP Method"; WIPCost: Boolean; WIPSales: Boolean)
    begin
        JobWIPMethod.Init();
        JobWIPMethod.Code := 'UTTJOB';
        JobWIPMethod."WIP Cost" := WIPCost;
        JobWIPMethod."WIP Sales" := WIPSales;
        JobWIPMethod.Insert(true);
    end;

    local procedure CreateJobPlanningLineInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; Qty: Decimal)
    begin
        JobPlanningLineInvoice.Init();
        JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
        JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
        JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Invoice";
        JobPlanningLineInvoice."Document No." := 'TEST';
        JobPlanningLineInvoice."Line No." := 10000;
        JobPlanningLineInvoice."Quantity Transferred" := Qty;
        JobPlanningLineInvoice."Transferred Date" := WorkDate();
        JobPlanningLineInvoice.Insert();
    end;

    local procedure CreateReservEntry(var ReservEntry: Record "Reservation Entry"; TableID: Integer; SourceID: Code[20])
    var
        RecRef: RecordRef;
    begin
        with ReservEntry do begin
            Init();
            RecRef.GetTable(ReservEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Source Type" := TableID;
            "Source Subtype" := LibraryRandom.RandInt(5);
            "Source ID" := SourceID;
            "Source Ref. No." := LibraryRandom.RandInt(100);
            Insert();
        end;
    end;

    local procedure CreateJob(var Job: Record Job)
    begin
        Job.Init();
        Job."No." := LibraryUtility.GenerateGUID();
        Job.Insert();
    end;

    local procedure MockTimeSheetWithLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        with TimeSheetHeader do begin
            Init();
            "No." := LibraryUtility.GenerateGUID();
            "Owner User ID" := UserId;
            "Starting Date" := WorkDate();
            "Ending Date" := WorkDate() + 7;
            Insert();
        end;

        with TimeSheetLine do begin
            Init();
            "Time Sheet No." := TimeSheetHeader."No.";
            "Line No." := 10000;
            Type := Type::Job;
            "Job No." := Job."No.";
            Status := Status::Open;
            Insert();
        end;
    end;

    local procedure MockUser(): Code[50]
    var
        UserSetup: Record "User Setup";
    begin
        with UserSetup do begin
            Init();
            Validate("User ID", LibraryUtility.GenerateGUID());
            Insert(true);
            exit("User ID");
        end;
    end;

    local procedure ValidateJobProjectManagerWithPage(Job: Record Job; ProjectManager: Code[50])
    var
        JobCard: TestPage "Job Card";
    begin
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard."Project Manager".SetValue(ProjectManager);
        JobCard.Close();
    end;

    local procedure UpdateTimeSheetLineStatus(var TimeSheetLine: Record "Time Sheet Line"; NewStatus: Enum "Time Sheet Status")
    begin
        TimeSheetLine.Status := NewStatus;
        TimeSheetLine.Modify();
    end;

    local procedure UpdateJobGlobalDimensionCode(var Job: Record Job; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    begin
        Job.Validate("Global Dimension 1 Code", DimValue1Code);
        Job.Validate("Global Dimension 2 Code", DimValue2Code);
    end;

    local procedure SetTotalCostLCYInJobPlanningLine(TotalCostLCY: Decimal)
    begin
        JobPlanningLine.Validate("Total Cost (LCY)", TotalCostLCY);
        JobPlanningLine.Modify(true);
    end;

    local procedure MockJobLedgEntryWithTotalCostLCY(JobNo: Code[20]; UsageCost: Decimal)
    var
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        with JobLedgEntry do begin
            Init();
            "Entry No." :=
              LibraryUtility.GetNewRecNo(JobLedgEntry, FieldNo("Entry No."));
            Validate("Job No.", JobNo);
            "Total Cost (LCY)" := UsageCost;
            Insert();
        end;
    end;

    local procedure GetRandomSetOfDecimalsWithDelta(var FirstDecimal: Decimal; var SecondDecimal: Decimal; var ThirdDecimal: Decimal; Delta: Decimal)
    begin
        FirstDecimal := LibraryRandom.RandDec(100, 2);
        SecondDecimal := LibraryRandom.RandDec(100, 2);
        ThirdDecimal := FirstDecimal + SecondDecimal + Delta;
    end;

    local procedure InvokeUpdateOverBudgetValueFunctionWithVerification(UsageCost: Boolean; InputCost: Decimal; ExpectedResult: Boolean)
    begin
        Job.UpdateOverBudgetValue(Job."No.", UsageCost, InputCost);
        Job.TestField("Over Budget", ExpectedResult);
    end;

    local procedure VerifyJobTaskDimension(JobTask: Record "Job Task"; DimensionCode: Code[20]; DimValueCode: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        Assert.IsTrue(
          JobTaskDimension.Get(JobTask."Job No.", JobTask."Job Task No.", DimensionCode), JobTaskDimDoesNotExistErr);
        Assert.AreEqual(
          DimValueCode, JobTaskDimension."Dimension Value Code", JobTaskDimension.FieldCaption("Dimension Value Code"));
    end;

    local procedure VerifyJobTaskDimDoesNotExist(JobTask: Record "Job Task")
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.SetRange("Job No.", JobTask."Job No.");
        JobTaskDimension.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.IsTrue(JobTaskDimension.IsEmpty, JobTaskDimExistsErr);
    end;

    local procedure VerifyJobTaskGlobalDimensions(var JobTask: Record "Job Task"; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    begin
        JobTask.Find();
        Assert.AreEqual(
          DimValue1Code, JobTask."Global Dimension 1 Code", JobTask.FieldCaption("Global Dimension 1 Code"));
        Assert.AreEqual(
          DimValue2Code, JobTask."Global Dimension 2 Code", JobTask.FieldCaption("Global Dimension 2 Code"));
    end;

    local procedure VerifyJobDefaultDimensionsFromCustDefaultDimensions(JobNo: Code[20]; CustomerNo: Code[20])
    var
        JobDefaultDimension: Record "Default Dimension";
        CustDefaultDimension: Record "Default Dimension";
    begin
        CustDefaultDimension.SetRange("Table ID", DATABASE::Customer);
        CustDefaultDimension.SetRange("No.", CustomerNo);
        CustDefaultDimension.FindSet();
        repeat
            JobDefaultDimension.Get(DATABASE::Job, JobNo, CustDefaultDimension."Dimension Code");
            JobDefaultDimension.TestField("Dimension Value Code", CustDefaultDimension."Dimension Value Code");
        until CustDefaultDimension.Next() = 0;
    end;

    local procedure VerifyJobTaskDimensionsFromCustDefaultDimensions(CustomerNo: Code[20]; JobTask: Record "Job Task")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", CustomerNo);
        DefaultDimension.FindSet();
        repeat
            VerifyJobTaskDimension(JobTask, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until DefaultDimension.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job", 'OnAfterModifyEvent', '', false, false)]
    local procedure InsertNameValueBufferOnJobModify(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.ID :=
          LibraryUtility.GetNewRecNo(NameValueBuffer, NameValueBuffer.FieldNo(ID));
        NameValueBuffer.Name := Rec."No.";
        NameValueBuffer.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmFalseHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure ShipToAddressListModalHandler(var ShipToAddressList: TestPage "Ship-to Address List")
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        ShipToAddress.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        ShipToAddressList.GoToRecord(ShipToAddress);
        ShipToAddressList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupModalHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Text;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            Database::Job:
                begin
                    ExpectedMessage := StrSubstNo(TasksNotUpdatedMsg, LibraryVariableStorage.DequeueText());
                    ExpectedMessage := StrSubstNo(SplitMessageTxt, ExpectedMessage, UpdateTasksManuallyMsg);
                end;
            Database::"Job Task":
                begin
                    ExpectedMessage := StrSubstNo(PlanningLinesNotUpdatedMsg, LibraryVariableStorage.DequeueText());
                    ExpectedMessage := StrSubstNo(SplitMessageTxt, ExpectedMessage, UpdatePlanningLinesManuallyMsg);
                end;
        end;
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;
}

