codeunit 134252 "Match Bank Reconciliation - UT"
{
    Permissions = TableData "Bank Account Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [Match] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        MatchSummaryMsg: Label '%1 reconciliation lines out of %2 are matched.';
        WrongValueOfFieldErr: Label 'Wrong value of field.';

    [Test]
    [HandlerFunctions('MatchSummaryMsgHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesFullMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(4);
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDesc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDocNoVsDesc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, DocumentNo, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesNoDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, 0D, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDateRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankEntries: Report "Match Bank Entries";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        DateRange: Integer;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        DateRange := LibraryRandom.RandIntInRange(2, 10);

        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation,
            PostingDate - LibraryRandom.RandInt(DateRange), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate + DateRange + LibraryRandom.RandInt(10), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(DateRange);
        Commit();
        MatchBankEntries.UseRequestPage(true);
        MatchBankEntries.SetTableView(BankAccReconciliation);
        REPORT.Run(REPORT::"Match Bank Entries", true, false, BankAccReconciliation);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDateVsRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankEntries: Report "Match Bank Entries";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        DateRange: Integer;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        DateRange := LibraryRandom.RandIntInRange(2, 10);

        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation,
          PostingDate + LibraryRandom.RandInt(DateRange), Description, '', Amount);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(DateRange);
        Commit();
        MatchBankEntries.UseRequestPage(true);
        MatchBankEntries.SetTableView(BankAccReconciliation);
        REPORT.Run(REPORT::"Match Bank Entries", true, false, BankAccReconciliation);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDescDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDocNoDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDocNoVsDescDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDescVsDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineFullMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, WorkDate, DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, WorkDate, 'WRONG DOC NO', '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineAmtVsDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineAmtVsDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineDocNoVsDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineDocNoVsExtDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', DocumentNo, Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleBankRec()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
        AdditionalLineNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation,
            PostingDate, Description, '', Amount);
        CreateBankAccRec(BankAccReconciliation1, BankAccountNo,
          LibraryUtility.GenerateRandomCode(BankAccReconciliation1.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation"));
        AdditionalLineNo := CreateBankAccRecLine(BankAccReconciliation1, PostingDate, Description, '', Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(0);
        Commit();
        BankAccReconciliationPage.OpenEdit;
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.MatchAutomatically.Invoke;

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
        asserterror VerifyOneToOneMatch(BankAccReconciliation1, AdditionalLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManyToOneNotSupported()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 1, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneToManyPartialBRL()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '',
            2 * Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 2, 2 * Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneToManyPartialBLE()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        Delta: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize;

        // Setup.
        Delta := LibraryRandom.RandDec(100, 2);
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - Delta, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 2, 2 * Amount - Delta);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchOneToMany()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Exercise.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchFromBLE()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize;

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Exercise.
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        TempBankAccountLedgerEntry.FindLast;
        TempBankAccountLedgerEntry.Delete;
        TempBankAccReconciliationLine.DeleteAll;
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 1, Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTFieldsBankAccReconciliationLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        FirstValue: Text[250];
        SecondValue: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375536] Fields "Related-Party Name" and "Related-Party Bank Acc. No." of "Bank Acc. Reconciliation Line" should have length of 250 and 100 respectively
        Initialize;

        // [GIVEN] Record of "Bank Acc. Reconciliation Line" - "BACL"
        BankAccReconciliationLine.Init();
        // [GIVEN] Length of string "X" = 250
        FirstValue := PadStr('', 250, '0');
        // [GIVEN] Length of string "Y" = 100
        SecondValue := PadStr('', 100, '0');

        // [WHEN] Validate "BACL"."Related-Party Name" with string "X", "BACL"."Related-Party Bank Acc. No." with string "Y"
        BankAccReconciliationLine.Validate("Related-Party Name", FirstValue);
        BankAccReconciliationLine.Validate("Related-Party Bank Acc. No.", SecondValue);

        // [THEN] Value of "BACL"."Related-Party Name" = "X"
        Assert.AreEqual(FirstValue, BankAccReconciliationLine."Related-Party Name", WrongValueOfFieldErr);
        // [THEN] Value of "BACL"."Related-Party Bank Acc. No." = "Y"
        Assert.AreEqual(SecondValue, BankAccReconciliationLine."Related-Party Bank Acc. No.", WrongValueOfFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTFieldsPostedPaymentReconLine()
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        StringValue: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375536] Field "Related-Party Name" of "Posted Payment Recon. Line" should has length of 250
        Initialize;

        // [GIVEN] Record of "Posted Payment Recon. Line" - "PPRL"
        PostedPaymentReconLine.Init();
        // [GIVEN] Length of string "X" = 250
        StringValue := PadStr('', 250, '0');

        // [WHEN] Validate "PPRL"."Related-Party Name" with string "X"
        PostedPaymentReconLine.Validate("Related-Party Name", StringValue);

        // [THEN] Value of "PPRL"."Related-Party Name" = "X"
        Assert.AreEqual(StringValue, PostedPaymentReconLine."Related-Party Name", WrongValueOfFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateAppliesToID()
    var
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [SCENARIO 198751] "Applies-to ID" must be unique for each Bank Account Reconciliation Line
        with DummyBankAccReconciliationLine do begin
            "Statement No." := 'STATEMENT_0000012345';
            "Statement Line No." := 1234567890;
            Assert.AreEqual(
              'STATEMENT_0000012345-1234567890',
              GetAppliesToID,
              'Wrong BankAccReconciliationLine.GenerateAppliesToID() return result');
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match Bank Reconciliation - UT");
        LibraryVariableStorage.Clear;
    end;

    local procedure AddBankRecLinesToTemp(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        TempBankAccReconciliationLine.Reset();
        TempBankAccReconciliationLine.DeleteAll();
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindSet then
            repeat
                TempBankAccReconciliationLine := BankAccReconciliationLine;
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next = 0;
    end;

    local procedure AddBankEntriesToTemp(var TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary; BankAccountNo: Code[20])
    var
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        TempBankAccLedgerEntry.Reset();
        TempBankAccLedgerEntry.DeleteAll();
        BankAccLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        if BankAccLedgerEntry.FindSet then
            repeat
                TempBankAccLedgerEntry := BankAccLedgerEntry;
                TempBankAccLedgerEntry.Insert();
            until BankAccLedgerEntry.Next = 0;
    end;

    local procedure CreateInputData(var PostingDate: Date; var BankAccountNo: Code[20]; var StatementNo: Code[20]; var DocumentNo: Code[20]; var Description: Text[50]; var Amount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Amount := -LibraryRandom.RandDec(1000, 2);
        PostingDate := WorkDate + LibraryRandom.RandInt(10);
        BankAccountNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Bank Account No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        StatementNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Statement No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        DocumentNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        Description := CopyStr(CreateGuid, 1, 50);
    end;

    local procedure CreateBankAccRec(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Bank Account No." := BankAccountNo;
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccReconciliation."Statement Date" := WorkDate;
        BankAccReconciliation.Insert();
    end;

    local procedure CreateBankAccRecLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; TransactionDate: Date; Description: Text[50]; PayerInfo: Text[50]; Amount: Decimal): Integer
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindLast then;

        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        BankAccReconciliationLine."Statement Line No." += 10000;
        BankAccReconciliationLine."Transaction Date" := TransactionDate;
        BankAccReconciliationLine.Description := Description;
        BankAccReconciliationLine."Related-Party Name" := PayerInfo;
        BankAccReconciliationLine."Statement Amount" := Amount;
        BankAccReconciliationLine.Difference := Amount;
        BankAccReconciliationLine.Type := BankAccReconciliationLine.Type::"Bank Account Ledger Entry";
        BankAccReconciliationLine.Insert();

        exit(BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure CreateBankAccLedgerEntry(BankAccountNo: Code[20]; PostingDate: Date; DocumentNo: Code[20]; ExtDocNo: Code[35]; Amount: Decimal; Description: Text[50]): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankAccountLedgerEntry.FindLast then;

        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry."Entry No." += 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Posting Date" := PostingDate;
        BankAccountLedgerEntry."Document No." := DocumentNo;
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry."Remaining Amount" := Amount;
        BankAccountLedgerEntry.Description := Description;
        BankAccountLedgerEntry."External Document No." := ExtDocNo;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Open;
        BankAccountLedgerEntry.Insert();

        exit(BankAccountLedgerEntry."Entry No.");
    end;

    local procedure VerifyOneToOneMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryNo: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        BankAccountLedgerEntry.Get(ExpBankEntryNo);

        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(1, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');
        Assert.AreEqual(ExpAmount, BankAccountLedgerEntry."Remaining Amount", 'Wrong remaining amt.');
        Assert.AreEqual(BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement No.", 'Wrong statement no.');
        Assert.AreEqual(ExpRecLineNo, BankAccountLedgerEntry."Statement Line No.",
          'Wrong statement line no.');

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetFilter("Applied Amount", '<>%1', 0);
        Assert.AreEqual(1, BankAccReconciliationLine.Count, 'Too many matches.');

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        Assert.AreEqual(1, BankAccountLedgerEntry.Count, 'Too many matches.');
    end;

    local procedure VerifyOneToManyMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryMatches: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(ExpBankEntryMatches, BankAccountLedgerEntry.Count, 'Wrong no of applied entries.');
        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(ExpBankEntryMatches, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MatchRecLinesReqPageHandler(var MatchBankAccReconciliation: TestRequestPage "Match Bank Entries")
    var
        DateRange: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateRange);
        MatchBankAccReconciliation.DateRange.SetValue(DateRange);
        MatchBankAccReconciliation.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MatchSummaryMsgHandler(Message: Text[1024])
    var
        MatchedLinesCount: Variant;
        TotalLinesCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(MatchedLinesCount);
        LibraryVariableStorage.Dequeue(TotalLinesCount);
        Assert.IsTrue(StrPos(Message, StrSubstNo(MatchSummaryMsg, MatchedLinesCount, TotalLinesCount)) > 0, Message);
    end;
}

