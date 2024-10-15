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
        LibraryService: Codeunit "Library - Service";
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
        WrongPriceListCodeErr: Label 'The field Price List Code of table Price List Line contains a value (%1) that cannot be found';
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
    procedure T005_ValidateNonexistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();

        PriceListHeader.DeleteAll();
        PriceListCode := LibraryUtility.GenerateGUID();
        asserterror PriceListLine.Validate("Price List Code", PriceListCode);

        Assert.ExpectedError(StrSubstNo(WrongPriceListCodeErr, PriceListCode));
    end;

    [Test]
    procedure T006_ValidateExistingPriceListCode()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Source Type"::Customer, LibrarySales.CreateCustomerNo());
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);

        PriceListLine.Testfield("Price List Code", PriceListHeader.Code);
    end;

    [Test]
    procedure T007_InsertLineForPriceListWithSourceTypeAll()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CustomerNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Price List Header 'X', where "Source Type" is 'All', "Source No." is <blank>, "Price Type" is 'Any', "Amount Type" is 'Any'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Source Type"::All, '');
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Any;
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Any;
        // [GIVEN] all other header's fields are filled with data
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader."Price Includes VAT" := true;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := LibraryUtility.GenerateGUID();
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X', "Source Type" is 'Customer', "Source No." is 'C', 
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        CustomerNo := LibrarySales.CreateCustomerNo();
        PriceListLine.Validate("Source No.", CustomerNo);
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceListLine.Validate("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);
        // [WHEN] Insert the line
        PriceListLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceListLine.TestField("Line No.");
        PriceListLine.TestField("Starting Date", 0D);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [THEN] Line where,  "Source Type" is 'Customer', "Source No." is 'C'
        PriceListLine.TestField("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.TestField("Source No.", CustomerNo);
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", PriceListLine."Amount Type"::Price);
        // [THEN] Other fields are copied from the header
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceListLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceListLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure T008_InsertLineForPriceListWithSourceTypeNotAll()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SourceNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Price List Header 'X', where "Source Type" is 'Vendor', "Source No." is 'V', "Price Type" is 'Any', "Amount Type" is 'Any'
        SourceNo := LibraryPurchase.CreateVendorNo();
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Source Type"::Vendor, SourceNo);
        PriceListHeader."Amount Type" := PriceListHeader."Amount Type"::Cost;
        PriceListHeader."Price Type" := PriceListHeader."Price Type"::Purchase;
        // [GIVEN] all other header's fields are filled with data
        PriceListHeader."Starting Date" := WorkDate();
        PriceListHeader."Ending Date" := WorkDate() + 10;
        PriceListHeader."Allow Invoice Disc." := true;
        PriceListHeader."Allow Line Disc." := true;
        PriceListHeader."Price Includes VAT" := true;
        PriceListHeader."VAT Bus. Posting Gr. (Price)" := LibraryUtility.GenerateGUID();
        PriceListHeader.Modify();
        // [GIVEN] Fill the Line, where "Price List Code" is 'X', "Source Type" is 'Customer', "Source No." is 'C', 
        PriceListLine.Init();
        PriceListLine.Validate("Price List Code", PriceListHeader.Code);
        PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Customer);
        PriceListLine.Validate("Source No.", LibrarySales.CreateCustomerNo());
        // [GIVEN] "Amount Type" is 'Price', "Price Type" is 'Sale'
        PriceListLine.Validate("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Price);

        // [WHEN] Insert the line
        PriceListLine.Insert(true);
        // [THEN] Header's fields are not copied, "Line No." is not 0,
        PriceListLine.TestField("Line No.");
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);

        // [WHEN] Validate "Asset Type"
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [THEN] Line inserted, all fields are copied for the header
        PriceListLine.TestField("Source Type", PriceListHeader."Source Type");
        PriceListLine.TestField("Source No.", PriceListHeader."Source No.");
        PriceListLine.TestField("Price Type", PriceListHeader."Price Type");
        PriceListLine.TestField("Amount Type", PriceListHeader."Amount Type");
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        PriceListLine.TestField("Allow Invoice Disc.", PriceListHeader."Allow Invoice Disc.");
        PriceListLine.TestField("Allow Line Disc.", PriceListHeader."Allow Line Disc.");
        PriceListLine.TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
        PriceListLine.TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
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
        // [SCENARIO] Revalidated unchanged "Source Type" does blank the source
        Initialize();
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price Line, where "Source Type" is 'Customer', "Source No." is 'C'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        MockPriceListLine."Source No.".SetValue(Customer."No.");
        // [WHEN] "Source Type" set as 'Customer'
        MockPriceListLine."Source Type".SetValue(PriceListLine."Source Type"::Customer);
        // [THEN] "Source Type" is 'Customer', "Source No." is <blank>
        MockPriceListLine."Source No.".AssertEquals('');
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
    [HandlerFunctions('LookupItemModalHandler')]
    procedure T016_LookupAssetNo()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        MockPriceListLine: TestPage "Mock Price List Line";
    begin
        // [FEATURE] [Asset]
        Initialize();
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price Line, where "Asset Type" is 'Item'
        MockPriceListLine.OpenEdit();
        MockPriceListLine."Asset Type".SetValue(PriceListLine."Asset Type"::Item);
        // [WHEN] Lookup "Asset No." set as 'I'
        LibraryVariableStorage.Enqueue(Item."No."); // for LookupItemModalHandler
        MockPriceListLine."Asset No.".Lookup();

        // [THEN] "Asset No." is 'I'
        asserterror // Fails in AL test but OK in manual test
            MockPriceListLine."Asset No.".AssertEquals(Item."No.");
        Assert.KnownFailure('AssertEquals for Field: Asset No.', 352195);
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
        // [WHEN] Insert temporary line 
        TempPriceListLine.Insert(true);
        // [THEN] "Line No." is not changed
        TempPriceListLine.TestField("Line No.", LineNo);
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
    procedure T119_ValidateWorkTypeForAllResources()
    var
        PriceListLine: Record "Price List Line";
        WorkType: Record "Work Type";
        UnitofMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Resource] [Work Type]
        // [SCENARIO 406833] "Work Type Code" can be set for 'all resources' price line ("Asset No." is blank)
        Initialize();
        // [GIVEN] Work Type 'WT', where "Unit of Measure Code" is 'UOM'
        LibraryResource.CreateWorkType(WorkType);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        WorkType."Unit of Measure Code" := UnitofMeasure.Code;
        WorkType.Modify();
        // [GIVEN] Price List Line, where "Source Type" is 'All Vendors', "Asset Type" is 'Resource', "Asset No." is <blank>
        PriceListLine.Validate("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.Validate("Asset Type", "Price Asset Type"::Resource);

        // [WHEN] Set "Work Type Code" as 'WT'
        PriceListLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] Price Line, where "Unit of Measure Code" is 'UOM'
        PriceListLine.TestField("Work Type Code", WorkType.Code);
        PriceListLine.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T120_DeletePricesOnResourceDeletion()
    var
        PriceListLine: Record "Price List Line";
        Resource: Array[2] of Record Resource;
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        CreateAssetPriceLines(AssetType::Resource, Resource[1]."No.", Resource[2]."No.");

        // [WHEN] Delete Resource 'A'
        Resource[1].Delete(true);

        // [THEN] Price list lines for Resource 'A' are deleted, for Resource 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::Resource, Resource[1]."No.", Resource[2]."No.");
    end;

    [Test]
    procedure T121_DeletePricesOnResourceGroupDeletion()
    var
        PriceListLine: Record "Price List Line";
        ResourceGroup: Array[2] of Record "Resource Group";
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] Two Resource Groups 'A' and 'B' have related price lines
        LibraryResource.CreateResourceGroup(ResourceGroup[1]);
        LibraryResource.CreateResourceGroup(ResourceGroup[2]);
        CreateAssetPriceLines(AssetType::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");

        // [WHEN] Delete ResourceGroup 'A'
        ResourceGroup[1].Delete(true);

        // [THEN] Price list lines for ResourceGroup 'A' are deleted, for ResourceGroup 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");
    end;

    [Test]
    procedure T122_DeletePricesOnItemDeletion()
    var
        PriceListLine: Record "Price List Line";
        Item: Array[2] of Record Item;
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Two Item 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        CreateAssetPriceLines(AssetType::Item, Item[1]."No.", Item[2]."No.");

        // [WHEN] Delete Item 'A'
        Item[1].Delete(true);

        // [THEN] Price list lines for Item 'A' are deleted, for Item 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::Item, Item[1]."No.", Item[2]."No.");
    end;

    [Test]
    procedure T123_DeletePricesOnItemDiscountGroupDeletion()
    var
        PriceListLine: Record "Price List Line";
        ItemDiscountGroup: Array[2] of Record "Item Discount Group";
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Two "Item Discount Group" 'A' and 'B' have related price lines
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[1]);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[2]);
        CreateAssetPriceLines(AssetType::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);

        // [WHEN] Delete "Item Discount Group" 'A'
        ItemDiscountGroup[1].Delete(true);

        // [THEN] Price list lines for "Item Discount Group" 'A' are deleted, for "Item Discount Group" 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);
    end;

    [Test]
    procedure T124_DeletePricesOnGLAccountDeletion()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PriceListLine: Record "Price List Line";
        GLAccount: Array[2] of Record "G/L Account";
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] GeneralLedgerSetup, where "Allow G/L Acc. Deletion Before" is set
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow G/L Acc. Deletion Before" := WorkDate();
        GeneralLedgerSetup.Modify();
        // [GIVEN] Two G/L Account 'A' and 'B' have related price lines
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateAssetPriceLines(AssetType::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");

        // [WHEN] Delete G/L Account 'A'
        GLAccount[1].Delete(true);

        // [THEN] Price list lines for G/L Account 'A' are deleted, for G/L Account 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");
    end;

    [Test]
    procedure T125_DeletePricesOnServiceCostDeletion()
    var
        PriceListLine: Record "Price List Line";
        ServiceCost: Array[2] of Record "Service Cost";
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] Two "Service Cost" 'A' and 'B' have related price lines
        LibraryService.CreateServiceCost(ServiceCost[1]);
        LibraryService.CreateServiceCost(ServiceCost[2]);
        CreateAssetPriceLines(AssetType::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);

        // [WHEN] Delete Service Cost 'A'
        ServiceCost[1].Delete(true);

        // [THEN] Price list lines for Service Cost 'A' are deleted, for Service Cost 'B' are not deleted
        VerifyDeletedAssetPrices(AssetType::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);
    end;

    [Test]
    procedure T126_DeletePricesOnItemVariantDeletion()
    var
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        ItemVariant: Array[2] of Record "Item Variant";
        AssetType: Enum "Price Asset Type";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Two Item Variants 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        CreateAssetPriceLines(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);

        // [WHEN] Delete Item Variant 'A'
        ItemVariant[1].Delete(true);

        // [THEN] Price list lines for Item Variant 'A' are deleted, for Item Variant 'B' are not deleted
        VerifyDeletedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);
    end;

    [Test]
    procedure T130_ModifyPricesOnResourceRename()
    var
        PriceListLine: Record "Price List Line";
        Resource: Array[2] of Record Resource;
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        CreateAssetPriceLines(AssetType::Resource, Resource[1]."No.", Resource[2]."No.");

        // [WHEN] Rename Resource 'A' to 'X'
        OldNo := Resource[1]."No.";
        Resource[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for Resource 'A' are modified to 'X', for Resource 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::Resource, Resource[1]."No.", Resource[2]."No.", OldNo);
    end;

    [Test]
    procedure T131_ModifyPricesOnResourceGroupRename()
    var
        PriceListLine: Record "Price List Line";
        ResourceGroup: Array[2] of Record "Resource Group";
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] Two Resource 'A' and 'B' have related price lines
        LibraryResource.CreateResourceGroup(ResourceGroup[1]);
        LibraryResource.CreateResourceGroup(ResourceGroup[2]);
        CreateAssetPriceLines(AssetType::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.");

        // [WHEN] Rename ResourceGroup 'A' to 'X'
        OldNo := ResourceGroup[1]."No.";
        ResourceGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for ResourceGroup 'A' are modified to 'X', for ResourceGroup 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::"Resource Group", ResourceGroup[1]."No.", ResourceGroup[2]."No.", OldNo);
    end;

    [Test]
    procedure T132_ModifyPricesOnItemRename()
    var
        PriceListLine: Record "Price List Line";
        Item: Array[2] of Record Item;
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Two Item 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        CreateAssetPriceLines(AssetType::Item, Item[1]."No.", Item[2]."No.");

        // [WHEN] Rename Item 'A' to 'X'
        OldNo := Item[1]."No.";
        Item[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for Item 'A' are modified to 'X', for Item 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::Item, Item[1]."No.", Item[2]."No.", OldNo);
    end;

    [Test]
    procedure T133_ModifyPricesOnItemDiscountGroupRename()
    var
        PriceListLine: Record "Price List Line";
        ItemDiscountGroup: Array[2] of Record "Item Discount Group";
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Two Item Discount Groups 'A' and 'B' have related price lines
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[1]);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup[2]);
        CreateAssetPriceLines(AssetType::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code);

        // [WHEN] Rename ItemDiscountGroup 'A' to 'X'
        OldNo := ItemDiscountGroup[1].Code;
        ItemDiscountGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for "Item Discount Group" 'A' are modified to 'X', for "Item Discount Group" 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::"Item Discount Group", ItemDiscountGroup[1].Code, ItemDiscountGroup[2].Code, OldNo);
    end;

    [Test]
    procedure T134_ModifyPricesOnGLAccountRename()
    var
        PriceListLine: Record "Price List Line";
        GLAccount: Array[2] of Record "G/L Account";
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] Two GLAccount 'A' and 'B' have related price lines
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateAssetPriceLines(AssetType::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.");

        // [WHEN] Rename GLAccount 'A' to 'X'
        OldNo := GLAccount[1]."No.";
        GLAccount[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for GLAccount 'A' are modified to 'X', for GLAccount 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::"G/L Account", GLAccount[1]."No.", GLAccount[2]."No.", OldNo);
    end;

    [Test]
    procedure T135_ModifyPricesOnServiceCostRename()
    var
        PriceListLine: Record "Price List Line";
        ServiceCost: Array[2] of Record "Service Cost";
        AssetType: Enum "Price Asset Type";
        OldNo: Code[20];
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] Two "Service Cost" 'A' and 'B' have related price lines
        LibraryService.CreateServiceCost(ServiceCost[1]);
        LibraryService.CreateServiceCost(ServiceCost[1]);
        CreateAssetPriceLines(AssetType::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code);

        // [WHEN] Rename "Service Cost" 'A' to 'X'
        OldNo := ServiceCost[1].Code;
        ServiceCost[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for "Service Cost" 'A' are modified to 'X', for "Service Cost" 'B' are not deleted
        VerifyRenamedAssetPrices(AssetType::"Service Cost", ServiceCost[1].Code, ServiceCost[2].Code, OldNo);
    end;

    [Test]
    procedure T136_ModifyPricesOnItemVariantRename()
    var
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        ItemVariant: Array[2] of Record "Item Variant";
        AssetType: Enum "Price Asset Type";
        OldNo: Code[10];
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Two Item Variants 'A' and 'B' have related price lines
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        CreateAssetPriceLines(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code);

        // [WHEN] Rename Item Variant 'A' to 'X'
        OldNo := ItemVariant[1].Code;
        ItemVariant[1].Rename(Item."No.", LibraryUtility.GenerateGUID());

        // [THEN] Price list lines for Item Variant 'A' are modified to 'X', for Item Variant 'B' are not deleted
        VerifyRenamedAssetPrices(Item."No.", ItemVariant[1].Code, ItemVariant[2].Code, OldNo);
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

        // [THEN] Error message: '... you can only change Starting Date and Ending Date from the Campaign Card.'
        Assert.ExpectedError(CampaignDateErr);
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

    local procedure CreateAssetPriceLines(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreatePriceLine(PriceListLine, '', AssetType, AssetNo1);
        LibraryPriceCalculation.CreatePriceLine(PriceListLine, '', AssetType, AssetNo2);
    end;

    local procedure CreateAssetPriceLines(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceListLine: Record "Price List Line";
        AssetType: Enum "Price Asset Type";
    begin
        PriceListLine.DeleteAll();
        LibraryPriceCalculation.CreatePriceLine(PriceListLine, '', AssetType::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode1);
        PriceListLine.Modify();
        LibraryPriceCalculation.CreatePriceLine(PriceListLine, '', AssetType::Item, ItemNo);
        PriceListLine.Validate("Variant Code", VariantCode2);
        PriceListLine.Modify();
    end;

    local procedure VerifyDeletedAssetPrices(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyDeletedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10])
    var
        PriceListLine: Record "Price List Line";
        AssetType: Enum "Price Asset Type";
    begin
        PriceListLine.SetRange("Asset Type", AssetType::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", VariantCode2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", VariantCode1);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyRenamedAssetPrices(AssetType: Enum "Price Asset Type"; AssetNo1: Code[20]; AssetNo2: Code[20]; OldAssetNo: Code[20])
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", AssetNo1);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", AssetNo2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Asset No.", OldAssetNo);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    local procedure VerifyRenamedAssetPrices(ItemNo: Code[20]; VariantCode1: Code[10]; VariantCode2: Code[10]; OldVariantCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
        AssetType: Enum "Price Asset Type";
    begin
        PriceListLine.SetRange("Asset Type", AssetType::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", VariantCode1);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", VariantCode2);
        Assert.RecordCount(PriceListLine, 1);
        PriceListLine.SetRange("Variant Code", OldVariantCode);
        Assert.RecordIsEmpty(PriceListLine);
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
    procedure LookupItemModalHandler(var ItemList: testpage "Item List")
    begin
        ItemList.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.OK().Invoke();
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
