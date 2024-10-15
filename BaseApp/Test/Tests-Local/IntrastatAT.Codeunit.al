#if not CLEAN22
codeunit 144061 "Intrastat AT"
{
    // // [FEATURE] [Intrastat]

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

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
    procedure TransactionTypes()
    var
        TransactionType: Record "Transaction Type";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 425729] All Transaction Types have description
        Assert.RecordCount(TransactionType, 18);
        TransactionType.FindSet();
        repeat
            TransactionType.TestField(Description);
        until TransactionType.Next() = 0;
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
        Initialize();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateCustomerWithCountryRegionCode(Customer, CreateCountryRegionWithIntrastatCode);
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNo(false));
        CreateAndPostSalesDoc(SalesHeader."Document Type"::Order, Customer."No.", Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Run Get Item Ledger Entries.
        RunGetItemLedgerEntriesToCreateJnlLines(IntrastatJnlBatch);

        // Verify: Verify Intrastat Journal gets the right entry.
        VerifyIntrastatJnlLineExists(IntrastatJnlBatch, Item."No.");
    end;

    [Test]
    procedure TotalWeightRounding()
    var
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        // [FEATURE] [Intrastat] [Export] [UT]
        // [SCENARIO 390312] Total Weight is rounded to 3 decimal places
        Assert.AreEqual(1, IntraJnlManagement.RoundTotalWeight(1), '');
        Assert.AreEqual(1.123, IntraJnlManagement.RoundTotalWeight(1.1234), '');
        Assert.AreEqual(1.679, IntraJnlManagement.RoundTotalWeight(1.6789), '');
    end;

    [Test]
    procedure IntrastatExport2022()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Export]
        // [SCENARIO 420178] Intrastat journal basic file export in format of 2022 (Supplementary Units = True)
        Initialize();
        IntrastatJnlLine.DeleteAll();

        // [GIVEN] Intrastat journal line (Supplementary Units = True)
        PrepareIntrastatJnlLine(IntrastatJnlLine);

        // [WHEN] Export Intrastat journal to file using format 2022
        RunIntrastatExport2022(FileTempBlob, IntrastatJnlLine);

        // [THEN] Basic fields are exported in format of 2022
        // [THEN] Quantity value is exported (TFS 423724)
        // [THEN] Tariff No value is exported w\o spaces (TFS 423720)
        VerifyIntrastatExportedFile2022(
            FileTempBlob, IntrastatJnlLine,
            TextZeroFormat(Format(IntrastatJnlLine.Quantity, 0, '<Integer><Decimals,4><Comma,,>'), 14));
    end;

    [Test]
    procedure IntrastatExport2022_NonSupplementary()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Export]
        // [SCENARIO 423724] Intrastat journal basic file export in format of 2022 (Supplementary Units = False)
        Initialize();
        IntrastatJnlLine.DeleteAll();

        // [GIVEN] Intrastat journal line (Supplementary Units = False)
        PrepareIntrastatJnlLine(IntrastatJnlLine);
        IntrastatJnlLine."Supplementary Units" := False;
        IntrastatJnlLine.Modify();

        // [WHEN] Export Intrastat journal to file using format 2022
        RunIntrastatExport2022(FileTempBlob, IntrastatJnlLine);

        // [THEN] Basic fields are exported in format of 2022
        // [THEN] Quantity value is not exported (blanked value) (TFS 423724)
        // [THEN] Tariff No value is exported w\o spaces (TFS 423720)
        VerifyIntrastatExportedFile2022(FileTempBlob, IntrastatJnlLine, '');
    end;

    [Test]
    procedure SuggestLinesAmountRounding()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Suggest Lines] [Rounding]
        // [SCENARIO 421109] Intrastat journal Suggest Lines Amount rounding
        Initialize();
        IntrastatJnlLine.DeleteAll();

        // [GIVEN] Posted EU Intrastat sales invoice with total Amount = 123.456
        DocumentNo := LibraryUtility.GenerateGUID();
        MockItemLedgerEntryWithValueEntry(DocumentNo, 123.456);

        // [WHEN] Suggest Lines
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        LibraryERM.CreateIntrastatJnlLine(
            IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        RunGetItemEntries(IntrastatJnlLine, WorkDate(), WorkDate());

        // [THEN] Suggested line has "Amount" = 123.456, "Statistical Value" = 123.456
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindFirst();
        IntrastatJnlLine.TestField(Amount, 123.456);
        IntrastatJnlLine.TestField("Statistical Value", 123.456);
    end;

    [Test]
    procedure JournalLinePageDecimals()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
        DecimalValue: Decimal;
    begin
        // [FEATURE] [UI] [Rounding]
        // [SCENARIO 421109] Intrastat journal page decimals rounding
        Initialize();

        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        LibraryERM.CreateIntrastatJnlLine(
            IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        DecimalValue := 123.456;
        IntrastatJnlLine.Quantity := DecimalValue;
        IntrastatJnlLine."Net Weight" := DecimalValue;
        IntrastatJnlLine."Total Weight" := DecimalValue;
        IntrastatJnlLine.Amount := DecimalValue;
        IntrastatJnlLine."Statistical Value" := DecimalValue;
        IntrastatJnlLine.Modify();

        IntrastatJournal.OpenEdit();
        IntrastatJournal.GotoRecord(IntrastatJnlLine);
        Assert.AreEqual(Format(123.46), IntrastatJournal.Quantity.Value, 'Quantity');
        Assert.AreEqual(Format(123.456), IntrastatJournal."Net Weight".Value, 'Net Weight');
        Assert.AreEqual(Format(123.456), IntrastatJournal."Total Weight".Value, 'Total Weight'); // TFS 425728
        Assert.AreEqual(Format(123.46), IntrastatJournal.Amount.Value, 'Amount');
        Assert.AreEqual(Format(123.46), IntrastatJournal."Statistical Value".Value, 'Statistical Value');
        IntrastatJournal.Close();
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Intrastat AT");
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();
        IntrastatJnlTemplate.DeleteAll(true);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Intrastat AT");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SetIntrastatCodeOnCountryRegion;
        SetTariffNoOnItems;
        SetCompanyInfoFields;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Intrastat AT");
    end;

    local procedure PrepareIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine."Tariff No." := '0123 45 67 89';
        IntrastatJnlLine."Item Description" :=
            CopyStr(
                LibraryUtility.GenerateRandomText(MaxStrLen(IntrastatJnlLine."Item Description")),
                1, MaxStrLen(IntrastatJnlLine."Item Description"));
        IntrastatJnlLine."Country/Region Code" := CreateCountryRegionWithIntrastatCode();
        IntrastatJnlLine."Country/Region of Origin Code" := CreateCountryRegionWithIntrastatCode();
        IntrastatJnlLine."Partner VAT ID" :=
            CopyStr(LibraryUtility.GenerateRandomAlphabeticText(12, 0), 1, MaxStrLen(IntrastatJnlLine."Partner VAT ID"));
        IntrastatJnlLine."Transaction Type" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(2, 0), 1, 2);
        IntrastatJnlLine."Transport Method" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(1, 0), 1, 1);
        IntrastatJnlLine."Total Weight" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        IntrastatJnlLine.Quantity := LibraryRandom.RandDecInRange(1000, 2000, 2);
        IntrastatJnlLine.Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        IntrastatJnlLine."Statistical Value" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        IntrastatJnlLine."Supplementary Units" := true;
        IntrastatJnlLine.Modify();
    end;

    local procedure MockItemLedgerEntryWithValueEntry(DocumentNo: Code[20]; SalesAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Sale;
        ItemLedgerEntry."Country/Region Code" := GetCountryRegionCode();
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Document No." := DocumentNo;
        ItemLedgerEntry.Insert();

        MockValueEntry(ItemLedgerEntry, SalesAmountActual);
    end;

    local procedure MockValueEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; SalesAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ValueEntry."Sales Amount (Actual)" := SalesAmountActual;
        ValueEntry.Insert();
    end;

    local procedure CreateAndPostSalesDoc(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20];
                                                            ItemNo: Code[20];
                                                            Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchDoc(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20];
                                                            ItemNo: Code[20];
                                                            Quantity: Decimal)
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
        CountryRegion.Code := LibraryUtility.GenerateRandomCodeWithLength(CountryRegion.FieldNo(Code), Database::"Country/Region", 2);
        CountryRegionCode := DelStr(CountryRegion.Code, 1, StrLen(CountryRegion.Code) - 2);
        CountryRegion.Validate("Intrastat Code", CountryRegionCode);
        CountryRegion.Validate("EU Country/Region Code", CountryRegionCode);
        CountryRegion.Insert(true);
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
        TempTariffNo := LibraryUtility.GenerateGUID();
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
            FindSet();
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

    local procedure FindIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CountryRegionCode: Code[10])
    begin
        with IntrastatJnlLine do begin
            SetRange("Country/Region Code", CountryRegionCode);
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            FindFirst();
        end;
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

    local procedure GetCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '<>''''');
        CountryRegion.FindFirst();
        exit(CountryRegion.Code);
    end;

    local procedure PrepareIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        DummyIntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
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
        LibraryVariableStorage.Enqueue(CalcDate('<-CM>', WorkDate()));
        LibraryVariableStorage.Enqueue(CalcDate('<CM>', WorkDate()));
        IntrastatJournal.GetEntries.Invoke;
        VerifyIntrastatJnlLinesExist(IntrastatJnlBatch);
        IntrastatJournal.Close();
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
        IntrastatDiskTaxAuthAT.Run();
    end;

    local procedure RunIntrastatExport2022(var FileTempBlob: Codeunit "Temp Blob"; IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
        FileOutStream: OutStream;
        ExportFormat: Enum "Intrastat Export Format";
    begin
        FileTempBlob.CreateOutStream(FileOutStream);
        IntrastatJnlLine.SetRecFilter();
        IntrastatMakeDiskTaxAuth.InitializeRequest(FileOutStream, ExportFormat::"2022");
        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlLine);
        IntrastatMakeDiskTaxAuth.UseRequestPage(false);
        IntrastatMakeDiskTaxAuth.Run();
    end;

    local procedure RunGetItemEntries(IntrastatJnlLine: Record "Intrastat Jnl. Line"; StartDate: Date; EndDate: Date)
    var
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        GetItemLedgerEntries.InitializeRequest(StartDate, EndDate, 0);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        GetItemLedgerEntries.UseRequestPage(false);
        GetItemLedgerEntries.Run();
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
        TariffNumber.FindFirst();
        Item.SetRange("Tariff No.", '');
        if not Item.IsEmpty() then
            Item.ModifyAll("Tariff No.", TariffNumber."No.");
    end;

    local procedure TextZeroFormat(Text: Text[20]; Length: Integer): Text[20]
    begin
        Assert.IsTrue(StrLen(Text) <= Length, StrSubstNo(CannotDisplayWithInvalidLengthErr, Text, Length));
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    local procedure ExtractZip(var ZipFileTempBlob: Codeunit "Temp Blob"; FileBlob: Codeunit "Temp Blob")
    var
        DataCompression: Codeunit "Data Compression";
        FileInStream: InStream;
        FileOutStream: OutStream;
        FilesList: List of [Text];
        FileName: Text;
    begin
        ZipFileTempBlob.CreateInStream(FileInStream);
        DataCompression.OpenZipArchive(FileInStream, false);
        DataCompression.GetEntryList(FilesList);
        FilesList.Get(1, FileName);
        FileBlob.CreateOutStream(FileOutStream);
        DataCompression.ExtractEntry(FileName, FileOutStream);
        DataCompression.CloseZipArchive();
    end;

    local procedure VerifyCNT19Section(FileName: Text; Quantity: Text[1])
    var
        File: DotNet File;
        Line: Text;
    begin
        Assert.IsTrue(FileManagement.ServerFileExists(FileName), FileNotCreatedErr);
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
        until IntrastatJnlLine.Next() = 0;

        SearchString :=
          Format(DelStr(CountryRegionCode, 1, StrLen(CountryRegionCode) - 2)) + KGMStringTxt + DecimalZeroFormat(TotalNetWeight, 12);
        VerifyStringInstancesInFile(FilenameSales, SearchString, 1);
    end;

    local procedure VerifyIntrastatExportedFile2022(var ZipFileTempBlob: Codeunit "Temp Blob"; IntrastatJnlLine: Record "Intrastat Jnl. Line"; QtyText: Text)
    var
        CountryRegion: Record "Country/Region";
        FileBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        Line: Text;
        Values: List of [Text];
        sep: Char;
        dec: Decimal;
    begin
        ExtractZip(ZipFileTempBlob, FileBlob);
        FileBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(Line);
        sep := 9; // TAB
        Values := Line.Split(sep);
        Assert.AreEqual(10, Values.Count(), '');

        Values.Get(1, Line);
        Assert.AreEqual(PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0'), Line, 'Tariff No');
        Values.Get(2, Line);
        Assert.AreEqual(IntrastatJnlLine."Item Description", Line, 'Item Description');
        Values.Get(3, Line);
        Assert.AreEqual(IntrastatJnlLine."Country/Region Code", Line, 'Country/Region Code');
        Values.Get(4, Line);
        Assert.AreEqual(IntrastatJnlLine."Country/Region of Origin Code", Line, 'Country/Region of Origin Code');
        Values.Get(5, Line);
        Assert.AreEqual(IntrastatJnlLine."Transaction Type", Line, 'Transaction Type');
        Values.Get(6, Line);
        dec := IntrastatJnlLine."Total Weight";
        Assert.AreEqual(TextZeroFormat(Format(dec, 0, '<Integer><Decimals,4><Comma,,>'), 14), Line, 'Total Weight');
        Values.Get(7, Line);
        Assert.AreEqual(QtyText, Line, 'Quantity');
        Values.Get(8, Line);
        dec := IntrastatJnlLine.Amount;
        Assert.AreEqual(TextZeroFormat(Format(dec, 0, '<Integer><Decimals,3><Comma,,>'), 13), Line, 'Amount');
        Values.Get(9, Line);
        dec := IntrastatJnlLine."Statistical Value";
        Assert.AreEqual(TextZeroFormat(Format(dec, 0, '<Integer><Decimals,3><Comma,,>'), 13), Line, 'Statistical Value');
        Values.Get(10, Line);
        Assert.AreEqual(IntrastatJnlLine."Partner VAT ID", Line, 'Partner VAT ID');
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
#endif