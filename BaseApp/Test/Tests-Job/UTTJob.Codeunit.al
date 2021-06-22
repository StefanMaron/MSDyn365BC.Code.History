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
        IsInitialized: Boolean;
        IncorrectSourceIDErr: Label 'Incorrect Source ID.';
        JobTaskDimDoesNotExistErr: Label 'Job Task Dimension does not exist.';
        JobTaskDimExistsErr: Label 'Job Task Dimension exists.';
        TimeSheetLinesErr: Label 'You cannot delete job %1 because it has open or submitted time sheet lines.', Comment = 'You cannot delete job JOB001 because it has open or submitted time sheet lines.';

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
        Initialize;
        JobsSetup.Get;
        JobsSetup.Validate("Apply Usage Link by Default", false);
        JobsSetup.Validate("Allow Sched/Contract Lines Def", false);
        JobsSetup.Modify;
        LibraryJob.CreateJob(Job);
        Assert.IsFalse(Job."Apply Usage Link", 'Apply Usage link is not FALSE by default.');
        Assert.IsFalse(Job."Allow Schedule/Contract Lines", 'Allow Schedule/Contract Lines is not FALSE by default.');

        TearDown;

        // Verify that Apply Usage Link and Allow Schedule/Contract Lines are set by default, if set in Jobs Setup.
        Initialize;
        JobsSetup.Get;
        JobsSetup.Validate("Apply Usage Link by Default", true);
        JobsSetup.Validate("Allow Sched/Contract Lines Def", true);
        JobsSetup.Modify;
        LibraryJob.CreateJob(Job);
        Assert.IsTrue(Job."Apply Usage Link", 'Apply Usage link is not TRUE by default.');
        Assert.IsTrue(Job."Allow Schedule/Contract Lines", 'Allow Schedule/Contract Lines is not TRUE by default.');

        // Verify that the Default WIP Method is set by default, if set in Jobs Setup.
        JobsSetup.Get;
        LibraryJob.GetJobWIPMethod(JobWIPMethod, Method::"Cost Value");
        JobsSetup.Validate("Default WIP Method", JobWIPMethod.Code);
        JobsSetup.Validate("Default WIP Posting Method", JobsSetup."Default WIP Posting Method"::"Per Job Ledger Entry");
        JobsSetup.Modify;
        LibraryJob.CreateJob(Job);
        Assert.AreEqual(Job."WIP Method", JobWIPMethod.Code, 'The WIP Method is not set to the correct default value.');

        // Verify that the Default WIP Posting Method is set by default, if set in Jobs Setup.
        Assert.AreEqual(Job."WIP Posting Method"::"Per Job Ledger Entry", Job."WIP Posting Method",
          'The WIP Posting Method is not set to the correct default value.');

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldApplyUsageLink()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryJob: Codeunit "Library - Job";
    begin
        Initialize;
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
        Assert.IsFalse(JobPlanningLine.FindFirst, 'Some Job Planning Lines were not updated with Usage Link.');

        // Verify that Apply Usage Link cannot be checked, once Usage has been posted.
        Job.Validate("Apply Usage Link", false);
        Job.Modify;
        JobLedgerEntry.Init;
        JobLedgerEntry."Job No." := Job."No.";
        JobLedgerEntry.Insert;

        asserterror Job.Validate("Apply Usage Link", true);

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPWarnings()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize;
        SetUp(true);

        // Verify that WIP Warnings is false when no warnings exist.
        Assert.IsFalse(Job."WIP Warnings", 'WIP Warning is true, even if no warnings exist.');

        // Verify that WIP Warnings is true when warnings exist.
        JobWIPWarning.Init;
        JobWIPWarning."Job No." := Job."No.";
        JobWIPWarning.Insert;
        Job.CalcFields("WIP Warnings");
        Assert.IsTrue(Job."WIP Warnings", 'WIP Warning is false, even if warnings exist.');

        TearDown;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestFieldWIPMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize;
        SetUp(true);

        // Verify that update of WIP Method is reflected on Job Tasks as well.
        JobWIPMethod.FindFirst;
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindFirst;
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Modify;
        Job.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.FindFirst;
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

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPPostingMethod()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize;
        SetUp(true);

        with Job do begin
            // Validate that WIP Posting Method can't be changed back to Per Job, once entries have been posted with Per Job Ledger Entry.
            Validate("WIP Posting Method", "WIP Posting Method"::"Per Job Ledger Entry");
            JobLedgerEntry.Init;
            JobLedgerEntry."Job No." := "No.";
            JobLedgerEntry."Amt. Posted to G/L" := LibraryRandom.RandInt(1000);
            JobLedgerEntry.Insert;
            asserterror Validate("WIP Posting Method", "WIP Posting Method"::"Per Job");

            // Validate that WIP Posting Method can't be changed, if Job WIP Entries exist.
            Clear(JobWIPEntry);
            JobWIPEntry.Init;
            if JobWIPEntry.FindLast then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert;
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

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionsCalcRecognized()
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        Initialize;
        SetUp(true);

        // Verify that CalcAccWIPCostsAmount, CalcAccWIPSalesAmount, CalcRecognizedProfitAmount, CalcRecognizedProfitPercentage,
        // CalcRecognizedProfitGLAmount and CalcRecognProfitGLPercentage calculate the correct amount.
        with Job do begin
            Clear(JobWIPEntry);
            JobWIPEntry.Init;
            if JobWIPEntry.FindLast then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry.Type := JobWIPEntry.Type::"Recognized Costs";
            JobWIPEntry.Reverse := false;
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert;

            Clear(JobWIPEntry);
            JobWIPEntry.Init;
            if JobWIPEntry.FindLast then
                JobWIPEntry."Entry No." += 1
            else
                JobWIPEntry."Entry No." := 1;
            JobWIPEntry."Job No." := "No.";
            JobWIPEntry.Type := JobWIPEntry.Type::"Recognized Sales";
            JobWIPEntry.Reverse := false;
            JobWIPEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPEntry.Insert;

            Clear(JobWIPGLEntry);
            if JobWIPGLEntry.FindLast then
                JobWIPGLEntry."Entry No." += 1
            else
                JobWIPGLEntry."Entry No." := 1;
            JobWIPGLEntry.Init;
            JobWIPGLEntry."Job No." := "No.";
            JobWIPGLEntry.Type := JobWIPGLEntry.Type::"Recognized Costs";
            JobWIPGLEntry.Reverse := false;
            JobWIPGLEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPGLEntry.Insert;

            Clear(JobWIPGLEntry);
            JobWIPGLEntry.Init;
            if JobWIPGLEntry.FindLast then
                JobWIPGLEntry."Entry No." += 1
            else
                JobWIPGLEntry."Entry No." := 1;
            JobWIPGLEntry."Job No." := "No.";
            JobWIPGLEntry.Type := JobWIPGLEntry.Type::"Recognized Sales";
            JobWIPGLEntry.Reverse := false;
            JobWIPGLEntry."WIP Entry Amount" := LibraryRandom.RandInt(1000);
            JobWIPGLEntry.Insert;

            JobTask."Recognized Sales Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Costs Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Sales G/L Amount" := LibraryRandom.RandInt(1000);
            JobTask."Recognized Costs G/L Amount" := LibraryRandom.RandInt(1000);
            JobTask.Modify;

            CalcFields("Calc. Recog. Sales Amount", "Calc. Recog. Costs Amount",
              "Calc. Recog. Sales G/L Amount", "Calc. Recog. Costs G/L Amount",
              "Total WIP Cost Amount", "Total WIP Sales Amount",
              "Applied Costs G/L Amount", "Applied Sales G/L Amount");

            Assert.AreEqual("Total WIP Cost Amount" + "Applied Costs G/L Amount", CalcAccWIPCostsAmount,
              'CalcAccWIPCostsAmount calculates the wrong amount.');

            Assert.AreEqual("Total WIP Sales Amount" - "Applied Sales G/L Amount", CalcAccWIPSalesAmount,
              'CalcAccWIPSalesAmount calculates the wrong amount.');

            Assert.AreEqual("Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount", CalcRecognizedProfitAmount,
              'CalcRecognizedProfitAmount calculates the wrong amount.');

            Assert.AreEqual((("Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount") / "Calc. Recog. Sales Amount") * 100,
              CalcRecognizedProfitPercentage, 'CalcRecognizedProfitPercentage calculates the wrong amount.');

            Assert.AreEqual("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount", CalcRecognizedProfitGLAmount,
              'CalcRecognizedProfitGLAmount calculates the wrong amount.');

            Assert.AreEqual((("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount") / "Calc. Recog. Sales G/L Amount") * 100,
              CalcRecognProfitGLPercentage, 'CalcRecognProfitGLPercentage calculates the wrong amount.');
        end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCurrencyUpdate()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Initialize;
        SetUp(true);

        // Make sure you can change the currency code on a Job Planning Line through this function.
        Currency.Init;
        Currency.Code := 'TEST';
        Currency.Insert;

        CurrencyExchangeRate.Init;
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate;
        CurrencyExchangeRate."Exchange Rate Amount" := 1;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 1;
        CurrencyExchangeRate.Insert;

        Job."Currency Code" := Currency.Code;
        Job.CurrencyUpdatePlanningLines;

        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindFirst;

        Assert.AreEqual('TEST', JobPlanningLine."Currency Code",
          'The Currency Code on the Job Planning Line was not set correctly.');

        // Make sure you can't change the currency when the line is transferred to a Sales Invoice.
        CreateJobPlanningLineInvoice(JobPlanningLineInvoice, 1);
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        asserterror Job.CurrencyUpdatePlanningLines;

        TearDown;
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
        Initialize;
        LibraryJob.CreateJob(Job);
        CreateReservEntry(JobPlanningReservEntry, DATABASE::"Job Planning Line", Job."No.");
        CreateReservEntry(JobJnlLineReservEntry, DATABASE::"Job Journal Line", Job."No.");
        NewJobNo := LibraryUtility.GenerateGUID;
        // [WHEN] Job is renamed from "X" to "Y"
        Job.Rename(NewJobNo);
        // [THEN] Source ID of Reservation Entry with Source Type = "Job Planning Line" is "Y"
        JobPlanningReservEntry.Find;
        Assert.AreEqual(NewJobNo, JobPlanningReservEntry."Source ID", IncorrectSourceIDErr);
        // [THEN] Source ID of Reservation Entry with Source Type = "Job Journal Line" is "Y"
        JobJnlLineReservEntry.Find;
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

        Initialize;
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

        Initialize;
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

        Initialize;
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

        Initialize;
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

        Initialize;
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

        Initialize;
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
        Initialize;

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
        Initialize;

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
        Initialize;

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Approved.
        UpdateTimeSheetLineStatus(TimeSheetLine, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);

        // [WHEN] Delete the Job.
        Job.SetRecFilter;
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
        Initialize;

        // [GIVEN] A Job.
        SetUp(false);

        // [GIVEN] Time Sheet Header with Line.
        // [GIVEN] Time Sheet Line Type = Job.
        MockTimeSheetWithLine(TimeSheetLine);

        // [GIVEN] Time Sheet Line Status = Rejected.
        UpdateTimeSheetLineStatus(TimeSheetLine, TimeSheetLine.Status::Rejected);
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Rejected);

        // [WHEN] Delete the Job.
        Job.SetRecFilter;
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
        Initialize;

        // [GIVEN] Users "A", "B", Job "X"
        UserA := MockUser;
        UserB := MockUser;
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
        Job.Find;
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

        Initialize;
        SetUp(false);
        GetRandomSetOfDecimalsWithDelta(InputCost, ScheduleCost, UsageCost, 1);

        // [GIVEN] Job "J" with Job Ledger Entries with total cost
        SetTotalCostLCYInJobPlanningLine(ScheduleCost);
        MockJobLedgEntryWithTotalCostLCY(Job."No.", UsageCost);

        // [GIVEN] "Over Budget" is already calculated for the job "J"
        InvokeUpdateOverBudgetValueFunctionWithVerification(false, InputCost, true);

        // [GIVEN] New dimension value code = "D"
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        NameValueBuffer.DeleteAll;
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
        Initialize;

        // [GIVEN] Customer "CUST" with set of default dimensions "DIMSET"
        CustomerNo := CreateCustomerWithDefDim;

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
        Initialize;

        // [GIVEN] Customer "CUST1" with set of dimensions "DIMSET1"
        // [GIVEN] Customer "CUST2" with set of dimensions "DIMSET2"
        CustomerNo[1] := CreateCustomerWithDefDim;
        CustomerNo[2] := CreateCustomerWithDefDim;

        // [GIVEN] New job "J" with Bill-to Customer No. = "CUST1"
        CreateJob(Job);
        Job.Validate("Bill-to Customer No.", CustomerNo[1]);
        Job.Validate("Job Posting Group", LibraryJob.FindJobPostingGroup);
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
        JobTask.FindSet;
        repeat
            VerifyJobTaskDimensionsFromCustDefaultDimensions(CustomerNo[2], JobTask);
        until JobTask.Next = 0;
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
        Initialize;

        // [GIVEN] Customer "CUST1" with global dimension 1 value "GLOBALDIM1"
        // [GIVEN] Customer "CUST2" with global dimension 2 value "GLOBALDIM2"
        Customer[1].Get(CreateCustomerWithDefGlobalDim(1));
        Customer[2].Get(CreateCustomerWithDefGlobalDim(2));

        // [GIVEN] New job "J" with Bill-to Customer No. = "CUST1"
        CreateJob(Job);
        Job.Validate("Bill-to Customer No.", Customer[1]."No.");
        Job.Validate("Job Posting Group", LibraryJob.FindJobPostingGroup);
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
        JobTask.FindSet;
        repeat
            JobTask.TestField("Global Dimension 1 Code", '');
            JobTask.TestField("Global Dimension 2 Code", Customer[2]."Global Dimension 2 Code");
        until JobTask.Next = 0;
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
        Initialize;

        // [GIVEN] Customer "CUST" with set of default dimensions "DIMSET"
        CustomerNo := CreateCustomerWithDefDim;

        // [GIVEN] Mock creating job from customer card
        Job.Init;
        Job.SetFilter("Bill-to Customer No.", CustomerNo);

        // [WHEN] Job is being inserted
        Job.Insert(true);

        // [THEN] Job "J" has same set of default dimensions "DIMSET"
        VerifyJobDefaultDimensionsFromCustDefaultDimensions(Job."No.", CustomerNo);
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

        LibraryERMCountryData.UpdateGeneralPostingSetup;

        JobBatchJobs.SetJobNoSeries(JobsSetup, NoSeries);

        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job");
    end;

    local procedure SetUp(ApplyUsageLink: Boolean)
    var
        JobWIPMethod: Record "Job WIP Method";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        JobWIPMethod.FindFirst;
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Modify;

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
        CustNo := LibrarySales.CreateCustomerNo;
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
        CustNo := LibrarySales.CreateCustomerNo;
        GLSetup.Get;
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
        JobWIPMethod.Init;
        JobWIPMethod.Code := 'UTTJOB';
        JobWIPMethod."WIP Cost" := WIPCost;
        JobWIPMethod."WIP Sales" := WIPSales;
        JobWIPMethod.Insert(true);
    end;

    local procedure CreateJobPlanningLineInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; Qty: Decimal)
    begin
        JobPlanningLineInvoice.Init;
        JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
        JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
        JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Posted Invoice";
        JobPlanningLineInvoice."Document No." := 'TEST';
        JobPlanningLineInvoice."Line No." := 10000;
        JobPlanningLineInvoice."Quantity Transferred" := Qty;
        JobPlanningLineInvoice."Transferred Date" := WorkDate;
        JobPlanningLineInvoice.Insert;
    end;

    local procedure CreateReservEntry(var ReservEntry: Record "Reservation Entry"; TableID: Integer; SourceID: Code[20])
    var
        RecRef: RecordRef;
    begin
        with ReservEntry do begin
            Init;
            RecRef.GetTable(ReservEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Source Type" := TableID;
            "Source Subtype" := LibraryRandom.RandInt(5);
            "Source ID" := SourceID;
            "Source Ref. No." := LibraryRandom.RandInt(100);
            Insert;
        end;
    end;

    local procedure CreateJob(var Job: Record Job)
    begin
        Job.Init;
        Job."No." := LibraryUtility.GenerateGUID;
        Job.Insert;
    end;

    local procedure MockTimeSheetWithLine(var TimeSheetLine: Record "Time Sheet Line")
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        with TimeSheetHeader do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Owner User ID" := UserId;
            "Starting Date" := WorkDate;
            "Ending Date" := WorkDate + 7;
            Insert;
        end;

        with TimeSheetLine do begin
            Init;
            "Time Sheet No." := TimeSheetHeader."No.";
            "Line No." := 10000;
            Type := Type::Job;
            "Job No." := Job."No.";
            Status := Status::Open;
            Insert;
        end;
    end;

    local procedure MockUser(): Code[50]
    var
        UserSetup: Record "User Setup";
    begin
        with UserSetup do begin
            Init;
            Validate("User ID", LibraryUtility.GenerateGUID);
            Insert(true);
            exit("User ID");
        end;
    end;

    local procedure ValidateJobProjectManagerWithPage(Job: Record Job; ProjectManager: Code[50])
    var
        JobCard: TestPage "Job Card";
    begin
        JobCard.OpenEdit;
        JobCard.GotoRecord(Job);
        JobCard."Project Manager".SetValue(ProjectManager);
        JobCard.Close;
    end;

    local procedure UpdateTimeSheetLineStatus(var TimeSheetLine: Record "Time Sheet Line"; NewStatus: Option)
    begin
        TimeSheetLine.Status := NewStatus;
        TimeSheetLine.Modify;
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
            Init;
            "Entry No." :=
              LibraryUtility.GetNewRecNo(JobLedgEntry, FieldNo("Entry No."));
            Validate("Job No.", JobNo);
            "Total Cost (LCY)" := UsageCost;
            Insert;
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
        JobTask.Find;
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
        CustDefaultDimension.FindSet;
        repeat
            JobDefaultDimension.Get(DATABASE::Job, JobNo, CustDefaultDimension."Dimension Code");
            JobDefaultDimension.TestField("Dimension Value Code", CustDefaultDimension."Dimension Value Code");
        until CustDefaultDimension.Next = 0;
    end;

    local procedure VerifyJobTaskDimensionsFromCustDefaultDimensions(CustomerNo: Code[20]; JobTask: Record "Job Task")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", CustomerNo);
        DefaultDimension.FindSet;
        repeat
            VerifyJobTaskDimension(JobTask, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        until DefaultDimension.Next = 0;
    end;

    [EventSubscriber(ObjectType::Table, 167, 'OnAfterModifyEvent', '', false, false)]
    local procedure InsertNameValueBufferOnJobModify(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.ID :=
          LibraryUtility.GetNewRecNo(NameValueBuffer, NameValueBuffer.FieldNo(ID));
        NameValueBuffer.Name := Rec."No.";
        NameValueBuffer.Insert;
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
}

