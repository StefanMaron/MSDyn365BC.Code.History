codeunit 134451 "ERM Fixed Assets"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        GLIntegrationDisposalError: Label '%1 must be equal to ''Yes''  in %2: %3=%4. Current value is ''No''.';
        AllowCorrectionError: Label '%1 must have a value in %2: %3=%4. It cannot be zero or empty.';
        UnknownError: Label 'Unknown error.';
        DateConfirmMessage: Label 'Posting Date %1 is different from Work Date %2.Do you want to continue?';
        NoOfYears: Integer;
        DepreciationBookCode2: Code[10];
        FixedAssetNo2: Code[20];
        GenJournalTemplateName: Code[10];
        GenJournalBatchName: Code[10];
        FAJournalTemplateName: Code[10];
        FAJournalBatchName: Code[10];
        DepreciationBookError: Label 'The %1 does not exist.';
        FADepreciationCreateError: Label 'FA Depreciation Book must be created for Fixed Asset No. %1';
        FADepreciationNotCreateError: Label 'FA Depreciation Book must not be created for Fixed Asset No. %1';
        NoOfYearsError: Label 'Total Number of Period No.must be equal to %1. Current value is %2.';
        ErrorText: Label 'Error Message Must be same.';
        MinNoOfYearError: Label 'You must specify No. of Years.';
        MaxNoOfYearError: Label 'No. of Years must be less than 200.';
        BlankCopyFromFANoError: Label 'You must specify a number in the Copy from %1 %2 field.', Comment = '%1: TABLECAPTION(Fixed Asset); %2: Field(No.)';
        BlankFirstFANoError: Label 'You must specify a number in First FA No. field or use the FA No. Series.';
        CopyFixedAssetError: Label '%1 must be equal to %2.';
        WrongDeprDaysErr: Label 'Wrong number of depreciation days.';
        CompletionStatsMsg: Label 'The depreciation has been calculated.\\No journal lines were created.';
        CompletionStatsFAJnlQst: Label 'The depreciation has been calculated.\\%1 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?', Comment = 'The depreciation has been calculated.\\5 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?';
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        MixedDerpFAUntilPostingDateErr: Label 'The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset %1.';
        CannotPostSameMultipleFAWhenDeprBookValueZeroErr: Label 'You cannot select the Depr. Until FA Posting Date check box because there is no previous acquisition entry for fixed asset %1.', Comment = '%1 - Fixed Asset No.';
        FirstMustBeAcquisitionCostErr: Label 'The first entry must be an Acquisition Cost';
        OnlyOneDefaultDeprBookErr: Label 'Only one fixed asset depreciation book can be marked as the default book';
        TestFieldThreeArgsErr: Label '%1 must have a value in %2: %3=%4, %5=%6, %7=%8. It cannot be zero or empty.';

    [Test]
    [Scope('OnPrem')]
    procedure PostFAJournalWithMultipleLine()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Posting of Fixed Asset Journal with multiple lines.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group and Create multiple FA Journal Line for
        // Acquisition Cost,Write-Down,Custom 1,Custom 2.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify FA Ledger Entry exist.
        VerifyFALedgerEntry(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCalculateDepreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // Test the Posting of Calculated Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2 .
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 2.Exercise: Calculate Depreciation and Change "Document No." in FA Journal line and Post FA Journal Line.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);

        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // 3.Verify: Verify FA Ledger Entry for Depreciation.
        VerifyDepreciationFALedger(FixedAsset."No.", DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcMessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationWithNoJournalOutput()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test Calculating Depreciation without generating any journal lines.

        // 1.Setup: Create Depreciation Book and FA Posting Group
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);

        // 2.Exercise: Calculate Depreciation with a non-existent fixed asset number to ensure no journal output
        LibraryLowerPermissions.SetO365FAView;
        RunCalculateDepreciation('DUMMY', DepreciationBook.Code);

        // 3.Verify: In DepreciationCalcMessageHandler, verify that no journal output is generated and that correct message is shown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvIntegrationError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test the Posting of Sales Invoice without Integration- Disposal on Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group. Create Customer, Create Sales Invoice with dimension.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post Sales Invoice.
        LibraryLowerPermissions.SetSalesDocsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3.Verify: Verify "Depreciation Book" Integration- Disposal Error.
        Assert.AreEqual(
          StrSubstNo(
            GLIntegrationDisposalError,
            DepreciationBook.FieldCaption("G/L Integration - Disposal"), DepreciationBook.TableCaption,
            DepreciationBook.FieldCaption(Code), DepreciationBook.Code),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvWithUseDuplicationList()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        DepreciationBook2: Record "Depreciation Book";
    begin
        // Test the Posting of Sales Invoice with two lines Fixed Assets with "Use Duplication List".

        // 1.Setup: Create Fixed Asset,2 Depreciation Books, FA Posting Group, Create Customer, Create Sales Invoice with 2 lines.
        Initialize;

        CreateDeprBookPartOfDuplicationList(DepreciationBook);
        CreateDeprBookPartOfDuplicationList(DepreciationBook2);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook2.Code, FixedAsset."FA Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        CreatePurchLine(PurchLine2, PurchHeader, FixedAsset."No.", DepreciationBook2.Code);

        // 2.Exercise: Post Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // 3.Verify: Verify FA Ledger Entry.
        VerifyFALedgerEntry(FixedAsset."No.", DepreciationBook2.Code);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation; // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvFixedAssetAppreciationAsFirstEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Appreciation]
        Initialize;

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify;
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Purchase invoice, where Vendor has non zero VAT group
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify;

        // [WHEN] Post the document
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] Error message: "The first entry must be an Acquisition Cost"
        Assert.ExpectedError(FirstMustBeAcquisitionCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvFixedAssetAppreciationAsSecondEntry()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLEntry: Record "G/L Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAPostingGroup: Record "FA Posting Group";
        VATEntry: Record "VAT Entry";
        PurchInvLine: Record "Purch. Inv. Line";
        AppreciationAmount: Decimal;
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Appreciation]
        Initialize;

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify;
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Posted Purchase invoice, where Fixed Asset is acquired
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::"Acquisition Cost");
        PurchLine.Modify;
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Invoice for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify;
        AppreciationAmount := Round(PurchLine."Direct Unit Cost" * PurchLine.Quantity, 0.01);

        // [WHEN] Post the document
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Document is posted, VAT Entry is posted, Base = 100.
        VATEntry.FindLast;
        VATEntry.TestField(Base, AppreciationAmount);
        // [THEN] FA Ledger Entry, where "FA Posting Type"=Appreciation, Amount = 100.
        FALedgerEntry.FindLast;
        FALedgerEntry.TestField("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
        FALedgerEntry.TestField(Amount, AppreciationAmount);
        // [THEN] G/L Entry, where G/L Account = 'AA', Amount = 100.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        GLEntry.SetRange("G/L Account No.", FAPostingGroup.GetAppreciationAccount);
        GLEntry.FindLast;
        GLEntry.TestField(Amount, AppreciationAmount);
        // [THEN] Posted Invoice Line, where "FA Posting Type" = Appreciation
        PurchInvLine.SetRange("Document No.", InvoiceDocNo);
        PurchInvLine.FindFirst;
        PurchInvLine.TestField("FA Posting Type", PurchInvLine."FA Posting Type"::Appreciation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoFixedAssetAppreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLEntry: Record "G/L Entry";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAPostingGroup: Record "FA Posting Group";
        AppreciationAmount: Decimal;
        CrMemoDocNo: Code[20];
    begin
        // [FEATURE] [Appreciation] [Credit Memo]
        Initialize;

        // [GIVEN] Fixed Asset, where FA posting group has "Appreciation Account" = 'AA'
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook."G/L Integration - Appreciation" := true;
        DepreciationBook.Modify;
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Posted Purchase invoice, where Fixed Asset is acquired
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::"Acquisition Cost");
        PurchLine.Modify;
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Invoice for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Modify;
        AppreciationAmount := Round(PurchLine."Direct Unit Cost" * PurchLine.Quantity, 0.01);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Purchase Credit Memo for Appreciation
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.");
        // [GIVEN] Purchase line, where Type = "Fixed Asset", "FA Posting Type"=Appreciation, "Direct Unit Cost"= 100
        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Direct Unit Cost", AppreciationAmount);
        PurchLine.Modify;

        // [WHEN] Post the document
        CrMemoDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Document is posted, VAT Entry is posted, Base = 100.
        // [THEN] FA Ledger Entry, where "FA Posting Type"=Appreciation, Amount = -100.
        FALedgerEntry.FindLast;
        FALedgerEntry.TestField("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
        FALedgerEntry.TestField(Amount, -AppreciationAmount);
        // [THEN] G/L Entry, where G/L Account = 'AA', Amount = -100.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        GLEntry.SetRange("G/L Account No.", FAPostingGroup.GetAppreciationAccount);
        GLEntry.FindLast;
        GLEntry.TestField(Amount, -AppreciationAmount);
        // [THEN] Posted Credit memo line, where "FA Posting Type" is 'Appreciation'
        PurchCrMemoLine.SetRange("Document No.", CrMemoDocNo);
        PurchCrMemoLine.FindFirst;
        PurchCrMemoLine.TestField("FA Posting Type", PurchCrMemoLine."FA Posting Type"::Appreciation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineFAPostingTypeAppreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Appreciation] [UT]
        Initialize;
        // [GIVEN] Purchase line with Fixed Asset
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);

        CreatePurchLine(PurchLine, PurchHeader, FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] FA Posting Group has "Appreciation Account", where "VAT Prod. Posting Group" = 'V' and "Gen. Prod. Posting Group" = 'G'
        CreateAppreciationAccount(PurchHeader, FixedAsset."FA Posting Group", GLAccount);

        // [WHEN] validate "FA Posting Type" as 'Appreciation'
        PurchLine.Validate("FA Posting Type", PurchLine."FA Posting Type"::Appreciation);

        // [THEN] Purchase lines, where "VAT Prod. Posting Group" = 'V' and "Gen. Prod. Posting Group" = 'G'
        PurchLine.TestField("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        PurchLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithFixedAsset()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        FALedgerEntry: Record "FA Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test the Posting of Sales Invoice with Fixed Asset.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for
        // Acquisition Cost,Write-Down,Custom 1,Custom 2. Create Customer, Create Sales Invoice with dimension.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        // 2.Exercise: Post Sales Invoice.
        LibraryLowerPermissions.SetSalesDocsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler;

        // 3.Verify: Verify FA Ledger Entry for Sales Invoice.
        VerifySalesFALedgerEntry(DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAllowCorrError()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test the Posting of Sales Order without Allow Correction of Disposal on Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2. Create Customer, Create and post Sales Invoice with dimension and create Sales Order.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler;

        Clear(SalesHeader);
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, FixedAsset."No.", DepreciationBook.Code);

        // 2.Exercise: Post Sales Order.
        LibraryLowerPermissions.SetSalesDocsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3.Verify: Verify "Depreciation Book" Allow Correction of Disposal Error.
        Assert.AreEqual(
          StrSubstNo(
            AllowCorrectionError,
            DepreciationBook.FieldCaption("Allow Correction of Disposal"), DepreciationBook.TableCaption,
            DepreciationBook.FieldCaption(Code), DepreciationBook.Code),
          GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProceedsOnDisposalAndGainLoss()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        FALedgerEntry: Record "FA Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test the Posting of Sales Order with Fixed Asset.

        // 1.Setup: Create Fixed Asset, Depreciation Book, FA Posting Group, Create and Post multiple FA Journal Line for Acquisition Cost,
        // Write-Down,Custom 1,Custom 2. Create Customer, Create and post Sales Invoice with dimension.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
        UpdateAllowCorrectionInBook(DepreciationBook);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);

        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2.Exercise: Create and Post Sales Order.
        LibraryLowerPermissions.SetSalesDocsPost;
        LibraryLowerPermissions.AddCustomerEdit;
        LibraryLowerPermissions.AddO365FAEdit;
        Clear(SalesHeader);
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, FixedAsset."No.", DepreciationBook.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler;

        // 3.Verify: Verify "Proceeds on Disposal" and "Gain/Loss" FA Ledger Entry for Sales Order.
        VerifySalesFALedgerEntry(DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
        VerifySalesFALedgerEntry(DocumentNo, FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Gain/Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AcquisitionCostNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Acquisition Cost.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateFAJournalBatch(FAJournalBatch);

        // Random Number Generator for Amount.
        Amount := LibraryRandom.RandDec(10000, 2);

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Acquisition Cost.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAcquisitionFALedgerEntry(FixedAsset."No.", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Depreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Depreciation.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Depreciation, -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::Depreciation, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteDownNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Write-Down.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Write-Down.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Write-Down", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Write-Down", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppreciationNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Appreciation.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Appreciation.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Appreciation, 1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::Appreciation, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom1NoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Custom 1.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Custom 1.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Custom 1", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Custom 1", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom2NoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Custom 2.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Custom 2.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Custom 2", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Custom 2", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalvageValueNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal with FA Posting Type Salvage Value.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;

        // Post a Line in FA Journal with FA Posting Type Salvage Value.
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::"Salvage Value", -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FANo, FALedgerEntry."FA Posting Type"::"Salvage Value", Amount);
    end;

    local procedure CreateFixedAssetWithoutIntegration(FAJnlLineFAPostingType: Option; AmountSign: Integer; var FAJournalLine: Record "FA Journal Line") Amount: Decimal
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateFAJournalBatch(FAJournalBatch);

        // Random Number Generator for Amount.
        Amount := LibraryRandom.RandDec(10000, 2);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        Amount := Round(Amount / 4) * AmountSign;  // Division by 4 is required to calculate Amount less than the original Amount."

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJnlLineFAPostingType, FixedAsset."No.", DepreciationBook.Code, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceNoIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;
        Amount := CreateFixedAssetWithoutIntegration(FAJournalLine."FA Posting Type"::Maintenance, -1, FAJournalLine);
        FANo := FAJournalLine."FA No.";

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Maintenance.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in Maintenance Ledger Entry correctly.
        VerifyMaintenanceLedgerEntry(FANo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        Amount: Decimal;
    begin
        // Test the Posting of Fixed Asset in FA Journal.

        // 1.Setup: Create Fixed Asset, Depreciation Book,FA Depreciation Book With FA Posting Group and remove check marks from
        // Integration Tab.
        Initialize;
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFixedAssetSetup(DepreciationBook);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        SetupPartialIntegrationInBook(DepreciationBook);

        CreateFAJournalBatch(FAJournalBatch);
        Amount := LibraryRandom.RandDec(10000, 2);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 2.Exercise: Post a Line in FA Journal with FA Posting Type Disposal.
        LibraryLowerPermissions.SetJournalsPost;
        LibraryLowerPermissions.AddO365FAEdit;
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::Disposal, FixedAsset."No.",
          DepreciationBook.Code, -Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // 3.Verify: Verify that the Amount is posted in FA Ledger Entry correctly.
        VerifyAmountInFALedgerEntry(FixedAsset."No.", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal", -Amount);
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure CreateFADepreciationBooksError()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test error occurs on running Create FA Depreciation Books report without Depreciation Book Code and Copy From FA No.

        // 1. Setup.
        Initialize;

        // 2. Exercise: Run Create FA Depreciation Books Report with Depreciation Book Code as blank and Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FAView;
        asserterror RunCreateFADepreciationBooks(FixedAsset, '', '');

        // 3. Verify: Verify error occurs on running Create FA Depreciation Books Report without Depreciation Book Code and Copy From FA No.
        Assert.ExpectedError(StrSubstNo(DepreciationBookError, DepreciationBook.TableCaption));
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetInactiveTrue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test FA Depreciation Book must not be created for Inactive Fixed Asset.

        // 1. Setup: Create Fixed Asset with Inactive as True. Create Depreciation Book.
        Initialize;
        CreateInactiveFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        Commit;  // COMMIT needs before running batch report.

        // 2. Exercise: Run Create FA Depreciation Books Report with Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FASetup;
        LibraryLowerPermissions.AddO365FAView;
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunCreateFADepreciationBooks(FixedAsset, DepreciationBook.Code, '');

        // 3. Verify: Verify FA Depreciation Book must not be created for Inactive Fixed Asset.
        Assert.IsFalse(
          FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code), StrSubstNo(FADepreciationNotCreateError, FixedAsset."No."));
    end;

    [Test]
    [HandlerFunctions('FADepreciationBooksHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetInactiveFalse()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Test FA Depreciation Book must be created for active Fixed Asset.

        // 1. Setup: Create Fixed Asset with Inactive as False. Create Depreciation Book.
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        Commit;  // COMMIT needs before running batch report.

        // 2. Exercise: Run Create FA Depreciation Books Report with Copy From FA No as blank.
        // Set Depreciation Book and Copy From FA No. into FA Depreciation Books Handler.
        LibraryLowerPermissions.SetO365FASetup;
        LibraryLowerPermissions.AddO365FAView;
        FixedAsset.SetRange("No.", FixedAsset."No.");
        RunCreateFADepreciationBooks(FixedAsset, DepreciationBook.Code, '');

        // 3. Verify: Verify FA Depreciation Book must be created for active Fixed Asset.
        Assert.IsTrue(
          FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code), StrSubstNo(FADepreciationCreateError, FixedAsset."No."));
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure MinNoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years is equal to 0 and check Error for Minimum No. of Year.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize;
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := 0;

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup;
        Commit;  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView;
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        asserterror DepreciationTableCard.CreateSumOfDigitsTable.Invoke;

        // 3.Verify: Check Error for Minimum No. of Year.
        Assert.IsTrue(StrPos(GetLastErrorText, MinNoOfYearError) > 0, ErrorText);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableLine: Record "Depreciation Table Line";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years and Verify Depreciation Table Line.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize;
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := LibraryRandom.RandInt(200);

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup;
        Commit;  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView;
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        DepreciationTableCard.CreateSumOfDigitsTable.Invoke;

        // 3.Verify: Check total number of Period No. for Depreciation Table.
        DepreciationTableLine.SetRange("Depreciation Table Code", DepreciationTableCard.Code.Value);
        Assert.AreEqual(DepreciationTableLine.Count, NoOfYears, StrSubstNo(NoOfYearsError, NoOfYears, DepreciationTableLine.Count));
    end;

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaxNoOfYearInDepreciationTable()
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        // Create Depreciation Table with Period Length, Run create Sum of Digits Table Report with
        // No. of Years is equal to 201 and check Error for maximum No. of Year.

        // 1.Setup: Create Depreciation Table with Period Length.
        Initialize;
        CreateDepreciationTable(DepreciationTableHeader);
        NoOfYears := LibraryRandom.RandInt(10) + 200;  // 200 maximum No. of Year.

        // 2.Exercise: Run Create Sum of Digits Table Report.
        LibraryLowerPermissions.SetO365FASetup;
        Commit;  // COMMIT is important here before use Depreciation Table Card Page.
        DepreciationTableCard.OpenView;
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableHeader.Code);
        asserterror DepreciationTableCard.CreateSumOfDigitsTable.Invoke;

        // 3.Verify: Check Error for Maximum No. of Year.
        Assert.IsTrue(StrPos(GetLastErrorText, MaxNoOfYearError) > 0, ErrorText);
    end;

    [HandlerFunctions('GenJournalBatchesHandler,FAJournalSetupGenBatchHandler')]
    [Scope('OnPrem')]
    procedure GenBatchNameOnFAJnlSetupLookUp()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Verify program opens General Journal batch on clicking lookup on 'Gen. Jnl. Batch Name' on FA Journal Setup.

        // 1.Setup: Find Depreciation Book,FA Journal Template and FA Journal Batch.
        Initialize;
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // Variables 'GenJournalTemplateName' and 'GenJournalBatchName' are declared Global as they are used in Handler method.
        GenJournalTemplateName := GenJournalTemplate.Name;
        GenJournalBatchName := GenJournalBatch.Name;

        // 2.Exercise: From Depreciation Book open FA Journal Setup page.
        // LibraryLowerPermissions.SetO365FAView; TODO: Remove the comment when you fix the test
        OpenFAJnlSetupFromDepBook(DepreciationBook.Code);

        // 3.Verify: Verification is done in 'GenJournalBatchesHandler' handler method.
    end;

    [HandlerFunctions('FAJournalSetupFABatchHandler,FAJournalBatchesHandler')]
    [Scope('OnPrem')]
    procedure FABatchNameOnFAJnlSetupLookUp()
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Verify program populates FA Journal Batch Name list when lookup is invoked on 'FA Journal Batch Name' field on FA Journal Setup.

        // 1.Setup: Find Depreciation Book,FA Journal Template and FA Journal Batch.
        Initialize;
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);

        // Variables 'FAJournalTemplateName' and 'FAJournalBatchName' are declared Global as they are used in Handler method.
        FAJournalTemplateName := FAJournalTemplate.Name;
        FAJournalBatchName := FAJournalBatch.Name;

        // 2.Exercise: From Depreciation Book open FA Journal Setup page.
        // LibraryLowerPermissions.SetO365FAView; TODO: Remove the comment when you fix the test
        OpenFAJnlSetupFromDepBook(DepreciationBook.Code);

        // 3.Verify: Verification is done in 'FAJournalBatchesHandler' handler method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithCopyFromFANoBlankError()
    var
        FixedAsset: Record "Fixed Asset";
        NoOfFixedAssetCopied: Integer;
    begin
        // Test error occurs on running Copy Fixed Asset Report with Copy From FA No. as blank.

        // 1. Setup: Create New Fixed Asset.
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2. Exercise:  Run Copy Fixed Asset Report with Copy From FA No. as blank.
        LibraryLowerPermissions.SetO365FAView;
        asserterror RunCopyFixedAsset(FixedAsset."No.", '', NoOfFixedAssetCopied, '', false);

        // 3. Verify: Verify error occurs on running Copy Fixed Asset Report with Copy From FA No. as blank.
        with FixedAsset do
            Assert.AreEqual(StrSubstNo(BlankCopyFromFANoError, TableCaption, FieldCaption("No.")), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithFirstFANoBlankError()
    var
        FixedAsset: Record "Fixed Asset";
        NoOfFixedAssetCopied: Integer;
    begin
        // Test error occurs on running Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.

        // 1. Setup: Create New Fixed Asset.
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2. Exercise: Run Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.
        LibraryLowerPermissions.SetO365FAView;
        asserterror RunCopyFixedAsset(FixedAsset."No.", FixedAsset."No.", NoOfFixedAssetCopied, '', false);

        // 3. Verify: Verify error occurs on running Copy Fixed Asset Report with First FA No. as blank and FA No. Series as false.
        Assert.AreEqual(StrSubstNo(BlankFirstFANoError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFixedAssetsWithFANoSeriesFalse()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetCount: Integer;
        NoOfFixedAssetCopied: Integer;
    begin
        // Test the Copy Fixed Assets functionality with Use FA No. Series as false.

        // 1.Setup: Create Fixed Asset
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAssetCount := FixedAsset.Count;
        NoOfFixedAssetCopied := LibraryRandom.RandInt(10);  // Using Random Generator to Copy the Number of Fixed Asset.

        // 2.Exercise: Run the Copy Fixed Assets with Use FA No. Series as false.
        LibraryLowerPermissions.SetO365FAEdit;
        RunCopyFixedAsset(FixedAsset."No.", FixedAsset."No.", NoOfFixedAssetCopied, GenerateFixedAssetNo, false);

        // 3.Verify: New count of Fixed Asset should be Equal to total of Previous Fixed Asset count and No of fixed assets copied.
        Assert.AreEqual(FixedAssetCount + NoOfFixedAssetCopied, FixedAsset.Count, CopyFixedAssetError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesUsingStatistics()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // Test to verify that FA Ledger entries page gets opened by invoking drill down on Fixed Asset Statistics page.

        // 1.Setup: Create Fixed Asset and Depreciation Book and set newly created Depreciation Book Code on Fixed Asset Card.
        // Open Fixed Asset Statistics page from Fixed Asset card.
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard.DepreciationBook."Depreciation Book Code".SetValue(DepreciationBook.Code);
        FixedAssetStatistics.Trap;
        FixedAssetCard.Statistics.Invoke;

        // 2.Exercise: Invoke drill down on Book Value field of Fixed Asset Statistics page.
        LibraryLowerPermissions.SetO365FAView;
        FALedgerEntries.Trap;
        FixedAssetStatistics."Book Value".DrillDown;

        // 3.Verify: Verify that FA Ledger Entries page gets opened.
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure WriteDownDepreciationTypeEnabled()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [SCENARIO 361344] Depreciation started from the next day of the last operation with "Depreciation Type" = TRUE.
        Initialize;

        // [GIVEN] Posted Acq. Cost and Write-Down operations with "FA Posting Date" = WORKDATE.
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        CreateAndPostAcqCostAndWriteDownFAJnlLines(FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] Set "Depreciation Type" TRUE in FA Posting Type Setup for Write-Down
        SetDeprTypeFAPostingTypeSetupWriteDown(DepreciationBook.Code);

        // [WHEN] Calculate depreciation with "FA Posting Date" = WORKDATE + 1. Post FA Journal.
        LibraryLowerPermissions.SetO365FAEdit;
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [THEN] Number of depreciation days in FA Ledger Entry equals 1
        VerifyFALedgEntryDeprDays(FixedAsset."No.", DepreciationBook.Code, 1);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure WriteDownDepreciationTypeDisabled()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [SCENARIO 361344] Depreciation started from the same day of the last operation with "Depreciation Type" = FALSE.
        Initialize;

        // [GIVEN] Posted Acq. Cost and Write-Down operations with "FA Posting Date" = WORKDATE.
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        CreateAndPostAcqCostAndWriteDownFAJnlLines(FixedAsset."No.", DepreciationBook.Code);
        // [GIVEN] Set "Depreciation Type" FALSE in FA Posting Type Setup for Write-Down
        ResetDeprTypeFAPostingTypeSetupWriteDown(DepreciationBook.Code);

        // [WHEN] Calculate depreciation with "FA Posting Date" = WORKDATE + 1. Post FA Journal.
        LibraryLowerPermissions.SetO365FAEdit;
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [THEN] Number of depreciation days in FA Ledger Entry equals 2
        VerifyFALedgEntryDeprDays(FixedAsset."No.", DepreciationBook.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJnlLineDimDuplicationListNoGLIntegration()
    var
        FAJnlLine: Record "FA Journal Line";
        ShortcutDimValueCode: array[2] of Code[20];
        FANo: Code[20];
        DeprBookCode: Code[10];
        DuplListDeprBookCode: Code[10];
    begin
        // [SCENARIO 363280] Post FA Jnl. Line with dimensions and "Use Duplication List"
        Initialize;
        // [GIVEN] Fixed Asset with two Depreciation Books "DB1", "DB2"
        // [GIVEN] "DB1" and "DB2": "G/L Integration - Acq. Cost" = FALSE, "DB2": "Part of Duplication List" = TRUE
        CreateFAAndDuplListSetup(FANo, DeprBookCode, DuplListDeprBookCode, false);
        // [GIVEN] FA Jnl. Line for "DB1", "Use Duplication List" = TRUE, Shortcut Dimension Codes = "DimVal1" and "DimVal2"
        CreateFAJnlLineWithDimensionsAndUseDuplicationList(FAJnlLine, ShortcutDimValueCode, FANo, DeprBookCode);
        // [WHEN] Post FA Jnl. Line
        LibraryLowerPermissions.SetO365FAEdit;
        LibraryFixedAsset.PostFAJournalLine(FAJnlLine);
        // [THEN] FA Jnl. Line for "DB2" created: "Shortcut Dimension 1 Code" = "DimVal1", "Shortcut Dimension 2 Code" = "DimVal2"
        VerifyFAJnlLineDimUseDuplicationList(DuplListDeprBookCode, ShortcutDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineDimDuplicationListGLIntegration()
    var
        GenJnlLine: Record "Gen. Journal Line";
        ShortcutDimValueCode: array[2] of Code[20];
        FANo: Code[20];
        DeprBookCode: Code[10];
        DuplListDeprBookCode: Code[10];
    begin
        // [SCENARIO 363280] Post Gen. Jnl. Line with dimensions and "Use Duplication List"
        Initialize;
        // [GIVEN] Fixed Asset with two Depreciation Books "DB1", "DB2"
        // [GIVEN] "DB1" and "DB2": "G/L Integration - Acq. Cost" = TRUE, "DB2": "Part of Duplication List" = TRUE
        CreateFAAndDuplListSetup(FANo, DeprBookCode, DuplListDeprBookCode, true);
        // [GIVEN] Gen. Jnl. Line for "DB1", "Use Duplication List" = TRUE, Shortcut Dimension Codes = "DimVal1" and "DimVal2"
        CreateGenJnlLineWithDimensionsAndUseDuplicationList(GenJnlLine, ShortcutDimValueCode, FANo, DeprBookCode);
        // [WHEN] Post Gen. Jnl. Line
        LibraryLowerPermissions.SetO365FAEdit;
        LibraryLowerPermissions.AddJournalsPost;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        // [THEN] Gen. Jnl. Line for "DB2" created: "Shortcut Dimension 1 Code" = "DimVal1", "Shortcut Dimension 2 Code" = "DimVal2"
        VerifyGenJnlLineDimUseDuplicationList(DuplListDeprBookCode, ShortcutDimValueCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADepreciationBookAfterPostFAJournal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        DocumentNo: Code[20];
    begin
        // Test to validate Amount on FA Depreciation Book After Post FA Journal Line.

        // Setup: Create FA Depreciation Book, Fixed Asset, FA Journal Line and post FA Journal Line.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // Exercise: Create and Post FA Journal Line.
        LibraryLowerPermissions.SetO365FAEdit;
        DocumentNo := CreateAndPostFAJournalLine(FixedAsset."No.", DepreciationBook.Code);

        // Verify: Verify FA Depreciation Book.
        VerifyFADepreciationBook(FixedAsset."No.", DocumentNo, DepreciationBook.Code);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForVATNetDisposal()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DummyGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link] [VAT on Net Disposal Entries]
        // [SCENARIO 376686] System creates "G/L Entry - VAT Entry Link" for GLEntry with VAT Amount <> 0 in case of posting Fixed Asset with "VAT on Net Disposal Entries" = TRUE.
        Initialize;
        CreateFixedAssetSetup(DepreciationBook);
        UpdateDeprBookVATNetDisposal(DepreciationBook);
        ModifyIntegrationInBook(DepreciationBook);

        // [GIVEN] Fixed Asset, where Depreciation Book has "VAT on Net Disposal Entries" = TRUE.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // [GIVEN] Post Fixed Asset Acquisition Cost.
        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Post Fixed Asset Depreciation.
        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);

        // [WHEN] Sell Fixed Asset. System creates: GLEntry "A" with VAT Amount <> 0; VATEntry "B".
        LibraryLowerPermissions.SetSalesDocsPost;
        LibraryLowerPermissions.AddCustomerEdit;
        LibraryLowerPermissions.AddO365FAEdit;
        SellFixedAsset(SalesHeader, SalesHeader."Document Type"::Invoice, FixedAsset."No.", DepreciationBook.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "G/L Entry - VAT Entry Link" has record with "G/L Entry No." = A, "VAT Entry No." = B
        FindSalesInvoiceVATEntry(VATEntry, DocumentNo);
        FindSalesInvoiceGLEntryWithVATAmount(GLEntry, DocumentNo, GetVATEntryAmount(VATEntry));
        DummyGLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Entry No.");
        DummyGLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
        Assert.RecordIsNotEmpty(DummyGLEntryVATEntryLink);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceVendorNoIsPreserved()
    var
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
        MaintenanceRegistration: TestPage "Maintenance Registration";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        Initialize;
        // [GIVEN] Fixed Asset, with a Vendor as 'Maintenance Vendor'
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPurchase.CreateVendor(Vendor);

        FixedAssetCard.OpenEdit;
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."Maintenance Vendor No.".SetValue(Vendor."No.");

        // [WHEN] Open Maintenance Registration Page and add a Service Date and a random Comment
        LibraryLowerPermissions.SetO365FAEdit;
        MaintenanceRegistration.Trap;
        FixedAssetCard."Maintenance &Registration".Invoke;
        MaintenanceRegistration."Service Date".SetValue(WorkDate);
        MaintenanceRegistration.Comment.SetValue(CopyStr(LibraryUtility.GenerateRandomText(5), 1, 5));

        // [THEN] The Maintenance Vendor should be preserved from Fixed Asset's Card
        MaintenanceRegistration."Maintenance Vendor No.".AssertEquals(FixedAssetCard."Maintenance Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingFAClassChangesSubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
    begin
        // Setup Subclasses with different classes
        FASetupClassesAndSubclasses(FAClass1, FASubclassWithFAClass1Parrent, FAClass2, FASubclassWithFAClass2Parrent, FASubclassWithNoClass);

        LibraryLowerPermissions.SetO365FAEdit;

        // [GIVEN] Blank Subclass
        // [WHEN] Setting a Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remains blank
        Assert.AreEqual('', FixedAsset."FA Subclass Code", 'Subclass remains blank');

        // [GIVEN] Subclass belonging to a differant class
        FixedAsset."FA Subclass Code" := FASubclassWithFAClass2Parrent.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass gets cleared
        Assert.AreEqual('', FixedAsset."FA Subclass Code", 'Subclass gets cleared');

        // [GIVEN] Subclass belonging to the same class
        FixedAsset."FA Subclass Code" := FASubclassWithFAClass1Parrent.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remaines unchanged
        Assert.AreEqual(FASubclassWithFAClass1Parrent.Code, FixedAsset."FA Subclass Code", 'Subclass remaines unchanged 1');

        // [GIVEN] Subclass belonging to all classes
        FixedAsset."FA Subclass Code" := FASubclassWithNoClass.Code;
        // [WHEN] Setting Class
        FixedAsset.Validate("FA Class Code", FAClass1.Code);
        // [THEN] Subclass remaines unchanged
        Assert.AreEqual(FASubclassWithNoClass.Code, FixedAsset."FA Subclass Code", 'Subclass remaines unchanged 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingFASubclassChangesClass()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
    begin
        // Setup Subclasses with different classes
        FASetupClassesAndSubclasses(FAClass1, FASubclassWithFAClass1Parrent, FAClass2, FASubclassWithFAClass2Parrent, FASubclassWithNoClass);

        LibraryLowerPermissions.SetO365FAEdit;

        // [GIVEN] Blank Class and a Subclass with class
        // [WHEN] Setting a Subclass
        FixedAsset.Validate("FA Subclass Code", FASubclassWithFAClass1Parrent.Code);
        // [THEN] Class get the value of belonging Subclass
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Class get the value of belonging Subclass');

        // [GIVEN] Existing Class and a Subclass with blank
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Still the same class');
        // [WHEN] Setting a Subclass
        FixedAsset.Validate("FA Subclass Code", FASubclassWithNoClass.Code);
        // [THEN] Class remaine unchanged
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Class remaine unchanged');

        // [GIVEN] Existing Class and a Subclass with blank
        Assert.AreEqual(FAClass1.Code, FixedAsset."FA Class Code", 'Still the same class');
        // [WHEN] Setting a Subclass with a differerent class
        asserterror FixedAsset.Validate("FA Subclass Code", FASubclassWithFAClass2Parrent.Code);
        // [THEN] Error telling the user that this is invalid
        Assert.ExpectedError('This fixed asset subclass belongs to a different fixed asset class.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForFASalesAccOnDispLoss()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        FANo: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link] [VAT] [Sales]
        // [SCENARIO 202344] VATEntry is linked to "VAT" GLEntry with "G/L Account No." = FAPostingGroup."Sales Acc. on Disp. (Loss)" when sale fixed asset with "Depr. until FA Posting Date" = TRUE
        Initialize;

        // [GIVEN] Fixed Asset with "Sales Acc. on Disp. (Loss)" = "DispLossGLAcc", "Disposal Calculation Method" = "Gross", "VAT on Net Disposal Entries" = TRUE
        FANo := CreateFAWithBookGrossAndNetDisposal;

        // [GIVEN] Acquisistion cost on "Posting Date" = 01-01-2019
        CreateAndPostFAJournalLine(FANo, GetFADeprBookCode(FANo));

        // [WHEN] Sale fixed asset (sales invoice "SI") on "Posting Date" = 01-02-2019 with "Depr. until FA Posting Date" = TRUE
        DocumentNo := CreatePostFixedAssetSalesInvoice(CalcDate('<1M>', WorkDate), FANo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] There is a GLEntry "X" with "Document Type" = "Invoice", "Document No." = "SI", "Gen. Posting Type" = "Sale", "G/L Account No." = "DispLossGLAcc"
        GLAccountNo := GetFASalesAccOnDispLoss(FANo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, GLEntry."Gen. Posting Type"::Sale, GLAccountNo);

        // [THEN] There is a VATEntry "Y" with "Document Type" = "Invoice", "Document No." = "SI", Type = "Sale"
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo, VATEntry.Type::Sale);

        // [THEN] There is a "G/L Entry - VAT Entry Link" record with "G/L Entry No." = "X", "VAT Entry No." = "Y"
        GLEntryVATEntryLink.Get(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithDifferentDeprUntilFAPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Acquisition Cost] [Depr. Until FA Posting Date]
        // [SCENARIO 201778] Stans gets error when he posts purchase invoice with two lines for the same fixed asset and mixed "Depr. until FA Posting Date" attribute
        Initialize;

        // [GIVEN] Purchase invoice with two lines for the same fixed asset
        // [GIVEN] Line[1] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] Line[2] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = FALSE
        CreatePurchInvoiceWithTwoFixedAsset(PurchaseHeader, FixedAsset, true, false);

        // [WHEN] Post invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Error "The value in the Depr. Until FA Posting Date field must be the same on lines for the same fixed asset."
        Assert.ExpectedError(StrSubstNo(MixedDerpFAUntilPostingDateErr, FixedAsset."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSameDeprUntilFAPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Acquisition Cost] [Depr. Until FA Posting Date]
        // [SCENARIO 201778] Stans gets error when he posts purchase invoice with two lines for the same fixed asset where "Depr. until FA Posting Date" = TRUE and there is no acqusition cost registered
        Initialize;

        // [GIVEN] Purchase invoice with two lines for the same fixed asset
        // [GIVEN] Line[1] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] Line[2] Type = Fixed Asset, "No." = "FA" and "Depr. until FA Posting Date" = TRUE
        // [GIVEN] There is no any acqusition cost registered for the fixed asset
        CreatePurchInvoiceWithTwoFixedAsset(PurchaseHeader, FixedAsset, true, true);

        // [WHEN] Post invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Error "You cannot post multiple purchase lines for the same fixed asset FA when Depr. Until FA Posting Date is TRUE and you've already registered depreciation."
        Assert.ExpectedError(StrSubstNo(CannotPostSameMultipleFAWhenDeprBookValueZeroErr, FixedAsset."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FASubclassCanBeBlankInFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266004] The field "FA Subclass Code" can be blank
        Initialize;

        // [GIVEN] Fixed Asset with assgned FA Subclass
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);

        // [WHEN] Validate "FA Subclass Code" with blank value
        FixedAsset.Validate("FA Subclass Code", '');

        // [THEN] Fixed Asset has blank value in "FA Subclass Code"
        FixedAsset.TestField("FA Subclass Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroupGetWriteDownAccountUT1()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281710] Fixed Asset Posting Group GetWriteDownAccount returns Write-Down Account
        Initialize;

        // [GIVEN] A Fixed Asset Posting Group with a Write-Down Account not empty
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [THEN] GetWriteDownAccount returns Write-Down Account
        Assert.AreEqual(FAPostingGroup."Write-Down Account", FAPostingGroup.GetWriteDownAccount, 'Accounts must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroupGetWriteDownAccountUT2()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 281710] Fixed Asset Posting Group GetWriteDownAccount throws Testfield error when Write-Down Account is empty
        Initialize;

        // [GIVEN] A Fixed Asset Posting Group with a Write-Down Account empty
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup."Write-Down Account" := '';

        // [THEN] GetWriteDownAccount throws TestField error
        asserterror FAPostingGroup.GetWriteDownAccount;
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(
            'Write-Down Account must have a value in FA Posting Group: Code=%1. It cannot be zero or empty.', FAPostingGroup.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_Set()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can set "Default FA Depreciation Book" on FA Depreciation Book when no default book is set before for given Fixed Asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);

        FADepreciationBook[1].TestField("Default FA Depreciation Book");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_UnSet()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can unset "Default FA Depreciation Book" on FA Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);
        FADepreciationBook[1].Modify(true);

        FADepreciationBook[1].Validate("Default FA Depreciation Book", false);
        FADepreciationBook[1].TestField("Default FA Depreciation Book", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DefaultFADepreciationBook_Negative()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Index: Integer;
    begin
        // [FEATURE] [UT] [Depreciation Book]
        // [SCENARIO 295642] Stan can't set "Default FA Depreciation Book" on FA Depreciation Book
        // [SCENARIO 295642] when another book is already defined as default for given Fixed Asset
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        for Index := 1 to ArrayLen(FADepreciationBook) do begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook[Index], FixedAsset."No.", DepreciationBook.Code);
        end;

        FADepreciationBook[1].Validate("Default FA Depreciation Book", true);
        FADepreciationBook[1].Modify(true);

        asserterror FADepreciationBook[2].Validate("Default FA Depreciation Book", true);
        Assert.ExpectedError(OnlyOneDefaultDeprBookErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCodeOnPurchDocOpen()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Depreciation] [Purchase] [Invoice Discount]
        // [SCENARIO 312521] Purchase Order page can be opened with Fixed Asset line with blank Depreciation Book Code and "Calc Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        Initialize;

        // [GIVEN] Set "Calc Inv. and Pmt. Discount" = TRUE in "Purchases & Payables Setup"
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Fixed Asset without a Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.DeleteAll(true);

        // [GIVEN] Purchase Order "PO01" with the Fixed Asset line and non-zero amount
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", '');

        // [WHEN] Open Purchase Order page on "PO01"
        PurchaseOrder.OpenView;
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Page opens without error
        PurchaseOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDepreciationBookCodeOnPurchDocPostErr()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Depreciation] [Purchase] [Invoice Discount] [Post]
        // [SCENARIO 312521] Purchase Order with Fixed Asset line with blank Depreciation Book Code can't be posted
        Initialize;

        // [GIVEN] Fixed Asset without a Depreciation Book
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.DeleteAll(true);

        // [GIVEN] Purchase Order with the Fixed Asset line and non-zero amount
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", '');

        // [WHEN] Post Purchase Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting fails on "Depreciation Book Code" check
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(
            TestFieldThreeArgsErr,
            PurchaseLine.FieldCaption("Depreciation Book Code"), PurchaseLine.TableCaption,
            PurchaseLine.FieldCaption("Document Type"), PurchaseLine."Document Type",
            PurchaseLine.FieldCaption("Document No."), PurchaseLine."Document No.",
            PurchaseLine.FieldCaption("Line No."), PurchaseLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1RecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Declining-Balance 1");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2RecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Declining-Balance 2");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualRecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::Manual);

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UDRecIsReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"User-Defined");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Straight-Line");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB1/SL");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2SLRecIsReadyForAcquisitionWithNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB2/SL");

        // [WHEN] "No. of Depreciation Years" is set to >0
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns TRUE
        Assert.IsTrue(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"Straight-Line");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB1SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB1/SL");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DB2SLRecIsNotReadyForAcquisitionWithoutNoOfDeprYears()
    var
        FAClass: Record "FA Class";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Depreciation] [UT]
        // [SCENARIO 314851] RecIsReadyForAcquisition works correctly for chosen "Depreciation Method"
        Initialize;

        // [GIVEN] Created FA Posting Group, FA Class and FIxed Asset
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FASetup.Get;

        // [GIVEN] Created FA Depreciation Book with the chosen "Depreciation Method"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBookSetMethod(FADepreciationBook, FAPostingGroup, FADepreciationBook."Depreciation Method"::"DB2/SL");

        // [WHEN] "No. of Depreciation Years" is set to 0
        FADepreciationBook.Validate("No. of Depreciation Years", 0);
        FADepreciationBook.Modify(true);

        // [THEN] RecIsReadyForAcquisition returns FALSE
        Assert.IsFalse(FADepreciationBook.RecIsReadyForAcquisition, '');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo shipment for sales shipment line of Fixed Asset type
        Initialize;

        // [GIVEN] Create and post shipment of sales order with Fixed Asset type line
        PrepareFAForSalesDocument(FixedAsset, DepreciationBook);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // [WHEN] Undo sales shipment.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Verify Quantity after Undo Shipment
        VerifyUndoShipmentLineOnPostedShipment(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesReturnReceiptLineFixedAsset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo return receipt line
        Initialize;

        // [GIVEN] Create and post receipt of sales return order with Fixed Asset type line
        PrepareFAForSalesDocument(FixedAsset, DepreciationBook);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FixedAsset."No.", DepreciationBook.Code);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindReturnReceiptLine(ReturnReceiptLine, SalesHeader."No.");

        // [WHEN] Undo return receipt
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptLineFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo receipt for Purchase receipt line of Fixed Asset type
        Initialize;

        // [GIVEN] Create and post receipt of Purchase order with Fixed Asset type line
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook.Modify;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", DepreciationBook.Code);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // [WHEN] Undo Purchase receipt.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Verify Quantity after Undo Receipt
        VerifyUndoReceiptLine(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentLineFixedAsset()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [Undo shipment]
        // [SCENARIO 289385] Stan is able to undo return shipment line of Fixed Asset type
        Initialize;

        // [GIVEN] Create and post receipt of purchase return order with Fixed Asset type line
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        DepreciationBook."G/L Integration - Acq. Cost" := true;
        DepreciationBook.Modify;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo);
        CreatePurchLine(PurchaseLine, PurchaseHeader, FixedAsset."No.", DepreciationBook.Code);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");

        // [WHEN] Undo return shipment
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Verify Quantity after Undo shipment
        VerifyUndoShipmentLine(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADefaultEndingBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Ending Book Value" for FA Depreciation Book is defaulted by the "Default Ending Book Value" of the Depreciation Book
        Initialize;

        // [GIVEN] Created Depreciation Book with specified "Default Ending Book Value", Fixed Asset
        CreateFixedAssetSetupWDefaultEndingBookValue(DepreciationBook, LibraryRandom.RandDec(100, 2));
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // [THEN] "Ending Book Value" on FA Depreciation Book is set to be equal to "Default Ending Book Value" from Depreciation Book
        Assert.AreEqual(DepreciationBook."Default Ending Book Value", FADepreciationBook."Ending Book Value", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FANonDefaultEndingBookValue()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        EndingBookValue: Decimal;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Ending Book Value" for FA Depreciation Book is not defaulted by the "Default Ending Book Value" of the Depreciation Book
        Initialize;

        // [GIVEN] Created Depreciation Book without specified "Default Ending Book Value" (=0), Fixed Asset
        CreateFixedAssetSetupWDefaultEndingBookValue(DepreciationBook, 0);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book, assign "Ending Book Value"
        EndingBookValue := LibraryRandom.RandDec(100, 2);
        CreateFADepreciationBookWEndingBookValue(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, EndingBookValue);

        // [THEN] "Ending Book Value" on FA Depreciation Book is correct
        Assert.AreEqual(EndingBookValue, FADepreciationBook."Ending Book Value", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FADefaultFinalRoundingAmount()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Final Rounding Amount" for FA Depreciation Book is defaulted by the "Default Final Rounding Amount" of the Depreciation Book
        Initialize;

        // [GIVEN] Created Depreciation Book with specified "Default Final Rounding Amount", Fixed Asset
        CreateFixedAssetSetupWDefaultFinalRoundingAmount(DepreciationBook, LibraryRandom.RandDec(100, 2));
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // [THEN] "Final Rounding Amount" on FA Depreciation Book is set to be equal to "Default Final Rounding Amount" from Depreciation Book
        Assert.AreEqual(DepreciationBook."Default Final Rounding Amount", FADepreciationBook."Final Rounding Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FANonDefaultFinalRoundingAmount()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FinalRoundingAmount: Decimal;
    begin
        // [FEATURE] [Depreciation]
        // [SCENARIO 335456] "Final Rounding Amount" for FA Depreciation Book is not defaulted by the "Default Final Rounding Amount" of the Depreciation Book
        Initialize;

        // [GIVEN] Created Depreciation Book without specified "Default Final Rounding Amount" (=0), Fixed Asset
        CreateFixedAssetSetupWDefaultFinalRoundingAmount(DepreciationBook, 0);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [WHEN] Create FA Depreciation Book, assign "Final Rounding Amount"
        FinalRoundingAmount := LibraryRandom.RandDec(100, 2);
        CreateFADepreciationBookWFinalRoundingAmount(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FinalRoundingAmount);

        // [THEN] "Final Rounding Amount" on FA Depreciation Book is correct
        Assert.AreEqual(FinalRoundingAmount, FADepreciationBook."Final Rounding Amount", '');
    end;

    local procedure Initialize()
    var
        DimValue: Record "Dimension Value";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets");
        // Use global variables for Test Request Page Handler.
        NoOfYears := 0;
        Clear(DepreciationBookCode2);
        Clear(FixedAssetNo2);
        Clear(GenJournalTemplateName);
        Clear(GenJournalBatchName);
        Clear(FAJournalTemplateName);
        Clear(FAJournalBatchName);
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets");

        // Trigger update of global dimension setup in general ledger
        LibraryDimension.GetGlobalDimCodeValue(1, DimValue);
        LibraryDimension.GetGlobalDimCodeValue(2, DimValue);

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateFAJnlTemplateName; // Bug #328391
        LibraryERMCountryData.UpdateFAPostingGroup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdateLocalData;
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets");
    end;

    [Normal]
    local procedure FADepreciationBookSetMethod(var FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group"; FAPostingMethod: Option)
    begin
        FADepreciationBook.Validate("Depreciation Method", FAPostingMethod);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate);
        FADepreciationBook.Modify(true);
    end;

    local procedure SellFixedAsset(var SalesHeader: Record "Sales Header"; DocumentType: Option; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, FANo, DepreciationBookCode);
    end;

    local procedure CreateAppreciationAccount(PurchHeader: Record "Purchase Header"; FAPostingGroupCode: Code[20]; var GLAccount: Record "G/L Account")
    var
        FAPostingGroup: Record "FA Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, PurchHeader."Gen. Bus. Posting Group", GenProductPostingGroup.Code);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup);
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GLAccount.Modify;

        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup."Appreciation Account" := GLAccount."No.";
        FAPostingGroup.Modify;
    end;

    local procedure CreateAndPostFAJournalLine(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]) DocumentNo: Code[20]
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAssetNo, DepreciationBookCode,
          LibraryRandom.RandDecInRange(10000, 20000, 2));  // Use random value for Amount.
        DocumentNo := FAJournalLine."Document No.";
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateDepreciationTable(var DepreciationTableHeader: Record "Depreciation Table Header")
    begin
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        DepreciationTableHeader.Validate("Period Length", DepreciationTableHeader."Period Length"::Year);
        DepreciationTableHeader.Modify(true);
    end;

    local procedure CreateDeprBookPartOfDuplicationList(var DepreciationBook: Record "Depreciation Book")
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("Part of Duplication List", true);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate);

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFixedAssetSetup(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
        UpdateFAPostingTypeSetup(DepreciationBook.Code);
    end;

    local procedure CreateFixedAssetSetupWDefaultEndingBookValue(var DepreciationBook: Record "Depreciation Book"; DefaultValue: Decimal)
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("Default Ending Book Value", DefaultValue);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFixedAssetSetupWDefaultFinalRoundingAmount(var DepreciationBook: Record "Depreciation Book"; DefaultValue: Decimal)
    begin
        CreateFixedAssetSetup(DepreciationBook);
        DepreciationBook.Validate("Default Final Rounding Amount", DefaultValue);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookWEndingBookValue(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; Value: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Ending Book Value", Value);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFADepreciationBookWFinalRoundingAmount(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; Value: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Final Rounding Amount", Value);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAAndDuplListSetup(var FANo: Code[20]; var DeprBookCode: Code[10]; var DuplListDeprBookCode: Code[10]; AcqCostGLIntegration: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DuplListDeprBook: Record "Depreciation Book";
    begin
        CreateFixedAssetWithSetup(FixedAsset, DeprBook);
        CreateDeprBookPartOfDuplicationList(DuplListDeprBook);
        CreateFADepreciationBook(FixedAsset."No.", DuplListDeprBook.Code, FixedAsset."FA Posting Group");
        SetupAcqCostGLIntegration(DeprBook, AcqCostGLIntegration);
        SetupAcqCostGLIntegration(DuplListDeprBook, AcqCostGLIntegration);
        FANo := FixedAsset."No.";
        DeprBookCode := DeprBook.Code;
        DuplListDeprBookCode := DuplListDeprBook.Code;
    end;

    local procedure CreateInactiveFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate(Inactive, true);
        FixedAsset.Modify(true);
    end;

    local procedure CreateMultipleFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        // Using Random Number Generator for Amount.
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          FANo, DepreciationBookCode, LibraryRandom.RandIntInRange(1000, 2000));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Write-Down",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Custom 1",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Custom 2",
          FANo, DepreciationBookCode, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FAPostingType: Option; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FAJournalLine."Journal Batch Name" + Format(FAJournalLine."Line No."));
        FAJournalLine.Validate("Posting Date", WorkDate);
        FAJournalLine.Validate("FA Posting Date", WorkDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        // Using Random Number Generator for Amount and Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Depreciation Book Code", DepreciationBookCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
        // Using Random Number Generator for Amount and Quantity.
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchLine.Validate("Use Duplication List", true);
        PurchLine.Modify(true);
    end;

    local procedure CreateFixedAssetWithSetup(var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book")
    begin
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);
    end;

    local procedure CreateFAWithBookGrossAndNetDisposal(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Modify(true);
        UpdateIntegrationInBook(DepreciationBook, true, true, true);
        UpdateFAPostingTypeSetup(DepreciationBook.Code);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate);
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(5));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateAndPostAcqCostAndWriteDownFAJnlLines(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);

        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          DeprBookCode, LibraryRandom.RandDec(1000, 2));
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Write-Down", FANo,
          DeprBookCode, -LibraryRandom.RandDec(100, 2));

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAJnlLineWithDimensionsAndUseDuplicationList(var FAJnlLine: Record "FA Journal Line"; var ShortcutDimValueCode: array[2] of Code[20]; FANo: Code[20]; DeprBookCode: Code[10])
    var
        FAJnlBatch: Record "FA Journal Batch";
        DimValue: Record "Dimension Value";
    begin
        CreateFAJournalBatch(FAJnlBatch);
        CreateFAJournalLine(
          FAJnlLine, FAJnlBatch, FAJnlLine."FA Posting Type"::"Acquisition Cost", FANo, DeprBookCode, LibraryRandom.RandInt(100));
        with FAJnlLine do begin
            Validate("Use Duplication List", true);
            LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
            Validate("Shortcut Dimension 1 Code", DimValue.Code);
            LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
            Validate("Shortcut Dimension 2 Code", DimValue.Code);
            Modify(true);
            ShortcutDimValueCode[1] := "Shortcut Dimension 1 Code";
            ShortcutDimValueCode[2] := "Shortcut Dimension 2 Code";
        end;
    end;

    local procedure CreateGenJnlLineWithDimensionsAndUseDuplicationList(var GenJnlLine: Record "Gen. Journal Line"; var ShortcutDimValueCode: array[2] of Code[20]; FANo: Code[20]; DeprBookCode: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        DimValue: Record "Dimension Value";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        with GenJnlLine do begin
            LibraryERM.CreateGeneralJnlLineWithBalAcc(
              GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, "Document Type"::" ",
              "Account Type"::"Fixed Asset", FANo, "Bal. Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNo, LibraryRandom.RandInt(100));
            Validate("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
            Validate("Depreciation Book Code", DeprBookCode);
            Validate("Use Duplication List", true);
            LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
            Validate("Shortcut Dimension 1 Code", DimValue.Code);
            LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(2));
            Validate("Shortcut Dimension 2 Code", DimValue.Code);
            Modify(true);
            ShortcutDimValueCode[1] := "Shortcut Dimension 1 Code";
            ShortcutDimValueCode[2] := "Shortcut Dimension 2 Code";
        end;
    end;

    local procedure CreatePostFixedAssetSalesInvoice(PostingDate: Date; FANo: Code[20]; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, 1);
        SalesLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        SalesLine.Validate("Depr. until FA Posting Date", true);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchInvoiceWithTwoFixedAsset(var PurchaseHeader: Record "Purchase Header"; var FixedAsset: Record "Fixed Asset"; DeprUntilPostingDate1: Boolean; DeprUntilPostingDate2: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateFixedAssetSetup(DepreciationBook);
        CreateFixedAssetWithSetup(FixedAsset, DepreciationBook);
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Depr. until FA Posting Date", DeprUntilPostingDate1);
        PurchaseLine.Modify(true);

        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Depr. until FA Posting Date", DeprUntilPostingDate2);
        PurchaseLine.Modify(true);
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst;
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; OrderNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", OrderNo);
        ReturnReceiptLine.FindFirst;
    end;

    local procedure FindPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst;
    end;

    local procedure FindPurchReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentLine.FindFirst;
    end;

    local procedure GenerateFixedAssetNo(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("No."), DATABASE::"Fixed Asset"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Fixed Asset", FixedAsset.FieldNo("No."))));
    end;

    local procedure GetFALedgerEntryAmount(DocumentNo: Code[20]; FANo: Code[20]): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst;
        exit(FALedgerEntry.Amount);
    end;

    local procedure GetVATEntryAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        if VATEntry.Amount <> 0 then
            exit(VATEntry.Amount);
        exit(VATEntry."Unrealized Amount");
    end;

    local procedure GetFASalesAccOnDispLoss(FANo: Code[20]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.Get(FANo);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        exit(FAPostingGroup."Sales Acc. on Disp. (Loss)");
    end;

    local procedure GetFADeprBookCode(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        with FADepreciationBook do begin
            SetRange("FA No.", FANo);
            FindFirst;
            exit("Depreciation Book Code");
        end;
    end;

    local procedure ModifyIntegrationInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);
    end;

    local procedure FindSalesInvoiceGLEntryWithVATAmount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; VATAmount: Decimal)
    begin
        with GLEntry do begin
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("Document No.", DocumentNo);
            SetRange("Gen. Posting Type", "Gen. Posting Type"::Sale);
            SetRange("VAT Amount", VATAmount);
            FindFirst;
        end;
    end;

    local procedure FindSalesInvoiceVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        with VATEntry do begin
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("Document No.", DocumentNo);
            SetRange(Type, Type::Sale);
            FindFirst;
        end;
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Option; DocumentNo: Code[20]; GenPostingType: Option; GLAccountNo: Code[20])
    begin
        with GLEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            SetRange("Gen. Posting Type", GenPostingType);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst;
        end;
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Option; DocumentNo: Code[20]; FilterType: Option)
    begin
        with VATEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            SetRange(Type, FilterType);
            FindFirst;
        end;
    end;

    local procedure OpenFAJnlSetupFromDepBook(DepreciationBookCode: Code[10])
    var
        DepreciationBookCard: TestPage "Depreciation Book Card";
    begin
        DepreciationBookCard.OpenView;
        DepreciationBookCard.FILTER.SetFilter(Code, DepreciationBookCode);
        DepreciationBookCard."FA &Journal Setup".Invoke;
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst;

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PrepareFAForSalesDocument(var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFixedAssetSetup(DepreciationBook);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateIntegrationInBook(DepreciationBook, false, false, false);

        CreateMultipleFAJournalLine(FAJournalLine, FixedAsset."No.", DepreciationBook.Code);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciation(FixedAsset."No.", DepreciationBook.Code);
        PostDepreciationWithDocumentNo(DepreciationBook.Code);
        ModifyIntegrationInBook(DepreciationBook);
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, CalcDate('<1D>', WorkDate), false, 0, CalcDate('<1D>', WorkDate), FixedAssetNo, FixedAsset.Description, false);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run;
    end;

    local procedure RunCopyFixedAsset(FANo: Code[20]; CopyFromFANo: Code[20]; NoOfFixedAssetCopied: Integer; FirstFANo: Code[20]; UseFANoSeries: Boolean)
    var
        CopyFixedAsset: Report "Copy Fixed Asset";
    begin
        Clear(CopyFixedAsset);
        CopyFixedAsset.SetFANo(FANo);
        CopyFixedAsset.InitializeRequest(CopyFromFANo, NoOfFixedAssetCopied, FirstFANo, UseFANoSeries);
        CopyFixedAsset.UseRequestPage(false);
        CopyFixedAsset.Run;
    end;

    local procedure RunCreateFADepreciationBooks(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; FixedAssetNo: Code[20])
    var
        CreateFADepreciationBooks: Report "Create FA Depreciation Books";
    begin
        DepreciationBookCode2 := DepreciationBookCode;
        FixedAssetNo2 := FixedAssetNo;
        Clear(CreateFADepreciationBooks);
        CreateFADepreciationBooks.SetTableView(FixedAsset);
        Commit;
        CreateFADepreciationBooks.Run;
    end;

    local procedure SetupPartialIntegrationInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Validate("G/L Integration - Disposal", false);
        DepreciationBook.Modify(true);
    end;

    local procedure SetDeprTypeFAPostingTypeSetupWriteDown(DeprBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Depreciation Type", true);
        FAPostingTypeSetup.Modify(true);
    end;

    local procedure SetupAcqCostGLIntegration(var DeprBook: Record "Depreciation Book"; AcqCostGLIntegration: Boolean)
    begin
        DeprBook.Validate("G/L Integration - Acq. Cost", AcqCostGLIntegration);
        DeprBook.Modify(true);
    end;

    local procedure ResetDeprTypeFAPostingTypeSetupWriteDown(DeprBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Depreciation Type", false);
        FAPostingTypeSetup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(var DepreciationBook: Record "Depreciation Book"; Depreciation: Boolean; Disposal: Boolean; VATOnNetDisposalEntries: Boolean)
    begin
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", Depreciation);
        DepreciationBook.Validate("G/L Integration - Write-Down", false);
        DepreciationBook.Validate("G/L Integration - Appreciation", false);
        DepreciationBook.Validate("G/L Integration - Disposal", Disposal);
        DepreciationBook.Validate("G/L Integration - Custom 1", false);
        DepreciationBook.Validate("G/L Integration - Custom 2", false);
        DepreciationBook.Validate("G/L Integration - Maintenance", false);
        DepreciationBook.Validate("VAT on Net Disposal Entries", VATOnNetDisposalEntries);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateAllowCorrectionInBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Allow Correction of Disposal", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook);
        FAJournalSetup2.FindFirst;
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateDeprBookVATNetDisposal(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("VAT on Net Disposal Entries", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateFAPostingTypeSetup(DepreciationBookCode: Code[10])
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.SetRange("Depreciation Book Code", DepreciationBookCode);
        FAPostingTypeSetup.ModifyAll("Include in Gain/Loss Calc.", true);
    end;

    local procedure VerifyAcquisitionFALedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst;
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgerEntry(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst;
        FALedgerEntry.TestField("Depreciation Book Code", DepreciationBookCode)
    end;

    local procedure VerifySalesFALedgerEntry(DocumentNo: Code[20]; FANo: Code[20]; FAPostingType: Option)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Document Type", FALedgerEntry."Document Type"::Invoice);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.FindFirst;
        FALedgerEntry.TestField("FA No.", FANo);
    end;

    local procedure VerifyDepreciationFALedger(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst;
        FALedgerEntry.TestField("Depreciation Book Code", DepreciationBookCode)
    end;

    local procedure VerifyAmountInFALedgerEntry(FANo: Code[20]; FALedgerEntryFAPostingType: Option; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntryFAPostingType);
        FALedgerEntry.FindFirst;
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFADepreciationBook(FANo: Code[20]; DocumentNo: Code[20]; DepreciationBookCode: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        Amount: Decimal;
    begin
        Amount := GetFALedgerEntryAmount(DocumentNo, FANo);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.SetRange("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.FindFirst;
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook.CalcFields("Acquisition Cost");
        FADepreciationBook.TestField("Book Value", Amount);
        FADepreciationBook.TestField("Acquisition Cost", Amount);
    end;

    local procedure VerifyMaintenanceLedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst;
        MaintenanceLedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgEntryDeprDays(FANo: Code[20]; DeprBookCode: Code[10]; ExpectedDeprDays: Integer)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        with FALedgEntry do begin
            SetRange("FA No.", FANo);
            SetRange("Depreciation Book Code", DeprBookCode);
            SetRange("FA Posting Type", "FA Posting Type"::Depreciation);
            FindFirst;
            Assert.AreEqual(ExpectedDeprDays, "No. of Depreciation Days", WrongDeprDaysErr);
        end;
    end;

    local procedure VerifyFAJnlLineDimUseDuplicationList(DuplicatedDeprBookCode: Code[10]; ShortcutDimValueCode: array[2] of Code[20])
    var
        DuplicatedFAJnlLine: Record "FA Journal Line";
    begin
        DuplicatedFAJnlLine.SetRange("Depreciation Book Code", DuplicatedDeprBookCode);
        DuplicatedFAJnlLine.FindFirst;
        Assert.AreEqual(
          ShortcutDimValueCode[1], DuplicatedFAJnlLine."Shortcut Dimension 1 Code",
          DuplicatedFAJnlLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(
          ShortcutDimValueCode[2], DuplicatedFAJnlLine."Shortcut Dimension 2 Code",
          DuplicatedFAJnlLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure VerifyGenJnlLineDimUseDuplicationList(DuplicatedDeprBookCode: Code[10]; ShortcutDimValueCode: array[2] of Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Depreciation Book Code", DuplicatedDeprBookCode);
        GenJnlLine.FindFirst;
        Assert.AreEqual(
          ShortcutDimValueCode[1], GenJnlLine."Shortcut Dimension 1 Code",
          GenJnlLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(
          ShortcutDimValueCode[2], GenJnlLine."Shortcut Dimension 2 Code",
          GenJnlLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure VerifyUndoShipmentLineOnPostedShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetRange(Type, SalesLine.Type);
        SalesShipmentLine.SetRange("No.", SalesLine."No.");
        SalesShipmentLine.FindLast;
        SalesShipmentLine.TestField(Quantity, -1 * SalesLine."Qty. to Ship");
    end;

    local procedure VerifyUndoReceiptLineOnPostedReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetRange(Type, SalesLine.Type);
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindLast;
        ReturnReceiptLine.TestField(Quantity, -1 * SalesLine."Return Qty. to Receive");
    end;

    local procedure VerifyUndoReceiptLine(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange(Type, PurchaseLine.Type);
        PurchRcptLine.SetRange("No.", PurchaseLine."No.");
        PurchRcptLine.FindLast;
        PurchRcptLine.TestField(Quantity, -1 * PurchaseLine."Qty. to Receive");
    end;

    local procedure VerifyUndoShipmentLine(PurchaseLine: Record "Purchase Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseLine."Document No.");
        ReturnShipmentLine.SetRange(Type, PurchaseLine.Type);
        ReturnShipmentLine.SetRange("No.", PurchaseLine."No.");
        ReturnShipmentLine.FindLast;
        ReturnShipmentLine.TestField(Quantity, -1 * PurchaseLine."Return Qty. to Ship");
    end;

    local procedure FASetupClassesAndSubclasses(var FAClass1: Record "FA Class"; var FASubclass1: Record "FA Subclass"; var FAClass2: Record "FA Class"; var FASubclass2: Record "FA Subclass"; var FASubclass: Record "FA Subclass")
    begin
        FAClass1.DeleteAll;
        FASubclass1.DeleteAll;
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        LibraryFixedAsset.CreateFAClass(FAClass1);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass1, FAClass1.Code, '');
        LibraryFixedAsset.CreateFAClass(FAClass2);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass2, FAClass2.Code, '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FADepreciationBooksHandler(var CreateFADepreciationBooks: TestRequestPage "Create FA Depreciation Books")
    begin
        CreateFADepreciationBooks.DepreciationBook.SetValue(DepreciationBookCode2);
        CreateFADepreciationBooks.CopyFromFANo.SetValue(FixedAssetNo2);
        CreateFADepreciationBooks.OK.Invoke;
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy Messages.
        if Confirm(StrSubstNo(DateConfirmMessage, CalcDate('<1D>', WorkDate), WorkDate)) then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var CreateSumOfDigitsTable: TestRequestPage "Create Sum of Digits Table")
    begin
        CreateSumOfDigitsTable.NoOfYears.SetValue(NoOfYears); // Value is important here, No. of Years can not be greater then 200.
        CreateSumOfDigitsTable.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAJournalSetupGenBatchHandler(var FAJournalSetup: TestPage "FA Journal Setup")
    begin
        FAJournalSetup."Gen. Jnl. Template Name".SetValue(GenJournalTemplateName);
        FAJournalSetup."Gen. Jnl. Batch Name".SetValue(GenJournalBatchName);
        FAJournalSetup."Gen. Jnl. Batch Name".Lookup;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FAJournalSetupFABatchHandler(var FAJournalSetup: TestPage "FA Journal Setup")
    begin
        // Set values on FA Journal Setup page and invoke Lookup on it to open FA Journal Batches page.
        FAJournalSetup."FA Jnl. Template Name".SetValue(FAJournalTemplateName);
        FAJournalSetup."FA Jnl. Batch Name".SetValue(FAJournalBatchName);
        FAJournalSetup."FA Jnl. Batch Name".Lookup;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalBatchesHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.Name.AssertEquals(GenJournalBatchName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAJournalBatchesHandler(var FAJournalBatches: TestPage "FA Journal Batches")
    begin
        FAJournalBatches.Name.AssertEquals(FAJournalBatchName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then begin
            Assert.ExpectedMessage(CompletionStatsFAJnlQst, Question);
            Reply := false;
        end else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CompletionStatsMsg, Message);
    end;
}

