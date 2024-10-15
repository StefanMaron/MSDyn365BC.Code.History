codeunit 136320 "Job Features Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Tests modifying feature keys]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

#if not CLEAN20
    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue,JobTransferFromJobPlanLineHandler')]
    [Scope('OnPrem')]
    procedure TransferToJobJnlAndPostWhenWhsFeatureIsDisabled()
    var
        LocationInvPick: Record Location;
        LocationWhsPick: Record Location;
        Item: Record Item;
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        FeatureKey: Record "Feature Key";
        FeatureManagement: Codeunit "Feature Management Facade";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PicksForJobsFeatureIdLbl: Label 'PicksForJobs', Locked = true;
    begin
        // [FEATURE] 315267 [WMS] Support Inventory Pick and Warehouse Pick for Job Planning Lines
        // [SCENARIO] Job journal posting is allowed if feature is disabled.
        // [GIVEN] Location that is warehouse/inventory pick relevant, item with available inventory in that location
        Initialize();
        LibraryWarehouse.CreateLocationWMS(LocationInvPick, false, false, true, false, false);
        LibraryWarehouse.CreateLocationWMS(LocationWhsPick, false, false, true, false, true);
        LibraryInventory.CreateItem(Item);
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationInvPick.Code, '', 1000, LibraryRandom.RandDec(10, 2));
        CreateAndPostInvtAdjustmentWithUnitCost(Item."No.", LocationWhsPick.Code, '', 1000, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Job is created with a Job Planning Line of type Budget and Item with some quantity available at the location
        CreateJobPlanningLine(JobPlanningLine1, true);
        CreateJobPlanningLine(JobPlanningLine2, true);
        JobPlanningLine1.Validate("Location Code", LocationInvPick.Code);
        JobPlanningLine2.Validate("Location Code", LocationWhsPick.Code);
        JobPlanningLine1.Modify(true);
        JobPlanningLine2.Modify(true);

        // [GIVEN] The feature is disabled
        Assert.IsFalse(FeatureManagement.IsEnabled(PicksForJobsFeatureIdLbl), 'The feature PicksForJobs must be disabled for this test.');

        // [WHEN] Job Journal Line is created from the Job Planning Line.
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine1);
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine2);

        // [WHEN] Job Journal Lines are posted.
        OpenRelatedJournalAndPost(JobPlanningLine1);

        // [THEN] No error is expected
    end;

    local procedure CreateAndPostInvtAdjustmentWithUnitCost(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure OpenRelatedJournalAndPost(JobPlanningLine: Record "Job Planning Line")
    var
        JobJournalPage: TestPage "Job Journal";
    begin
        OpenRelatedJobJournal(JobJournalPage, JobPlanningLine);
        JobJournalPage."P&ost".Invoke(); //Needs ConfirmHandlerTrue, MessageHandler
        JobJournalPage.Close();
    end;

    local procedure OpenRelatedJobJournal(var JobJournalPage: TestPage "Job Journal"; JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLinePage: TestPage "Job Planning Lines";
    begin
        JobPlanningLinePage.OpenEdit();
        JobPlanningLinePage.GoToRecord(JobPlanningLine);
        JobJournalPage.Trap();
        JobPlanningLinePage."&Open Job Journal".Invoke();
        JobPlanningLinePage.Close();
    end;

    local procedure TransferToJobJournalFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLinePage: TestPage "Job Planning Lines";
    begin
        JobPlanningLinePage.OpenEdit();
        JobPlanningLinePage.GoToRecord(JobPlanningLine);
        JobPlanningLinePage.CreateJobJournalLines.Invoke(); //Needs JobTransferFromJobPlanLineHandler Handler
        JobPlanningLinePage.Close();
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ApplyUsageLink: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Unit Price", JobPlanningLine."Unit Cost" * (1 + LibraryRandom.RandInt(100) / 100));
        JobPlanningLine.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferFromJobPlanLineHandler(var JobTransferJobPlanLine: TestPage "Job Transfer Job Planning Line")
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
    begin
        if JobTransferJobPlanLine.JobJournalTemplateName.Value = '' then begin
            JobJournalTemplate.SetRange("Page ID", PAGE::"Job Journal");
            JobJournalTemplate.SetRange(Recurring, false);
            JobJournalTemplate.FindFirst();
            JobTransferJobPlanLine.JobJournalTemplateName.Value := JobJournalTemplate.Name;
        end else
            JobJournalTemplate.Get(JobTransferJobPlanLine.JobJournalTemplateName.Value);

        if JobTransferJobPlanLine.JobJournalBatchName.Value = '' then begin
            JobJournalBatch.SetRange("Journal Template Name", JobJournalTemplate.Name);
            JobJournalBatch.FindFirst();
            JobTransferJobPlanLine.JobJournalBatchName.Value := JobJournalBatch.Name;
        end;

        JobTransferJobPlanLine.OK.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // For handle message
    end;
#endif
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Features Management");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Features Management");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Features Management");
    end;
}