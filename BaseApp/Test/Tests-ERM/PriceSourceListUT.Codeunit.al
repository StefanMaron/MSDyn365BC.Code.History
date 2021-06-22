codeunit 134121 "Price Source List UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Source] [List]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure T001_AddTwiceThenGetList()
    var
        TempPriceSource: Record "Price Source" temporary;
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [WHEN] Add "All Customers" and "All Vendors" sources
        PriceSourceList.Add(SourceType::"All Customers");
        PriceSourceList.Add(SourceType::"All Vendors");
        // [THEN] GetList returns two records
        PriceSourceList.GetList(TempPriceSource);
        Assert.RecordCount(TempPriceSource, 2);
    end;

    [Test]
    procedure T002_AddBlankCustomerSource()
    var
        TempPriceSource: Record "Price Source" temporary;
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [WHEN] Add "Customer" source with <blank> "Source No."
        PriceSourceList.Add(SourceType::"Customer", '');
        // [THEN] GetList returns zero records
        PriceSourceList.GetList(TempPriceSource);
        Assert.RecordCount(TempPriceSource, 0);
    end;

    [Test]
    procedure T003_FirstNextOnThreeSources()
    var
        Job: Record Job;
        JobTask: record "Job Task";
        TempPriceSource: Record "Price Source" temporary;
        PriceSource: Record "Price Source";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Job and Job Task, where "Job No." is 'Job', "Job Task No." is 'Task'
        Job.Init();
        Job."No." := 'Job';
        if Job.Insert() then;
        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := 'Task';
        if JobTask.Insert() then;

        // [WHEN] Add "All Jobs", "Job" as 'Job', "Job Task" as 'Task' sources
        PriceSourceList.Add(SourceType::"All Jobs");
        PriceSourceList.Add(SourceType::"Job", 'Job');
        PriceSourceList.Add(SourceType::"Job Task", 'Job', 'Task');
        // [THEN] GetList returns 3 records
        PriceSourceList.GetList(TempPriceSource);
        Assert.RecordCount(TempPriceSource, 3);
        // [THEN] List.First() returns 'All Jobs'
        Assert.IsTrue(PriceSourceList.First(PriceSource, 0), 'First');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"All Jobs");
        PriceSource.TestField("Source No.", '');
        // [THEN] List.Next() returns 'Job' as 'Job'
        Assert.IsTrue(PriceSourceList.Next(PriceSource), '1st Next');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"Job");
        PriceSource.TestField("Source No.", 'Job');
        // [THEN] List.Next() returns 'Job Task' as 'Task'
        Assert.IsTrue(PriceSourceList.Next(PriceSource), '2nd Next');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.TestField("Source No.", 'Task');
        // [THEN] List.Next() returns <False> and blank Source.
        Assert.IsFalse(PriceSourceList.Next(PriceSource), '3rd Next should fail');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::All);
        PriceSource.TestField("Source No.", '');
    end;

    [Test]
    procedure T004_FirstNextOnThreeLevels()
    var
        Job: Record Job;
        JobTask: record "Job Task";
        TempPriceSource: Record "Price Source" temporary;
        PriceSource: Record "Price Source";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
        Level: array[2] of Integer;
    begin
        Initialize();
        // [GIVEN] Job and Job Task, where "Job No." is 'Job', "Job Task No." is 'Task'
        Job.Init();
        Job."No." := 'Job';
        if Job.Insert() then;
        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := 'Task';
        if JobTask.Insert() then;

        // [GIVEN] Add "Job Task" as 'Task' at level 2
        PriceSourceList.SetLevel(2);
        PriceSourceList.Add(SourceType::"Job Task", 'Job', 'Task');

        // [GIVEN] Add "Job" as 'Job', at level 1
        PriceSourceList.SetLevel(1);
        PriceSourceList.Add(SourceType::"Job", 'Job');

        // [GIVEN] Add "All Jobs", at level 0
        PriceSourceList.SetLevel(0);
        PriceSourceList.Add(SourceType::"All Jobs");

        // [THEN] GetList returns 3 records
        PriceSourceList.GetList(TempPriceSource);
        Assert.RecordCount(TempPriceSource, 3);

        // [THEN] GetMaxLevel() returns 2
        PriceSourceList.GetMinMaxLevel(Level);
        Assert.AreEqual(0, Level[1], 'MimLevel');
        Assert.AreEqual(2, Level[2], 'MaxLevel');

        // [THEN] List.First(0) returns 'All Jobs', Next() returns false
        Assert.IsTrue(PriceSourceList.First(PriceSource, 0), 'First at level 0');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"All Jobs");
        PriceSource.TestField("Source No.", '');
        Assert.IsFalse(PriceSourceList.Next(PriceSource), '1st Next at Level 0');

        // [THEN] List.First(1) returns 'Job' as 'Job'
        Assert.IsTrue(PriceSourceList.First(PriceSource, 1), 'First at level 1');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"Job");
        PriceSource.TestField("Source No.", 'Job');
        Assert.IsFalse(PriceSourceList.Next(PriceSource), '1st Next at Level 1');

        // [THEN] List.First(2) returns 'Job Task' as 'Task'
        Assert.IsTrue(PriceSourceList.First(PriceSource, 2), 'First at level 2');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.TestField("Source No.", 'Task');
        // [THEN] List.Next() returns <False> and blank Source.
        Assert.IsFalse(PriceSourceList.Next(PriceSource), '1st Next at Level 2');
        PriceSource.TestField("Source Type", PriceSource."Source Type"::All);
        PriceSource.TestField("Source No.", '');
    end;

    [Test]
    procedure T100_GetSourceGroupFromListOfNoGroups()
    var
        Campaign: Record Campaign;
        Customer: Record Customer;
        Job: Record Job;
        Vendor: Record Vendor;
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Campaign 'C', "Customer Disc. Group" 'CDG' are in the list
        PriceSourceList.Add(SourceType::"Customer Disc. Group", 'CDG');
        LibraryMarketing.CreateCampaign(Campaign);
        PriceSourceList.Add(SourceType::Campaign, Campaign."No.");
        // [WHEN] GetSourceGroup()
        Assert.IsFalse(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup), 'GetSourceGroup');
        // [THEN] "Source Group" is not found
        DtldPriceCalculationSetup.TestField("Source Group", 0);
        DtldPriceCalculationSetup.TestField("Source No.", '');
    end;

    [Test]
    procedure T101_GetSourceGroupFromListWithGroupAndNonGroup()
    var
        Campaign: Record Campaign;
        Customer: Record Customer;
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Customer 'C', Campaign 'Camp' are in the list
        LibraryMarketing.CreateCampaign(Campaign);
        PriceSourceList.Add(SourceType::Campaign, Campaign."No.");
        LibrarySales.CreateCustomer(Customer);
        PriceSourceList.Add(SourceType::Customer, Customer."No.");
        // [WHEN] GetSourceGroup()
        Assert.IsTrue(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup), 'GetSourceGroup');
        // [THEN] Found Customer 'C'
        DtldPriceCalculationSetup.TestField("Source Group", DtldPriceCalculationSetup."Source Group"::Customer);
        DtldPriceCalculationSetup.TestField("Source No.", Customer."No.");
    end;

    [Test]
    procedure T102_GetSourceGroupFromListOf3Groups()
    var
        Customer: Record Customer;
        Job: Record Job;
        Vendor: Record Vendor;
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Customer 'C', Vendor 'V', Job 'J' are in the list
        LibraryJob.CreateJob(Job);
        PriceSourceList.Add(SourceType::Job, Job."No.");
        LibraryPurchase.CreateVendor(Vendor);
        PriceSourceList.Add(SourceType::Vendor, Vendor."No.");
        LibrarySales.CreateCustomer(Customer);
        PriceSourceList.Add(SourceType::Customer, Customer."No.");
        // [WHEN] GetSourceGroup()
        Assert.IsTrue(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup), 'GetSourceGroup');
        // [THEN] Found Job 'J' (as it is the first in the list)
        DtldPriceCalculationSetup.TestField("Source Group", DtldPriceCalculationSetup."Source Group"::Job);
        DtldPriceCalculationSetup.TestField("Source No.", Job."No.");
    end;

    [Test]
    procedure T103_GetSourceGroupFromListWithGroupsOnThreeLevels()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Customer 'C' (level 0), Job 'J' (level 1), Job Task 'JT' (level 2) are in the list
        LibrarySales.CreateCustomer(Customer);
        PriceSourceList.Add(SourceType::Customer, Customer."No.");
        LibraryJob.CreateJob(Job);
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::Job, Job."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::"Job Task", Job."No.", JobTask."Job Task No.");
        // [WHEN] GetSourceGroup()
        Assert.IsTrue(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup), 'GetSourceGroup');
        // [THEN] Found Job 'J' (as Job Task at higher level, but returns Job)
        DtldPriceCalculationSetup.TestField("Source Group", DtldPriceCalculationSetup."Source Group"::Job);
        DtldPriceCalculationSetup.TestField("Source No.", Job."No.");
    end;

    [Test]
    procedure T104_GetSourceGroupFromListWithAllGroupOnHigherLevel()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
        PriceSourceList: Codeunit "Price Source List";
        SourceType: Enum "Price Source Type";
    begin
        Initialize();
        // [GIVEN] Job Task 'JT' (level 1), Job 'J' (level 2), All Customers (level 3) are in the list
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        PriceSourceList.Add(SourceType::"Job Task", Job."No.", JobTask."Job Task No.");
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::Job, Job."No.");
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::"All Customers");
        // [WHEN] GetSourceGroup()
        Assert.IsTrue(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup), 'GetSourceGroup');
        // [THEN] Found Job 'J' (as Job at higher level than Job Task, while All Customers is skipped)
        DtldPriceCalculationSetup.TestField("Source Group", DtldPriceCalculationSetup."Source Group"::Job);
        DtldPriceCalculationSetup.TestField("Source No.", Job."No.");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Source List UT");
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Source List UT");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Source List UT");
    end;


}