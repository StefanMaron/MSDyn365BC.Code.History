codeunit 144054 "ERM ES Income Statement"
{
    // Test for feature INCOMESTAT - Income Statement.
    //  1. Verify G/L Account number with - 1290001 after filter - Income/Balance - Income Statement and Account Type - Posting.
    //  2. Verify Income Statement Batch Job automatically posted all closing entries in case entries are only in local currency.
    //  3. Verify error when indenting Chart of Accounts any commercial G/L Account does have Income Statement Balance Account.
    //  4. Test Dimensions updated after posting General Journal Lines.
    // 
    // Covers Test Cases for WI - 352077.
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // GLAccountWithIncomeStatementAndAccountTypePosting                                           151479
    // IncomeStatementBatchWithCloseEntries                                                        151480
    // IndentChartOfAccountsError                                                                  151481
    // 
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // CheckDimenstionsJobJournalLineAfterCloseIncomStat                                           359520

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        IncomeStatementBalanceAccTxt: Label '1290001';
        ValueMustBeSameMsg: Label 'Value must be same.';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WrongDimensionsErr: Label '%1 must be equal';
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        ExpectedMessageMsg: Label 'The journal lines have successfully been created.';

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountWithIncomeStmtAndAccTypePosting()
    var
        GLAccount: Record "G/L Account";
    begin
        // Verify G/L Account number with - 1290001 after filter - Income/Balance - Income Statement and Account Type - Posting.

        // Setup.
        Initialize();

        // Exercise: G/L Account with filter - Income/Balance - Income Statement and Account Type - Posting.
        FilterGLAccount(GLAccount);

        // Verify: Verify all G/L Account - Income Statement Balance Account with - 1290001 after filter.
        VerifyGLAccountIncomeStmtBalAccNumber(GLAccount);
    end;

    [Test]
    [HandlerFunctions('CloseIncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IncomeStatementBatchWithCloseEntries()
    var
        GenJournalBatchName: Code[10];
        Amount: Decimal;
    begin
        // Verify Income Statement Batch Report automatically posted all closing entries in case entries are only in local currency.

        // Setup: Create and Post Sales Invoice to make close entry.
        Initialize();
        RunCloseIncomeStatementReport();  // To verify new created entry so post all previous closed entries.
        Amount := CreateAndPostSalesInvoice();

        // Exercise.
        GenJournalBatchName := RunCloseIncomeStatementReport();  // Opens handler - CloseIncomeStatementRequestPageHandler.

        // Verify: Verify generated G/L register - Journal Batch Name, G/L Entry - Document No and Amount.
        VerifyGLEntryAndRegister(GenJournalBatchName, Amount)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure IndentChartOfAccountsError()
    var
        GLAccount: Record "G/L Account";
        ChartOfAccounts: TestPage "Chart of Accounts";
        GLAccountNo: Code[20];
    begin
        // Verify error when indenting Chart of Accounts any commercial G/L Account does have Income Statement Balance Account.

        // Setup: Create Commercial G/L Account with filter - Income/Balance - Income Statement and Account Type - Posting.
        Initialize();
        FilterGLAccount(GLAccount);
        GLAccount.FindLast();
        GLAccountNo := CreateCommercialGLAccount(GLAccount."No.");
        ChartOfAccounts.OpenEdit();

        // Exercise: Invoke Action Chart Of Accounts - Indent Chart Of Accounts.
        asserterror ChartOfAccounts.IndentChartOfAccounts.Invoke();  // Opens handler - ConfirmHandler.

        // Verify: Verify Expected Error - Income Stmt. Bal. Acc. must have a value for G/L Account Number. It cannot be zero or empty.
        ChartOfAccounts.Close();
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption("Income Stmt. Bal. Acc."), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerVoid')]
    [Scope('OnPrem')]
    procedure CheckDimenstionsJobJournalLineAfterCloseIncomStat()
    var
        GLEntry: Record "G/L Entry";
        ShortcutDimension1Before: Code[20];
        ShortcutDimension2Before: Code[20];
        GLAccountNo: Code[20];
    begin
        // SETUP
        Initialize();

        // EXERCISE: Create and post Gen. Journal Line, close FY, execute Close Income Statement
        PostGenJnlLineWithDimAndCloseIncomeStatement(ShortcutDimension1Before, ShortcutDimension2Before, GLAccountNo);

        // VERIFY
        FindGLEntryForGLAccount(GLAccountNo, GLEntry);

        Assert.AreEqual(ShortcutDimension1Before, GLEntry."Global Dimension 1 Code",
          StrSubstNo(WrongDimensionsErr, GLEntry.FieldName("Global Dimension 1 Code")));
        Assert.AreEqual(ShortcutDimension2Before, GLEntry."Global Dimension 2 Code",
          StrSubstNo(WrongDimensionsErr, GLEntry.FieldName("Global Dimension 2 Code")));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostSalesInvoice(): Decimal
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random value for quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateCommercialGLAccount(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Rename(IncStr(GLAccountNo));  // Rename to make a commercial G/L Account with next number.
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure FilterGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
    end;

    local procedure RunCloseIncomeStatementReport(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        Commit();
        Clear(CloseIncomeStatement);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CloseIncomeStatement.Run();
        exit(GenJournalBatch.Name);
    end;

    local procedure VerifyGLEntryAndRegister(GenJournalBatchName: Code[10]; Amount: Decimal)
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        GLRegister.TestField("Journal Batch Name", GenJournalBatchName);
        GLEntry.Get(GLRegister."From Entry No.");
        GLEntry.TestField("Document No.", GenJournalBatchName);
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLAccountIncomeStmtBalAccNumber(var GLAccount: Record "G/L Account")
    begin
        GLAccount.FindSet();
        repeat
            Assert.AreEqual(Format(IncomeStatementBalanceAccTxt), GLAccount."Income Stmt. Bal. Acc.", ValueMustBeSameMsg);
        until GLAccount.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        GenJournalBatch: Variant;
        GenJournalTemplate: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.DocumentNo.SetValue(GenJournalBatch);
        CloseIncomeStatement.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure PostGenJnlLineWithDimAndCloseIncomeStatement(var ShortcutDimension1Before: Code[20]; var ShortcutDimension2Before: Code[20]; var GLAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Create random Transaction in General Journal Line, Post the Journal Line, Close the Fiscal Year and run Close Income Statement Batch Job.
        CreateGenJournalLine(GenJournalLine, GLAccount);
        GLAccountNo := GLAccount."No.";
        // Set global dimensions
        SetGenJnlLineGlobalDimensions(GenJournalLine);
        ShortcutDimension1Before := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDimension2Before := GenJournalLine."Shortcut Dimension 2 Code";
        // Post Gen. Journal Line, close FY and run Close Income Statement
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryFiscalYear.CloseFiscalYear();
        ExecuteUIHandler();
        CloseIncomeStatement(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGLAccount(GLAccount);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(1000));
    end;

    local procedure SetGenJnlLineGlobalDimensions(var GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        SelectedDimension: Record "Selected Dimension";
        AllObj: Record AllObj;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GLSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateSelectedDimension(SelectedDimension, AllObj."Object Type"::Report,
          REPORT::"Close Income Statement", '', GLSetup."Global Dimension 2 Code");
    end;

    local procedure CloseIncomeStatement(GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        Date: Record Date;
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        // Run the Close Income Statement Batch Job.
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange("Period Start", LibraryFiscalYear.GetLastPostingDate(true));
        Date.FindFirst();
        LibraryERM.FindDirectPostingGLAccount(GLAccount);

        // Run Close Income Statement Batch Report.
        CloseIncomeStatement.InitializeRequestTest(NormalDate(Date."Period End"), GenJournalLine, GLAccount, true);
        Commit();  // Required to handle Modal Form.
        CloseIncomeStatement.UseRequestPage(false);
        CloseIncomeStatement.RunModal();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        IncomeStmtBalGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        LibraryERM.CreateGLAccount(IncomeStmtBalGLAccount);
        GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalGLAccount."No.");
        GLAccount.Modify(true);
    end;

    local procedure FindGLEntryForGLAccount(GLAccountNo: Code[20]; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerVoid(Message: Text[1024])
    begin
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully in ES.
        Message(ExpectedMessageMsg);
    end;
}

