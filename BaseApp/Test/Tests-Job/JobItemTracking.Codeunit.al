codeunit 136319 "Job Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Pick] [Item Tracking]
        // Common Item Tracking Codes:
        // SNALL - SN Tracking =True
        // SNWMS - SN tracking = true and SN WMS = true
        // SNJOB - SN tracking = false, Neg.Adj.inbound/outbound = true
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Assert: Codeunit Assert;
        ItemTrackingHandlerAction: Option Assign,AssignSpecific,AssignSpecificLot,AssignMultiple,Select,NothingToHandle,SelectWithQtyToHandle,ChangeSelection,ChangeSelectionLot,ChangeSelectionLotLast,ChangeSelectionQty,AssignLot;
        IsInitialized: Boolean;
        ReInitializeJobSetup: Boolean;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,AssignSerialNoEnterQtyPageHandler,ItemTrackingSummaryPageHandler,JobTransferToSalesInvoiceRequestPageHandler,MessageHandler,JobTransferFromJobPlanLineHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure S455935_PostJobJournalPartiallyForSerialItemTracking()
    var
        SerialTrackedItem: Record Item;
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [FEATURE] [Serial Item Tracking] [Job] [Job Planning Line] [Sales Invoice] [Job Journal]
        // [SCENARIO 455935] "Job Journal" created from "Job Planning Lines" can be posted after serial numbers are assigned.
        Initialize();

        // [GIVEN] Create serial tracked Item.
        CreateSerialTrackedItem(SerialTrackedItem, false);

        // [GIVEN] Create Location without WMS.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post positive adjustment of 10 serial numbers of Item to Location.
        CreateAndPostInvtAdjustmentWithSNTracking(SerialTrackedItem."No.", Location.Code, '', 10, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create Job with "Apply Usage Link".
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create Job Task.
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Planning Line for Job Task: Type = Item, No. = SerialTrackedItem, Line Type = "Both Budget and Billable", Quantity = 3.
        CreateJobPlanningLineWithData(JobPlanningLine, JobTask, "Job Planning Line Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, SerialTrackedItem."No.", Location.Code, '', 3);

        // [GIVEN] Create and post Sales Invoice from Job Planning Lines.
        CreateAndPostSalesInvoiceFromJobPlanningLine(JobPlanningLine);

        // [GIVEN] Transfer Job Planning Lines to Job Journal.
        TransferToJobJournalFromJobPlanningLine(JobPlanningLine);

        // [GIVEN] Set serial numbers in Job Journal Line for Item.
        JobJournalLine.SetRange("Job No.", JobTask."Job No.");
        JobJournalLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Select); // ItemTrackingSummaryPageHandler
        JobJournalLine.OpenItemTrackingLines(false);

        // [WHEN] Post Job Journal Line for Job Planning Line.
        OpenRelatedJournalAndPost(JobPlanningLine);

        // [THEN] Verify that there are 3 Job Ledger Entries with "Serial No." values.
        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.SetFilter("Serial No.", '<>%1', '');
        Assert.RecordCount(JobLedgerEntry, 3);
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Job Item Tracking");
        LibrarySetupStorage.Restore();
        LibraryJob.DeleteJobJournalTemplate();
        LibraryVariableStorage.Clear();

        if ReInitializeJobSetup then begin
            DummyJobsSetup.Get();
            DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
            DummyJobsSetup."Apply Usage Link by Default" := true;
            DummyJobsSetup."Job Nos." := LibraryJob.GetJobTestNoSeries();
            DummyJobsSetup."Document No. Is Job No." := true;
            DummyJobsSetup.Modify();
            ReInitializeJobSetup := false;
        end;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Job Item Tracking");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        NoSeries.Get(LibraryJob.GetJobTestNoSeries());
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();

        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Job Item Tracking");
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

    local procedure CreateSerialTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateSerialItem(Item);
        if WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("SN Warehouse Tracking", true);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateJobPlanningLineWithData(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; Number: Code[20];
                                                                                                                                             LocationCode: Code[10];
                                                                                                                                             BinCode: Code[20];
                                                                                                                                             Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Number);
        JobPlanningLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            JobPlanningLine.Validate("Bin Code", BinCode);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
        Commit();
    end;

    local procedure CreateAndPostSalesInvoiceFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, JobPlanningLine."Job No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; JobNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateAndPostInvtAdjustmentWithSNTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::Assign);
        ItemJournalLine.OpenItemTrackingLines(false); //ItemTrackingSummaryPageHandler required.
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
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

        JobTransferJobPlanLine.OK().Invoke();
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
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ActionOption: Integer;
    begin
        ActionOption := LibraryVariableStorage.DequeueInteger();
        case ActionOption of
            ItemTrackingHandlerAction::Assign:
                ItemTrackingLines."Assign &Serial No.".Invoke(); // AssignSerialNoEnterQtyPageHandler required.
            ItemTrackingHandlerAction::Select:
                ItemTrackingLines."Select Entries".Invoke(); // ItemTrackingSummaryPageHandler
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialNoEnterQtyPageHandler(var EnterQuantityPage: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK.Invoke;
    end;
}

