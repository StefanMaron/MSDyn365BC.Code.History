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
        DateConfirmQst: Label 'Do you want to update %1 in the price list lines?', Comment = '%1 - the field caption';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1 - Field caption';
        StatusUpdateQst: Label 'Do you want to update status to %1?', Comment = '%1 - status value: Draft, Active, or Inactive';
        CannotDeleteActivePriceListErr: Label 'You cannot delete the active price list %1.', Comment = '%1 - the price list code.';
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
    procedure T005_CodeByAllNoSeriesOnInsert()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceListHeader."Source Group" := PriceListHeader."Source Group"::All;
        asserterror PriceListHeader.Insert(true);
        Assert.ExpectedError(CodeMustNotBeBlankErr);
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
    procedure T011_SourceTypeCannotBeChangedIfLinesExist()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where "Source Type" = 'Customer'
        CreatePriceList(PriceListHeader, PriceListLine);
        // [WHEN] Change "Source Type" to 'All Customers' 
        asserterror PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"All Customers");
        // [THEN] Error message: 'You cannot update Source Type because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Source Type")));
    end;

    [Test]
    procedure T012_SourceNoCannotBeChangedIfLinesExist()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List Header, where "Source Type" = 'All Customers'
        CreatePriceList(PriceListHeader, PriceListLine);
        // [WHEN] Change "Source Type" to 'Customer' 
        asserterror PriceListHeader.Validate("Source No.", LibrarySales.CreateCustomerNo());
        // [THEN] Error message: 'You cannot update Source No. because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Source No.")));
    end;

    [Test]
    procedure T015_JobTask_ChangedSourceNoValidation()
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
    procedure T016_JobTask_IsSourceNoAllowed()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [FEATURE] [Job Task]
        Initialize();
        PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"Job Task");
        Assert.IsTrue(PriceListHeader.IsSourceNoAllowed(), 'IsSourceNoAllowed');
    end;

    [Test]
    [HandlerFunctions('LookupCustomerModalHandler')]
    procedure T019_LookupSourceNoCustomer()
    var
        PriceListHeader: Record "Price List Header";
        MockPriceListHeader: TestPage "Mock Price List Header";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        Initialize();
        // [GIVEN] Header, where "Source Type" is 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"All Customers", '');
        Commit();
        // [GIVEN] Open Price List Header page and set "Source Type" as 'Customer'
        MockPriceListHeader.Trap();
        PriceListHeader.SetRecFilter();
        Page.Run(Page::"Mock Price List Header", PriceListHeader);
        MockPriceListHeader."Source Type".SetValue(PriceListHeader."Source Type"::Customer);

        // [WHEN] Lookup "Source No." to pick Customer 'X'
        SourceNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(SourceNo); // CustomerNo to LookupCustomerModalHandler
        MockPriceListHeader."Source No.".Lookup();
        MockPriceListHeader.Close();

        // [THEN] Header, where "Source Type" is Customer, "Source No." is 'X'
        PriceListHeader.Find();
        PriceListHeader.TestField("Source No.", SourceNo);
    end;

    [Test]
    procedure T020_ValidateStartingDateAfterEndingDate()
    var
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        // [GIVEN] Price List Header, where  "Ending Date" is '310120'
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
        // [GIVEN] Price List Header, where "Starting Date" is '010220'
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
        // [GIVEN] Price List Header, where "Source Type" is 'Campaign', "Ending Date" is '310120'
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
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T024_ChangeStartingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Starting Date" is '010220'
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Set "Starting Date" as '310120', answer 'Yes' to confirm
        PriceListHeader.Validate("Starting Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Confirmation question: 'Do you want to update Starting Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Starting Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price List Line, where "Starting Date" is '310120'
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", PriceListHeader."Starting Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T025_ChangeEndingDateWithLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Ending Date" is '300120'
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Set "Ending Date" as '310120', answer 'Yes' to confirm
        PriceListHeader.Validate("Ending Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Confirmation question: 'Do you want to update Ending Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Ending Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price List Line, where "Ending Date" is '310120'
        PriceListLine.Find();
        PriceListLine.TestField("Ending Date", PriceListHeader."Ending Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T026_ChangeStartingDateWithLinesConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ExpectedDate: Date;
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Starting Date" is '010220'
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Set "Starting Date" as '310120', answer 'No' to confirm
        ExpectedDate := PriceListHeader."Starting Date";
        PriceListHeader.Validate("Starting Date", PriceListHeader."Starting Date" - 1);

        // [THEN] Confirmation question: 'Do you want to update Starting Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Starting Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price List Line, where "Starting Date" is '010220'
        PriceListLine.Find();
        PriceListLine.TestField("Starting Date", ExpectedDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T027_ChangeEndingDateWithLinesConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ExpectedDate: Date;
    begin
        Initialize();
        // [GIVEN] Price List with one line, where "Ending Date" is '300120'
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Set "Ending Date" as '310120', answer 'No' to confirm
        ExpectedDate := PriceListHeader."Ending Date";
        PriceListHeader.Validate("Ending Date", PriceListHeader."Ending Date" + 1);

        // [THEN] Confirmation question: 'Do you want to update Ending Date'
        Assert.AreEqual(
            StrSubstNo(DateConfirmQst, PriceListHeader.FieldCaption("Ending Date")),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price List Line, where "Ending Date" is '300120'
        PriceListLine.Find();
        PriceListLine.TestField("Ending Date", ExpectedDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure T030_UpdateAmountTypeAnyNoLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with 'Any'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes no lines
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T031_UpdateAmountTypeAnyInLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with 'Any'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Any'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Any;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T032_UpdateAmountTypeAnyInLinesPriceAndDiscount()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Any' if lines contain a lines with both 'Price' and 'Discount'
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes two lines with "Amount Type" 'Price' and 'Discount'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Insert();
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Any'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Any);
    end;

    [Test]
    procedure T033_UpdateAmountTypePriceInLinesPriceOnly()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Price' if all lines contain 'Price' only
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Price'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Price'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Price);
    end;

    [Test]
    procedure T034_UpdateAmountTypeDiscountInLinesDiscountOnly()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLIne: Record "Price List Line";
    begin
        // [SCENARIO] "Amount Type" is 'Discount' if all lines contain 'Discount' only
        Initialize();
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();
        // [GIVEN] Price list includes one line with "Amount Type" 'Discount'
        PriceListHeader.Code := 'X';
        PriceListHeader.Insert();
        PriceListLine."Price List Code" := PriceListHeader.Code;
        PriceListLine."Line No." := 0;
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
        PriceListLine.Insert();

        // [WHEN] UpdateAmountType
        PriceListHeader.UpdateAmountType();
        // [THEN] "Amount Type" is 'Discount'
        PriceListHeader.TestField("Amount Type", PriceListHeader."Amount Type"::Discount);
    end;

    [Test]
    procedure T040_UpdateAllowLineDiscDoesNotUpdateLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Updated "Allow Line Disc." in the header does not update lines.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Allow Line Disc." in the header
        PriceListHeader.Validate("Allow Line Disc.", not PriceListHeader."Allow Line Disc.");
        // [THEN] Price list line, where "Allow Line Disc." is not changed
        PriceListLine.Find();
        PriceListLine.TestField("Allow Line Disc.", not PriceListHeader."Allow Line Disc.");
    end;

    [Test]
    procedure T041_UpdateAllowInvDiscDoesNotUpdateLines()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Updated "Allow Invoice Disc." in the header does not update lines.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Allow Invoice Disc." in the header
        PriceListHeader.Validate("Allow Invoice Disc.", not PriceListHeader."Allow Invoice Disc.");
        // [THEN] Price list line, where "Allow LiInvoicene Disc." is not changed
        PriceListLine.Find();
        PriceListLine.TestField("Allow Invoice Disc.", not PriceListHeader."Allow Invoice Disc.");
    end;

    [Test]
    procedure T042_UpdateCurrencyCodeWIthLinesNotAllowed()
    var
        Currency: Record Currency;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of "Currency Code" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Currency Code" in the header
        LibraryERM.CreateCurrency(Currency);
        asserterror PriceListHeader.Validate("Currency Code", Currency.Code);
        // [THEN] Error message: 'You cannot update Currency Code because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Currency Code")));
    end;

    [Test]
    procedure T043_UpdatePriceInclVatWithLinesNotAllowed()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of "Price Includes VAT" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "Price Includes VAT" in the header
        asserterror PriceListHeader.Validate("Price Includes VAT", not PriceListHeader."Price Includes VAT");
        // [THEN] Error message: 'You cannot update Price Includes VAT because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("Price Includes VAT")));
    end;

    [Test]
    procedure T044_UpdateVATBusGroupWithLinesNotAllowed()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // [SCENARIO] Update of "VAT Bus. Posting Gr. (Price)" in the header with lines not allowed.
        Initialize();
        CreatePriceList(PriceListHeader, PriceListLine);

        // [WHEN] Change "VAT Bus. Posting Gr. (Price)" in the header
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        asserterror PriceListHeader.Validate("VAT Bus. Posting Gr. (Price)", VATBusinessPostingGroup.Code);
        // [THEN] Error message: 'You cannot update VAT Bus. Posting Gr. (Price) because lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, PriceListHeader.FieldCaption("VAT Bus. Posting Gr. (Price)")));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure T050_UpdateStatusConfirmYes()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines updates lines with confirmation.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);

        // [WHEN] Set "Status" as 'Active' and answer 'Yes'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Confirmation question: 'Do you want to update Status to Active?'
        Assert.AreEqual(
            StrSubstNo(StatusUpdateQst, PriceListHeader.Status::Active),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmYesHandler
        // [THEN] Price list lines got "Status" 'Active'.
        PriceListHeader.TestField(Status, PriceListHeader.Status::Active);
        PriceListLine.Find();
        PriceListLine.TestField(Status, PriceListHeader.Status::Active);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T051_UpdateStatusConfirmNo()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Update of Status in the header with lines will not be updated without confirmation.
        Initialize();
        // [GIVEN] New price list, where "Status" is 'Draft'
        CreatePriceList(PriceListHeader, PriceListLine);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);

        // [WHEN] Set "Status" as 'Active' and answer 'No'
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);

        // [THEN] Confirmation question: 'Do you want to update Status to Active?'
        Assert.AreEqual(
            StrSubstNo(StatusUpdateQst, PriceListHeader.Status::Active),
            LibraryVariableStorage.DequeueText(), 'Confirm question'); // from ConfirmNoHandler
        // [THEN] Price list header and lines keep "Status" 'Draft'.
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        PriceListLine.Find();
        PriceListLine.TestField(Status, PriceListHeader.Status::Draft);
    end;

    [Test]
    procedure T052_IsEditable()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Price List should be editable only if Status is Draft.
        Initialize();

        PriceListHeader.Status := PriceListHeader.Status::Draft;
        Assert.IsTrue(PriceListHeader.IsEditable(), 'Draft');

        PriceListHeader.Status := PriceListHeader.Status::Active;
        Assert.IsFalse(PriceListHeader.IsEditable(), 'Active');

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        Assert.IsFalse(PriceListHeader.IsEditable(), 'Inactive')
    end;

    [Test]
    procedure T053_CannotDeleteActivePriceList()
    var
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO] Price List cannot be deleted if Status is Active.
        Initialize();
        PriceListHeader.DeleteAll();

        PriceListHeader.Code := 'X';
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Inactive;
        PriceListHeader.Insert(true);
        PriceListHeader.Delete(true);

        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Insert(true);
        asserterror PriceListHeader.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteActivePriceListErr, PriceListHeader.Code));
    end;


    [Test]
    procedure T100_DeletePricesOnCampaignDeletion()
    var
        Campaign: array[2] of Record Campaign;
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor("Price Source Type"::Campaign, Campaign[1]."No.", Campaign[2]."No.");

        // [WHEN] Delete Campaign 'A'
        Campaign[1].Delete(true);

        // [THEN] Price list headers and lines for Campaign 'A' are deleted, for Campaign 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Campaign, '', Campaign[1]."No.", Campaign[2]."No.");
    end;

    [Test]
    procedure T101_DeletePricesOnContactDeletion()
    var
        Contact: Array[2] of Record Contact;
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor("Price Source Type"::Contact, Contact[1]."No.", Contact[2]."No.");

        // [WHEN] Delete Contact 'A'
        Contact[1].Delete(true);

        // [THEN] Price list headers and lines for Contact 'A' are deleted, for Contact 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Contact, '', Contact[1]."No.", Contact[2]."No.");
    end;

    [Test]
    procedure T102_DeletePricesOnCustomerDeletion()
    var
        Customer: Array[2] of Record Customer;
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor("Price Source Type"::Customer, Customer[1]."No.", Customer[2]."No.");

        // [WHEN] Delete Customer 'A'
        Customer[1].Delete(true);

        // [THEN] Price list headers and lines for Customer 'A' are deleted, for Customer 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Customer, '', Customer[1]."No.", Customer[2]."No.");
    end;

    [Test]
    procedure T103_DeletePricesOnCustomerPriceGroupDeletion()
    var
        CustomerPriceGroup: Array[2] of Record "Customer Price Group";
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor("Price Source Type"::"Customer Price Group", CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerPriceGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Price Group 'A' are deleted, for Customer Price Group 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Customer Price Group", '', CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T104_DeletePricesOnCustomerDiscGroupDeletion()
    var
        CustomerDiscountGroup: Array[2] of Record "Customer Discount Group";
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor("Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);

        // [WHEN] Delete Customer Price Group 'A'
        CustomerDiscountGroup[1].Delete(true);

        // [THEN] Price list headers and lines for Customer Disc. Group 'A' are deleted, for Customer Disc. Group 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Customer Disc. Group", '', CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T105_DeletePricesOnVendorDeletion()
    var
        Vendor: Array[2] of Record Vendor;
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor("Price Source Type"::Vendor, Vendor[1]."No.", Vendor[2]."No.");

        // [WHEN] Delete Vendor 'A'
        Vendor[1].Delete(true);

        // [THEN] Price list headers and lines for Vendor 'A' are deleted, for Vendor 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Vendor, '', Vendor[1]."No.", Vendor[2]."No.");
    end;

    [Test]
    procedure T106_DeletePricesOnJobDeletion()
    var
        Job: Array[2] of Record Job;
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor("Price Source Type"::Job, Job[1]."No.", Job[2]."No.");

        // [WHEN] Delete Job 'A'
        Job[1].Delete(true);

        // [THEN] Price list headers and lines for Job 'A' are deleted, for Job 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::Job, '', Job[1]."No.", Job[2]."No.");
    end;

    [Test]
    procedure T107_DeletePricesOnJobTaskDeletion()
    var
        Job: Record Job;
        JobTask: Array[2] of Record "Job Task";
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor("Price Source Type"::"Job Task", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Delete Job 'A'
        JobTask[1].Delete(true);

        // [THEN] Price list headers and lines for JobTask 'A' are deleted, for JobTask 'B' are not deleted
        VerifyPricesDeleted("Price Source Type"::"Job Task", Job."No.", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.");
    end;

    [Test]
    procedure T110_ModifyPricesOnCampaignRename()
    var
        Campaign: array[2] of Record Campaign;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Campaigns 'A' and 'B' have related prices
        LibraryMarketing.CreateCampaign(Campaign[1]);
        LibraryMarketing.CreateCampaign(Campaign[2]);
        CreatePriceListFor("Price Source Type"::Campaign, Campaign[1]."No.", Campaign[2]."No.");

        // [WHEN] Rename Campaign 'A' to 'X'
        OldNo := Campaign[1]."No.";
        Campaign[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Campaign 'A' are modified to 'X', for Campaign 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Campaign, '', Campaign[1]."No.", OldNo, Campaign[2]."No.");
    end;

    [Test]
    procedure T111_ModifyPricesOnContactRename()
    var
        Contact: Array[2] of Record Contact;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Contacts 'A' and 'B' have related prices
        LibraryMarketing.CreateCompanyContact(Contact[1]);
        LibraryMarketing.CreateCompanyContact(Contact[2]);
        CreatePriceListFor("Price Source Type"::Contact, Contact[1]."No.", Contact[2]."No.");

        // [WHEN] Rename Contact 'A' to 'X'
        OldNo := Contact[1]."No.";
        Contact[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Contact 'A' are modified to 'X', for Contact 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Contact, '', Contact[1]."No.", OldNo, Contact[2]."No.");
    end;

    [Test]
    procedure T112_ModifyPricesOnCustomerRename()
    var
        Customer: Array[2] of Record Customer;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customers 'A' and 'B' have related prices
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        CreatePriceListFor("Price Source Type"::Customer, Customer[1]."No.", Customer[2]."No.");

        // [WHEN] Rename Customer 'A' to 'X'
        OldNo := Customer[1]."No.";
        Customer[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Customer 'A' are modified to 'X', for Customer 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Customer, '', Customer[1]."No.", OldNo, Customer[2]."No.");
    end;

    [Test]
    procedure T113_ModifyPricesOnCustomerPriceGroupRename()
    var
        CustomerPriceGroup: Array[2] of Record "Customer Price Group";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Price Groups 'A' and 'B' have related prices
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[1]);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup[2]);
        CreatePriceListFor("Price Source Type"::"Customer Price Group", CustomerPriceGroup[1].Code, CustomerPriceGroup[2].Code);

        // [WHEN] Rename CustomerPriceGroup 'A' to 'X'
        OldNo := CustomerPriceGroup[1].Code;
        CustomerPriceGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerPriceGroup 'A' are modified to 'X', for CustomerPriceGroup 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Customer Price Group", '', CustomerPriceGroup[1].Code, OldNo, CustomerPriceGroup[2].Code);
    end;

    [Test]
    procedure T114_ModifyPricesOnCustomerDiscGroupRename()
    var
        CustomerDiscountGroup: Array[2] of Record "Customer Discount Group";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Customer Disc Groups 'A' and 'B' have related prices
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[1]);
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup[2]);
        CreatePriceListFor("Price Source Type"::"Customer Disc. Group", CustomerDiscountGroup[1].Code, CustomerDiscountGroup[2].Code);

        // [WHEN] Rename CustomerDiscountGroup 'A' to 'X'
        OldNo := CustomerDiscountGroup[1].Code;
        CustomerDiscountGroup[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for CustomerDiscountGroup 'A' are modified to 'X', for CustomerDiscountGroup 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Customer Disc. Group", '', CustomerDiscountGroup[1].Code, OldNo, CustomerDiscountGroup[2].Code);
    end;

    [Test]
    procedure T115_ModifyPricesOnVendorRename()
    var
        Vendor: Array[2] of Record Vendor;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Vendors 'A' and 'B' have related prices
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        CreatePriceListFor("Price Source Type"::Vendor, Vendor[1]."No.", Vendor[2]."No.");

        // [WHEN] Rename Vendor 'A' to 'X'
        OldNo := Vendor[1]."No.";
        Vendor[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Vendor 'A' are modified to 'X', for Vendor 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Vendor, '', Vendor[1]."No.", OldNo, Vendor[2]."No.");
    end;

    [Test]
    procedure T116_ModifyPricesOnJobRename()
    var
        Job: Array[2] of Record Job;
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Jobs 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJob(Job[2]);
        CreatePriceListFor("Price Source Type"::Job, Job[1]."No.", Job[2]."No.");

        // [WHEN] Rename Job 'A' to 'X'
        OldNo := Job[1]."No.";
        Job[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for Job 'A' are modified to 'X', for Job 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::Job, '', Job[1]."No.", OldNo, Job[2]."No.");
    end;

    [Test]
    procedure T117_ModifyPricesOnJobTaskRename()
    var
        Job: Record Job;
        JobTask: Array[2] of Record "Job Task";
        OldNo: Code[20];
    begin
        Initialize();
        // [GIVEN] Two Job Tasks 'A' and 'B' have related prices
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask[1]);
        LibraryJob.CreateJobTask(Job, JobTask[2]);
        CreatePriceListFor("Price Source Type"::"Job Task", JobTask[1]."Job Task No.", JobTask[2]."Job Task No.", Job."No.");

        // [WHEN] Rename Job Task 'A' to 'X'
        OldNo := JobTask[1]."Job Task No.";
        JobTask[1].Rename(Job."No.", LibraryUtility.GenerateGUID());

        // [THEN] Price list headers and lines for JobTask 'A' are modified to 'X', for JobTask 'B' are not deleted
        VerifyPricesRenamed("Price Source Type"::"Job Task", Job."No.", JobTask[1]."Job Task No.", OldNo, JobTask[2]."Job Task No.");
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
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        FillPriceListHeader(PriceListHeader[1]);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Price List, where "Source Type" is 'Job Task', "Source No." is 'JT', "Parent Source No." is 'J'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"Job Task", Job."No.", JobTask."Job Task No.");
        FillPriceListHeader(PriceListHeader[2]);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[3], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[4], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, LibraryInventory.CreateItemNo());
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

    local procedure CreatePriceList(var PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line")
    begin
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"Customer", '');
        FillPriceListHeader(PriceListHeader);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20]; ParentSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, ParentSourceNo, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, '');

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, ParentSourceNo, SourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, '');
    end;

    local procedure CreatePriceListFor(SourceType: Enum "Price Source Type"; DeletedSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        PriceListHeader.DeleteAll();
        PriceListLine.DeleteAll();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, DeletedSourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, '');

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, SourceType, SourceNo);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, '');
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

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;
}
