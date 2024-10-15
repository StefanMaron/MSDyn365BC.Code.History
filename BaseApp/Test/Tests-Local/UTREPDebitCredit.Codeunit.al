codeunit 144040 "UT REP Debit Credit"
{
    //  1. Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Bal with Show Amounts In LCY as True.
    //  2. Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Bal with Show Amounts In LCY as False.
    //  3. Purpose of the test is to validate Detailed Cust. Ledg. Entry2 - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Bal with Debit Application Rounding.
    //  4. Purpose of the test is to validate Detailed Cust. Ledg. Entry2 - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Bal with Credit Application Rounding.
    //  5. Purpose of the test is to validate G/L Entry - OnPreDataItem Trigger of Report - 3 G/L Register.
    //  6. Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 7 Trial Balance Previous Year.
    //  7. Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 304  Vendor Detail Trial Balance when Show Amts In LCY is TRUE.
    //  8. Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 304  Vendor Detail Trial Balance when Show Amts In LCY is FALSE.
    //  9. Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 2 General Journal - Test with positive Amount.
    // 10. Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 2 General Journal - Test with negative Amount.
    // 11. Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book with Show Amounts In Add Currency as FALSE.
    // 12. Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book with Show Amounts In Add Currency as TRUE.
    // 13. Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for multiple Fiscal Years.
    // 14. Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for Period Starting Date error.
    // 15. Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for Period Ending Date error.
    // 16. Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with G/L Account Type Posting.
    // 17. Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with G/L Account Type Heading.
    // 18. Purpose of the test is to validate Integer - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with Show Amounts in Additional Currency.
    // 19. Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with Initial Date error.
    // 20. Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with End Period Date error.
    // 
    // Covers Test Cases for WI - 351317
    // -------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecLedgEntryShowAmtsInLCYTrueCustDtlTrialBal, OnAfterGetRecLedgEntryShowAmtsInLCYFalseCustDtlTrialBal
    // OnAfterGetRecLedgEntryTwoDebitApplnRndgCustDtlTrialBal, OnAfterGetRecDtldLedgEntryTwoCrApplnRndgCustDtlTrialBal         152147,152467
    // OnPreDataItemGLEntryGLRegister                                                                                                 151228
    // OnAfterGetRecordGLAccountTrialBalancePreviousYear                                                                       151080,219661
    // OnAfterGetRecLedgEntryShowAmtsInLCYTrueVendDtlTrialBal, OnAfterGetRecLedgEntryShowAmtsInLCYFalseVendDtlTrialBal                151061
    // OnAfterGetRecGenJournaLinePosAmtGeneralJournalTest, OnAfterGetRecGenJournaLineNegAmtGeneralJournalTest                         151227
    // 
    // Covers Test Cases for WI - 351315
    // -------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------
    // OnPreDataItemIntShowAmtsInAddCurrFalseOffAccSumBook, OnPreDataItemIntShowAmtsInAddCurrTrueOffAccSumBook
    // OnPreDataItemIntFiscYearOffAccSummarizedBookErr, OnPreDataItemIntStartingDateOffAccSummarizedBookErr
    // OnPreDataItemIntEndingDateOffAccSummarizedBookErr                                                                       152144,152145
    // 
    // Covers Test Cases for WI - 352075
    // -------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecGLAccountAccTypePostingMainAccBook, OnAfterGetRecGLAccountAccTypeHeadingMainAccBook
    // OnAfterGetRecordIntegerMainAccountingBook, OnAfterGetRecGLAccountInitialDateMainAccBookErr
    // OnAfterGetRecGLAccountEndPeriodDateMainAccBookErr                                                                              151206

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AllAmountsInCurrencyCap: Label 'All Amounts in %1';
        CreditAmtGLEntryCap: Label 'DebitAmt_GLEntry';
        CreditAmtLCYCap: Label 'CreditAmtLCY';
        CustCreditCap: Label 'CustCreditAmount';
        CustDebitCap: Label 'CustDebitAmount';
        DateFilterTxt: Label '%1..%2';
        DebitAmtGLEntryCap: Label 'DebitAmt_GLEntry';
        DebitAmtLCYCap: Label 'DebitAmtLCY';
        DialogErr: Label 'Dialog';
        ErrorTxt: Label 'ErrorTextNumber';
        FiscalYearCreditBalanceCap: Label 'FiscalYearCreditBalance';
        FiscalYearCreditChangeCap: Label 'FiscalYearCreditChange';
        FiscalYearDebitBalanceCap: Label 'FiscalYearDebitBalance';
        FiscalYearDebitChangeCap: Label 'FiscalYearDebitChange';
        HeaderTextCap: Label 'HeaderText';
        StartVendCreditAmountTotalCap: Label 'StartVendCreditAmtTotal';
        StartVendDebitAmountTotalCap: Label 'StartVendDebitAmtTotal';
        TotalCreditHeadCap: Label 'TotalCreditHead';
        TotalDebitHeadCap: Label 'TotalDebitHead';
        TransactionOutOfBalanceErr: Label 'Transaction %1 is out of balance by %2.';
        VendCreditAmtCap: Label 'VendCreditAmt';
        VendDebitAmtCap: Label 'VendDebitAmt';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecLedgEntryShowAmtsInLCYTrueCustDtlTrialBal()
    var
        AmountLCY: Decimal;
    begin
        // [SCENARIO] Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Balance with Show Amounts In LCY as True.
        Initialize();
        AmountLCY := LibraryRandom.RandDec(100, 2);
        CustomerDetailTrialBalanceReportWithShowAmtsInLCY(true, LibraryRandom.RandDec(100, 2), AmountLCY, AmountLCY);  // Using TRUE for ShowAmtsInLCY and random value for Amount.
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecLedgEntryShowAmtsInLCYFalseCustDtlTrialBal()
    var
        Amount: Decimal;
    begin
        // [SCENARIO] Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 104 Customer - Detail Trial Balance with Show Amounts In LCY as False.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        CustomerDetailTrialBalanceReportWithShowAmtsInLCY(false, Amount, LibraryRandom.RandDec(100, 2), 0); // Using FALSE for ShowAmtsInLCY and random value for AmountLCY.
    end;

    local procedure CustomerDetailTrialBalanceReportWithShowAmtsInLCY(ShowAmtsInLCY: Boolean; Amount: Decimal; AmountLCY: Decimal; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [GIVEN] Customer Ledger Entry and Detailed Customer Ledger Entry.
        CreateCustomerLedgerEntries(
          CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount", Amount, AmountLCY);
        EnqueueValuesForRequestPageHandler(CustLedgerEntry."Customer No.", ShowAmtsInLCY);  // Enqueue for CustomerDetailTrialBalRequestPageHandler.
        CustLedgerEntry.CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // [WHEN] Running report "Customer - Detail Trial Bal."
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.");  // Opens CustomerDetailTrialBalRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(CustDebitCap, CustCreditCap, ExpectedAmount, 0);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLEntryGLRegister()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Entry - OnPreDataItem Trigger of Report - 3 G/L Register.

        // [GIVEN] G/L Entry
        Initialize();
        CreateGLEntry(GLEntry, '', '', '', WorkDate());  // Using blank for GLAccountNo,GlobalDimensionOneCode and GlobalDimensionTwoCode and WORKDATE for Posting Date.
        LibraryVariableStorage.Enqueue(GLEntry."Transaction No.");  // Enqueue for GLRegisterRequestPageHandler.

        // [WHEN] Running report "G/L Register"
        REPORT.Run(REPORT::"G/L Register");  // Opens GLRegisterRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(CreditAmtGLEntryCap, DebitAmtGLEntryCap, GLEntry."Credit Amount", GLEntry."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountTrialBalancePreviousYear()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 7 Trial Balance Previous Year.

        // [GIVEN] Two GL Entries with different Posting Dates.
        Initialize();
        CreateGLAccount(GLAccount, LibraryUTUtility.GetNewCode(), GLAccount."Account Type"::Posting, '');  // Blank used for Totaling.
        CreateGLEntry(GLEntry, GLAccount."No.", GLAccount."Global Dimension 1 Code", GLAccount."Global Dimension 2 Code", WorkDate());  // Using WORKDATE for Posting Date.
        CreateGLEntry(
          GLEntry2, GLEntry."G/L Account No.", GLAccount."Global Dimension 1 Code", GLAccount."Global Dimension 2 Code",
          CalcDate('<-1Y>', WorkDate()));  // Using 1Y as required for the test case.
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");  // Enqueue for TrialBalancePreviousYearRequestPageHandler.

        // [WHEN] Running report "Trial Balance/Previous Year"
        REPORT.Run(REPORT::"Trial Balance/Previous Year");  // Opens TrialBalancePreviousYearRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(FiscalYearDebitChangeCap, FiscalYearCreditChangeCap, GLEntry."Debit Amount", GLEntry."Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists(FiscalYearDebitBalanceCap, GLEntry."Debit Amount" + GLEntry2."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(FiscalYearCreditBalanceCap, GLEntry."Credit Amount" + GLEntry2."Credit Amount");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecLedgEntryShowAmtsInLCYTrueVendDtlTrialBal()
    var
        AmountLCY: Decimal;
    begin
        // [SCENARIO] Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 304  Vendor Detail Trial Balance when Show Amts In LCY is TRUE.
        Initialize();
        AmountLCY := LibraryRandom.RandDec(100, 2);
        VendorDetailTrialBalanceReport(true, LibraryRandom.RandDec(100, 2), AmountLCY, AmountLCY);  // Using TRUE for ShowAmtsInLCY and random for Amount.
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecLedgEntryShowAmtsInLCYFalseVendDtlTrialBal()
    var
        Amount: Decimal;
    begin
        // [SCENARIO] Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 304  Vendor Detail Trial Balance when Show Amts In LCY is FALSE.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        VendorDetailTrialBalanceReport(false, Amount, LibraryRandom.RandDec(100, 2), Amount);  // Using FALSE for ShowAmtsInLCY and random for AmountLCY.
    end;

    local procedure VendorDetailTrialBalanceReport(ShowAmtsInLCY: Boolean; Amount: Decimal; AmountLCY: Decimal; ExpectedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [GIVEN] Vendor Ledger Entry and Detailed Vendor Ledger Entry.
        CreateVendorLedgerEntries(VendorLedgerEntry, Amount, AmountLCY);
        EnqueueValuesForRequestPageHandler(VendorLedgerEntry."Vendor No.", ShowAmtsInLCY);  // Enqueue for VendorDetailTrialBalanceRequestPageHandler.
        VendorLedgerEntry.CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // [WHEN] Running report "Vendor - Detail Trial Balance"
        REPORT.Run(REPORT::"Vendor - Detail Trial Balance");  // Opens VendorDetailTrialBalanceRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(VendDebitAmtCap, VendCreditAmtCap, ExpectedAmount, ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(StartVendCreditAmountTotalCap, VendorLedgerEntry."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(StartVendDebitAmountTotalCap, VendorLedgerEntry."Debit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGenJournaLinePosAmtGeneralJournalTest()
    begin
        // [SCENARIO] Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 2 General Journal - Test with positive Amount.
        Initialize();
        GeneralJournalTestReport(DebitAmtLCYCap, LibraryRandom.RandDec(100, 2));  // Using random for Amount.
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGenJournaLineNegAmtGeneralJournalTest()
    begin
        // [SCENARIO] Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord Trigger of Report - 2 General Journal - Test with negative Amount.
        Initialize();
        GeneralJournalTestReport(CreditAmtLCYCap, -LibraryRandom.RandDec(100, 2));  // Using random for Amount.
    end;

    local procedure GeneralJournalTestReport(AmountCap: Text; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [GIVEN] Gen. journal Line
        CreateGeneralJournalLine(GenJournalLine, Amount);
        EnqueueValuesForRequestPageHandler(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");  // Enqueue for GeneralJournalTestRequestPageHandler.

        // [WHEN] Running report "General Journal - Test"
        REPORT.Run(REPORT::"General Journal - Test");  // Opens GeneralJournalTestRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(
          AmountCap, ErrorTxt, GenJournalLine."Amount (LCY)",
          StrSubstNo(TransactionOutOfBalanceErr, GenJournalLine."Transaction No.", GenJournalLine."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemIntShowAmtsInAddCurrFalseOffAccSumBook()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc. Summarized Book with Show Amounts In Add Currency as FALSE.
        Initialize();
        GeneralLedgerSetup.Get();
        OfficialAccSummarizedBookReportWithShowAmtsInAddCurr(
          GeneralLedgerSetup."LCY Code", GeneralLedgerSetup."Additional Reporting Currency", false);  // FALSE for Show Amounts In Add Currency.
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemIntShowAmtsInAddCurrTrueOffAccSumBook()
    var
        NewAdditionalReportingCurrency: Code[10];
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book with Show Amounts In Add Currency as TRUE.
        Initialize();
        NewAdditionalReportingCurrency := LibraryUTUtility.GetNewCode10();
        OfficialAccSummarizedBookReportWithShowAmtsInAddCurr(NewAdditionalReportingCurrency, NewAdditionalReportingCurrency, true);  // TRUE for Show Amounts In Add Currency.
    end;

    local procedure OfficialAccSummarizedBookReportWithShowAmtsInAddCurr(ExpectedHeaderCaption: Code[10]; NewAdditionalReportingCurrency: Code[10]; ShowAmountsInAddCurrency: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        // [GIVEN] Update Additional Reporting Currency and Create Accounting Periods.
        UpdateAdditionalReportingCurrOnGeneralLedgerSetup(NewAdditionalReportingCurrency);
        CreateAccountingPeriod(false, WorkDate());  // FALSE for New Fiscal Year.
        CreateAccountingPeriod(false, CalcDate('<1D>', WorkDate()));  // Using 1D as required for the test case and FALSE for New Fiscal Year.
        EnqueueValuesForOfficialAccSumBookRqstPageHandler(ShowAmountsInAddCurrency, GLAccount."Account Type"::Heading, WorkDate());

        // [WHEN] Running report "Official Acc.Summarized Book"
        REPORT.Run(REPORT::"Official Acc.Summarized Book");  // Opens OfficialAccSummarizedBookRequestPageHandler.

        // [THEN]
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(HeaderTextCap, StrSubstNo(AllAmountsInCurrencyCap, ExpectedHeaderCaption));
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemIntFiscYearOffAccSummarizedBookErr()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for multiple Fiscal Years.

        // [GIVEN] Accounting Periods in different years.
        Initialize();
        CreateAccountingPeriod(true, WorkDate());  // TRUE for New Fiscal Year.
        CreateAccountingPeriod(true, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Adding random years to WORKDATE for Starting Date, TRUE for New Fiscal Year.
        EnqueueValuesForOfficialAccSumBookRqstPageHandler(
          false, GLAccount."Account Type"::Heading, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Adding random years to WORKDATE for ToDate, FALSE for Show Amounts In Add Currency.

        // [WHEN] Running report "Official Acc.Summarized Book"
        asserterror REPORT.Run(REPORT::"Official Acc.Summarized Book");  // Opens OfficialAccSummarizedBookRequestPageHandler.

        // [THEN] Verify expected error code, actual error:"You cannot execute this report for more than one Fiscal Year".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemIntStartingDateOffAccSummarizedBookErr()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for Period Starting Date error.

        // [GIVEN] Enqued values for Report 10716
        Initialize();
        EnqueueValuesForOfficialAccSumBookRqstPageHandler(false, GLAccount."Account Type"::Heading, WorkDate());  // FALSE for Show Amounts In Add Currency.

        // [WHEN] Running report "Official Acc.Summarized Book"
        asserterror REPORT.Run(REPORT::"Official Acc.Summarized Book");  // Opens OfficialAccSummarizedBookRequestPageHandler.

        // [THEN] Verify expected error code, actual error:"The date XXXX is not a Period Starting Date".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemIntEndingDateOffAccSummarizedBookErr()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnPreDataItem Trigger of Report - 10716 Official Acc.Summarized Book for Period Ending Date error.

        // [GIVEN] Enqued values for Report 10716
        Initialize();
        CreateAccountingPeriod(false, WorkDate());  // FALSE for New Fiscal Year.
        EnqueueValuesForOfficialAccSumBookRqstPageHandler(
          false, GLAccount."Account Type"::Heading, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Adding random years to WORKDATE for ToDate, FALSE for Show Amounts In Add Currency.

        // [WHEN] Running report "Official Acc.Summarized Book"
        asserterror REPORT.Run(REPORT::"Official Acc.Summarized Book");  // Opens OfficialAccSummarizedBookRequestPageHandler.

        // [THEN] Verify expected error code, actual error:"Check the ending date of the Fiscal Year".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('MainAccountingBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccountAccTypePostingMainAccBook()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with G/L Account Type Posting.

        // [GIVEN] G/L Entry
        Initialize();
        CreateGLEntryWithGLAccount(GLEntry, false);  // False for ShowAmtsInAddCurrency.

        // [WHEN] Running report "Main Accounting Book"
        REPORT.Run(REPORT::"Main Accounting Book");  // Opens MainAccountingBookRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(TotalCreditHeadCap, TotalDebitHeadCap, GLEntry."Credit Amount", GLEntry."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('MainAccountingBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccountAccTypeHeadingMainAccBook()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with G/L Account Type Heading.

        // [GIVEN] GLAccount with Account Type Heading with Code length 3.
        Initialize();
        CreateGLEntrySetup(GLEntry);
        CreateGLAccount(GLAccount, CopyStr(LibraryUTUtility.GetNewCode(), 1, 3), GLAccount."Account Type"::Heading, GLEntry."G/L Account No.");
        EnqueueValuesForMainAccountingBookRqstPageHandler(
          GLAccount."No.", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code", GLAccount."Account Type"::Heading,
          Format(WorkDate()), false);  // False for ShowAmtsInAddCurrency.

        // [WHEN] Running report "Main Accounting Book"
        REPORT.Run(REPORT::"Main Accounting Book");  // Opens MainAccountingBookRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(TotalCreditHeadCap, TotalDebitHeadCap, GLEntry."Credit Amount", GLEntry."Debit Amount");
    end;

    [Test]
    [HandlerFunctions('MainAccountingBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIntegerMainAccountingBook()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Purpose of the test is to validate Integer - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with Show Amounts in Additional Currency.

        // [GIVEN] G/L Entry
        Initialize();
        CreateGLEntryWithGLAccount(GLEntry, true);  // True for ShowAmtsInAddCurrency.

        // [WHEN] Running report "Main Accounting Book"
        REPORT.Run(REPORT::"Main Accounting Book");  // Opens MainAccountingBookRequestPageHandler.

        // [THEN]
        VerifyXMLValuesOnReport(
          TotalCreditHeadCap, TotalDebitHeadCap, GLEntry."Add.-Currency Credit Amount", GLEntry."Add.-Currency Debit Amount");
    end;

    [Test]
    [HandlerFunctions('MainAccountingBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccountInitialDateMainAccBookErr()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with Initial Date error.

        // Setup.
        Initialize();
        AccountingPeriod.FindFirst();
        OnAfterGetRecordGLAccountMainAccountingBookError(
          Format(CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', AccountingPeriod."Starting Date")));  // Subtracting random years from Starting Date for DateFilter.
    end;

    [Test]
    [HandlerFunctions('MainAccountingBookRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLAccountEndPeriodDateMainAccBookErr()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // [SCENARIO] Purpose of the test is to validate G/L Account - OnAfterGetRecord Trigger of Report - 10723 Main Accounting Book with End Period Date error.

        // Setup.
        Initialize();
        AccountingPeriod.FindFirst();
        OnAfterGetRecordGLAccountMainAccountingBookError(
          StrSubstNo(DateFilterTxt, Format(AccountingPeriod."Starting Date"),
            Format(CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', NormalDate(AccountingPeriod."Starting Date")))));  // DateRange - Subtracting random years from Starting Date to set Ending Date greater than Starting Date in DateFilter.
    end;

    local procedure OnAfterGetRecordGLAccountMainAccountingBookError(DateFilter: Text)
    var
        GLAccount: Record "G/L Account";
    begin
        // [GIVEN] Enqued values for Main Accounting Book
        EnqueueValuesForMainAccountingBookRqstPageHandler('', '', '', GLAccount."Account Type"::Posting, DateFilter, false);  // Blank used for GLAccountNo, GlobalDimensionOneCode and GlobalDimensionTwoCode. False for ShowAmtsInAddCurrency.

        // [WHEN] Running report "Main Accounting Book"
        asserterror REPORT.Run(REPORT::"Main Accounting Book");  // Opens MainAccountingBookRequestPageHandler.

        // [THEN] Verify expected error code, actual error: "There is no period within this date range.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BalanceAtDateInTrialBalanceReport()
    var
        AmountBeforePeriod: Decimal;
        AmountWithinPeriod: Decimal;
        GLAccountNo: Code[20];
        PeriodStart: Date;
        PeriodEnd: Date;
        RunAsOption: Option XML,Excel;
    begin
        // [FEATURE] [Trial Balance] [Balance at date]
        // [SCENARIO 374752] The "Accumulated Balance at date" field should be calculated assuming balance before the specified period

        Initialize();

        // [GIVEN] Reporting period from 01-01-15 to 31-12-15 (1 year)
        PeriodStart := CalcDate('<-CY>', WorkDate());
        PeriodEnd := CalcDate('<CY>', WorkDate());

        // [GIVEN] G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] G/L Entry before the reporting period (Amount = 100)
        AmountBeforePeriod := CreateGLEntryWithSpecifiedAmount(GLAccountNo, PeriodStart - 1);

        // [GIVEN] G/L Entry within the reporting period (Amount = 500)
        AmountWithinPeriod := CreateGLEntryWithSpecifiedAmount(GLAccountNo, WorkDate());

        // [GIVEN] G/L Entry after the reporting period (Amount = 1000)
        CreateGLEntryWithSpecifiedAmount(GLAccountNo, PeriodEnd + 1);
        Commit();

        // [WHEN] Run Trial Balance report
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(PeriodStart);
        LibraryVariableStorage.Enqueue(PeriodEnd);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(RunAsOption::XML);

        REPORT.Run(REPORT::"Trial Balance");

        // [THEN] "Accumulated Balance at date" field contains sum of entries before and within period (100 + 500 = 600)
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalBalanceAtEnd', AmountBeforePeriod + AmountWithinPeriod);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AdditionalCurrencyTrialBalanceReport()
    var
        GLEntryBefore: Record "G/L Entry";
        GLEntryWithin: Record "G/L Entry";
        RunAsOption: Option XML,Excel;
        GLAccountNo: Code[20];
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        // [FEATURE] [Trial Balance] [Additional Currency] [ACY] [UT]
        // [SCENARIO 290722] Trial Balance shows correct amounts in Additional Currency
        // [SCENARIO 302418] Trial Balance shows row of totals
        Initialize();

        // [GIVEN] Reporting period from 01-01-18 to 31-12-18 (1 year)
        PeriodStart := CalcDate('<-CY>', WorkDate());
        PeriodEnd := CalcDate('<CY>', WorkDate());

        // [GIVEN] G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] G/L Entry before the reporting period (Amount = 100, Debit = 200, Credit = 300)
        CreateGLEntryWithAdditionalCurrency(GLEntryBefore, GLAccountNo, PeriodStart - 1);

        // [GIVEN] G/L Entry within the reporting period (Amount = 10, Debit = 20, Credit = 30)
        CreateGLEntryWithAdditionalCurrency(GLEntryWithin, GLAccountNo, WorkDate());

        // [WHEN] Run Trial Balance report and save dataset as XML
        Commit();
        RunTrialBalanceReportWithParams(true, GLAccountNo, PeriodStart, PeriodEnd, true, RunAsOption::XML);

        // [THEN] Amount fields populated accordingly in DataSet
        // [THEN] Total Period Debit Amount = 200
        // [THEN] Total Period Credit Amount = 300
        // [THEN] Total Debit Amount at the end = 220
        // [THEN] Total Credit Amount at the end = 330
        // [THEN] Total Balance at the end = 110
        VerifyTrialBalanceDataSet(GLEntryBefore, GLEntryWithin);
        LibraryVariableStorage.AssertEmpty();

        // [WHEN] Run Trial Balance report and save as Excel
        RunTrialBalanceReportWithParams(true, GLAccountNo, PeriodStart, PeriodEnd, true, RunAsOption::Excel);

        // [THEN] Amount fields populated accordingly in Excel
        // [THEN] Total Period Debit Amount = 200
        // [THEN] Total Period Credit Amount = 300
        // [THEN] Total Debit Amount at the end = 220
        // [THEN] Total Credit Amount at the end = 330
        // [THEN] Total Balance at the end = 110
        VerifyTrialBalanceExcelFile(GLEntryBefore, GLEntryWithin);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalBalanceAtDateMultipleGLAccountsTrialBalanceReport()
    var
        AmountWithinPeriod: array[2] of Decimal;
        GLAccountNo: array[2] of Code[20];
        PeriodStart: Date;
        PeriodEnd: Date;
        RunAsOption: Option XML,Excel;
    begin
        // [FEATURE] [Trial Balance] [Balance at date]
        // [SCENARIO 334810] Calculation of the Total value for "Balance at date" in case "Include Opening/Closing Entries" are not set.
        Initialize();

        // [GIVEN] Reporting period from 01-01-15 to 31-12-15 (1 year)
        PeriodStart := CalcDate('<-CY>', WorkDate());
        PeriodEnd := CalcDate('<CY>', WorkDate());

        // [GIVEN] Two G/L Accounts.
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Each G/L Account has a G/L Entry before the reporting period.
        CreateGLEntryWithSpecifiedAmount(GLAccountNo[1], PeriodStart - 1);
        CreateGLEntryWithSpecifiedAmount(GLAccountNo[2], PeriodStart - 1);

        // [GIVEN] Each G/L Account has a G/L Entry within the reporting period. Amount[1] = 500, Amount[2] = 600.
        AmountWithinPeriod[1] := CreateGLEntryWithSpecifiedAmount(GLAccountNo[1], WorkDate());
        AmountWithinPeriod[2] := CreateGLEntryWithSpecifiedAmount(GLAccountNo[2], WorkDate());

        // [GIVEN] Each G/L Account has a G/L Entry after the reporting period.
        CreateGLEntryWithSpecifiedAmount(GLAccountNo[1], PeriodEnd + 1);
        CreateGLEntryWithSpecifiedAmount(GLAccountNo[2], PeriodEnd + 1);
        Commit();

        // [WHEN] Run Trial Balance report with "Include Opening/Closing Entries" = False.
        RunTrialBalanceReportWithParams(
          false, StrSubstNo('%1|%2', GLAccountNo[1], GLAccountNo[2]), PeriodStart, PeriodEnd, false, RunAsOption::XML);

        // [THEN] The Total value for "Balance at date" column is calculated as sum of "Amount" of entries within period (500 + 600 = 1100).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalBalanceAtEnd', AmountWithinPeriod[1] + AmountWithinPeriod[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalBalanceAtDateMultipleGLAccountsAddnlCurrencyTrialBalanceReport()
    var
        GLEntryWithin: array[2] of Record "G/L Entry";
        GLEntryBeforeAfter: Record "G/L Entry";
        GLAccountNo: array[2] of Code[20];
        PeriodStart: Date;
        PeriodEnd: Date;
        RunAsOption: Option XML,Excel;
    begin
        // [FEATURE] [Trial Balance] [Balance at date] [ACY]
        // [SCENARIO 334810] Calculation of the Total value for "Balance at date" in case "Include Opening/Closing Entries" are not set and "Show Amts in Add. Currency" is set.
        Initialize();

        // [GIVEN] Reporting period from 01-01-15 to 31-12-15 (1 year)
        PeriodStart := CalcDate('<-CY>', WorkDate());
        PeriodEnd := CalcDate('<CY>', WorkDate());

        // [GIVEN] Two G/L Accounts.
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Each G/L Account has a G/L Entry before the reporting period.
        CreateGLEntryWithAdditionalCurrency(GLEntryBeforeAfter, GLAccountNo[1], PeriodStart - 1);
        CreateGLEntryWithAdditionalCurrency(GLEntryBeforeAfter, GLAccountNo[2], PeriodStart - 1);

        // [GIVEN] Each G/L Account has a G/L Entry within the reporting period.
        // [GIVEN] Additional-Currency Amount[1] = 50, Additional-Currency Amount[2] = 60.
        CreateGLEntryWithAdditionalCurrency(GLEntryWithin[1], GLAccountNo[1], WorkDate());
        CreateGLEntryWithAdditionalCurrency(GLEntryWithin[2], GLAccountNo[2], WorkDate());

        // [GIVEN] Each G/L Account has a G/L Entry after the reporting period.
        CreateGLEntryWithAdditionalCurrency(GLEntryBeforeAfter, GLAccountNo[1], PeriodEnd + 1);
        CreateGLEntryWithAdditionalCurrency(GLEntryBeforeAfter, GLAccountNo[2], PeriodEnd + 1);
        Commit();

        // [WHEN] Run Trial Balance report with "Include Opening/Closing Entries" = False, "Show Amts in Add. Currency" = True.
        RunTrialBalanceReportWithParams(
          false, StrSubstNo('%1|%2', GLAccountNo[1], GLAccountNo[2]), PeriodStart, PeriodEnd, true, RunAsOption::XML);

        // [THEN] The Total value for "Balance at date" column is calculated as sum of "Additional-Currency Amount" of entries within period (50 + 60 = 110).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalBalanceAtEnd', GLEntryWithin[1]."Additional-Currency Amount" + GLEntryWithin[2]."Additional-Currency Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalWithDifferentAccountLevelCorrectOnTrialBalanceReport()
    var
        AmountWithinPeriod: Decimal;
        GLAccountNo: array[2] of Code[20];
        PeriodStart: Date;
        PeriodEnd: Date;
        RunAsOption: Option XML,Excel;
    begin
        // [SCENARIO 521732] Trial Balance does not sum up as expected with Different Level Account Filters in the Spanish Version.
        Initialize();

        // [GIVEN] Reporting period from 01-01-15 to 31-12-15 (1 year)
        PeriodStart := CalcDate('<-CY>', WorkDate());
        PeriodEnd := CalcDate('<CY>', WorkDate());

        // [GIVEN] G/L Account
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] G/L Entry within the reporting period
        AmountWithinPeriod := CreateGLEntryWithSpecifiedAmount(GLAccountNo[1], WorkDate());
        AmountWithinPeriod += CreateGLEntryWithSpecifiedAmount(GLAccountNo[2], WorkDate());
        Commit();

        // [WHEN] Run Trial Balance report
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(GLAccountNo[1] + '|' + GLAccountNo[2]);
        LibraryVariableStorage.Enqueue(PeriodStart);
        LibraryVariableStorage.Enqueue(PeriodEnd);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(RunAsOption::XML);

        REPORT.Run(REPORT::"Trial Balance");

        // [THEN] "Accumulated Balance at date" field contains sum of entries before and within period (100 + 500 = 600)
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalBalanceAtEnd', AmountWithinPeriod);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
    end;

    local procedure CreateAccountingPeriod(NewFiscalYear: Boolean; StartingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod."Starting Date" := StartingDate;
        AccountingPeriod."New Fiscal Year" := NewFiscalYear;
        AccountingPeriod.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; Amount: Decimal; AmountLCY: Decimal)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry.Insert();
        CreateDetailedCustomerLedgerEntry(EntryType, CustLedgerEntry."Entry No.", Amount, AmountLCY);
    end;

    local procedure CreateDetailedCustomerLedgerEntry(EntryType: Enum "Detailed CV Ledger Entry Type"; CustLedgerEntryNo: Integer; Amount: Decimal; AmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Debit Amount" := Amount;
        DetailedCustLedgEntry."Credit Amount" := Amount;
        DetailedCustLedgEntry."Debit Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Credit Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; Amount: Decimal; AmountLCY: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Correction of Remaining Amount";
        DetailedVendorLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry."Debit Amount" := Amount;
        DetailedVendorLedgEntry."Credit Amount" := Amount;
        DetailedVendorLedgEntry."Debit Amount (LCY)" := AmountLCY;
        DetailedVendorLedgEntry."Credit Amount (LCY)" := AmountLCY;
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch."Journal Template Name" := CreateGeneralJournalTemplate();
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Insert(true);
    end;

    local procedure CreateGeneralJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; No: Code[20]; AccountType: Enum "G/L Account Type"; Totaling: Text)
    begin
        GLAccount."No." := No;
        GLAccount."Account Type" := AccountType;
        GLAccount."Global Dimension 1 Code" := LibraryUTUtility.GetNewCode();
        GLAccount."Global Dimension 2 Code" := LibraryUTUtility.GetNewCode();
        GLAccount.Totaling := Totaling;
        GLAccount.Insert();
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20]; PostingDate: Date)
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."Posting Date" := PostingDate;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Transaction No." := CreateGLRegister(GLEntry."Entry No.");
        GLEntry."Debit Amount" := LibraryRandom.RandDec(100, 2);
        GLEntry."Credit Amount" := GLEntry."Debit Amount";
        GLEntry."Global Dimension 1 Code" := GlobalDimensionOneCode;
        GLEntry."Global Dimension 2 Code" := GlobalDimensionTwoCode;
        GLEntry."Add.-Currency Debit Amount" := LibraryRandom.RandDec(100, 2);
        GLEntry."Add.-Currency Credit Amount" := GLEntry."Add.-Currency Debit Amount";
        GLEntry.Insert();
    end;

    local procedure CreateGLEntryWithSpecifiedAmount(GLAccountNo: Code[20]; PostingDate: Date): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := LibraryRandom.RandDec(1000, 2);
        GLEntry.Insert();
        exit(GLEntry.Amount);
    end;

    local procedure CreateGLEntrySetup(var GLEntry: Record "G/L Entry")
    var
        GLAccount: Record "G/L Account";
    begin
        CreateAccountingPeriod(true, WorkDate());  // True for New Fiscal Year.
        CreateGLAccount(GLAccount, LibraryUTUtility.GetNewCode(), GLAccount."Account Type"::Posting, '');  // Blank used for Totaling.
        CreateGLEntry(GLEntry, GLAccount."No.", GLAccount."Global Dimension 1 Code", GLAccount."Global Dimension 2 Code", WorkDate());  // Using WORKDATE for Posting Date.
    end;

    local procedure CreateGLEntryWithGLAccount(var GLEntry: Record "G/L Entry"; ShowAmtsInAddCurrency: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Accounting Period. Create GLAccount with Account Type Posting and create G/L entry.
        CreateGLEntrySetup(GLEntry);
        EnqueueValuesForMainAccountingBookRqstPageHandler(
          GLEntry."G/L Account No.", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code",
          GLAccount."Account Type"::Posting, Format(WorkDate()), ShowAmtsInAddCurrency);
    end;

    local procedure CreateGLEntryWithAdditionalCurrency(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; PostingDate: Date)
    begin
        with GLEntry do begin
            "Entry No." := LibraryUtility.GetNewRecNo(GLEntry, FieldNo("Entry No."));
            "G/L Account No." := GLAccountNo;
            "Posting Date" := PostingDate;
            Amount := LibraryRandom.RandDec(100, 2);
            "Debit Amount" := LibraryRandom.RandDec(100, 2);
            "Credit Amount" := LibraryRandom.RandDec(100, 2);
            "Additional-Currency Amount" := LibraryRandom.RandDec(100, 2);
            "Add.-Currency Debit Amount" := LibraryRandom.RandDec(100, 2);
            "Add.-Currency Credit Amount" := LibraryRandom.RandDec(100, 2);
            Insert();
        end;
    end;

    local procedure CreateGLRegister(EntryNo: Integer): Integer
    var
        GLRegister: Record "G/L Register";
        GLRegister2: Record "G/L Register";
    begin
        GLRegister2.FindLast();
        GLRegister."No." := GLRegister2."No." + 1;
        GLRegister."From Entry No." := EntryNo;
        GLRegister."To Entry No." := EntryNo;
        GLRegister."Posting Date" := WorkDate();
        GLRegister.Insert();
        exit(GLRegister."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Amount: Decimal; AmountLCY: Decimal)
    begin
        VendorLedgerEntry."Vendor No." := CreateVendor();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Insert();
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", Amount, AmountLCY);
    end;

    local procedure RunTrialBalanceReportWithParams(AcumBalanceAtDate: Boolean; GLAccountNoFilter: Text; PeriodStart: Date; PeriodEnd: Date; ShowAmountsInAddCurrency: Boolean; RunAsOption: Option XML,Excel)
    begin
        LibraryVariableStorage.Enqueue(AcumBalanceAtDate);
        LibraryVariableStorage.Enqueue(GLAccountNoFilter);
        LibraryVariableStorage.Enqueue(PeriodStart);
        LibraryVariableStorage.Enqueue(PeriodEnd);
        LibraryVariableStorage.Enqueue(ShowAmountsInAddCurrency);
        LibraryVariableStorage.Enqueue(RunAsOption);
        REPORT.Run(REPORT::"Trial Balance");
    end;

    local procedure EnqueueValuesForMainAccountingBookRqstPageHandler(GLAccountNo: Code[20]; GlobalDimensionOneCode: Code[20]; GlobalDimensionTwoCode: Code[20]; AccountType: Enum "G/L Account Type"; DateFilter: Text; ShowAmtsInAddCurrency: Boolean)
    begin
        EnqueueValuesForRequestPageHandler(GLAccountNo, GlobalDimensionOneCode);
        EnqueueValuesForRequestPageHandler(GlobalDimensionTwoCode, AccountType);
        EnqueueValuesForRequestPageHandler(DateFilter, ShowAmtsInAddCurrency);
    end;

    local procedure EnqueueValuesForOfficialAccSumBookRqstPageHandler(ShowAmountsInAddCurrency: Boolean; AccountType: Enum "G/L Account Type"; ToDate: Date)
    begin
        EnqueueValuesForRequestPageHandler(ShowAmountsInAddCurrency, ToDate);
        LibraryVariableStorage.Enqueue(AccountType);
    end;

    local procedure EnqueueValuesForRequestPageHandler(Value: Variant; Value2: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
    end;

    local procedure UpdateAdditionalReportingCurrOnGeneralLedgerSetup(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyXMLValuesOnReport(Caption: Text; Caption2: Text; Value: Decimal; Value2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    local procedure VerifyTrialBalanceDataSet(GLEntryBefore: Record "G/L Entry"; GLEntryWithin: Record "G/L Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalPeriodDebitAmt', GLEntryWithin."Add.-Currency Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalPeriodCreditAmt', GLEntryWithin."Add.-Currency Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalDebitAmtAtEnd', GLEntryWithin."Add.-Currency Debit Amount" + GLEntryBefore."Add.-Currency Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalCreditAmtAtEnd', GLEntryWithin."Add.-Currency Credit Amount" + GLEntryBefore."Add.-Currency Credit Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalBalanceAtEnd', GLEntryBefore."Additional-Currency Amount" + GLEntryWithin."Additional-Currency Amount");
    end;

    local procedure VerifyTrialBalanceExcelFile(GLEntryBefore: Record "G/L Entry"; GLEntryWithin: Record "G/L Entry")
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(
          21, 4, LibraryReportValidation.FormatDecimalValue(GLEntryWithin."Add.-Currency Debit Amount"));
        LibraryReportValidation.VerifyCellValue(
          21, 6, LibraryReportValidation.FormatDecimalValue(GLEntryWithin."Add.-Currency Credit Amount"));
        LibraryReportValidation.VerifyCellValue(
          21, 9,
          LibraryReportValidation.FormatDecimalValue(
            GLEntryWithin."Add.-Currency Debit Amount" + GLEntryBefore."Add.-Currency Debit Amount"));
        LibraryReportValidation.VerifyCellValue(
          21, 12,
          LibraryReportValidation.FormatDecimalValue(
            GLEntryWithin."Add.-Currency Credit Amount" + GLEntryBefore."Add.-Currency Credit Amount"));
        LibraryReportValidation.VerifyCellValue(
          21, 14,
          LibraryReportValidation.FormatDecimalValue(GLEntryWithin.Amount + GLEntryBefore.Amount));
        LibraryReportValidation.VerifyCellValue(
          22, 4, LibraryReportValidation.FormatDecimalValue(GLEntryWithin."Add.-Currency Debit Amount"));
        LibraryReportValidation.VerifyCellValue(
          22, 6, LibraryReportValidation.FormatDecimalValue(GLEntryWithin."Add.-Currency Credit Amount"));
        LibraryReportValidation.VerifyCellValue(
          22, 9,
          LibraryReportValidation.FormatDecimalValue(
            GLEntryWithin."Add.-Currency Debit Amount" + GLEntryBefore."Add.-Currency Debit Amount"));
        LibraryReportValidation.VerifyCellValue(
          22, 12,
          LibraryReportValidation.FormatDecimalValue(
            GLEntryWithin."Add.-Currency Credit Amount" + GLEntryBefore."Add.-Currency Credit Amount"));
        LibraryReportValidation.VerifyCellValue(
          22, 14,
          LibraryReportValidation.FormatDecimalValue(
            GLEntryWithin."Additional-Currency Amount" + GLEntryBefore."Additional-Currency Amount"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalRequestPageHandler(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    var
        No: Variant;
        ShowAmountsInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAmountsInLCY);
        CustomerDetailTrialBal.ShowAmountsInLCY.SetValue(ShowAmountsInLCY);
        CustomerDetailTrialBal.Customer.SetFilter("No.", No);
        CustomerDetailTrialBal.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    var
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Posting Date", Format(WorkDate()));
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRegisterRequestPageHandler(var GLRegister: TestRequestPage "G/L Register")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GLRegister."G/L Register".SetFilter("No.", Format(No));
        GLRegister."G/L Register".SetFilter("Posting Date", Format(WorkDate()));
        GLRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MainAccountingBookRequestPageHandler(var MainAccountingBook: TestRequestPage "Main Accounting Book")
    var
        AccountType: Variant;
        DateFilter: Variant;
        GlobalDimensionOneFilter: Variant;
        GlobalDimensionTwoFilter: Variant;
        No: Variant;
        ShowAmtsInAddCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(GlobalDimensionOneFilter);
        LibraryVariableStorage.Dequeue(GlobalDimensionTwoFilter);
        LibraryVariableStorage.Dequeue(AccountType);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ShowAmtsInAddCurrency);
        MainAccountingBook."G/L Account".SetFilter("No.", No);
        MainAccountingBook."G/L Account".SetFilter("Global Dimension 1 Filter", GlobalDimensionOneFilter);
        MainAccountingBook."G/L Account".SetFilter("Global Dimension 2 Filter", GlobalDimensionTwoFilter);
        MainAccountingBook."G/L Account".SetFilter("Account Type", Format(AccountType));
        MainAccountingBook."G/L Account".SetFilter("Date Filter", Format(DateFilter));
        MainAccountingBook.ShowAmountsInAddCurrency.SetValue(ShowAmtsInAddCurrency);
        MainAccountingBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OfficialAccSummarizedBookRequestPageHandler(var OfficialAccSummarizedBook: TestRequestPage "Official Acc.Summarized Book")
    var
        AccountType: Variant;
        ShowAmountsInAddCurrency: Variant;
        ToDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountsInAddCurrency);
        LibraryVariableStorage.Dequeue(ToDate);
        LibraryVariableStorage.Dequeue(AccountType);
        OfficialAccSummarizedBook.FromDate.SetValue(WorkDate());
        OfficialAccSummarizedBook.ToDate.SetValue(ToDate);
        OfficialAccSummarizedBook.IncludeClosingEntries.SetValue(true);
        OfficialAccSummarizedBook.AccountType.SetValue(AccountType);
        OfficialAccSummarizedBook.ShowAmountsInAddCurrency.SetValue(ShowAmountsInAddCurrency);
        OfficialAccSummarizedBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousYearRequestPageHandler(var TrialBalancePreviousYear: TestRequestPage "Trial Balance/Previous Year")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        TrialBalancePreviousYear."G/L Account".SetFilter("No.", No);
        TrialBalancePreviousYear."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalancePreviousYear.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    var
        RunAsOption: Option XML,Excel;
    begin
        TrialBalance.AcumBalanceAtDate.SetValue(LibraryVariableStorage.DequeueBoolean());
        TrialBalance."G/L Account".SetFilter("No.", LibraryVariableStorage.DequeueText());
        TrialBalance."G/L Account".SetFilter(
          "Date Filter", Format(LibraryVariableStorage.DequeueDate()) + '..' + Format(LibraryVariableStorage.DequeueDate()));
        TrialBalance.ShowAmountsInAddCurrency.SetValue := LibraryVariableStorage.DequeueBoolean();
        RunAsOption := LibraryVariableStorage.DequeueInteger();
        case RunAsOption of
            RunAsOption::XML:
                TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
            RunAsOption::Excel:
                begin
                    LibraryReportValidation.SetFileName(LibraryRandom.RandText(10));
                    TrialBalance.SaveAsExcel(LibraryReportValidation.GetFileName());
                end;
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceRequestPageHandler(var VendorDetailTrialBalance: TestRequestPage "Vendor - Detail Trial Balance")
    var
        No: Variant;
        ShowAmountsInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAmountsInLCY);
        VendorDetailTrialBalance.Vendor.SetFilter("No.", No);
        VendorDetailTrialBalance.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        VendorDetailTrialBalance.ShowAmountsInLCY.SetValue(ShowAmountsInLCY);
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

