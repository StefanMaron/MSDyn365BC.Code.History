codeunit 144714 "ERM FA Reports Test"
{
    // // [FEATURE] [Fixed Asset] [Reports]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IncorrectLineAmountErr: Label 'Incorrect Line Amount';
        ValueNotExistErr: Label 'Value %1 does not exist on worksheet %2';
        TransferOperationTypeTxt: Label 'Transfer';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FAMovementAct()
    begin
        FAMovement;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFAMovementAct()
    begin
        PostedFAMovement;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA15Movement()
    var
        FADeprBook: Record "FA Depreciation Book";
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
    begin
        CreateFADeprBook(FADeprBook);
        CreateFADocHeader(FADocHeader);
        CreateFADocLine(FADocLine, FADocHeader, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        PrintFA15(FADocHeader."No.");

        VerifyFA15ReportValues(FADocHeader."No.", FADocLine."Book Value", FADocLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA15PostedMovement()
    var
        FADeprBook: Record "FA Depreciation Book";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFADocLine: Record "Posted FA Doc. Line";
    begin
        CreateFADeprBook(FADeprBook);
        CreatePostedFADocHeader(PostedFADocHeader);
        CreatePostedFADocLine(PostedFADocLine, PostedFADocHeader, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        PrintPostedFA15(PostedFADocHeader."No.");

        VerifyFA15ReportValues(PostedFADocHeader."No.", PostedFADocLine."Book Value", PostedFADocLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnpostedFA14()
    var
        DocumentNo: Code[20];
        NoOfLines: Integer;
        Amounts: array[20] of Decimal;
    begin
        DocumentNo := CreateFAPurchDoc(false, NoOfLines, Amounts);
        PrintFA14Receipt(DocumentNo, NoOfLines, Amounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFA14()
    var
        DocumentNo: Code[20];
        NoOfLines: Integer;
        Amounts: array[20] of Decimal;
    begin
        DocumentNo := CreateFAPurchDoc(true, NoOfLines, Amounts);
        PrintPostedFA14Receipt(DocumentNo, NoOfLines, Amounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_FAData()
    var
        FADeprBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFAWithDeprBook(FADeprBook);

        PrintF6FAInvCard(FADeprBook."FA No.");

        FixedAsset.Get(FADeprBook."FA No.");
        LibraryReportValidation.VerifyCellValue(14, 20, FADeprBook."FA No.");
        LibraryReportValidation.VerifyCellValue(15, 6, FixedAsset.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_InitialAcquisition()
    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [SCENARIO] FA Inventory Card FA-6 report when "Accrued Depr. Amount" is not defined

        // [GIVEN] Fixed Asset with Initial Acquisition = 100 and Depreciation = 10
        CreateFAWithDeprBook(FADeprBook);
        UpdateFALedgerEntries(FADeprBook, true);

        // [WHEN] Print FA Inventory Card FA-6 report
        PrintF6FAInvCard(FADeprBook."FA No.");

        // [THEN] Section 1 has empty field for Depreciation and Initial Acquisition = 100
        LibraryReportValidation.VerifyCellValue(35, 41, '');
        LibraryReportValidation.VerifyCellValue(35, 53, FormatAmount(FADeprBook."Initial Acquisition Cost"));

        // [THEN] Section 4 has 90 as Book Value for Acquisition Cost operation
        LibraryReportValidation.VerifyCellValue(59, 39, FormatAmount(FADeprBook."Acquisition Cost" + FADeprBook.Depreciation));
        LibraryReportValidation.VerifyCellValue(59, 10, Format(FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_InitialAcquisitionWithAccruedDeprAmount()
    var
        FADeprBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FALocation: Record "FA Location";
    begin
        // [SCENARIO 381708] FA Inventory Card FA-6 report when "Accrued Depr. Amount" has value

        // [GIVEN] Fixed Asset with Initial Acquisition = 100
        CreateFAWithDeprBook(FADeprBook);
        UpdateFALedgerEntries(FADeprBook, true);

        // [GIVEN] "Accrued Depr. Amount" is not zero for Fixed Asset
        FixedAsset.Get(FADeprBook."FA No.");
        FixedAsset."Accrued Depr. Amount" := LibraryRandom.RandDec(100, 2);
        FixedAsset.Modify();
        FALocation.Get(FixedAsset."FA Location Code");

        // [WHEN] Print FA Inventory Card FA-6 report
        PrintF6FAInvCard(FADeprBook."FA No.");

        // [THEN] Section 1 has 100 as Initial Acquisition and 10 Depreciation
        LibraryReportValidation.VerifyCellValue(35, 41, FormatAmount(FADeprBook.Depreciation));
        LibraryReportValidation.VerifyCellValue(35, 53, FormatAmount(FADeprBook."Initial Acquisition Cost"));
        // [THEN] Section 4 has 90 as Book Value for Acquisition Cost operation
        LibraryReportValidation.VerifyCellValue(59, 39, FormatAmount(FADeprBook."Acquisition Cost" + FADeprBook.Depreciation));
        LibraryReportValidation.VerifyCellValue(59, 10, Format(FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        // [THEN] Asset Location and Department Name are printed from Name field of FA Location
        LibraryReportValidation.VerifyCellValue(9, 1, FALocation.Name);
        LibraryReportValidation.VerifyCellValue(20, 27, FALocation.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_FAEntriesOnDate()
    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        EndingBookValue: Decimal;
        InitAcq: Decimal;
    begin
        // [SCENARIO 381708] FA Inventory Card FA-6 report when entries exist out of report date

        // [GIVEN] Fixed Asset with Initial Acquisition = 100 and Depreciation = 10
        CreateFAWithDeprBook(FADeprBook);
        UpdateFALedgerEntries(FADeprBook, true);
        InitAcq := FADeprBook."Initial Acquisition Cost";
        EndingBookValue := FADeprBook."Acquisition Cost" + FADeprBook.Depreciation;

        // [GIVEN] Acquisition cost entry of Amount 20 with FA Posting Date date more than WORKDATE
        MockFALedgerEntry(
          FALedgerEntry, FADeprBook, LibraryRandom.RandDate(5), FALedgerEntry."FA Posting Category"::" ");

        // [WHEN] Print FA Inventory Card FA-6 report on WORKDATE
        PrintF6FAInvCard(FADeprBook."FA No.");

        // [THEN] Section 1 has empty field for Depreciation and Initial Acquisition = 100
        LibraryReportValidation.VerifyCellValue(35, 41, '');
        LibraryReportValidation.VerifyCellValue(35, 53, FormatAmount(InitAcq));

        // [THEN] Section 4 has 90 as Book Value for Acquisition Cost operation
        LibraryReportValidation.VerifyCellValue(59, 39, FormatAmount(EndingBookValue));
        LibraryReportValidation.VerifyCellValue(59, 10, Format(FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_Transfer()
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        // [SCENARIO] FA Inventory Card FA-6 report with Transfer

        // [GIVEN] Fixed Asset with Tranfer entry
        CreateFAWithDeprBook(FADeprBook);
        UpdateFALedgerEntries(FADeprBook, false);

        // [WHEN] Print FA Inventory Card FA-6 report
        PrintF6FAInvCard(FADeprBook."FA No.");

        // [THEN] Transfer Entries are printed with Transfer Type and Ending Book Value
        VerifyFA6TransferEntries(FADeprBook);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_WriteOff()
    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // [SCENARIO] FA Inventory Card FA-6 report with Write-Off

        // [GIVEN] Fixed Asset with Write-Off entry
        CreateFAWithDeprBook(FADeprBook);
        MockFADisposalEntry(FADeprBook);

        // [WHEN] Print FA Inventory Card FA-6 report
        PrintF6FAInvCard(FADeprBook."FA No.");

        // [THEN] Write-Off is exported with Disposal Type and Ending Book Value
        LibraryReportValidation.VerifyCellValue(59, 39, FormatAmount(FADeprBook."Acquisition Cost" + FADeprBook.Depreciation));
        LibraryReportValidation.VerifyCellValue(59, 10, Format(FALedgerEntry."FA Posting Category"::Disposal));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_MainAssetComponents()
    var
        FADeprBook: Record "FA Depreciation Book";
        MainAssetComponent: Record "Main Asset Component";
    begin
        CreateFAWithDeprBook(FADeprBook);

        LibraryRUReports.MockMainAssetComponent(FADeprBook."FA No.");

        PrintF6FAInvCard(FADeprBook."FA No.");

        with MainAssetComponent do begin
            SetRange("Main Asset No.", FADeprBook."FA No.");
            FindFirst;
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Quantity)),
              StrSubstNo(ValueNotExistErr, Quantity, 2));
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Description),
              StrSubstNo(ValueNotExistErr, Description, 2));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FA6_PreciousMetal()
    var
        FADeprBook: Record "FA Depreciation Book";
        ItemFAPreciousMetal: Record "Item/FA Precious Metal";
    begin
        CreateFAWithDeprBook(FADeprBook);

        LibraryRUReports.MockItemFAPreciousMetal(FADeprBook."FA No.");

        PrintF6FAInvCard(FADeprBook."FA No.");

        with ItemFAPreciousMetal do begin
            SetRange("Item Type", "Item Type"::FA);
            SetRange("No.", FADeprBook."FA No.");
            FindFirst;
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Quantity)),
              StrSubstNo(ValueNotExistErr, Quantity, 2));
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, FormatAmount(Mass)),
              StrSubstNo(ValueNotExistErr, Mass, 2));
        end;
    end;

    [Test]
    [HandlerFunctions('FAJournalTemplateListPageHandler,ReportSelectionPrintPageHandler,FAPhysInventoryINV1aRequestPageHandler,FAComparativeSheetINV18RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListOfReportsIsInvokedWhenFAJournalIsPrinted()
    var
        ReportSelections: Record "Report Selections";
        FixedAssetJournal: TestPage "Fixed Asset Journal";
    begin
        // [FEATURE] [FA Journal]
        // [SCENARIO 201939] List of reports defined in Report Selections should be shown when Print button is pushed on FA Journal page.
        Initialize;

        // [GIVEN] FA Journal page.
        FixedAssetJournal.OpenEdit;

        // [WHEN] Push "Print" on the page ribbon.
        EnqueueReportsNos(ReportSelections.Usage::FAJ.AsInteger());
        FixedAssetJournal.Print.Invoke;

        // [THEN] List of reports set for FA Journal is shown.
        // Verification is done in ReportSelectionPrintPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        Commit();
        isInitialized := true;
    end;

    local procedure FAMovement()
    var
        FADeprBook: Record "FA Depreciation Book";
        FADocHeader: Record "FA Document Header";
        FADocLine: Record "FA Document Line";
    begin
        CreateFADeprBook(FADeprBook);
        CreateFADocHeader(FADocHeader);
        CreateFADocLine(FADocLine, FADocHeader, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        PrintFAMovement(FADocHeader."No.");

        VerifyFA2ReportValues(
          FADocHeader."No.", FADocHeader."Posting Date", FADocLine.Quantity, FADocLine.Amount, FADocLine."Book Value");
    end;

    local procedure PostedFAMovement()
    var
        FADeprBook: Record "FA Depreciation Book";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFADocLine: Record "Posted FA Doc. Line";
    begin
        CreateFADeprBook(FADeprBook);
        CreatePostedFADocHeader(PostedFADocHeader);
        CreatePostedFADocLine(PostedFADocLine, PostedFADocHeader, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        PrintPostedFAMovement(PostedFADocHeader."No.");

        VerifyFA2ReportValues(
          PostedFADocHeader."No.", PostedFADocHeader."Posting Date",
          PostedFADocLine.Quantity, PostedFADocLine.Amount, PostedFADocLine."Book Value");
    end;

    local procedure CreateFADocHeader(var FADocHeader: Record "FA Document Header")
    begin
        with FADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Movement;
            "No." := LibraryUtility.GenerateGUID;
            Insert(true);
            "Posting Date" := WorkDate;
            "FA Posting Date" := WorkDate;
            "FA Location Code" := CreateLocation;
            "New FA Location Code" := CreateLocation;
            Modify;
        end;
    end;

    local procedure CreateFADocLine(var FADocLine: Record "FA Document Line"; FADocHeader: Record "FA Document Header"; FANo: Code[20]; DeprBookCode: Code[10])
    begin
        with FADocLine do begin
            Init;
            "Document Type" := FADocHeader."Document Type";
            "Document No." := FADocHeader."No.";
            "Line No." := 10000;
            Insert;
            "FA No." := FANo;
            "Depreciation Book Code" := DeprBookCode;
            Quantity := LibraryRandom.RandInt(10);
            Amount := LibraryRandom.RandInt(100);
            "Book Value" := LibraryRandom.RandInt(1000);
            "FA Posting Group" := LibraryUtility.GenerateGUID;
            Modify;
        end;
    end;

    local procedure CreatePostedFADocHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        with PostedFADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Movement;
            "No." := LibraryUtility.GenerateGUID;
            "Posting Date" := WorkDate;
            "FA Posting Date" := WorkDate;
            "FA Location Code" := CreateLocation;
            "New FA Location Code" := CreateLocation;
            Insert;
        end;
    end;

    local procedure CreatePostedFADocLine(var PostedFADocLine: Record "Posted FA Doc. Line"; PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: Code[20]; DeprBookCode: Code[10])
    begin
        with PostedFADocLine do begin
            Init;
            "Document Type" := PostedFADocHeader."Document Type";
            "Document No." := PostedFADocHeader."No.";
            "Line No." := 10000;
            Insert;
            "FA No." := FANo;
            "Depreciation Book Code" := DeprBookCode;
            Quantity := LibraryRandom.RandInt(10);
            Amount := LibraryRandom.RandInt(100);
            "Book Value" := LibraryRandom.RandInt(1000);
            "FA Posting Group" := LibraryUtility.GenerateGUID;
            Modify;
        end;
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        with Location do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::Location);
            Insert;
            exit(Code);
        end;
    end;

    local procedure CreateFALocation(): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        FALocation.Init();
        FALocation.Code := LibraryUtility.GenerateRandomCode(FALocation.FieldNo(Code), DATABASE::"FA Location");
        FALocation.Name := LibraryUtility.GenerateGUID;
        FALocation.Insert();
        exit(FALocation.Code);
    end;

    local procedure PrintFAMovement(FADocNo: Code[20])
    var
        FADocHeader: Record "FA Document Header";
        FA2Report: Report "FA Movement FA-2";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        FADocHeader.SetRange("No.", FADocNo);
        FA2Report.SetTableView(FADocHeader);
        FA2Report.SetFileNameSilent(LibraryReportValidation.GetFileName);
        FA2Report.UseRequestPage(false);
        FA2Report.Run;
    end;

    local procedure PrintPostedFAMovement(PostedFADocNo: Code[20])
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFA2Report: Report "FA Posted Movement FA-2";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        PostedFADocHeader.SetRange("No.", PostedFADocNo);
        PostedFA2Report.SetTableView(PostedFADocHeader);
        PostedFA2Report.SetFileNameSilent(LibraryReportValidation.GetFileName);
        PostedFA2Report.UseRequestPage(false);
        PostedFA2Report.Run;
    end;

    local procedure VerifyFA2ReportValues(DocNo: Code[20]; PostingDate: Date; Qty: Decimal; Amount: Decimal; BookValue: Decimal)
    begin
        LibraryReportValidation.VerifyCellValue(16, 95, DocNo);
        LibraryReportValidation.VerifyCellValue(16, 111, Format(PostingDate));
        LibraryReportValidation.VerifyCellValue(22, 102, Format(Qty));
        LibraryReportValidation.VerifyCellValue(22, 118, Format(Amount));
        LibraryReportValidation.VerifyCellValue(22, 141, Format(BookValue));
    end;

    local procedure PrintFA14Receipt(DocumentNo: Code[20]; NoOfLines: Integer; Amounts: array[20] of Decimal)
    var
        PurchHeader: Record "Purchase Header";
        FA14Report: Report "Purch. FA Receipt FA-14";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        PurchHeader.SetRange("No.", DocumentNo);
        FA14Report.SetTableView(PurchHeader);
        FA14Report.SetFileNameSilent(LibraryReportValidation.GetFileName);
        FA14Report.UseRequestPage(false);
        FA14Report.Run;

        VerifyFA14ReportLineAmounts(NoOfLines, Amounts);
    end;

    local procedure PrintPostedFA14Receipt(DocumentNo: Code[20]; NoOfLines: Integer; Amounts: array[20] of Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        FA14Report: Report "Posted Purch. FA Receipt FA-14";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        PurchInvHeader.SetRange("No.", DocumentNo);
        FA14Report.SetTableView(PurchInvHeader);
        FA14Report.SetFileNameSilent(LibraryReportValidation.GetFileName);
        FA14Report.UseRequestPage(false);
        FA14Report.Run;

        VerifyFA14ReportLineAmounts(NoOfLines, Amounts);
    end;

    local procedure VerifyFA14ReportLineAmounts(NoOfLines: Integer; Amounts: array[20] of Decimal)
    var
        ExcelAmount: Decimal;
        StartRow: Integer;
        FoundValue: Boolean;
        Counter: Integer;
    begin
        StartRow := 56;
        for Counter := 1 to NoOfLines do begin
            Evaluate(ExcelAmount, LibraryReportValidation.GetValueAt(FoundValue, Counter + StartRow, 59));
            Assert.AreEqual(Amounts[Counter], ExcelAmount, IncorrectLineAmountErr);
        end;
    end;

    local procedure CreateFADeprBook(var FADeprBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DeprBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADeprBook, FixedAsset."No.", DeprBook.Code);
    end;

    local procedure CreateFAPurchDoc(Post: Boolean; var NoOfLines: Integer; var Amounts: array[20] of Decimal): Code[20]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
        Counter: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        for Counter := 1 to ArrayLen(Amounts) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
            PurchaseLine.Modify(true);
            Amounts[Counter] := PurchaseLine.Amount;
        end;

        NoOfLines := Counter;
        if Post then
            exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateFAWithDeprBook(var FADeprBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAsset."FA Location Code" := CreateFALocation;
        FixedAsset.Modify();
        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.SetRange("Depreciation Book Code", LibraryRUReports.GetFirstFADeprBook(FixedAsset."No."));
        FADeprBook.FindFirst;
        LibraryRUReports.MockFADepreciationBook(FADeprBook);
    end;

    local procedure MockFADisposalEntry(FADeprBook: Record "FA Depreciation Book")
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        MockFALedgerEntry(
          FALedgEntry, FADeprBook, WorkDate, FALedgEntry."FA Posting Category"::Disposal);
    end;

    local procedure MockFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FADeprBook: Record "FA Depreciation Book"; PostingDate: Date; FAPostCategory: Option)
    begin
        with FALedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FieldNo("Entry No."));
            "FA No." := FADeprBook."FA No.";
            "FA Posting Date" := PostingDate;
            "Depreciation Book Code" := FADeprBook."Depreciation Book Code";
            "FA Posting Category" := FAPostCategory;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure PrintF6FAInvCard(FANo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        FAInvCardFA6: Report "FA Inventory Card FA-6";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        FixedAsset.SetRange("No.", FANo);
        FAInvCardFA6.SetTableView(FixedAsset);
        FAInvCardFA6.InitializeRequest(WorkDate, LibraryRUReports.GetFirstFADeprBook(FANo));
        FAInvCardFA6.SetFileNameSilent(LibraryReportValidation.GetFileName);
        FAInvCardFA6.UseRequestPage(false);
        FAInvCardFA6.Run;
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        StdRepMgt: Codeunit "Local Report Management";
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;

    local procedure EnqueueReportsNos(DocUsage: Option)
    var
        ReportSelections: Record "Report Selections";
    begin
        with ReportSelections do begin
            Ascending(false);
            SetRange(Usage, DocUsage);
            FindSet;
            repeat
                LibraryVariableStorage.Enqueue("Report ID");
            until Next = 0;
        end;
    end;

    local procedure FilterFALedgerEntries(var FALedgEntry: Record "FA Ledger Entry"; FADeprBook: Record "FA Depreciation Book")
    begin
        FALedgEntry.SetRange("FA No.", FADeprBook."FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");
    end;

    local procedure UpdateFALedgerEntries(FADeprBook: Record "FA Depreciation Book"; InitialAcquisition: Boolean)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FilterFALedgerEntries(FALedgEntry, FADeprBook);
        with FALedgEntry do begin
            SetRange("Initial Acquisition", InitialAcquisition);
            FindSet;
            repeat
                Quantity := LibraryRandom.RandDecInRange(2, 5, 2);
                "Reclassification Entry" := not InitialAcquisition;
                Modify;
            until Next = 0;
        end;
    end;

    local procedure VerifyFA6TransferEntries(FADeprBook: Record "FA Depreciation Book")
    var
        FALedgEntry: Record "FA Ledger Entry";
        i: Integer;
    begin
        with FALedgEntry do begin
            SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type",
              "FA Posting Date", "Part of Book Value", "Reclassification Entry");
            FilterFALedgerEntries(FALedgEntry, FADeprBook);
            SetRange("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
            SetRange("Initial Acquisition", false);
            SetFilter(Quantity, '>0');
            SetRange("Reclassification Entry", true);
            FindSet;
            repeat
                i += 1;
                LibraryReportValidation.VerifyCellValue(58 + i, 39, FormatAmount(FADeprBook."Acquisition Cost" + FADeprBook.Depreciation));
                LibraryReportValidation.VerifyCellValue(58 + i, 10, TransferOperationTypeTxt);
            until Next = 0;
        end;
    end;

    local procedure PrintFA15(DocumentNo: Code[20])
    var
        FADocumentHeader: Record "FA Document Header";
        FAMovementFA15: Report "FA Movement FA-15";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        FADocumentHeader.SetRange("No.", DocumentNo);
        FAMovementFA15.SetTableView(FADocumentHeader);
        FAMovementFA15.SetFileNameSilent(LibraryReportValidation.GetFileName);
        FAMovementFA15.UseRequestPage(false);
        FAMovementFA15.Run;
    end;

    local procedure PrintPostedFA15(DocumentNo: Code[20])
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        PostedFAMovementFA15: Report "Posted FA Movement FA-15";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        PostedFADocHeader.SetRange("No.", DocumentNo);
        PostedFAMovementFA15.SetTableView(PostedFADocHeader);
        PostedFAMovementFA15.SetFileNameSilent(LibraryReportValidation.GetFileName);
        PostedFAMovementFA15.UseRequestPage(false);
        PostedFAMovementFA15.Run;
    end;

    local procedure VerifyFA15ReportValues(DocumentNo: Code[20]; BookValue: Decimal; Amount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValue(15, 73, DocumentNo);
        LibraryReportValidation.VerifyCellValue(31, 122, FormatAmount(BookValue));
        LibraryReportValidation.VerifyCellValue(31, 136, FormatAmount(Amount));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReportSelectionPrintPageHandler(var ReportSelectionPrint: TestPage "Report Selection - Print")
    begin
        ReportSelectionPrint.Last;
        repeat
            ReportSelectionPrint."Report ID".AssertEquals(LibraryVariableStorage.DequeueInteger);
        until not ReportSelectionPrint.Previous;
        ReportSelectionPrint.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAJournalTemplateListPageHandler(var FAJournalTemplateList: TestPage "FA Journal Template List")
    begin
        FAJournalTemplateList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAPhysInventoryINV1aRequestPageHandler(var FAPhysInventoryINV1a: TestRequestPage "FA Phys. Inventory INV-1a")
    begin
        FAPhysInventoryINV1a.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAComparativeSheetINV18RequestPageHandler(var FAComparativeSheetINV18: TestRequestPage "FA Comparative Sheet INV-18")
    begin
        FAComparativeSheetINV18.Cancel.Invoke;
    end;
}

