codeunit 142059 "Payment Rec Deposits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        ValidationErr: Label 'Sum of %1 must be %2 in Report.';

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDepositsOutstandingBankTrxs()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        NoOfOutstandingBankTrxEntries: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view the breakdown of the deposits in the Outstanding Bank Transactions window
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted
        CreateDeposits(DepositHeader, BankAcc);

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Outstanding Bank Transactions is opened
        NoOfOutstandingBankTrxEntries := OutstandingBankTrxsCount(PmtReconJnl);

        // [THEN] Verify 3 lines are in the Outstanding Bank Transactions window
        Assert.AreEqual(3, NoOfOutstandingBankTrxEntries, '');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDepositsOutstandingBankTrxsTotal()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        // [FEATURE] [Payment Reconciliation Journal]
        // [SCENARIO 167357] Annie can see the Outstanding Transactions Amount matches the Total Deposit Amount from the Deposit
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted
        CreateDeposits(DepositHeader, BankAcc);

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [THEN] Verify 3 lines are in the Outstanding Bank Transactions window
        PmtReconJnl.OutstandingTransactions.AssertEquals(DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestDepOneSaleOnePayOutstBankTrxs()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        NoOfOutstandingBankTrxEntries: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view the breakdown of the deposits and a bank transaction in the Outstanding Bank Transactions window
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted, One Sale is created and One Payment Posted
        CreateDeposits(DepositHeader, BankAcc);
        CreateOneSaleOnePmtTwoDepositLines(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);

        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Outstanding Bank Transactions is opened
        NoOfOutstandingBankTrxEntries := OutstandingBankTrxsCount(PmtReconJnl);

        // [THEN] Verify 4 lines are in the Outstanding Bank Transactions window
        Assert.AreEqual(4, NoOfOutstandingBankTrxEntries, '');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOneDepositPostPaymentReconOutstBankTrxs()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        PmtReconJnl2: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        EntryNoArray: array[2] of Integer;
        DoesPostedLineExist: Boolean;
        DoesUnPostedLineExist: Boolean;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view that deposits, once posted, don't show up in the Outstanding Bank Transactions
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted
        CreateDeposits(DepositHeader, BankAcc);

        // [WHEN] One Deposit line is imported from the bank
        CreateOneDepositLine(OutStream, TempBlobUTF8, DepositHeader);

        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);

        // [WHEN] Payment Reconciliation Journal is opened
        // [WHEN] Automatically Apply the 1 line
        // [WHEN] Post the Applied line
        ApplyLineAndPost(PmtReconJnl, EntryNoArray, BankAcc."No.", BankAccRecon);

        // [WHEN] Reopen up the Payment Reconcilation Journal
        LibraryERM.CreateBankAccReconciliation(BankAccRecon2, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl2);

        DoesPostedLineExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[1]);
        DoesUnPostedLineExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[2]);

        // [THEN] Verify that the posted line is gone and the second one is still there
        Assert.IsFalse(DoesPostedLineExist, 'This line should have been posted');
        Assert.IsTrue(DoesUnPostedLineExist, 'This line should not have been posted');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOneDepositOneSalePostPaymentReconOutstBankTrxs()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        PmtReconJnl2: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        EntryNoArray: array[3] of Integer;
        DoesPostedLineExist: Boolean;
        DoesUnPostedLineExist: Boolean;
        DoesSalesPaymentExits: Boolean;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view that deposits and Payments, once posted, don't show up in the Outstanding Bank Transactions
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted
        CreateDeposits(DepositHeader, BankAcc);

        // [WHEN] One Sale/Payment and Deposit line is imported from the bank
        CreateOneSaleOnePmtOneDepositLine(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);

        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        // [WHEN] Automatically Apply the 1 line
        // [WHEN] Post the Applied line
        ApplyLineAndPost(PmtReconJnl, EntryNoArray, BankAcc."No.", BankAccRecon);

        // [WHEN] Reopen up the Payment Reconcilation Journal
        LibraryERM.CreateBankAccReconciliation(BankAccRecon2, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl2);

        DoesPostedLineExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[1]);
        DoesUnPostedLineExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[2]);
        DoesSalesPaymentExits := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[3]);

        // [THEN] Verify that the posted line is gone and the second one is still there
        Assert.IsFalse(DoesPostedLineExist, 'This line should have been posted');
        Assert.IsTrue(DoesUnPostedLineExist, 'This line should not have been posted');
        Assert.IsFalse(DoesSalesPaymentExits, 'This line should have been posted');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestPostTwoDepositKeepOneSalePayment()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        PmtReconJnl2: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        NoOfOutstandingBankTrxEntries: Integer;
        EntryNoArray: array[3] of Integer;
        DoesFirstDepositExist: Boolean;
        DoesSecondDepositExist: Boolean;
        DoesSalesPaymentExits: Boolean;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view that deposits and Payments, once posted, don't show up in the Outstanding Bank Transactions
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted
        CreateDeposits(DepositHeader, BankAcc);

        // [WHEN] One Sale/Payment and Deposit line is imported from the bank
        CreateTwoDepositLines(OutStream, TempBlobUTF8, DepositHeader);

        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        // [WHEN] Automatically Apply the 1 line
        // [WHEN] Post the Applied line
        ApplyLineAndPost(PmtReconJnl, EntryNoArray, BankAcc."No.", BankAccRecon);

        // [WHEN] Reopen up the Payment Reconcilation Journal
        LibraryERM.CreateBankAccReconciliation(BankAccRecon2, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl2);

        NoOfOutstandingBankTrxEntries := OutstandingBankTrxsCount(PmtReconJnl2);

        Assert.AreEqual(1, NoOfOutstandingBankTrxEntries, '');

        DoesFirstDepositExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[1]);
        DoesSecondDepositExist := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[2]);
        DoesSalesPaymentExits := OutstandingBankTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[3]);

        // [THEN] Verify that the posted line is gone and the second one is still there
        Assert.IsFalse(DoesFirstDepositExist, 'This line should have been posted');
        Assert.IsFalse(DoesSecondDepositExist, 'This line should not have been posted');
        Assert.IsTrue(DoesSalesPaymentExits, 'This line should not have been posted');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestDepOneSaleOnePayVerifyNumLines()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view that after automatically applying that Outstanding totals are zero
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted, One Sale is created and One Payment Posted
        CreateDeposits(DepositHeader, BankAcc);
        CreateOneSaleOnePmtTwoDepositLines(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);

        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Automatically Apply the 2 lines
        ApplyAutomatically(PmtReconJnl);

        // [THEN] Verify Outstanding Transactions Total is 0 and Outstanding Payments total stays 0
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
        PmtReconJnl.OutstandingPayments.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,PmtApplnAllOpenBankTrxsHandler')]
    [Scope('OnPrem')]
    procedure TestDepOneSaleOnePayManualApply()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AmountArray: array[3] of Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view the breakdown of the deposits, one sale and payment and manually apply them
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted, One Sale is created and One Payment Posted
        CreateDeposits(DepositHeader, BankAcc);
        CreateOneSaleOnePmtTwoDepositLines(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);

        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        GetBankAccLedgEntryAmounts(AmountArray, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [THEN]  Verify Outstanding Trx total gets updated after applying each line manually
        PmtReconJnl.OutstandingTransactions.AssertEquals(AmountArray[1] + AmountArray[2] + AmountArray[3]);
        PmtReconJnl.First;
        HandlePmtEntries(PmtReconJnl);
        PmtReconJnl.OutstandingTransactions.AssertEquals(AmountArray[1] + AmountArray[2]);
        PmtReconJnl.Next;
        HandlePmtEntries(PmtReconJnl);
        PmtReconJnl.OutstandingTransactions.AssertEquals(AmountArray[2]);
        PmtReconJnl.Next;
        HandlePmtEntries(PmtReconJnl);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDepositsOutstandingBankTransacReport()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions] [Bank Reconciliation Report]
        // [SCENARIO 167364] Annie can view the outstanding deposits on the bank reconciliation report
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created/posted with 2 lines and imported on statement
        CreateDeposits(DepositHeader, BankAcc);
        CreateTwoDepositLines(OutStream, TempBlobUTF8, DepositHeader);
        ImportBankStmtAndUpdateBankAccReconTable(BankAccRecon, TempBlobUTF8);
        UpdateBankAccReconStatementDate(BankAccRecon, DepositHeader."Posting Date");
        Commit();

        // [WHEN] Payment Reconciliation Journal is opened and report is invoked
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        PmtReconJnl.TestReport.Invoke;

        // [THEN] Verify outstanding deposits are included and report totals correct
        LibraryVariableStorage.AssertEmpty;
        VerifyBankAccReconReportData(
          DepositHeader."Total Deposit Amount",
          0,
          BankAccRecon."Statement Ending Balance",
          DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDepOneSaleOnePayOutstBankTransacReport()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustAmount: Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions] [Bank Reconciliation Report]
        // [SCENARIO 167364] Annie can view the breakdown of the deposits and bank transactions on the Bank Reconciliation Report
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted, One Sale is created and One Payment Posted
        CreateDeposits(DepositHeader, BankAcc);
        CreateOneSaleOnePmtTwoDepositLines(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);
        CustAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        ImportBankStmtAndUpdateBankAccReconTable(BankAccRecon, TempBlobUTF8);
        UpdateBankAccReconStatementDate(BankAccRecon, DepositHeader."Posting Date");

        // [GIVEN] Post the payment
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened and report is invoked
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        PmtReconJnl.TestReport.Invoke;

        // [THEN] Verify outstanding transactions and deposits are included and report totals correct
        LibraryVariableStorage.AssertEmpty;
        VerifyBankAccReconReportData(
          CustAmount + DepositHeader."Total Deposit Amount",
          0,
          BankAccRecon."Statement Ending Balance",
          CustAmount + DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,MsgHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDepositsOutstBankTransacAppliedOnReport()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions] [Bank Reconciliation Report]
        // [SCENARIO 167364] Annie can view the applied transactions on the bank reconciliation report
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created/posted with 2 lines and imported on statement
        CreateDeposits(DepositHeader, BankAcc);
        CreateTwoDepositLines(OutStream, TempBlobUTF8, DepositHeader);
        ImportBankStmtAndUpdateBankAccReconTable(BankAccRecon, TempBlobUTF8);
        UpdateBankAccReconStatementDate(BankAccRecon, DepositHeader."Posting Date");

        // [WHEN] Payment Reconciliation Journal is opened, deposits are automatically applied, report is run
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Commit();
        PmtReconJnl.TestReport.Invoke;

        // [THEN] Verify deposits are not included in the outstanding when applied and report totals correct
        LibraryVariableStorage.AssertEmpty;
        VerifyBankAccReconReportData(
          0,
          0,
          BankAccRecon."Statement Ending Balance",
          DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler,PmtApplnAllOpenBankTrxsHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestDepOneSaleOnePayManualApplyOnReport()
    var
        BankAcc: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AmountArray: array[3] of Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions] [Bank Reconciliation Report]
        // [SCENARIO 167364] Annie can view the breakdown of the deposits, one sale, and some manually applied on report
        CreateBankAccRecon(BankAccRecon, BankAcc, '');

        // [GIVEN] Deposit is created with 2 lines and is posted, One Sale is created and One Payment Posted
        CreateDeposits(DepositHeader, BankAcc);
        CreateOneSaleOnePmtTwoDepositLines(CustLedgEntry, OutStream, TempBlobUTF8, DepositHeader);

        LibraryLowerPermissions.SetBanking;
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        GetBankAccLedgEntryAmounts(AmountArray, BankAccRecon."Bank Account No.");
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        UpdateBankAccReconStatementDate(BankAccRecon, DepositHeader."Posting Date");

        // [WHEN] Payment Reconciliation Journal is opened and Apply two lines manually
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        PmtReconJnl.First;
        HandlePmtEntries(PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(PmtReconJnl);
        Commit();
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");

        // [WHEN] Invoke the report
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        PmtReconJnl.TestReport.Invoke;

        // [THEN] Verify only not applied transactions show as outstanding and report totals correct
        LibraryVariableStorage.AssertEmpty;
        VerifyBankAccReconReportData(
          AmountArray[2],
          0,
          BankAccRecon."Statement Ending Balance",
          AmountArray[1] + AmountArray[2] + AmountArray[3]);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        GLSetup: Record "General Ledger Setup";
    begin
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData;
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GLSetup.Get();
        GLSetup."Deposit Nos." := NoSeries.Code;
        GLSetup.Modify(true);
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure ApplyAutomatically(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        PmtReconJnl.ApplyAutomatically.Invoke;
        PmtReconJnl.First;
    end;

    local procedure ApplyLineAndPost(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var EntryNoArray: array[3] of Integer; BankAccNo: Code[20]; BankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        FillEntryNoArray(EntryNoArray, BankAccNo);

        // Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // Automatically Apply the 1 line
        ApplyAutomatically(PmtReconJnl);

        // Post the Applied line
        PmtReconJnl.Post.Invoke;
    end;

    local procedure SetupAndPostDeposit(var DepositHeader: Record "Deposit Header"; GLAccountNo: Code[20]; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Deposit Document with Account Type GL, Vendor and Bank.
        CreateMultilineDepositDocument(
          DepositHeader, BankAccountNo, GLAccountNo, GenJournalLine."Account Type"::"G/L Account",
          VendorNo, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Refund);
        UpdateDepositHeaderWithAmount(DepositHeader);
        LibrarySales.PostDepositDocument(DepositHeader);
    end;

    local procedure CreateBankAccRecon(var BankAccRecon: Record "Bank Acc. Reconciliation"; var BankAcc: Record "Bank Account"; CurrencyCode: Code[10])
    var
        BankStmtFormat: Code[20];
    begin
        Initialize;
        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc, CurrencyCode);

        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
    end;

    local procedure CreateDeposits(var DepositHeader: Record "Deposit Header"; var BankAcc: Record "Bank Account")
    begin
        // Deposit is created with 2 lines and is posted, Sale is created and Payment Posted
        SetupAndPostDeposit(DepositHeader, LibraryERM.CreateGLAccountNo,
          LibraryPurchase.CreateVendorNo, BankAcc."No.");
    end;

    local procedure CreateMultilineDepositDocument(var DepositHeader: Record "Deposit Header"; BankAccountNo: Code[20]; AccountNo: Code[20]; AccountType: Option; AccountNo2: Code[20]; AccountType2: Option; DocumentType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Deposit Document WIth two line with different Account Type.
        CreateDepositDocument(DepositHeader, BankAccountNo, AccountNo, AccountType, -1);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name", DocumentType,
          AccountType2, AccountNo2, -LibraryRandom.RandInt(1000));  // Using Random value for Deposit Amount.
        // BUG 254007
        GenJournalLine."External Document No." :=
          PadStr(DepositHeader."No.", MaxStrLen(GenJournalLine."External Document No."), 'Z');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateDepositDocument(var DepositHeader: Record "Deposit Header"; BankAccountNo: Code[20]; AccountNo: Code[20]; AccountType: Option; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::Deposits);
        LibrarySales.CreateDepositHeader(DepositHeader, GenJournalBatch);
        DepositHeader.Validate("Bank Account No.", BankAccountNo);
        DepositHeader.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, DepositHeader."Journal Template Name",
          DepositHeader."Journal Batch Name", GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, LibraryRandom.RandInt(1000) * SignFactor);  // Using Random value for Deposit Amount.
        // BUG 254007
        GenJournalLine."External Document No." :=
          PadStr(DepositHeader."No.", MaxStrLen(GenJournalLine."External Document No."), 'Z');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAcc(BankStmtFormat: Code[20]; var BankAcc: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."Bank Account No." := 'TEST';
        BankAcc."Bank Branch No." := '123';
        BankAcc."Bank Statement Import Format" := BankStmtFormat;
        BankAcc.Validate("Currency Code", CurrencyCode);
        BankAcc.Modify(true);
    end;

    local procedure CreateOneSaleOnePmtTwoDepositLines(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob"; DepositHeader: Record "Deposit Header")
    begin
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmt(CustLedgEntry, OutStream);
        TwoDepositLines(OutStream, DepositHeader);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateOneSaleOnePmtOneDepositLine(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob"; DepositHeader: Record "Deposit Header")
    begin
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmt(CustLedgEntry, OutStream);
        OneDepositLine(OutStream, DepositHeader);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateOneDepositLine(var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob"; DepositHeader: Record "Deposit Header")
    begin
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneDepositLine(OutStream, DepositHeader);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateTwoDepositLines(var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob"; DepositHeader: Record "Deposit Header")
    begin
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoDepositLines(OutStream, DepositHeader);
        WriteCAMTFooter(OutStream);
    end;

    local procedure FillEntryNoArray(var EntryNoArray: array[3] of Integer; BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        i: Integer;
    begin
        i := 1;
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, true);
        BankAccLedgEntry.FindSet;
        repeat
            EntryNoArray[i] += BankAccLedgEntry."Entry No.";
            i := i + 1;
        until BankAccLedgEntry.Next = 0;
    end;

    local procedure ImportBankStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob")
    var
        BankStmtFormat: Code[20];
    begin
        BankStmtFormat := 'SEPA CAMT';

        SetupSourceMock(BankStmtFormat, TempBlobUTF8);
        BankAccRecon.ImportBankStatement;

        BankAccRecon.CalcFields("Total Transaction Amount");
    end;

    local procedure TwoDepositLines(var OutStream: OutStream; DepositHeader: Record "Deposit Header")
    var
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        with PostedDepositLine do begin
            SetRange("Deposit No.", DepositHeader."No.");

            if FindSet then begin
                repeat
                    WriteCAMTStmtLine(OutStream, "Posting Date", "Document No.", Amount, "Currency Code");
                until Next = 0;
            end;
        end;
    end;

    local procedure CreateCustAndPostSalesInvoice(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
        CreateSalesInvoiceAndPost(CustLedgEntry, LibrarySales.CreateCustomerNo, CurrencyCode);
    end;

    local procedure CreateSalesInvoiceAndPost(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateRandomText(10));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst;

        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK.Invoke;
    end;

    local procedure HandlePmtEntries(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        PmtReconJnlLocal: TestPage "Payment Reconciliation Journal";
    begin
        PmtReconJnlLocal := PmtReconJnl;
        PmtReconJnlLocal.ApplyEntries.Invoke;
        PmtReconJnl := PmtReconJnlLocal;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgTxt: Text)
    begin
    end;

    local procedure OneDepositLine(var OutStream: OutStream; DepositHeader: Record "Deposit Header")
    var
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        with PostedDepositLine do begin
            SetRange("Deposit No.", DepositHeader."No.");

            FindFirst;
            WriteCAMTStmtLine(OutStream, "Posting Date", "Document No.", Amount, "Currency Code");
        end;
    end;

    local procedure OneSaleOnePmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    begin
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        with CustLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Posting Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure OpenPmtReconJnl(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView;
        PmtReconciliationJournals.GotoRecord(BankAccRecon);
        PmtReconJnl.Trap;
        PmtReconciliationJournals.EditJournal.Invoke;
    end;

    local procedure OutstandingBankTrxsCount(PmtReconJnl: TestPage "Payment Reconciliation Journal") NoOfOutstandingBankTrxEntries: Integer
    var
        OutstandingBankTrxs: TestPage "Outstanding Bank Transactions";
    begin
        OutstandingBankTrxs.Trap;
        PmtReconJnl.OutstandingTransactions.DrillDown;
        // Outstanding Bank Trxs page shows and count records
        OutstandingBankTrxs.Expand(true);
        OutstandingBankTrxs.First;
        repeat
            if OutstandingBankTrxs."Entry No.".Value <> '' then
                NoOfOutstandingBankTrxEntries += 1;
        until not OutstandingBankTrxs.Next;
        OutstandingBankTrxs.Close;
    end;

    local procedure OutstandingBankTrxsVerifyEntryNo(PmtReconJnl: TestPage "Payment Reconciliation Journal"; EntryNo: Integer) EntryNoExists: Boolean
    var
        OutstandingBankTrxs: TestPage "Outstanding Bank Transactions";
    begin
        OutstandingBankTrxs.Trap;
        EntryNoExists := false;
        PmtReconJnl.OutstandingTransactions.DrillDown;
        OutstandingBankTrxs.Expand(true);
        OutstandingBankTrxs.First;
        repeat
            if OutstandingBankTrxs."Entry No.".AsInteger = EntryNo then
                EntryNoExists := true;
        until not OutstandingBankTrxs.Next;
        OutstandingBankTrxs.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenBankTrxsHandler(var PmtAppln: TestPage "Payment Application")
    begin
        with PmtAppln do begin
            AllOpenBankTransactions.Invoke;

            // check that it is the customer ledger entry and apply
            if RemainingAmountAfterPosting.AsDEcimal <> 0 then
                if AppliedAmount.AsDEcimal = 0 then begin
                    Applied.SetValue(true);
                    RemainingAmountAfterPosting.AssertEquals(0);
                end;

            OK.Invoke;
        end;
    end;

    local procedure PostPayment(var CustLedgEntry: Record "Cust. Ledger Entry"; BankAccNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer,
          CustLedgEntry."Customer No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -CustLedgEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJournalLine.Validate("External Document No.", CustLedgEntry."External Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCAMTFileMgt.SetupSourceMock(DataExchDefCode, TempBlob);
    end;

    local procedure UpdateDepositHeaderWithAmount(var DepositHeader: Record "Deposit Header")
    begin
        DepositHeader.CalcFields("Total Deposit Lines");
        DepositHeader.Validate("Total Deposit Amount", DepositHeader."Total Deposit Lines");
        DepositHeader.Modify(true);
    end;

    local procedure WriteCAMTHeader(var OutStream: OutStream; CurrTxt: Code[10]; BankAccNo: Code[20])
    begin
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeader(OutStream, CurrTxt, BankAccNo);
    end;

    local procedure WriteCAMTStmtLine(var OutStream: OutStream; StmtDate: Date; StmtText: Text; StmtAmt: Decimal; StmtCurr: Code[10])
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtLine(OutStream, StmtDate, StmtText, StmtAmt, StmtCurr, '');
    end;

    local procedure WriteCAMTFooter(var OutStream: OutStream)
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtFooter(OutStream);
        LibraryCAMTFileMgt.WriteCAMTFooter(OutStream);
    end;

    local procedure VerifyBankAccReconReportData(OutstdTransactions: Decimal; OutstdPayments: Decimal; StatementEndingBalance: Decimal; GLBalance: Decimal)
    var
        DepositTotal: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile;

        // Verify Header Amounts
        LibraryReportDataset.AssertElementWithValueExists('Ending_GL_Balance', GLBalance);
        LibraryReportDataset.AssertElementWithValueExists('Adjusted_Statement_Ending_Balance',
          StatementEndingBalance + OutstdTransactions + OutstdPayments);
        LibraryReportDataset.AssertElementWithValueExists('Difference',
          (GLBalance - (StatementEndingBalance + OutstdTransactions + OutstdPayments)));

        // Verify Totals
        Assert.AreEqual(GLBalance,
          LibraryReportDataset.Sum('Bank_Acc__Reconciliation_Line__Statement_Amount_'),
          StrSubstNo(ValidationErr, 'Bank_Acc__Reconciliation_Line__Statement_Amount_', (OutstdTransactions + OutstdPayments)));
        LibraryReportDataset.SetRange('Outstd_Bank_Transac_Doc_Type', 'Deposit');
        DepositTotal := LibraryReportDataset.Sum('Outstd_Bank_Transac_Amount');
        LibraryReportDataset.Reset();
        Assert.AreEqual(OutstdTransactions, LibraryReportDataset.Sum('Outstd_Bank_Transac_Amount') - DepositTotal,
          StrSubstNo(ValidationErr, 'Outstd_Bank_Transac_Amount', OutstdTransactions));
        Assert.AreEqual(OutstdPayments, LibraryReportDataset.Sum('Outstd_Payment_Amount'),
          StrSubstNo(ValidationErr, 'Outstd_Payment_Amount', OutstdPayments));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecTestReportRequestPageHandler(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Bank Account No.", LibraryVariableStorage.DequeueText);
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Statement No.", LibraryVariableStorage.DequeueText);
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Statement Type", 'Payment Application');
        BankAccReconTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;

    local procedure GetBankAccLedgEntryAmounts(var AmountArray: array[3] of Decimal; BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        i: Integer;
    begin
        i := 1;
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, true);
        BankAccLedgEntry.FindSet;
        repeat
            AmountArray[i] += BankAccLedgEntry.Amount;
            i += 1;
        until BankAccLedgEntry.Next = 0;
    end;

    local procedure ImportBankStmtAndUpdateBankAccReconTable(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        LibraryLowerPermissions.SetBanking;
        ImportBankStmt(BankAccRecon, TempBlobUTF8);
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        Commit();
    end;

    local procedure UpdateBankAccReconStatementDate(var BankAccRecon: Record "Bank Acc. Reconciliation"; PostingDate: Date)
    begin
        BankAccRecon.Validate("Statement Date", PostingDate);
        BankAccRecon.Modify(true);
    end;
}

