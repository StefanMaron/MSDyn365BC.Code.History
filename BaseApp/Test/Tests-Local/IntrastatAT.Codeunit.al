codeunit 144061 "Intrastat AT"
{
    // // [FEATURE] [Intrastat]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileManagement: Codeunit "File Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        CannotDisplayWithInvalidLengthErr: Label 'You cannot display %1 in a field of length %2.';
        FieldMustHaveValueErr: Label '%1 must have a value in %2';
        FileExtenstionTxt: Label '.EDI';
        FileNotCreatedErr: Label 'Intrastat file was not created';
        InternalRefNoErr: Label 'Internal Ref. No. is not correct in Intrastat Jnl. Line.';
        IntrastatLineWithTransSpecExistsErr: Label 'At least one Intrastat Jnl. Line has a Transaction Specification';
        KGMStringTxt: Label '''MEA+WT++KGM:';
        LessInstancesThanExpectedErr: Label 'Fewer instances than expected found';
        MoreInstancesThanExpectedErr: Label 'More instances than expected found';
        NoIntrastatJnlLineErr: Label 'No Intrastat Journal Line exists';
        WrongQtyInCNT19Err: Label 'Wrong quantity is specified in section CNT+19.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportOnBlankTransportMethod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        Initialize;
        // first without error, later with error
        DisableTransportMethodCheck;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(IntrastatJnlLine, IntrastatJnlBatch, '', FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // Exercise
        RunIntrastatJournalCheckList;

        // second with error
        EnableTransportMethodCheck;
        Commit();

        // Exercise
        asserterror RunIntrastatJournalCheckList;

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transport Method"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportOnBlankTransportMethod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        Initialize;
        // first without error, later with error
        DisableTransportMethodCheck;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(IntrastatJnlLine, IntrastatJnlBatch, '', FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // second with error
        EnableTransportMethodCheck;
        Commit();

        // Exercise
        asserterror RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transport Method"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskOnBlankTransportMethod()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilenameSales: Text;
        FilenamePurchase: Text;
        Filepath: Text;
    begin
        Initialize;
        // first without error, later with error
        DisableTransportMethodCheck;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(IntrastatJnlLine, IntrastatJnlBatch, '', FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // Exercise
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // second with error, need to fix up the batch to avoid 'reported' error
        EnableTransportMethodCheck;
        IntrastatJnlBatch.Get(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlBatch.Reported := false;
        IntrastatJnlBatch.Modify();
        Commit();

        // Exercise
        asserterror RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transport Method"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatJnlCheckListReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatCheckListReportOnBlankTransactionSpecification()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        Initialize;
        // first without error, later with error
        DisableTransactionSpecificationCheck;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(IntrastatJnlLine, IntrastatJnlBatch, FindOrCreateIntrastatTransportMethod,
          FindOrCreateIntrastatTransactionType, '', LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // Exercise
        RunIntrastatJournalCheckList;

        // second with error
        EnableTransactionSpecificationCheck;
        Commit();

        // Exercise
        asserterror RunIntrastatJournalCheckList;

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transaction Specification"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportOnBlankTransactionSpecification()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        Initialize;
        // first without error, later with error
        DisableTransactionSpecificationCheck;

        // Setup
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(IntrastatJnlLine, IntrastatJnlBatch, FindOrCreateIntrastatTransportMethod,
          FindOrCreateIntrastatTransactionType, '', LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // Exercise
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // second with error
        EnableTransactionSpecificationCheck;
        Commit();

        // Exercise
        asserterror RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transaction Specification"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskOnBlankTransactionSpecification()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilenameSales: Text;
        FilenamePurchase: Text;
        Filepath: Text;
    begin
        Initialize;
        // first without error, later with error
        DisableTransactionSpecificationCheck;

        // Setup
        PrepareIntrastatBatch(IntrastatJnlBatch);
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // Exercise
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // second with error, need to fix up the batch to avoid 'reported' error
        EnableTransactionSpecificationCheck;
        IntrastatJnlBatch.Get(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlBatch.Reported := false;
        IntrastatJnlBatch.Modify();
        Commit();

        // Exercise
        asserterror RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueErr, IntrastatJnlLine.FieldCaption("Transaction Specification"), IntrastatJnlLine.TableCaption));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatMakeDiskOnBlankTransportMethodAndTransactionSpecification()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilenameSales: Text;
        FilenamePurchase: Text;
        Filepath: Text;
    begin
        // [SCENARIO 344448] Stan can generate intrastat file from the Intrastat Journal with the correct content

        Initialize;
        DisableTransportMethodCheck;
        DisableTransactionSpecificationCheck;

        // [GIVEN] Intrastat batch with entries taken by "Get Entries"
        PrepareIntrastatBatch(IntrastatJnlBatch);
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Create intrastat file
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // [THEN] File content is correct
        // TFS 344448, 406878: A period text in the file is correct
        VerifyIntrastatMakeDiskFiles(IntrastatJnlLine, FilenameSales, FilenamePurchase);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatJournalWithIntrastatCodeFilter()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // Setup: Create Intrastat Journal Template and Batch. Create Customer, Item. Create and Post Sales Order.
        Initialize;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        CreateCustomerWithCountryRegionCode(Customer, CreateCountryRegionWithIntrastatCode);
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNo(false));
        CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, Customer."No.", Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Run Get Item Ledger Entries.
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // Verify: Verify Intrastat Journal gets the right entry.
        VerifyIntrastatJnlLineExists(IntrastatJnlBatch, Item."No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatJournalWhenTariffNoWithSpace()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        Item: array[2] of Record Item;
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
        TariffNo: Code[20];
        CountryRegionCode: Code[10];
        Filepath: Text;
        FilenameSales: Text;
        FilenamePurchase: Text;
        i: Integer;
        j: Integer;
    begin
        // Setup: Create Intrastat Journal Template and Batch. Create Customer, Item. Create and Post Sales Order.
        Initialize;
        DisableTransactionSpecificationCheck;
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);

        // Create 2 pairs data with 4 items and 2 Country Region Codes
        for i := 1 to ArrayLen(Customer) do begin
            TariffNo := CreateTariffNoWithSpace;
            CountryRegionCode := CreateCountryRegionWithIntrastatCode;
            CreateCustomerWithCountryRegionCode(Customer[i], CountryRegionCode);
            for j := 1 to ArrayLen(Item) do begin
                LibraryInventory.CreateItemWithTariffNo(Item[j], TariffNo);
                CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, Customer[i]."No.", Item[j]."No.", LibraryRandom.RandInt(10));
            end;
        end;

        // Run Get Item Ledger Entries.
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(DummyIntrastatJnlLine, IntrastatJnlBatch, FindOrCreateIntrastatTransportMethod,
          FindOrCreateIntrastatTransactionType, '', LibraryRandom.RandIntInRange(1, 10));
        Commit();
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // Exercise: Click Make Diskette to run Intrastat - Disk Tax Auth AT Report
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // Verify: "Internal Ref. No." are same for Intrastat Jnl. Lines with same Country Region Code
        VerifyIntrastatJnlLineForInternalRefNo(IntrastatJnlBatch, CountryRegionCode);

        // Verify: Total Net Weight in Export file is correct - Net Weight should be summed with same Country Region Code
        VerifyTotalNetWeightInstancesInFile(IntrastatJnlBatch, CountryRegionCode, FilenameSales);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOfSupplementaryUnitsInIntrastatDeclaration()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        SupplementaryUnitsCount: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376253] Intrastat file should contain quatity of Supplementary Units in a section called "CNT+19"

        Initialize;

        // [GIVEN] Item with Tarriff No having "Supplementary Units" = TRUE
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNo(true));

        // [GIVEN] Posted Purchase Invoice for 9 created Items
        SupplementaryUnitsCount := LibraryRandom.RandInt(9);
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo, Item."No.", SupplementaryUnitsCount);

        // Because of report's design there should be a shipment to call it without file saving UI
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo, Item."No.", LibraryRandom.RandInt(9));

        // [GIVEN] Suggested Intrastat Journal Line for Posted Invoice
        PrepareIntrastatBatch(IntrastatJnlBatch);
        RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatch.Name, Item."Tariff No.");
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Run "Make Diskette"
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // [THEN] "CNT+19" section of file contains 'CNT+19:0000000000009'
        VerifyCNT19Section(FilenamePurchase, Format(SupplementaryUnitsCount));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOfNonSupplementaryUnitsInIntrastatDeclaration()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376253] Intrastat file should not contain quatity of non Supplementary Units in a section called "CNT+19"

        Initialize;

        // [GIVEN] Item with Tarriff No having "Supplementary Units" = FALSE
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNo(false));

        // [GIVEN] Posted Purchase Invoice for 9 created Items
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo, Item."No.", LibraryRandom.RandInt(9));

        // Because of report's design there should be a shipment to call it without file saving UI
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo, Item."No.", LibraryRandom.RandInt(9));

        // [GIVEN] Intrastat Journal Line containing Invoice's data
        PrepareIntrastatBatch(IntrastatJnlBatch);
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Tariff No.", '<%1', Item."Tariff No.");
        if not IntrastatJnlLine.IsEmpty then
            IntrastatJnlLine.DeleteAll();
        Commit();
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Run "Make Diskette"
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // [THEN] "CNT+19" section of file contains 'CNT+19:0000000000000'
        VerifyCNT19Section(FilenamePurchase, Format(0));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOfSupplementaryUnitsInMixedIntrastatDeclaration()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNoSupp: Record Item;
        ItemSupp: Record Item;
        PurchaseHeader: Record "Purchase Header";
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        QtyOfSupplementaryItems: array[2] of Integer;
    begin
        // [FEATURE] [Supplementary Units] [Tariff No.]
        // [SCENARIO 376862] Intrastat file must contain quantity of only Supplementary Units in a section called "CNT+19"

        Initialize;

        // [GIVEN] Item "X" with Tarriff No having "Supplementary Units" = TRUE
        LibraryInventory.CreateItemWithTariffNo(ItemSupp, CreateTariffNo(true));

        // [GIVEN] Item "Y" with Tarriff No having "Supplementary Units" = FALSE
        LibraryInventory.CreateItemWithTariffNo(ItemNoSupp, CreateTariffNo(false));

        // [GIVEN] Posted Purchase Invoice for 4 created Items "X"
        QtyOfSupplementaryItems[1] := LibraryRandom.RandInt(4);
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo, ItemSupp."No.", QtyOfSupplementaryItems[1]);

        // [GIVEN] Posted Purchase Invoice for 3 created Items "X"
        QtyOfSupplementaryItems[2] := LibraryRandom.RandInt(4);
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo, ItemSupp."No.", QtyOfSupplementaryItems[2]);

        // [GIVEN] Posted Purchase Invoice for 13 created Items "Y"
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo, ItemNoSupp."No.", LibraryRandom.RandIntInRange(10, 20));

        // Because of report's design there should be a shipment to call it without file saving UI
        CreateAndPostPurchDoc(
          PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo, ItemSupp."No.", LibraryRandom.RandInt(9));

        // [GIVEN] Intrastat Journal Line containing Invoice's data
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Tariff No.", '<>%1&<>%2', ItemSupp."Tariff No.", ItemNoSupp."Tariff No.");
        if not IntrastatJnlLine.IsEmpty then
            IntrastatJnlLine.DeleteAll();

        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(
          IntrastatJnlLine, IntrastatJnlBatch, FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Run "Make Diskette"
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch, Filepath);

        // [THEN] "CNT+19" section of file contains 'CNT+19:0000000000007'
        VerifyCNT19Section(FilenamePurchase, Format(QtyOfSupplementaryItems[1] + QtyOfSupplementaryItems[2]));
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Intrastat AT");
        LibraryVariableStorage.Clear;
        LibraryReportDataset.Reset();
        IntrastatJnlTemplate.DeleteAll(true);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Intrastat AT");

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        SetIntrastatCodeOnCountryRegion;
        SetTariffNoOnItems;
        SetCompanyInfoFields;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Intrastat AT");
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchDoc(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateCountryRegionWithIntrastatCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CountryRegionCode: Code[10];
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegionCode := DelStr(CountryRegion.Code, 1, StrLen(CountryRegion.Code) - 2);
        CountryRegion.Validate("Intrastat Code", CountryRegionCode);
        CountryRegion.Validate("EU Country/Region Code", CountryRegionCode);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomerWithCountryRegionCode(var Customer: Record Customer; CountryRegionCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Modify(true);
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; PostingDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(PostingDate, 0, '<Year,2><Month,2>'));
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateTariffNo(SupplementaryUnits: Boolean) TariffNo: Code[8]
    var
        TariffNumber: Record "Tariff Number";
        TempTariffNo: Code[20];
    begin
        // TariffNo must be length 8 and unique
        TempTariffNo := LibraryUtility.GenerateGUID;
        TariffNo := CopyStr(TempTariffNo, StrLen(TempTariffNo) - MaxStrLen(TariffNo) + 1);
        TariffNumber.Init();
        TariffNumber.Validate("No.", TariffNo);
        TariffNumber.Validate("Supplementary Units", SupplementaryUnits);
        TariffNumber.Insert(true);
        exit(TariffNumber."No.");
    end;

    local procedure CreateTariffNoWithSpace() TariffNo: Code[10]
    var
        TariffNumber: Record "Tariff Number";
    begin
        // TariffNo must be length 8 and unique
        TariffNo :=
          Format(LibraryRandom.RandIntInRange(9406, 9410)) + ' ' +
          Format(LibraryRandom.RandIntInRange(10, 99)) + ' ' +
          Format(LibraryRandom.RandIntInRange(10, 99));
        TariffNumber.Init();
        TariffNumber.Validate("No.", TariffNo);
        TariffNumber.Insert(true);
    end;

    local procedure CountInternalRefNo(var IntrastatJnlLine: Record "Intrastat Jnl. Line") LineCount: Integer
    var
        InternalRefNo: Code[10];
    begin
        with IntrastatJnlLine do begin
            SetCurrentKey("Internal Ref. No.");
            FindSet;
            repeat
                if InternalRefNo <> "Internal Ref. No." then begin
                    InternalRefNo := "Internal Ref. No.";
                    LineCount += 1;
                end;
            until Next = 0;
            exit(LineCount);
        end;
    end;

    local procedure DecimalZeroFormat(DecimalNumber: Decimal; Length: Integer): Text[20]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumber), 1, '<'), 0, 1)), Length));
    end;

    local procedure DisableTransportMethodCheck()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Check Transport Method", false);
        CompanyInfo.Modify(true);
    end;

    local procedure DisableTransactionSpecificationCheck()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Check Transaction Specific.", false);
        CompanyInfo.Modify(true);
    end;

    local procedure EnableTransportMethodCheck()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Check Transport Method", true);
        CompanyInfo.Modify(true);
    end;

    local procedure EnableTransactionSpecificationCheck()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Check Transaction Specific.", true);
        CompanyInfo.Modify(true);
    end;

    local procedure FindIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CountryRegionCode: Code[10])
    begin
        with IntrastatJnlLine do begin
            SetRange("Country/Region Code", CountryRegionCode);
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            FindFirst;
        end;
    end;

    local procedure FindOrCreateIntrastatTransactionType(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Type"));
    end;

    local procedure FindOrCreateIntrastatTransportMethod(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
    end;

    local procedure FindOrCreateIntrastatTransactionSpecification(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Specification"));
    end;

    local procedure GetIntrastatFilenames(var Filepath: Text; var FilenameSales: Text; var FilenamePurchase: Text; IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        Filepath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(FileExtenstionTxt));
        FilenameSales := Filepath + '\' + CopyStr(CompanyInfo."Sales Authorized No.", 1, 4) +
          IntrastatJnlBatch."Statistics Period" + FileExtenstionTxt;
        FilenamePurchase := Filepath + '\' + CopyStr(CompanyInfo."Purch. Authorized No.", 1, 4) +
          IntrastatJnlBatch."Statistics Period" + FileExtenstionTxt;
    end;

    local procedure PrepareIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        LibraryERM.SetMandatoryFieldsOnIntrastatJnlLines(DummyIntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType, '',
          LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();
    end;

    local procedure RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatchName: Code[10]; TariffNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        IntrastatJnlLine.SetFilter("Tariff No.", '<>%1', TariffNo);
        IntrastatJnlLine.DeleteAll();
        Commit();
    end;

    local procedure RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', WorkDate));
        LibraryVariableStorage.Enqueue(CalcDate('<CM>', WorkDate));
        IntrastatJournal.GetEntries.Invoke;
        VerifyIntrastatJnlLinesExist(IntrastatJnlBatch);
        IntrastatJournal.Close;
    end;

    local procedure RunIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal")
    begin
        IntrastatJournal.OpenEdit;
    end;

    local procedure RunIntrastatJournalCheckList()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        IntrastatJournal.ChecklistReport.Invoke;
    end;

    local procedure RunIntrastatJournalForm(Type: Option)
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        RunIntrastatJournal(IntrastatJournal);
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(Type);
        IntrastatJournal.Form.Invoke;
    end;

    local procedure RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Path: Text)
    var
        IntrastatDiskTaxAuthAT: Report "Intrastat - Disk Tax Auth AT";
    begin
        LibraryVariableStorage.Enqueue(IntrastatJnlBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(IntrastatJnlBatch.Name);
        IntrastatDiskTaxAuthAT.InitializeRequest(Path);
        IntrastatDiskTaxAuthAT.Run;
    end;

    local procedure SetCompanyInfoFields()
    var
        CompanyInfo: Record "Company Information";
        ControlNo: Code[20];
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Statistic No.",
          LibraryUtility.GenerateRandomCode(CompanyInfo.FieldNo("Statistic No."), DATABASE::"Company Information"));
        ControlNo := LibraryUtility.GenerateRandomCode(CompanyInfo.FieldNo("Control No."), DATABASE::"Company Information");
        CompanyInfo.Validate("Control No.", CopyStr(ControlNo, StrLen(ControlNo) - 7)); // must be 8 chars long
        CompanyInfo.Modify(true);
    end;

    local procedure SetIntrastatCodeOnCountryRegion()
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure SetTariffNoOnItems()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst;
        Item.SetRange("Tariff No.", '');
        if not Item.IsEmpty then
            Item.ModifyAll("Tariff No.", TariffNumber."No.");
    end;

    local procedure TextZeroFormat(Text: Text[20]; Length: Integer): Text[20]
    begin
        Assert.IsTrue(StrLen(Text) <= Length, StrSubstNo(CannotDisplayWithInvalidLengthErr, Text, Length));
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    local procedure VerifyCNT19Section(FileName: Text; Quantity: Text[1])
    var
        File: DotNet File;
        Line: Text;
    begin
        Assert.IsTrue(FileManagement.ClientFileExists(FileName), FileNotCreatedErr);
        FileName := FileManagement.UploadFileSilent(FileName);
        Line := File.ReadAllText(FileName);

        Assert.AreEqual(Quantity, CopyStr(Line, StrPos(Line, 'CNT+19:') + 19, 1), WrongQtyInCNT19Err);
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.IsFalse(IntrastatJnlLine.IsEmpty, 'No Intrastat Journal Lines exist');
    end;

    local procedure VerifyIntrastatJnlLineExists(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Item No.", ItemNo);
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            Assert.IsFalse(IsEmpty, NoIntrastatJnlLineErr);
        end;
    end;

    local procedure VerifyIntrastatJnlLineForInternalRefNo(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CountryRegionCode: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        InternalRefNo: Text[10];
    begin
        with IntrastatJnlLine do begin
            FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, CountryRegionCode);
            repeat
                InternalRefNo := "Internal Ref. No.";
                Next;
                Assert.AreEqual(InternalRefNo, "Internal Ref. No.", InternalRefNoErr); // Verify "Internal Ref. No." are same for Intrastat Jnl. Lines
            until Next = 0;
        end;
    end;

    local procedure VerifyIntrastatMakeDiskFiles(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; FilenameSales: Text; FilenamePurchase: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        LineCount: Integer;
        PeriodText: Text;
    begin
        // files exist
        Assert.IsTrue(FileManagement.ServerFileExists(FilenameSales), FileNotCreatedErr);
        Assert.IsTrue(FileManagement.ServerFileExists(FilenamePurchase), FileNotCreatedErr);

        // upload to server
        FilenameSales := FileManagement.UploadFileSilent(FilenameSales);
        FilenamePurchase := FileManagement.UploadFileSilent(FilenamePurchase);

        // Assert Jnl. Line does not have Transaction Specification
        IntrastatJnlLine.SetFilter("Transaction Specification", '<>%1', '');
        Assert.IsTrue(IntrastatJnlLine.IsEmpty, IntrastatLineWithTransSpecExistsErr);
        IntrastatJnlLine.SetRange("Transaction Specification");

        // values in file ok
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment);
        LineCount := CountInternalRefNo(IntrastatJnlLine);
        VerifyStringInstancesInFile(FilenameSales, ':112+0:177', LineCount);

        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        PeriodText :=
          StrSubstNo('DTM+320:%1%2:610', '20', IntrastatJnlBatch."Statistics Period");
        VerifyStringInstancesInFile(FilenameSales, PeriodText, 1);

        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt);
        LineCount := CountInternalRefNo(IntrastatJnlLine);
        VerifyStringInstancesInFile(FilenamePurchase, ':112+0:177', LineCount);

        VerifyStringInstancesInFile(FilenameSales, PeriodText, 1);
    end;

    local procedure VerifyStringInstancesInFile(Filename: Text; SearchString: Text; InstanceCount: Integer)
    var
        File: File;
        Line: Text;
        i: Integer;
        Pos: Integer;
    begin
        File.WriteMode(false);
        File.TextMode(true);
        File.Open(Filename);

        File.Read(Line);
        for i := 1 to InstanceCount do begin
            Pos := StrPos(Line, SearchString);
            Assert.AreNotEqual(0, Pos, LessInstancesThanExpectedErr);
            Line := CopyStr(Line, Pos + StrLen(SearchString));
        end;
        Pos := StrPos(Line, SearchString);
        Assert.AreEqual(0, Pos, MoreInstancesThanExpectedErr);
    end;

    local procedure VerifyTotalNetWeightInstancesInFile(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CountryRegionCode: Code[10]; FilenameSales: Text)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TotalNetWeight: Integer;
        SearchString: Text[50];
    begin
        FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, CountryRegionCode);
        repeat
            TotalNetWeight += IntrastatJnlLine."Total Weight";
        until IntrastatJnlLine.Next = 0;

        FilenameSales := FileManagement.UploadFileSilent(FilenameSales);
        SearchString :=
          Format(DelStr(CountryRegionCode, 1, StrLen(CountryRegionCode) - 2)) + KGMStringTxt + DecimalZeroFormat(TotalNetWeight, 12);
        VerifyStringInstancesInFile(FilenameSales, SearchString, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntriesReqPage: TestRequestPage "Get Item Ledger Entries")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GetItemLedgerEntriesReqPage.StartingDate.SetValue(StartDate);
        GetItemLedgerEntriesReqPage.EndingDate.SetValue(EndDate);
        GetItemLedgerEntriesReqPage."Cost Regulation %".SetValue(0);
        GetItemLedgerEntriesReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskTaxAuthReqPageHandler(var IntrastatMakeDiskTaxAuthReqPage: TestRequestPage "Intrastat - Disk Tax Auth AT")
    begin
        IntrastatMakeDiskTaxAuthReqPage."Intrastat Jnl. Batch".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        IntrastatMakeDiskTaxAuthReqPage."Intrastat Jnl. Batch".SetFilter(Name, LibraryVariableStorage.DequeueText);
        IntrastatMakeDiskTaxAuthReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntratstatJnlFormReqPageHandler(var IntrastatFormReqPage: TestRequestPage "Intrastat - Form AT")
    var
        Type: Variant;
    begin
        LibraryVariableStorage.Dequeue(Type);
        IntrastatFormReqPage."Intrastat Jnl. Line".SetFilter(Type, Format(Type));
        IntrastatFormReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatJnlCheckListReqPageHandler(var IntrastatChecklistReqPage: TestRequestPage "Intrastat - Checklist AT")
    begin
        IntrastatChecklistReqPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

