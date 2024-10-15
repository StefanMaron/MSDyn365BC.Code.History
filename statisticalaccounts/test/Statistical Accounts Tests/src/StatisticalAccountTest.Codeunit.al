codeunit 139683 "Statistical Account Test"
{
    // [FEATURE] [Statistical Accounts]
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        Initialized: Boolean;

    local procedure Initialize()
    var
        StatisticalAccount: Record "Statistical Account";
        StatisticalLedgerEntry: Record "Statistical Ledger Entry";
        StatisticalAccJournalLine: Record "Statistical Acc. Journal Line";
    begin
        StatisticalAccount.DeleteAll();
        StatisticalLedgerEntry.DeleteAll();
        StatisticalAccJournalLine.DeleteAll();
        LibraryVariableStorage.AssertEmpty();

        if Initialized then
            exit;

        Commit();
        Initialized := true;
    end;

    [Test]
    procedure TestCreateStatisticalAccount()
    var
        StatisticalAccount: Record "Statistical Account";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        StatisticalAccountCard: TestPage "Statistical Account Card";
        DefaultDimensions: TestPage "Default Dimensions";
        AccountNo: Code[20];
    begin
        Initialize();

        // [GIVEN] - Dimensions exist
        LibraryDimension.CreateDimWithDimValue(DimensionValue1);
        LibraryDimension.CreateDimWithDimValue(DimensionValue2);

        // [WHEN] A user creates a statistical account with dimensions
        StatisticalAccountCard.OpenNew();
#pragma warning disable AA0139
        AccountNo := UpperCase(Any.AlphabeticText(MaxStrLen(AccountNo)));
#pragma warning restore AA0139

        StatisticalAccountCard."No.".SetValue(AccountNo);
        DefaultDimensions.Trap();
        StatisticalAccountCard.Dimensions.Invoke();

        DefaultDimensions.New();
        DefaultDimensions."Dimension Code".SetValue(DimensionValue1."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue1.Code);
        DefaultDimensions.New();
        DefaultDimensions."Dimension Code".SetValue(DimensionValue2."Dimension Code");
        DefaultDimensions."Dimension Value Code".SetValue(DimensionValue2.Code);
        DefaultDimensions.Close();
        StatisticalAccountCard.Close();

        // [THEN] A New statistical account is created with dimensions
        Assert.IsTrue(StatisticalAccount.Get(AccountNo), 'Statistical account was not created');
        Assert.IsTrue(DefaultDimension.Get(Database::"Statistical Account", StatisticalAccount."No.", DimensionValue1."Dimension Code"), 'Could not get the first dimension');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", DimensionValue1.Code, 'Wrong value for the first dimension');

        Assert.IsTrue(DefaultDimension.Get(Database::"Statistical Account", StatisticalAccount."No.", DimensionValue2."Dimension Code"), 'Could not get the second dimension');
        Assert.AreEqual(DefaultDimension."Dimension Value Code", DimensionValue2.Code, 'Wrong value for the second dimension');
    end;

    [Test]
    [HandlerFunctions('MessageDialogHandler,ConfirmationDialogHandler')]
    procedure TestPostTransactionsToStatisticalAccount()
    var
        StatisticalAccount: Record "Statistical Account";
        StatisticalLedgerEntry: Record "Statistical Ledger Entry";
        TempStatisticalAccJournalLine: Record "Statistical Acc. Journal Line" temporary;
        StatisticalAccountsJournal: TestPage "Statistical Accounts Journal";
    begin
        Initialize();

        // [GIVEN] - Statistical Account 
        CreateStatisticalAccountWithDimensions(StatisticalAccount);

        // [GIVEN] User creates journal with lines
        StatisticalAccountsJournal.OpenEdit();
        TempStatisticalAccJournalLine."Posting Date" := DT2Date(CurrentDateTime());
        TempStatisticalAccJournalLine."Statistical Account No." := StatisticalAccount."No.";
        TempStatisticalAccJournalLine."Amount" := Any.DecimalInRange(1000, 2);

        StatisticalAccountsJournal."Posting Date".SetValue(TempStatisticalAccJournalLine."Posting Date");
        StatisticalAccountsJournal.StatisticalAccountNo.SetValue(TempStatisticalAccJournalLine."Statistical Account No.");
        StatisticalAccountsJournal.Amount.SetValue(TempStatisticalAccJournalLine.Amount);

        // [WHEN] User posts the journal
        RegisterJournal(StatisticalAccountsJournal);

        // [THEN] Journal and transactions are posted correctly
        StatisticalLedgerEntry.SetRange("Statistical Account No.", StatisticalAccount."No.");
        Assert.AreEqual(1, StatisticalLedgerEntry.Count(), 'Wrong number of posting entries');
        StatisticalLedgerEntry.FindFirst();

        Assert.AreEqual(TempStatisticalAccJournalLine."Posting Date", StatisticalLedgerEntry."Posting Date", 'Wrong posting date');
        Assert.AreEqual(TempStatisticalAccJournalLine."Statistical Account No.", StatisticalLedgerEntry."Statistical Account No.", 'Wrong Statistical Account No.');
        Assert.AreEqual(TempStatisticalAccJournalLine.Amount, StatisticalLedgerEntry.Amount, 'Wrong amount');
    end;

    [Test]
    [HandlerFunctions('MessageDialogHandler,ConfirmationDialogHandler')]
    procedure TestBalancesAreShownCorrectlyOnStatisticalAccount()
    var
        StatisticalAccount: Record "Statistical Account";
        TempStatisticalAccountLedgerEntries: Record "Statistical Ledger Entry" temporary;
        StatisticalAccountsJournal: TestPage "Statistical Accounts Journal";
        StatisticalAccountCard: TestPage "Statistical Account Card";
        StatAccountBalance: TestPage "Stat. Account Balance";
    begin
        Initialize();
        // [GIVEN] - Statistical Account with transactions 
        CreateStatisticalAccountWithDimensions(StatisticalAccount);
        CreateTransactions(StatisticalAccount, 4, TempStatisticalAccountLedgerEntries);
        CreateJournal(StatisticalAccountsJournal, TempStatisticalAccountLedgerEntries);

        RegisterJournal(StatisticalAccountsJournal);
        StatisticalAccountsJournal.Close();

        StatisticalAccountCard.OpenEdit();
        StatisticalAccountCard.GoToRecord(StatisticalAccount);

        // [WHEN] User opens balances with net view
        StatAccountBalance.Trap();
        StatisticalAccountCard.StatisticalAccountBalance.Invoke();
        // [THEN] Balances are show correctly
        VerifyStatisticalAccountBalances(StatAccountBalance, TempStatisticalAccountLedgerEntries);
    end;

    local procedure RegisterJournal(var StatisticalAccountsJournal: TestPage "Statistical Accounts Journal")
    begin
        LibraryVariableStorage.Enqueue('register');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue('successfully');
        StatisticalAccountsJournal.Register.Invoke();
    end;

    local procedure VerifyStatisticalAccountBalances(var StatAccountBalance: TestPage "Stat. Account Balance"; var TempStatisticalAccountLedgerEntries: Record "Statistical Ledger Entry" temporary)
    var
        AnalysisPeriodType: Enum "Analysis Period Type";
    begin
        StatAccountBalance.PeriodType.SetValue(AnalysisPeriodType::Day);

        TempStatisticalAccountLedgerEntries.Reset();
        TempStatisticalAccountLedgerEntries.FindSet();
        repeat
            StatAccountBalance.StatisticalAccountBalanceLines.Filter.SetFilter("Period Start", Format(TempStatisticalAccountLedgerEntries."Posting Date"));
            Assert.AreEqual(StatAccountBalance.StatisticalAccountBalanceLines.Amount.AsDecimal(), TempStatisticalAccountLedgerEntries.Amount, 'Wrong amount was set.');
        until TempStatisticalAccountLedgerEntries.Next() = 0;
    end;

    local procedure CreateTransactions(var StatisticalAccount: Record "Statistical Account"; NumberOfTransactions: Integer; var TempStatisticalAccountLedgerEntries: Record "Statistical Ledger Entry" temporary)
    var
        I: Integer;
        CurrentDate: Date;
    begin
        CurrentDate := CalcDate(StrSubstNo('<-%1D>', NumberOfTransactions + 5), DT2Date(CurrentDateTime()));
        for I := 1 to NumberOfTransactions do begin
            TempStatisticalAccountLedgerEntries."Entry No." := TempStatisticalAccountLedgerEntries."Entry No." + 1;
            TempStatisticalAccountLedgerEntries."Posting Date" := CurrentDate;
            TempStatisticalAccountLedgerEntries."Statistical Account No." := StatisticalAccount."No.";
            TempStatisticalAccountLedgerEntries."Amount" := Any.DecimalInRange(1000, 2);
            TempStatisticalAccountLedgerEntries.Insert();
            CurrentDate := CalcDate('<+1D>', CurrentDate);
        end;
    end;

    local procedure CreateJournal(var StatisticalAccountsJournal: TestPage "Statistical Accounts Journal"; var TempStatisticalAccountLedgerEntries: Record "Statistical Ledger Entry" temporary)
    begin
        StatisticalAccountsJournal.OpenEdit();

        TempStatisticalAccountLedgerEntries.Reset();
        TempStatisticalAccountLedgerEntries.FindSet();
        repeat
            StatisticalAccountsJournal.New();
            StatisticalAccountsJournal."Posting Date".SetValue(TempStatisticalAccountLedgerEntries."Posting Date");
            StatisticalAccountsJournal.StatisticalAccountNo.SetValue(TempStatisticalAccountLedgerEntries."Statistical Account No.");
            StatisticalAccountsJournal.Amount.SetValue(TempStatisticalAccountLedgerEntries.Amount);
        until TempStatisticalAccountLedgerEntries.Next() = 0;
    end;

    local procedure CreateStatisticalAccountWithDimensions(var StatisticalAccount: Record "Statistical Account")
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimensionValuePostingType: Enum "Default Dimension Value Posting Type";
    begin
        CreateStatisticalAccount(StatisticalAccount);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(DefaultDimension, Database::"Statistical Account", StatisticalAccount."No.", DefaultDimensionValuePostingType::" ");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(DefaultDimension, Database::"Statistical Account", StatisticalAccount."No.", DefaultDimensionValuePostingType::" ");
    end;

    local procedure CreateStatisticalAccount(var StatisticalAccount: Record "Statistical Account")
    begin
#pragma warning disable AA0139
        StatisticalAccount."No." := Any.AlphabeticText(MaxStrLen(StatisticalAccount."No."));
        StatisticalAccount.Name := Any.AlphabeticText(MaxStrLen(StatisticalAccount.Name));
#pragma warning restore AA0139

        StatisticalAccount.Insert();
    end;

    [MessageHandler]
    procedure MessageDialogHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(Message, ExpectedMsg) > 0, Message);
    end;

    [ConfirmHandler]
    procedure ConfirmationDialogHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(StrPos(Question, ExpectedQuestion) > 0, 'Expected ' + Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}