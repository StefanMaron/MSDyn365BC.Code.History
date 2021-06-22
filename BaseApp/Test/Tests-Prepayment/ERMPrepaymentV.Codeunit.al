codeunit 134106 "ERM Prepayment V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';
        IncorrectPrepmtAmountInvLCYErr: Label 'Incorrect Prepmt. Amount Inv. (LCY) value.';
        IncorrectGLEntryExistsErr: Label 'Incorrect G/L Entry exists.';
        CountDimSetEntriesErr: Label 'Count of Dimension Set Entries is wrong.';
        IncorrectVATEntryAmountErr: Label 'Incorrect VAT Entry Amount.';

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsWithoutCompressPrepmt()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Purchase Order Statistics Page after Create Purchase Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdatePurchasePrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");

        // Exercise: Open Purchase Order Statistics Page.
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(PurchaseOrderStatisticsHandler).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchCrMemoWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PurchasePrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on G/L Entry after Posting Purchase Prepayment Invoice with Prepayment 100% and  Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchasePrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Purchase Prepayment Invoice.
        UpdatePurchasePrepmtAccount(
          PurchasePrepaymentsAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");

        // Exercise: Post Prepayment Credit Memo.
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // Verify:
        VerifyGLEntry(-PurchaseLine."Prepmt. Line Amount", DocumentNo, PurchasePrepaymentsAccount);

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          GeneralPostingSetup."Purch. Prepayments Account", PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoStatisticsWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PurchasePrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on Posted Purchase Credit Memo Statistics page using Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Purchase Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchasePrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Purchase Prepayment Invoice.
        UpdatePurchasePrepmtAccount(
          PurchasePrepaymentsAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);

        // Enqueue VAT Amount and Amount Including VAT.
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");

        // Exercise: Open Posted Purchase Credit Memo Statistics Page.
        OpenPstdPurchCrMemorStatistics(DocumentNo);

        // Verify:  and Verify VAT Amount field through Page Handler 'PurchaseCreditMemoStatisticsPageHandler'.

        // Tear Down.
        UpdatePurchasePrepmtAccount(
          GeneralPostingSetup."Purch. Prepayments Account", PurchaseLine."Gen. Bus. Posting Group",
          PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsWithoutCompressPrepmt()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check VAT Amount on Sales Order Statistics Page after Create Sales Order with Prepayment 100% and  Compress Prepayment as FALSE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, false);

        // Update Prepayment Account and Enqueue VAT Amount and Amount Including VAT.
        UpdateSalesPrepmtAccount(
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), SalesLine."Gen. Bus. Posting Group",
          SalesLine."Gen. Prod. Posting Group");
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");

        // Exercise: Open Sales Order Statistics Page.
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // Verify:  and Verify VAT Amount field through Page Handler(SalesOrderStatisticsPageHandler).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesCrMemoWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        SalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on G/L Entry after Posting Sales Prepayment Invoice with Prepayment 100% and  Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesPrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");

        // Update Prepayment Account and Post Prepayment Invoice.
        UpdateSalesPrepmtAccount(SalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Exercise:Post Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify:
        VerifyGLEntry(SalesLine."Prepmt. Line Amount", DocumentNo, SalesPrepaymentsAccount);

        // Tear Down.
        UpdateSalesPrepmtAccount(
          GeneralPostingSetup."Sales Prepayments Account", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoStatisticsWithCompressPrepmt()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        SalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Amount on Posted Sales Credit Memo Statistics page using Compress Prepayment as TRUE.

        // Setup: Find VAT Posting Setup, create Sales Order with Prepayment and post Prepayment Invoice and Credit Memo.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesLine, VATPostingSetup, true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesPrepaymentsAccount := CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group");
        UpdateSalesPrepmtAccount(SalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Post Prepayment Credit Memo. and Enqueue VAT Amount and Amount Including VAT.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT");

        // Exercise: Open Posted Sales Credit Memo Statistics Page.
        OpenPstdSalesCrMemorStatistics(DocumentNo);

        // Verify:  and Verify VAT Amount field through Page Handler 'SalesCreditMemoStatisticsPageHandler'.

        // Tear Down.
        UpdateSalesPrepmtAccount(
          GeneralPostingSetup."Sales Prepayments Account", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSeveralLinesPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // check "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" calculation during the partial posting
        // in case of several document lines

        // Setup: create sales order with 2 lines and post prepayment invoice
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocumentWithTwoLines(SalesHeader, SalesLine, VATPostingSetup);
        UpdateSalesPrepmtAccount(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise: post the half of quantity
        PostSalesDocumentPartially(SalesHeader);

        // Verify: "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" of the first line have to be updated
        VerifyFirstSalesLinePrepmtAmountInvLCY(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderSeveralLinesPartialPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // check "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" calculation during the partial posting
        // in case of several document lines

        // Setup: create purchase order with 2 lines and post prepayment invoice
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchDocumentWithTwoLines(PurchaseHeader, PurchaseLine, VATPostingSetup);
        UpdatePurchasePrepmtAccount(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Exercise: post the half of quantity
        PostPurchDocumentPartially(PurchaseHeader);

        // Verify: "Prepmt. Amount Inv. (LCY)" and "Prepmt. VAT Amount Inv. (LCY)" of the first line have to be updated
        VerifyFirstPurchLinePrepmtAmountInvLCY(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvRoundingOnFullDeductionWhenPostingPartialSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentsAccount: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 362757] Manually settled full prepayment deduction posted for partial sales order

        Initialize;
        // [GIVEN] Sales Order with Prepayment and Qty. to Invoice < Quantity
        SalesPrepaymentsAccount := CreatePartialSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] "Prepmt. Amount to Deduct" = Quantity * "Prepmt. Amount Inv." = X (full prepayment deduction)
        UpdateSalesPrepmtAmtToDeductWithPrepmtAmtInvoiced(SalesLine);

        // [WHEN] Post Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/Entry amount for account "Invoice Rounding Account" = 0
        VerifyGLEntryDoesNotExist(DocNo, GetInvRoundingAccFromCust(SalesHeader."Bill-to Customer No."));
        // [THEN] G/Entry amount for account "Sales Prepayments Account" = "X"
        VerifyGLEntry(SalesLine."Prepmt Amt to Deduct", DocNo, SalesPrepaymentsAccount);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInvRoundingOnFullDeductionWhenPostingPartialPurchaseOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPrepaymentsAccount: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 362757] Manually settled full prepayment deduction posted for partial purchase order

        Initialize;
        // [GIVEN] Purchase Order with Prepayment and Qty. to Invoice < Quantity
        PurchPrepaymentsAccount := CreatePartialPurchOrder(PurchHeader, PurchLine);

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] "Prepmt. Amount to Deduct" = Quantity * "Prepmt. Amount Inv." = X (full prepayment deduction)
        UpdatePurchPrepmtAmtToDeductWithPrepmtAmtInvoiced(PurchLine);
        PurchHeader."Vendor Invoice No." := IncStr(PurchHeader."Vendor Invoice No.");
        PurchHeader.Modify;

        // [WHEN] Post Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/Entry amount for account "Invoice Rounding Account" = 0
        VerifyGLEntryDoesNotExist(DocNo, GetInvRoundingAccFromVend(PurchHeader."Pay-to Vendor No."));
        // [THEN] G/Entry amount for account "Purchase Prepayments Account" = "X"
        VerifyGLEntry(-PurchLine."Prepmt Amt to Deduct", DocNo, PurchPrepaymentsAccount);

        // Tear down
        TearDownVATPostingSetup(PurchHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentPostingGroupsInPurchLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        TotalCountDimSetEntries: Integer;
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different setups of Purchase line of Posting groups if "Purch. Prepayments Account" of groups have account with default dimension value.

        Initialize;
        // [GIVEN] "G/L Account" = "A1" without default dimension
        // [GIVEN] "G/L Account" = "A2" with Default Dimension = "DD1" and Default Dimension Value = "DDV1"
        // [GIVEN] "G/L Account" = "A3" with Default Dimension = "DD2" and Default Dimension Value = "DDV2"

        // [GIVEN] Purchase order with four purchase lines with posted prepayment invoices and different setup of posting groups
        MockPurchaseHeader(PurchaseHeader);

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET1" with "Purch. Prepayments Account" = "A1"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, false);
        // [GIVEN] First line has posting groups = "SET1"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET2" with "Purch. Prepayments Account" = "A2"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Second line has posting groups = "SET2"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET3" with "Purch. Prepayments Account" = "A3"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue2, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Third line has posting groups = "SET3"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Fourth line has posting groups = "SET3"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
        // [GIVEN] Total count of Dimension set entries = "X"
        TotalCountDimSetEntries := DimensionSetEntry.Count;

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Two new Dimension Set Entries added:
        Assert.AreEqual(TotalCountDimSetEntries + 2, DimensionSetEntry.Count, CountDimSetEntriesErr);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" was created
        VerifyDimensionSetEntryIsExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" was created
        VerifyDimensionSetEntryIsExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentPostingGroupsInSalesLines()
    var
        SalesHeader: Record "Sales Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        TotalCountDimSetEntries: Integer;
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different setups of Sales line of Posting groups if "Sales Prepayments Account" of groups have account with default dimension value.

        Initialize;
        // [GIVEN] "G/L Account" = "A1" without default dimension
        // [GIVEN] "G/L Account" = "A2" with Default Dimension = "DD1" and Default Dimension Value = "DDV1"
        // [GIVEN] "G/L Account" = "A3" with Default Dimension = "DD2" and Default Dimension Value = "DDV2"

        // [GIVEN] Sales order with four sales lines with posted prepayment invoices and different setup of posting groups
        MockSalesHeader(SalesHeader);

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET1" with "Sales Prepayments Account" = "A1"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, false);
        // [GIVEN] First line has posting groups = "SET1"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET2" with "Sales Prepayments Account" = "A2"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue1, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Second line has posting groups = "SET2"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET3" with "Sales Prepayments Account" = "A3"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValue2, GenBusPostingGroupCode, GenProdPostingGroupCode, true);
        // [GIVEN] Third line has posting groups = "SET3"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Fourth line has posting groups = "SET3"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
        // [GIVEN] Total count of Dimension set entries = "X"
        TotalCountDimSetEntries := DimensionSetEntry.Count;

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Sales Header
        SalesHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Two new Dimension Set Entries added:
        Assert.AreEqual(TotalCountDimSetEntries + 2, DimensionSetEntry.Count, CountDimSetEntriesErr);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD1" and "Dimension Value Code" = "DDV1" was created
        VerifyDimensionSetEntryIsExists(DimensionValue1."Dimension Code", DimensionValue1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DD2" and "Dimension Value Code" = "DDV2" was created
        VerifyDimensionSetEntryIsExists(DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimIfPurchPrepmtAccNotSet()
    var
        GenPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Default Dimension]
        // [SCENARIO 363725] Show error when creating dimension set for prepayment invoice for Purchase line and "Purch. Prepayments Account" of posting groups not set.

        Initialize;
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" without "Purch. Prepayments Account"
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        // [GIVEN] Purchase order with purchase line with prepayment invoice
        MockPurchaseHeader(PurchaseHeader);
        // [GIVEN] Purchase line has posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDime" on Purchase Header
        asserterror PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Error: "Purch. Prepayments Account" must have a value in General Posting Setup
        Assert.ExpectedError(GenPostingSetup.FieldCaption("Purch. Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimIfSalesPrepmtAccNotSet()
    var
        GenPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Show error when creating dimension set for prepayment invoice for Sales line and "Sales Prepayments Account" of posting groups not set.

        Initialize;
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" without "Sales Prepayments Account"
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        // [GIVEN] Sales order with sales line with prepayment invoice
        MockSalesHeader(SalesHeader);
        // [GIVEN] Sales line has posting groups =  "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, '');

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Sales Header
        asserterror SalesHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Error: "Sales Prepayments Account" must have a value in General Posting Setup
        Assert.ExpectedError(GenPostingSetup.FieldCaption("Sales Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentCombinationOfParametersPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionValueAcc: Record "Dimension Value";
        DimensionValueJob1: Record "Dimension Value";
        DimensionValueJob2: Record "Dimension Value";
        JobNo1: Code[20];
        JobNo2: Code[20];
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different "Job No." of Purchase Line.

        Initialize;
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValueAcc, GenBusPostingGroupCode, GenProdPostingGroupCode, true);

        // [GIVEN] Two jobs with different default dimensions
        // [GIVEN] First job = "J1" has "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1"
        JobNo1 := MockJobWithDfltDimension(DimensionValueJob1);
        // [GIVEN] First job = "J2" has "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2"
        JobNo2 := MockJobWithDfltDimension(DimensionValueJob2);

        // [GIVEN] Purchase order with two purchase line with different "Job No."
        MockPurchaseHeader(PurchaseHeader);
        // [GIVEN] First line has "Job No." = "J1" and posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo1);
        // [GIVEN] Second line has "Job No." = "J2" and posting groups = "SET"
        MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo2);

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        PurchaseHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" was created
        VerifyDimensionSetEntryIsExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCreateDimSetForPrepmtAccDefaultDimWithDifferentCombinationOfParametersSalesLine()
    var
        SalesHeader: Record "Sales Header";
        DimensionValueAcc: Record "Dimension Value";
        DimensionValueJob1: Record "Dimension Value";
        DimensionValueJob2: Record "Dimension Value";
        JobNo1: Code[20];
        JobNo2: Code[20];
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Dimension Sets is created for different "Job No." of Sales Line.

        Initialize;
        // [GIVEN] "Gen. Bus. Posting Group" and "Gen. Prod. Posting Group" = "SET" with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc"
        MockGenBusProdPostingGroupWithPrepmtAcc(DimensionValueAcc, GenBusPostingGroupCode, GenProdPostingGroupCode, true);

        // [GIVEN] Two jobs with different default dimensions
        // [GIVEN] First job = "J1" has "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1"
        JobNo1 := MockJobWithDfltDimension(DimensionValueJob1);
        // [GIVEN] First job = "J2" has "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2"
        JobNo2 := MockJobWithDfltDimension(DimensionValueJob2);

        // [GIVEN] Sales order with two sales line with different "Job No."
        MockSalesHeader(SalesHeader);
        // [GIVEN] First line has "Job No." = "J1" and posting groups = "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo1);
        // [GIVEN] Second line has "Job No." = "J2" and posting groups = "SET"
        MockSalesLineWithPrepmtAmtInv(SalesHeader, GenBusPostingGroupCode, GenProdPostingGroupCode, JobNo2);

        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [GIVEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);

        // [WHEN] Invoke "CreateDimSetForPrepmtAccDefaultDim" on Purchase Header
        SalesHeader.CreateDimSetForPrepmtAccDefaultDim;

        // [THEN] Dimension Set Entry with "Dimension Code" = "DDAcc" and "Dimension Value Code" = "DDVAcc" was created
        VerifyDimensionSetEntryIsExists(DimensionValueAcc."Dimension Code", DimensionValueAcc.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob1" and "Dimension Value Code" = "DDVJob1" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob1."Dimension Code", DimensionValueJob1.Code);
        // [THEN] Dimension Set Entry with "Dimension Code" = "DDJob2" and "Dimension Value Code" = "DDVJob2" was created
        VerifyDimensionSetEntryIsExists(DimensionValueJob2."Dimension Code", DimensionValueJob2.Code);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForPurchPrepmtWithDfltDimInPurchPrepmtAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Sales] [Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Purchase Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.

        Initialize;
        // [GIVEN] Purchase order with prepayment
        CreatePartialPurchOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, PurchaseHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Purchase Order Statistic"
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('SalesOrdStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDfltDimSetForSalesPrepmtWithDfltDimInSalesPrepmtAcc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Sales][Default Dimension]
        // [SCENARIO 363725] Default Dimension Set is created on open "Sales Order Statistics" where prepayment account has default dimensions and order has posted prepayment invoice.

        Initialize;
        // [GIVEN] Sales order with prepayment
        CreatePartialSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Posting group with G/L Account with default dimension
        CreateDefaultDimensionAndUpdatePostingGroup(DimensionValue, SalesHeader."Gen. Bus. Posting Group");

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Default Dimension set not exists
        VerifyDimensionSetEntryIsNotExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] Open "Sales Order Statistic"
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [THEN] Default Dimension set was created
        VerifyDimensionSetEntryIsExists(DimensionValue."Dimension Code", DimensionValue.Code);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithTheSameNoAsSalesOrderWithPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO 377768] Posting of Return order with the same No. of Sales Order when Prepayment Invoice is posted for Sales Order
        Initialize;

        // [GIVEN] "Check Prepmt. when Posting" is Yes in Sales & Receivables Setup
        SetCheckPrepaymentinSalesSetup(true);

        // [GIVEN] Sales Order "X" with Posted Prepayment Invoice
        SalesHeader."No." := LibraryUtility.GenerateGUID;
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Sales Return Order with the same No. = "X"
        ReturnSalesHeader."No." := SalesHeader."No.";
        LibrarySales.CreateSalesHeader(
          ReturnSalesHeader, ReturnSalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(ReturnSalesLine, ReturnSalesHeader, SalesLine.Type, SalesLine."No.", SalesLine.Quantity);
        ReturnSalesLine.Validate("Unit Price", SalesLine."Unit Price");
        ReturnSalesLine.Modify(true);

        // [WHEN] Post Sales Return Order using SendToPosting
        ReturnSalesHeader.SendToPosting(CODEUNIT::"Sales-Post (Yes/No)");

        // [THEN] Posted Sales Credit Memo is created with "Return Order No." = "X"
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", ReturnSalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst;
        SalesCrMemoHeader.TestField("Return Order No.", ReturnSalesHeader."No.");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentCreditMemoFromCopiedSalesOrder()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 377768] Posting of Prepayment Credit Memo from sales order wich was copied from another order
        Initialize;
        LibrarySales.SetCreditWarningsToNoWarnings;

        // [GIVEN] Sales Order "X" with Posted Prepayment Invoice
        SalesHeader[1]."No." := LibraryUtility.GenerateGUID;
        CreatePrepmtSalesOrder(SalesHeader[1], SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader[1]);

        // [GIVEN] Sales Order "Y" created from order "X" by Copy Document function
        LibrarySales.CreateSalesHeader(
          SalesHeader[2], SalesHeader[2]."Document Type"::Order, SalesHeader[1]."Sell-to Customer No.");
        CopySalesOrderFromSalesOrder(SalesHeader[1]."No.", SalesHeader[2]);

        // [GIVEN] Posted Prepayment Invoice for order "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader[2]);

        // [WHEN] Prepayment Credit Memo is being posted
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader[2]);

        // [THEN] Created VAT Entry has proper value of VAT amount
        VerifySalesPrepaymentCreditMemoVATAmount(SalesHeader[2]);

        // Tear down
        TearDownVATPostingSetup(SalesHeader[1]."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentCreditMemoFromCopiedPurchOrder()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 377768] Posting of Prepayment Credit Memo from purchase order wich was copied from another order
        Initialize;

        // [GIVEN] Purchase Order "X" with Posted Prepayment Invoice
        PurchaseHeader[1]."No." := LibraryUtility.GenerateGUID;
        CreatePrepmtPurchOrder(PurchaseHeader[1]);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[1]);

        // [GIVEN] Purchase Order "Y" created from order "X" by Copy Document function
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, PurchaseHeader[1]."Sell-to Customer No.");
        CopyPurchOrderFromPurchOrder(PurchaseHeader[1]."No.", PurchaseHeader[2]);
        PurchaseHeader[2]."Vendor Invoice No." := LibraryUtility.GenerateGUID;
        PurchaseHeader[2].Modify;

        // [GIVEN] Posted Prepayment Invoice for order "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[2]);

        // [WHEN] Prepayment Credit Memo is being posted
        PurchaseHeader[2]."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID;
        PurchaseHeader[2].Modify;
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader[2]);

        // [THEN] Created VAT Entry has proper value of VAT amount
        VerifyPurchPrepaymentCreditMemoVATAmount(PurchaseHeader[2]);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader[1]."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchaseInvoiceHasVendorLedgerEntryNoValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 222891] Posted prepayment purchase invoice has "Vendor Ledger Entry No." value
        Initialize;

        // [GIVEN] Purchase order with prepayment percent
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [WHEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        FindPostedPurchaseInvoice(PurchInvHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] There is a vendor ledger entry for the posted prepayment invoice with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");
        VendorLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment purchase invoice has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Closed" = "No"
        PurchInvHeader.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchInvHeader.CalcFields("Remaining Amount", Closed);
        PurchInvHeader.TestField("Remaining Amount", -VendorLedgerEntry.Amount);
        PurchInvHeader.TestField(Closed, false);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtPurchaseCrMemoHasVendorLedgerEntryNoValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 222891] Posted prepayment purchase credit memo has "Vendor Ledger Entry No." value
        Initialize;

        // [GIVEN] Purchase order with prepayment percent
        CreatePrepmtPurchOrder(PurchaseHeader);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post prepayment credit memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        FindPostedPurchaseCrMemo(PurchCrMemoHdr, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] There is a vendor ledger entry for the posted prepayment credit memo with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");
        VendorLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment purchase credit memo has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Paid" = "No"
        PurchCrMemoHdr.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchCrMemoHdr.CalcFields("Remaining Amount", Paid);
        PurchCrMemoHdr.TestField("Remaining Amount", -VendorLedgerEntry.Amount);
        PurchCrMemoHdr.TestField(Paid, false);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesInvoiceHasVendorLedgerEntryNoValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 222891] Posted prepayment sales invoice has "Cust. Ledger Entry No." value
        Initialize;

        // [GIVEN] Sales order with prepayment percent
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [WHEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        FindPostedSalesInvoice(SalesInvoiceHeader, SalesHeader."Sell-to Customer No.");

        // [THEN] There is a customer ledger entry for the posted prepayment invoice with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");
        CustLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment sales invoice has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Closed" = "No"
        SalesInvoiceHeader.TestField("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        SalesInvoiceHeader.CalcFields("Remaining Amount", Closed);
        SalesInvoiceHeader.TestField("Remaining Amount", CustLedgerEntry.Amount);
        SalesInvoiceHeader.TestField(Closed, false);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrepmtSalesCrMemoHasVendorLedgerEntryNoValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 222891] Posted prepayment sales credit memo has "Cust. Ledger Entry No." value
        Initialize;

        // [GIVEN] Sales order with prepayment percent
        CreatePrepmtSalesOrder(SalesHeader, SalesLine);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post prepayment credit memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        FindPostedSalesCrMemo(SalesCrMemoHeader, SalesHeader."Sell-to Customer No.");

        // [THEN] There is a customer ledger entry for the posted prepayment credit memo with "Entry No." = "X", "Amount" = "A"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");
        CustLedgerEntry.CalcFields(Amount);
        // [THEN] Posted prepayment sales credit memo has "Vendor Ledger Entry No." = "X", "Remaining Amount" = "A", "Paid" = "No"
        SalesCrMemoHeader.TestField("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        SalesCrMemoHeader.CalcFields("Remaining Amount", Paid);
        SalesCrMemoHeader.TestField("Remaining Amount", CustLedgerEntry.Amount);
        SalesCrMemoHeader.TestField(Paid, false);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase]
        // [SCENARIO 261533] Posting of partial and final purchase invoice with custom prepayment, amounts, integer precision
        Initialize;
        PrepareVendorAndTwoGLAccWithSetup(VATPostingSetup, VendorNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Purchase Order with "Prepayment %" = 95, line with Quantity = 48, Unit Cost = 6706996.8
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 95, false);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, GLAccountNo[1], 48, 6706996.8);
        // [GIVEN] Modify total prepayment amount = 305900000
        UpdatePurchTotalPrepmtAmount(PurchaseHeader, 305900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 30590000);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -336490000);

        // [GIVEN] Modify Quantity to Receive = 37
        UpdatePurchQtyToReceive(PurchaseLine, 37);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 248158881
        UpdatePurchPrepmtAmtToDeduct(PurchaseLine, 248158881);

        // [GIVEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyValueNeedsToBeRounded(-17639431.1);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account",DocumentNo,1603585);
        // VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group",DocumentNo,-17639431);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales]
        // [SCENARIO 261533] Posting of partial and final sales invoice with custom prepayment, amounts, integer precision
        Initialize;
        PrepareCustomerAndTwoGLAccWithSetup(VATPostingSetup, CustomerNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Sales Order with "Prepayment %" = 95, line with Quantity = 48, Unit Cost = 6706996.8
        CreateSalesHeader(SalesHeader, CustomerNo, 95, false);
        CreateCustomSalesLine(SalesLine, SalesHeader, GLAccountNo[1], 48, 6706996.8);
        // [GIVEN] Modify total prepayment amount = 305900000
        UpdateSalesTotalPrepmtAmount(SalesHeader, 305900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, -30590000);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 336490000);

        // [GIVEN] Modify Quantity to Ship = 37
        UpdateSalesQtyToShip(SalesLine, 37);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 248158881
        UpdateSalesPrepmtAmtToDeduct(SalesLine, 248158881);

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyValueNeedsToBeRounded(17639431.1);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account",DocumentNo,-1603585);
        // VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group",DocumentNo,17639431);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTwoLinesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase]
        // [SCENARIO 261533] Posting of partial and final purchase invoice with custom prepayment, amounts, two lines, integer precision
        Initialize;
        PrepareVendorAndTwoGLAccWithSetup(VATPostingSetup, VendorNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Purchase Order with "Prepayment %" = 95 and 2 lines:
        // [GIVEN] Line1: Quantity = 10000, Unit Cost = 11432
        // [GIVEN] Line2: Quantity = 20000, Unit Cost = 11432
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 95, false);
        CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, GLAccountNo[1], 10000, 11432);
        CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, GLAccountNo[2], 20000, 11432);
        // [GIVEN] Modify total prepayment amount = 325900000
        UpdatePurchTotalPrepmtAmount(PurchaseHeader, 325900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 32590000);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, -358490000);

        // [GIVEN] Modify Quantity to Receive: Line1 = 0, Line2 = 6577
        UpdatePurchQtyToReceive(PurchaseLine[1], 0);
        UpdatePurchQtyToReceive(PurchaseLine[2], 6577);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 75188264
        UpdatePurchPrepmtAmtToDeduct(PurchaseLine[2], 75188264);

        // [GIVEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := PostPurchaseDocument(PurchaseHeader);
        VerifyValueNeedsToBeRounded(-18766001.5);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account",DocumentNo,1706000);
        // VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group",DocumentNo,-18766000);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTwoLinesCustomInvWithIntegerPrecisionAndChangedTotalPrepmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales]
        // [SCENARIO 261533] Posting of partial and final sales invoice with custom prepayment, amounts, two lines, integer precision
        Initialize;
        PrepareCustomerAndTwoGLAccWithSetup(VATPostingSetup, CustomerNo, GLAccountNo, 10);

        // [GIVEN] GLSetup "Amount Decimal Places" = "0:2", "Unit Amount Decimal Places" = "0:2", "Amount Rounding Precision" = "1", "Unit Amount Rounding Precision" = "1"
        // [GIVEN] VAT Posting Setup "VAT %" = 10
        UpdateGeneralSetup('0:2', '0:2', 1, 1);

        // [GIVEN] Sales Order with "Prepayment %" = 95 and 2 lines:
        // [GIVEN] Line1: Quantity = 10000, Unit Cost = 11432
        // [GIVEN] Line2: Quantity = 20000, Unit Cost = 11432
        CreateSalesHeader(SalesHeader, CustomerNo, 95, false);
        CreateCustomSalesLine(SalesLine[1], SalesHeader, GLAccountNo[1], 10000, 11432);
        CreateCustomSalesLine(SalesLine[2], SalesHeader, GLAccountNo[2], 20000, 11432);
        // [GIVEN] Modify total prepayment amount = 325900000
        UpdateSalesTotalPrepmtAmount(SalesHeader, 325900000);

        // [GIVEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, -32590000);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 358490000);

        // [GIVEN] Modify Quantity to Ship: Line1 = 0, Line2 = 6577
        UpdateSalesQtyToShip(SalesLine[1], 0);
        UpdateSalesQtyToShip(SalesLine[2], 6577);
        // [GIVEN] Modify prepayment amount to deduct for Line2 = 75188264
        UpdateSalesPrepmtAmtToDeduct(SalesLine[2], 75188264);

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0);

        // [WHEN] Post final invoice
        // The Company should be reopened for the new rounding to be loaded in COD1 ApplicationManagement.ReadRounding()
        // Since we can't reopen Company within test excution, system throws rounding error
        asserterror DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyValueNeedsToBeRounded(18766001.5);

        // [THEN] The invoice has been posted
        // VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account",DocumentNo,-1706000);
        // VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group",DocumentNo,18766000);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithTwoLinesCustomAmountsAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 267789] Posting of a purchase order with prepayment, two item lines with custom amounts, invoice discount amount
        Initialize;
        LibraryPurchase.SetInvoiceRounding(false);
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 19);

        // [GIVEN] Purchase Order with "VAT %" = 19, "Prepayment %" = 92 and 2 lines:
        // [GIVEN] Line1: Quantity = 1, Unit Cost = 7462.40
        // [GIVEN] Line2: Quantity = 1, Unit Cost = 2727.17
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 92, false);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], 1, 7462.4);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[2], 1, 2727.17);
        // [GIVEN] Invoice Discount Amount = 815.17
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, 815.17);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post invoice
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] The document has been poted
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
        VerifyVendorPayablesAccountAmount(PurchaseHeader."Vendor Posting Group", DocumentNo, 0);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoLinesCustomAmountsAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 267789] Posting of a sales order with prepayment, two item lines with custom amounts, invoice discount amount
        Initialize;
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "VAT %" = 19, "Prepayment %" = 92 and 2 lines:
        // [GIVEN] Line1: Quantity = 1, Unit Cost = 7462.40
        // [GIVEN] Line2: Quantity = 1, Unit Cost = 2727.17
        CreateSalesHeader(SalesHeader, CustomerNo, 92, false);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], 1, 7462.4);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[2], 1, 2727.17);
        // [GIVEN] Invoice Discount Amount = 815.17
        SetSalesInvoiceDiscountAmount(SalesHeader, 815.17);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been poted
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
        VerifyCustomerReceivablesAccountAmount(SalesHeader."Customer Posting Group", DocumentNo, 0);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT] [Prices Excl. VAT]
        // [SCENARIO 267789] PurchaseLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount" in case of Prices Excluding VAT
        Initialize;

        // [GIVEN] Purchase Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, false, 50, 1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = 600
        PurchaseLine."Inv. Discount Amount" := 600;
        PurchaseLine.Modify;

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 400
        PurchaseLine.TestField(Amount, 400);
        PurchaseLine.TestField("Prepmt. Line Amount", 400);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLinesPricesInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT] [Prices Incl. VAT]
        // [SCENARIO 267789] PurchaseLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount Including VAT" in case of Prices Including VAT
        Initialize;

        // [GIVEN] Purchase Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, true, 50, 1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = 600
        PurchaseLine."Inv. Discount Amount" := 600;
        PurchaseLine.Modify;

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 400
        PurchaseLine.TestField("Amount Including VAT", 400);
        PurchaseLine.TestField("Prepmt. Line Amount", 400);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtLineAmountAfterUpdateVATOnLinesNegativeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 267789] PurchaseLine."Prepmt. Line Amount" remains zero after UpdateVATOnLines() with negative Amount
        Initialize;

        // [GIVEN] Purchase Line with "Line Amount" = -1000, "Prepmt. Line Amount" = 0, "Inv. Discount Amount" = 0
        CreatePurchLineAndCalcVATAmountLine(PurchaseHeader, PurchaseLine, VATAmountLine, false, 0, -1000);

        // [GIVEN] Update Purchase Line's "Inv. Discount Amount" = -600
        PurchaseLine."Inv. Discount Amount" := -600;
        PurchaseLine.Modify;

        // [WHEN] Call PurchaseLine.UpdateVATOnLines()
        PurchaseLine.UpdateVATOnLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] PurchaseLine."Prepmt. Line Amount" = 0
        PurchaseLine.TestField(Amount, -400);
        PurchaseLine.TestField("Prepmt. Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT] [Prices Excl. VAT]
        // [SCENARIO 267789] SalesLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount" in case of Prices Excluding VAT
        Initialize;

        // [GIVEN] Sales Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, false, 50, 1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = 600
        SalesLine."Inv. Discount Amount" := 600;
        SalesLine.Modify;

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 400
        SalesLine.TestField(Amount, 400);
        SalesLine.TestField("Prepmt. Line Amount", 400);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLinesPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT] [Prices Incl. VAT]
        // [SCENARIO 267789] SalesLine.UpdateVATOnLines() updates "Prepmt. Line Amount" to be <= "Amount Including VAT" in case of Prices Including VAT
        Initialize;

        // [GIVEN] Sales Line with "Line Amount" = 1000, "Prepmt. Line Amount" = 500, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, true, 50, 1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = 600
        SalesLine."Inv. Discount Amount" := 600;
        SalesLine.Modify;

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 400
        SalesLine.TestField("Amount Including VAT", 400);
        SalesLine.TestField("Prepmt. Line Amount", 400);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtLineAmountAfterUpdateVATOnLinesNegativeAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 267789] SalesLine."Prepmt. Line Amount" remains zero after UpdateVATOnLines() with negative Amount
        Initialize;

        // [GIVEN] Sales Line with "Line Amount" = -1000, "Prepmt. Line Amount" = 0, "Inv. Discount Amount" = 0
        CreateCustomSalesLineAndCalcVATAmountLine(SalesHeader, SalesLine, VATAmountLine, false, 0, -1000);

        // [GIVEN] Update Sales Line's "Inv. Discount Amount" = -600
        SalesLine."Inv. Discount Amount" := -600;
        SalesLine.Modify;

        // [WHEN] Call SalesLine.UpdateVATOnLines()
        SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, VATAmountLine);

        // [THEN] SalesLine."Prepmt. Line Amount" = 0
        SalesLine.TestField(Amount, -400);
        SalesLine.TestField("Prepmt. Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalSalesInvoiceWithOneHundredPrepmtAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 273512] Stan can post sales invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %"

        Initialize;
        LibrarySales.SetInvoiceRounding(false);
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 19);

        // [GIVEN] Sales Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreateSalesHeader(SalesHeader, CustomerNo, 100, false);
        CreateCustomItemSalesLine(
          SalesLine, SalesHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetSalesInvoiceDiscountAmount(SalesHeader, SalesLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Find;

        // [GIVEN] Posted prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Multiple G/L Entries posted with "G/L Account" = "Sales VAT Account" and total amount equal 0
        VerifyGLEntriesAmount(0, DocumentNo, VATPostingSetup."Sales VAT Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Inv. Discount Account" and Amount = 500
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesLine."Inv. Discount Amount", DocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Prepayment Account" and Amount = 3500
        VerifyGLEntry(SalesLine."Prepmt. Line Amount", DocumentNo, GeneralPostingSetup."Sales Prepayments Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Sales Account" and Amount = -4000
        VerifyGLEntry(-SalesLine."Line Amount", DocumentNo, GeneralPostingSetup."Sales Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Receivables Account" and Amount = 0
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyGLEntry(0, DocumentNo, CustomerPostingGroup."Receivables Account");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalPurchInvoiceWithOneHundredPrepmtAndInvDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 273512] Stan can post purchase invoice with "Prepayment %" = 100 and non-zero "Invoice Discount %"

        Initialize;
        LibraryPurchase.SetInvoiceRounding(false);
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 19);

        // [GIVEN] Purchase Order with "Line Amount" = 4000, "Invoice Discount Amount" = 500, "Prepayment %" = 100
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 100, false);
        CreateCustomItemPurchaseLine(
          PurchaseLine, PurchaseHeader, ItemNo[1], LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, PurchaseLine.Amount / LibraryRandom.RandIntInRange(3, 10));
        PurchaseLine.Find;

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Find;
        PurchaseHeader."Vendor Invoice No." := IncStr(PurchaseHeader."Vendor Invoice No.");
        PurchaseHeader.Modify;

        // [WHEN] Post final invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Multiple G/L Entries posted with "G/L Account" = "Purchase VAT Account" and total amount equal 0
        VerifyGLEntriesAmount(0, DocumentNo, VATPostingSetup."Purchase VAT Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Inv. Discount Account" and Amount = -500
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(-PurchaseLine."Inv. Discount Amount", DocumentNo, GeneralPostingSetup."Purch. Inv. Disc. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Prepayment Account" and Amount = -3500
        VerifyGLEntry(-PurchaseLine."Prepmt. Line Amount", DocumentNo, GeneralPostingSetup."Purch. Prepayments Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Purch. Account" and Amount = 4000
        VerifyGLEntry(PurchaseLine."Line Amount", DocumentNo, GeneralPostingSetup."Purch. Account");

        // [THEN] G/L Entry posted with "G/L Account" = "Payables Account" and Amount = 0
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(0, DocumentNo, VendorPostingGroup."Payables Account");

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceAfterGetReceiptLinesWithPrepayments()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 278361] Purchase Invoice posting created with GetReceiptLines from posted receipts linked with prepayment Purchase Order
        Initialize;

        // [GIVEN] VAT Posting Setup with VAT % = 24
        PrepareVendorAndTwoItemsWithSetup(VATPostingSetup, VendorNo, ItemNo, 24);

        // [GIVEN] Purchase Order with 30% prepayment, Item with Quantity = 620 and Unit Cost = 26,67
        CreatePurchaseHeader(PurchaseHeader, VendorNo, 30, false);
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, ItemNo[1], 620, 27.67);

        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Posted Receipt with "Qty. to Receive" = 585
        UpdatePurchQtyToReceive(PurchaseLine, 585);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Posted Receipt with "Qty. to Receive" = 30
        PurchaseLine.Find;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] A new Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Populate lines using GetReceiptLines, select both receipts
        GetPurchaseReceiptLines(PurchaseHeader);

        // [WHEN] Post the invoice
        // [THEN] The invoice has been posted
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterGetShipmentLinesWithPrepayments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 278361] Sales Invoice posting created with GetShipmentLines from posted shipments linked with prepayment Sales Order
        Initialize;

        // [GIVEN] VAT Posting Setup with VAT % = 24
        PrepareCustomerAndTwoItemsWithSetup(VATPostingSetup, CustomerNo, ItemNo, 24);

        // [GIVEN] Sales Order with 30% prepayment, Item with Quantity = 620 and Unit Cost = 26,67
        CreateSalesHeader(SalesHeader, CustomerNo, 30, false);
        CreateCustomItemSalesLine(SalesLine, SalesHeader, ItemNo[1], 620, 27.67);

        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Posted Shipment with "Qty. to Receive" = 585
        UpdateSalesQtyToShip(SalesLine, 585);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Posted Shipment with "Qty. to Receive" = 30
        SalesLine.Find;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] A new Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Populate lines using GetShipmentLines, select both shipments
        GetSalesShipmentLines(SalesHeader);

        // [WHEN] Post the invoice
        // [THEN] The invoice has been posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingPrepaymentPctAfterInvoiceDiscountSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Sales Order takes Invoice Discount into account when validated second
        Initialize;

        // [GIVEN] Sales Order with one Sales Line
        CreateSalesOrderWithOneLine(SalesHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        SetSalesInvoiceDiscountAmount(SalesHeader, LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);

        // [THEN] Sales Line's "Prepmt. Line Amount" = "Amount"
        VerifySalesLineFullPrepaymentWithDiscount(SalesHeader."No.", SalesLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingInvoiceDiscountAfterPrepaymentPctSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Sales Order takes Invoice Discount into account when validated first
        Initialize;

        // [GIVEN] Sales Order with one Sales Line
        CreateSalesOrderWithOneLine(SalesHeader);

        // [WHEN] Setting 100% Prepayment and then Invoice Discount Amount
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        SetSalesInvoiceDiscountAmount(SalesHeader, LibraryRandom.RandDec(10, 2));

        // [THEN] Sales Line's "Prepmt. Line Amount" = "Amount"
        VerifySalesLineFullPrepaymentWithDiscount(SalesHeader."No.", SalesLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingPrepaymentPctAfterInvoiceDiscountPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Purchase Order takes Invoice Discount into account when validated second
        Initialize;

        // [GIVEN] Purchase Order with one Purchase Line
        CreatePurchaseOrderWithOneLine(PurchaseHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);

        // [THEN] Purchase Line's "Prepmt. Line Amount" = "Amount"
        VerifyPurchaseLineFullPrepaymentWithDiscount(PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingInvoiceDiscountAfterPrepaymentPctPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [Prepayment]
        // [SCENARIO 291647] Prepayment Amount on Purchase Order takes Invoice Discount into account when validated first
        Initialize;

        // [GIVEN] Purchase Order with one Purchase Line
        CreatePurchaseOrderWithOneLine(PurchaseHeader);

        // [WHEN] Setting "Invoice Discount Amount" and then 100% Prepayment
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        SetPurchaseInvoiceDiscountAmount(PurchaseHeader, LibraryRandom.RandDec(10, 2));

        // [THEN] Purchase Line's "Prepmt. Line Amount" = "Amount"
        VerifyPurchaseLineFullPrepaymentWithDiscount(PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment V");
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment V");

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdatePrepaymentAccounts;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment V");
    end;

    local procedure PrepareVendorAndTwoGLAccWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var GLAccountNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup);
        UpdateVendorRoundingAccount(VendorNo, CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup));
        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareCustomerAndTwoGLAccWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var GLAccountNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup);

        UpdateCustomerRoundingAccount(CustomerNo, CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup));
        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareVendorAndTwoItemsWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var ItemNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdatePurchasePrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PrepareCustomerAndTwoItemsWithSetup(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var ItemNo: array[2] of Code[20]; VATRate: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, VATRate);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              LibraryInventory.CreateItemNoWithPostingSetup(
                GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        UpdateSalesPrepmtAccount(
          CreateGLAccountWithGivenSetup(VATPostingSetup, GeneralPostingSetup),
          GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure CopySalesOrderFromSalesOrder(DocFromNo: Code[20]; var SalesHeaderTo: Record "Sales Header")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        RefDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc(RefDocType::Order, DocFromNo, SalesHeaderTo);
    end;

    local procedure CopyPurchOrderFromPurchOrder(DocFromNo: Code[20]; var PurchaseHeaderTo: Record "Purchase Header")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        RefDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc(RefDocType::Order, DocFromNo, PurchaseHeaderTo);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithGivenSetup(VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        with GLAccount do begin
            Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
            Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; CompressPrepayment: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", CompressPrepayment);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchDocumentWithTwoLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateFullPrepaymentPurchHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", false);

        CreatePurchLine(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchLine(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateFullPrepaymentPurchHeader(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; CompressPrepayment: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATBusPostingGroup));
        PurchaseHeader.Validate("Prepayment %", 100);  // Added 100 for taking 100% prepayment amount.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Compress Prepayment", CompressPrepayment);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATProdPostingGroupCode), LibraryRandom.RandInt(5) * 2); // to simplify next division by 2
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineAndCalcVATAmountLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; PricesInclVAT: Boolean; PrepmtPct: Decimal; DirectUnitCost: Decimal)
    begin
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorNo, PrepmtPct, PricesInclVAT);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryERM.CreateGLAccountWithPurchSetup, 1, DirectUnitCost);
        PurchaseLine.CalcVATAmountLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);
    end;

    local procedure CreatePartialSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    begin
        SalesPrepmtAccount := CreatePrepmtSalesOrder(SalesHeader, SalesLine);
        SalesLine.Validate("Qty. to Invoice", Round(SalesLine.Quantity / 2, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepmtSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
    begin
        SalesPrepmtAccount :=
          LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandInt(50));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepmtPurchOrder(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID);
        PurchHeader.Modify(true);
        CreatePrepPurhcLine(PurchHeader, PurchLine, LineGLAccount."No.");
    end;

    local procedure CreatePartialPurchOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchPrepmtAccount: Code[20];
    begin
        PurchPrepmtAccount :=
          LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");

        CreatePrepPurhcLine(PurchHeader, PurchLine, LineGLAccount."No.");
        PurchLine.Validate("Qty. to Invoice", Round(PurchLine.Quantity / 2, 1));
        PurchLine.Modify(true);

        exit(PurchPrepmtAccount);
    end;

    local procedure CreatePrepPurhcLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineGLAccountNo: Code[20])
    begin
        with PurchLine do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, Type::"G/L Account", LineGLAccountNo, LibraryRandom.RandInt(50));
            Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            Validate("Prepayment %", LibraryRandom.RandInt(50));
            Modify(true);
        end;
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; CompressPrepayment: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CompressPrepayment);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithTwoLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateFullPrepaymentSalesHeader(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", false);

        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateFullPrepaymentSalesHeader(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; CompressPrepayment: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATBusPostingGroup));
        SalesHeader.Validate("Prepayment %", 100);  // Added 100 for taking 100% prepayment amount.
        SalesHeader.Validate("Compress Prepayment", CompressPrepayment);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(VATProdPostingGroupCode), LibraryRandom.RandInt(5) * 2); // to simplify next division by 2
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateDefaultDimensionAndUpdatePostingGroup(var DimensionValue: Record "Dimension Value"; GenBusPostingGroupCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GenPostingSetup: Record "General Posting Setup";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        GenPostingSetup.FindFirst;
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GenPostingSetup."Purch. Prepayments Account",
          DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PrepaymentPct: Decimal; PricesInclVAT: Boolean)
    begin
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Document Type"::Order, VendorNo);
            Validate("Prices Including VAT", PricesInclVAT);
            Validate("Prepayment %", PrepaymentPct);
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, Type::"G/L Account", GLAccountNo, NewQuantity);
            Validate("Direct Unit Cost", DirectUnitCost);
            Modify(true);
        end;
    end;

    local procedure CreateCustomItemPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, Type::Item, ItemNo, NewQuantity);
            Validate("Direct Unit Cost", DirectUnitCost);
            Modify(true);
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PrepaymentPct: Decimal; PricesInclVAT: Boolean)
    begin
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, "Document Type"::Order, CustomerNo);
            Validate("Prices Including VAT", PricesInclVAT);
            Validate("Prepayment %", PrepaymentPct);
            Modify(true);
        end;
    end;

    local procedure CreateCustomSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, Type::"G/L Account", GLAccountNo, NewQuantity);
            Validate("Unit Price", UnitPrice);
            Modify(true);
        end;
    end;

    local procedure CreateCustomItemSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, Type::Item, ItemNo, NewQuantity);
            Validate("Unit Price", UnitPrice);
            Modify(true);
        end;
    end;

    local procedure CreateCustomSalesLineAndCalcVATAmountLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; PricesInclVAT: Boolean; PrepmtPct: Decimal; UnitPrice: Decimal)
    begin
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerNo, PrepmtPct, PricesInclVAT);
        CreateCustomSalesLine(SalesLine, SalesHeader, LibraryERM.CreateGLAccountWithPurchSetup, 1, UnitPrice);
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);
    end;

    local procedure CreateSalesOrderWithOneLine(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateCustomItemSalesLine(SalesLine, SalesHeader, LibraryInventory.CreateItemNo, 1, LibraryRandom.RandDecInRange(10, 100, 2));
    end;

    local procedure CreatePurchaseOrderWithOneLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateCustomItemPurchaseLine(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo, 1, LibraryRandom.RandDecInRange(10, 100, 2));
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        Clear(NoSeriesManagement);
        exit(NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate, false));
    end;

    local procedure MockPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Init;
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        PurchaseHeader.Insert;
    end;

    local procedure MockPurchaseLineWithPrepmtAmtInv(PurchaseHeader: Record "Purchase Header"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; JobNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        with PurchaseLine do begin
            Init;
            "Document Type" := PurchaseHeader."Document Type";
            "Document No." := PurchaseHeader."No.";
            RecRef.GetTable(PurchaseLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Purchase Line");
            "Prepmt. Amt. Inv." := LibraryRandom.RandDec(100, 2);
            "Gen. Bus. Posting Group" := GenBusPostingGroupCode;
            "Gen. Prod. Posting Group" := GenProdPostingGroupCode;
            "Job No." := JobNo;
            Insert;
        end;
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader.Insert;
    end;

    local procedure MockSalesLineWithPrepmtAmtInv(SalesHeader: Record "Sales Header"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; JobNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        with SalesLine do begin
            Init;
            "Document Type" := SalesHeader."Document Type";
            "Document No." := SalesHeader."No.";
            RecRef.GetTable(SalesLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Sales Line");
            "Prepmt. Amt. Inv." := LibraryRandom.RandDec(100, 2);
            "Gen. Bus. Posting Group" := GenBusPostingGroupCode;
            "Gen. Prod. Posting Group" := GenProdPostingGroupCode;
            "Job No." := JobNo;
            Insert;
        end;
    end;

    local procedure MockGenBusProdPostingGroups(var GenPostingSetup: Record "General Posting Setup"; var GenBusPostingGroupCode: Code[20]; var GenProdPostingGroupCode: Code[20])
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroupCode := GenBusPostingGroup.Code;
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroupCode := GenProdPostingGroup.Code;
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
    end;

    local procedure MockGenBusProdPostingGroupWithPrepmtAcc(var DimensionValue: Record "Dimension Value"; var GenBusPostingGroupCode: Code[20]; var GenProdPostingGroupCode: Code[20]; CreateDfltDimInAcc: Boolean)
    var
        DefaultDimension: Record "Default Dimension";
        GenPostingSetup: Record "General Posting Setup";
        GLAccountNo: Code[20];
    begin
        MockGenBusProdPostingGroups(GenPostingSetup, GenBusPostingGroupCode, GenProdPostingGroupCode);
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        if CreateDfltDimInAcc then begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo,
              DimensionValue."Dimension Code", DimensionValue.Code);
        end;
        GenPostingSetup."Sales Prepayments Account" := GLAccountNo;
        GenPostingSetup."Purch. Prepayments Account" := GLAccountNo;
        GenPostingSetup.Modify;
    end;

    local procedure MockJobWithDfltDimension(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        Job: Record Job;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryJob.CreateJob(Job);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, Job."No.",
          DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Job."No.");
    end;

    local procedure OpenPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke;
    end;

    local procedure OpenPstdPurchCrMemorStatistics(No: Code[20])
    var
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
    begin
        PostedPurchaseCreditMemos.OpenEdit;
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PostedPurchaseCreditMemos.Statistics.Invoke;
    end;

    local procedure OpenPstdSalesCrMemorStatistics(No: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit;
        PostedSalesCreditMemos.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemos.Statistics.Invoke;
    end;

    local procedure OpenSalesOrderStatistics(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke;
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorRoundingAccount(VendorNo: Code[20]; AccountNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", AccountNo);
        VendorPostingGroup.Modify(true);
    end;

    local procedure UpdateCustomerRoundingAccount(CustomerNo: Code[20]; AccountNo: Code[20])
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", AccountNo);
        CustomerPostingGroup.Modify(true);
    end;

    local procedure PostSalesDocumentPartially(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindSet;
            repeat
                Validate("Qty. to Ship", Quantity / 2);
                Modify;
            until Next = 0;
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPurchDocumentPartially(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            FindSet;
            repeat
                Validate("Qty. to Receive", Quantity / 2);
                Modify;
            until Next = 0;
        end;
        PurchaseHeader."Vendor Invoice No." := IncStr(PurchaseHeader."Vendor Invoice No.");
        PurchaseHeader.Modify;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateSalesPrepmtAmtToDeductWithPrepmtAmtInvoiced(var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            Find;
            Validate("Prepmt Amt to Deduct", "Prepmt. Amt. Inv.");
            Modify(true);
        end;
    end;

    local procedure UpdatePurchPrepmtAmtToDeductWithPrepmtAmtInvoiced(var PurchLine: Record "Purchase Line")
    begin
        with PurchLine do begin
            Find;
            Validate("Prepmt Amt to Deduct", "Prepmt. Amt. Inv.");
            Modify(true);
        end;
    end;

    local procedure UpdateGeneralSetup(AmountDecimalPlaces: Text[5]; UnitAmountDecimalPlaces: Text[5]; AmountRoundingPrecision: Decimal; UnitAmountRoundingPrecision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            "Amount Decimal Places" := AmountDecimalPlaces;
            "Unit-Amount Decimal Places" := UnitAmountDecimalPlaces;
            "Amount Rounding Precision" := AmountRoundingPrecision;
            "Unit-Amount Rounding Precision" := UnitAmountRoundingPrecision;
            "Inv. Rounding Precision (LCY)" := AmountRoundingPrecision;
            Modify;
        end;
    end;

    local procedure UpdatePurchTotalPrepmtAmount(PurchaseHeader: Record "Purchase Header"; NewPrepmtTotalAmount: Decimal)
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchasePostPrepayments.UpdatePrepmtAmountOnPurchLines(PurchaseHeader, NewPrepmtTotalAmount);
    end;

    local procedure UpdateSalesTotalPrepmtAmount(SalesHeader: Record "Sales Header"; NewPrepmtTotalAmount: Decimal)
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.UpdatePrepmtAmountOnSaleslines(SalesHeader, NewPrepmtTotalAmount);
    end;

    local procedure UpdatePurchQtyToReceive(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        with PurchaseLine do begin
            Find;
            Validate("Qty. to Receive", QtyToReceive);
            Modify(true);
        end;
    end;

    local procedure UpdateSalesQtyToShip(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        with SalesLine do begin
            Find;
            Validate("Qty. to Ship", QtyToShip);
            Modify(true);
        end;
    end;

    local procedure UpdatePurchPrepmtAmtToDeduct(var PurchaseLine: Record "Purchase Line"; PrepmtAmtToDeduct: Decimal)
    begin
        PurchaseLine.Validate("Prepmt Amt to Deduct", PrepmtAmtToDeduct);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAmtToDeduct(var SalesLine: Record "Sales Line"; PrepmtAmtToDeduct: Decimal)
    begin
        SalesLine.Validate("Prepmt Amt to Deduct", PrepmtAmtToDeduct);
        SalesLine.Modify(true);
    end;

    local procedure GetInvRoundingAccFromCust(CustNo: Code[20]): Code[20]
    var
        Cust: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Cust.Get(CustNo);
        CustPostingGroup.Get(Cust."Customer Posting Group");
        exit(CustPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetInvRoundingAccFromVend(VendNo: Code[20]): Code[20]
    var
        Vend: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        Vend.Get(VendNo);
        VendPostingGroup.Get(Vend."Vendor Posting Group");
        exit(VendPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetVATEntryAmount(CustomerNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Bill-to/Pay-to No.", CustomerNo);
            SetRange("Document No.", DocumentNo);
            FindFirst;
            exit(Amount);
        end;
    end;

    local procedure GetPurchaseReceiptLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetSalesShipmentLines(SalesHeader: Record "Sales Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure FindPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; VendorNo: Code[20])
    begin
        with PurchInvHeader do begin
            SetRange("Buy-from Vendor No.", VendorNo);
            SetRange("Prepayment Invoice", true);
            FindFirst;
        end;
    end;

    local procedure FindPostedPurchaseCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendorNo: Code[20])
    begin
        with PurchCrMemoHdr do begin
            SetRange("Buy-from Vendor No.", VendorNo);
            SetRange("Prepayment Credit Memo", true);
            FindFirst;
        end;
    end;

    local procedure FindPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20])
    begin
        with SalesInvoiceHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            SetRange("Prepayment Invoice", true);
            FindFirst;
        end;
    end;

    local procedure FindPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CustomerNo: Code[20])
    begin
        with SalesCrMemoHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            SetRange("Prepayment Credit Memo", true);
            FindFirst;
        end;
    end;

    local procedure SetCheckPrepaymentinSalesSetup(CheckPrepmt: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmt);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetSalesInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesHeader.Find;
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetPurchaseInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchaseHeader.Find;
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
    end;

    local procedure TearDownVATPostingSetup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.DeleteAll;
    end;

    local procedure VerifyGLEntry(Amount: Decimal; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption));
    end;

    local procedure VerifyGLEntriesAmount(Amount: Decimal; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption));
    end;

    local procedure VerifyGLEntryDoesNotExist(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntry.IsEmpty, IncorrectGLEntryExistsErr);
    end;

    local procedure VerifyFirstSalesLinePrepmtAmountInvLCY(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindFirst;
            Assert.AreEqual("Prepayment Amount" / 2, "Prepmt. Amount Inv. (LCY)", IncorrectPrepmtAmountInvLCYErr);
        end;
    end;

    local procedure VerifyFirstPurchLinePrepmtAmountInvLCY(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            FindFirst;
            Assert.AreEqual("Prepayment Amount" / 2, "Prepmt. Amount Inv. (LCY)", IncorrectPrepmtAmountInvLCYErr);
        end;
    end;

    local procedure VerifyDimensionSetEntryIsExists(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        Assert.RecordIsNotEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifyDimensionSetEntryIsNotExists(DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        Assert.RecordIsEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifySalesPrepaymentCreditMemoVATAmount(SalesHeader: Record "Sales Header")
    var
        ExpectedVATAmount: Decimal;
    begin
        ExpectedVATAmount := -GetVATEntryAmount(SalesHeader."Sell-to Customer No.", SalesHeader."Last Prepayment No.");
        Assert.AreEqual(
          ExpectedVATAmount,
          GetVATEntryAmount(SalesHeader."Sell-to Customer No.", SalesHeader."Last Prepmt. Cr. Memo No."),
          IncorrectVATEntryAmountErr);
    end;

    local procedure VerifyPurchPrepaymentCreditMemoVATAmount(PurchaseHeader: Record "Purchase Header")
    var
        ExpectedVATAmount: Decimal;
    begin
        ExpectedVATAmount := -GetVATEntryAmount(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Last Prepayment No.");
        Assert.AreEqual(
          ExpectedVATAmount,
          GetVATEntryAmount(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Last Prepmt. Cr. Memo No."),
          IncorrectVATEntryAmountErr);
    end;

    local procedure VerifyGLAccountBalance(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("G/L Account No.", GLAccountNo);
            SetRange("Document No.", DocumentNo);
            CalcSums(Amount);
            TestField(Amount, ExpectedBalance);
        end;
    end;

    local procedure VerifyCustomerReceivablesAccountAmount(CustomerPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        VerifyGLAccountBalance(CustomerPostingGroup."Receivables Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifyVendorPayablesAccountAmount(VendorPostingGroupCode: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VerifyGLAccountBalance(VendorPostingGroup."Payables Account", DocumentNo, ExpectedAmount);
    end;

    local procedure VerifyValueNeedsToBeRounded(Value: Decimal)
    begin
        Assert.ExpectedErrorCode('TableErrorStr');
        Assert.ExpectedError(
          StrSubstNo('%1 needs to be rounded', Format(Value, 0, '<Sign><Integer Thousand><Decimals,3><Filler Character,0>')));
    end;

    local procedure VerifySalesLineFullPrepaymentWithDiscount(DocumentNo: Code[20]; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindFirst;
        SalesLine.TestField("Prepmt. Line Amount", SalesLine.Amount);
    end;

    local procedure VerifyPurchaseLineFullPrepaymentWithDiscount(DocumentNo: Code[20]; DocumentType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.FindFirst;
        PurchaseLine.TestField("Prepmt. Line Amount", PurchaseLine.Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoStatisticsPageHandler(var PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        PurchCreditMemoStatistics.VATAmount.AssertEquals(VATAmount);
        PurchCreditMemoStatistics.AmountInclVAT.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        PurchaseOrderStatistics."VATAmount[1]".AssertEquals(VATAmount);
        PurchaseOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        SalesOrderStatistics.VATAmount.AssertEquals(VATAmount);
        SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatisticsPageHandler(var SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics")
    var
        VATAmount: Variant;
        TotalAmount1: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount1);
        SalesCreditMemoStatistics.VATAmount.AssertEquals(VATAmount);
        SalesCreditMemoStatistics.AmountInclVAT.AssertEquals(Format(TotalAmount1, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrdStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderStatistics.PrepmtTotalAmount.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrdStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics.PrepmtTotalAmount.Value);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3; // Receive and Invoice
    end;
}

