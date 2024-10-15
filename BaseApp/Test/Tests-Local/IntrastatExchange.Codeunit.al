codeunit 144004 "Intrastat Exchange"
{
    // // [FEATURE] [Intrastat] [Report]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        FileNotCreatedErr: Label 'Intrastat file was not created';
        FileExtenstionTxt: Label '.EDI';
        WrongQtyInCNT18Err: Label 'Wrong quantity is specified in section CNT+18.';
        WrongQtyInCNT19Err: Label 'Wrong quantity is specified in section CNT+19.';
        SpecifyIntrastatJournalBatchErr: Label 'You must specify a template name and batch name for the Intrastat journal.';
        SupplementaryTagTxt: Label 'MEA+AAE++PCE:';
        LessInstancesThanExpectedErr: Label 'Fewer instances than expected found';
        MoreInstancesThanExpectedErr: Label 'More instances than expected found';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuantityInIntrastatDeclaration()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        Quantity: Decimal;
        i: Integer;
        Actual: Integer;
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 208579] Purchase quantities in a section called "CNT+19" of Intrastat file should be rounded to nearest integer
        Initialize;

        // [GIVEN] Item with Tarriff No having "Supplementary Units" = TRUE
        CreateItemWithTariffNo(Item, CreateTariffNo(true));

        // [GIVEN] 10 Posted Purchase Invoice with  with quantity = "0.16" each
        Quantity := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 2);
        for i := 1 to 10 do
            CreatePurchInvWithItem(Item."No.", Quantity);

        // [GIVEN] Intrastat Journal Line containing Invoice's data
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatch.Name, Item."Tariff No.");

        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Run "Make Diskette"
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] "CNT+19" section of intrastat file contains summary quantity rounded to nearest integer = "2"
        Evaluate(Actual, ExtractCNTSectionFromFile(FilenamePurchase, 'CNT+19:', 13));
        Assert.AreEqual(Round(Quantity * 10, 1), Actual, WrongQtyInCNT19Err);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuantityInIntrastatDeclaration()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        Quantity: Decimal;
        i: Integer;
        Actual: Integer;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 208579] Sales quantities in a section called "CNT+19" of Intrastat file should be rounded to nearest integer
        Initialize;

        // [GIVEN] Item with Tarriff No
        CreateItemWithTariffNo(Item, CreateTariffNo(true));

        // [GIVEN] 10 Posted Sales Invoice with quantity = "0.16" each
        Quantity := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 2);
        for i := 1 to 10 do
            CreateSalesInvWithItem(Item."No.", Quantity);

        // [GIVEN] Intrastat Journal Line containing Invoice's data
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatch.Name, Item."Tariff No.");

        SetMandatoryFieldsOnJnlLines(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);

        // [WHEN] Run "Make Diskette"
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] "CNT+19" section of intrastat file contains summary quantity rounded to nearest integer = "2"
        Evaluate(Actual, ExtractCNTSectionFromFile(FilenameSales, 'CNT+19:', 13));
        Assert.AreEqual(Round(Quantity * 10, 1), Actual, WrongQtyInCNT19Err);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportReceiptWeight()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilenameSales: Text;
        FilenamePurchase: Text;
        Filepath: Text;
        I: Integer;
        Actual: Integer;
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 208579] Weigth of receipt in a section called "CNT+18" of Intrastat file should be rounded to nearest integer
        Initialize;

        // [GIVEN] Item with weight = "0.16" kg
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        CreateItemWithTariffNo(Item, CreateTariffNo(false));
        Item."Net Weight" := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 2);
        Item.Modify(true);

        // [GIVEN] 10 intrastat purchase orders
        for I := 1 to 10 do
            CreateAndPostPurchDoc(
              PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo, Item."No.", 1);
        Commit();

        // [GIVEN] Intrastat Journal Line containing orders' data
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatch.Name, Item."Tariff No.");
        SetTransactionInfo(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification);
        Commit();
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Receipt);
        Commit();

        // [WHEN] Run "Make Diskette"
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] field "CNT+18:" contains common weight of 10 items rounded to nearest integer = "2" kg
        Evaluate(Actual, ExtractCNTSectionFromFile(FilenamePurchase, 'CNT+18:', 13));
        Assert.AreEqual(Round(Item."Net Weight" * 10, 1), Actual, WrongQtyInCNT18Err);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntratstatJnlFormReqPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestIntrastatFormReportShippmentWeight()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilenameSales: Text;
        FilenamePurchase: Text;
        Filepath: Text;
        Actual: Integer;
        I: Integer;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 208579] Weigth of shippment in a section called "CNT+18" of Intrastat file should be rounded to nearest integer
        Initialize;

        // [GIVEN] Item with weight = "0.16" kg
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        CreateItemWithTariffNo(Item, CreateTariffNo(false));
        Item."Net Weight" := LibraryRandom.RandDecInDecimalRange(0.1, 0.4, 2);
        Item.Modify(true);

        // [GIVEN] 10 intrastat sales orders
        for I := 1 to 10 do
            CreateAndPostSalesDoc(
              SalesHeader."Document Type"::Order, CreateForeignCustomerNo, Item."No.", 1);
        Commit();

        // [GIVEN] Intrastat Journal Line containing orders' data
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatch.Name, Item."Tariff No.");
        SetTransactionInfo(IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification);
        Commit();
        RunIntrastatJournalForm(IntrastatJnlLine.Type::Shipment);
        Commit();

        // [WHEN] Run "Make Diskette"
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] field "CNT+18:" contains common weight of 10 items rounded to nearest integer = "2" kg
        Evaluate(Actual, ExtractCNTSectionFromFile(FilenameSales, 'CNT+18:', 13));
        Assert.AreEqual(Round(Item."Net Weight" * 10, 1), Actual, WrongQtyInCNT18Err);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthATWhenBatchTemplateNameIsNotSpecified()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [SCENARIO 208382] Run 'Intrastat - Disk Tax Auth AT' report when filter for "Intrastat Jornal Batch".Name is not specified
        Initialize;

        // [GIVEN] Intrastat Journal Batch with "Journal Template Name" = "T", Name = "B"
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();

        // [WHEN] Run 'Intrastat - Disk Tax Auth AT' report where Intrastat Journal Batch has filters for "Intrastat Journal Name" = "T", Name = ''
        asserterror RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", '', '');

        // [THEN] Error raised 'Please specify Intrastat Journal Template and Batch Name'
        Assert.ExpectedError(SpecifyIntrastatJournalBatchErr);
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthATWhenBatchNameIsNotSpecified()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [SCENARIO 208382] Run 'Intrastat - Disk Tax Auth AT' report when filter for "Intrastat Jornal Batch"."Journal Template Name" is not specified
        Initialize;

        // [GIVEN] Intrastat Journal Batch with "Journal Template Name" = "T", Name = "B"
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();

        // [WHEN] Run 'Intrastat - Disk Tax Auth AT' report where Intrastat Journal Batch has filters for "Intrastat Journal Name" = empty, Name = "B"
        asserterror RunIntrastatMakeDiskTaxAuth('', IntrastatJnlBatch.Name, '');

        // [THEN] Error raised 'Please specify Intrastat Journal Template and Batch Name'
        Assert.ExpectedError(SpecifyIntrastatJournalBatchErr);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestShipmentSupplementaryUnitWithTagPCE()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: array[2] of Record Item;
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        Line: Text;
        ItemLine: array[2] of Text;
    begin
        // [FEATURE] [Shipment] [UT]
        // [SCENARIO 295289] Supplementary tag MEA+AAE++PCE exists for the Shipment lines with Tariff that use Supplementary Units
        Initialize;

        // [GIVEN] "Item1" with "Tariff1" and "Item2" with "Tariff2"
        // [GIVEN] "Tariff2" is using Supplementary Units
        CreateItemWithTariffNo(Item[1], CreateTariffNo(false));
        CreateItemWithTariffNo(Item[2], CreateTariffNo(true));

        // [GIVEN] Posted Sales Invoices for "Item1" and "Item2"
        CreateSalesInvWithItem(Item[1]."No.", LibraryRandom.RandDec(100, 2));
        CreateSalesInvWithItem(Item[2]."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Intrastat Journal populated for "Item1" and "Item2"
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Tariff No.", '<>%1&<>%2', Item[1]."Tariff No.", Item[2]."Tariff No.");
        IntrastatJnlLine.DeleteAll();
        IntrastatJnlLine.SetRange("Tariff No.");
        SetMandatoryFieldsOnJnlLines(
          IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // [WHEN] Run "Make Diskette" to export intrastat file
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] Created intrastat file contains MEA+AAE++PCE tag for the line with "Item2" only
        Line := ReadTextFile(FilenameSales);

        ItemLine[1] := CopyStr(Line, StrPos(Line, '+0001+'), 140);
        ItemLine[2] := CopyStr(Line, StrPos(Line, '+0002+'), 166);

        Assert.AreEqual(0, StrPos(ItemLine[1], SupplementaryTagTxt), MoreInstancesThanExpectedErr);
        Assert.AreEqual(88, StrPos(ItemLine[2], SupplementaryTagTxt), LessInstancesThanExpectedErr);
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatMakeDiskTaxAuthReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestReceiptSupplementaryUnitWithTagPCE()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: array[2] of Record Item;
        FilenamePurchase: Text;
        FilenameSales: Text;
        Filepath: Text;
        Line: Text;
        ItemLine: array[2] of Text;
    begin
        // [FEATURE] [Receipt] [UT]
        // [SCENARIO 295289] Supplementary tag MEA+AAE++PCE exists for the Receipts lines with Tariff that use Supplementary Units
        Initialize;

        // [GIVEN] "Item1" with "Tariff1" and "Item2" with "Tariff2"
        // [GIVEN] "Tariff2" is using Supplementary Units
        CreateItemWithTariffNo(Item[1], CreateTariffNo(false));
        CreateItemWithTariffNo(Item[2], CreateTariffNo(true));

        // [GIVEN] Posted Purchase Invoices for "Item1" and "Item2"
        CreatePurchInvWithItem(Item[1]."No.", LibraryRandom.RandDec(100, 2));
        CreatePurchInvWithItem(Item[2]."No.", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Intrastat Journal populated for "Item1" and "Item2"
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Tariff No.", '<>%1&<>%2', Item[1]."Tariff No.", Item[2]."Tariff No.");
        IntrastatJnlLine.DeleteAll();
        IntrastatJnlLine.SetRange("Tariff No.");
        SetMandatoryFieldsOnJnlLines(
          IntrastatJnlLine, IntrastatJnlBatch,
          FindOrCreateIntrastatTransportMethod, FindOrCreateIntrastatTransactionType,
          FindOrCreateIntrastatTransactionSpecification, LibraryRandom.RandDecInRange(1, 10, 2));
        Commit();

        // [WHEN] Run "Make Diskette" to export intrastat file
        GetIntrastatFilenames(Filepath, FilenameSales, FilenamePurchase, IntrastatJnlBatch);
        RunIntrastatMakeDiskTaxAuth(IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, Filepath);

        // [THEN] Created intrastat file contains MEA+AAE++PCE tag for the line with "Item2" only
        Line := ReadTextFile(FilenamePurchase);

        ItemLine[1] := CopyStr(Line, StrPos(Line, '+0001+'), 150);
        ItemLine[2] := CopyStr(Line, StrPos(Line, '+0002+'), 176);

        Assert.AreEqual(0, StrPos(ItemLine[1], SupplementaryTagTxt), MoreInstancesThanExpectedErr);
        Assert.AreEqual(98, StrPos(ItemLine[2], SupplementaryTagTxt), LessInstancesThanExpectedErr);
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Intrastat Exchange");
        LibraryRandom.SetSeed(1);
        LibraryVariableStorage.Clear;
        LibraryReportDataset.Reset();
        IntrastatJnlTemplate.DeleteAll(true);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Intrastat Exchange");

        IsInitialized := true;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        SetIntrastatCodeOnCountryRegion;
        SetDACHReportSelection;
        SetCompanyInfoFields;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Intrastat Exchange");
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
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateForeignCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", FindCountryRegionCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItemWithTariffNo(var Item: Record Item; TariffNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Tariff No.", TariffNo);
            Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Last Direct Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Modify(true);
        end;
    end;

    local procedure CreateSalesInvWithItem(ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateForeignCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure RunIntrastatJournal(var IntrastatJournal: TestPage "Intrastat Journal")
    begin
        IntrastatJournal.OpenEdit;
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

    local procedure RunIntrastatMakeDiskTaxAuth(IntrastatTemplateName: Code[10]; IntrastatBatchName: Code[10]; Filename: Text)
    var
        IntrastatDiskTaxAuthAT: Report "Intrastat - Disk Tax Auth AT";
    begin
        LibraryVariableStorage.Enqueue(IntrastatTemplateName);
        LibraryVariableStorage.Enqueue(IntrastatBatchName);
        IntrastatDiskTaxAuthAT.InitializeRequest(Filename);
        IntrastatDiskTaxAuthAT.Run;
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

    local procedure SetMandatoryFieldsOnJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; TransportMethod: Code[10]; TransactionType: Code[10]; TransactionSpecification: Code[10]; NetWeight: Decimal)
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindSet();
        repeat
            IntrastatJnlLine.Validate("Transport Method", TransportMethod);
            IntrastatJnlLine.Validate("Transaction Type", TransactionType);
            IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification);
            IntrastatJnlLine.Validate("Net Weight", NetWeight);
            IntrastatJnlLine.Validate("Internal Ref. No.",
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(IntrastatJnlLine."Internal Ref. No.")),
                1, MaxStrLen(IntrastatJnlLine."Internal Ref. No.")));
            IntrastatJnlLine.Modify(true);
        until IntrastatJnlLine.Next = 0;
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.IsFalse(IntrastatJnlLine.IsEmpty, 'No Intrastat Journal Lines exist');
    end;

    local procedure FindOrCreateIntrastatTransactionType(): Code[10]
    var
        TransactionType: Record "Transaction Type";
    begin
        TransactionType.Code := Format(LibraryRandom.RandIntInRange(1, 9));
        if not TransactionType.Get(TransactionType.Code) then
            TransactionType.Insert();
        exit(TransactionType.Code);
    end;

    local procedure FindOrCreateIntrastatTransportMethod(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
    end;

    local procedure FindCountryRegionCode(): Code[10]
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInfo.Get();
        with CountryRegion do begin
            SetFilter(Code, '<>%1', CompanyInfo."Country/Region Code");
            SetFilter("Intrastat Code", '<>%1', '');
            FindFirst;
            exit(Code);
        end;
    end;

    local procedure FindOrCreateIntrastatTransactionSpecification(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Specification"));
    end;

    local procedure SetDACHReportSelection()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Intrastat Checklist");
        DACHReportSelections.DeleteAll();
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Intrastat Disk");
        DACHReportSelections.DeleteAll();
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Intrastat Form");
        DACHReportSelections.DeleteAll();

        DACHReportSelections.Init();
        DACHReportSelections.Validate(Usage, DACHReportSelections.Usage::"Intrastat Checklist");
        DACHReportSelections.Validate("Report ID", REPORT::"Intrastat - Checklist AT");
        DACHReportSelections.Insert(true);

        DACHReportSelections.Init();
        DACHReportSelections.Validate(Usage, DACHReportSelections.Usage::"Intrastat Disk");
        DACHReportSelections.Validate("Report ID", REPORT::"Intrastat - Disk Tax Auth AT");
        DACHReportSelections.Insert(true);

        DACHReportSelections.Init();
        DACHReportSelections.Validate(Usage, DACHReportSelections.Usage::"Intrastat Form");
        DACHReportSelections.Validate("Report ID", REPORT::"Intrastat - Form AT");
        DACHReportSelections.Insert(true);
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

    local procedure GetIntrastatFilenames(var Filepath: Text; var FilenameSales: Text; var FilenamePurchase: Text; IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        Filepath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(FileExtenstionTxt));  // ClientTempFileName
        FilenameSales := Filepath + '\' + CopyStr(CompanyInfo."Sales Authorized No.", 1, 4) +
          IntrastatJnlBatch."Statistics Period" + FileExtenstionTxt;
        FilenamePurchase := Filepath + '\' + CopyStr(CompanyInfo."Purch. Authorized No.", 1, 4) +
          IntrastatJnlBatch."Statistics Period" + FileExtenstionTxt;
    end;

    local procedure RemoveExtraLinesFromIntrastatJnlBatch(IntrastatJnlBatchName: Code[10]; TariffNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        IntrastatJnlLine.SetFilter("Tariff No.", '<>%1', TariffNo);
        if not IntrastatJnlLine.IsEmpty() then
            IntrastatJnlLine.DeleteAll();
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

    local procedure CreatePurchInvWithItem(ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure ExtractIntrastatField(Text: Text; FieldName: Text; FieldLength: Integer) Result: Text
    var
        Length: Integer;
    begin
        Length := StrPos(Text, FieldName);
        Result := CopyStr(Text, Length + StrLen(FieldName), FieldLength);
    end;

    local procedure ExtractCNTSectionFromFile(FileName: Text; SectionName: Text; SectionLen: Integer): Text
    var
        Line: Text;
    begin
        Line := ReadTextFile(FileName);
        exit(ExtractIntrastatField(Line, SectionName, SectionLen));
    end;

    local procedure ReadTextFile(FileName: Text) Line: Text
    var
        File: DotNet File;
    begin
        Assert.IsTrue(FileManagement.ClientFileExists(FileName), FileNotCreatedErr);
        FileName := FileManagement.UploadFileSilent(FileName);
        Line := File.ReadAllText(FileName);
        File.Delete(FileName);
        exit(Line);
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

    local procedure SetTransactionInfo(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; TransportMethod: Code[10]; TransactionType: Code[10]; TransactionSpecification: Code[10])
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindSet();
        repeat
            IntrastatJnlLine.Validate("Transaction Type", TransactionType);
            IntrastatJnlLine.Validate("Transport Method", TransportMethod);
            IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification);
            IntrastatJnlLine.Validate("Internal Ref. No.",
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(IntrastatJnlLine."Internal Ref. No.")),
                1, MaxStrLen(IntrastatJnlLine."Internal Ref. No.")));
            IntrastatJnlLine.Modify(true);
        until IntrastatJnlLine.Next = 0;
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
}

