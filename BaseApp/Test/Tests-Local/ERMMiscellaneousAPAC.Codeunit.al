codeunit 141008 "ERM - Miscellaneous APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqualMsg: Label 'Amount must be equal.';
        PurchaseLineNoCap: Label 'Purchase_Line___No__';
        PurchaseLineQuantityCap: Label 'Purchase_Line__Quantity';
        PurchaseLinePrepaymentCap: Label 'Purchase_Line___Prepayment___';
        PurchaseLinePrepmtLineAmountCap: Label 'Purchase_Line___Prepmt__Line_Amount_';
        JournalLinesCreatedMsg: Label 'The journal lines have successfully been created.';
        MessageDoesNotMatchErr: Label 'Message does not match Error.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        CurrentSaveValuesId: Integer;
        LinesNotUpdatedMsg: Label 'You have changed %1 on the purchase header, but it has not been changed on the existing purchase lines.', Comment = 'You have changed Posting Date on the purchase header, but it has not been changed on the existing purchase lines.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePaymentWithGST()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Sales Entry after posting Sales Order and General Journal.

        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup(true, true, true, true, true);  // Using true for Enable GST (Australia),Adjustment Mandatory,GST Report,Full GST on Prepayment,Unrealized VAT.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesInvoice(
          SalesLine, CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group"), CreateGLAccount(GeneralPostingSetup), 0);  // Using 0 for Line Discount Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice.

        // Exercise.
        CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", -SalesLine.Amount);

        // [THEN] Verify Unrealized GST GL Entry after post Sales Invoice.
        SourceCodeSetup.Get();
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup.Sales, GetReceivablesAccountFromCustomerPostingGroup(SalesLine."Sell-to Customer No."),
          SalesLine."Amount Including VAT");
        VerifyGSTSalesEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePaymentWithGST()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SourceCodeSetup: Record "Source Code Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Purchase Entry after posting Purchase Order and General Journal.

        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup(true, true, true, true, true);  // Using true for Enable GST (Australia),Adjustment Mandatory,GST Report,Full GST on Prepayment,Unrealized VAT.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseInvoice(
          PurchaseLine, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group"),
          PurchaseLine.Type::"G/L Account", CreateGLAccount(GeneralPostingSetup), 0);  // Using 0 for Line Discount Percent.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for Receive and Invoice.

        // Exercise.
        CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchaseLine.Amount);

        // [THEN] Verify Unrealized GST GL Entry after post purchase Invoice.
        SourceCodeSetup.Get();
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup.Purchases, GetPayablesAccountFromVendorPostingGroup(PurchaseLine."Buy-from Vendor No."),
          -PurchaseLine."Amount Including VAT");
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.FindFirst();
        Assert.AreNearlyEqual(
          PurchaseLine."Amount Including VAT" - PurchaseLine.Amount, GSTPurchaseEntry.Amount,
          LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithGST()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] GL and GST Sales Entry after posting Sales Order.

        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup(true, true, true, true, true);  // Using true for Enable GST (Australia),Adjustment Mandatory,GST Report,Full GST on Prepayment,Unrealized VAT.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesInvoice(
          SalesLine, CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group"), CreateGLAccount(GeneralPostingSetup), 0);  // Using 0 for Line Discount Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice.

        // [THEN] Verify Unrealized GST GL Entry after post Sales Invoice.
        SourceCodeSetup.Get();
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup.Sales, GetReceivablesAccountFromCustomerPostingGroup(SalesLine."Sell-to Customer No."),
          SalesLine."Amount Including VAT");
        VerifyGSTSalesEntry(DocumentNo, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,PaymentToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerPaymentWithPaymentToleranceAndGST()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PaymentToleranceAmount: Decimal;
    begin
        // [SCENARIO] G/L entries after unapply Customer Payment entry with Payment Tolerance and GST.

        // [GIVEN] Create and post Sales Invoice. Create General Journal line. Apply Invoice to Payment on Cash Receipt Journal with Payment Tolerance and Post it.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();
        UpdatePaymentToleranceOnGeneralLedgerSetup(true, true, true);  // True for AdjustForPaymentDisc, PmtDiscToleranceWarning and PmtToleranceWarning.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreateSalesInvoice(
          SalesLine, CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group"), CreateGLAccount(GeneralPostingSetup),
          LibraryRandom.RandDec(10, 2));  // Using Random value for Line Discount Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice.
        PaymentToleranceAmount := LibraryRandom.RandDecInDecimalRange(0.2, 0.5, 2);
        LibraryVariableStorage.Enqueue(PaymentToleranceAmount);  // Enqueue value for ApplyCustomerEntriesModalPageHandler.
        DocumentNo := CreateAndPostCashReceiptJournalAfterApplyInvoice(SalesLine, PaymentToleranceAmount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        VerifyGSTEntryFromVATEntry(DocumentNo); // TFS 313783

        // Exercise.
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify.
        SourceCodeSetup.Get();
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.", GetReceivablesAccountFromCustomerPostingGroup(
            SalesLine."Sell-to Customer No."), -PaymentToleranceAmount);
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.", VATPostingSetup."Sales VAT Account",
          PaymentToleranceAmount * VATPostingSetup."VAT %" / 100);
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.", GeneralPostingSetup."Sales Pmt. Tol. Credit Acc.",
          PaymentToleranceAmount - PaymentToleranceAmount * VATPostingSetup."VAT %" / 100);

        // Tear Down.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,PaymentToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorPaymentWithPaymentToleranceAndGST()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SourceCodeSetup: Record "Source Code Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        PaymentToleranceAmount: Decimal;
    begin
        // [SCENARIO] G/L entries after unapply Vendor Payment entry with Payment Tolerance and GST.

        // [GIVEN] Create and post Purchase Invoice. Create General Journal line. Apply Invoice to Payment on Payment Journal with Payment Tolerance and Post it.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();
        UpdatePaymentToleranceOnGeneralLedgerSetup(true, true, true);  // True for AdjustForPaymentDisc, PmtDiscToleranceWarning and PmtToleranceWarning.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralPostingSetup(GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseInvoice(
          PurchaseLine, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group"),
          PurchaseLine.Type::"G/L Account", CreateGLAccount(GeneralPostingSetup),
          LibraryRandom.RandDec(10, 2));  // Using Random value for Line Discount Percent.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        PaymentToleranceAmount := LibraryRandom.RandDecInDecimalRange(0.2, 0.5, 2);
        LibraryVariableStorage.Enqueue(-PaymentToleranceAmount);  // Enqueue value for ApplyVendorEntriesModalPageHandler.
        DocumentNo := CreateAndPostPaymentJournalAfterApplyInvoice(PurchaseLine, PaymentToleranceAmount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VerifyGSTEntryFromVATEntry(DocumentNo); // TFS 313783

        // Exercise.
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // Verify.
        SourceCodeSetup.Get();
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.", GetPayablesAccountFromVendorPostingGroup(
            PurchaseLine."Buy-from Vendor No."), PaymentToleranceAmount);
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.", VATPostingSetup."Purchase VAT Account",
          -PaymentToleranceAmount * VATPostingSetup."VAT %" / 100);
        VerifyAmountOnGLEntry(
          DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.", GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.",
          -(PaymentToleranceAmount - PaymentToleranceAmount * VATPostingSetup."VAT %" / 100));

        // Tear Down.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Adjust for Payment Discount");
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler,DimensionSelectionMultipleModalPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementReportWithDimensionSelection()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        NoSeriesLine: Record "No. Series Line";
    begin
        // [FEATURE] [Close Income Statement]
        // [SCENARIO] Close Income Statement report runs successfully with Dimension Selection.

        // [GIVEN] Close the Fiscal Year and find General Journal Template and Batch. Find No. Series Line.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        FindGeneralJournalTemplateAndBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        NoSeriesLine.SetRange("Series Code", GenJournalBatch."No. Series");
        NoSeriesLine.FindFirst();
        LibraryERM.CreateGLAccount(GLAccount);
        Commit();  // COMMIT required for test case.

        // Enqueue values for CloseIncomeStatementRequestPageHandler.
        EnqueueValuesForHandler(CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true)), GenJournalBatch."Journal Template Name");  // Calculated date required for Fiscal Year ending Date. True used for Closed.
        EnqueueValuesForHandler(GenJournalBatch.Name, NoSeriesLine."Starting No.");
        EnqueueValuesForHandler(GLAccount."No.", JournalLinesCreatedMsg);  // Enqueue GLAccountNo for CloseIncomeStatementRequestPageHandler and JournalLinesCreatedMsg for MessageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Close Income Statement");  // Opens CloseIncomeStatementRequestPageHandler.

        // [THEN] Message "The journal lines have successfully been created" in the MessageHandler.
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTest()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] values on report Purchase Prepmt. Doc. - Test.

        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseHeader(PurchaseHeader, Item."Gen. Prod. Posting Group");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0);  // 0 for Line Discount %.
        EnqueueValuesForHandler(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");  // Enqueue for PurchasePrepmtDocTestRequestPageHandler.
        Commit();  // commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");  // Opens PurchasePrepmtDocTestRequestPageHandler.

        // [THEN] Verify values on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLineNoCap, PurchaseLine."No.");
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLineQuantityCap, PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLinePrepaymentCap, PurchaseLine."Prepayment %");
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLinePrepmtLineAmountCap, PurchaseLine."Prepmt. Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithPrepaymentAndVATAmount()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmount: Decimal;
    begin
        // [SCENARIO]  VAT Amount on Posted Purchase Invoice after posting Purchase prepayment.

        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseHeader(PurchaseHeader, Item."Gen. Prod. Posting Group");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0); // 0 for Line Discount %.

        // Exercise.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify VAT Amount on Posted Purchase Invoice.
        PurchInvLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvLine.FindFirst();
        VATAmount := PurchInvLine."Amount Including VAT" - PurchInvLine.Amount;
        Assert.AreNearlyEqual(
          PurchaseLine."Amount Including VAT" - PurchaseLine.Amount, VATAmount,
          LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentDateToDtldCustLedgEntryFromSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 213137] Value of "Document Date" of "Detailed Cust. Ledg. Entry" must be equal to value from Sales Invoice after posting
        Initialize();

        // [GIVEN] Sales invoice with "Document Date" = '01.01.2020', "Posting Date" = '02.02.2021', WORKDATE = '03.03.2022'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader."Document Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(5, 10));
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Post sales invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Detailed Cust. Ledg. Entry"."Document Date" = '01.01.2020'

        DetailedCustLedgEntry.SetRange("Document No.", DocNo);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField("Document Date", SalesHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentDateToDtldVendLedgEntryFromPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 213137] Value of "Document Date" of "Detailed Vendor Ledg. Entry" must be equal to value from Purchase Invoice after posting
        Initialize();

        // [GIVEN] Purchase invoice with "Document Date" = '01.01.2020', "Posting Date" = '02.02.2021', WORKDATE = '03.03.2022'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader."Document Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(5, 10));
        PurchaseHeader.Modify();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Detailed Vendor Ledg. Entry"."Document Date" = '01.01.2020'
        DetailedVendorLedgEntry.SetRange("Document No.", DocNo);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField("Document Date", PurchaseHeader."Document Date");
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure PmtReconJnlGLAccWithVATSetup()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DummyVATEntry: Record "VAT Entry";
        AmountToApply: Decimal;
    begin
        // [FEATURE] [Reconciliation] [VAT]
        // [SCENARIO 374756] VAT Entry is created after posting Payment Reconciliation Journal with GLAccount with VAT Posting Setup
        Initialize();

        // [GIVEN] GLAccount "A" with VAT Posting Setup
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Payment Reconciliation Journal with GLAccount "A"
        AmountToApply := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateBankAccReconLineWithGLAcc(
          BankAccReconciliation, BankAccReconciliationLine,
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), AmountToApply);
        CreatePaymentApplication(BankAccReconciliationLine, AmountToApply);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation,
                                         BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");

        // [WHEN] Post Reconciliation Journal
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] New VATEntry is created
        DummyVATEntry.SetRange("Document No.", BankAccReconciliation."Statement No.");
        DummyVATEntry.SetRange(Type, DummyVATEntry.Type::Purchase);
        Assert.RecordIsNotEmpty(DummyVATEntry)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithItemAndDeferralCreatesGSTEntry()
    var
        Item: Record Item;
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [GST] [Deferrals]
        // [SCENARIO 221286] When Sales Invoice with Item and Deferral Code is posted, a GST Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Sales Invoice "SI" with Item in the Sales Line.
        CreateItemWithUnitPrice(Item);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, Item."No.", WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "SI" Sales Line.
        UpdateSalesLineWithDeferral(SalesHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "SI" is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GST Sales Entries created for the posted "SI".
        VerifyGSTSalesEntryExists(PostedDocNo, GSTSalesEntry."Document Type"::Invoice, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithGLAndDeferralCreatesGSTEntry()
    var
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [GST] [Deferrals]
        // [SCENARIO 221286] When Sales Invoice with GL Account and Deferral Code is posted, a GST Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Sales Invoice "SI" with GLAccount in the Sales Line.
        CreateSalesDocWithLine(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "SI" Sales Line.
        UpdateSalesLineWithDeferral(SalesHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "SI" is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GST Sales Entries created for the posted "SI".
        VerifyGSTSalesEntryExists(PostedDocNo, GSTSalesEntry."Document Type"::Invoice, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithItemAndDeferralCreatesGSTEntry()
    var
        Item: Record Item;
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [GST] [Deferrals]
        // [SCENARIO 221286] When Sales Credit Memo with Item and Deferral Code is posted, a GST Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Sales Credit Memo "SC" with Item in the Sales Line.
        CreateItemWithUnitPrice(Item);
        CreateSalesDocWithLine(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo",
          SalesLine.Type::Item, Item."No.", WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "SI" Sales Line.
        UpdateSalesLineWithDeferral(SalesHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "SI" is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GST Sales Entries created for the posted "SC".
        VerifyGSTSalesEntryExists(PostedDocNo, GSTSalesEntry."Document Type"::"Credit Memo", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithItemAndDeferralCreatesGSTEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [GST] [Deferrals]
        // [SCENARIO 221286] When Purchase Invoice with Item and Deferral Code is posted, a GST Purchase Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Purchase Invoice "PI" with Item in the Purchase Line.
        CreateItemWithUnitPrice(Item);
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          PurchaseLine.Type::Item, Item."No.", WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "SI" Purchase Line.
        UpdatePurchaseLineWithDeferral(PurchaseHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "PI" is posted.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GST Purchase Entries created for the posted "PI".
        VerifyGSTPurchaseEntryExists(PostedDocNo, GSTPurchaseEntry."Document Type"::Invoice, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithGLAndDeferralCreatesGSTEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [GST] [Deferrals]
        // [SCENARIO 221286] When Purchase Invoice with GL Account and Deferral Code is posted, a GST Purchase Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Purchase Invoice "PI" with Item in the Purchase Line.
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "PI" Purchase Line.
        UpdatePurchaseLineWithDeferral(PurchaseHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "PI" is posted.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GST Purchase Entries created for the posted "PI".
        VerifyGSTPurchaseEntryExists(PostedDocNo, GSTPurchaseEntry."Document Type"::Invoice, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithItemAndDeferralCreatesGSTEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [GST] [Deferrals]
        // [SCENARIO 221286] When Purchase Credit Memo with Item and Deferral Code is posted, a GST Purchase Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Purchase Credit Memo "PI" with Item in the Purchase Line.
        CreateItemWithUnitPrice(Item);
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo",
          PurchaseLine.Type::Item, Item."No.", WorkDate());

        // [GIVEN] Deferral Template "DF" is applied for "PI" Purchase Line.
        UpdatePurchaseLineWithDeferral(PurchaseHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "PI" is posted.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GST Purchase Entries created for the posted "PI".
        VerifyGSTPurchaseEntryExists(PostedDocNo, GSTPurchaseEntry."Document Type"::"Credit Memo", 1);
    end;

#if not CLEAN23
    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostBuffer_GetGLAccountGST()
    var
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        InvoicePostBuffer: Record "Invoice Post. Buffer";
        Result: Code[20];
    begin
        // [FEATURE] [UT] [GST] [Deferrals]
        // [SCENARIO 221286] TAB49 GetGLAccountGST returns correct GL Account.
        Initialize();

        Result := InvoicePostBuffer.GetGLAccountGST('', '');
        Assert.AreEqual('', Result, 'InvoicePostBuffer.GetGLAccountGST should return empty value');

        LibraryERM.CreateGLAccount(GLAccount);
        Result := InvoicePostBuffer.GetGLAccountGST('', GLAccount."No.");
        Assert.AreEqual(GLAccount."No.", Result, 'InvoicePostBuffer.GetGLAccountGST should return GLAccount No.');

        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 1);
        Result := InvoicePostBuffer.GetGLAccountGST(DeferralTemplate."Deferral Code", GLAccount."No.");
        Assert.AreEqual(
          DeferralTemplate."Deferral Account", Result,
          'InvoicePostBuffer.GetGLAccountGST should return DeferralTemplate."Deferral Account"');
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostingBuffer_GetGLAccountGST()
    var
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        Result: Code[20];
    begin
        // [FEATURE] [UT] [GST] [Deferrals]
        // [SCENARIO 221286] TAB55 GetGLAccountGST returns correct GL Account.
        Initialize();

        Result := InvoicePostingBuffer.GetGLAccountGST('', '');
        Assert.AreEqual('', Result, 'InvoicePostingBuffer.GetGLAccountGST should return empty value');

        LibraryERM.CreateGLAccount(GLAccount);
        Result := InvoicePostingBuffer.GetGLAccountGST('', GLAccount."No.");
        Assert.AreEqual(GLAccount."No.", Result, 'InvoicePostingBuffer.GetGLAccountGST should return GLAccount No.');

        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 1);
        Result := InvoicePostingBuffer.GetGLAccountGST(DeferralTemplate."Deferral Code", GLAccount."No.");
        Assert.AreEqual(
          DeferralTemplate."Deferral Account", Result,
          'InvoicePostingBuffer.GetGLAccountGST should return DeferralTemplate."Deferral Account"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithGLCreatesGLEntriesWithSalesLineDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 253900] When Sales Invoice with GL Account is posted, GL Entries are created with Description taken from the GL Account.
        Initialize();

        // [GIVEN] Sales Invoice with G/L Account in the Sales Line.
        CreateSalesDocWithLine(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), WorkDate());

        // [GIVEN] Set Sales Line Description
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomXMLText(10));
        SalesLine.Modify(true);

        // [WHEN] Sales Invoice is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] For G/L Entry with Receivables Account Description is equal to the Sales Header Posting Description.
        VerifyGLEntryForReceivablesAccountDescription(
          PostedDocNo, SalesLine."Sell-to Customer No.", SalesHeader."Posting Description");

        // [THEN] For all G/L Entries with not Receivables Account Description is equal to the Sales Line Description.
        VerifyGLEntriesForNotReceivablesAccountsDescription(
          PostedDocNo, SalesLine."Sell-to Customer No.", SalesLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithGLCreatesGLEntriesWithPurchLineDescription()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 253900] When Purchase Invoice with GL Account is posted, GL Entries are created with Description taken from the GL Account.
        Initialize();

        // [GIVEN] Purchase Invoice with G/L Account in the Purchase Line.
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), WorkDate());

        // [GIVEN] Set Purchase Line Description
        PurchaseLine.Validate(Description, LibraryUtility.GenerateRandomXMLText(10));
        PurchaseLine.Modify(true);

        // [WHEN] Purchase Invoice is posted.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] For G/L Entry with Receivables Account Description is equal to the Purchase Header Posting Description.
        VerifyGLEntryForPayablesAccountDescription(
          PostedDocNo, PurchaseLine."Buy-from Vendor No.", PurchaseHeader."Posting Description");

        // [THEN] For all G/L Entries with not Receivables Account Description is equal to the Purchase Line Description.
        VerifyGLEntriesForNotPayablesAccountsDescription(
          PostedDocNo, PurchaseLine."Buy-from Vendor No.", PurchaseLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithGLCreatesGLEntriesWithServiceLineDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 253900] When Service Invoice with GL Account is posted, GL Entries are created with Description taken from the GL Account.
        Initialize();

        // [GIVEN] Service Invoice with G/L Account in the Service Line.
        CreateServiceDocWithLine(
          ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice,
          ServiceLine.Type::"G/L Account", CreateGLAccountNo(), WorkDate());

        // [GIVEN] Set Service Line Description
        ServiceLine.Validate(Description, LibraryUtility.GenerateRandomXMLText(10));
        ServiceLine.Modify(true);

        // [WHEN] Service Invoice is posted.
        PostedDocNo := PostServiceInvoice(ServiceHeader);

        // [THEN] For G/L Entry with Receivables Account Description is equal to the Service Header Posting Description.
        VerifyGLEntryForReceivablesAccountDescription(
          PostedDocNo, ServiceLine."Bill-to Customer No.", ServiceHeader."Posting Description");

        // [THEN] For all G/L Entries with not Receivables Account Description is equal to the Service Line Description.
        VerifyGLEntriesForNotReceivablesAccountsDescription(
          PostedDocNo, ServiceLine."Bill-to Customer No.", ServiceLine.Description);
    end;

    [Test]
    [HandlerFunctions('AUNZStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintDueDateInAUNZStatementsReport()
    var
        ExpectedDueDate: Date;
    begin
        // [SCENARIO 258164] Due Date is printed in report "AU/NZ Statement"
        Initialize();

        // [GIVEN] Cust. Ledger Entry with "Due Date" = "06-02-2018"
        ExpectedDueDate := MockCustLedgerEntryWithDueDate();
        Commit();

        // [WHEN] Invoke report "AU/NZ Statement"
        REPORT.Run(REPORT::"AU/NZ Statement");

        // [THEN] Due Date has been printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('FORMAT_DueDate_', Format(ExpectedDueDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseVendorExchangeRateIsUsedForAdditionalCurrencyAmountCalculation()
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Purchase] [ACY]
        // [SCENARIO 321551] Vendor Exchange rate in Purchase Order is used for Additional-Currency Amount Calculation.
        Initialize();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Currency.
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] "Enable Vendor GST Amount (ACY)" set to TRUE in Purchases & Payables Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Enable Vendor GST Amount (ACY)" := true;
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Currency set up as Additional Reporting curreny.
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        // [GIVEN] Purchase Order with "Vendor Exchange Rate (ACY)" = 10 and Purchase Line with "Quanitity" = 2, "Direct Unit Cost" = 15.
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), WorkDate());
        PurchaseHeader."Vendor Exchange Rate (ACY)" := LibraryRandom.RandInt(10);
        PurchaseHeader.Modify();

        // [WHEN] Purchase Order is posted.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry has "Additional-Currency Amount" equal to 2 * 15 * 10 = 300.
        GLEntry.SetRange("G/L Account No.", PurchaseLine."No.");
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(
          "Additional-Currency Amount",
          PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseHeader."Vendor Exchange Rate (ACY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoLinesAndDeferralCreatesSingleGSTSalesEntry()
    var
        Item: Record Item;
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [GST] [Deferrals]
        // [SCENARIO xxxxxx] When Sales Order with two lines and deferral setup, a single GST Sales Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Sales Order "SO" with two item lines
        CreateItemWithUnitPrice(Item);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, Item."No.", WorkDate());

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        // [GIVEN] Deferral Template "DF" with 3 "No. Of Periods" is applied for second "SO" line.
        UpdateSalesLineWithDeferral(SalesHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "SO" is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] 2 GST Sales Entries created for the posted "SO".
        VerifyGSTSalesEntryExists(PostedDocNo, GSTSalesEntry."Document Type"::Invoice, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTwoLinesAndDeferralCreatesSingleGSTPurchaseEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [GST] [Deferrals]
        // [SCENARIO xxxxxx] When Purchase Order with two lines and deferral setup, a single GST Sales Entry is created.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Purchase Order "PO" with two item lines
        CreateItemWithUnitPrice(Item);
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          PurchaseLine.Type::Item, Item."No.", WorkDate());

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Deferral Template "DF" with "No. Of Periods" is applied for second "SO" Line.
        UpdatePurchaseLineWithDeferral(PurchaseHeader, LibraryRandom.RandIntInRange(3, 10));

        // [WHEN] "PO" is posted.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 2 GST Purchase Entries created for the posted "PO".
        VerifyGSTPurchaseEntryExists(PostedDocNo, GSTPurchaseEntry."Document Type"::Invoice, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoLinesAndDeferralCreatesSingleGSTSalesEntryPreview()
    var
        Item: Record Item;
        GSTSalesEntry: Record "GST Sales Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLPostingPreview: TestPage "G/L Posting Preview";
        GSTSalesEntriesPreview: TestPage "GST Sales Entries Preview";
    begin
        // [FEATURE] [Sales] [GST] [Deferrals] [Posting Preview]
        // [SCENARIO 337956] When Sales Order with two lines and deferral setup, a single GST Sales Entry is created in posting preview.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Sales Order "SO" with two item lines
        CreateItemWithUnitPrice(Item);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, Item."No.", WorkDate());

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        // [GIVEN] Deferral Template "DF" with 3 "No. Of Periods" is applied for second "SO" line.
        UpdateSalesLineWithDeferral(SalesHeader, LibraryRandom.RandIntInRange(3, 10));
        Commit();

        // [WHEN] Preview posting of "SO".
        GLPostingPreview.Trap();
        asserterror LibrarySales.PreviewPostSalesDocument(SalesHeader);
        Assert.ExpectedError('');

        // [THEN] Two GST Sales Entries shown on "G/L Posting Preview" page
        GLPostingPreview.FindFirstField("Table Name", GSTSalesEntry.TableCaption());
        GLPostingPreview."No. of Records".AssertEquals(2);

        GSTSalesEntriesPreview.Trap();
        GLPostingPreview."No. of Records".Drilldown();

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        GSTSalesEntriesPreview.FindFirstField(Amount, -(SalesLine."Amount Including VAT" - SalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTwoLinesAndDeferralCreatesSingleGSTPurchaseEntryPreview()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GLPostingPreview: TestPage "G/L Posting Preview";
        GSTPurchaseEntriesPreview: TestPage "GST Purchase Entries Preview";
    begin
        // [FEATURE] [Purchase] [GST] [Posting Preview]
        // [SCENARIO 337956] When Purchase Order with two lines and deferral setup, a single GST Sales Entry is created in posting preview.
        Initialize();
        UpdateGeneralLedgerSetupGSTReport();

        // [GIVEN] Purchase Order "PO" with two item lines
        CreateItemWithUnitPrice(Item);
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          PurchaseLine.Type::Item, Item."No.", WorkDate());

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Deferral Template "DF" with "No. Of Periods" is applied for second "SO" Line.
        UpdatePurchaseLineWithDeferral(PurchaseHeader, LibraryRandom.RandIntInRange(3, 10));
        Commit();

        // [WHEN] Preview posting of "PO".
        GLPostingPreview.Trap();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);
        Assert.ExpectedError('');

        // [THEN] Two GST Sales Entries shown on "G/L Posting Preview" page
        GLPostingPreview.FindFirstField("Table Name", GSTPurchaseEntry.TableCaption());
        GLPostingPreview."No. of Records".AssertEquals(2);

        GSTPurchaseEntriesPreview.Trap();
        GLPostingPreview."No. of Records".Drilldown();

        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        GSTPurchaseEntriesPreview.FindFirstField(Amount, PurchaseLine."Amount Including VAT" - PurchaseLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GSTBaseIsZero()
    var
        GSTPurchaseEntries: TestPage "GST Purchase Entries";
    begin
        // [SCENARIO] When the page GST Purchase Entry is open and a value in the GST Purchase Entries table
        // has a record with "GST Base" = 0 no error is thrown

        // [GIVEN] the GST Purchase Entries table with at least one record with the value "GST Base" = 0
        InitGSTPurchaseEntry();

        // [WHEN] the page GST Purchase Entry opens
        GSTPurchaseEntries.OpenView();
        //[THEN] no error is thrown
        GSTPurchaseEntries.Close();
    end;

    [Scope('OnPrem')]
    procedure ACYAmountsChangeInPurchLineOnHeaderPostingDateValidation()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewExchRate: Decimal;
    begin
        // [FEATURE] [Purchase] ACY]
        // [SCENARIO 412958] ACY amounts in purchase line change after Stan validates "Posting Date" in purchase header

        Initialize();

        // [GIVEN] ACY Currency is "USD" in General Ledger Setup
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        // [GIVEN] Two exchange rates:
        // [GIVEN] "Starting Date" = 01.01.2021, "Exch. Rate Amount" = 10
        // [GIVEN] "Starting Date" = 02.01.2021, "Exch. Rate Amount" = 20
        LibraryERM.CreateExchangeRate(
          Currency.Code, WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        NewExchRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate() + 1, NewExchRate, NewExchRate);

        // [GIVEN] Purchase invoice with "Posting Date" = 01.01.2021, "VAT Base" = 100, "VAT %" = 10
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(LinesNotUpdatedMsg, PurchaseHeader.FieldCaption("Posting Date")));

        // [WHEN] Change posting date in purchase header to 02.01.2021
        PurchaseHeader.Validate("Posting Date", WorkDate() + 1);
        PurchaseHeader.Modify(true);

        // [THEN] "VAT Base (ACY)" is 2000 ("VAT Base" * "Exch. Rate Amount" = 100 * 20)
        // [THEN] "Amount (ACY)" is 2000
        // [THEN] "Amount Including VAT (ACY)" is 2200 ("Amount (ACY)" + "VAT Base (ACY)" * "VAT %" / 100 = 2000 + 2000 * 10 / 100)
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT Base (ACY)", Round(PurchaseLine."VAT Base Amount" * NewExchRate));
        PurchaseLine.TestField("Amount (ACY)", PurchaseLine."VAT Base (ACY)");
        PurchaseLine.TestField(
          "Amount Including VAT (ACY)",
          Round(PurchaseLine."Amount (ACY)" + PurchaseLine."VAT Base (ACY)" * PurchaseLine."VAT %" / 100));
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM - Miscellaneous APAC");
        LibraryApplicationArea.EnableFoundationSetup();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM - Miscellaneous APAC");

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryVariableStorage.Clear();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM - Miscellaneous APAC");
        Commit();
    end;

    local procedure CreateBankAccReconLineWithGLAcc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; GLAccountNo: Code[20]; StmtAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        with BankAccReconciliationLine do begin
            Validate("Transaction Date", WorkDate());
            Validate("Account Type", "Account Type"::"G/L Account");
            Validate("Account No.", GLAccountNo);
            Validate("Statement Amount", StmtAmount);
            Modify();
        end;
    end;

    local procedure CreatePaymentApplication(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AmountToApply: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        with AppliedPaymentEntry do begin
            Init();
            "Statement Type" := BankAccReconLine."Statement Type";
            "Bank Account No." := BankAccReconLine."Bank Account No.";
            "Statement No." := BankAccReconLine."Statement No.";
            "Statement Line No." := BankAccReconLine."Statement Line No.";
            "Account Type" := BankAccReconLine."Account Type";
            "Account No." := BankAccReconLine."Account No.";
            "Applied Amount" := AmountToApply;
            Insert();
        end;

        BankAccReconLine.Validate("Applied Amount", AmountToApply);
        BankAccReconLine.Modify();
    end;

    local procedure CreateAndPostCashReceiptJournalAfterApplyInvoice(SalesLine: Record "Sales Line"; PaymentToleranceAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.", -(SalesLine."Amount Including VAT" + PaymentToleranceAmount));  // Value required to invoke Payment Tolerance Warning.
        Commit();  // COMMIT is required for the test case.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        CashReceiptJournal."Apply Entries".Invoke();  // Opens ApplyCustomerEntriesModalPageHandler.
        CashReceiptJournal.Close();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGeneralJournalLine(GenJournalLine, GenJournalTemplate.Type::General, AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPaymentJournalAfterApplyInvoice(PurchaseLine: Record "Purchase Line"; PaymentToleranceAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentJournal: TestPage "Payment Journal";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."Amount Including VAT" + PaymentToleranceAmount);  // Value required to invoke Payment Tolerance Warning.
        Commit();  // COMMIT is required for the test case.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ApplyEntries.Invoke();  // Opens ApplyVendorEntriesModalPageHandler.
        PaymentJournal.Close();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralBusinessPostingGroup(DefVATBusinessPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", DefVATBusinessPostingGroup);
        GenBusinessPostingGroup.Modify(true);
        exit(GenBusinessPostingGroup.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        FindGeneralJournalTemplateAndBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateVATPostingSetup(VATPostingSetup, true);  // True used for AdjustForPaymentDiscount.
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, CreateGeneralBusinessPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CreateGeneralProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Line Disc. Account", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralProductPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", DefVATProdPostingGroup);
        GenProdPostingGroup.Modify(true);
        exit(GenProdPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; GenProdPostingGroup: Code[20])
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", GenProdPostingGroup);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prepayment %", 100);  // 100 is required for test case.
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; LineDiscountPercent: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random for quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LineDiscountPercent);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; BuyfromVendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; LineDiscountPercent: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyfromVendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LineDiscountPercent);
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20]; No: Code[20]; LineDiscountPercent: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LineDiscountPercent);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDocWithLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchLineType, No, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceDocWithLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; ServiceLineType: Enum "Service Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLineType, No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateItemWithUnitPrice(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDecInRange(100, 1000, 2),
          LibraryRandom.RandDecInRange(100, 1000, 2));
    end;

    local procedure CreateGLAccountNo(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        exit(CreateGLAccount(GeneralPostingSetup));
    end;

    local procedure MockCustLedgerEntryWithDueDate(): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Due Date" :=
          LibraryRandom.RandDateFrom(CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 100)) + 'D>', WorkDate()),
            LibraryRandom.RandIntInRange(10, 100));
        CustLedgerEntry.Insert();
        LibraryVariableStorage.Enqueue(CustomerNo);
        exit(CustLedgerEntry."Due Date");
    end;

    local procedure PostServiceInvoice(ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure EnqueueValuesForHandler(Value: Variant; Value2: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
    end;

    local procedure FindGeneralJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure GetPayablesAccountFromVendorPostingGroup(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetReceivablesAccountFromCustomerPostingGroup(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure UpdateGeneralLedgerSetup(EnableGSTAustralia: Boolean; AdjustmentMandatory: Boolean; GSTReport: Boolean; FullGSTOnPrepayment: Boolean; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGSTAustralia);
        GeneralLedgerSetup.Validate("Adjustment Mandatory", AdjustmentMandatory);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupGSTReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("GST Report", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePaymentToleranceOnGeneralLedgerSetup(AdjustForPaymentDisc: Boolean; PmtDiscToleranceWarning: Boolean; PmtToleranceWarning: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PmtDiscountGracePeriod: DateFormula;
    begin
        Evaluate(PmtDiscountGracePeriod, Format(LibraryRandom.RandInt(5)) + 'D');
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", AdjustForPaymentDisc);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", PmtDiscToleranceWarning);
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", PmtToleranceWarning);
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", PmtDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", LibraryRandom.RandDecInDecimalRange(0.0, 0.1, 2));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePrepmtAccInGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount(GeneralPostingSetup));
        GeneralPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount(GeneralPostingSetup));
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjustForPaymentDiscount: Boolean)
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesLineWithDeferral(SalesHeader: Record "Sales Header"; NoOfPeriods: Integer)
    var
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralTemplateCode: Code[10];
    begin
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Posting Date", NoOfPeriods);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindLast();
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineWithDeferral(PurchaseHeader: Record "Purchase Header"; NoOfPeriods: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralTemplateCode: Code[10];
    begin
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Posting Date", NoOfPeriods);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindLast();
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyGSTSalesEntryExists(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedNoOfEntries: Integer)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document Type", DocumentType);
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GSTSalesEntry, ExpectedNoOfEntries);
    end;

    local procedure VerifyGSTPurchaseEntryExists(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedNoOfEntries: Integer)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document Type", DocumentType);
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GSTPurchaseEntry, ExpectedNoOfEntries);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; SourceCode: Code[10]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCode);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyGSTSalesEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GSTSalesEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyGSTEntryFromVATEntry(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();

        case VATEntry.Type of
            VATEntry.Type::Sale:
                VerifyGSTSalesEntryAmount(DocumentNo, VATEntry.Amount, VATEntry.Count);
            VATEntry.Type::Purchase:
                VerifyGSTPurchaseEntryAmount(DocumentNo, VATEntry.Amount, VATEntry.Count);
        end;
    end;

    local procedure VerifyGSTSalesEntryAmount(DocumentNo: Code[20]; EntryAmount: Decimal; Cnt: Integer)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.FindFirst();
        GSTSalesEntry.TestField(Amount, EntryAmount);
        Assert.RecordCount(GSTSalesEntry, Cnt);
    end;

    local procedure VerifyGSTPurchaseEntryAmount(DocumentNo: Code[20]; EntryAmount: Decimal; Cnt: Integer)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.FindFirst();
        GSTPurchaseEntry.TestField(Amount, EntryAmount);
        Assert.RecordCount(GSTPurchaseEntry, Cnt);
    end;

    local procedure VerifyGLEntryForReceivablesAccountDescription(PostedDocNo: Code[20]; CustomerNo: Code[20]; ExpectedDescription: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", PostedDocNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("G/L Account No.", GetReceivablesAccountFromCustomerPostingGroup(CustomerNo));
            FindFirst();
            TestField(Description, ExpectedDescription);
        end;
    end;

    local procedure VerifyGLEntriesForNotReceivablesAccountsDescription(PostedDocNo: Code[20]; CustomerNo: Code[20]; ExpectedDescription: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", PostedDocNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetFilter("G/L Account No.", StrSubstNo('<>%1', GetReceivablesAccountFromCustomerPostingGroup(CustomerNo)));
            FindSet();
            repeat
                TestField(Description, ExpectedDescription);
            until Next() = 0;
        end;
    end;

    local procedure VerifyGLEntryForPayablesAccountDescription(PostedDocNo: Code[20]; VendorNo: Code[20]; ExpectedDescription: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", PostedDocNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("G/L Account No.", GetPayablesAccountFromVendorPostingGroup(VendorNo));
            FindFirst();
            TestField(Description, ExpectedDescription);
        end;
    end;

    local procedure VerifyGLEntriesForNotPayablesAccountsDescription(PostedDocNo: Code[20]; VendorNo: Code[20]; ExpectedDescription: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", PostedDocNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetFilter("G/L Account No.", StrSubstNo('<>%1', GetPayablesAccountFromVendorPostingGroup(VendorNo)));
            FindSet();
            repeat
                TestField(Description, ExpectedDescription);
            until Next() = 0;
        end;
    end;

    local procedure InitGSTPurchaseEntry()
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.DeleteAll();
        GSTPurchaseEntry."Entry No." := 1000;
        GSTPurchaseEntry."GST Base" := 0;
        GSTPurchaseEntry.Insert();
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageStatementDateHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        MaxPaymentTolerance: Variant;
    begin
        LibraryVariableStorage.Dequeue(MaxPaymentTolerance);
        ApplyCustomerEntries."Max. Payment Tolerance".SetValue(MaxPaymentTolerance);
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        MaxPaymentTolerance: Variant;
    begin
        LibraryVariableStorage.Dequeue(MaxPaymentTolerance);
        ApplyVendorEntries."Max. Payment Tolerance".SetValue(MaxPaymentTolerance);
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultipleModalPageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningModalPageHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        PaymentToleranceWarning.InitializeOption(1);  // Option 1 used for Payment Tolerance Accounts.
        Response := ACTION::Yes
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        DocumentNo: Variant;
        FiscalYearEndingDate: Variant;
        GenJournalTemplate: Variant;
        GenJournalBatch: Variant;
        RetainedEarningsAccount: Variant;
    begin
        LibraryVariableStorage.Dequeue(FiscalYearEndingDate);
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(RetainedEarningsAccount);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FiscalYearEndingDate);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.DocumentNo.SetValue(DocumentNo);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(RetainedEarningsAccount);
        CloseIncomeStatement.Dimensions.AssistEdit();
        CloseIncomeStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestRequestPageHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    var
        No: Variant;
        BuyFromVendorNo: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Purchase Prepmt. Doc. - Test";
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        PurchasePrepmtDocTest."Purchase Header".SetFilter("No.", No);
        PurchasePrepmtDocTest."Purchase Header".SetFilter("Buy-from Vendor No.", BuyFromVendorNo);
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        Variable: Variant;
        ExpectedMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(Variable);
        Evaluate(ExpectedMessage, Variable);
        Assert.AreEqual(ExpectedMessage, Message, MessageDoesNotMatchErr);
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AUNZStatementRequestPageHandler(var AUNZStatement: TestRequestPage "AU/NZ Statement")
    var
        CustomerNo: Variant;
        StatementStyle: Option "Open Item",Balance;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        AUNZStatement.PrintAllWithEntries.SetValue(true);
        AUNZStatement.PrintAllWithBalance.SetValue(true);
        AUNZStatement.StatementStyle.SetValue(StatementStyle::Balance);
        AUNZStatement.Customer.SetFilter("No.", CustomerNo);
        AUNZStatement.Customer.SetFilter(
          "Date Filter",
          StrSubstNo('%1..%2', Format(WorkDate()), LibraryRandom.RandDateFrom(WorkDate(), LibraryRandom.RandIntInRange(10, 100))));
        AUNZStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

