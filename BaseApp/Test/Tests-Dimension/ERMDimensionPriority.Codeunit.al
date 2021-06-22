codeunit 134381 "ERM Dimension Priority"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE]  [Dimension] [Dimension Priority]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        isInitialized: Boolean;
        WrongDimValueCodeErr: Label 'Wrong dimension value code.';

    [Test]
    [Scope('OnPrem')]
    procedure PriorityAccount()
    begin
        DifferentPriority(1, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityCustomer()
    begin
        DifferentPriority(2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityChangeCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize;
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo;

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode, 1, 1);

        // Find default dimension codes
        FindDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo);

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Update customer on journal line
        GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Modify(true);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityChangeAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize;
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo;

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode, 1, 1);

        // Find default dimension codes
        FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GenJournalBatch."Bal. Account No.");

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Update account on journal line
        GenJournalLine.Validate("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GenJournalLine.Modify(true);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupDefaultDimensionPriority()
    var
        SourceCode: Code[10];
    begin
        // Test setup default dimension priority.

        // Setup: Find Source Code.
        Initialize;
        SourceCode := LibraryERM.FindGeneralJournalSourceCode;

        // Exercise: Create default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account with source code.
        SetDefaultDimensionPriority(SourceCode);

        // Verify: Verify default dimension priority for Customer, Vendor and G/L Account with Source Code must exist.
        VerifyDefaultDimensionPriority(SourceCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PriorityReqWkshAndCarryOutAction()
    var
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        // Test that purchase order created by carry out action from requisition worskeet has correct dimensions according to dimension in requisition worksheet

        Initialize;
        SetupDimensionPriorityForPurchSrcCode;
        DimensionCode := CreateDimensionValues(DimValueArray);
        VendNo := CreateVendorWithPurchaserAndDefDim(DimensionCode, DimValueArray);
        ItemNo := CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode, DimValueArray[3], VendNo);
        CreateReqLineAndCarryOutAction(ItemNo);
        VerifyDimValueInPurchLine(VendNo, DimensionCode, DimValueArray[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshCarryOutActionWithChangedDim()
    var
        RequisitionLine: Record "Requisition Line";
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
        VendNo: Code[20];
        ItemNo: Code[20];
        PrevGlobalDimCode: Code[20];
        ExpectedDimValue: Code[20];
    begin
        // [FEATURE] [Change Global Dimensions]
        // [SCENARIO] purchase order line created by carry out action from requisition worskeet with changed dimension has dimension value from requisition worksheet

        // Setup.
        Initialize;
        LibraryDimension.InitGlobalDimChange;
        SetupDimensionPriorityForPurchSrcCode;
        DimensionCode := CreateDimensionValues(DimValueArray);
        PrevGlobalDimCode := SetupGlobalDimension(1, DimensionCode);
        VendNo := CreateVendorWithPurchaserAndDefDim(DimensionCode, DimValueArray);
        ItemNo := CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode, DimValueArray[3], VendNo);
        ExpectedDimValue := CreateReqLineWithCustomDimVal(RequisitionLine, ItemNo, DimensionCode);

        // Exercise.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate, WorkDate, WorkDate, WorkDate, '');

        // Verify.
        VerifyDimValueInPurchLine(VendNo, DimensionCode, ExpectedDimValue);
        Assert.TableIsEmpty(DATABASE::"Change Global Dim. Log Entry");

        // Teardown.
        SetupGlobalDimension(1, PrevGlobalDimCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if it has higher priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if it has higher priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource's Dimension Values if Job has lower priority and line has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourcePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource's Dimension Values if Job has lower priority and line has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 2, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if no priority specified and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 0, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if if no priority specified and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 0, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoJobPriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if Resource only has priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoJobPriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Resource Dimension Values if Resource only has priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoResourcePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if Job has only priority and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoResourcePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if Job has only priority and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 2, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityJobJnlLineWithJobDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job's Dimension Values if Job has the same priority as Resource and it has empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SamePriorityJobJnlLineWithJobTaskDefaultDim()
    var
        TableIDs: array[2] of Integer;
        Priorities: array[2] of Integer;
    begin
        // Verify that Job Journal Line contains Job Task's Dimension Values if Job has the same priority as Resource and it has non-empty Job Task No

        SetTablePriority(TableIDs, Priorities, DATABASE::Job, 1, 1);
        SetTablePriority(TableIDs, Priorities, DATABASE::Resource, 1, 2);
        PriorityJobJnlLineWithDefaultDim(TableIDs, Priorities, 3, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderDimPrioritySalesPerson()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Sales Person's dimension if Sales Person Dimension priority is higher then Service Contract one
        Initialize;

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 1
        SetServiceDimensionPriorities(1, 2);
        LibraryDimension.CreateDimension(Dimension);
        ReturnDim := CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 2
        CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD1"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderDimPriorityServiceContract()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Service Contract dimension if Service Contract Dimension priority is higher then Sales Person's one
        Initialize;

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 2
        SetServiceDimensionPriorities(2, 1);
        LibraryDimension.CreateDimension(Dimension);
        CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 1
        ReturnDim := CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD2"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderSameDimPriorities()
    var
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        SalesPersonCode: Code[20];
        ServiceContractCode: Code[20];
        CustomerCode: Code[20];
        ReturnDim: Code[20];
    begin
        // [FEATURE] [Service Order]
        // [SCENARIO 380432] Inherit Service Contract dimension if Service Contract Dimension priority it the same as Sales Person's one
        Initialize;

        // [GIVEN] Sales Person "SP" with default dimension "DD1" where Priority = 1
        SetServiceDimensionPriorities(1, 1);
        LibraryDimension.CreateDimension(Dimension);
        CreateSalesPersonWithDimAndPriority(SalesPersonCode, Dimension.Code);

        // [GIVEN] Service Contract with dimension value "DD2" where Priority = 1
        ReturnDim := CreateServiceContractWithDimAndPriority(ServiceContractCode, CustomerCode, Dimension.Code);

        // [GIVEN] Service Quote with Sales Person "SP"
        CreateServiceQuotaWithSalesPerson(ServiceHeader, CustomerCode, SalesPersonCode);

        // [WHEN] Assign Service Contract to Service Quote
        ServiceHeader.Validate("Contract No.", ServiceContractCode);

        // [THEN] Service Quote dimension value is "DD2"
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, ServiceHeader."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", ReturnDim);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityPurchaseLineWithItemDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Dimension] [Job] [Purchase]
        // [SCENARIO 257952] Purchase line with job sets the Item Dimension Value if it has the highest Dimension Priority.
        Initialize;

        // [GIVEN] Default Dimension Priorities for Source Code = PURCHASE are set as 1 for Item and 2 for Job.
        SetPurchaseDimensionPriorities(1, 2);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [WHEN] Create Purchase Line with Item and Job Task.
        CreatePurchaseLineWithItemAndJobTask(PurchaseLine, Item, JobTask);

        // [THEN] Purchase Line Dimension Value = "IDV".
        VerifyPurchaseLineDimensionValue(PurchaseLine, ItemDimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriorityPurchaseLineWithJobDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Dimension] [Job] [Purchase]
        // [SCENARIO 257952] Purchase line with job sets the Job Dimension Value if it has the highest Dimension Priority.
        Initialize;

        // [GIVEN] Default Dimension Priorities for Source Code = PURCHASE are set as 1 for Job and 2 for Item.
        SetPurchaseDimensionPriorities(2, 1);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [WHEN] Create Purchase Line with Item and Job Task.
        CreatePurchaseLineWithItemAndJobTask(PurchaseLine, Item, JobTask);

        // [THEN] Purchase Line Dimension Value = "JDV".
        VerifyPurchaseLineDimensionValue(PurchaseLine, JobDimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningLineWithItemDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Dimension] [Job] [Sales]
        // [SCENARIO 257952] Sales line created from Job Planning Line sets the Item Dimension Value if it has the highest Dimension Priority.
        Initialize;

        // [GIVEN] Default Dimension Priorities for Source Code = SALES are set as 1 for Item and 2 for Job.
        SetSalesDimensionPriorities(1, 2);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [GIVEN] Job Planning Line for Item with Job Task.
        CreateJobPlanningLineWithItemAndJobTask(JobPlanningLine, JobTask, Item."No.");
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Line Dimension Value = "IDV".
        FindSalesLineFromJobPlanningLine(SalesLine, JobPlanningLine);
        VerifySalesLineDimensionValue(SalesLine, ItemDimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningLineWithJobDim()
    var
        Dimension: Record Dimension;
        Item: Record Item;
        ItemDimensionValue: Record "Dimension Value";
        JobTask: Record "Job Task";
        JobDimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Dimension] [Job] [Sales]
        // [SCENARIO 257952] Sales line created from Job Planning Line sets the Job Dimension Value if it has the highest Dimension Priority.
        Initialize;

        // [GIVEN] Default Dimension Priorities for Source Code = SALES are set as 1 for Job and 2 for Item.
        SetSalesDimensionPriorities(2, 1);

        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Item with Default Dimension Value "IDV".
        CreateItemWithDefaultDimension(Item, ItemDimensionValue, Dimension.Code);

        // [GIVEN] Job Task with Default Dimension Value "JDV".
        CreateJobTaskWithDefaultDimension(JobTask, JobDimensionValue, Dimension.Code);

        // [GIVEN] Job Planning Line for Item with Job Task.
        CreateJobPlanningLineWithItemAndJobTask(JobPlanningLine, JobTask, Item."No.");
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Line Dimension Value = "JDV".
        FindSalesLineFromJobPlanningLine(SalesLine, JobPlanningLine);
        VerifySalesLineDimensionValue(SalesLine, JobDimensionValue.Code);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Priority");
        // Lazy Setup.
        LibraryDimension.InitGlobalDimChange;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Priority");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        ClearDimensionCombinations;

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Priority");
    end;

    local procedure DifferentPriority(CustomerPri: Integer; GLAccountPri: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        Initialize;
        GetGLBalancedBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo;

        // Create default dimension codes for Customer and G/L Account
        CreateDefaultDimensionCodes(CustomerNo, GenJournalBatch."Bal. Account No.");

        // Setup priorities
        SetupDimensionPriority(LibraryERM.FindGeneralJournalSourceCode, CustomerPri, GLAccountPri);

        // Find default dimension codes
        if CustomerPri < GLAccountPri then
            FindDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo)
        else
            FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GenJournalBatch."Bal. Account No.");

        // Create a journal line
        ClearJournalBatch(GenJournalBatch);
        CreateGeneralJnlLine(GenJournalLine, GenJournalBatch, CustomerNo);

        // Verify dimensions
        VerifyDimensionSetID(DefaultDimension, GenJournalLine."Dimension Set ID");
    end;

    local procedure PriorityJobJnlLineWithDefaultDim(TableIDs: array[2] of Integer; Priorities: array[2] of Integer; ExpectedDimValueIndex: Integer; FillJobTaskNo: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        DefaultDimension: Record "Default Dimension";
        ResourceNo: Code[20];
        DimValueArray: array[3] of Code[20];
        DimensionCode: Code[20];
    begin
        // Setup.
        Initialize;

        SetupDimensionPriorityForJobJnlSrcCode(TableIDs, Priorities);
        DimensionCode := CreateDimensionValues(DimValueArray);
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.", DimensionCode, DimValueArray[1]);
        LibraryJob.CreateJobTask(Job, JobTask);
        if FillJobTaskNo then
            UpdateJobTaskDimension(JobTask, DimensionCode, DimValueArray[2]);
        ResourceNo := LibraryJob.CreateConsumable(0); // Use 0 for Resource
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Resource, ResourceNo, DimensionCode, DimValueArray[3]);

        // Exercise.
        if not FillJobTaskNo then
            JobTask."Job Task No." := '';
        CreateJobJnlLine(JobTask, ResourceNo);

        // Verify.
        VerifyDimValueInJobJnlLine(Job."No.", JobTask."Job Task No.", DimensionCode, DimValueArray[ExpectedDimValueIndex]);
    end;

    local procedure CreateVendorWithPurchaserAndDefDim(DimensionCode: Code[20]; DimensionValueCode: array[3] of Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        Purchaser: Record "Salesperson/Purchaser";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(Purchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", Purchaser.Code, DimensionCode, DimensionValueCode[1]);

        Vendor.Validate("Purchaser Code", Purchaser.Code);
        Vendor.Modify(true);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Vendor, Vendor."No.", DimensionCode, DimensionValueCode[2]);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithReplenishmentPociliyAndDefDim(DimensionCode: Code[20]; DimensionValueCode: Code[20]; VendNo: Code[20]): Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
    begin
        with Item do begin
            LibraryInventory.CreateItem(Item);
            Validate("Replenishment System", "Replenishment System"::Purchase);
            Validate("Reordering Policy", "Reordering Policy"::"Fixed Reorder Qty.");
            Validate("Reorder Quantity", 1);
            Validate("Vendor No.", VendNo);
            Modify(true);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, "No.", DimensionCode, DimensionValueCode);
            exit("No.");
        end;
    end;

    local procedure CreateItemWithDefaultDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Item, Item."No.", DimensionCode, DimensionValue.Code);
    end;

    local procedure CreateJobTaskWithDefaultDimension(var JobTask: Record "Job Task"; var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20])
    var
        Job: Record Job;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.", DimensionCode, DimensionValue.Code);
        LibraryJob.CreateJobTask(Job, JobTask);
        UpdateJobTaskDimension(JobTask, DimensionCode, DimensionValue.Code);
    end;

    local procedure CreateSalesPersonWithDimAndPriority(var SalespersonCode: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code,
          DimensionValue."Dimension Code", DimensionValue.Code);
        SalespersonCode := SalespersonPurchaser.Code;
        exit(DimensionValue.Code);
    end;

    local procedure CreateServiceContractWithDimAndPriority(var ServiceContractCode: Code[20]; var CustomerCode: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        CreateServiceContract(ServiceContractHeader);
        ServiceContractHeader."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(ServiceContractHeader."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        ServiceContractHeader.Modify();
        ServiceContractCode := ServiceContractHeader."Contract No.";
        CustomerCode := ServiceContractHeader."Customer No.";
        exit(DimensionValue.Code);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Init();
        ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
        ServiceContractHeader."Contract No." :=
          LibraryUtility.GenerateRandomCode(ServiceContractHeader.FieldNo("Contract No."), DATABASE::"Service Contract Header");
        ServiceContractHeader.Status := ServiceContractHeader.Status::Signed;
        ServiceContractHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo);
        ServiceContractHeader.Insert();
        Commit();
    end;

    local procedure CreateServiceQuotaWithSalesPerson(var ServiceHeader: Record "Service Header"; CustomerCode: Code[20]; SalespersonCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustomerCode);
        ServiceHeader.Validate("Salesperson Code", SalespersonCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreatePurchaseLineWithItemAndJobTask(var PurchaseLine: Record "Purchase Line"; Item: Record Item; JobTask: Record "Job Task")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithItemAndJobTask(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ItemNo: Code[20])
    begin
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract, LibraryJob.ItemType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure FindDefaultDimension(var DefaultDimension: Record "Default Dimension"; TableID: Integer; No: Code[20])
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindSet;
    end;

    local procedure SetupDimensionPriority(SourceCode: Code[10]; CustomerPriority: Integer; GLAccountPriority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        with DefaultDimensionPriority do begin
            // Clear priorities setup
            SetRange("Source Code", SourceCode);
            DeleteAll();

            // Setup new priorities
            Validate("Source Code", SourceCode);
            CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Customer, CustomerPriority);
            CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::"G/L Account", GLAccountPriority);
        end;
    end;

    local procedure SetupDimensionPriorityForPurchSrcCode()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        SourceCodeSetup.Get();
        with DefaultDimensionPriority do begin
            SetRange("Source Code", SourceCodeSetup.Purchases);
            DeleteAll();

            Validate("Source Code", SourceCodeSetup.Purchases);
            CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::"Salesperson/Purchaser", 1);
            CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Vendor, 2);
            CreateDefaultDimPriority(DefaultDimensionPriority, DATABASE::Item, 3);
        end;
    end;

    local procedure SetupDimensionPriorityForJobJnlSrcCode(TableIDs: array[2] of Integer; Priorities: array[2] of Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        DefaultDimensionPriority: Record "Default Dimension Priority";
        i: Integer;
    begin
        SourceCodeSetup.Get();
        with DefaultDimensionPriority do begin
            SetRange("Source Code", SourceCodeSetup."Job Journal");
            DeleteAll();

            Validate("Source Code", SourceCodeSetup."Job Journal");
            for i := 1 to ArrayLen(TableIDs) do
                CreateDefaultDimPriority(DefaultDimensionPriority, TableIDs[i], Priorities[i]);
        end;
    end;

    local procedure CreateDefaultDimPriority(var DefaultDimPriority: Record "Default Dimension Priority"; TableID: Integer; Priority: Integer)
    begin
        if (TableID = 0) or (Priority = 0) then
            exit;

        DefaultDimPriority.Validate("Table ID", TableID);
        DefaultDimPriority.Validate(Priority, Priority);
        DefaultDimPriority.Insert(true);
    end;

    local procedure ClearDimensionCombinations()
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        DimensionCombination.DeleteAll(true);
    end;

    local procedure CreateDimensionValues(var DimensionValueArray: array[3] of Code[20]): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to 3 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            DimensionValueArray[i] := DimensionValue.Code;
        end;
        exit(DimensionValue."Dimension Code");
    end;

    local procedure CreateDefaultDimensionCodes(CustomerNo: Code[20]; GLAccount: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        i: Integer;
    begin
        // Clear existing dimension setup to make room for our new setup
        ClearDefaultDimensionCodes(DATABASE::Customer, CustomerNo);
        ClearDefaultDimensionCodes(DATABASE::"G/L Account", GLAccount);

        // Setup special dimension values such that all cases exists:
        // Case 1: Dimension exist in customer, but not in Account
        // Case 2: Opposite of Case 1
        // Case 3: Dimension exists in both with same value
        // Case 4: Dimension exists in both with different value

        i := 0;
        Dimension.FindSet;
        repeat
            if i < Dimension.Count - 1 then
                LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo, Dimension.Code,
                  GetDimensionValueCode(Dimension.Code, 1));
            if i > 0 then
                LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"G/L Account", GLAccount, Dimension.Code,
                  GetDimensionValueCode(Dimension.Code, i mod 2));
            i += 1;
        until Dimension.Next = 0;
    end;

    local procedure ClearDefaultDimensionCodes(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.DeleteAll(true);
    end;

    local procedure ClearDefaultDimensionPriorities(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.DeleteAll(true);
    end;

    local procedure GetDimensionValueCode(DimensionCode: Code[20]; Number: Integer): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindSet;
        DimensionValue.Next(Number);
        exit(DimensionValue.Code);
    end;

    local procedure GetGLBalancedBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer,
          CustomerNo,
          -LibraryRandom.RandInt(1000));
    end;

    local procedure CreateJobJnlLine(JobTask: Record "Job Task"; ResourceNo: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        JobJournalLine: Record "Job Journal Line";
    begin
        SourceCodeSetup.Get();
        with JobJournalLine do begin
            LibraryJob.CreateJobJournalLine("Line Type"::Budget, JobTask, JobJournalLine);
            Validate("Source Code", SourceCodeSetup."Job Journal");
            Validate(Type, Type::Resource);
            Validate("No.", ResourceNo);
            Modify(true);
        end;
    end;

    local procedure UpdateJobTaskDimension(JobTask: Record "Job Task"; DimensionCode: Code[20]; DimensionValue: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        with JobTaskDimension do begin
            Get(JobTask."Job No.", JobTask."Job Task No.", DimensionCode);
            Validate("Dimension Value Code", DimensionValue);
            Modify(true);
        end
    end;

    local procedure CreateReqLineAndCarryOutAction(ItemNo: Code[20])
    var
        ReqLine: Record "Requisition Line";
    begin
        CreateReqLine(ReqLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(ReqLine, WorkDate, WorkDate, WorkDate, WorkDate, '');
    end;

    local procedure CreateReqLineWithCustomDimVal(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        CreateReqLine(RequisitionLine, ItemNo);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        RequisitionLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        RequisitionLine.Modify();
        exit(DimensionValue.Code);
    end;

    local procedure SetupGlobalDimension(DimIndex: Integer; NewDimCode: Code[20]) PrevDimCode: Code[20]
    var
        DimCodes: array[2] of Code[20];
    begin
        DimCodes[1] := LibraryERM.GetGlobalDimensionCode(1);
        DimCodes[2] := LibraryERM.GetGlobalDimensionCode(2);
        PrevDimCode := DimCodes[DimIndex];
        DimCodes[DimIndex] := NewDimCode;
        LibraryDimension.RunChangeGlobalDimensions(DimCodes[1], DimCodes[2]);
    end;

    local procedure SetServiceDimensionPriorities(SalesPersonPriority: Integer; ServiceContractPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup."Service Management");
        CreateDefaultDimensionPriority(SourceCodeSetup."Service Management", DATABASE::"Salesperson/Purchaser", SalesPersonPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup."Service Management", DATABASE::"Service Contract Header", ServiceContractPriority);
    end;

    local procedure SetPurchaseDimensionPriorities(ItemPriority: Integer; JobPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup.Purchases);
        CreateDefaultDimensionPriority(SourceCodeSetup.Purchases, DATABASE::Item, ItemPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup.Purchases, DATABASE::Job, JobPriority);
    end;

    local procedure SetSalesDimensionPriorities(ItemPriority: Integer; JobPriority: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ClearDefaultDimensionPriorities(SourceCodeSetup.Sales);
        CreateDefaultDimensionPriority(SourceCodeSetup.Sales, DATABASE::Item, ItemPriority);
        CreateDefaultDimensionPriority(SourceCodeSetup.Sales, DATABASE::Job, JobPriority);
    end;

    local procedure CreateReqLine(var ReqLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        Item: Record Item;
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst;
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Item.Get(ItemNo);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate, WorkDate);
        FindReqLine(ReqLine, Item."No.");
    end;

    local procedure FindReqLine(var ReqLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", ItemNo);
        ReqLine.FindFirst;
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; VendNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchHeader.FindLast;
        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            SetRange(Type, Type::Item);
            FindFirst;
        end;
    end;

    local procedure FindJobJnlLine(var JobJournalLine: Record "Job Journal Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        with JobJournalLine do begin
            SetRange("Job No.", JobNo);
            SetRange("Job Task No.", JobTaskNo);
            FindSet;
        end;
    end;

    local procedure FindSalesLineFromJobPlanningLine(var SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        with JobPlanningLineInvoice do begin
            SetRange("Job No.", JobPlanningLine."Job No.");
            SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
            SetRange("Document Type", "Document Type"::Invoice);
            FindFirst;
            SalesLine.SetRange("Document No.", "Document No.");
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
            SalesLine.FindFirst;
        end
    end;

    local procedure SetTablePriority(var TableIDs: array[2] of Integer; var Priorities: array[2] of Integer; TableID: Integer; Priority: Integer; Index: Integer)
    begin
        TableIDs[Index] := TableID;
        Priorities[Index] := Priority;
    end;

    local procedure VerifyDimensionSetID(var DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Compare dimension set on the "Customer" / "G/L Account" to that on the journal line
        DefaultDimension.FindSet;
        repeat
            DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
            DimensionSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
            DimensionSetEntry.FindFirst;
            Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DefaultDimension."Dimension Value Code", 'Dimension value mismatch');
        until DefaultDimension.Next = 0;
    end;

    local procedure CreateDefaultDimensionPriority(SourceCode: Code[10]; TableID: Integer; Priority: Integer)
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        LibraryDimension.CreateDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, TableID);
        DefaultDimensionPriority.Validate(Priority, Priority);
        DefaultDimensionPriority.Modify(true);
    end;

    local procedure FindDefaultDimensionPriority(var DefaultDimensionPriority: Record "Default Dimension Priority"; SourceCode: Code[10]; TableID: Integer)
    begin
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.SetRange("Table ID", TableID);
        DefaultDimensionPriority.FindFirst;
    end;

    local procedure SetDefaultDimensionPriority(SourceCode: Code[10])
    begin
        // Create default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account must created with source code.
        ClearDefaultDimensionPriorities(SourceCode);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::Customer, 1);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::Vendor, 1);
        CreateDefaultDimensionPriority(SourceCode, DATABASE::"G/L Account", 2);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    local procedure VerifyDefaultDimensionPriority(SourceCode: Code[10])
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        // Verify default dimension priority 1 for Customer, 1 for Vendor and  2 for G/L Account must created with source code.
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::Customer);
        DefaultDimensionPriority.TestField(Priority, 1);
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::Vendor);
        DefaultDimensionPriority.TestField(Priority, 1);
        FindDefaultDimensionPriority(DefaultDimensionPriority, SourceCode, DATABASE::"G/L Account");
        DefaultDimensionPriority.TestField(Priority, 2);
    end;

    local procedure VerifyDimValueInPurchLine(VendNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        PurchLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindPurchLine(PurchLine, VendNo);
        DimensionSetEntry.Get(PurchLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", WrongDimValueCodeErr);
    end;

    local procedure VerifyDimValueInJobJnlLine(JobNo: Code[20]; JobTaskNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        FindJobJnlLine(JobJournalLine, JobNo, JobTaskNo);
        DimensionSetEntry.Get(JobJournalLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionValueCode, DimensionSetEntry."Dimension Value Code", WrongDimValueCodeErr);
    end;

    local procedure VerifyPurchaseLineDimensionValue(PurchaseLine: Record "Purchase Line"; DimensionValueCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, PurchaseLine."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifySalesLineDimensionValue(SalesLine: Record "Sales Line"; DimensionValueCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, SalesLine."Dimension Set ID");
        DimSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToInvoiceHandler(var RequestPage: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        RequestPage.OK.Invoke
    end;
}

