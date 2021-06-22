codeunit 134123 "Price List Line UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Line]
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
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemUOMModalHandler')]
    procedure T001_LookupItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Item] [Unit Of Measure]
        Initialize();
        // [GIVEN] Item 'I', and one Item UoM 'X'
        LibraryInventory.CreateItem(Item);
        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
        ItemUnitofMeasure.DeleteAll();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 134123);
        // [GIVEN] Price List Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Unit of Measure Code".Lookup();

        // [THEN] Page "Item Unit Of Measure" shows one record with 'X'
        Assert.AreEqual(ItemUnitofMeasure.Code, LibraryVariableStorage.DequeueText(), 'UoM Code');
        Assert.AreEqual(
            ItemUnitofMeasure."Qty. per Unit of Measure",
            LibraryVariableStorage.DequeueDecimal(), 'Qty. per Unit of Measure');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next line is found');
    end;

    [Test]
    [HandlerFunctions('ItemVariantsHandler')]
    procedure T002_LookupVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Item] [Variant]
        Initialize();
        // [GIVEN] Item 'I', and one Variant 'X'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Price List Line, where "Asset Type" is Item, "Asset No."" is 'I'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup "Valiant Code" in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Variant Code".Lookup();

        // [THEN] Page "Item Variants" shows one record with 'X'
        Assert.AreEqual(ItemVariant.Code, LibraryVariableStorage.DequeueText(), 'Variant Code');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next Variant is found');
    end;

    [Test]
    [HandlerFunctions('ResourceUOMModalHandler')]
    procedure T003_LookupRersourceUnitOfMeasure()
    var
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        PriceListLine: Record "Price List Line";
        UnitofMeasure: Record "Unit of Measure";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset] [Resource] [Unit Of Measure]
        Initialize();
        // [GIVEN] Resource 'R', and one UoM 'X'
        LibraryResource.CreateResource(Resource, '');
        ResourceUnitofMeasure.SetRange("Resource No.", Resource."No.");
        ResourceUnitofMeasure.DeleteAll();
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitofMeasure, Resource."No.", UnitofMeasure.Code, 1);
        // [GIVEN] Price List Line, where "Asset Type" is Resource, "Asset No."" is 'R'
        PriceListLine.Init();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.Validate("Asset No.", Resource."No.");
        PriceListLine.Insert();

        // [WHEN] Lookup Unit Of Measure in Line
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine);
        MockPriceListLine."Unit of Measure Code".Lookup();

        // [THEN] Page "Item Unit Of Measure" shows one record with 'X'
        Assert.AreEqual(ResourceUnitofMeasure.Code, LibraryVariableStorage.DequeueText(), 'UoM Code');
        Assert.AreEqual(
            ResourceUnitofMeasure."Qty. per Unit of Measure",
            LibraryVariableStorage.DequeueDecimal(), 'Qty. per Unit of Measure');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Next line is found');
    end;

    [Test]
    procedure T010_ValidateSourceNo()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        // [WHEN] Enter "Source No." set as 'C'
        MockPriceListLine."Source No.".SetValue(Customer."No.");
        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
        MockPriceListLine."Source ID".AssertEquals(Customer.SystemId);
    end;

    [Test]
    procedure T011_ReValidateSourceType()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        // [SCENARIO] Revalidated unchanged "Source Type" does not change the source
        Initialize();
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        MockPriceListLine."Source No.".SetValue(Customer."No.");
        // [WHEN] "Source Type" set as 'Customer'
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        // [THEN] "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
    end;

    [Test]
    procedure T012_ValidateParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::"Job Task");
        MockPriceListLine."Parent Source No.".SetValue(JobTask."Job No.");
        // [WHEN] Enter "Source No." as 'JT'
        MockPriceListLine."Source No.".SetValue(JobTask."Job Task No.");
        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceListLine."Source No.".AssertEquals(JobTask."Job Task No.");
        MockPriceListLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    procedure T013_ValidateSourceID()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', where SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        // [WHEN] "Source ID" set as 'X'
        MockPriceListLine."Source ID".SetValue(Customer.SystemId);
        // [THEN] "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine."Source Type".AssertEquals(PriceListLine."Source Type"::Customer);
        MockPriceListLine."Source No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T014_LookupSourceNo()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Customer 'C', SystemID is 'X'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        // [WHEN] Lookup "Source No." set as 'C'
        LibraryVariableStorage.Enqueue(Customer."No."); // for LookupCustomerModalHandler
        MockPriceListLine."Source No.".Lookup();

        // [THEN] "Source No." is 'C', "Source ID" is 'X'
        asserterror
        begin // Fails in AL test but OK in manual test
            MockPriceListLine."Source No.".AssertEquals(Customer."No.");
            MockPriceListLine."Source ID".AssertEquals(Customer.SystemId);
        end;
        Assert.KnownFailure('AssertEquals for Field: Source No.', 352195);
    end;

    [Test]
    [HandlerFunctions('LookupJobModalHandler,LookupJobTaskModalHandler')]
    procedure T015_LookupParentSourceNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Source]
        Initialize();
        // [GIVEN] Job Task 'JT', where Job is 'J'
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] Price Line, where "Source Type" is 'Job Task', "Parent Source No." is 'J'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::"Job Task");
        // [WHEN] Lookup "Source No."
        LibraryVariableStorage.Enqueue(JobTask."Job No."); // for LookupJobModalHandler
        LibraryVariableStorage.Enqueue(JobTask."Job Task No."); // for LookupJobTaskModalHandler
        asserterror // Fails in AL test but OK in manual test
            MockPriceListLine."Source No.".Lookup();
        Assert.KnownFailure('The built-in action = OK is not found', 352195);

        // [THEN] "Source No." is 'JT',"Parent Source No." is 'J'
        MockPriceListLine."Parent Source No.".AssertEquals(JobTask."Job No.");
    end;

    [Test]
    procedure T020_InsertNewLineDoesNotControlConsistency()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        LineNo: Integer;
    begin
        // [SCENARIO] OnInsert() does not control data consistency, but increments "Line No." for the temp record.
        Initialize();
        // [GIVEN] Price list line, where "Source Type" is 'Customer', "Asset Type" is 'Item', but "Source No." and "Asset No." are blank, 
        LineNo := LibraryRandom.RandInt(100);
        TempPriceListLine."Line No." := LineNo;
        TempPriceListLine.Validate("Source Type", TempPriceListLine."Source Type"::Customer);
        TempPriceListLine.Validate("Asset Type", TempPriceListLine."Asset Type"::Item);
        TempPriceListLine.Insert(true);
        TempPriceListLine.TestField("Line No.", LineNo + 1);
    end;

    [Test]
    procedure T100_ValidateItemNoForCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(PriceListLine, Item."Sales Unit of Measure", true, false, Customer."VAT Bus. Posting Group", '');
    end;

    [Test]
    procedure T101_ValidateItemNoForAllCustomers()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLine(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T102_ValidateItemNoForCustomerPriceGroup()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] CustomerPriceGroup 'CPG', where "Allow Invoice Disc." is No, "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Price List Line, where "Allow Invoice Disc." is No, "Source Type" is 'Customer Price Group', "Asset Type" is 'Item', "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Customer Price Group");
        PriceListLine.Validate("Source No.", CustomerPriceGroup.Code);
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CPGVAT'
        VerifyLine(
            PriceListLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            CustomerPriceGroup."Price Includes VAT", CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T103_ValidateItemDiscountGroupForCustomer()
    var
        Customer: Record Customer;
        ItemDiscountGroup: Record "Item Discount Group";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceListLine: Record "Price List Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // [FEATURE] [Customer] [Item Discount Group]
        Initialize();
        // [GIVEN] ItemDiscountGroup 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is "Item Discount Group", 
        // [GIVEN] "Variant Code" is 'V', "Unit of Measure Code" is 'UoM'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Item Discount Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ItemDiscountGroup.Code);

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(PriceListLine, '', false, false, Customer."VAT Bus. Posting Group", '');
    end;

    [Test]
    procedure T104_ValidateItemNoForVendor()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Vendor] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Purch. Unit of Measure" - 'PUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Vendor', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
        PriceListLine.Validate("Source No.", LibraryPurchase.CreateVendorNo());
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLine(PriceListLine, Item."Purch. Unit of Measure", false, false, '', '');
    end;

    [Test]
    procedure T105_ValidateItemNoForJobSale()
    var
        Item: Record Item;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type" is 'Sale', "Source Type" is 'Job', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLine(
            PriceListLine, Item."Sales Unit of Measure", Item."Allow Invoice Disc.",
            Item."Price Includes VAT", item."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T106_ValidateItemNoForJobPurchase()
    var
        Item: Record Item;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Purch. Unit of Measure" - 'PUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type" is 'Purchase', "Source Type" is 'Job', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'PUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLine(PriceListLine, Item."Purch. Unit of Measure", false, false, '', '');
    end;

    [Test]
    procedure T107_ValidateGlAccNoForJob()
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job] [G/L Account]
        Initialize();
        // [GIVEN] G/L Account 'X', where "VAT Bus. Posting Group" is 'VATBPG'
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"G/L Account");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", GLAccount."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>
        VerifyLine(PriceListLine, '', false, false, '', '');
    end;

    [Test]
    procedure T108_ValidateResourceForJob()
    var
        Resource: Record Resource;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource]
        Initialize();
        // [GIVEN] Resource 'X'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is 'WT'
        VerifyLine(PriceListLine, '', false, false, '', WorkType.Code);
    end;

    [Test]
    procedure T109_ValidateResourceGroupForJob()
    var
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Job] [Resource Group]
        Initialize();
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price List Line, where "Price Type" is 'Any, "Source Type" is 'Job', "Asset Type" is 'Resource Group', 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
        LibraryJob.CreateJob(Job);
        PriceListLine.Validate("Source No.", Job."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLine(PriceListLine, '', false, false, '', '');
    end;

    [Test]
    procedure T110_ValidateResourceForCustomer()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Customer] [Resource]
        Initialize();
        // [GIVEN] Resource 'X'
        Resource.Get(LibraryResource.CreateResourceNo());
        // [GIVEN] Customer 'C', where "VAT Bus. Posting Group" is 'CVAT'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Resource, 
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", Customer."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", Resource."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT', "Work Type Code" is 'WT'
        VerifyLine(PriceListLine, '', false, false, Customer."VAT Bus. Posting Group", WorkType.Code);
    end;

    [Test]
    procedure T111_ValidateResourceGroupForVendor()
    var
        ResourceGroup: Record "Resource Group";
        Job: Record Job;
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Vendor] [Resource Group]
        Initialize();
        // [GIVEN] Resource Group 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [GIVEN] Price List Line, where "Source Type" is 'Vendor', "Asset Type" is 'Resource Group',
        // [GIVEN] "Variant Code" is 'V', "Work Type Code" is 'WT'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
        PriceListLine.Validate("Source No.", LibraryPurchase.CreateVendorNo());
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        LibraryResource.CreateWorkType(WorkType);
        PriceListLine."Work Type Code" := WorkType.Code;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");

        // [WHEN] Set "Asset No." as 'X'
        PriceListLine.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is <blank>, "Variant Code" is <blank>, "Allow Invoice Disc." is No, 
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is <blank>, "Work Type Code" is <blank>
        VerifyLine(PriceListLine, '', false, false, '', '');
    end;

    [Test]
    procedure T112_ValidateSourceTypeForItem()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLine(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T113_ValidateAllCustomersSourceNoForItem()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [All Customers]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'All Customers'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");

        // [WHEN] Set "Source No." as 'X'
        PriceListLine.Validate("Source No.", LibraryUtility.GenerateGUID());

        // [THEN] "Source No." is <blank>
        PriceListLine.TestField("Source No.", '');
    end;

    [Test]
    procedure T114_ValidateCustomerNoForItem()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer] [Item]
        Initialize();
        // [GIVEN] Customer 'C', where "Currency Code" is 'USD', "VAT Bus. POsting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        CreateCustomer(Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source No.", Customer."No.");

        // [THEN] Price List Line, where "Allow Line Disc." is Yes, "Currency Code" is 'USD',
        // [THEN] "Price Includes VAT" is No, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceListLine, Customer."Allow Line Disc.", Customer."Prices Including VAT",
            Customer."VAT Bus. Posting Group", Customer."Currency Code");
    end;

    [Test]
    procedure T115_ValidateCustomerPriceGroupForItem()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Currency: Record Currency;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Customer Price Group] [Item]
        Initialize();
        // [GIVEN] Customer Price Group 'CPG', where "VAT Bus. Posting Gr. (Price)" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is Yes, "Allow Line Disc." is No, "Allow Invoice Disc." is No
        CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Source Type" is 'Customer Price GroupCustomer Price Group', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Customer Price Group");
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source Type " as 'Customer'
        PriceListLine.Validate("Source No.", CustomerPriceGroup.Code);

        // [THEN] Price List Line, where "Allow Line Disc." is No, "Allow Invoice Disc." is No,
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'CVAT'
        VerifyLine(
            PriceListLine, CustomerPriceGroup."Allow Line Disc.", CustomerPriceGroup."Price Includes VAT",
            CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", CustomerPriceGroup."Allow Invoice Disc.");
    end;

    [Test]
    procedure T116_ValidateCampaignNoForItem()
    var
        Campaign: Record Campaign;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Campaign 'C', where "Starttin Date" is '010120', "Ending Date" is '310120'
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", WorkDate());
        Campaign.Validate("Ending Date", WorkDate() + 10);
        Campaign.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" and "Ending Date" are <blank>
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Campaign);

        // [WHEN] Set "Source No." as 'C'
        PriceListLine.Validate("Source No.", Campaign."No.");

        // [THEN] Price List Line, where "Starting Date" is '010120', "Ending Date" is '310120'
        VerifyLine(PriceListLine, Campaign."Starting Date", Campaign."Ending Date");
    end;

    [Test]
    procedure T117_ValidateContactNoForItem()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "Currency Code" is 'USD', "VAT Bus. POsting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Contact);
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Asset No.", Item."No.");

        // [WHEN] Set "Source No." as 'CONT'
        PriceListLine.Validate("Source No.", Contact."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLine(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T118_ValidateItemForContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Contact] [Item]
        Initialize();
        // [GIVEN] Customer 'C' with Contact 'CONT', where "Currency Code" is 'USD', "VAT Bus. POsting Group" is 'CVAT', 
        // [GIVEN] "Prices Including VAT" is No, "Allow Line Disc." is Yes
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        // [GIVEN] Item 'X', where "Sales Unit of Measure" - 'SUoM', "Allow Invoice Disc." is Yes, 
        // [GIVEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        CreateItem(Item);
        // [GIVEN] Price List Line, where "Price Type"::Sale, "Source Type" is 'Contact', "Asset Type" is Item, "Variant Code" is 'V'
        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Contact);
        PriceListLine.Validate("Source No.", Contact."No.");
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine."Variant Code" := LibraryUtility.GenerateGUID();
        PriceListLine."Unit of Measure Code" := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Source No." as 'X'
        PriceListLine.Validate("Asset No.", Item."No.");

        // [THEN] Price List Line, where "Unit of Measure Code" is 'SUoM', "Variant Code" is <blank>, "Allow Invoice Disc." is Yes, 
        // [THEN] "Price Includes VAT" is Yes, "VAT Bus. Posting Gr. (Price)" is 'VATBPG'
        VerifyLine(PriceListLine, Item."Sales Unit of Measure", true, true, Item."VAT Bus. Posting Gr. (Price)", '');
    end;

    [Test]
    procedure T140_ValidateStartingDateAfterEndingDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Line, where  "Ending Date" is '310120'
        PriceListLine.Init();
        PriceListLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010220'
        asserterror PriceListLine.Validate("Starting Date", PriceListLine."Ending Date" + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    procedure T141_ValidateEndingDateBeforeStartingDate()
    var
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Line, where "Starting Date" is '010220'
        PriceListLine.Init();
        PriceListLine."Starting Date" := WorkDate();
        // [WHEN] Set "Ending Date" as '310120'
        asserterror PriceListLine.Validate("Ending Date", PriceListLine."Starting Date" - 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    procedure T142_ValidateStartingDateForCampaign()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Campaign]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Ending Date" is '310120'
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::Campaign;
        PriceListLine."Ending Date" := WorkDate();
        // [WHEN] Set "Starting Date" as '010120'
        asserterror PriceListLine.Validate("Starting Date", WorkDate() + 1);

        // [THEN] Error message: 'Starting Date cannot be after Ending Date'
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    procedure T143_ValidateEndingDateForCampaignViaUI()
    var
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Campaign] [UI]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Campaign', "Starting Date" is '010220'
        PriceListLine.DeleteAll();
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::Campaign;
        PriceListLine."Starting Date" := WorkDate();
        PriceListLine.Insert();
        // [GIVEN] Open page 
        MockPriceListLine.Trap();
        Page.Run(Page::"Mock Price List Line", PriceListLine, PriceListLine."Starting Date");
        // [WHEN] Set "Ending Date" as '310120'
        asserterror MockPriceListLine."Ending Date".SetValue(PriceListLine."Starting Date" - 1);

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
    end;

    [Test]
    procedure T150_ValidateUnitOfMeasureForNonItem()
    var
        PriceListLine: Record "Price List Line";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Unit of Measure]
        Initialize();
        // [GIVEN] Price List Line, where "Asset Type" is 'G/L Account'
        PriceListLine.Init();
        PriceListLine."Asset Type" := PriceListLine."Asset Type"::"G/L Account";
        // [WHEN] Set "Unit Of Meadure" as 'BOX'
        UnitofMeasure.FindFirst();
        asserterror PriceListLine.Validate("Unit of Measure Code", UnitofMeasure.Code);

        // [THEN] Error message: 'Asset Type must be Item or Resource.'
        Assert.ExpectedError(AssetTypeForUOMErr);
    end;

    [Test]
    procedure T151_ValidateVariantCodeForNonItem()
    var
        PriceListLine: Record "Price List Line";
        ItemVariant: Record "Item Variant";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Item Variant 'X' for Item 'I'
        ItemVariant.FindFirst();
        // [GIVEN] Price List Line, where "Asset Type" is 'Item Discount Group', "Asset Type" is 'I'
        PriceListLine.Init();
        PriceListLine."Asset Type" := PriceListLine."Asset Type"::"Item Discount Group";
        PriceListLine."Asset No." := ItemVariant."Item No.";
        // [WHEN] Set "Variant Code" as 'X'
        asserterror PriceListLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] Error message: 'Asset Type must be Item.'
        Assert.ExpectedError(AssetTypeMustBeItemErr);
    end;

    [Test]
    procedure T160_ValidateUnitPriceForJob()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Job', "Cost Factor" is 2
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::Job;
        PriceListLine."Cost Factor" := 2;
        // [WHEN] Set "Unit Price" as 1
        PriceListLine.Validate("Unit Price", 1);
        // [THEN] "Cost Factor" is 0
        PriceListLine.TestField("Cost Factor", 0);
    end;

    [Test]
    procedure T161_ValidateCostFactorForJob()
    var
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Price List Line, where "Source Type" is 'Job', "Unit Price" is 2
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::Job;
        PriceListLine."Unit Price" := 2;
        // [WHEN] Set "Cost Factor" as 1
        PriceListLine.Validate("Cost Factor", 1);
        // [THEN] "Unit Price" is 0
        PriceListLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T162_ValidateNonPostingJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'JT', where "Job Task Type" is 'Heading' (not Posting)
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
        JobTask.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job Task'
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::"Job Task";
        PriceListLine."Parent Source No." := Job."No.";
        // [WHEN] Set "Source No." as 'JT'
        asserterror PriceListLine.Validate("Source No.", JobTask."Job Task No.");
        // [THEN] Error message: 'Job Task Type must be equal to Posting'
        Assert.ExpectedError(NotPostingJobTaskTypeErr);
    end;

    [Test]
    procedure T163_ValidateJobNoAsSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job'
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::"Job";
        // [WHEN] Set "Source No." as 'JT'
        PriceListLine.Validate("Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceListLine.TestField("Currency Code", Job."Currency Code");
    end;

    [Test]
    procedure T164_ValidateJobNoAsParentSource()
    var
        Currency: Record Currency;
        Job: Record Job;
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Job Task 'J', where "Currency Code" is 'USD'
        LibraryJob.CreateJob(Job);
        LibraryERM.CreateCurrency(Currency);
        Job."Currency Code" := Currency.Code;
        Job.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'Job Task'
        PriceListLine.Init();
        PriceListLine."Source Type" := PriceListLine."Source Type"::"Job Task";
        // [WHEN] Set "Parent Source No." as 'J'
        PriceListLine.Validate("Parent Source No.", Job."No.");
        // [THEN] Line, where "Currency Code" is 'USD'
        PriceListLine.TestField("Currency Code", Job."Currency Code");
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price List Line UT");
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price List Line UT");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price List Line UT");
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryInventory.CreateItem(Item);
        Item."Allow Invoice Disc." := true;
        Item."Price Includes VAT" := true;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Item."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 10);
        Item."Sales Unit of Measure" := ItemUnitofMeasure.Code;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitofMeasure, Item."No.", 10);
        Item."Purch. Unit of Measure" := ItemUnitofMeasure.Code;
        Item.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        Currency: Record Currency;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCurrency(Currency);
        Customer."Currency Code" := Currency.Code;
        Customer."Allow Line Disc." := true;
        Customer."Prices Including VAT" := false;
        Customer.Modify();
    end;

    local procedure CreateCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup."Allow Invoice Disc." := false;
        CustomerPriceGroup."Allow Line Disc." := false;
        CustomerPriceGroup."Price Includes VAT" := true;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CustomerPriceGroup."VAT Bus. Posting Gr. (Price)" := VATBusinessPostingGroup.Code;
        CustomerPriceGroup.Modify(true);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; UoM: Code[10]; AllowInvoiceDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; WorkTypeCode: Code[10])
    begin
        PriceListLine.TestField("Unit of Measure Code", UoM);
        PriceListLine.TestField("Variant Code", '');
        PriceListLine.TestField("Allow Invoice Disc.", AllowInvoiceDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
        PriceListLine.TestField("Work Type Code", WorkTypeCode);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; CurrencyCode: Code[10])
    begin
        PriceListLine.TestField("Currency Code", CurrencyCode);
        PriceListLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; AllowLineDisc: Boolean; PriceIncludesVAT: Boolean; VATBusPostingGr: Code[20]; AlloInvDisc: Boolean)
    begin
        PriceListLine.TestField("Allow Invoice Disc.", AlloInvDisc);
        PriceListLine.TestField("Allow Line Disc.", AllowLineDisc);
        PriceListLine.TestField("Price Includes VAT", PriceIncludesVAT);
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostingGr);
    end;

    local procedure VerifyLine(PriceListLine: Record "Price List Line"; StartingDate: Date; EndingDate: Date)
    begin
        PriceListLine.TestField("Starting Date", StartingDate);
        PriceListLine.TestField("Ending Date", EndingDate);
    end;


    [ModalPageHandler]
    procedure ItemUOMModalHandler(var ItemUnitsofMeasure: testpage "Item Units of Measure")
    begin
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure.Code.Value);
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure."Qty. per Unit of Measure".Value);
        LibraryVariableStorage.Enqueue(ItemUnitsofMeasure.Next());
        ItemUnitsofMeasure.First();
        ItemUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemVariantsHandler(var ItemVariants: testpage "Item Variants")
    begin
        LibraryVariableStorage.Enqueue(ItemVariants.Code.Value);
        LibraryVariableStorage.Enqueue(ItemVariants.Next());
        ItemVariants.First();
        ItemVariants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ResourceUOMModalHandler(var ResourceUnitsofMeasure: testpage "Resource Units of Measure")
    begin
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure.Code.Value);
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure."Qty. per Unit of Measure".Value);
        LibraryVariableStorage.Enqueue(ResourceUnitsofMeasure.Next());
        ResourceUnitsofMeasure.First();
        ResourceUnitsofMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupCustomerModalHandler(var CustomerList: testpage "Customer List")
    begin
        CustomerList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupJobModalHandler(var JobList: testpage "Job List")
    begin
        JobList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        JobList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupJobTaskModalHandler(var JobTaskList: testpage "Job Task List")
    begin
        JobTaskList.Filter.SetFilter("Job Task No.", LibraryVariableStorage.DequeueText());
        JobTaskList.OK().Invoke();
    end;
}
