codeunit 134266 "Payment Recon. E2E Tests 2"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Reconciliation] [Purchase]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;
        OpenBankLedgerEntriesErr: Label 'All bank account ledger entries should be closed after posting the payment reconciliation journal.';
        ClosedBankLedgerEntriesErr: Label 'All bank account ledger entries should be open after posting the payment reconciliation journal.';
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        SEPA_CAMT_Txt: Label 'SEPA CAMT';

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTransactionsAlreadyImported()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon1: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        BankAcc: Record "Bank Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        BankStmtFormat: Code[20];
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc, '');

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables;
        OnePurchOnePmt1(BankAccRecon1, BankAcc, TempBlobUTF8);
        OnePurchOnePmt1(BankAccRecon2, BankAcc, TempBlobUTF8);

        OpenPmtReconJnl(BankAccRecon1, PmtReconJnl);
        PmtReconJnl.Post.Invoke;
        VerifyNoLinesImported(BankAccRecon2);

        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl);
        asserterror PmtReconJnl.Post.Invoke; // It should not be possible to post
        PmtReconJnl.Close;
        BankAccRecon2.Find;
        BankAccRecon2.Delete(true); // It should be possible to delete the payment reconcilation journal

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
    end;

    local procedure OnePurchOnePmt1(var BankAccRecon: Record "Bank Acc. Reconciliation"; BankAcc: Record "Bank Account"; TempBlobUTF8: Codeunit "Temp Blob")
    var
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(BankAcc."Bank Statement Import Format", TempBlobUTF8);
        BankAccRecon.ImportBankStatement;

        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        VerifyPrePost(BankAccRecon, PmtReconJnl);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        LibraryLowerPermissions.AddAccountReceivables;
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPrePostedPmtNoReconciliation()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.PostPaymentsOnly.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntryAmount(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesOpen(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithPmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmtWithPmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchTwoPmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmtWithPmtDisc2()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry2, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry, OutStream, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYPurchOnePmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneFCYPurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYPurchOneFCYPmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithLateDueDatePmtDisc(
          VendLedgEntry, OutStream, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 10, 10));
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, VendLedgEntry."Currency Code");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithWrongPmtDiscPct()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithWrongPmtDiscPct(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscAmt(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestBankTransfer()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransferAmount: Decimal;
    begin
        Initialize();
        TransferAmount := -100;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        BankTransfer(BankAcc, OutStream, TransferAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyBankLedgEntryAmount(BankAcc."No.", -BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestMappedGLAccountPayment()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        GLAccount: Record "G/L Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransactionText: Text[250];
        TransactionAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryERM.CreateGLAccount(GLAccount);
        TransactionText := 'Transfer' + LibraryUtility.GenerateGUID;
        TransactionAmount := -100;
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, WorkDate, TransactionText, TransactionAmount, '');
        WriteCAMTFooter(OutStream);
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := TransactionText;
        TextToAccountMapping."Credit Acc. No." := GLAccount."No.";
        TextToAccountMapping.Insert();

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPaymentToGLAccount(GLAccount."No.", BankAccRecon."Bank Account No.", TransactionAmount);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestUnMappedGLAccountPayment()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GLAccount: Record "G/L Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransactionText: Text[250];
        TransactionAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryERM.CreateGLAccount(GLAccount);
        TransactionText := 'Transfer' + LibraryUtility.GenerateGUID;
        TransactionAmount := -100;
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, WorkDate, TransactionText, TransactionAmount, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPaymentToGLAccount(GLAccount."No.", BankAccRecon."Bank Account No.", TransactionAmount);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler')]
    [Scope('OnPrem')]
    procedure TestRecurringInterest()
    var
        GLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Interest2');
        GLAcc.Modify(true);
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, CalcDate('<CM+1D>', WorkDate), GLAcc."No." + ' Bank Interest2', -200, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        LibraryVariableStorage.Enqueue(GLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke;

        ApplyAutomatically(PmtReconJnl);
        HandleRecurringInterestAmt(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler')]
    [Scope('OnPrem')]
    procedure TestRecurringRent()
    var
        GLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Rent');
        GLAcc.Modify(true);
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate), 'Rent', -10000, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        LibraryVariableStorage.Enqueue(GLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke;

        ApplyAutomatically(PmtReconJnl);
        HandleRecurringRentAmt(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler')]
    [Scope('OnPrem')]
    procedure TestEndToEnd()
    var
        RentGLAcc: Record "G/L Account";
        InterestGLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: array[20] of Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        i: Integer;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        CreateUnpaidDocs(OutStream, VendLedgEntry, RentGLAcc, InterestGLAcc);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        AddTextMapperRules(PmtReconJnl, InterestGLAcc, RentGLAcc);
        ApplyAutomatically(PmtReconJnl);
        ApplyManually(PmtReconJnl, VendLedgEntry);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        for i := 1 to 14 do
            VerifyVendLedgEntry(VendLedgEntry[i]."Vendor No.");

        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('ApplyCheckLedgEntriesHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCheckLedgRecon()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecon: TestPage "Bank Acc. Reconciliation";
        StmtAmt: Decimal;
    begin
        LibraryERM.CreateBankAccount(BankAcc);

        StmtAmt := 100;
        CreateVendPaymentGenJnlLine(GenJnlLine, BankAcc, StmtAmt);

        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.Modify(true);
        Commit();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        Commit();

        BankAccRecon.OpenNew;
        BankAccRecon.BankAccountNo.SetValue(BankAcc."No.");
        BankAccRecon.StatementNo.SetValue('1');
        BankAccRecon.StatementDate.SetValue(WorkDate);
        BankAccRecon.StatementEndingBalance.SetValue(-StmtAmt);

        BankAccRecon.StmtLine.New;
        BankAccRecon.StmtLine."Transaction Date".SetValue(WorkDate);
        BankAccRecon.StmtLine.Type.SetValue(BankAccReconLine.Type::"Check Ledger Entry");
        BankAccRecon.StmtLine."Statement Amount".SetValue(-StmtAmt);

        BankAccRecon.StmtLine.ApplyEntries.Invoke;

        BankAccRecon.StmtLine.Difference.AssertEquals(0);

        BankAccRecon.Post.Invoke;

        VerifyBankLedgEntry(BankAcc."No.", -StmtAmt);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestManyToOne()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        MatchConfidence1: Text;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        PmtReconJnl.SortForReviewAscending.Invoke;

        PmtReconJnl.First;
        AccountNo1 := PmtReconJnl."Account No.".Value;
        AccountType1 := PmtReconJnl."Account Type".Value;
        MatchConfidence1 := PmtReconJnl."Match Confidence".Value;

        PmtReconJnl.Next;
        Assert.AreEqual(
          AccountNo1, Format(PmtReconJnl."Account No.".Value), 'Entries not applied correctly. Account No. missmatch.');
        Assert.AreEqual(
          AccountType1, Format(PmtReconJnl."Account Type".Value), 'Entries not applied correctly. Account Type missmatch.');
        Assert.AreEqual(
          MatchConfidence1, Format(PmtReconJnl."Match Confidence".Value), 'Entries not applied correctly. Match confidence missmatch.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestManyToOnePmtAmountBiggerThanRemAmount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        AppliedAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        PmtReconJnl.SortForReviewAscending.Invoke;

        PmtReconJnl.First;
        AccountNo1 := PmtReconJnl."Account No.".Value;
        AccountType1 := PmtReconJnl."Account Type".Value;
        AppliedAmount := PmtReconJnl."Applied Amount".AsDEcimal;

        PmtReconJnl.Next;
        if (AccountNo1 = Format(PmtReconJnl."Account No.".Value)) and
           (AccountType1 = Format(PmtReconJnl."Account Type".Value))
        then
            AppliedAmount += PmtReconJnl."Applied Amount".AsDEcimal;

        PmtReconJnl.Next;
        if (AccountNo1 = Format(PmtReconJnl."Account No.".Value)) and
           (AccountType1 = Format(PmtReconJnl."Account Type".Value))
        then
            AppliedAmount += PmtReconJnl."Applied Amount".AsDEcimal;

        Assert.AreEqual(
          VendLedgEntry."Remaining Amount", AppliedAmount, 'Entries not applied correctly. Missmatch for total applied amount.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestAccountNameWhenApplyingToBankAccountLedgerEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Vendor.Get(VendLedgEntry."Vendor No.");
        BankAccReconciliationLine.LinesExist(BankAccRecon);
        repeat
            Assert.AreEqual(Vendor.Name, BankAccReconciliationLine.GetAppliedToName, '');
        until BankAccReconciliationLine.Next = 0;
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtExcessiveAmount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        PmtReconJnl.Accept.Invoke;
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntryExcessiveAmount(VendLedgEntry."Vendor No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePrePostedPmtExcessiveAmount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1.23;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        asserterror PmtReconJnl.Accept.Invoke;
        Assert.ExpectedError(StrSubstNo(ExcessiveAmountErr, Format(-ExcessiveAmount)));
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,TransferDiffToAccountHandler')]
    [Scope('OnPrem')]
    procedure TestTransferDiffToAccount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        DummyGenJournalLine: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        LibraryVariableStorage.Enqueue(DummyGenJournalLine."Account Type"::Vendor);
        LibraryVariableStorage.Enqueue(VendLedgEntry."Vendor No.");
        PmtReconJnl.TransferDiffToAccount.Invoke;
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntryExcessiveAmount(VendLedgEntry."Vendor No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestDrilldownTwoPurchTwoPrePostedPmt()
    var
        Vend: Record Vendor;
        Vend2: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendorCard: TestPage "Vendor Card";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryPurch.CreateVendor(Vend);
        LibraryPurch.CreateVendor(Vend2);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend2, VendLedgEntry2, '');

        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(
          OutStream,
          VendLedgEntry."Posting Date",
          StrSubstNo('%1 %2', VendLedgEntry."Document No.", VendLedgEntry2."Document No."),
          VendLedgEntry."Remaining Amount" + VendLedgEntry2."Remaining Amount",
          VendLedgEntry."Currency Code");
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // verify that you got two applied payment entries
        BankAccReconLine.FilterBankRecLines(BankAccRecon);
        BankAccReconLine.FindFirst;
        AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        Assert.AreEqual(2, AppliedPmtEntry.Count, '');

        // verify that you can drill down to correct vendor from the first applied entry
        AppliedPmtEntry.Find('-');
        Assert.AreEqual(Vend.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        VendorCard.Trap;
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Vend."No.", VendorCard."No.".Value, '');
        VendorCard.Close;

        // verify that you can drill down to correct vendor from the second applied entry
        AppliedPmtEntry.Next;
        Assert.AreEqual(Vend2.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        VendorCard.Trap;
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Vend2."No.", VendorCard."No.".Value, '');
        VendorCard.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOutstandingPaymentTrxTotal()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal]
        // [SCENARIO 166797] Annie can view that one outstanding check transactions total is updated

        // [GIVEN] One purchase and one payment is created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] GL Journal is created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlOnePayment(PmtReconJnl, VendLedgEntry, BankAccRecon, VendLedgerAmount);

        // [THEN] Outstanding Payment Total and Outstanding Bank Transactions are verified
        PmtReconJnl.OutstandingPayments.AssertEquals(VendLedgerAmount);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestOneOutstandingPaymentTrxsTotalPost()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
        NoOfOutstandingBankTrxEntries: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 166797] Annie can view one outstanding check transactions and Verify that all Vendors | gls | banks go to zero

        // [GIVEN] One purchase and one payment is created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] GL Journal is created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlOnePayment(PmtReconJnl, VendLedgEntry, BankAccRecon, VendLedgerAmount);

        // [WHEN] Manually match one and post the Payment Reconcilation Journal
        NoOfOutstandingBankTrxEntries := OutstandingCheckTrxsCount(PmtReconJnl);
        Assert.AreEqual(1, NoOfOutstandingBankTrxEntries, '');
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // [THEN] Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoOutstandingPaymentTrxsTotalPost()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        PmtReconJnl2: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
        NoOfOutstandingBankTrxEntries: Integer;
        DoesPostedLineExist: Boolean;
        DoesUnPostedLineExist: Boolean;
        EntryNoArray: array[2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 166797] Annie can view that after posting one check journal that it doesn't show up in Outstanding Bank Trx

        // [GIVEN] Two purchases and two payments are created and one is put into xml import bank statment
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);
        CreateVendAndPostPurchInvoice(VendLedgEntry2, '');

        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        VendLedgerAmount2 := VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible";

        // [WHEN] Statement is imported
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');

        // [WHEN] Two GL Journals are created as a manual check
        CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry, BankAccRecon."Bank Account No.", -VendLedgerAmount);
        CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry2, BankAccRecon."Bank Account No.", -VendLedgerAmount2);

        i := 1;
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        BankAccLedgEntry.SetRange(Open, true);
        BankAccLedgEntry.FindSet;
        repeat
            EntryNoArray[i] += BankAccLedgEntry."Entry No.";
            i := i + 1;
        until BankAccLedgEntry.Next = 0;

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Manually match one and post the Payment Reconcilation Journal
        NoOfOutstandingBankTrxEntries := OutstandingCheckTrxsCount(PmtReconJnl);
        Assert.AreEqual(2, NoOfOutstandingBankTrxEntries, '');
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // [WHEN] Reopen up the Payment Reconcilation Journal
        LibraryERM.CreateBankAccReconciliation(BankAccRecon2, BankAccRecon."Bank Account No.",
          BankAccRecon."Statement Type"::"Payment Application");
        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl2);

        DoesPostedLineExist := OutstandingCheckTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[1]);
        DoesUnPostedLineExist := OutstandingCheckTrxsVerifyEntryNo(PmtReconJnl2, EntryNoArray[2]);

        // [THEN] Verify that the Unposted line still exists and verify the posted one is not available
        Assert.IsFalse(DoesPostedLineExist, 'This line should have been posted');
        Assert.IsTrue(DoesUnPostedLineExist, 'This line should not have been posted');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOutstandingPaymentApplyAutoTwoLines()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal]
        // [SCENARIO 166797] Annie can view that two outstanding check transactions total is updated when auto applied

        // [GIVEN] Two purchases and two payments are created and put into xml import bank statment
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and payments are posted
        LibraryLowerPermissions.SetBanking;
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened and automatically apply is ran
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // [THEN] Outstanding Payment Total is verified
        PmtReconJnl.OutstandingPayments.AssertEquals(0);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler')]
    [Scope('OnPrem')]
    procedure TestOutstandingPaymentAllOpenPayments()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal]
        // [SCENARIO 166797] Annie can view that one outstanding check transactions total is updated when manually applied

        // [GIVEN] One purchase and one payment is created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] GL Journal is created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlOnePayment(PmtReconJnl, VendLedgEntry, BankAccRecon, VendLedgerAmount);

        // [THEN] Verify Outstanding Trx total gets updated after manually applying the line
        PmtReconJnl.OutstandingPayments.AssertEquals(VendLedgerAmount);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.OutstandingPayments.AssertEquals(0);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler')]
    [Scope('OnPrem')]
    procedure TestOutstandingPaymentAllOpenPaymentsTwoLines()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal]
        // [SCENARIO 166797] Annie can view that two outstanding check transactions total is updated when manually applied

        // [GIVEN] Two purchases and two payments are created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] Two GL Journals are created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlTwoPayments(PmtReconJnl, VendLedgEntry, VendLedgEntry2, BankAccRecon, VendLedgerAmount, VendLedgerAmount2);

        // [THEN] Verify Outstanding Trx total gets updated after manually applying the line
        PmtReconJnl.OutstandingPayments.AssertEquals(VendLedgerAmount + VendLedgerAmount2);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.OutstandingPayments.AssertEquals(VendLedgerAmount2);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry2, PmtReconJnl);
        PmtReconJnl.OutstandingPayments.AssertEquals(0);
        PmtReconJnl.OutstandingTransactions.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOutstandingBankTrxsPagePaymentOneLine()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
        NoOfOutstandingBankTrxEntries: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 166797] Annie can view that one outstanding check transaction in the Outstanding Bank Transactions window

        // [GIVEN] One purchase and one payment is created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] GL Journal is created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlOnePayment(PmtReconJnl, VendLedgEntry, BankAccRecon, VendLedgerAmount);

        // [WHEN] Outstanding Bank Transactions is opened and lines are counted
        NoOfOutstandingBankTrxEntries := OutstandingCheckTrxsCount(PmtReconJnl);

        // [THEN] Verify only one line in the Outstanding Bank Transactions
        Assert.AreEqual(1, NoOfOutstandingBankTrxEntries, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOutstandingBankTrxsPagePaymentTwoLines()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
        NoOfOutstandingBankTrxEntries: Integer;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 166797] Annie can view that two outstanding check transactions in the Outstanding Bank Transactions window

        // [GIVEN] Two purchases and two payments are created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] Two GL Journals are created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlTwoPayments(PmtReconJnl, VendLedgEntry, VendLedgEntry2, BankAccRecon, VendLedgerAmount, VendLedgerAmount2);

        // [WHEN] Outstanding Bank Transactions is opened and lines are counted
        NoOfOutstandingBankTrxEntries := OutstandingCheckTrxsCount(PmtReconJnl);

        // [THEN] Verify two lines in the Outstanding Bank Transactions
        Assert.AreEqual(2, NoOfOutstandingBankTrxEntries, '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure SingleVendorAutoMatchAndPostTwoPaymentsTwoInvoicesInViceVersaOrder()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: array[2] of Record "Bank Acc. Reconciliation Line";
        InvVendLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PmtVendLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO 198751] Automatically match and post payment reconciliation journal with two vendor payments applied to two invoices in vice versa order
        Initialize();

        // [GIVEN] Vendor "V" with two posted purchase invoices:
        VendorNo := LibraryPurch.CreateVendorNo;
        // [GIVEN] "PI1" with Amount Including VAT = 1000 (vendor ledger entry no. = "VLE_INV1")
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InvoiceNo[1] := CreateAndPostPurchaseInvoiceWithAmount(VendorNo, Amount);
        FindVendorLedgerEntry(InvVendLedgerEntry[1], VendorNo, InvVendLedgerEntry[1]."Document Type"::Invoice, InvoiceNo[1]);
        // [GIVEN] "PI2" with Amount Including VAT = 1000 (vendor ledger entry no. = "VLE_INV2")
        InvoiceNo[2] := CreateAndPostPurchaseInvoiceWithAmount(VendorNo, Amount);
        FindVendorLedgerEntry(InvVendLedgerEntry[2], VendorNo, InvVendLedgerEntry[2]."Document Type"::Invoice, InvoiceNo[2]);

        // [GIVEN] Payment Reconciliation Journal ("Statement No." = "X") with two lines:
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo,
          BankAccReconciliation."Statement Type"::"Payment Application");
        // [GIVEN] Line1: "Statement Line No." = 10000, "Account Type" = "Vendor", "Account No." = "V", "Transaction Text" = "PI2", "Transaction Amount" = -1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[1], BankAccReconciliation, VendorNo, InvoiceNo[2], -Amount);
        // [GIVEN] Line2: "Statement Line No." = 20000, "Account Type" = "Vendor", "Account No." = "V", "Transaction Text" = "PI1", "Transaction Amount" = -1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[2], BankAccReconciliation, VendorNo, InvoiceNo[1], -Amount);

        // [GIVEN] Perform "Apply automatically" action
        MatchBankReconLineAutomatically(BankAccReconciliation);

        // [GIVEN] Vendor ledger entry "VLE_INV1" has "Applies-To ID" = "X-20000"
        InvVendLedgerEntry[1].Find;
        Assert.AreEqual(
          BankAccReconciliationLine[2].GetAppliesToID,
          InvVendLedgerEntry[1]."Applies-to ID", InvVendLedgerEntry[1].FieldCaption("Applies-to ID"));
        // [GIVEN] Vendor ledger entry "VLE_INV2" has "Applies-To ID" = "X-10000"
        InvVendLedgerEntry[2].Find;
        Assert.AreEqual(
          BankAccReconciliationLine[1].GetAppliesToID,
          InvVendLedgerEntry[2]."Applies-to ID", InvVendLedgerEntry[2].FieldCaption("Applies-to ID"));

        // [WHEN] Post the journal
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] The journal has been posted and two invoices "PI1", "PI2" are closed:
        // [THEN] Vendor ledger entry "VLE_INV2" has "Open" = FALSE, "Closed by Entry No." = "VLE_PMT1", where
        // [THEN] Vendor ledger entry "VLE_PMT1": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        FindVendorLedgerEntry(
          PmtVendLedgerEntry, VendorNo, PmtVendLedgerEntry."Document Type"::Payment, BankAccReconciliationLine[1]."Statement No.");
        InvVendLedgerEntry[2].Find;
        Assert.AreEqual(false, InvVendLedgerEntry[2].Open, InvVendLedgerEntry[2].FieldCaption(Open));
        Assert.AreEqual(
          PmtVendLedgerEntry."Entry No.", InvVendLedgerEntry[2]."Closed by Entry No.",
          InvVendLedgerEntry[2].FieldCaption("Closed by Entry No."));
        // [THEN] Vendor ledger entry "VLE_INV1" has "Open" = FALSE, "Closed by Entry No." = "VLE_PMT2", where
        // [THEN] Vendor ledger entry "VLE_PMT2": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        PmtVendLedgerEntry.Next;
        InvVendLedgerEntry[1].Find;
        Assert.AreEqual(false, InvVendLedgerEntry[1].Open, InvVendLedgerEntry[1].FieldCaption(Open));
        Assert.AreEqual(
          PmtVendLedgerEntry."Entry No.", InvVendLedgerEntry[1]."Closed by Entry No.",
          InvVendLedgerEntry[1].FieldCaption("Closed by Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryCreatedWhenCopyVATSetupToJnlLineEnabledInBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 212403] VAT Entry is created when post Payment Reconciliation with enabled "Copy VAT Setup to Jnl. Line" in Payment Reconciliation

        Initialize();

        // [GIVEN] Payment Reconciliation with enabled "Copy VAT Setup to Jnl. Line"
        CreateBankAccReconSetCopyVATSetupInJnlLine(BankAccReconciliation, true);

        // [GIVEN] Payment Reconciliation Line
        CreateBankAccReconciliationLineWithVATGLAcc(BankAccReconciliationLine, BankAccReconciliation);

        // [WHEN] Post Payment Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry is created for Payment Reconciliation
        FindGLEntry(GLEntry, BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Account No.");
        FilterPmtVATEntry(VATEntry, BankAccReconciliationLine."Statement No.", GLEntry."Transaction No.");
        Assert.RecordCount(VATEntry, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATEntryCreatedWhenCopyVATSetupToJnlLineDisabledInBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 212403] VAT Entry is not created when post Payment Reconciliation with disabled  "Copy VAT Setup to Jnl. Line" in Payment Reconciliation

        Initialize();

        // [GIVEN] Payment Reconciliation with disabled "Copy VAT Setup to Jnl. Line"
        CreateBankAccReconSetCopyVATSetupInJnlLine(BankAccReconciliation, false);

        // [GIVEN] Payment Reconciliation Line
        CreateBankAccReconciliationLineWithVATGLAcc(BankAccReconciliationLine, BankAccReconciliation);

        // [WHEN] Post Payment Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry is not created for Payment Reconciliation
        FindGLEntry(GLEntry, BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Account No.");
        FilterPmtVATEntry(VATEntry, BankAccReconciliationLine."Statement No.", GLEntry."Transaction No.");
        Assert.RecordCount(VATEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenAndVATPostingGroupsNotCopiesIfCopyVATSetupSetInGenJnlLine()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] General and VAT Posting groups not copies to General Journal Line from G/L Account when "Bank Acc. Recon. Rec. ID" is set in General Journal Line

        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        GenJournalLine.Init();
        GenJournalLine.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccount."No.");

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenAndVATPostingGroupsCopiesIfCopyVATSetupDoesNotSetInGenJnlLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] General and VAT Posting groups copies to General Journal Line from G/L Account when "Bank Acc. Recon. Rec. ID" is not set in General Journal Line

        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        GenJournalLine.Init();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccount."No.");

        GenJournalLine.TestField("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GenJournalLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenJournalLine.TestField("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        GenJournalLine.TestField("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenJournalLine.TestField("Gen. Posting Type", GLAccount."Gen. Posting Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJnlLineHasCopyVATSetupToJnlLineByDefault()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] "Copy VAT Setup to Jnl. Line" is true by default in General Journal Line

        Initialize();

        GenJournalLine.Init();
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Insert();

        GenJournalLine.TestField("Copy VAT Setup to Jnl. Lines", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJnlLineInheritsCopyVATSetupToJnlLineFromBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] "Copy VAT Setup to Jnl. Line" inherits from General Journal Batch to General Journal Line

        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.Insert(true);

        GenJournalLine.TestField("Copy VAT Setup to Jnl. Lines", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllFieldsExceptCopyVATSetupToJnlLineNonEditableOnPmtReconJnlsPage()
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 212403] All fields except "Copy VAT Setup to Jnl. Line" are not editable on "Pmt. Reconciliation Journals" page

        Initialize();

        PmtReconciliationJournals.OpenEdit;
        Assert.IsFalse(PmtReconciliationJournals."Bank Account No.".Editable, 'Bank Account No.');
        Assert.IsFalse(PmtReconciliationJournals."Statement No.".Editable, 'Statement No.');
        Assert.IsFalse(PmtReconciliationJournals."Total Transaction Amount".Editable, 'Total Transaction Amount');
        Assert.IsFalse(PmtReconciliationJournals."Total Difference".Editable, 'Total Difference');
        Assert.IsTrue(PmtReconciliationJournals."Copy VAT Setup to Jnl. Line".Editable, 'Copy VAT Setup to Jnl. Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATSetupDoesNotCopyToGenJnlLineByBatchValueWhenRecordInsertsAfterGLAccValidation()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255555] VAT Setup does not copy to General Journal Line based on "Copy VAT Setup to Jnl. Lines" value of General Journal Batch when record inserts after G/L Account Validation

        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup);
        GenJournalLine.Insert(true);

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATSetupDoesNotCopyToGenJnlLineByFieldValueWhenRecordInsertsAfterGLAccValidation()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255555] VAT Setup does not copy to General Journal Line based on "Copy VAT Setup to Jnl. Lines" value of record when it inserts after G/L Account Validation

        Initialize();
        GenJournalLine.Init();
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup);
        GenJournalLine.Insert(); // insert without trigger to avoid error on GenJournalBatch.GET

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT053_BankAccountID()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [SEPA CAMT] [CAMT 053] [Bank Account ID]
        // [SCENARIO 273063] Import CAMT 053 when only Bank Account Id is specified in Stmt/Acct/Id/Othr/Id
        Initialize();

        // [GIVEN] Bank account with SEPA CAMT 053 setup
        CreateBankAcc(SEPA_CAMT_Txt, BankAccount, '');

        // [GIVEN] XML file with Bank Account Id specified in Stmt/Acct/Id/Othr/Id
        WriteCAMTFile_BankAccID(BankAccount."Bank Account No.");

        // [WHEN] Import bank statement
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliation.ImportBankStatement;

        // [THEN] The file has been imported and a line has been created
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindFirst;
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Recon. E2E Tests 2");

        if Initialized then
            exit;

        Initialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 2");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        UpdateVendPostingGrp();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 2");
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

    local procedure CreateVendor(var Vend: Record Vendor)
    begin
        LibraryPurch.CreateVendor(Vend);
        Vend.Validate(Name, LibraryUtility.GenerateRandomText(10));
        Vend.Modify(true);
    end;

    local procedure CreateVendPaymentGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; BankAcc: Record "Bank Account"; StmtAmt: Decimal)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine,
          GenJnlTemplate.Name,
          GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor,
          Vend."No.",
          GenJnlLine."Bal. Account Type"::"Bank Account",
          BankAcc."No.",
          StmtAmt);
    end;

    [Scope('OnPrem')]
    procedure CreateManualCheckAndPostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; BankAccNo: Code[20]; StmtAmt: Decimal)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine,
          GenJnlTemplate.Name,
          GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor,
          VendLedgEntry."Vendor No.",
          GenJnlLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          StmtAmt);

        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.Validate("Applies-to Doc. Type", VendLedgEntry."Document Type");
        GenJnlLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
        GenJnlLine.Validate("External Document No.", VendLedgEntry."External Document No.");
        GenJnlLine.Modify(true);
        Commit();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        Commit();
    end;

    local procedure CreateBankAccReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; CurrencyCode: Code[10])
    var
        BankAcc: Record "Bank Account";
    begin
        CreateBankAcc(SEPA_CAMT_Txt, BankAcc, CurrencyCode);
        CreateBankReconAndImportStmt(BankAccRecon, TempBlobUTF8, BankAcc);
    end;

    local procedure CreateBankReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; BankAcc: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(SEPA_CAMT_Txt, TempBlobUTF8);
        BankAccRecon.ImportBankStatement;

        BankAccRecon.CalcFields("Total Transaction Amount");
    end;

    local procedure CreateUnpaidDocs(var OutStream: OutStream; var VendLedgEntry: array[20] of Record "Vendor Ledger Entry"; var RentGLAcc: Record "G/L Account"; var InterestGLAcc: Record "G/L Account")
    begin
        WriteCAMTHeader(OutStream, '', 'TEST');

        OnePurchOnePmt(VendLedgEntry[1], OutStream);
        OnePurchTwoPmt(VendLedgEntry[2], OutStream);
        TwoPurchTwoPmt(VendLedgEntry[3], VendLedgEntry[4], OutStream);
        TwoPurchOnePmt(VendLedgEntry[5], VendLedgEntry[6], OutStream);

        OnePurchOnePmtWithPmtDisc(VendLedgEntry[7], OutStream);
        OnePurchTwoPmtWithPmtDisc(VendLedgEntry[8], OutStream);
        TwoPurchTwoPmtWithPmtDisc(VendLedgEntry[9], VendLedgEntry[10], OutStream);
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry[11], VendLedgEntry[12], OutStream);

        OnePurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry[13], OutStream, '');
        OnePurchOnePmtWithWrongPmtDiscPct(VendLedgEntry[14], OutStream);

        // BankTransfer(BankAcc,OutStream);

        RecurringRent(RentGLAcc, OutStream);
        RecurringInterest(InterestGLAcc, OutStream);

        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithAmount(VendorNo: Code[20]; Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurch.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurch.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        exit(LibraryPurch.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; VendorNo: Code[20]; InvoiceNo: Code[20]; StatementAmount: Decimal)
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        with BankAccReconciliationLine do begin
            Validate("Transaction Date", WorkDate);
            Validate("Transaction Text", InvoiceNo);
            Validate("Document No.", LibraryUtility.GenerateGUID);
            Validate("Statement Amount", StatementAmount);
            Validate("Account Type", "Account Type"::Vendor);
            Validate("Account No.", VendorNo);
            Modify(true);
        end;
    end;

    local procedure CreateBankAccReconSetCopyVATSetupInJnlLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; CopyVATSetupToJnlLine: Boolean)
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo,
          BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliation.Validate("Copy VAT Setup to Jnl. Line", CopyVATSetupToJnlLine);
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankAccReconciliationLineWithVATGLAcc(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        with BankAccReconciliationLine do begin
            Validate("Transaction Date", WorkDate);
            Validate("Document No.", LibraryUtility.GenerateGUID);
            Validate(Description, "Document No.");
            Validate("Statement Amount", LibraryRandom.RandDec(100, 2));
            Validate("Account Type", "Account Type"::"G/L Account");
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GLAccNo :=
              LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
            Validate("Account No.", GLAccNo);
            Modify(true);
            TransferRemainingAmountToAccount;
        end;
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

    local procedure FilterPmtVATEntry(var VATEntry: Record "VAT Entry"; DocNo: Code[20]; TransactionNo: Integer)
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);
    end;

    local procedure AddTextMapperRules(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; InterestGLAcc: Record "G/L Account"; RentGLAcc: Record "G/L Account")
    begin
        PmtReconJnl.Last;
        LibraryVariableStorage.Enqueue(InterestGLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke;

        PmtReconJnl.Previous;
        LibraryVariableStorage.Enqueue(RentGLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke;
    end;

    local procedure ApplyAutomatically(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        PmtReconJnl.ApplyAutomatically.Invoke;
        Commit();
        PmtReconJnl.First;
    end;

    local procedure ApplyManually(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var VendLedgEntry: array[20] of Record "Vendor Ledger Entry")
    begin
        // Without Pmt Disc

        // OnePurchOnePmt
        PmtReconJnl.First;
        HandlePmtEntries(VendLedgEntry[1], PmtReconJnl);
        // OnePurchTwoPmt
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[2], PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[2], PmtReconJnl);
        // TwoPurchTwoPmt
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[3], PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[4], PmtReconJnl);
        // TwoPurchOnePmt
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[5], PmtReconJnl);
        HandlePmtEntries(VendLedgEntry[6], PmtReconJnl);

        // OnePurchOnePmtWithPmtDisc
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[7], PmtReconJnl);
        // OnePurchTwoPmtWithPmtDisc
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[8], PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[8], PmtReconJnl);
        // TwoPurchTwoPmtWithPmtDisc
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[9], PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[10], PmtReconJnl);
        // TwoPurchOnePmtWithPmtDisc
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry[11], PmtReconJnl);
        HandlePmtEntries(VendLedgEntry[12], PmtReconJnl);

        PmtReconJnl.Next;
        HandlePmtDiscDate(VendLedgEntry[13], PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtDiscAmt(VendLedgEntry[14], PmtReconJnl);

        // PmtReconJnl.NEXT;
        // HandleBankTransAmt(BankAcc,PmtReconJnl);
        PmtReconJnl.Next;
        HandleRecurringInterestAmt(PmtReconJnl);

        PmtReconJnl.Next;
        HandleRecurringRentAmt(PmtReconJnl);
    end;

    local procedure MatchBankReconLineAutomatically(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Option; DocumentNo: Code[20])
    begin
        with VendorLedgerEntry do begin
            SetRange("Vendor No.", VendorNo);
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            FindFirst;
        end;
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst;
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

    local procedure WriteCAMTFile_BankAccID(BankAccountID: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderWithBankID(
          OutStream, 'TEST', '2018-01-01T12:00:00+00:00', '', BankAccountID, '100', '01-01-2018', '100', '01-01-2018');
        WriteCAMTStmtLine(OutStream, WorkDate, 'TEST CAMT BANK ID', 1000, '');
        WriteCAMTFooter(OutStream);
        SetupSourceMock(SEPA_CAMT_Txt, TempBlob);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCAMTFileMgt.SetupSourceMock(DataExchDefCode, TempBlob);
    end;

    [Scope('OnPrem')]
    procedure OnePurchOnePmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Posting Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure OnePurchOnePmtExcessiveAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; Excessiveamount: Decimal)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(OutStream,
              "Posting Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible" - Excessiveamount, "Currency Code");
    end;

    local procedure OnePurchTwoPmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        HalfAmt: Decimal;
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        with VendLedgEntry do begin
            HalfAmt := Round("Remaining Amount" / 2);
            WriteCAMTStmtLine(OutStream, "Posting Date", "Document No.", HalfAmt, "Currency Code");
            WriteCAMTStmtLine(
              OutStream, "Posting Date", "Document No.",
              "Remaining Amount" - HalfAmt - "Remaining Pmt. Disc. Possible", "Currency Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure TwoPurchTwoPmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Posting Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
        with VendLedgEntry2 do
            WriteCAMTStmtLine(
              OutStream, "Posting Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure TwoPurchOnePmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Posting Date", StrSubstNo('%1;%2', "Document No.", VendLedgEntry2."Document No."),
              "Remaining Amount" - "Remaining Pmt. Disc. Possible" +
              VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible",
              "Currency Code");
    end;

    local procedure OnePurchOnePmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Pmt. Discount Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure OnePurchTwoPmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
        HalfAmt: Decimal;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');

        with VendLedgEntry do begin
            HalfAmt := Round("Remaining Amount" / 2);
            WriteCAMTStmtLine(OutStream, "Pmt. Discount Date", "Document No.", HalfAmt, "Currency Code");
            WriteCAMTStmtLine(
              OutStream, "Pmt. Discount Date", "Document No.",
              "Remaining Amount" - HalfAmt - "Remaining Pmt. Disc. Possible", "Currency Code");
        end;
    end;

    local procedure TwoPurchTwoPmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Pmt. Discount Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
        with VendLedgEntry2 do
            WriteCAMTStmtLine(
              OutStream, "Pmt. Discount Date", "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure TwoPurchOnePmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream, "Pmt. Discount Date", StrSubstNo('%1;%2', "Document No.", VendLedgEntry2."Document No."),
              "Remaining Amount" - "Remaining Pmt. Disc. Possible" +
              VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible",
              "Currency Code");
    end;

    local procedure OnePurchOnePmtWithLateDueDatePmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; CurrencyCode: Code[10])
    var
        Vend: Record Vendor;
        PmtTerms: Record "Payment Terms";
    begin
        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, CurrencyCode);

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream,
              CalcDate('<+1D>', "Pmt. Discount Date"),
              "Document No.", "Remaining Amount" - "Remaining Pmt. Disc. Possible", "Currency Code");
    end;

    local procedure OneFCYPurchOnePmtWithLateDueDatePmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
        PmtTerms: Record "Payment Terms";
        Curr: Record Currency;
        StmtAmt: Decimal;
    begin
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 10, 10));

        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, Curr.Code);

        with VendLedgEntry do begin
            StmtAmt :=
              "Remaining Amt. (LCY)" -
              Round("Remaining Pmt. Disc. Possible" * ("Remaining Amt. (LCY)" / "Remaining Amount"));

            WriteCAMTStmtLine(
              OutStream,
              CalcDate('<+1D>', "Pmt. Discount Date"),
              "Document No.", StmtAmt, "Currency Code");
        end;
    end;

    local procedure OnePurchOnePmtWithWrongPmtDiscPct(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        with VendLedgEntry do
            WriteCAMTStmtLine(
              OutStream,
              "Pmt. Discount Date",
              "Document No.", "Remaining Amount" + Round("Remaining Pmt. Disc. Possible" - 5 / 100 * "Remaining Amount"),
              "Currency Code");
    end;

    local procedure RecurringInterest(var GLAcc: Record "G/L Account"; var OutStream: OutStream)
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Interest');
        GLAcc.Modify(true);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM+1D>', WorkDate), GLAcc."No." + ' Bank Interest', -200, '');
    end;

    local procedure BankTransfer(var BankAcc: Record "Bank Account"; var OutStream: OutStream; TransferAmount: Decimal)
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate), BankAcc."No." + ' Bank Transfer', TransferAmount, '');
    end;

    local procedure RecurringRent(var GLAcc: Record "G/L Account"; var OutStream: OutStream)
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Rent');
        GLAcc.Modify(true);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate), 'Rent', -10000, '');
    end;

    [Scope('OnPrem')]
    procedure HandlePmtEntries(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate, PmtReconJnl."Statement Amount".AsDEcimal, false, false, false, false);
        PmtReconJnl.ApplyEntries.Invoke;
    end;

    local procedure HandlePmtDiscDate(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate, PmtReconJnl."Statement Amount".AsDEcimal, false, true, false, false);
        PmtReconJnl.ApplyEntries.Invoke;
    end;

    local procedure HandlePmtDiscAmt(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate, PmtReconJnl."Statement Amount".AsDEcimal, true, false, false, false);
        PmtReconJnl.ApplyEntries.Invoke;
    end;

    local procedure HandleRecurringInterestAmt(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          '', 0, 0, PmtReconJnl."Transaction Date".AsDate, PmtReconJnl."Statement Amount".AsDEcimal, false, false, true, false);
        PmtReconJnl.ApplyEntries.Invoke;
    end;

    local procedure HandleRecurringRentAmt(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          '', 0, 0, PmtReconJnl."Transaction Date".AsDate, PmtReconJnl."Statement Amount".AsDEcimal, false, false, false, true);
        PmtReconJnl.ApplyEntries.Invoke;
    end;

    local procedure EnqueueValuesForPmtApplnHandler(VendorNo: Code[20]; VLEEntryNo: Integer; VLERemAmtLCY: Decimal; TransactionDate: Date; StatementAmount: Decimal; AdjustDiscountAmount: Boolean; AdjustDiscountDate: Boolean; IsRecurringInterest: Boolean; IsRecurringRent: Boolean)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(VLEEntryNo);
        LibraryVariableStorage.Enqueue(VLERemAmtLCY);
        LibraryVariableStorage.Enqueue(TransactionDate);
        LibraryVariableStorage.Enqueue(StatementAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountDate);
        LibraryVariableStorage.Enqueue(IsRecurringInterest);
        LibraryVariableStorage.Enqueue(IsRecurringRent);
    end;

    local procedure CreateVendWithPmtDisc(var Vend: Record Vendor)
    var
        PmtTerms: Record "Payment Terms";
    begin
        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);
    end;

    local procedure CreateVendAndPostPurchInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, CurrencyCode);
    end;

    local procedure CreatePurchInvoiceAndPost(var Vend: Record Vendor; var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomText(10));
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Document No.", LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
        VendLedgEntry.FindFirst;

        VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure PostPayment(var VendLedgerEntry: Record "Vendor Ledger Entry"; BankAccNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor,
          VendLedgerEntry."Vendor No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -VendLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", VendLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJournalLine.Validate("External Document No.", VendLedgerEntry."External Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentToGLAccount(GLAccountNo: Code[20]; BankAccNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostBankTransfer(BankAccNo: Code[20]; BalBankAccNo: Code[20]; TransferAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account",
          BankAccNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BalBankAccNo,
          -TransferAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyPrePost(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        PmtReconJnl.First;
        repeat
            PmtReconJnl.Difference.AssertEquals(0);
            PmtReconJnl."Applied Amount".AssertEquals(PmtReconJnl."Statement Amount".AsDEcimal);
        until not PmtReconJnl.Next;

        BankAccReconLine.LinesExist(BankAccRecon);
        repeat
            AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
            Assert.AreEqual(AppliedPmtEntry.Count, BankAccReconLine."Applied Entries", 'Checking the Applied Entries field on Tab273');
        until BankAccReconLine.Next = 0;
    end;

    local procedure VerifyVendLedgEntry(VendNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange(Open, true);
        Assert.IsTrue(VendLedgEntry.IsEmpty, 'All entries are closed')
    end;

    local procedure VerifyVendLedgEntryExcessiveAmount(VendNo: Code[20]; ExcessiveAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetAutoCalcFields("Remaining Amount");
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Remaining Amount", ExcessiveAmount);
        Assert.AreEqual(1, VendLedgEntry.Count, 'There should be one open ledger entry for the excessive amount.')
    end;

    local procedure VerifyBankLedgEntry(BankAccNo: Code[20]; ExpAmt: Decimal)
    begin
        VerifyBankLedgEntryAmount(BankAccNo, ExpAmt);
        VerifyBankLedgEntriesClosed(BankAccNo);
    end;

    local procedure VerifyBankLedgEntryAmount(BankAccNo: Code[20]; ExpAmt: Decimal)
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TotalAmt: Decimal;
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.FindSet;
        repeat
            TotalAmt += BankAccLedgEntry.Amount;
        until BankAccLedgEntry.Next = 0;

        Assert.AreEqual(ExpAmt, TotalAmt, '')
    end;

    local procedure VerifyBankLedgEntriesClosed(BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, true);
        Assert.IsTrue(BankAccLedgEntry.IsEmpty, OpenBankLedgerEntriesErr);
    end;

    local procedure VerifyBankLedgEntriesOpen(BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, false);
        Assert.IsTrue(BankAccLedgEntry.IsEmpty, ClosedBankLedgerEntriesErr);
    end;

    local procedure VerifyNoLinesImported(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        Assert.IsTrue(BankAccReconciliationLine.IsEmpty, 'Processed payments should not have been imported.');
    end;

    local procedure UpdateVendPostingGrp()
    var
        VendPostingGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        with VendPostingGroup do
            if FindSet then
                repeat
                    if "Payment Disc. Debit Acc." = '' then begin
                        Validate("Payment Disc. Debit Acc.", GLAcc."No.");
                        Modify(true);
                    end;
                    if "Payment Disc. Credit Acc." = '' then begin
                        Validate("Payment Disc. Credit Acc.", GLAcc."No.");
                        Modify(true);
                    end;
                until Next = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgTxt: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnHandler(var PmtAppln: TestPage "Payment Application")
    var
        VendorNo: Code[20];
        VLEEntryNo: Integer;
        VLERemAmtLCY: Decimal;
        PmtReconJnlTransactionDate: Date;
        PmtReconJnlStatementAmount: Decimal;
        AdjustDiscountAmount: Boolean;
        AdjustDiscountDate: Boolean;
        IsRecurringInterest: Boolean;
        IsRecurringRent: Boolean;
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(VendorNo));
        VLEEntryNo := LibraryVariableStorage.DequeueInteger;
        VLERemAmtLCY := LibraryVariableStorage.DequeueDecimal;
        PmtReconJnlTransactionDate := LibraryVariableStorage.DequeueDate;
        PmtReconJnlStatementAmount := LibraryVariableStorage.DequeueDecimal;
        AdjustDiscountAmount := LibraryVariableStorage.DequeueBoolean;
        AdjustDiscountDate := LibraryVariableStorage.DequeueBoolean;
        IsRecurringInterest := LibraryVariableStorage.DequeueBoolean;
        IsRecurringRent := LibraryVariableStorage.DequeueBoolean;

        with PmtAppln do begin
            if IsRecurringRent or IsRecurringInterest then begin
                RemainingAmountAfterPosting.AssertEquals(0);
                exit;
            end;

            // Remove Entry is not the same Vendor
            if AppliedAmount.AsDEcimal <> 0 then
                if "Account No.".Value <> VendorNo then begin
                    Applied.SetValue(false);
                    Next;
                end;

            // Go to the first and check that it is the Vendor and scroll down to find the entry
            if Applied.AsBoolean then begin
                RelatedPartyOpenEntries.Invoke;
                while "Applies-to Entry No.".AsInteger <> VLEEntryNo do begin
                    "Account No.".AssertEquals(VendorNo);
                    Next;
                end;
            end;

            // check that it is the Vendor ledger entry and apply
            if RemainingAmountAfterPosting.AsDEcimal <> 0 then
                if AppliedAmount.AsDEcimal = 0 then begin
                    Applied.SetValue(true);
                    RemainingAmountAfterPosting.AssertEquals(0);
                end;
            if AdjustDiscountAmount then
                // Introduce payment discount
                if RemainingAmountAfterPosting.AsDEcimal <> 0 then begin
                    "Pmt. Disc. Due Date".SetValue(PmtReconJnlTransactionDate);
                    "Remaining Pmt. Disc. Possible".SetValue(
                      VLERemAmtLCY - PmtReconJnlStatementAmount);
                    RemainingAmountAfterPosting.AssertEquals(0);
                end;
            if AdjustDiscountDate then
                if PmtReconJnlTransactionDate > "Pmt. Disc. Due Date".AsDate then begin
                    "Pmt. Disc. Due Date".SetValue(PmtReconJnlTransactionDate);
                    RemainingAmountAfterPosting.AssertEquals(0);
                end;

            OK.Invoke;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TextMapperHandler(var TextToAccMapping: TestPage "Text-to-Account Mapping")
    var
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(GLAccountNo));
        TextToAccMapping."Debit Acc. No.".SetValue(GLAccountNo);
        TextToAccMapping."Credit Acc. No.".SetValue(GLAccountNo);
        TextToAccMapping.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCheckLedgEntriesHandler(var ApplyCheckLedgEntries: TestPage "Apply Check Ledger Entries")
    begin
        with ApplyCheckLedgEntries do begin
            First;
            LineApplied.SetValue(true);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferDiffToAccountHandler(var TransferDifferenceToAccount: TestPage "Transfer Difference to Account")
    var
        AccountTypeVar: Variant;
        AccountNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountTypeVar);
        LibraryVariableStorage.Dequeue(AccountNoVar);
        with TransferDifferenceToAccount do begin
            "Account Type".SetValue(AccountTypeVar);
            "Account No.".SetValue(AccountNoVar);
            OK.Invoke;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenPaymentsHandler(var PmtAppln: TestPage "Payment Application")
    var
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(VendorNo));
        // dummy dequeues
        LibraryVariableStorage.DequeueInteger;
        LibraryVariableStorage.DequeueDecimal;
        LibraryVariableStorage.DequeueDate;
        LibraryVariableStorage.DequeueDecimal;
        LibraryVariableStorage.DequeueBoolean;
        LibraryVariableStorage.DequeueBoolean;
        LibraryVariableStorage.DequeueBoolean;
        LibraryVariableStorage.DequeueBoolean;

        with PmtAppln do begin
            // Remove Entry is not the same customer
            if AppliedAmount.AsDEcimal <> 0 then
                if "Account No.".Value <> VendorNo then begin
                    Applied.SetValue(false);
                    Next;
                end;

            AllOpenPayments.Invoke;

            // check that it is the customer ledger entry and apply
            if RemainingAmountAfterPosting.AsDEcimal <> 0 then
                if AppliedAmount.AsDEcimal = 0 then begin
                    Applied.SetValue(true);
                    RemainingAmountAfterPosting.AssertEquals(0);
                end;

            OK.Invoke;
        end;
    end;

    [Scope('OnPrem')]
    procedure OutstandingCheckTrxsCount(PmtReconJnl: TestPage "Payment Reconciliation Journal") NoOfOutstandingBankTrxEntries: Integer
    var
        OutstandingBankTrxs: TestPage "Outstanding Bank Transactions";
    begin
        OutstandingBankTrxs.Trap;
        PmtReconJnl.OutstandingPayments.DrillDown;
        // Outstanding Bank Trxs page shows and count records
        OutstandingBankTrxs.First;
        repeat
            if OutstandingBankTrxs."Entry No.".Value <> '' then
                NoOfOutstandingBankTrxEntries += 1;
        until not OutstandingBankTrxs.Next;
    end;

    [Scope('OnPrem')]
    procedure OutstandingCheckTrxsVerifyEntryNo(PmtReconJnl: TestPage "Payment Reconciliation Journal"; EntryNo: Integer) EntryNoExists: Boolean
    var
        OutstandingBankTrxs: TestPage "Outstanding Bank Transactions";
    begin
        OutstandingBankTrxs.Trap;
        EntryNoExists := false;
        PmtReconJnl.OutstandingPayments.DrillDown;
        // Outstanding Bank Trxs page shows and count records
        OutstandingBankTrxs.First;
        repeat
            if OutstandingBankTrxs."Entry No.".AsInteger = EntryNo then
                EntryNoExists := true;
        until not OutstandingBankTrxs.Next;
        OutstandingBankTrxs.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateOnePurchOnePmtOutstream(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    [Scope('OnPrem')]
    procedure CreateTwoPurchTwoPmtOutstream(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchTwoPmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8: Codeunit "Temp Blob"; VendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry2: Record "Vendor Ledger Entry")
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Next;
        HandlePmtEntries(VendLedgEntry2, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke;

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    local procedure OpenPmtReconJrnlOnePayment(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var VendLedgEntry: Record "Vendor Ledger Entry"; var BankAccRecon: Record "Bank Acc. Reconciliation"; var VendLedgerAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // One purchase and one payment is created and put into xml import bank statment
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";

        // Statement is imported
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');

        // GL Journal is created as a manual check
        CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry, BankAccRecon."Bank Account No.", -VendLedgerAmount);

        // Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
    end;

    local procedure OpenPmtReconJrnlTwoPayments(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var BankAccRecon: Record "Bank Acc. Reconciliation"; var VendLedgerAmount: Decimal; var VendLedgerAmount2: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Two purchases and two payments are created and put into xml import bank statment
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        VendLedgerAmount2 := VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible";

        // Statement is imported
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');

        // Two GL Journals are created as a manual check
        CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry, BankAccRecon."Bank Account No.", -VendLedgerAmount);
        CreateManualCheckAndPostGenJnlLine(GenJnlLine2, VendLedgEntry2, BankAccRecon."Bank Account No.", -VendLedgerAmount2);

        // Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
    end;
}

