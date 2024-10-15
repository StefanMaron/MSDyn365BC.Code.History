﻿codeunit 134011 "ERM Application Vendor"
{
    // // [FEATURE] [Purchase] [Application]
    // Unsupported version tags:
    // NA: Unable to Execute
    // ES: Unable to Execute
    // DE: Unable to Execute
    // 
    // Test case covering application and un-application of all document combinations for vendors.
    // 
    // Each test is executed with stepwise application and bulk application.

    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Application]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryERMVendorWatch: Codeunit "Library - ERM Vendor Watch";
        DeltaAssert: Codeunit "Delta Assert";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        VendorAmount: Decimal;
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        WrongBalancePerTransNoErr: Label 'Wrong total amount of detailed entries per transaction.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.';

    [Test]
    [Scope('OnPrem')]
    procedure VendorNoDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorInvPmt("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorInvPmt("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                VendorInvPmt("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                VendorInvPmt("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorInvPmtDisc("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorInvPmtDisc("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                // The following two combinations do not generate discount ledger entries and will thus fail to close.
                asserterror VendorInvPmtDisc("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                DeltaAssert.Reset();
                asserterror VendorInvPmtDisc("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                DeltaAssert.Reset();
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorInvPmtVAT("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorInvPmtVAT("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                VendorInvPmtVAT("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                VendorInvPmtVAT("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorInvPmtCorrection("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorInvPmtCorrection("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                VendorInvPmtCorrection("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                VendorInvPmtCorrection("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorDiscVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorPmtDiscVATAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorPmtDiscVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
                asserterror VendorPmtDiscVATAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                asserterror VendorPmtDiscVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        SetupPaymentTolerance();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorPmtTolVATAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorPmtTolVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
                asserterror VendorPmtTolVATAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                asserterror VendorPmtTolVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorDiscTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<5D>');

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorPmtDiscTolVATAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise);
                VendorPmtDiscTolVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
                // The following two combinations do not generate payment discount / tolerance ledger entries and will thus fail to close.
                asserterror VendorPmtDiscTolVATAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise);
                asserterror VendorPmtDiscTolVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorRealizedGain()
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorRealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorRealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorRealizedAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorRealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorRealizedLoss()
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorRealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorRealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorRealizedAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorRealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
            end;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure VendorUnrealizedGain()
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorUnrealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorUnrealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorUnrealizedAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
                VendorUnrealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Gain");
            end;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure VendorUnrealizedLoss()
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do
            with GenJournalLine do begin
                VendorUnrealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorUnrealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorUnrealizedAdjust("Document Type"::Payment, "Document Type"::Refund, VendorAmount, Stepwise,
                  1.1, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
                VendorUnrealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -VendorAmount, Stepwise,
                  0.9, DtldVendorLedgEntry."Entry Type"::"Realized Loss");
            end;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure FutureCurrAdjTransaction()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        LastTransactionNo: array[2] of Integer;
        TransactionNo: Integer;
        i: Integer;
        TotalAmount: Decimal;
        InvAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates] [Transaction No.]
        // [SCENARIO] Currency Adjustment job posts Detailed Vendor Ledger Entries linked by "Transaction No." with related G/L Entries
        Initialize();

        // [GIVEN] Currency "FCY" with different rates on Workdate and on (WorkDate() + 1)
        CurrencyCode := SetExchRateForCurrency(2);

        LibraryPurchase.CreateVendor(Vendor);

        GetGLBalancedBatch(GenJournalBatch);
        for i := 1 to 3 do
            with GenJournalLine do begin
                // [GIVEN] Post Invoice in "FCY" on WorkDate
                InvAmount := LibraryRandom.RandDec(1000, 2);
                DocumentNo := CreateJournalLine(
                    GenJournalLine, GenJournalBatch, "Document Type"::Invoice, "Account Type"::Vendor,
                    Vendor."No.", -InvAmount, '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
                RunGenJnlPostLine(GenJournalLine);

                // [GIVEN] Post 1st partial Payment in "FCY" on WorkDate with application to Invoice
                CreateJournalLine(
                  GenJournalLine, GenJournalBatch, "Document Type"::Payment, "Account Type"::Vendor,
                  Vendor."No.", InvAmount / (i + 1), '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
                Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
                Validate("Applies-to Doc. No.", DocumentNo);
                Modify();
                RunGenJnlPostLine(GenJournalLine);

                // [GIVEN] Post 2nd partial Payment in "FCY" on (WorkDate() + 2) with application to Invoice
                CreateJournalLine(
                  GenJournalLine, GenJournalBatch, "Document Type"::Payment, "Account Type"::Vendor,
                  Vendor."No.", InvAmount - Amount, '<2D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
                Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
                Validate("Applies-to Doc. No.", DocumentNo);
                Modify();
                RunGenJnlPostLine(GenJournalLine);
            end;

        LastTransactionNo[1] := GetLastTransactionNo();

        // [WHEN] Run the Adjust Exchange Rates Batch job on (WorkDate() + 1)
#if not CLEAN23
        LibraryERM.RunAdjustExchangeRatesSimple(
          CurrencyCode, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
#else
        LibraryERM.RunExchRateAdjustmentSimple(
          CurrencyCode, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
#endif

        // [THEN] posted G/L Entries on different dates have different "Transaction No."
        // [THEN] Dtld. Vendor Ledger Entries have same "Transaction No." with related G/L Entries
        LastTransactionNo[2] := GetLastTransactionNo();
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        for TransactionNo := LastTransactionNo[1] + 1 to LastTransactionNo[2] do begin
            GLEntry.SetRange("Transaction No.", TransactionNo);
            GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
            GLEntry.FindLast();
            TotalAmount := 0;
            DtldVendLedgEntry.SetRange("Transaction No.", TransactionNo);
            DtldVendLedgEntry.FindSet();
            repeat
                TotalAmount += DtldVendLedgEntry."Amount (LCY)";
            until DtldVendLedgEntry.Next() = 0;
            Assert.AreEqual(GLEntry.Amount, TotalAmount, WrongBalancePerTransNoErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ApplyMultipleLedgEntriesBySetAppliesToId()
    var
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Multiple vendor ledger entries applies when call SetApplId function of codeunit "Vend. Entry-SetAppl.ID"

        Initialize();
        MockVendLedgEntry(ApplyingVendLedgerEntry);
        MockVendLedgEntry(VendLedgerEntry);
        MockVendLedgEntry(VendLedgerEntry2);
        VendLedgerEntry.SetRange("Entry No.", VendLedgerEntry."Entry No.", VendLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID();

        VendEntrySetApplID.SetApplId(VendLedgerEntry, ApplyingVendLedgerEntry, AppliesToID);

        VerifyAppliedLedgerEntry(VendLedgerEntry, AppliesToID);
        VerifyAppliedLedgerEntry(VendLedgerEntry2, AppliesToID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ClearApplicationInforForMultipleAlreadyAppliedLedgEntriesBySetAppliesToId()
    var
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Application information clears for already applied vendor ledger entries when call SetApplId function of codeunit "Vend. Entry-SetAppl.ID"

        Initialize();
        MockVendLedgEntry(ApplyingVendLedgerEntry);
        MockAppliedVendLedgEntry(VendLedgerEntry);
        MockAppliedVendLedgEntry(VendLedgerEntry2);
        VendLedgerEntry.SetRange("Entry No.", VendLedgerEntry."Entry No.", VendLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID();

        VendEntrySetApplID.SetApplId(VendLedgerEntry, ApplyingVendLedgerEntry, AppliesToID);

        VerifyUnappliedLedgerEntry(VendLedgerEntry);
        VerifyUnappliedLedgerEntry(VendLedgerEntry2);
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplyDifferentDocumentTypesToPayment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        Amount: Decimal;
    begin
        // Verify Program populates correct Document Type value on G/L entry window after doing un application on Vendor when adjust for payment discount is involved.

        // Setup: Post Invocie, Credit Memo and Payment Line.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        GetGLBalancedBatch(GenJournalBatch);

        Amount := LibraryRandom.RandDec(1000, 2);  // Using Random value for Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithPaymentTermsDiscount(), -Amount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", Amount / 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyAndPostMultipleVendorEntries(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", Amount / 2);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Exercise: Unapply Vendor Entries.
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // Verify: Verfiy Document Type should be Payment in G/L Entry.
        VerifyUnapplyGLEntry(VendorLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInvoiceCreditMemoWithPaymentDisc()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        RemainingAmount: Decimal;
    begin
        // [FEATURE] [Payment Discount]
        // [SCENARIO 364591] Application of Payment to Invoice and Credit Memo with Payment Discount
        Initialize();
        GetGLBalancedBatch(GenJournalBatch);

        // [GIVEN] Posted Purchase Invoice with Amount "X", Payment Discount Amount = "D".
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithPaymentTermsDiscount(), -Amount);

        // [GIVEN] Posted Purchase Credit Memo with Amount "Y" < "X"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", LibraryRandom.RandDecInDecimalRange(1, Amount, 2));

        // [GIVEN] Posted Payment with Amount "Z" = "X" - "Y"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", Amount - GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to both Invoice and Credit Memo
        ApplyAndPostMultipleVendorEntries(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", GenJournalLine.Amount);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");

        // [THEN] Vendor Ledger Entries for Invoice and Credit Memo are closed and "Remaining Pmt. Disc. Possible" = 0
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, false, 0, 0);
        RemainingAmount := -VendorLedgerEntry."Original Pmt. Disc. Possible";

        asserterror VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", false, 0, 0);
        Assert.KnownFailure('Open', 252156);

        // [THEN] Vendor Ledger Entries for Payment is Opened. "Remaining Amount" = "D".
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, true, 0, RemainingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCreditMemoInvoiceWithPaymentDisc()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        RemainingAmount: Decimal;
    begin
        // [FEATURE] [Payment Discount]
        // [SCENARIO 364591] Application of Refund to Credit Memo and Invoice with Payment Discount
        Initialize();
        GetGLBalancedBatch(GenJournalBatch);

        // [GIVEN] Posted Purchase Credit Memo with Amount "X", "Payment Discount Amount" = "D".
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, CreateVendorWithPaymentTermsDiscount(), Amount);

        // [GIVEN] Posted Purchase Invoice with Amount "Y" < "X"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", -LibraryRandom.RandDecInDecimalRange(1, Amount, 2));

        // [GIVEN] Posted Refund with Amount "Z" = "X" - "Y"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", -Amount - GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to both Credit Memo and Invoice
        ApplyAndPostMultipleVendorEntries(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.", GenJournalLine.Amount);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");

        // [THEN] Vendor Ledger Entries for Credit Memo and Invoice are closed and "Remaining Pmt. Disc. Possible" = 0
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", false, 0, 0);
        RemainingAmount := -VendorLedgerEntry."Original Pmt. Disc. Possible";

        asserterror VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, false, 0, 0);
        Assert.KnownFailure('Open', 252156);

        // [THEN] Vendor Ledger Entries for Refund is Opened. "Remaining Amount" = "D".
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Refund, true, 0, RemainingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageOnApplyWithoutAplliesToID()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DummyGenJournalLine: Record "Gen. Journal Line";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        Amount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 380040] During application, if there is no "Applies-to ID", then "The application could not be posted, because no entry
        // [SCENARIO] has been selected to be applied / for none of the open entries the "Applies-to ID" has been specfied." error message should appear

        Initialize();

        // [GIVEN] Vendor VVV
        // [GIVEN] Gen. Journal Batch GJB with two lines
        // [GIVEN] Gen. Journal Line JL1: an invoice for Vendor VVV with "Document No" = 123 and "Amount" = -1000
        // [GIVEN] Gen. Journal Line JL2: a payment for Vendor VVV with "Document No" = 123 (same as JL1) and "Amount" = 1000
        // [GIVEN] Batch GJB posted
        Amount := LibraryRandom.RandDec(1000, 2);
        DocNo := LibraryERM.CreateAndPostTwoGenJourLinesWithSameBalAccAndDocNo(
            DummyGenJournalLine, DummyGenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), Amount);

        // [WHEN] Apply Payment to Invoice
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Payment, DocNo);
        ApplyUnapplyParameters."Document No." := DocNo;
        ApplyUnapplyParameters."Posting Date" := WorkDate();
        asserterror VendEntryApplyPostedEntries.Apply(VendLedgerEntry, ApplyUnapplyParameters);

        // [THEN] The following message appears: Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.
        Assert.ExpectedError(NoEntriesAppliedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithNoDiscount1()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO 233340] When payment amount is not sufficient to close applied invoice and credit memo, the remaining amount is left on the last applied entry.
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 44 LCY, payment for 105 LCY.
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, VendorNo, 150, 44, 105);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 105);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 1, payment = 0.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 1, 0);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithNoDiscount2()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO 233340] When payment amount is sufficient to close applied invoice and credit memo, the remaining amount is left on the payment entry.
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 46 LCY, payment for 105 LCY.
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, VendorNo, 150, 46, 105);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 105);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 0, payment = 1.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 0, 1);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithDiscount1()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 233340] When payment amount is sufficient to close both invoice and credit memo only if the invoice has payment discount, the remaining amount is left on the payment entry. Extra payment amount < discount amount.
        Initialize();

        CreateVendorWithPaymentTerms(Vendor, CreatePaymentTerms(3.33333));

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 49 LCY, payment for 100 LCY. Payment discount for the invoice = 5 LCY (3.3333%)
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, Vendor."No.", 150, 49, 100);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 100);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 0, payment = 4.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 0, 4);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithDiscount2()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 233340] When payment amount is sufficient to close both invoice and credit memo only if the invoice has payment discount, the remaining amount is left on the payment entry. Extra payment amount > discount amount.
        Initialize();

        CreateVendorWithPaymentTerms(Vendor, CreatePaymentTerms(3.33333));

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 51 LCY, payment for 100 LCY. Payment discount for the invoice = 5 LCY (3.3333%)
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, Vendor."No.", 150, 51, 100);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 100);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 0, payment = 6.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 0, 6);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithDiscount3()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 233340] When payment amount is not sufficient to close both invoice and credit memo even with a payment discount on the invoice, the remaining amount is left on the last applied entry.
        Initialize();

        CreateVendorWithPaymentTerms(Vendor, CreatePaymentTerms(3.33333));

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 44 LCY, payment for 100 LCY. Payment discount for the invoice = 5 LCY (3.3333%)
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, Vendor."No.", 150, 44, 100);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 100);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 1, payment = 0.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 1, 0);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingPaymentToBothInvoiceAndCrMemoWithDiscount4()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 233340] When payment amount is sufficient to close both invoice and credit memo only if the invoice has payment discount, the remaining amount is left on the payment entry.
        Initialize();

        CreateVendorWithPaymentTerms(Vendor, CreatePaymentTerms(3.33333));

        // [GIVEN] Post invoice for 150 LCY, credit-memo for 46 LCY, payment for 100 LCY. Payment discount for the invoice = 5 LCY (3.3333%)
        CreateAndPostInvoiceCrMemoAndPayment(GenJournalLine, Vendor."No.", 150, 46, 100);

        // [WHEN] Apply payment to both invoice and credit-memo.
        ApplyAndPostMultipleVendorEntries(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", 100);

        // [THEN] Remaining amount: invoice = 0, credit-memo = 0, payment = 1.
        asserterror VerifyInvoiceCrMemoAndPaymentRemAmounts(GenJournalLine."Document No.", 0, 0, 1);
        Assert.KnownFailure('Remaining Amount must be equal to ''0''  in Vendor Ledger Entry', 252156);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTwoInvoiceSetAppliesToIdFromGeneralJournal()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 342909] System clean "Applies-to ID" field in vendor ledger entry when it is generated from general journal line applied to vendor ledger entry
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        InvoiceAmount := -LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount := -InvoiceAmount * 3;

        // Invoice 1
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Invoice 2
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Payment 1 with false "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaymentAmount);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Applies-to ID", '');

        // Payment 2 with true "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaymentAmount);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        VendorLedgerEntry.ModifyAll("Applies-to ID", GenJournalLine."Document No.");

        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField(Open, false);
        until VendorLedgerEntry.Next() = 0;
        Assert.RecordCount(VendorLedgerEntry, 2);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,PostApplicationModalPageHandler,MessageHandler')]
    procedure TwoPaymentTwoInvoiceSetAppliesToIdFromGeneralJournal()
    var
        Vendor: Record Vendor;
        GenJournalLineInvoice: array[2] of Record "Gen. Journal Line";
        GenJournalLinePayment: array[2] of Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        InvoiceAmount: array[2] of Decimal;
        PaymentAmount: array[2] of Decimal;
        AppliesToId: Code[20];
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 342909] System clean "Applies-to ID" field in vendor ledger entry when it is generated from general journal line applied to customer ledger entry
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        InvoiceAmount[1] := -LibraryRandom.RandIntInRange(10, 20);
        InvoiceAmount[2] := -LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount[1] := -(InvoiceAmount[1] + InvoiceAmount[2]) * 3;
        PaymentAmount[2] := -InvoiceAmount[2];

        // [GIVEN] Posted Invoice "B"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLineInvoice[2], GenJournalLineInvoice[2]."Document Type"::Invoice, GenJournalLineInvoice[2]."Account Type"::Vendor, Vendor."No.", InvoiceAmount[2]);
        GenJournalLineInvoice[2].Validate("Posting Date", WorkDate() + 1);
        GenJournalLineInvoice[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice[2]);

        // [GIVEN] Posted Payment "A"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLinePayment[1], GenJournalLinePayment[1]."Document Type"::Payment, GenJournalLinePayment[1]."Account Type"::Vendor, Vendor."No.", PaymentAmount[1]);
        GenJournalLinePayment[1].Validate("Posting Date", WorkDate() - 1);
        GenJournalLinePayment[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment[1]);

        // [GIVEN] Posted Payment "A" applied to Invoice "B" with "Applies-to ID", but not posted
        LibraryVariableStorage.Enqueue(GenJournalLineInvoice[2]."Document No.");
        LibraryVariableStorage.Enqueue(false);

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.Filter.SetFilter("Vendor No.", Vendor."No.");
        VendorLedgerEntries.Filter.SetFilter("Document No.", GenJournalLinePayment[1]."Document No.");
        VendorLedgerEntries.ActionApplyEntries.Invoke();
        VendorLedgerEntries.Close();

        AppliesToId := LibraryUtility.GenerateGUID();
        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Applies-to ID", UserId());
        VendorLedgerEntry.ModifyAll("Applies-to ID", AppliesToId);

        // [GIVEN] Payment "B" applied to Invoice "B" with "Applies-to Doc. No." and posted
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLinePayment[2], GenJournalLinePayment[2]."Document Type"::Payment, GenJournalLinePayment[2]."Account Type"::Vendor, Vendor."No.", PaymentAmount[2]);
        GenJournalLinePayment[2].Validate("Posting Date", WorkDate() + 1);
        GenJournalLinePayment[2].Validate("Applies-to Doc. Type", GenJournalLinePayment[2]."Applies-to Doc. Type"::Invoice);
        GenJournalLinePayment[2].Validate("Applies-to Doc. No.", GenJournalLineInvoice[2]."Document No.");
        GenJournalLinePayment[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment[2]);

        // [GIVEN] Posting engine cleared "Applies-to ID" and "Applies-to Doc. No." on applied customer ledger entry of Invoice "B"
        VerifyBlankAppliestoID(Vendor."No.", GenJournalLineInvoice[2]."Document No.", VendorLedgerEntry."Document Type"::Invoice);

        // [GIVEN] Posted Invoice "A"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLineInvoice[1], GenJournalLineInvoice[1]."Document Type"::Invoice, GenJournalLineInvoice[1]."Account Type"::Vendor, Vendor."No.", InvoiceAmount[1]);
        GenJournalLineInvoice[1].Validate("Posting Date", WorkDate() - 1);
        GenJournalLineInvoice[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice[1]);

        // [GIVEN] Posted Payment "A" applied to Posted Invoice "A" with "Applies-to ID."
        AppliesToId := LibraryUtility.GenerateGUID();
        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Applies-to ID", AppliesToId);
        VendorLedgerEntry.ModifyAll("Applies-to ID", UserId());

        LibraryVariableStorage.Enqueue(GenJournalLineInvoice[1]."Document No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(WorkDate() - 1);

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.Filter.SetFilter("Vendor No.", Vendor."No.");
        VendorLedgerEntries.Filter.SetFilter("Document No.", GenJournalLinePayment[1]."Document No.");

        // [WHEN] Stan posts 
        VendorLedgerEntries.ActionApplyEntries.Invoke();

        // [GIVEN] Applied documents posted and posting engine cleared "Applies-to ID" and "Applies-to Doc. No." on applied customer ledger entry of Invoice "A"
        VerifyBlankAppliestoID(Vendor."No.", GenJournalLineInvoice[1]."Document No.", VendorLedgerEntry."Document Type"::Invoice);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ApplyVendorEntriesTwiceModalPageHandler')]
    procedure ThreeInvoicesAndApplyEntries()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: array[3] of Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        Index: Integer;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 411946] "Applies-to ID" must be cleared on applying entry when the mark is removed from applied entries.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        for Index := 1 to ArrayLen(VendorLedgerEntry) do begin
            Clear(GenJournalLine);
            LibraryJournals.CreateGenJournalLineWithBatch(
                GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine.Validate("Posting Date", WorkDate() + 1);
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            VendorLedgerEntry[Index].SetRange("Vendor No.", Vendor."No.");
            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry[Index], VendorLedgerEntry[Index]."Document Type"::Invoice, GenJournalLine."Document No.");
        end;

        LibraryVariableStorage.Enqueue(VendorLedgerEntry[2]."Document No.");

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.Filter.SetFilter("Vendor No.", Vendor."No.");
        VendorLedgerEntries.Filter.SetFilter("Document No.", VendorLedgerEntry[1]."Document No.");
        VendorLedgerEntries.ActionApplyEntries.Invoke(); // set and remove Applies-to ID mark on 2nd invoice (on page handler)
        VendorLedgerEntries.Close();

        VendorLedgerEntry[1].Find();
        VendorLedgerEntry[1].TestField("Applies-to ID", '');

        VendorLedgerEntry[2].Find();
        VendorLedgerEntry[2].TestField("Applies-to ID", '');

        VendorLedgerEntry[3].Find();
        VendorLedgerEntry[3].TestField("Applies-to ID", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        VendorAmount := 1000;  // Use a fixed amount to avoid rounding issues.
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure ApplyAndPostMultipleVendorEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        GLRegister: Record "G/L Register";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SetApplyVendorEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo, AmountToApply);
        GLRegister.FindLast();
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendorLedgerEntry);
    end;

    local procedure CreateAndPostInvoiceCrMemoAndPayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; InvoiceAmt: Decimal; CrMemoAmt: Decimal; PaymentAmt: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGLBalancedBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -InvoiceAmt);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendorNo, CrMemoAmt);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, PaymentAmt);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VendorRealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('0'));

        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rate
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesEqual(Vendor."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, PmtAmount, InvAmount, '<0D>', '', Currency.Code);

        // Adjust the currency exchange rate of the document currency to trigger realized gain/loss
        CurrencyExchangeRate."Relational Exch. Rate Amount" *= CurrencyAdjustFactor;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" *= CurrencyAdjustFactor;
        CurrencyExchangeRate.Modify(true);

        VendorApplyUnapply(Desc, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorUnrealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('0'));

        Currency.Get(SetExchRateForCurrency(CurrencyAdjustFactor));

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesEqual(Vendor."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, PmtAmount, InvAmount, '<1D>', '', Currency.Code);

        // Run the Adjust Exchange Rates Batch job.
#if not CLEAN23
        LibraryERM.RunAdjustExchangeRatesSimple(
            Currency.Code, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
#else
        LibraryERM.RunExchRateAdjustmentSimple(
            Currency.Code, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
#endif

        VendorApplyUnapply(Desc, Stepwise);

        asserterror LibraryERMVendorWatch.AssertVendor(); // NAVCZ
    end;

    local procedure VendorPmtDiscVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Vendor: Record Vendor;
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('>0'));

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount (VAT Adjustment)", 0);
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount (VAT Excl.)", 0);
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount", 0);

        // Apply / Unapply with VAT posting setup
        VendorApplyUnapplyVAT(Vendor, PmtType, InvType, Amount - GetDiscount(Vendor."Payment Terms Code", Amount), Amount, '<0D>', Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorPmtTolVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application that triggers payment tolerance

        // Find none discounted payment terms
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);

        // Watch for detailed ledger entry type "Payment Tolerance (VAT Adjustment)" and "Payment Tolerance (VAT Excl.)"
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesGreaterThan(
          Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Tolerance (VAT Adjustment)", 0);
        LibraryERMVendorWatch.DtldEntriesGreaterThan(
          Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Tolerance (VAT Excl.)", 0);
        LibraryERMVendorWatch.DtldEntriesGreaterThan(
          Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Tolerance", 0);

        // Apply / Unapply with VAT posting setup
        VendorApplyUnapplyVAT(Vendor, PmtType, InvType, Amount - GetPaymentTolerance(), Amount, '<0D>', Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorPmtDiscTolVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Vendor: Record Vendor;
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PaymentTerms: Record "Payment Terms";
        Offset: Text[30];
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        PaymentTerms.Get(GetPaymentTerms('>0'));
        CreateVendorWithPaymentTerms(Vendor, PaymentTerms.Code);

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)", 0);
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Excl.)", 0);
        LibraryERMVendorWatch.DtldEntriesSigned(
          Amount, Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount Tolerance", 0);

        // Trigger payment discount tolerance by exceeding discount due date by 1 day
        Offset := Format(PaymentTerms."Discount Date Calculation") + '+<1D>';

        // Apply / Unapply with VAT posting setup
        VendorApplyUnapplyVAT(Vendor, PmtType, InvType, Amount - GetDiscount(PaymentTerms.Code, Amount), Amount, Offset, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorInvPmt(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Desc: Text[30];
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('0'));

        // Setup basic application watches
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.EntriesEqual(Vendor."No.", InvType.AsInteger(), -Amount);
        LibraryERMVendorWatch.EntriesEqual(Vendor."No.", PmtType.AsInteger(), Amount);
        LibraryERMVendorWatch.DtldEntriesEqual(Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMVendorWatch.DtldEntriesGreaterThan(Vendor."No.", DtldVendorLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers application dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        VendorApplyUnapply(Desc, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorInvPmtDisc(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DiscountAmount: Decimal;
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('>0'));
        DiscountAmount := GetDiscount(Vendor."Payment Terms Code", Amount);

        // Watch for "Payment Discount" detailed ledger entries.
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.DtldEntriesEqual(Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Payment Discount", DiscountAmount);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, Amount - DiscountAmount, Amount, '<0D>', '', '');
        VendorApplyUnapply(Desc, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorInvPmtVAT(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Desc: Text[30];
    begin
        // Test with VAT

        // Find a VAT setup that has a balancing account with direct posting
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalBatch, GLAccount);

        // Find a vendor (or modify) with the correct VAT posting group setup and no discount
        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Payment Terms Code", GetPaymentTerms('0'));
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);

        // Try out vendor watch
        LibraryERMVendorWatch.Init();
        LibraryERMVendorWatch.EntriesEqual(Vendor."No.", InvType.AsInteger(), -Amount);
        LibraryERMVendorWatch.EntriesEqual(Vendor."No.", PmtType.AsInteger(), Amount);
        LibraryERMVendorWatch.DtldEntriesEqual(Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMVendorWatch.DtldEntriesGreaterThan(Vendor."No.", DtldVendorLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        VendorApplyUnapply(Desc, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorInvPmtCorrection(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GLAccount: Record "G/L Account";
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('0'));

        // Create a currency code with magic exchange rate valid for Amount = 1000
        LibraryERM.CreateCurrency(Currency);
        // NAVCZ
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Validate("Realized Losses Acc.", GLAccount."No.");
        Currency.Modify(true);
        // NAVCZ
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 64.580459);  // Magic exchange rate
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        // Watch for "Correction of Remaining Amount" detailed ledger entries.
        LibraryERMVendorWatch.Init();
        if Stepwise then // NAVCZ
            LibraryERMVendorWatch.DtldEntriesGreaterThan(Vendor."No.", DtldVendorLedgEntry."Entry Type"::"Correction of Remaining Amount", 0);

        // Generate a document that triggers "Correction of Remaining Amount" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, Amount, Amount, '<0D>', Currency.Code, Currency.Code);
        VendorApplyUnapply(Desc, Stepwise);

        LibraryERMVendorWatch.AssertVendor();
    end;

    local procedure VendorApplyUnapplyVAT(Vendor: Record Vendor; PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; Stepwise: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        Desc: Text[30];
    begin
        // Setup payment tolerance on payment discount
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // Find a VAT setup that has a balancing account with direct posting and update it
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalBatch, GLAccount);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // Update General Posting Setup
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        // Update Vendor to our needs
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);

        // Generate a document that triggers "Payment Tolerance (VAT Adjustment)" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Vendor, PmtType, InvType, PmtAmount, InvAmount, PmtOffset, '', '');
        VendorApplyUnapply(Desc, Stepwise);
    end;

    local procedure VendorApplyUnapply(Desc: Text[30]; Stepwise: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange(Description, Desc);
        Assert.AreEqual(VendorLedgerEntry.Count, 4, 'Expected to find exactly 4 vendor ledger entries!');

        // Exercise #1. Apply entries.
        PostVendorApplication(VendorLedgerEntry, Stepwise);

        // Verify #1.
        VerifyVendorEntriesClosed(VendorLedgerEntry);

        // Exercise #2. Unapply entries.
        PostVendorUnapply(VendorLedgerEntry, Stepwise);

        // Verify #2.
        VerifyVendorEntriesOpen(VendorLedgerEntry);

        // Exercise #3. Apply entries.
        PostVendorApplication(VendorLedgerEntry, Stepwise);

        // Verify #3.
        VerifyVendorEntriesClosed(VendorLedgerEntry);
    end;

    local procedure SetupPaymentTolerance()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", 1.0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 5.0);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GenerateDocument(GenJournalBatch: Record "Gen. Journal Batch"; Vendor: Record Vendor; PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; PmtCurrencyCode: Code[10]; InvCurrencyCode: Code[10]): Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Desc: Text[30];
    begin
        ClearJournalBatch(GenJournalBatch);

        // Create four documents with seperate document no. and external document no. but with unique description.
        with GenJournalLine do begin
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Vendor,
                Vendor."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, DocumentNo, '');
            Desc := DocumentNo;
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Vendor,
                Vendor."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Vendor,
                Vendor."No.", PmtAmount / 2, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, InvType, "Account Type"::Vendor,
                Vendor."No.", -InvAmount, '<0D>', InvCurrencyCode, IncStr(DocumentNo), Desc);
        end;

        PostJournalBatch(GenJournalBatch);
        exit(Desc);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PmtOffset: Text[30]; CurrencyCode: Code[10]; DocNo: Code[20]; Description: Text[30]): Code[20]
    var
        DateOffset: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        Evaluate(DateOffset, PmtOffset);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", CalcDate(DateOffset, WorkDate()));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");

        // Update document number and description if specified
        if DocNo <> '' then
            GenJournalLine."Document No." := DocNo;
        if Description <> '' then
            GenJournalLine.Description := Description;

        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll();
    end;

    local procedure MockVendLedgEntry(var VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        with VendLedgerEntry do begin
            Init();
            "Entry No." :=
              LibraryUtility.GetNewRecNo(VendLedgerEntry, FieldNo("Entry No."));
            Open := true;
            Insert();
            MockDtldLedgEntry("Entry No.");
        end;
    end;

    local procedure MockDtldLedgEntry(VendLedgEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            Init();
            "Entry No." :=
              LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, FieldNo("Entry No."));
            "Vendor Ledger Entry No." := VendLedgEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            Amount := LibraryRandom.RandDec(100, 2);
            Insert();
        end;
    end;

    local procedure MockAppliedVendLedgEntry(var VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        with VendLedgerEntry do begin
            MockVendLedgEntry(VendLedgerEntry);
            "Amount to Apply" := LibraryRandom.RandDec(100, 2);
            "Applies-to ID" := LibraryUtility.GenerateGUID();
            "Accepted Pmt. Disc. Tolerance" := true;
            "Accepted Payment Tolerance" := LibraryRandom.RandDec(100, 2);
            Modify();
        end;
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostVendorApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostVendorApplicationStepwise(VendorLedgerEntry)
        else
            PostVendorApplicationOneGo(VendorLedgerEntry);
    end;

    local procedure PostVendorApplicationOneGo(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        // The first entry is the applying entry.
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry.Amount);

        // Apply to all other entries.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // Call Apply codeunit.
        VendorLedgerEntry.FindFirst();
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure PostVendorApplicationStepwise(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        i: Integer;
    begin
        // The first entry is the applying entry.
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry2.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
        VendorLedgerEntry2.FindFirst();

        VendorLedgerEntry.FindFirst();
        for i := 1 to VendorLedgerEntry.Count - 1 do begin
            VendorLedgerEntry.CalcFields(Amount);
            LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry.Amount);

            // Apply to last entry.
            LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);

            // Post application.
            LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

            VendorLedgerEntry.Next();
        end;
    end;

    local procedure PostVendorUnapply(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostVendorUnapplyStepwise(VendorLedgerEntry)
        else
            PostVendorUnapplyOneGo(VendorLedgerEntry);
    end;

    local procedure PostVendorUnapplyOneGo(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DtldVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        DtldVendorLedgEntry.Get(FindLastApplEntry(VendorLedgerEntry."Entry No."));

        DtldVendorLedgEntry2.SetRange("Transaction No.", DtldVendorLedgEntry."Transaction No.");
        DtldVendorLedgEntry2.SetRange("Vendor No.", DtldVendorLedgEntry."Vendor No.");
        DtldVendorLedgEntry2.FindFirst();

        ApplyUnapplyParameters."Document No." := VendorLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DtldVendorLedgEntry."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DtldVendorLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure PostVendorUnapplyStepwise(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        i: Integer;
    begin
        VendorLedgerEntry.FindLast();

        for i := 1 to VendorLedgerEntry.Count - 1 do begin
            // Unapply in reverse order.
            VendorLedgerEntry.Next(-1);
            PostVendorUnapplyOneGo(VendorLedgerEntry);
        end;
    end;

    local procedure SetApplyVendorEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountToApply: Decimal)
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
    end;

    local procedure SetExchRateForCurrency(CurrencyAdjustFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rates
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100);
        CurrencyExchangeRate.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, CalcDate('<1D>', WorkDate()));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure GetDirectVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var GLAccount: Record "G/L Account"; VATFilter: Text[30])
    begin
        VATPostingSetup.SetFilter("VAT %", VATFilter);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindSet();
        repeat
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
            GLAccount.SetFilter("Gen. Bus. Posting Group", '<>''''');
            GLAccount.SetFilter("Gen. Prod. Posting Group", '<>''''');
            GLAccount.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            GLAccount.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GLAccount.SetRange("Direct Posting", true);
        until (VATPostingSetup.Next() = 0) or GLAccount.FindFirst();

        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetPaymentTerms(DiscountFilter: Text[30]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Reset();
        PaymentTerms.SetFilter("Discount %", DiscountFilter);
        PaymentTerms.FindFirst();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := true;
        PaymentTerms.Modify(true);

        exit(PaymentTerms.Code);
    end;

    local procedure CreatePaymentTerms(DiscountPercent: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Modify(true);

        exit(PaymentTerms.Code);
    end;

    local procedure CreateVendorWithPaymentTerms(var Vendor: Record Vendor; PaymentTerms: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTermsDiscount(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendorWithPaymentTerms(Vendor, GetPaymentTerms('>0'));
        exit(Vendor."No.");
    end;

    local procedure GetGLBalancedBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        // Find template type.
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        // Find a GL balanced batch.
        GenJnlBatch.SetRange("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"G/L Account");
        GenJnlBatch.SetFilter("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.SetRange("Bal. Account No.");
        GenJnlBatch.FindFirst();
        GenJnlBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlBatch.Modify(true);

        ClearJournalBatch(GenJnlBatch);
    end;

    local procedure GetVATBalancedBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account")
    begin
        with GenJournalBatch do begin
            SetRange("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            SetRange("Bal. Account No.", GLAccount."No.");
            if not FindFirst() then begin
                GetGLBalancedBatch(GenJournalBatch);
                Name := 'VendorVAT';
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := GLAccount."No.";
                Insert(true);
            end;
        end;
    end;

    local procedure GetPaymentTolerance(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    local procedure GetDiscount(PmtTerms: Code[10]; Amount: Decimal): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PmtTerms);
        exit(Amount * PaymentTerms."Discount %" / 100);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure VerifyInvoiceCrMemoAndPaymentRemAmounts(DocumentNo: Code[20]; InvoiceRemAmt: Decimal; CrMemoRemAmt: Decimal; PaymentRemAmt: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VerifyVendorLedgEntryRemAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo, InvoiceRemAmt);
        VerifyVendorLedgEntryRemAmount(VendorLedgerEntry."Document Type"::"Credit Memo", DocumentNo, CrMemoRemAmt);
        VerifyVendorLedgEntryRemAmount(VendorLedgerEntry."Document Type"::Payment, DocumentNo, PaymentRemAmt);
    end;

    local procedure VerifyVendorEntriesClosed(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        with VendorLedgerEntry do begin
            FindFirst();
            repeat
                Assert.IsFalse(Open, StrSubstNo('Vendor ledger entry %1 did not close.', "Entry No."));
            until Next() = 0;
        end;
    end;

    local procedure VerifyVendorEntriesOpen(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        with VendorLedgerEntry do begin
            FindFirst();
            repeat
                Assert.IsTrue(Open, StrSubstNo('Vendor ledger entry %1 did not open.', "Entry No."));
            until Next() = 0;
        end;
    end;

    local procedure VerifyAppliedLedgerEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    begin
        VendLedgerEntry.Find();
        VendLedgerEntry.CalcFields("Remaining Amount");
        VendLedgerEntry.TestField("Applies-to ID", AppliesToID);
        VendLedgerEntry.TestField("Amount to Apply", VendLedgerEntry."Remaining Amount");
    end;

    local procedure VerifyVendorLedgEntryRemAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; RemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", RemAmount);
    end;

    local procedure VerifyUnappliedLedgerEntry(VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Applies-to ID", '');
        VendLedgerEntry.TestField("Amount to Apply", 0);
        VendLedgerEntry.TestField("Accepted Payment Tolerance", 0);
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    local procedure VerifyUnapplyGLEntry(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        GLEntry.SetRange("Source Code", SourceCodeSetup."Unapplied Purch. Entry Appln.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Document Type", GLEntry."Document Type"::Payment);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyVLEPaymentDisc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; VendLedgerEntryIsOpen: Boolean; RemPaymentDiscPossible: Decimal; RemainingAmount: Decimal)
    begin
        with VendorLedgerEntry do begin
            SetRange("Document Type", DocType);
            FindFirst();
            Assert.AreEqual(VendLedgerEntryIsOpen, Open, FieldCaption(Open));
            Assert.AreEqual(
              RemPaymentDiscPossible, "Remaining Pmt. Disc. Possible",
              FieldCaption("Remaining Pmt. Disc. Possible"));
            CalcFields("Remaining Amount");
            Assert.AreEqual(RemainingAmount, "Remaining Amount", FieldCaption("Remaining Amount"));
        end;
    end;

    local procedure VerifyBlankAppliestoID(VendorNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField(Open, false);
            VendorLedgerEntry.TestField("Applies-to ID", '');
            VendorLedgerEntry.TestField("Applies-to Doc. No.", '');
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure FindLastApplEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendorLedgEntry.SetRange("Entry Type", DtldVendorLedgEntry."Entry Type"::Application);
        ApplicationEntryNo := 0;
        if DtldVendorLedgEntry.Find('-') then
            repeat
                if (DtldVendorLedgEntry."Entry No." > ApplicationEntryNo) and not DtldVendorLedgEntry.Unapplied then
                    ApplicationEntryNo := DtldVendorLedgEntry."Entry No.";
            until DtldVendorLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.Filter.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        if (LibraryVariableStorage.DequeueBoolean()) then
            ApplyVendorEntries.ActionPostApplication.Invoke()
        else
            ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesTwiceModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.Filter.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.DocNo.SetValue(LibraryVariableStorage.DequeueText());
        PostApplication.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;
}

