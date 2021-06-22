codeunit 134118 "Price List Header UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Header]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        StartingDateErr: Label 'Starting Date cannot be after Ending Date.';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';
        AssetTypeForUOMErr: Label 'Asset Type must be equal to Item or Resource.';
        AssetTypeMustBeItemErr: Label 'Asset Type must be equal to ''Item''';
        NotPostingJobTaskTypeErr: Label 'Job Task Type must be equal to ''Posting''';
        CodeMustNotBeBlankErr: Label 'Code must have a value in Price List';
        IsInitialized: Boolean;

    [Test]
    procedure T001_ManualCode()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;

        PriceListHeader.Validate(Code, LibraryUtility.GenerateGUID());
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PriceListHeader.TestField("No. Series", '');
    end;

    [Test]
    procedure T002_CodeBySalesNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Customer;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        SalesReceivablesSetup.Get();
        PriceListHeader.TestField("No. Series", SalesReceivablesSetup."Price List Nos.");
    end;

    [Test]
    procedure T003_CodeByPurchaseNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Vendor;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        PurchasesPayablesSetup.Get();
        PriceListHeader.TestField("No. Series", PurchasesPayablesSetup."Price List Nos.");
    end;

    [Test]
    procedure T004_CodeByJobsNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
        JobsSetup: Record "Jobs Setup";
    begin
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader."Source Group" := PriceListHeader."Source Group"::Job;
        PriceListHeader.Insert(true);

        PriceListHeader.Testfield(Code);
        JobsSetup.Get();
        PriceListHeader.TestField("No. Series", JobsSetup."Price List Nos.");
    end;

    [Test]
    procedure T004_CodeByAllNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::All;
        asserterror PriceListHeader.Insert(true);
        Assert.ExpectedError(CodeMustNotBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T009_LookupSourceNoCustomer()
    var
        PriceListHeader: Record "Price List Header";
        MockPriceListHeader: TestPage "Mock Price List Header";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        Initialize();
        // [GIVEN] Header, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, PriceListHeader."Source Type"::"All Customers", '');
        Commit();
        // [GIVEN] Open Price List Header page and set "Source Type" aas 'Customer'
        MockPriceListHeader.Trap();
        PriceListHeader.SetRecFilter();
        Page.Run(Page::"Mock Price List Header", PriceListHeader);
        MockPriceListHeader."Source Type".SetValue(PriceListHeader."Source Type"::Customer);

        // [WHEN] Lookup "Source No." to pick Customer 'X'
        SourceNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(SourceNo); // CustomerNo to LookupCustomerModalHandler
        MockPriceListHeader."Source No.".Lookup();

        // [THEN] Header, where "Source Type" is Customer, "Source No." is 'X'
        PriceListHeader.Find();
        // Fails in AL test but OK in manual test
        asserterror PriceListHeader.TestField("Source No.", SourceNo);
        Assert.KnownFailure('Source No. must be equal to', 352195);
    end;

    [Test]
    procedure T010_ChangedSourceTypeValidation()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Header, where all fields are filled, "Source Type" = 'Job Task'
        NewSourceJobTask(PriceListHeader);

        // [WHEN] Validate "Source Type" as 'Vendor'
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::Vendor);

        // [THEN] "Source No.", "Parent Source No.", "Source ID" are blank, "Source Type" = 'Vendor', "Source Group" =  'Vendor'
        PriceListHeader.Testfield("Source Type", PriceListHeader."Source Type"::Vendor);
        PriceListHeader.Testfield("Source Group", PriceListHeader."Source Group"::Vendor);
        VerifyBlankSource(PriceListHeader);
    end;

    [Test]
    procedure T011_JobTask_ChangedSourceNoValidation()
    var
        NewPriceListHeader: Record "Price List Header";
        PriceListHeader: Record "Price List Header";
        JobNo: Code[20];
    begin
        // [FEATURE] [Job Task]
        Initialize();
        // [GIVEN] Price Source, where "Source Type" = 'Job Task', "Job Task No." is 'JT', Job No." is 'J'
        NewSourceJobTask(PriceListHeader);
        JobNo := PriceListHeader."Parent Source No.";

        // [GIVEN] JobTask, where "Job Task No." is 'X', Job No." is 'J', SystemId is 'A'
        NewPriceListHeader."Parent Source No." := JobNo;
        NewSourceJobTask(NewPriceListHeader);

        // [WHEN] Validate "Source No." as 'X'
        PriceListHeader.Validate("Source No.", NewPriceListHeader."Source No.");

        // [THEN] "Source No." is 'X', "Parent Source No." = 'J', "Source ID" is 'A', "Source Type" = 'Job Task'
        PriceListHeader.Testfield("Source Type", PriceListHeader."Source Type"::"Job Task");
        PriceListHeader.Testfield("Parent Source No.", JobNo);
        PriceListHeader.Testfield("Source No.", NewPriceListHeader."Source No.");
        PriceListHeader.Testfield("Source ID", NewPriceListHeader."Source ID");
    end;

    [Test]
    procedure T012_JobTask_IsSourceNoAllowed()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"Job Task");
        Assert.IsTrue(PriceListHeader.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    procedure T020_ValidateStartingDateAfterEndingDate()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Line, where  "Ending Date" is '310120'
        PriceListHeader.Init();
        PriceListHeader."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010220'
        asserterror PriceListHeader.Validate("Starting Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    procedure T021_ValidateEndingDateBeforeStartingDate()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Line, where "Starting Date" is '010220'
        PriceListHeader.Init();
        PriceListHeader."Starting Date" := WorkDate();
        // [WHEN] Set "Ending Date" as '310120'
        asserterror PriceListHeader.Validate("Ending Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    procedure T022_ValidateStartingDateForCampaign()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Ending Date" is '310120'
        PriceListHeader.Init();
        PriceListHeader."Source Type" := PriceListHeader."Source Type"::Campaign;
        PriceListHeader."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010120'
        asserterror PriceListHeader.Validate("Starting Date", WorkDate() + 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T023_ValidateCampaignNoSetsDates()
    var
        Campaign: Record Campaign;
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Campaign 'C', where "Starttin Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" and "Ending Date" are <blank>
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::Campaign);

        // [WHEN] Set "Source No." as 'C'
        PriceListHeader.Validate("Source No.", Campaign."No.");

        // [THEN] Price List Header, where "Starting Date" is '010120', "Ending Date" is '310120'
        VerifyDates(PriceListHeader, Campaign."Starting Date", Campaign."Ending Date");
    end;

    [Test]
    procedure T100_DeletePricesOnCampaignDeletion()
    var
        Campaign: array[2] of Record Campaign;
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        SourceType := SourceType::Campaign;
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor(SourceType, Campaign[1]."No.", Campaign[2]."No.");

        // [WHEN] Delete Campaign 'A'
        Campaign[1].Delete(true);

        // [THEN] Price list headers and lines for Campaign 'A' are deleted, for Campaign 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', Campaign[1]."No.", Campaign[2]."No.");
    end;

    [Test]
    procedure T101_DeletePricesOnContactDeletion()
    var
        Contact: Array[2] of Record Contact;
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        SourceType := SourceType::Contact;
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor(SourceType, Contact[1]."No.", Contact[2]."No.");

        // [WHEN] Delete Contact 'A'
        Contact[1].Delete(true);

        // [THEN] Price list headers and lines for Contact 'A' are deleted, for Contact 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', Contact[1]."No.", Contact[2]."No.");
    end;

    [Test]
    procedure T102_DeletePricesOnCustomerDeletion()
    var
        Customer: Array[2] of Record Customer;
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        SourceType := SourceType::Customer;
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor(SourceType, Customer[1]."No.", Customer[2]."No.");

        // [WHEN] Delete Customer 'A'
        Customer[1].Delete(true);

        // [THEN] Price list headers and lines for Customer 'A' are deleted, for Customer 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', Customer[1]."No.", Customer[2]."No.");
    end;

    [Test]
    procedure T103_DeletePricesOnCustomerPriceGroupDeletion()
    var
        CustomerPriceGroup: Array[2] of Record "Customer Price Group";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        SourceType := SourceType::"Customer Price Group";
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor(SourceType, CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerPriceGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Price Group 'A' are deleted, for Customer Price Group 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T104_DeletePricesOnCustomerDiscGroupDeletion()
    var
        CustomerDiscountGroup: Array[2] of Record "Customer Discount Group";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        SourceType := SourceType::"Customer Disc. Group";
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor(SourceType, CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerDiscountGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Disc. Group 'A' are deleted, for Customer Disc. Group 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T105_DeletePricesOnVendorDeletion()
    var
        Vendor: Array[2] of Record Vendor;
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        SourceType := SourceType::Vendor;
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor(SourceType, Vendor[1]."No.", Vendor[2]."No.");

        // [WHEN] Delete Vendor 'A'
        Vendor[1].Delete(true);

        // [THEN] Price list headers and lines for Vendor 'A' are deleted, for Vendor 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', Vendor[1]."No.", Vendor[2]."No.");
    end;

    [Test]
    procedure T106_DeletePricesOnJobDeletion()
    var
        Job: Array[2] of Record Job;
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        SourceType := SourceType::Job;
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor(SourceType, Job[1]."No.", Job[2]."No.");

        // [WHEN] Delete Job 'A'
        Job[1].Delete(true);

        // [THEN] Price list headers and lines for Job 'A' are deleted, for Job 'B' are not deleted
        VerifyPricesDeleted(SourceType, '', Job[1]."No.", Job[2]."No.");
    end;

    [Test]
    procedure T107_DeletePricesOnJobTaskDeletion()
    var
        Job: Record Job;
        JobTask: Array[2] of Record "Job Task";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        SourceType := SourceType::"Job Task";
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor(SourceType, JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Delete Job 'A'
        JobTask[1].Delete(true);

        // [THEN] Price list headers and lines for JobTask 'A' are deleted, for JobTask 'B' are not deleted
        VerifyPricesDeleted(SourceType, Job."No.", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.");
    end;

    [Test]
    procedure T110_ModifyPricesOnCampaignRename()
    var
        Campaign: array[2] of Record Campaign;
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        SourceType := SourceType::Campaign;
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor(SourceType, Campaign[1]."No.", Campaign[2]."No.");

        // [WHEN] Rename Campaign 'A' to 'X'
        OldNo := Campaign[1]."No.";
        Campaign[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Campaign 'A' are modified to 'X', for Campaign 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', Campaign[1]."No.", OldNo, Campaign[2]."No.");
    end;

    [Test]
    procedure T111_ModifyPricesOnContactRename()
    var
        Contact: Array[2] of Record Contact;
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        SourceType := SourceType::Contact;
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor(SourceType, Contact[1]."No.", Contact[2]."No.");

        // [WHEN] Rename Contact 'A' to 'X'
        OldNo := Contact[1]."No.";
        Contact[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Contact 'A' are modified to 'X', for Contact 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', Contact[1]."No.", OldNo, Contact[2]."No.");
    end;

    [Test]
    procedure T112_ModifyPricesOnCustomerRename()
    var
        Customer: Array[2] of Record Customer;
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        SourceType := SourceType::Customer;
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor(SourceType, Customer[1]."No.", Customer[2]."No.");

        // [WHEN] Rename Customer 'A' to 'X'
        OldNo := Customer[1]."No.";
        Customer[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Customer 'A' are modified to 'X', for Customer 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', Customer[1]."No.", OldNo, Customer[2]."No.");
    end;

    [Test]
    procedure T113_ModifyPricesOnCustomerPriceGroupRename()
    var
        CustomerPriceGroup: Array[2] of Record "Customer Price Group";
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        SourceType := SourceType::"Customer Price Group";
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor(SourceType, CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);

        // [WHEN] Rename CustomerPriceGroup 'A' to 'X'
        OldNo := CustomerPriceGroup[1].Code;
        CustomerPriceGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerPriceGroup 'A' are modified to 'X', for CustomerPriceGroup 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', CustomerPriceGroup[1].Code, OldNo, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T114_ModifyPricesOnCustomerDiscGroupRename()
    var
        CustomerDiscountGroup: Array[2] of Record "Customer Discount Group";
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        SourceType := SourceType::"Customer Disc. Group";
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor(SourceType, CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);

        // [WHEN] Rename CustomerDiscountGroup 'A' to 'X'
        OldNo := CustomerDiscountGroup[1].Code;
        CustomerDiscountGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerDiscountGroup 'A' are modified to 'X', for CustomerDiscountGroup 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', CustomerDiscountGroup[1].Code, OldNo, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T115_ModifyPricesOnVendorRename()
    var
        Vendor: Array[2] of Record Vendor;
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        SourceType := SourceType::Vendor;
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor(SourceType, Vendor[1]."No.", Vendor[2]."No.");

        // [WHEN] Rename Vendor 'A' to 'X'
        OldNo := Vendor[1]."No.";
        Vendor[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Vendor 'A' are modified to 'X', for Vendor 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', Vendor[1]."No.", OldNo, Vendor[2]."No.");
    end;

    [Test]
    procedure T116_ModifyPricesOnJobRename()
    var
        Job: Array[2] of Record Job;
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        SourceType := SourceType::Job;
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor(SourceType, Job[1]."No.", Job[2]."No.");

        // [WHEN] Rename Job 'A' to 'X'
        OldNo := Job[1]."No.";
        Job[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Job 'A' are modified to 'X', for Job 'B' are not deleted
        VerifyPricesRenamed(SourceType, '', Job[1]."No.", OldNo, Job[2]."No.");
    end;

    [Test]
    procedure T117_ModifyPricesOnJobTaskRename()
    var
        Job: Record Job;
        JobTask: Array[2] of Record "Job Task";
        SourceType: Enum "Price Source Type";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        SourceType := SourceType::"Job Task";
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor(SourceType, JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Rename Job Task 'A' to 'X'
        OldNo := JobTask[1]."Job Task No.";
        JobTask[1].Rename(Job."No.", LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for JobTask 'A' are modified to 'X', for JobTask 'B' are not deleted
        VerifyPricesRenamed(SourceType, Job."No.", JobTask[1]."Job Task No.", OldNo, JobTask[2]."Job Task No.");
    end;

    [Test]
    procedure T120_CopyJobWIthPrices()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListHeader: Array[2] of Record "Price List Header";
        NewPriceListHeader: Record "Price List Header";
        PriceListLine: Array[6] of Record "Price List Line";
        NewPriceListLine: Record "Price List Line";
        CopyJob: Codeunit "Copy Job";
        NewJobNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Job 'J' with Job Task 'JT'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price List, where "Source Type" is 'Job', "Source No." is 'J'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], PriceListHeader[1]."Source Type"::Job, Job."No.");
        FillPriceListHeader(PriceListHeader[1]);
        LibraryPriceCalculation.CreatePriceLine(PriceListLine[1], PriceListHeader[1].Code, PriceListLine[1]."Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceLine(PriceListLine[2], PriceListHeader[1].Code, PriceListLine[1]."Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List, where "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'J'
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], PriceListHeader[2]."Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        FillPriceListHeader(PriceListHeader[2]);
        LibraryPriceCalculation.CreatePriceLine(PriceListLine[3], PriceListHeader[2].Code, PriceListLine[1]."Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceLine(PriceListLine[4], PriceListHeader[2].Code, PriceListLine[1]."Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List Line, where 'Price List Code' is <blank>, "Source Type" is 'Job', "Source No." is 'J'
        PriceListLine[5] := PriceListLine[1];
        PriceListLine[5]."Price List Code" := '';
        PriceListLine[5]."Line No." := 0;
        PriceListLine[5].Insert();
        // [GIVEN] Price List Line, where 'Price List Code' is <blank>, "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'J'
        PriceListLine[6] := PriceListLine[3];
        PriceListLine[6]."Price List Code" := '';
        PriceListLine[6]."Line No." := 0;
        PriceListLine[6].Insert();

        // [WHEN] Copy Job 'J' as 'NewJ'
        NewJobNo := LibraryUtility.GenerateGUID();
        CopyJob.SetCopyOptions(true, false, false, 0, 0, 0);
        CopyJob.CopyJob(Job, NewJobNo, '', '');

        // [THEN] Job 'NewJ' with  Job Task 'JT'
        Job.Get(NewJobNo);
        JobTask.Get(NewJobNo, JobTask."Job Task No.");
        // [GIVEN] Price List, where "Source Type" is 'Job', "Source No." is 'NewJ'
        NewPriceListHeader.SetRange("Source Type", NewPriceListHeader."Source Type"::Job);
        NewPriceListHeader.SetRange("Source No.", NewJobNo);
        Assert.RecordCount(NewPriceListHeader, 1);
        NewPriceListHeader.FindFirst();
        NewPriceListHeader.TestField(Description, PriceListHeader[1].Description);
        NewPriceListHeader.TestField("Currency Code", PriceListHeader[1]."Currency Code");
        NewPriceListHeader.TestField("Starting Date", PriceListHeader[1]."Starting Date");
        NewPriceListHeader.TestField("Ending Date", PriceListHeader[1]."Ending Date");

        NewPriceListLine.Reset();
        NewPriceListLine.SetRange("Source Type", NewPriceListLine."Source Type"::Job);
        NewPriceListLine.SetRange("Source No.", NewJobNo);
        Assert.RecordCount(NewPriceListLine, 3);
        NewPriceListLine.SetRange("Price List Code", NewPriceListHeader.Code);
        Assert.RecordCount(NewPriceListLine, 2);
        // [GIVEN] Price List, where "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'NewJ'
        NewPriceListHeader.Reset();
        NewPriceListHeader.SetRange("Source Type", NewPriceListHeader."Source Type"::"Job Task");
        NewPriceListHeader.SetRange("Parent Source No.", NewJobNo);
        NewPriceListHeader.SetRange("Source No.", JobTask."Job Task No.");
        Assert.RecordCount(NewPriceListHeader, 1);
        NewPriceListHeader.FindFirst();
        NewPriceListHeader.TestField(Description, PriceListHeader[2].Description);
        NewPriceListHeader.TestField("Currency Code", PriceListHeader[2]."Currency Code");
        NewPriceListHeader.TestField("Starting Date", PriceListHeader[2]."Starting Date");
        NewPriceListHeader.TestField("Ending Date", PriceListHeader[2]."Ending Date");

        NewPriceListLine.Reset();
        NewPriceListLine.SetRange("Source Type", NewPriceListLine."Source Type"::"Job Task");
        NewPriceListLine.SetRange("Parent Source No.", NewJobNo);
        NewPriceListLine.SetRange("Source No.", JobTask."Job Task No.");
        Assert.RecordCount(NewPriceListLine, 3);
        NewPriceListLine.SetRange("Price List Code", NewPriceListHeader.Code);
        Assert.RecordCount(NewPriceListLine, 2);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price List Header UT");
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price List Header UT");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price List Header UT");
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20]; ParentSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, SourceType, ParentSourceNo, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceLine(
            PriceListLine, PriceListHeader.Code, PriceListLine."Asset Type"::Resource, '');

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, SourceType, ParentSourceNo, SourceNo);
        LibraryPriceCalculation.CreatePriceLine(
            PriceListLine, PriceListHeader.Code, PriceListLine."Asset Type"::Resource, '');
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, SourceType, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceLine(
            PriceListLine, PriceListHeader.Code, PriceListLine."Asset Type"::Item, '');

        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, SourceType, SourceNo);
        LibraryPriceCalculation.CreatePriceLine(
            PriceListLine, PriceListHeader.Code, PriceListLine."Asset Type"::Item, '');
    end;

    local procedure FillPriceListHeader(var PriceListHeader: Record "Price List Header")
    var
        Currency: Record Currency;
    begin
        PriceListHeader.Description := LibraryUtility.GenerateGUID();
        PriceListHeader."Starting Date" := LibraryRandom.RandDate(50);
        PriceListHeader."Ending Date" := PriceListHeader."Starting Date" + 30;
        LibraryERM.CreateCurrency(Currency);
        PriceListHeader."Currency Code" := Currency.Code;
        PriceListHeader.Modify();
    end;

    local procedure NewSourceJobTask(var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource.NewEntry(PriceSource."Source Type"::"Job Task", 0);
        PriceSource."Parent Source No." := PriceListHeader."Parent Source No.";
        PriceSource.Validate("Source No.", NewJobTask(PriceSource."Parent Source No.", PriceSource."Source ID"));
        PriceListHeader.CopyFrom(PriceSource);
    end;

    local procedure NewJobTask(var JobNo: Code[20]; var SystemID: Guid) JobTaskNo: Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not Job.Get(JobNo) then begin
            LibraryJob.CreateJob(Job);
            JobNo := Job."No.";
        end;
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTaskNo := JobTask."Job Task No.";
        SystemID := JobTask.SystemId;
    end;

    local procedure VerifyBlankSource(PriceListHeader: Record "Price List Header")
    var
        BlankGuid: Guid;
    begin
        with PriceListHeader do begin
            Testfield("Parent Source No.", '');
            Testfield("Source No.", '');
            Testfield("Source ID", BlankGuid);
        end;
    end;

    local procedure VerifyDates(PriceListHeader: Record "Price List Header"; StartingDate: Date; EndingDate: Date)
    begin
        PriceListHeader.TestField("Starting Date", StartingDate);
        PriceListHeader.TestField("Ending Date", EndingDate);
    end;

    local procedure VerifyPricesDeleted(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; DeletedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", DeletedSourceNo);
        Assert.RecordIsEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceListLine.SetRange("Source No.", DeletedSourceNo);
        Assert.RecordIsEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
    end;

    local procedure VerifyPricesRenamed(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; NewSourceNo: Code[20]; RenamedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", RenamedSourceNo);
        Assert.RecordIsEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", NewSourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);
        PriceListHeader.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListHeader);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceListLine.SetRange("Source No.", RenamedSourceNo);
        Assert.RecordIsEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", NewSourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
        PriceListLine.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(PriceListLine);
    end;

    [ModalPageHandler]
    procedure LookupCustomerModalHandler(var CustomerList: testpage "Customer List")
    begin
        CustomerList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerList.OK().Invoke();
    end;
}
